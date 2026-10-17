//
//  StyleTriggerMainView.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import GameKit
import SpriteKit
import SwiftUI
import UIKit

enum StyleTriggerPalette {
    static let background = Color(hex: "0B0B0F")
    static let panel = Color(hex: "161924")
    static let cyan = Color(hex: "00F6FF")
    static let magenta = Color(hex: "FF007F")
    static let silver = Color(hex: "F5F5FA")
    static let steel = Color(hex: "D1D5DB")
    static let darkSteel = Color(hex: "6B7280")
}

struct StyleTriggerMainView: View {
    @State private var model = StyleTriggerViewModel()

    var body: some View {
        ZStack {
            StyleTriggerBackground()

            if let error = model.loadError {
                DataErrorView(message: error) {
                    Task { await model.load() }
                }
            } else if model.content == nil {
                ProgressView("LOADING COMBAT DATA")
                    .tint(StyleTriggerPalette.cyan)
                    .foregroundStyle(StyleTriggerPalette.silver)
            } else {
                switch model.screen {
                case .menu:
                    MenuPager(model: model)
                case .lobby:
                    MatchLobbyView(model: model)
                case .combat:
                    CombatScreen(model: model)
                case .results:
                    MatchResultsView(model: model)
                }
            }
        }
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .task {
            if model.content == nil {
                await model.load()
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { model.multiplayer.isShowingMatchmaker },
                set: { model.multiplayer.isShowingMatchmaker = $0 }
            )
        ) {
            GameCenterMatchmakerView(service: model.multiplayer)
                .ignoresSafeArea()
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { model.multiplayer.authenticationViewController != nil },
                set: { isPresented in
                    if !isPresented {
                        model.multiplayer.authenticationViewController = nil
                    }
                }
            )
        ) {
            if let controller = model.multiplayer.authenticationViewController {
                GameCenterAuthenticationView(viewController: controller)
                    .ignoresSafeArea()
            }
        }
        .onChange(of: model.multiplayer.isConnected) { _, isConnected in
            if isConnected, model.screen == .lobby,
                model.selectedMode == .versus
            {
                model.startMatch()
            }
        }
    }
}

private struct MenuPager: View {
    @Bindable var model: StyleTriggerViewModel

