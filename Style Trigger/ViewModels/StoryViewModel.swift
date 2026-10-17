//
//  StoryViewModel.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class StoryViewModel {
    private(set) var chapters: [StoryChapter] = []
    private(set) var arenas: [StoryArena] = []
    private(set) var enemies: [EnemyDefinition] = []
    private(set) var selectedChapterID: StoryChapter.ID?
    var isPresented = false

    var availableChapters: [StoryChapter] {
        chapters.sorted { $0.number < $1.number }
    }

    var selectedChapter: StoryChapter? {
        guard let selectedChapterID else { return nil }
        return chapters.first { $0.id == selectedChapterID }
    }

    func configure(with story: StoryContent, enemies: [EnemyDefinition]) {
        chapters = story.chapters.sorted { $0.number < $1.number }
        arenas = story.arenas
        self.enemies = enemies

        if let selectedChapterID,
            !chapters.contains(where: { $0.id == selectedChapterID })
        {
            self.selectedChapterID = nil
        }
    }

    func present() {
        selectedChapterID = nil
        isPresented = true
    }

    func dismiss() {
        isPresented = false
        selectedChapterID = nil
    }

    func select(_ chapter: StoryChapter, unlockedChapter: Int) -> Bool {
        guard chapters.contains(chapter),
            isUnlocked(chapter, unlockedChapter: unlockedChapter)
        else {
            return false
        }

        selectedChapterID = chapter.id
        isPresented = false
        return true
    }

    func isUnlocked(_ chapter: StoryChapter, unlockedChapter: Int) -> Bool {
        chapter.number <= unlockedChapter
    }

    func isCompleted(_ chapter: StoryChapter, unlockedChapter: Int) -> Bool {
        chapter.number < unlockedChapter
    }

    func arena(for chapter: StoryChapter) -> StoryArena? {
        arenas.first { $0.id == chapter.environmentID }
    }

    func enemies(for chapter: StoryChapter) -> [EnemyDefinition] {
        let definitionsByID = Dictionary(
            uniqueKeysWithValues: enemies.map { ($0.id, $0) }
        )
        return chapter.enemyIDs.compactMap { definitionsByID[$0] }
    }
}
