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
    var selectedMode: GameModeKind = .arcade
    var selectedDifficulty = "NORMAL"
    var selectedTeamSize = 1
    var menuPage = 1
    private let repository = GameDataRepository()
    private let progressionStore = ProgressionStore()
    private let music = MetalMusicService()
    let multiplayer = GameCenterMultiplayerService()
    private var timerTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var loadInProgress = false
    private static let environmentIDs = [
        "neon-rooftop", "void-cathedral", "chrome-subway",
    ]
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
            || progress.unlockedCharacterIDs.contains(character.id)
    }
    var availableCombos: [ComboDefinition] {
        guard let content, let weapon = selectedWeapon else { return [] }
        let weaponIDs = Set(weapon.associatedCombos)
        return content.combos.filter { weaponIDs.contains($0.id) }
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
        guard Self.environmentIDs.contains(id) else { return }
        progress.selectedEnvironmentID = id
        saveProgress()
    }
    func chooseRandomEnvironment() {
        progress.selectedEnvironmentID =
            Self.environmentIDs.randomElement() ?? Self.environmentIDs[0]
        saveProgress()
    }
    func openLobby(for mode: GameModeKind) {
        guard progress.unlockedModes.contains(mode) else { return }
        selectedMode = mode
        screen = .lobby
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
            isSelectedModeUnlocked,
            let duration = selectedModeDefinition?.matchDuration
        else {
            return
        }
        remainingSeconds = duration
        combat = .initial
        result = nil
        screen = .combat
        startTimer()
    }
    func startSelectedMatch() {
        if selectedMode == .versus {
            multiplayer.beginMatchmaking(teamSize: selectedTeamSize)
        } else {
            startMatch()
        }
    }
    func receiveCombatSnapshot(_ snapshot: CombatSnapshot) {
        guard screen == .combat else { return }
        combat = snapshot
        if snapshot.playerHealth <= 0 {
            finishMatch(didWin: false)
        } else if snapshot.enemyHealth <= 0 && selectedMode != .survival {
            finishMatch(didWin: true)
        }
    }
    func finishMatch(didWin: Bool) {
        guard screen == .combat else { return }
        timerTask?.cancel()
        timerTask = nil
        let experience = max(25, combat.score / 12)
        let completedResult = MatchResult(
            didWin: didWin,
            totalDamage: combat.totalDamage,
            highestStyleRank: combat.styleRank,
            totalScore: combat.score,
            earnedExperience: experience
        )
        result = completedResult
        apply(result: completedResult)
        screen = .results
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
        if selectedMode == .story && result.didWin {
            progress.storyChapter += 1
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
        for character in content.characters where character.unlocked {
            progress.unlockedCharacterIDs.insert(character.id)
            for skinID in character.unlockedSkins.prefix(1) {
                progress.unlockedSkinIDs.insert(skinID)
            }
            for weaponID in character.defaultWeaponIDs {
                if content.weapons.first(where: { $0.id == weaponID })?
                    .unlockedByDefault == true
                {
                    progress.unlockedWeaponIDs.insert(weaponID)
                }
            }
        }
        for (index, character) in content.characters.enumerated()
        where index < progress.storyChapter {
            progress.unlockedCharacterIDs.insert(character.id)
            if let defaultSkin = character.unlockedSkins.first {
                progress.unlockedSkinIDs.insert(defaultSkin)
                progress.selectedSkinByCharacter[
                    character.id,
                    default: defaultSkin
                ] =
                    progress.selectedSkinByCharacter[character.id]
                    ?? defaultSkin
            }
            for weaponID in character.defaultWeaponIDs {
                progress.unlockedWeaponIDs.insert(weaponID)
            }
            progress.equippedWeaponIDsByCharacter[
                character.id,
                default: character.defaultWeaponIDs
            ] =
                progress.equippedWeaponIDsByCharacter[character.id]
                ?? character.defaultWeaponIDs
        }
        saveProgress()
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

        if !Self.environmentIDs.contains(progress.selectedEnvironmentID) {
            progress.selectedEnvironmentID = Self.environmentIDs[0]
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
