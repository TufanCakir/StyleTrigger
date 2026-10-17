//
//  GameData.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation

nonisolated struct GameCharacter: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let unlocked: Bool
    let baseComboList: [String]
    let unlockedSkins: [String]
}

nonisolated struct Weapon: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let visualStyle: String
    let associatedCombos: [String]
}

nonisolated enum CombatInput: String, Codable, CaseIterable, Hashable, Sendable
{
    case tap
    case swipeUp
    case swipeDown
    case swipeLeft
    case swipeRight
    case diagonalUpLeft
    case diagonalUpRight
    case diagonalDownLeft
    case diagonalDownRight

    var symbol: String {
        switch self {
        case .tap: "●"
        case .swipeUp: "↑"
        case .swipeDown: "↓"
        case .swipeLeft: "←"
        case .swipeRight: "→"
        case .diagonalUpLeft: "↖"
        case .diagonalUpRight: "↗"
        case .diagonalDownLeft: "↙"
        case .diagonalDownRight: "↘"
        }
    }
}

nonisolated struct ComboDefinition: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let inputSequence: [CombatInput]
    let damage: Int
    let stylePoints: Int
    let isAirLauncher: Bool
}

nonisolated enum GameModeKind: String, Codable, CaseIterable, Identifiable,
    Sendable
{
    case story
    case arcade
    case survival
    case versus
    case timedEvent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .story: "STORY"
        case .arcade: "ARCADE"
        case .survival: "SURVIVAL"
        case .versus: "VERSUS"
        case .timedEvent: "TIMED EVENT"
        }
    }
}

nonisolated struct GameModeDefinition: Codable, Identifiable, Hashable, Sendable
{
    let id: GameModeKind
    let description: String
    let unlockedByDefault: Bool
    let unlockAfterStoryChapter: Int?
    let matchDuration: Int
}

nonisolated struct ProgressionConfiguration: Codable, Hashable, Sendable {
    let storyChapterCount: Int
    let modes: [GameModeDefinition]
    let expPerLevel: Int
}

nonisolated struct EnemyDefinition: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let visualStyle: String
    let baseHealth: Int
    let baseVelocity: Double
    let aggression: Double
}

nonisolated struct TimedEventDefinition: Codable, Identifiable, Hashable,
    Sendable
{
    let id: String
    let name: String
    let description: String
    let endsAt: Date
    let currencyName: String
    let rewardSkinIDs: [String]
}

nonisolated struct PlayerProgress: Codable, Equatable, Sendable {
    var storyChapter: Int
    var unlockedModes: Set<GameModeKind>
    var characterExperience: [String: Int]
    var highScores: [GameModeKind: Int]
    var eventCurrency: Int
    var selectedCharacterID: String
    var selectedWeaponID: String
    var selectedEnvironmentID: String
    var isSoundEnabled: Bool
    var isHapticsEnabled: Bool

    static let initial = PlayerProgress(
        storyChapter: 1,
        unlockedModes: [.story, .arcade],
        characterExperience: [:],
        highScores: [:],
        eventCurrency: 0,
        selectedCharacterID: "vex",
        selectedWeaponID: "neon-edge",
        selectedEnvironmentID: "neon-rooftop",
        isSoundEnabled: true,
        isHapticsEnabled: true
    )
}

nonisolated enum StyleRank: Int, Codable, CaseIterable, Comparable, Sendable {
    case d
    case c
    case b
    case a
    case s
    case ss
    case sss

    static func < (lhs: StyleRank, rhs: StyleRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var letter: String {
        switch self {
        case .d: "D"
        case .c: "C"
        case .b: "B"
        case .a: "A"
        case .s: "S"
        case .ss: "SS"
        case .sss: "SSS"
        }
    }

    var title: String {
        switch self {
        case .d: "Dismal"
        case .c: "Crazy"
        case .b: "Badass"
        case .a: "Apocalyptic"
        case .s: "Savage"
        case .ss: "Sick Skills"
        case .sss: "Smokin’ Sexy Style!"
        }
    }
}

nonisolated struct MatchResult: Equatable, Sendable {
    let didWin: Bool
    let totalDamage: Int
    let highestStyleRank: StyleRank
    let totalScore: Int
    let earnedExperience: Int
}

nonisolated struct CombatSnapshot: Equatable, Sendable {
    let playerHealth: Double
    let enemyHealth: Double
    let comboCount: Int
    let score: Int
    let totalDamage: Int
    let styleRank: StyleRank

    static let initial = CombatSnapshot(
        playerHealth: 1,
        enemyHealth: 1,
        comboCount: 0,
        score: 0,
        totalDamage: 0,
        styleRank: .d
    )
}

nonisolated struct GameContent: Sendable {
    let characters: [GameCharacter]
    let weapons: [Weapon]
    let combos: [ComboDefinition]
    let progression: ProgressionConfiguration
    let enemies: [EnemyDefinition]
    let events: [TimedEventDefinition]
}
