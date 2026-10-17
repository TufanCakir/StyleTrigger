//
//  StyleTriggerViewModel.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation
import Observation

enum AppScreen: Equatable {
    case menu
    case lobby
    case combat
    case results
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case german

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .system: "SYSTEM"
        case .english: "ENGLISH"
        case .german: "GERMAN"
        }
    }

    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .english: Locale(identifier: "en")
        case .german: Locale(identifier: "de")
        }
    }
}

enum VersusOpponent: String, CaseIterable, Identifiable {
    case bot
    case gameCenter

    var id: String { rawValue }
    var title: LocalizedStringResource {
        self == .bot ? "BOT" : "GAME CENTER"
    }
    var icon: String { self == .bot ? "cpu" : "person.2.fill" }
}
@MainActor
@Observable
final class StyleTriggerViewModel {
    private(set) var content: GameContent?
    private(set) var progress = PlayerProgress.initial
    private(set) var loadError: String?
    private(set) var screen: AppScreen = .menu
    private(set) var combat = CombatSnapshot.initial
    private(set) var remainingSeconds = 90
    private(set) var result: MatchResult?
    private(set) var isRevivePromptPresented = false
    var selectedMode: GameModeKind = .arcade
    var selectedDifficulty = "NORMAL"
    var selectedTeamSize = 1
    var menuPage = 1
    var versusOpponent: VersusOpponent = .bot
    var appLanguage =
        AppLanguage(
            rawValue: UserDefaults.standard.string(
                forKey: "styleTrigger.appLanguage"
            ) ?? ""
        ) ?? .system
    private let repository = GameDataRepository()
    private let progressionStore = ProgressionStore()
    private let music = MetalMusicService()
    let multiplayer = GameCenterMultiplayerService()
    private var timerTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var loadInProgress = false
    let story = StoryViewModel()

    func selectStoryChapter(_ chapter: StoryChapter) {
        guard selectedMode == .story,
            story.select(chapter, unlockedChapter: progress.storyChapter)
        else {
            return
        }

        selectedDifficulty = chapter.difficulty
        progress.selectedEnvironmentID = chapter.environmentID
        screen = .lobby
        saveProgress()
    }

    func localizedGameText(_ source: String) -> String {
        let usesGerman =
            appLanguage == .german
            || (appLanguage == .system
                && Locale.preferredLanguages.first?.hasPrefix("de") == true)
        guard usesGerman else { return source }
        return content?.germanLocalization[source] ?? source
    }

