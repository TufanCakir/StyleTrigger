import SwiftUI

struct CharacterRosterView: View {
    let characters: [GameCharacter]
    let selectedCharacterID: GameCharacter.ID
    let accountLevel: Int
    let isUnlocked: (GameCharacter) -> Bool
    let select: (GameCharacter) -> Void
    let showDetails: (GameCharacter) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 104, maximum: 132), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(characters) { character in
                CharacterRosterCard(
                    character: character,
                    accountLevel: accountLevel,
                    isSelected: selectedCharacterID == character.id,
                    isUnlocked: isUnlocked(character),
                    select: { select(character) },
                    showDetails: { showDetails(character) }
                )
            }
        }
    }
}

private struct CharacterRosterCard: View {
    let character: GameCharacter
    let accountLevel: Int
    let isSelected: Bool
    let isUnlocked: Bool
    let select: () -> Void
    let showDetails: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                StyleTriggerFighterArtwork(
                    name: character.name,
                    appearance: character.appearance
                )
                .frame(height: 78)
                .opacity(isUnlocked ? 1 : 0.35)

                Button(action: showDetails) {
                    Image(systemName: "info.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            StyleTriggerPalette.silver,
                            StyleTriggerPalette.panel
                        )
                        .frame(width: 30, height: 30)
                }
                .accessibilityLabel("FIGHTER INFO")
            }

            Text(character.name)
                .font(.caption.monospaced().weight(.black))
                .lineLimit(1)

            Label(statusTitle, systemImage: statusIcon)
                .font(.caption2.monospaced().weight(.bold))
                .foregroundStyle(statusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(7)
        .frame(maxWidth: .infinity)
        .background(
            StyleTriggerPalette.panel.opacity(0.92),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected
                        ? StyleTriggerPalette.cyan
                        : .white.opacity(0.1),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            guard isUnlocked else { return }
            select()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(
            isUnlocked
                ? "Select this fighter."
                : "Unlocks at account level \(character.unlockLevel)."
        )
    }

    private var statusTitle: String {
        if isSelected { return "SELECTED" }
        if isUnlocked { return "READY" }
        return "LEVEL \(character.unlockLevel)"
    }

    private var statusIcon: String {
        if isSelected { return "checkmark.circle.fill" }
        return isUnlocked ? "bolt.fill" : "lock.fill"
    }

    private var statusColor: Color {
        if isSelected { return StyleTriggerPalette.cyan }
        return isUnlocked ? StyleTriggerPalette.silver : StyleTriggerPalette.magenta
    }
}
