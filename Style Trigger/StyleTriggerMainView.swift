import SpriteKit
import SwiftUI

enum StyleTriggerPalette {
    static let background = Color(hex: "0B0B0F")
    static let backgroundCenter = Color(hex: "161924")
    static let backgroundEdge = Color(hex: "050508")
    static let cyan = Color(hex: "00F6FF")
    static let magenta = Color(hex: "FF007F")
    static let silver = Color(hex: "F5F5FA")
    static let steel = Color(hex: "D1D5DB")
    static let darkSteel = Color(hex: "6B7280")
}

struct StyleTriggerMainView: View {
    @AppStorage("styleTriggerHighscore") private var highscore = 0
    @State private var isGamePlaying = false
    @State private var scene = ActionGameScene(size: CGSize(width: 390, height: 844))

    var body: some View {
        ZStack {
            StyleTriggerPalette.background
                .ignoresSafeArea()

            if isGamePlaying {
                GameScreen(scene: scene) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isGamePlaying = false
                    }
                }
                .transition(.opacity)
            } else {
                StyleTriggerNavigationContainer(highscore: highscore) {
                    scene.onGameOver = { finalScore in
                        highscore = max(highscore, finalScore)
                    }
                    withAnimation(.easeIn(duration: 0.25)) {
                        isGamePlaying = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
    }
}

private struct GameScreen: View {
    let scene: ActionGameScene
    let onExit: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(StyleTriggerPalette.silver)
                    .frame(width: 44, height: 44)
                    .background(StyleTriggerPalette.background.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(StyleTriggerPalette.silver.opacity(0.2), lineWidth: 1))
            }
            .accessibilityLabel("Spiel verlassen")
            .padding(.leading, 16)
            .padding(.top, 8)
        }
    }
}

private struct StyleTriggerNavigationContainer: View {
    @State private var currentPage = 1

    let highscore: Int
    let onStart: () -> Void

    var body: some View {
        TabView(selection: $currentPage) {
            ArsenalPage()
                .tag(0)

            StyleTriggerPremiumMenu(highscore: highscore, onStart: onStart)
                .tag(1)

            RecordsAndSettingsPage(highscore: highscore)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(StyleTriggerPalette.background)
        .ignoresSafeArea()
        .accessibilityValue("Seite \(currentPage + 1) von 3")
    }
}

private struct ArsenalPage: View {
    var body: some View {
        ZStack {
            PremiumMenuBackground()
            MenuBladeLines()

            VStack(spacing: 22) {
                PageHeader(
                    icon: "shippingbox.fill",
                    eyebrow: "LOADOUT 01",
                    title: "ARSENAL",
                    accent: StyleTriggerPalette.cyan
                )

                VStack(spacing: 12) {
                    ArsenalItem(
                        icon: "bolt.horizontal.fill",
                        name: "NEON EDGE",
                        detail: "CYAN / SPEED",
                        accent: StyleTriggerPalette.cyan,
                        isEquipped: true
                    )
                    ArsenalItem(
                        icon: "flame.fill",
                        name: "VOID FANG",
                        detail: "MAGENTA / POWER",
                        accent: StyleTriggerPalette.magenta,
                        isEquipped: false
                    )
                    ArsenalItem(
                        icon: "sparkles",
                        name: "CHROME REAPER",
                        detail: "LOCKED · 12,000 STYLE",
                        accent: StyleTriggerPalette.silver,
                        isEquipped: false
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                SwipeDirectionHint(
                    text: "SWIPE RIGHT FOR COMBAT",
                    systemImage: "chevron.right.2"
                )
            }
            .padding(.top, 72)
            .padding(.bottom, 76)
        }
    }
}

private struct ArsenalItem: View {
    let icon: String
    let name: LocalizedStringResource
    let detail: LocalizedStringResource
    let accent: Color
    let isEquipped: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2.weight(.black))
                .foregroundStyle(accent)
                .frame(width: 48, height: 48)
                .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: accent.opacity(0.45), radius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(.headline, design: .monospaced, weight: .black))
                    .foregroundStyle(StyleTriggerPalette.silver)

                Text(detail)
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.48))
            }

            Spacer()

            if isEquipped {
                Text("ACTIVE")
                    .font(.system(.caption2, design: .monospaced, weight: .black))
                    .foregroundStyle(StyleTriggerPalette.background)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 9)
                    .background(accent, in: Capsule())
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.34))
            }
        }
        .padding(16)
        .background(StyleTriggerPalette.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(isEquipped ? 0.65 : 0.2), lineWidth: 1)
        )
    }
}

