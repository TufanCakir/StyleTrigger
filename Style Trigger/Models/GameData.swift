//
//  GameData.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation

nonisolated enum BodyStyle: String, Codable, CaseIterable, Sendable {

    case slim, athletic, heavy, armored, agile

}

nonisolated enum HelmetStyle: String, Codable, CaseIterable, Sendable {

    case angular, rounded, pointed, horned, masked, visor

}

nonisolated enum ArmorStyle: String, Codable, CaseIterable, Sendable {

    case light, tactical, plated, ceremonial, shadow

}

nonisolated enum WeaponType: String, Codable, CaseIterable, Sendable {

    case sword

    case greatsword

    case dualBlades

    case katana

    case crossbow

    case nunchaku

    case gauntlets

    case scythe

    case spear

    case energyBlade

}

nonisolated enum WeaponAnimationType: String, Codable, Sendable {

    case quickSlash

    case heavySlash

    case alternating

    case precision

    case projectile

    case spinning

    case boxing

    case sweeping

    case thrusting

    case energy

}

nonisolated struct CharacterAppearance: Codable, Hashable, Sendable {

    let primaryColor: String

    let secondaryColor: String

    let visorColor: String

    let bodyStyle: BodyStyle

    let helmetStyle: HelmetStyle

    let armorStyle: ArmorStyle

    let weaponStyle: WeaponType

    let weaponColor: String

    let glowIntensity: Double

    let outlineWidth: Double

    let bodyScale: Double

    let weaponScale: Double

}

nonisolated struct AnimationProfile: Codable, Hashable, Sendable {

    let idleSpeed: Double

    let attackSpeed: Double

    let movementBounce: Double

    let trailLength: Double

}

nonisolated struct GameCharacter: Codable, Identifiable, Hashable, Sendable {

    let id: String

    let name: String

    let description: String

    let unlocked: Bool

    let baseComboList: [String]

    let unlockedSkins: [String]

    let appearance: CharacterAppearance

    let compatibleWeaponIDs: [String]

    let defaultWeaponIDs: [String]

    let animationProfile: AnimationProfile

}

nonisolated struct CharacterSkin: Codable, Identifiable, Hashable, Sendable {

    let id: String

    let characterID: String

    let name: String

    let unlockedByDefault: Bool

    let appearance: CharacterAppearance

    let particleStyle: String

}

