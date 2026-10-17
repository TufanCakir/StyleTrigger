//
//  StyleTriggerSettingsView.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SwiftUI

struct StyleTriggerSettingsView: View {
    @Bindable var model: StyleTriggerViewModel

    private let frameRates = [30, 60]

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: StyleTriggerMetrics.sectionSpacing
            ) {
                settingsHeader

                StyleTriggerPanel {
                    VStack(spacing: 14) {
                        settingsToggle(
                            title: "MUSIC",
                            icon: "speaker.wave.3.fill",
                            isOn: Binding(
                                get: { model.progress.isSoundEnabled },
                                set: { model.setSoundEnabled($0) }
                            )
                        )
                        settingsToggle(
                            title: "HAPTICS",
                            icon: "waveform",
                            isOn: Binding(
                                get: { model.progress.isHapticsEnabled },
                                set: { model.setHapticsEnabled($0) }
                            )
                        )
                        settingsToggle(
                            title: "COMBAT FX",
                            icon: "sparkles",
                            isOn: Binding(
                                get: { model.progress.combatEffectsEnabled },
                                set: { model.setCombatEffectsEnabled($0) }
                            )
                        )
                        settingsToggle(
                            title: "SCREEN SHAKE",
                            icon: "iphone.radiowaves.left.and.right",
                            isOn: Binding(
                                get: { model.progress.screenShakeEnabled },
                                set: { model.setScreenShakeEnabled($0) }
                            )
                        )
                    }
                }

                StyleTriggerPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("FRAME RATE")
                        HStack(spacing: 8) {
                            ForEach(frameRates, id: \.self) { fps in
                                optionButton(
                                    title: "\(fps) FPS",
                                    isSelected: model.progress.targetFrameRate
                                        == fps
                                ) {
                                    model.setTargetFrameRate(fps)
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)
                    }
                }

                StyleTriggerPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("GRAPHICS")
                        HStack(spacing: 7) {
                            ForEach(GraphicsQuality.allCases) { quality in
                                optionButton(
                                    title: quality.displayName,
                                    isSelected: model.progress.graphicsQuality
                                        == quality
                                ) {
                                    model.setGraphicsQuality(quality)
                                }
                            }
                        }
                        Text(graphicsDescription)
                            .font(.caption)
                            .foregroundStyle(
                                StyleTriggerPalette.silver.opacity(0.7)
                            )
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, StyleTriggerMetrics.screenPadding)
            .padding(.vertical, StyleTriggerMetrics.sectionSpacing)
        }
        .scrollIndicators(.hidden)
    }

    private var settingsHeader: some View {
        HStack(spacing: 8) {
            Label(
                "PERFORMANCE",
                systemImage: "gauge.with.dots.needle.67percent"
            )
            .font(.caption.monospaced().weight(.black))
            .foregroundStyle(StyleTriggerPalette.cyan)
            Spacer(minLength: 8)
            Text("\(model.progress.targetFrameRate) FPS")
                .font(.caption2.monospaced().weight(.black))
                .monospacedDigit()
                .foregroundStyle(StyleTriggerPalette.magenta)
        }
        .accessibilityElement(children: .combine)
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(StyleTriggerPalette.silver.opacity(0.75))
    }

    private func settingsToggle(
        title: LocalizedStringKey,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: icon)
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(StyleTriggerPalette.silver)
        }
        .tint(StyleTriggerPalette.cyan)
        .controlSize(.regular)
        .frame(minHeight: 44)
    }

    private func optionButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(
                    isSelected
                        ? StyleTriggerPalette.background
                        : StyleTriggerPalette.silver
                )
                .background(
                    isSelected
                        ? StyleTriggerPalette.cyan
                        : StyleTriggerPalette.raisedPanel,
                    in: RoundedRectangle(
                        cornerRadius: StyleTriggerMetrics.compactCornerRadius
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: StyleTriggerMetrics.compactCornerRadius
                    )
                    .strokeBorder(
                        isSelected
                            ? StyleTriggerPalette.cyan
                            : StyleTriggerPalette.silver.opacity(0.15),
                        lineWidth: 1
                    )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var graphicsDescription: LocalizedStringKey {
        switch model.progress.graphicsQuality {
        case .performance:
            "Reduced particles and glow for older iPhones."
        case .balanced:
            "Balanced particles, trails and impact effects."
        case .ultra:
            "Full particles, trails and neon glow."
        }
    }
}