    var selectedCharacter: GameCharacter? {
        content?.characters.first { $0.id == progress.selectedCharacterID }
    }
    var selectedWeapon: Weapon? {
        content?.weapons.first { $0.id == progress.selectedWeaponID }
    }
    var selectedSkin: CharacterSkin? {
        guard let content else { return nil }
        let skinID = progress.selectedSkinByCharacter[
            progress.selectedCharacterID
        ]
        return content.skins.first { $0.id == skinID }
            ?? content.skins.first {
                $0.characterID == progress.selectedCharacterID
            }
    }
    var selectedAppearance: CharacterAppearance? {
        selectedSkin?.appearance ?? selectedCharacter?.appearance
    }
    var equippedWeapons: [Weapon] {
        guard let content else { return [] }
        let ids =
            progress.equippedWeaponIDsByCharacter[progress.selectedCharacterID]
            ?? selectedCharacter?.defaultWeaponIDs
            ?? []
        return ids.compactMap { id in content.weapons.first { $0.id == id } }
    }
    func skins(for character: GameCharacter) -> [CharacterSkin] {
        content?.skins.filter { $0.characterID == character.id } ?? []
    }
    func compatibleWeapons(for character: GameCharacter) -> [Weapon] {
        guard let content else { return [] }
        let ids = Set(character.compatibleWeaponIDs)
        return content.weapons.filter { ids.contains($0.id) }
    }
    func isCharacterUnlocked(_ character: GameCharacter) -> Bool {
        character.unlocked
            || accountLevel >= character.unlockLevel
            || progress.unlockedCharacterIDs.contains(character.id)
    }
    var availableCombos: [ComboDefinition] {
        guard let content, let weapon = selectedWeapon else { return [] }
        let weaponIDs = Set(weapon.associatedCombos).union(
            progress.purchasedComboIDs
        )
        return content.combos.filter { weaponIDs.contains($0.id) }
    }
    var accountExperience: Int {
        progress.characterExperience.values.reduce(0, +)
            + progress.highScores.values.reduce(0, +) / 20
    }
    var accountLevel: Int { max(1, accountExperience / 1_000 + 1) }
    var currentAccountTitle: AccountTitleDefinition? {
        content?.accountTitles
            .filter { $0.minimumLevel <= accountLevel }
            .max { $0.minimumLevel < $1.minimumLevel }
    }
    var reviveCount: Int {
        progress.consumableInventory["revive-core", default: 0]
    }
    func boostMagnitude(_ effect: ConsumableEffect) -> Double {
        content?.shopItems.first(where: {
            $0.effect == effect && progress.activeBoostIDs.contains($0.id)
        })?.magnitude ?? 0
    }
    var selectedModeDefinition: GameModeDefinition? {
        content?.progression.modes.first { $0.id == selectedMode }
    }
    var isSelectedModeUnlocked: Bool {
        progress.unlockedModes.contains(selectedMode)
    }
    var currentEvent: TimedEventDefinition? {
        content?.events.first { $0.endsAt > .now }
    }
    func load() async {
        guard !loadInProgress else { return }
        loadInProgress = true
        loadError = nil
        defer { loadInProgress = false }

        do {
            let loadedContent = try repository.load()
            let loadedProgress = await progressionStore.load()
            guard !Task.isCancelled else { return }
            content = loadedContent
            story.configure(
                with: loadedContent.story,
                enemies: loadedContent.enemies
            )
            progress = loadedProgress
            applyConfiguredUnlocks()
            repairProgressReferences()
            music.setEnabled(progress.isSoundEnabled)
        } catch {
            loadError = error.localizedDescription
        }
    }
    func selectCharacter(_ id: String) {
        guard
            content?.characters.contains(where: {
                $0.id == id && isCharacterUnlocked($0)
            })
                == true
        else { return }
        progress.selectedCharacterID = id
        repairSelectedLoadout()
        saveProgress()
    }
    func selectWeapon(_ id: String) {
        guard let character = selectedCharacter,
            character.compatibleWeaponIDs.contains(id),
            progress.unlockedWeaponIDs.contains(id),
            content?.weapons.contains(where: { $0.id == id }) == true
        else {
            return
        }
        progress.selectedWeaponID = id
        saveProgress()
    }
    func toggleEquippedWeapon(_ id: String) {
        guard let character = selectedCharacter,
            character.compatibleWeaponIDs.contains(id),
            progress.unlockedWeaponIDs.contains(id)
        else { return }
        var ids =
            progress.equippedWeaponIDsByCharacter[character.id]
            ?? character.defaultWeaponIDs
        var seen = Set<String>()
        ids = ids.filter { seen.insert($0).inserted }
        if ids.contains(id) {
            guard ids.count > 1 else { return }
            ids.removeAll { $0 == id }
        } else if ids.count < 3 {
            ids.append(id)
        } else {
            ids[2] = id
        }
        progress.equippedWeaponIDsByCharacter[character.id] = ids
        if !ids.contains(progress.selectedWeaponID), let first = ids.first {
            progress.selectedWeaponID = first
        }
        saveProgress()
    }
    func selectSkin(_ id: String, for characterID: String) {
        guard progress.unlockedSkinIDs.contains(id),
            content?.skins.contains(where: {
                $0.id == id && $0.characterID == characterID
            }) == true
        else { return }
        progress.selectedSkinByCharacter[characterID] = id
        saveProgress()
    }

    func selectEnvironment(_ id: String) {
        guard selectedMode != .story,
            content?.story.arenas.contains(where: { $0.id == id }) == true
        else {
            return
        }

        progress.selectedEnvironmentID = id
        saveProgress()
    }

    func chooseRandomEnvironment() {
        guard selectedMode != .story else { return }

        progress.selectedEnvironmentID =
            content?.story.arenas.randomElement()?.id
            ?? progress.selectedEnvironmentID

        saveProgress()
    }

    func openLobby(for mode: GameModeKind) {
        guard progress.unlockedModes.contains(mode) else {
            return
        }

        selectedMode = mode

        if mode == .story {
            story.present()
        } else {
            story.isPresented = false
            screen = .lobby
        }
    }

    func returnToMenu() {
        timerTask?.cancel()
        timerTask = nil
        multiplayer.disconnect()
        screen = .menu
        music.setEnabled(progress.isSoundEnabled)
    }

    func startMatch() {
        guard screen == .lobby,
            isSelectedModeUnlocked
        else { return }

        let duration: Int

        if selectedMode == .story {
            guard let chapter = story.selectedChapter,
                story.isUnlocked(
                    chapter,
                    unlockedChapter: progress.storyChapter
                )
            else { return }

            duration = selectedModeDefinition?.matchDuration ?? 180
        } else {
            guard let configuredDuration = selectedModeDefinition?.matchDuration
            else { return }

            duration = configuredDuration
        }

        remainingSeconds = duration
        combat = .initial
        result = nil
        isRevivePromptPresented = false
        screen = .combat

        if selectedMode != .training {
            startTimer()
        }
    }