nonisolated struct Weapon: Codable, Identifiable, Hashable, Sendable {

    let id: String

    let name: String

    let type: WeaponType

    let visualStyle: String

    let damage: Int

    let attackSpeed: Double

    let range: Double

    let associatedCombos: [String]

    let animationType: WeaponAnimationType

    let hitEffect: String

    let particleEffect: String

    let unlockedByDefault: Bool

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

nonisolated enum GraphicsQuality: String, Codable, CaseIterable, Identifiable,
    Sendable
{

    case performance

    case balanced

    case ultra

    var id: String { rawValue }

    var displayName: String { rawValue.uppercased() }

    var particleMultiplier: Double {

        switch self {

        case .performance: 0.35

        case .balanced: 0.7

        case .ultra: 1

        }

    }

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

    var unlockedCharacterIDs: Set<String>

    var unlockedWeaponIDs: Set<String>

    var unlockedSkinIDs: Set<String>

    var selectedSkinByCharacter: [String: String]

    var equippedWeaponIDsByCharacter: [String: [String]]

    var targetFrameRate: Int

    var graphicsQuality: GraphicsQuality

    var combatEffectsEnabled: Bool

    var screenShakeEnabled: Bool

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

        isHapticsEnabled: true,

        unlockedCharacterIDs: ["vex"],

        unlockedWeaponIDs: ["neon-edge", "standard-sword"],

        unlockedSkinIDs: ["vex-default"],

        selectedSkinByCharacter: ["vex": "vex-default"],

        equippedWeaponIDsByCharacter: ["vex": ["neon-edge", "standard-sword"]],

        targetFrameRate: 60,

        graphicsQuality: .balanced,

        combatEffectsEnabled: true,

        screenShakeEnabled: true

    )

    private enum CodingKeys: String, CodingKey {

        case storyChapter, unlockedModes, characterExperience, highScores

        case eventCurrency, selectedCharacterID, selectedWeaponID

        case selectedEnvironmentID, isSoundEnabled, isHapticsEnabled

        case unlockedCharacterIDs, unlockedWeaponIDs, unlockedSkinIDs

        case selectedSkinByCharacter, equippedWeaponIDsByCharacter

        case targetFrameRate, graphicsQuality, combatEffectsEnabled

        case screenShakeEnabled

    }

    init(

        storyChapter: Int,

        unlockedModes: Set<GameModeKind>,

        characterExperience: [String: Int],

        highScores: [GameModeKind: Int],

        eventCurrency: Int,

        selectedCharacterID: String,

        selectedWeaponID: String,

        selectedEnvironmentID: String,

        isSoundEnabled: Bool,

        isHapticsEnabled: Bool,

        unlockedCharacterIDs: Set<String>,

        unlockedWeaponIDs: Set<String>,

        unlockedSkinIDs: Set<String>,

        selectedSkinByCharacter: [String: String],

        equippedWeaponIDsByCharacter: [String: [String]],

        targetFrameRate: Int,

        graphicsQuality: GraphicsQuality,

        combatEffectsEnabled: Bool,

        screenShakeEnabled: Bool

    ) {

        self.storyChapter = storyChapter

        self.unlockedModes = unlockedModes

        self.characterExperience = characterExperience

        self.highScores = highScores

        self.eventCurrency = eventCurrency

        self.selectedCharacterID = selectedCharacterID

        self.selectedWeaponID = selectedWeaponID

        self.selectedEnvironmentID = selectedEnvironmentID

        self.isSoundEnabled = isSoundEnabled

        self.isHapticsEnabled = isHapticsEnabled

        self.unlockedCharacterIDs = unlockedCharacterIDs

        self.unlockedWeaponIDs = unlockedWeaponIDs

        self.unlockedSkinIDs = unlockedSkinIDs

        self.selectedSkinByCharacter = selectedSkinByCharacter

        self.equippedWeaponIDsByCharacter = equippedWeaponIDsByCharacter

        self.targetFrameRate = targetFrameRate

        self.graphicsQuality = graphicsQuality

        self.combatEffectsEnabled = combatEffectsEnabled

        self.screenShakeEnabled = screenShakeEnabled

    }

    init(from decoder: Decoder) throws {

        let defaults = Self.initial

        let container = try decoder.container(keyedBy: CodingKeys.self)

        storyChapter =
            try container.decodeIfPresent(Int.self, forKey: .storyChapter)
            ?? defaults.storyChapter

        unlockedModes =
            try container.decodeIfPresent(
                Set<GameModeKind>.self,
                forKey: .unlockedModes
            ) ?? defaults.unlockedModes

        characterExperience =
            try container.decodeIfPresent(
                [String: Int].self,
                forKey: .characterExperience
            ) ?? defaults.characterExperience

        highScores =
            try container.decodeIfPresent(
                [GameModeKind: Int].self,
                forKey: .highScores
            ) ?? defaults.highScores

        eventCurrency =
            try container.decodeIfPresent(Int.self, forKey: .eventCurrency)
            ?? defaults.eventCurrency

        selectedCharacterID =
            try container.decodeIfPresent(
                String.self,
                forKey: .selectedCharacterID
            ) ?? defaults.selectedCharacterID

        selectedWeaponID =
            try container.decodeIfPresent(
                String.self,
                forKey: .selectedWeaponID
            ) ?? defaults.selectedWeaponID

        selectedEnvironmentID =
            try container.decodeIfPresent(
                String.self,
                forKey: .selectedEnvironmentID
            ) ?? defaults.selectedEnvironmentID

        isSoundEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .isSoundEnabled)
            ?? true

        isHapticsEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .isHapticsEnabled)
            ?? true

        unlockedCharacterIDs =
            try container.decodeIfPresent(
                Set<String>.self,
                forKey: .unlockedCharacterIDs
            ) ?? defaults.unlockedCharacterIDs

        unlockedWeaponIDs =
            try container.decodeIfPresent(
                Set<String>.self,
                forKey: .unlockedWeaponIDs
            ) ?? defaults.unlockedWeaponIDs

        unlockedSkinIDs =
            try container.decodeIfPresent(
                Set<String>.self,
                forKey: .unlockedSkinIDs
            ) ?? defaults.unlockedSkinIDs

        selectedSkinByCharacter =
            try container.decodeIfPresent(
                [String: String].self,
                forKey: .selectedSkinByCharacter
            ) ?? defaults.selectedSkinByCharacter

        equippedWeaponIDsByCharacter =
            try container.decodeIfPresent(
                [String: [String]].self,
                forKey: .equippedWeaponIDsByCharacter
            ) ?? defaults.equippedWeaponIDsByCharacter

        targetFrameRate =
            try container.decodeIfPresent(Int.self, forKey: .targetFrameRate)
            ?? 60

        graphicsQuality =
            try container.decodeIfPresent(
                GraphicsQuality.self,
                forKey: .graphicsQuality
            ) ?? .balanced

        combatEffectsEnabled =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .combatEffectsEnabled
            ) ?? true

        screenShakeEnabled =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .screenShakeEnabled
            ) ?? true

    }

}

nonisolated enum StyleRank: Int, Codable, CaseIterable, Comparable, Sendable {

    case d, c, b, a, s, ss, sss

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

    let skins: [CharacterSkin]

    let weapons: [Weapon]

    let combos: [ComboDefinition]

    let progression: ProgressionConfiguration

    let enemies: [EnemyDefinition]

    let events: [TimedEventDefinition]

}

// MARK: - Derived values (not persisted)

extension PlayerProgress {
    /// Returns a nonnegative score even when an older save contains invalid values.
    func highScore(for mode: GameModeKind) -> Int {
        max(0, highScores[mode, default: 0])
    }

    func experience(for characterID: String) -> Int {
        max(0, characterExperience[characterID, default: 0])
    }

    func isWeaponUnlocked(_ weaponID: String) -> Bool {
        unlockedWeaponIDs.contains(weaponID)
    }
}

extension CombatSnapshot {
    var clampedPlayerHealth: Double { Self.clampHealth(playerHealth) }
    var clampedEnemyHealth: Double { Self.clampHealth(enemyHealth) }

    private static func clampHealth(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }
}

extension StyleRank {
    /// Convenient for HUD presentation and rank progression.
    var next: StyleRank? { StyleRank(rawValue: rawValue + 1) }
    var previous: StyleRank? { StyleRank(rawValue: rawValue - 1) }
}