private struct RecordsAndSettingsPage: View {
    @AppStorage("styleTriggerSoundEnabled") private var isSoundEnabled = true
    @AppStorage("styleTriggerHapticsEnabled") private var isHapticsEnabled = true

    let highscore: Int

    var body: some View {
        ZStack {
            PremiumMenuBackground()
            MenuBladeLines()

            VStack(spacing: 22) {
                PageHeader(
                    icon: "trophy.fill",
                    eyebrow: "PLAYER DATA",
                    title: "RECORDS",
                    accent: StyleTriggerPalette.magenta
                )

                RecordCard(highscore: highscore)

                VStack(spacing: 0) {
                    SettingToggle(
                        title: "SOUND",
                        systemImage: "speaker.wave.3.fill",
                        accent: StyleTriggerPalette.cyan,
                        isOn: $isSoundEnabled
                    )

                    Divider()
                        .overlay(StyleTriggerPalette.silver.opacity(0.12))
                        .padding(.leading, 54)

                    SettingToggle(
                        title: "HAPTICS",
                        systemImage: "waveform",
                        accent: StyleTriggerPalette.magenta,
                        isOn: $isHapticsEnabled
                    )
                }
                .padding(.horizontal, 16)
                .background(StyleTriggerPalette.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(StyleTriggerPalette.silver.opacity(0.13), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()

                SwipeDirectionHint(
                    text: "SWIPE LEFT FOR COMBAT",
                    systemImage: "chevron.left.2"
                )
            }
            .padding(.top, 72)
            .padding(.bottom, 76)
        }
    }
}

private struct PageHeader: View {
    let icon: String
    let eyebrow: LocalizedStringResource
    let title: LocalizedStringResource
    let accent: Color

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.title.weight(.black))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.7), radius: 10)

            Text(eyebrow)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .tracking(3)
                .foregroundStyle(accent.opacity(0.75))

            Text(title)
                .font(.system(.largeTitle, design: .monospaced, weight: .black))
                .italic()
                .foregroundStyle(StyleTriggerPalette.silver)
        }
    }
}

private struct RecordCard: View {
    let highscore: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("HIGHEST STYLE")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.5))

                Text(highscore > 0 ? "SSS" : "D")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                StyleTriggerPalette.silver,
                                StyleTriggerPalette.magenta
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(highscore, format: .number)
                    .font(.system(.title2, design: .monospaced, weight: .black))
                    .foregroundStyle(StyleTriggerPalette.cyan)

                Text("BEST SCORE")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.45))
            }
        }
        .padding(22)
        .background(StyleTriggerPalette.background.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [
                            StyleTriggerPalette.cyan.opacity(0.6),
                            StyleTriggerPalette.magenta.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal, 24)
    }
}

private struct SettingToggle: View {
    let title: LocalizedStringResource
    let systemImage: String
    let accent: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                Text(title)
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(StyleTriggerPalette.silver)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(accent)
            }
        }
        .tint(accent)
        .padding(.vertical, 15)
    }
}

private struct SwipeDirectionHint: View {
    let text: LocalizedStringResource
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.system(.caption2, design: .monospaced, weight: .bold))
            .tracking(1)
            .foregroundStyle(StyleTriggerPalette.silver.opacity(0.4))
    }
}

private struct StyleTriggerPremiumMenu: View {
    let highscore: Int
    let onStart: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PremiumMenuBackground()
                MenuBladeLines()

                VStack(spacing: 0) {
                    Spacer(minLength: 42)

                    StyleTriggerLogo()
                        .scaleEffect(min(1, proxy.size.width / 410))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Style Trigger")

                    Text("ONE TOUCH. INFINITE STYLE.")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .tracking(2.4)
                        .foregroundStyle(StyleTriggerPalette.silver.opacity(0.62))
                        .padding(.top, 22)

                    Spacer(minLength: 34)

                    HighestStyleBadge(highscore: highscore)
                        .padding(.bottom, 28)

                    TriggerButton(action: onStart)
                        .padding(.horizontal, 32)

                    Text("TAP · SWIPE UP · SWIPE DOWN · SWIPE RIGHT")
                        .font(.system(.caption2, design: .monospaced, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(StyleTriggerPalette.silver.opacity(0.38))
                        .padding(.top, 18)
                        .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 14))
                }
            }
        }
    }
}