    func startSelectedMatch() {
        if selectedMode == .versus && versusOpponent == .gameCenter {
            multiplayer.beginMatchmaking(teamSize: selectedTeamSize)
        } else {
            startMatch()
        }
    }
    func receiveCombatSnapshot(_ snapshot: CombatSnapshot) {
        guard screen == .combat else { return }
        combat = snapshot
        if snapshot.playerHealth <= 0 {
            if selectedMode == .training { return }
            if reviveCount > 0 {
                isRevivePromptPresented = true
            } else {
                finishMatch(didWin: false)
            }
        } else if snapshot.enemyHealth <= 0
            && selectedMode != .survival
            && selectedMode != .training
        {
            finishMatch(didWin: true)
        }
    }
    func finishMatch(didWin: Bool) {
        guard screen == .combat else { return }
        timerTask?.cancel()
        timerTask = nil
        let baseExperience = max(25, combat.score / 12)
        let experience = Int(
            Double(baseExperience) * (1 + boostMagnitude(.experienceBoost))
        )
        let completedResult = MatchResult(
            didWin: didWin,
            totalDamage: combat.totalDamage,
            highestStyleRank: combat.styleRank,
            totalScore: combat.score,
            earnedExperience: experience
        )
        result = completedResult
        apply(result: completedResult)
        progress.activeBoostIDs.removeAll()
        saveProgress()
        screen = .results
    }
    func setLanguage(_ language: AppLanguage) {
        appLanguage = language
        UserDefaults.standard.set(
            language.rawValue,
            forKey: "styleTrigger.appLanguage"
        )
    }

