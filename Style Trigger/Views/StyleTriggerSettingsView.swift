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
                NeonHeader(
                    kicker: "PLAYER CONFIGURATION",
                    title: "SETTINGS",
                    icon: "gearshape.fill"
                )
                .frame(maxWidth: .infinity)

                performanceStatus

                languageSection

                audioSection

                graphicsSection

                frameRateSection

                statisticsSection
            }
            .padding(
                .horizontal,
                StyleTriggerMetrics.screenPadding
            )
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Performance Status

    private var performanceStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.circle.fill")
                .font(.title2)
                .foregroundStyle(StyleTriggerPalette.cyan)

            VStack(alignment: .leading, spacing: 3) {
                Text("SYSTEM STATUS")
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(
                        StyleTriggerPalette.silver.opacity(0.6)
                    )

                Text("COMBAT CONFIGURATION")
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(StyleTriggerPalette.silver)
            }

            Spacer(minLength: 8)

            Text("\(model.progress.targetFrameRate) FPS")
                .font(.caption.monospaced().weight(.black))
                .monospacedDigit()
                .foregroundStyle(StyleTriggerPalette.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    StyleTriggerPalette.cyan.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .padding(14)
        .background(
            StyleTriggerPalette.panel,
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: - Language

    private var languageSection: some View {
        StyleTriggerPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    "LANGUAGE",
                    icon: "globe"
                )

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                    ],
                    spacing: 8
                ) {
                    ForEach(AppLanguage.allCases) { language in
                        optionButton(
                            title: language.title,
                            isSelected: model.appLanguage == language
                        ) {
                            model.setLanguage(language)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Audio & Feedback

    private var audioSection: some View {
        StyleTriggerPanel {
            VStack(alignment: .leading, spacing: 4) {
                sectionHeader(
                    "AUDIO & FEEDBACK",
                    icon: "waveform"
                )
                .padding(.bottom, 8)

                settingsToggle(
                    title: "SOUND",
                    icon: "speaker.wave.3.fill",
                    isOn: Binding(
                        get: { model.progress.isSoundEnabled },
                        set: { model.setSoundEnabled($0) }
                    )
                )

                Divider()
                    .overlay(
                        StyleTriggerPalette.silver.opacity(0.1)
                    )

                settingsToggle(
                    title: "HAPTICS",
                    icon: "hand.tap.fill",
                    isOn: Binding(
                        get: { model.progress.isHapticsEnabled },
                        set: { model.setHapticsEnabled($0) }
                    )
                )
            }
        }
    }

    // MARK: - Graphics

    private var graphicsSection: some View {
        StyleTriggerPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    "GRAPHICS",
                    icon: "sparkles.rectangle.stack.fill"
                )

                HStack(spacing: 7) {
                    ForEach(GraphicsQuality.allCases) { quality in
                        optionButton(
                            title: quality.displayName,
                            isSelected:
                                model.progress.graphicsQuality == quality
                        ) {
                            model.setGraphicsQuality(quality)
                        }
                    }
                }

                Text(graphicsDescription)
                    .font(.caption2)
                    .foregroundStyle(
                        StyleTriggerPalette.silver.opacity(0.65)
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Divider()
                    .overlay(
                        StyleTriggerPalette.silver.opacity(0.1)
                    )

                settingsToggle(
                    title: "COMBAT FX",
                    icon: "sparkles",
                    isOn: Binding(
                        get: { model.progress.combatEffectsEnabled },
                        set: { model.setCombatEffectsEnabled($0) }
                    )
                )

                Divider()
                    .overlay(
                        StyleTriggerPalette.silver.opacity(0.1)
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
    }

    // MARK: - Frame Rate

    private var frameRateSection: some View {
        StyleTriggerPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    "FRAME RATE",
                    icon: "speedometer"
                )

                HStack(spacing: 8) {
                    ForEach(frameRates, id: \.self) { fps in
                        optionButton(
                            title: LocalizedStringResource("\(fps) FPS"),
                            isSelected:
                                model.progress.targetFrameRate == fps
                        ) {
                            model.setTargetFrameRate(fps)
                        }
                    }
                }

                Text("Select your preferred frame rate.")
                    .font(.caption2)
                    .foregroundStyle(
                        StyleTriggerPalette.silver.opacity(0.6)
                    )
            }
        }
    }

    // MARK: - Player Statistics

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "PLAYER STATISTICS",
                icon: "chart.bar.fill"
            )

            ScoreSummary(progress: model.progress)
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(
        _ title: LocalizedStringKey,
        icon: String
    ) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.monospaced().weight(.black))
            .foregroundStyle(StyleTriggerPalette.cyan)
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
        .frame(minHeight: 48)
    }

    private func optionButton(
        title: LocalizedStringResource,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                }
            }
            .font(.caption2.monospaced().weight(.black))
            .frame(maxWidth: .infinity, minHeight: 48)
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
                    cornerRadius:
                        StyleTriggerMetrics.compactCornerRadius
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius:
                        StyleTriggerMetrics.compactCornerRadius
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
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    // MARK: - Descriptions

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
