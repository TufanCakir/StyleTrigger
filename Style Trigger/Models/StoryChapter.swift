//
//  StoryChapter.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation

nonisolated struct StoryChapter: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let number: Int
    let title: String
    let description: String
    let briefing: String
    let environmentID: String
    let enemyIDs: [String]
    let difficulty: String
    let rewardShards: Int
}

nonisolated struct StoryArena: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let systemImage: String
}

nonisolated struct StoryContent: Codable, Sendable {
    let chapters: [StoryChapter]
    let arenas: [StoryArena]
}
