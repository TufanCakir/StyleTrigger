import SwiftUI

struct StyleTriggerLogo: View {
    var body: some View {
        VStack(spacing: -8) {
            ZStack {
                Text("S")
                    .font(.system(size: 142, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white,
                                StyleTriggerPalette.steel,
                                StyleTriggerPalette.darkSteel
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Text("S")
                            .font(.system(size: 142, weight: .black, design: .rounded))
                            .italic()
                            .foregroundStyle(.clear)
                            .stroke(
                                StyleTriggerPalette.silver.opacity(0.45),
                                lineWidth: 0.7
                            )
                    }
                    .shadow(color: StyleTriggerPalette.silver.opacity(0.28), radius: 8)

                LogoSlash()
            }
            .frame(height: 150)

            Text("STYLE")
                .font(.system(size: 52, weight: .black, design: .monospaced))
                .italic()
                .foregroundStyle(StyleTriggerPalette.silver)
                .shadow(color: StyleTriggerPalette.silver.opacity(0.35), radius: 9)

            HStack(spacing: 0) {
                Text("TRIGGER")
                    .font(.system(size: 23, weight: .bold, design: .monospaced))
                    .foregroundStyle(StyleTriggerPalette.cyan)
                    .tracking(9)

                Circle()
                    .fill(StyleTriggerPalette.magenta)
                    .frame(width: 6, height: 6)
                    .shadow(color: StyleTriggerPalette.magenta, radius: 6)
                    .offset(x: -5, y: -4)
            }
            .padding(.leading, 9)
            .shadow(color: StyleTriggerPalette.cyan.opacity(0.75), radius: 12)
        }
    }
}

private struct LogoSlash: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(StyleTriggerPalette.cyan.opacity(0.25))
                .frame(width: 270, height: 22)
                .blur(radius: 10)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            StyleTriggerPalette.cyan,
                            .white,
                            StyleTriggerPalette.magenta,
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 270, height: 7)
                .shadow(color: StyleTriggerPalette.cyan, radius: 12)
                .shadow(color: StyleTriggerPalette.magenta, radius: 20)
        }
        .rotationEffect(.degrees(-25))
        .blendMode(.screen)
    }
}

private extension View {
    func stroke(_ color: Color, lineWidth: CGFloat) -> some View {
        overlay(self.mask(self).foregroundStyle(color))
            .padding(lineWidth)
    }
}
