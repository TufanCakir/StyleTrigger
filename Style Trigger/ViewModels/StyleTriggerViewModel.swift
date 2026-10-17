//
//  StyleTriggerViewModel.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation
import Observation
import SpriteKit

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

    var selectedCharacter: GameCharacter? {
        content?.characters.first { $0.id == progress.selectedCharacterID }
    }

    var selectedWeapon: Weapon? {
        content?.weapons.first { $0.id == progress.selectedWeaponID }
    }

    var availableCombos: [ComboDefinition] {
        guard let content, let weapon = selectedWeapon else { return [] }
        let characterIDs = Set(selectedCharacter?.baseComboList ?? [])
        let weaponIDs = Set(weapon.associatedCombos)
        return content.combos.filter {
            characterIDs.contains($0.id) || weaponIDs.contains($0.id)
        }
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
        do {
            content = try repository.load()
            progress = await progressionStore.load()
            applyConfiguredUnlocks()
            music.setEnabled(progress.isSoundEnabled)
        } catch {
            loadError = error.localizedDescription
        }
    }

    func selectCharacter(_ id: String) {
        guard
            content?.characters.contains(where: { $0.id == id && $0.unlocked })
                == true
        else { return }
        progress.selectedCharacterID = id
        saveProgress()
    }

    func selectWeapon(_ id: String) {
        guard content?.weapons.contains(where: { $0.id == id }) == true else {
            return
        }
        progress.selectedWeaponID = id
        saveProgress()
    }

    func selectEnvironment(_ id: String) {
        progress.selectedEnvironmentID = id
        saveProgress()
    }

    func chooseRandomEnvironment() {
        let environments = ["neon-rooftop", "void-cathedral", "chrome-subway"]
        progress.selectedEnvironmentID =
            environments.randomElement() ?? environments[0]
        saveProgress()
    }

    func openLobby(for mode: GameModeKind) {
        selectedMode = mode
        guard progress.unlockedModes.contains(mode) else { return }
        screen = .lobby
    }

    func returnToMenu() {
        timerTask?.cancel()
        multiplayer.disconnect()
        screen = .menu
        music.setEnabled(progress.isSoundEnabled)
    }

    func startMatch() {
        guard let duration = selectedModeDefinition?.matchDuration else {
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
        let experience = max(25, combat.score / 12)
        result = MatchResult(
            didWin: didWin,
            totalDamage: combat.totalDamage,
            highestStyleRank: combat.styleRank,
            totalScore: combat.score,
            earnedExperience: experience
        )
        apply(result: result!)
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

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, self.screen == .combat else { return }
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
        saveProgress()
    }

    private func saveProgress() {
        let snapshot = progress
        Task {
            try? await progressionStore.save(snapshot)
        }
    }
}