    var body: some View {
        TabView(selection: $model.menuPage) {
            ArsenalView(model: model)
                .tag(0)
            ModeSelectView(model: model)
                .tag(1)
            ComboAndSettingsView(model: model)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

private struct ArsenalView: View {
    let model: StyleTriggerViewModel

    var body: some View {
        VStack(spacing: 16) {
            NeonHeader(
                kicker: "BALANCED ARCHETYPES",
                title: "ARSENAL",
                icon: "bolt.horizontal.fill"
            )

            HStack(spacing: 16) {
                ForEach(model.content?.weapons ?? []) { weapon in
                    Button {
                        model.selectWeapon(weapon.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(
                                systemName: weapon.id == "neon-edge"
                                    ? "bolt.fill" : "flame.fill"
                            )
                            .font(.largeTitle)
                            .foregroundStyle(
                                weapon.id == "neon-edge"
                                    ? StyleTriggerPalette.cyan
                                    : StyleTriggerPalette.magenta
                            )
                            Text(weapon.name)
                                .font(.title3.monospaced().weight(.black))
                            Text(
                                weapon.id == "neon-edge"
                                    ? "PRECISION / CANCELS"
                                    : "MOMENTUM / LAUNCHERS"
                            )
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            Label(
                                model.progress.selectedWeaponID == weapon.id
                                    ? "EQUIPPED" : "EQUIP",
                                systemImage: model.progress.selectedWeaponID
                                    == weapon.id
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .font(.caption.weight(.bold))
                            .foregroundStyle(StyleTriggerPalette.cyan)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 170,
                            alignment: .leading
                        )
                        .padding(18)
                        .background(
                            StyleTriggerPalette.panel.opacity(0.88),
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    model.progress.selectedWeaponID == weapon.id
                                        ? StyleTriggerPalette.cyan
                                        : StyleTriggerPalette.silver.opacity(
                                            0.14
                                        ),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)

            Text("Weapons change routes and timing — never raw power.")
                .font(.caption.monospaced())
                .foregroundStyle(StyleTriggerPalette.silver.opacity(0.55))
        }
        .padding(.vertical, 32)
    }
}

private struct ModeSelectView: View {
    let model: StyleTriggerViewModel

    var body: some View {
        HStack(spacing: 28) {
            StyleTriggerLogo()
                .scaleEffect(0.62)
                .frame(width: 245)

            VStack(alignment: .leading, spacing: 12) {
                Text("SELECT MODE")
                    .font(.title2.monospaced().weight(.black))
                    .foregroundStyle(StyleTriggerPalette.silver)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    ForEach(model.content?.progression.modes ?? []) { mode in
                        ModeButton(
                            mode: mode,
                            isUnlocked: model.progress.unlockedModes.contains(
                                mode.id
                            ),
                            event: mode.id == .timedEvent
                                ? model.currentEvent : nil
                        ) {
                            model.openLobby(for: mode.id)
                        }
                    }
                }
            }
            .frame(maxWidth: 560)
        }
        .padding(.horizontal, 40)
    }
}

private struct ModeButton: View {
    let mode: GameModeDefinition
    let isUnlocked: Bool
    let event: TimedEventDefinition?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: isUnlocked ? "bolt.fill" : "lock.fill")
                    Text(mode.id.displayName)
                    Spacer()
                }
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(
                    isUnlocked
                        ? StyleTriggerPalette.cyan
                        : StyleTriggerPalette.silver.opacity(0.38)
                )

                Text(mode.description)
                    .font(.caption2)
                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.58))
                    .lineLimit(2)

                if let chapter = mode.unlockAfterStoryChapter, !isUnlocked {
                    Text("CLEAR STORY \(chapter)")
                        .font(.caption2.monospaced().weight(.bold))
                        .foregroundStyle(StyleTriggerPalette.magenta)
                }

                if let event {
                    EventCountdown(endDate: event.endsAt)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .padding(12)
            .background(
                StyleTriggerPalette.panel.opacity(0.9),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(
                    StyleTriggerPalette.silver.opacity(0.12)
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

private struct EventCountdown: View {
    let endDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(endDate.timeIntervalSince(context.date)))
            Text("ENDS \(remaining / 86_400)D \((remaining % 86_400) / 3_600)H")
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(StyleTriggerPalette.magenta)
        }
    }
}

private struct ComboAndSettingsView: View {
    let model: StyleTriggerViewModel

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                NeonHeader(
                    kicker: model.selectedWeapon?.name ?? "WEAPON",
                    title: "COMBO BOOK",
                    icon: "book.closed.fill"
                )

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(model.availableCombos) { combo in
                            ComboRow(combo: combo)
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                NeonHeader(
                    kicker: "PLAYER",
                    title: "SETTINGS",
                    icon: "gearshape.fill"
                )

                SettingButton(
                    title: "MUSIC",
                    icon: "speaker.wave.3.fill",
                    isOn: model.progress.isSoundEnabled
                ) {
                    model.setSoundEnabled(!model.progress.isSoundEnabled)
                }

                SettingButton(
                    title: "HAPTICS",
                    icon: "waveform",
                    isOn: model.progress.isHapticsEnabled
                ) {
                    model.setHapticsEnabled(!model.progress.isHapticsEnabled)
                }

                ScoreSummary(progress: model.progress)
            }
            .frame(width: 280)
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 28)
    }
}

private struct ComboRow: View {
    let combo: ComboDefinition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(combo.name)
                    .font(.headline.monospaced().weight(.black))
                Text(combo.isAirLauncher ? "AIR LAUNCHER" : "GROUND ROUTE")
                    .font(.caption2.monospaced())
                    .foregroundStyle(StyleTriggerPalette.magenta)
            }

            Spacer()

            HStack(spacing: 5) {
                ForEach(Array(combo.inputSequence.enumerated()), id: \.offset) {
                    _,
                    input in
                    Text(input.symbol)
                        .font(.headline.weight(.black))
                        .frame(width: 30, height: 30)
                        .background(
                            StyleTriggerPalette.cyan.opacity(0.12),
                            in: Circle()
                        )
                }
            }