    func setSoundEnabled(_ enabled: Bool) {
        progress.isSoundEnabled = enabled
        music.setEnabled(enabled)
        saveProgress()
    }
    func setHapticsEnabled(_ enabled: Bool) {
        progress.isHapticsEnabled = enabled
        saveProgress()
    }
    func setTargetFrameRate(_ value: Int) {
        progress.targetFrameRate = value == 30 ? 30 : 60
        saveProgress()
    }
    func setGraphicsQuality(_ quality: GraphicsQuality) {
        progress.graphicsQuality = quality
        saveProgress()
    }
    func setCombatEffectsEnabled(_ enabled: Bool) {
        progress.combatEffectsEnabled = enabled
        saveProgress()
    }
    func setScreenShakeEnabled(_ enabled: Bool) {
        progress.screenShakeEnabled = enabled
        saveProgress()
    }
    @discardableResult
    func purchase(_ item: ShopItem) -> Bool {
        guard progress.styleShards >= item.price else { return false }
        if item.productType == .combo,
            let comboID = item.comboID,
            progress.purchasedComboIDs.contains(comboID)
        {
            return false
        }
        progress.styleShards -= item.price
        if item.productType == .combo, let comboID = item.comboID {
            progress.purchasedComboIDs.insert(comboID)
        } else {
            progress.consumableInventory[item.id, default: 0] += 1
        }
        saveProgress()
        return true
    }
    func toggleBoost(_ item: ShopItem) {
        guard item.productType == .consumable, item.effect != .revive else {
            return
        }
        if progress.activeBoostIDs.remove(item.id) != nil {
            progress.consumableInventory[item.id, default: 0] += 1
        } else if progress.consumableInventory[item.id, default: 0] > 0 {
            progress.consumableInventory[item.id, default: 0] -= 1
            progress.activeBoostIDs.insert(item.id)
        }
        saveProgress()
    }
    func consumeRevive() -> Bool {
        guard reviveCount > 0 else { return false }
        progress.consumableInventory["revive-core", default: 0] -= 1
        isRevivePromptPresented = false
        saveProgress()
        return true
    }
    func declineRevive() {
        isRevivePromptPresented = false
        finishMatch(didWin: false)
    }
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                guard !Task.isCancelled, let self, self.screen == .combat else {
                    return
                }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                }
                if self.remainingSeconds == 0 {
                    self.finishMatch(
                        didWin: self.combat.enemyHealth
                            < self.combat.playerHealth
                    )
                    return
                }
            }
        }
    }
    private func apply(result: MatchResult) {
        let characterID = progress.selectedCharacterID
        progress.characterExperience[characterID, default: 0] +=
            result.earnedExperience
        progress.highScores[selectedMode] = max(
            progress.highScores[selectedMode, default: 0],
            result.totalScore
        )
        progress.styleShards += max(20, result.totalScore / 40)
        applyConfiguredUnlocks()

        if selectedMode == .story,
            result.didWin,
            let chapter = story.selectedChapter,
            chapter.number == progress.storyChapter
        {

            progress.styleShards += chapter.rewardShards

            if chapter.number < story.chapters.count {
                progress.storyChapter = chapter.number + 1
            } else {
                progress.storyChapter = story.chapters.count + 1
            }

            applyConfiguredUnlocks()
        }

        if selectedMode == .timedEvent && result.didWin {
            progress.eventCurrency += max(1, result.totalScore / 500)
            if let rewardID = currentEvent?.rewardSkinIDs.first(where: {
                !progress.unlockedSkinIDs.contains($0)
            }) {
                progress.unlockedSkinIDs.insert(rewardID)
            }
        }
        saveProgress()
    }
    private func applyConfiguredUnlocks() {
        guard let modes = content?.progression.modes else { return }
        for mode in modes {
            if mode.unlockedByDefault
                || (mode.unlockAfterStoryChapter ?? .max)
                    <= progress.storyChapter
            {
                progress.unlockedModes.insert(mode.id)
            }
        }
        guard let content else { return }

        for weapon in content.weapons where weapon.unlockedByDefault {
            progress.unlockedWeaponIDs.insert(weapon.id)
        }

        for character in content.characters
        where character.unlocked || accountLevel >= character.unlockLevel {
            progress.unlockedCharacterIDs.insert(character.id)

            if let defaultSkin = character.unlockedSkins.first {
                progress.unlockedSkinIDs.insert(defaultSkin)
                progress.selectedSkinByCharacter[
                    character.id,
                    default: defaultSkin
                ] = progress.selectedSkinByCharacter[character.id] ?? defaultSkin
            }

            for weaponID in character.defaultWeaponIDs {
                progress.unlockedWeaponIDs.insert(weaponID)
            }

            let availableWeaponIDs = character.compatibleWeaponIDs.filter { id in
                content.weapons.first(where: { $0.id == id })?
                    .unlockedByDefault == true
                    || character.defaultWeaponIDs.contains(id)
            }
            progress.equippedWeaponIDsByCharacter[
                character.id,
                default: availableWeaponIDs
            ] = progress.equippedWeaponIDsByCharacter[character.id]
                ?? availableWeaponIDs
        }
    }
    private func repairProgressReferences() {
        guard let content else { return }
        if !content.characters.contains(where: {
            $0.id == progress.selectedCharacterID && isCharacterUnlocked($0)
        }),
            let first = content.characters.first(where: {
                isCharacterUnlocked($0)
            })
        {
            progress.selectedCharacterID = first.id
        }

        if !content.story.arenas.contains(where: {
            $0.id == progress.selectedEnvironmentID
        }), let firstArenaID = content.story.arenas.first?.id {
            progress.selectedEnvironmentID = firstArenaID
        }

        repairSelectedLoadout()
        saveProgress()
    }

    private func repairSelectedLoadout() {
        guard let character = selectedCharacter, let content else { return }
        let validIDs = Set(content.weapons.map(\.id))
        let compatibleIDs = Set(character.compatibleWeaponIDs)
        let allowed: (String) -> Bool = {
            validIDs.contains($0) && compatibleIDs.contains($0)
                && self.progress.unlockedWeaponIDs.contains($0)
        }
        var equipped =
            progress.equippedWeaponIDsByCharacter[character.id]
            ?? character.defaultWeaponIDs
        var seen = Set<String>()
        equipped = equipped.filter { allowed($0) && seen.insert($0).inserted }
        if equipped.isEmpty,
            let fallback = character.defaultWeaponIDs.first(where: allowed)
                ?? character.compatibleWeaponIDs.first(where: allowed)
        {
            equipped = [fallback]
        }
        progress.equippedWeaponIDsByCharacter[character.id] = Array(
            equipped.prefix(3)
        )
        if !equipped.contains(progress.selectedWeaponID),
            let first = equipped.first
        {
            progress.selectedWeaponID = first
        }
        let characterSkins = skins(for: character)
        if !characterSkins.contains(where: {
            $0.id == progress.selectedSkinByCharacter[character.id]
                && progress.unlockedSkinIDs.contains($0.id)
        }),
            let first = characterSkins.first(where: {
                progress.unlockedSkinIDs.contains($0.id)
            })
        {
            progress.selectedSkinByCharacter[character.id] = first.id
        }
    }

    private func saveProgress() {
        let snapshot = progress
        let previous = saveTask
        saveTask = Task { [progressionStore] in
            // Wait for the previous save to finish, preserving write order.
            await previous?.value
            // Do not skip this snapshot if another save was already queued:
            // the subsequent snapshot will overwrite it in sequence.
            try? await progressionStore.save(snapshot)
        }
    }
}