private struct PremiumMenuBackground: View {
    var body: some View {
        RadialGradient(
            colors: [
                StyleTriggerPalette.backgroundCenter,
                StyleTriggerPalette.backgroundEdge
            ],
            center: .center,
            startRadius: 20,
            endRadius: 600
        )
        .overlay {
            LinearGradient(
                colors: [
                    StyleTriggerPalette.cyan.opacity(0.055),
                    .clear,
                    StyleTriggerPalette.magenta.opacity(0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

private struct MenuBladeLines: View {
    var body: some View {
        Canvas { context, size in
            drawBlade(
                in: &context,
                size: size,
                start: CGPoint(x: -20, y: size.height * 0.18),
                end: CGPoint(x: size.width + 30, y: size.height * 0.76),
                color: StyleTriggerPalette.cyan,
                opacity: 0.16
            )
            drawBlade(
                in: &context,
                size: size,
                start: CGPoint(x: -45, y: size.height * 0.72),
                end: CGPoint(x: size.width + 20, y: size.height * 0.28),
                color: StyleTriggerPalette.magenta,
                opacity: 0.13
            )

            var centerSlash = Path()
            centerSlash.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.58))
            centerSlash.addQuadCurve(
                to: CGPoint(x: size.width * 0.92, y: size.height * 0.34),
                control: CGPoint(x: size.width * 0.55, y: size.height * 0.62)
            )
            context.stroke(
                centerSlash,
                with: .linearGradient(
                    Gradient(colors: [
                        .clear,
                        StyleTriggerPalette.silver.opacity(0.24),
                        .clear
                    ]),
                    startPoint: CGPoint(x: 0, y: size.height * 0.5),
                    endPoint: CGPoint(x: size.width, y: size.height * 0.5)
                ),
                lineWidth: 1
            )
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func drawBlade(
        in context: inout GraphicsContext,
        size: CGSize,
        start: CGPoint,
        end: CGPoint,
        color: Color,
        opacity: Double
    ) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [.clear, color.opacity(opacity), .clear]),
                startPoint: CGPoint(x: 0, y: size.height / 2),
                endPoint: CGPoint(x: size.width, y: size.height / 2)
            ),
            lineWidth: 2
        )
    }
}

private struct HighestStyleBadge: View {
    let highscore: Int

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(StyleTriggerPalette.magenta)
                .shadow(color: StyleTriggerPalette.magenta, radius: 6)

            if highscore > 0 {
                Text("HIGHEST STYLE: SSS · \(highscore)")
            } else {
                Text("HIGHEST STYLE: D")
            }
        }
        .font(.system(.subheadline, design: .monospaced, weight: .bold))
        .foregroundStyle(StyleTriggerPalette.silver)
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        .background(StyleTriggerPalette.background.opacity(0.64), in: Capsule())
        .overlay(
            Capsule()
                .stroke(StyleTriggerPalette.magenta.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: StyleTriggerPalette.magenta.opacity(0.32), radius: 9)
    }
}

private struct TriggerButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("START COMBO")
                Image(systemName: "bolt.fill")
            }
            .font(.system(.headline, design: .monospaced, weight: .black))
            .foregroundStyle(StyleTriggerPalette.silver)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 62)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    StyleTriggerPalette.cyan,
                                    StyleTriggerPalette.magenta
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 12)
                        .fill(StyleTriggerPalette.background)
                        .padding(2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: StyleTriggerPalette.cyan.opacity(0.52),
                radius: 16,
                x: -6
            )
            .shadow(
                color: StyleTriggerPalette.magenta.opacity(0.52),
                radius: 16,
                x: 6
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Startet den Kampf")
    }
}

extension Color {
    init(hex: String) {
        let cleanedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&value)

        let alpha: UInt64
        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch cleanedHex.count {
        case 3:
            alpha = 255
            red = (value >> 8) * 17
            green = (value >> 4 & 0xF) * 17
            blue = (value & 0xF) * 17
        case 6:
            alpha = 255
            red = value >> 16
            green = value >> 8 & 0xFF
            blue = value & 0xFF
        case 8:
            alpha = value >> 24
            red = value >> 16 & 0xFF
            green = value >> 8 & 0xFF
            blue = value & 0xFF
        default:
            alpha = 255
            red = 245
            green = 245
            blue = 250
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

#Preview {
    StyleTriggerMainView()
}
