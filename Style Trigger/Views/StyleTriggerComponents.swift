//
//  StyleTriggerComponents.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SwiftUI

enum StyleTriggerPalette {
    static let background = Color(hex: "0B0B0F")
    static let panel = Color(hex: "161924")
    static let raisedPanel = Color(hex: "1D2130")
    static let cyan = Color(hex: "00F6FF")
    static let magenta = Color(hex: "FF007F")
    static let silver = Color(hex: "F5F5FA")
    static let steel = Color(hex: "D1D5DB")
    static let darkSteel = Color(hex: "6B7280")
}

enum StyleTriggerMetrics {
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
    static let cardSpacing: CGFloat = 10
    static let cornerRadius: CGFloat = 14
    static let compactCornerRadius: CGFloat = 10
    static let minimumTapTarget: CGFloat = 44
}

struct StyleTriggerTab: Identifiable {
    let id: Int
    let title: LocalizedStringResource
    let icon: String
}

struct StyleTriggerTopTabBar: View {
    @Binding var selection: Int
    let tabs: [StyleTriggerTab]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                Button {
                    if reduceMotion {
                        selection = tab.id
                    } else {
                        withAnimation(.snappy(duration: 0.22)) {
                            selection = tab.id
                        }
                    }
                } label: {
                    VStack(spacing: 5) {
                        Label(tab.title, systemImage: tab.icon)
                            .font(.caption2.monospaced().weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                        Capsule()
                            .fill(
                                selection == tab.id
                                    ? StyleTriggerPalette.cyan : .clear
                            )
                            .frame(height: 2)
                    }
                    .foregroundStyle(
                        selection == tab.id
                            ? StyleTriggerPalette.silver
                            : StyleTriggerPalette.steel
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: StyleTriggerMetrics.minimumTapTarget
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab.id ? .isSelected : [])
            }
        }
        .padding(.horizontal, StyleTriggerMetrics.screenPadding)
        .background(StyleTriggerPalette.background.opacity(0.96))
    }
}

struct StyleTriggerPanel<Content: View>: View {
    let isSelected: Bool
    private let content: Content

    init(isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                StyleTriggerPalette.panel,
                in: RoundedRectangle(
                    cornerRadius: StyleTriggerMetrics.cornerRadius
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: StyleTriggerMetrics.cornerRadius)
                    .strokeBorder(
                        isSelected
                            ? StyleTriggerPalette.cyan
                            : StyleTriggerPalette.silver.opacity(0.16),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
    }
}

struct StyleTriggerPrimaryButtonStyle: ButtonStyle {
    var color = StyleTriggerPalette.cyan
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.monospaced().weight(.bold))
            .foregroundStyle(StyleTriggerPalette.background)
            .frame(
                maxWidth: .infinity,
                minHeight: StyleTriggerMetrics.minimumTapTarget
            )
            .padding(.horizontal, 12)
            .background(
                color.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(
                    cornerRadius: StyleTriggerMetrics.compactCornerRadius
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: StyleTriggerMetrics.compactCornerRadius
                )
                .strokeBorder(
                    StyleTriggerPalette.silver.opacity(0.25),
                    lineWidth: 1
                )
            }
            .shadow(
                color: color.opacity(configuration.isPressed ? 0.08 : 0.22),
                radius: 6
            )
            .scaleEffect(
                reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1)
            )
    }
}

struct StyleTriggerDifficultyPicker: View {
    @Binding var selection: String

    private struct Difficulty: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let icon: String
        let color: Color
    }

    private let choices: [Difficulty] = [
        .init(
            id: "EASY",
            title: "EASY",
            icon: "shield.fill",
            color: StyleTriggerPalette.steel
        ),
        .init(
            id: "NORMAL",
            title: "NORMAL",
            icon: "bolt.fill",
            color: StyleTriggerPalette.cyan
        ),
        .init(
            id: "HELL",
            title: "HELL",
            icon: "flame.fill",
            color: StyleTriggerPalette.magenta
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("DIFFICULTY")
                .font(.caption2.monospaced().weight(.bold))
                .foregroundStyle(StyleTriggerPalette.steel)

            HStack(spacing: 7) {
                ForEach(choices) { choice in
                    let selected = selection == choice.id
                    Button {
                        selection = choice.id
                    } label: {
                        Label(choice.title, systemImage: choice.icon)
                            .font(.caption2.monospaced().weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: StyleTriggerMetrics.minimumTapTarget
                            )
                            .foregroundStyle(
                                selected
                                    ? StyleTriggerPalette.background
                                    : StyleTriggerPalette.silver
                            )
                            .background(
                                selected
                                    ? choice.color
                                    : StyleTriggerPalette.raisedPanel,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        selected
                                            ? choice.color
                                            : StyleTriggerPalette.steel.opacity(
                                                0.15
                                            ),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }
}

struct StyleTriggerBattleBar: View {
    let name: String
    let health: Double
    let color: Color
    let alignment: HorizontalAlignment

    private var healthFraction: Double {
        guard health.isFinite else { return 0 }
        return min(1, max(0, health))
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 5) {
            HStack(spacing: 5) {
                if alignment == .trailing { Spacer(minLength: 0) }
                Text(name)
                    .font(.caption2.monospaced().weight(.bold))
                    .lineLimit(1)
                    .foregroundStyle(StyleTriggerPalette.silver)
                if alignment == .leading { Spacer(minLength: 0) }
            }
            GeometryReader { geometry in
                ZStack(alignment: alignment == .trailing ? .trailing : .leading)
                {
                    Capsule().fill(StyleTriggerPalette.background)
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * healthFraction)
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)

            Text("\(Int((healthFraction * 100).rounded())) HP")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(StyleTriggerPalette.steel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(name))
        .accessibilityValue(
            Text("\(Int((healthFraction * 100).rounded())) percent health")
        )
    }
}
