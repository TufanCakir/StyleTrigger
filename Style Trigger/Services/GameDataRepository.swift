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

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            "Missing game data resource: \(name).json"
        case .invalidResource(let name, let error):
            "Could not decode \(name).json: \(error.localizedDescription)"
        }
    }
}

struct GameDataRepository {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func load() throws -> GameContent {
        GameContent(
            characters: try decode("characters", as: [GameCharacter].self),
            weapons: try decode("weapons", as: [Weapon].self),
            combos: try decode("combos", as: [ComboDefinition].self),
            progression: try decode(
                "progression",
                as: ProgressionConfiguration.self
            ),
            enemies: try decode("enemies", as: [EnemyDefinition].self),
            events: try decode("events", as: [TimedEventDefinition].self)
        )
    }

    private func decode<Value: Decodable>(_ name: String, as type: Value.Type)
        throws -> Value
    {
        guard let url = bundle.url(forResource: name, withExtension: "json")
        else {
            throw GameDataError.missingResource(name)
        }

        do {
            return try decoder.decode(Value.self, from: Data(contentsOf: url))
        } catch {
            throw GameDataError.invalidResource(name, error)
        }
    }
}

actor ProgressionStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        fileURL = directory.appendingPathComponent(
            "style-trigger-progress.json"
        )
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> PlayerProgress {
        guard let data = try? Data(contentsOf: fileURL),
            let progress = try? decoder.decode(PlayerProgress.self, from: data)
        else {
            return .initial
        }
        return progress
    }

    func save(_ progress: PlayerProgress) throws {
        let data = try encoder.encode(progress)
        try data.write(to: fileURL, options: .atomic)
    }
}
