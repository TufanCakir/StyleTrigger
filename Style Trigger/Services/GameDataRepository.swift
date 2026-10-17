//
//  GameDataRepository.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation

enum GameDataError: LocalizedError {
    case missingResource(String)
    case invalidResource(String, Error)
    case invalidReferences([String])

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Missing game data resource: \(name).json"
        case .invalidResource(let name, let error):
            return "Could not load \(name).json: \(error.localizedDescription)"
        case .invalidReferences(let messages):
            return "Invalid game data: \(messages.joined(separator: "; "))"
        }
    }
}

struct GameDataRepository {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func load() throws -> GameContent {
        let content = GameContent(
            characters: try decode("characters", as: [GameCharacter].self),
            skins: try decode("skins", as: [CharacterSkin].self),
            weapons: try decode("weapons", as: [Weapon].self),
            combos: try decode("combos", as: [ComboDefinition].self),
            progression: try decode(
                "progression",
                as: ProgressionConfiguration.self
            ),
            enemies: try decode("enemies", as: [EnemyDefinition].self),
            story: try decode("story", as: StoryContent.self),
            events: try decode("events", as: [TimedEventDefinition].self),
            shopItems: try decode("shop", as: [ShopItem].self),
            accountTitles: try decode(
                "titles",
                as: [AccountTitleDefinition].self
            ),
            germanLocalization: try decode(
                "localization_de",
                as: [String: String].self
            )
        )
        try validate(content)
        return content
    }

    private func decode<Value: Decodable>(_ name: String, as type: Value.Type)
        throws -> Value
    {
        guard let url = bundle.url(forResource: name, withExtension: "json")
        else {
            throw GameDataError.missingResource(name)
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            throw GameDataError.invalidResource(name, error)
        }
    }