            Text("+\(combo.stylePoints)")
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(StyleTriggerPalette.cyan)
                .frame(width: 55, alignment: .trailing)
        }
        .padding(12)
        .background(
            StyleTriggerPalette.panel.opacity(0.82),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

private struct SettingButton: View {
    let title: LocalizedStringResource
    let icon: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(isOn ? "ON" : "OFF")
                    .foregroundStyle(
                        isOn
                            ? StyleTriggerPalette.cyan
                            : StyleTriggerPalette.magenta
                    )
            }
            .font(.headline.monospaced().weight(.bold))
            .padding(14)
            .background(
                StyleTriggerPalette.panel,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ScoreSummary: View {
    let progress: PlayerProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HIGH SCORES")
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(.secondary)
            ForEach(GameModeKind.allCases) { mode in
                HStack {
                    Text(mode.displayName)
                    Spacer()
                    Text(progress.highScores[mode, default: 0], format: .number)
                        .foregroundStyle(StyleTriggerPalette.cyan)
                }
                .font(.caption.monospaced())
            }
        }
        .padding(14)
        .background(
            StyleTriggerPalette.panel,
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

private struct MatchLobbyView: View {
    let model: StyleTriggerViewModel
    private let environments = [
        ("neon-rooftop", "NEON ROOFTOP"),
        ("void-cathedral", "VOID CATHEDRAL"),
        ("chrome-subway", "CHROME SUBWAY"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("BACK", systemImage: "chevron.left") {
                    model.returnToMenu()
                }
                Spacer()
                NeonHeader(
                    kicker: model.selectedMode.displayName,
                    title: "PREPARE",
                    icon: "scope"
                )
                Spacer()
                Button(
                    model.selectedMode == .versus ? "FIND FIGHT" : "FIGHT",
                    systemImage: model.selectedMode == .versus
                        ? "person.2.fill" : "bolt.fill"
                ) {
                    model.startSelectedMatch()
                }
                .buttonStyle(.borderedProminent)
                .tint(StyleTriggerPalette.magenta)
            }

            HStack(spacing: 24) {
                SelectionPanel(title: "CHARACTER") {
                    ForEach(model.content?.characters ?? []) { character in
                        SelectChip(
                            title: character.name,
                            subtitle: character.description,
                            isSelected: model.progress.selectedCharacterID
                                == character.id,
                            isEnabled: character.unlocked
                        ) {
                            model.selectCharacter(character.id)
                        }
                    }
                }

                SelectionPanel(title: "ENVIRONMENT") {
                    ForEach(environments, id: \.0) { environment in
                        SelectChip(
                            title: environment.1,
                            subtitle: environment.0,
                            isSelected: model.progress.selectedEnvironmentID
                                == environment.0,
                            isEnabled: true
                        ) {
                            model.selectEnvironment(environment.0)
                        }
                    }

                    Button("RANDOM", systemImage: "shuffle") {
                        model.chooseRandomEnvironment()
                    }
                    .buttonStyle(.bordered)
                    .tint(StyleTriggerPalette.cyan)
                }

                SelectionPanel(title: "RULES") {
                    Picker(
                        "Difficulty",
                        selection: Bindable(model).selectedDifficulty
                    ) {
                        Text("EASY").tag("EASY")
                        Text("NORMAL").tag("NORMAL")
                        Text("HELL").tag("HELL")
                    }
                    .pickerStyle(.segmented)

                    if model.selectedMode == .versus {
                        Picker(
                            "Team Size",
                            selection: Bindable(model).selectedTeamSize
                        ) {
                            ForEach(1...4, id: \.self) { size in
                                Text("\(size)V\(size)").tag(size)
                            }
                        }
                        .pickerStyle(.segmented)

                        Label(
                            model.multiplayer.state.label,
                            systemImage: model.multiplayer.isConnected
                                ? "network" : "gamecontroller.fill"
                        )
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(
                            model.multiplayer.isAuthenticated
                                ? StyleTriggerPalette.cyan
                                : StyleTriggerPalette.magenta
                        )
                    }

                    Text("Weapon: \(model.selectedWeapon?.name ?? "NONE")")
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(StyleTriggerPalette.cyan)
                }
            }
        }
        .padding(28)
        .buttonStyle(.plain)
    }
}

private struct SelectionPanel<Content: View>: View {
    let title: LocalizedStringResource
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.monospaced().weight(.black))
            content
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            StyleTriggerPalette.panel.opacity(0.88),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct SelectChip: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .font(.subheadline.monospaced().weight(.black))
                    Spacer()
                    Image(
                        systemName: isEnabled
                            ? (isSelected ? "checkmark.circle.fill" : "circle")
                            : "lock.fill"
                    )
                }
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(10)
            .background(
                (isSelected
                    ? StyleTriggerPalette.cyan.opacity(0.12) : Color.clear),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(
                    isSelected ? StyleTriggerPalette.cyan : .white.opacity(0.1)
                )
            )
        }
        .disabled(!isEnabled)
    }
}

private struct CombatScreen: View {
    let model: StyleTriggerViewModel
    @State private var scene = ActionGameScene(
        size: CGSize(width: 844, height: 390)
    )

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            VStack {
                CombatHUD(model: model)
                Spacer()
            }

            HStack {
                VStack {
                    Spacer()
                    Button("EXIT", systemImage: "xmark") {
                        model.finishMatch(didWin: false)
                    }
                    .buttonStyle(.bordered)
                    .tint(StyleTriggerPalette.magenta)
                }
                Spacer()
            }
            .padding(18)
        }
        .onAppear {
            scene.scaleMode = .aspectFill
            scene.configure(combos: model.availableCombos)
            scene.onCombatSnapshot = { snapshot in
                model.receiveCombatSnapshot(snapshot)
            }
            scene.onLocalInput = { input in
                if model.selectedMode == .versus {
                    model.multiplayer.send(input)
                }
            }
            scene.onGameOver = { score in
                let snapshot = CombatSnapshot(
                    playerHealth: 0,
                    enemyHealth: model.combat.enemyHealth,
                    comboCount: model.combat.comboCount,
                    score: score,
                    totalDamage: model.combat.totalDamage,
                    styleRank: model.combat.styleRank
                )
                model.receiveCombatSnapshot(snapshot)
            }
        }
        .onChange(of: model.screen) { _, screen in
            scene.isPaused = screen != .combat
        }
        .onChange(of: model.multiplayer.remoteInputSequence) { _, _ in
            if let input = model.multiplayer.remoteInput {
                scene.receiveRemoteInput(input)
            }
        }
    }
}

