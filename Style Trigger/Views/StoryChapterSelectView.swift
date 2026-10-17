//
//  StorySelectionScreen.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SwiftUI

struct StorySelectionScreen: View {
    @Bindable var story: StoryViewModel
    let unlockedChapter: Int
    let selectChapter: (StoryChapter) -> Void

    var body: some View {
        ZStack {
            StyleTriggerBackground()

            VStack(spacing: 12) {
                header
                NeonHeader(
                    kicker: "STORY MODE",
                    title: "CHAPTER SELECT",
                    icon: "book.closed.fill"
                )
                StoryChapterSelectView(
                    story: story,
                    unlockedChapter: unlockedChapter,
                    selectChapter: selectChapter
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            Button {
                story.dismiss()
            } label: {
                Label("BACK", systemImage: "chevron.left")
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct StoryChapterSelectView: View {
    let story: StoryViewModel
    let unlockedChapter: Int
    let selectChapter: (StoryChapter) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(story.availableChapters) { chapter in
                    StoryChapterCard(
                        chapter: chapter,
                        arena: story.arena(for: chapter),
                        enemies: story.enemies(for: chapter),
                        isUnlocked: story.isUnlocked(
                            chapter,
                            unlockedChapter: unlockedChapter
                        ),
                        isCompleted: story.isCompleted(
                            chapter,
                            unlockedChapter: unlockedChapter
                        ),
                        select: { selectChapter(chapter) }
                    )
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }
}

private struct StoryChapterCard: View {
    let chapter: StoryChapter
    let arena: StoryArena?
    let enemies: [EnemyDefinition]
    let isUnlocked: Bool
    let isCompleted: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Text(
                        chapter.number,
                        format: .number.precision(.integerLength(2))
                    )
                    .font(.title.monospaced().weight(.black))
                    .foregroundStyle(
                        isUnlocked ? StyleTriggerPalette.cyan : .gray
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.title)
                            .font(.headline.monospaced().weight(.black))
                        Text(chapter.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: statusIcon)
                        .foregroundStyle(
                            isUnlocked ? StyleTriggerPalette.cyan : .gray
                        )
                }

                Divider().overlay(StyleTriggerPalette.cyan.opacity(0.25))

                Label(
                    arena?.name ?? chapter.environmentID,
                    systemImage: arena?.systemImage ?? "map"
                )
                .font(.caption.monospaced().weight(.bold))

                Label(enemyNames, systemImage: "person.3.fill")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)

                HStack {
                    Text(statusTitle)
                    Spacer()
                    Text("+\(chapter.rewardShards) SHARDS")
                }
                .font(.caption2.monospaced().weight(.bold))
                .foregroundStyle(
                    isUnlocked
                        ? StyleTriggerPalette.cyan : StyleTriggerPalette.magenta
                )
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                StyleTriggerPalette.panel,
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1 : 0.55)
        .accessibilityHint(chapter.briefing)
    }

    private var enemyNames: String {
        enemies.isEmpty
            ? "UNKNOWN OPPOSITION"
            : enemies.map(\.name).joined(separator: " • ")
    }

    private var statusTitle: String {
        isCompleted ? "COMPLETED" : isUnlocked ? "AVAILABLE" : "LOCKED"
    }

    private var statusIcon: String {
        isCompleted
            ? "checkmark.circle.fill"
            : isUnlocked ? "chevron.right" : "lock.fill"
    }
}