    private func validate(_ content: GameContent) throws {
        var errors: [String] = []
        checkUnique(
            content.characters.map(\.id),
            category: "character",
            errors: &errors
        )
        checkUnique(content.skins.map(\.id), category: "skin", errors: &errors)
        checkUnique(
            content.weapons.map(\.id),
            category: "weapon",
            errors: &errors
        )
        checkUnique(
            content.combos.map(\.id),
            category: "combo",
            errors: &errors
        )
        checkUnique(
            content.enemies.map(\.id),
            category: "enemy",
            errors: &errors
        )
        checkUnique(
            content.story.chapters.map(\.id),
            category: "story chapter",
            errors: &errors
        )
        checkUnique(
            content.story.arenas.map(\.id),
            category: "story arena",
            errors: &errors
        )
        checkUnique(
            content.events.map(\.id),
            category: "event",
            errors: &errors
        )
        checkUnique(
            content.shopItems.map(\.id),
            category: "shop item",
            errors: &errors
        )
        checkUnique(
            content.accountTitles.map(\.id),
            category: "account title",
            errors: &errors
        )
        checkUnique(
            content.progression.modes.map(\.id.rawValue),
            category: "mode",
            errors: &errors
        )

        let characterIDs = Set(content.characters.map(\.id))
        let skinIDs = Set(content.skins.map(\.id))
        let weaponIDs = Set(content.weapons.map(\.id))
        let comboIDs = Set(content.combos.map(\.id))
        let enemyIDs = Set(content.enemies.map(\.id))
        let arenaIDs = Set(content.story.arenas.map(\.id))

        for chapter in content.story.chapters {
            if !arenaIDs.contains(chapter.environmentID) {
                errors.append(
                    "\(chapter.id) references missing arena \(chapter.environmentID)"
                )
            }
            checkReferences(
                chapter.enemyIDs,
                valid: enemyIDs,
                owner: chapter.id,
                kind: "enemy",
                errors: &errors
            )
            if chapter.enemyIDs.isEmpty {
                errors.append("\(chapter.id) has no enemies")
            }
        }

        let orderedChapterNumbers = content.story.chapters.map(\.number)
            .sorted()
        let expectedChapterNumbers = Array(
            1...max(1, content.story.chapters.count)
        )
        if content.story.chapters.isEmpty {
            errors.append("no story chapters configured")
        } else if orderedChapterNumbers != expectedChapterNumbers {
            errors.append("story chapter numbers must be unique and contiguous")
        }

        for character in content.characters {
            if character.unlockLevel < 1 {
                errors.append("\(character.id) has invalid unlock level")
            }
            checkReferences(
                character.unlockedSkins,
                valid: skinIDs,
                owner: character.id,
                kind: "skin",
                errors: &errors
            )
            checkReferences(
                character.compatibleWeaponIDs,
                valid: weaponIDs,
                owner: character.id,
                kind: "weapon",
                errors: &errors
            )
            checkReferences(
                character.defaultWeaponIDs,
                valid: weaponIDs,
                owner: character.id,
                kind: "default weapon",
                errors: &errors
            )
            checkReferences(
                character.baseComboList,
                valid: comboIDs,
                owner: character.id,
                kind: "combo",
                errors: &errors
            )

            let compatible = Set(character.compatibleWeaponIDs)
            for id in character.defaultWeaponIDs where !compatible.contains(id)
            {
                errors.append(
                    "\(character.id) has incompatible default weapon \(id)"
                )
            }
            for id in character.unlockedSkins {
                if let skin = content.skins.first(where: { $0.id == id }),
                    skin.characterID != character.id
                {
                    errors.append(
                        "\(character.id) references skin \(id) belonging to \(skin.characterID)"
                    )
                }
            }
        }

        for skin in content.skins where !characterIDs.contains(skin.characterID)
        {
            errors.append(
                "\(skin.id) references missing character \(skin.characterID)"
            )
        }
        for weapon in content.weapons {
            checkReferences(
                weapon.associatedCombos,
                valid: comboIDs,
                owner: weapon.id,
                kind: "combo",
                errors: &errors
            )
        }
        for event in content.events {
            checkReferences(
                event.rewardSkinIDs,
                valid: skinIDs,
                owner: event.id,
                kind: "reward skin",
                errors: &errors
            )
        }
        for item in content.shopItems {
            if item.productType == .combo,
                let comboID = item.comboID,
                !comboIDs.contains(comboID)
            {
                errors.append("\(item.id) references missing combo \(comboID)")
            }
            if item.productType == .consumable, item.effect == nil {
                errors.append("\(item.id) has no consumable effect")
            }
        }

        if content.characters.isEmpty {
            errors.append("no characters configured")
        }
        if content.weapons.isEmpty { errors.append("no weapons configured") }
        if content.enemies.isEmpty { errors.append("no enemies configured") }
        if content.progression.modes.isEmpty {
            errors.append("no game modes configured")
        }

        guard errors.isEmpty else {
            throw GameDataError.invalidReferences(errors.sorted())
        }
    }

    private func checkUnique(
        _ ids: [String],
        category: String,
        errors: inout [String]
    ) {
        var seen = Set<String>()
        var duplicates = Set<String>()
        for id in ids {
            if id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("empty \(category) id")
            } else if !seen.insert(id).inserted {
                duplicates.insert(id)
            }
        }
        for id in duplicates.sorted() {
            errors.append("duplicate \(category) id \(id)")
        }
    }

    private func checkReferences(
        _ ids: [String],
        valid: Set<String>,
        owner: String,
        kind: String,
        errors: inout [String]
    ) {
        for id in Set(ids).sorted() where !valid.contains(id) {
            errors.append("\(owner) references missing \(kind) \(id)")
        }
    }
}

actor ProgressionStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        fileURL = directory.appendingPathComponent(
            "style-trigger-progress.json"
        )
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    // Keep the existing non-throwing API for StyleTriggerViewModel.
    // Corrupt saves are retained for diagnosis rather than overwritten here.
    func load() -> PlayerProgress {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .initial
        }
        do {
            return try decoder.decode(
                PlayerProgress.self,
                from: Data(contentsOf: fileURL)
            )
        } catch {
            NSLog(
                "Style Trigger: Could not load saved progress: %@",
                String(describing: error)
            )
            return .initial
        }
    }

    func save(_ progress: PlayerProgress) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(progress)
        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtectionUnlessOpen]
        )
    }
}