private struct CombatHUD: View {
    let model: StyleTriggerViewModel

    var body: some View {
        HStack(spacing: 22) {
            FighterHUD(
                name: model.selectedCharacter?.name ?? "VEX",
                health: model.combat.playerHealth,
                color: StyleTriggerPalette.cyan,
                alignment: .leading
            )

            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(.title, design: .monospaced, weight: .black))
                Text(model.combat.styleRank.letter)
                    .font(
                        .system(.largeTitle, design: .rounded, weight: .black)
                    )
                    .foregroundStyle(StyleTriggerPalette.magenta)
            }
            .frame(width: 120)

            FighterHUD(
                name: model.content?.enemies.first?.name ?? "WRAITH",
                health: model.combat.enemyHealth,
                color: StyleTriggerPalette.magenta,
                alignment: .trailing
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var timeString: String {
        String(
            format: "%02d:%02d",
            model.remainingSeconds / 60,
            model.remainingSeconds % 60
        )
    }
}

private struct FighterHUD: View {
    let name: String
    let health: Double
    let color: Color
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 5) {
            Text(name)
                .font(.caption.monospaced().weight(.black))
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.7))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * max(0, min(1, health)))
                }
            }
            .frame(height: 10)
            Text("HP \(Int(health * 100))")
                .font(.caption2.monospaced())
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MatchResultsView: View {
    let model: StyleTriggerViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(model.result?.didWin == true ? "JACKPOT!" : "STYLE BROKEN")
                .font(.system(.largeTitle, design: .monospaced, weight: .black))
                .foregroundStyle(
                    model.result?.didWin == true
                        ? StyleTriggerPalette.cyan : StyleTriggerPalette.magenta
                )

            HStack(spacing: 12) {
                ResultStat(
                    title: "DAMAGE",
                    value: "\(model.result?.totalDamage ?? 0)"
                )
                ResultStat(
                    title: "HIGHEST STYLE",
                    value: model.result?.highestStyleRank.letter ?? "D"
                )
                ResultStat(
                    title: "SCORE",
                    value: "\(model.result?.totalScore ?? 0)"
                )
                ResultStat(
                    title: "CHARACTER EXP",
                    value: "+\(model.result?.earnedExperience ?? 0)"
                )
            }

            Button("RETURN TO MENU", systemImage: "arrow.counterclockwise") {
                model.returnToMenu()
            }
            .buttonStyle(.borderedProminent)
            .tint(StyleTriggerPalette.cyan)
        }
        .padding(32)
    }
}

private struct ResultStat: View {
    let title: LocalizedStringResource
    let value: String

    var body: some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.monospaced().weight(.black))
        }
        .frame(minWidth: 140)
        .padding(16)
        .background(
            StyleTriggerPalette.panel,
            in: RoundedRectangle(cornerRadius: 14)
        )
    }
}

private struct NeonHeader: View {
    let kicker: String
    let title: LocalizedStringResource
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Label(kicker, systemImage: icon)
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(StyleTriggerPalette.cyan)
            Text(title)
                .font(.title.monospaced().weight(.black))
                .foregroundStyle(StyleTriggerPalette.silver)
        }
    }
}

private struct StyleTriggerBackground: View {
    var body: some View {
        RadialGradient(
            colors: [
                StyleTriggerPalette.panel, StyleTriggerPalette.background,
            ],
            center: .center,
            startRadius: 20,
            endRadius: 650
        )
        .overlay {
            LinearGradient(
                colors: [
                    StyleTriggerPalette.cyan.opacity(0.04), .clear,
                    StyleTriggerPalette.magenta.opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

private struct DataErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(StyleTriggerPalette.magenta)
            Text(message)
                .font(.caption.monospaced())
            Button("RETRY", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(StyleTriggerPalette.cyan)
        }
        .padding()
    }
}

private struct GameCenterMatchmakerView: UIViewControllerRepresentable {
    let service: GameCenterMultiplayerService

    func makeUIViewController(context: Context) -> UIViewController {
        guard let controller = service.makeMatchmakerViewController() else {
            let fallback = UIViewController()
            fallback.view.backgroundColor = UIColor(
                StyleTriggerPalette.background
            )
            return fallback
        }
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {}
}

private struct GameCenterAuthenticationView: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        viewController
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {}
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

#Preview {
    StyleTriggerMainView()
}
