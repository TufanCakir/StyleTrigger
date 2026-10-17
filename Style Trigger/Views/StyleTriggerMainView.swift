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

        .environment(\.locale, model.appLanguage.locale)
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

        .fullScreenCover(
            isPresented: Binding(
                get: { model.story.isPresented },
                set: { isPresented in
                    if !isPresented {
                        model.story.dismiss()
                    }
                }
            )
        ) {
            StorySelectionScreen(
                story: model.story,
                unlockedChapter: model.progress.storyChapter,
                selectChapter: model.selectStoryChapter
            )
        }

        .onChange(of: model.multiplayer.isConnected) { _, isConnected in

            if isConnected, model.screen == .lobby,

                model.selectedMode == .versus,
                model.versusOpponent == .gameCenter
            {

                model.startMatch()

            }

        }

    }

}

private struct MenuPager: View {

    @Bindable var model: StyleTriggerViewModel

    private let tabs = [

        StyleTriggerTab(id: 0, title: "ARSENAL", icon: "bolt.horizontal.fill"),

        StyleTriggerTab(id: 1, title: "BATTLE", icon: "scope"),

        StyleTriggerTab(id: 2, title: "COMBOS", icon: "book.closed.fill"),
        
        StyleTriggerTab(id: 3, title: "SHOP", icon: "cart"),

        StyleTriggerTab(id: 4, title: "SETTINGS", icon: "gear"),

    ]

    var body: some View {

        VStack(spacing: 0) {

            StyleTriggerAccountHeader(model: model)

            StyleTriggerTopTabBar(selection: $model.menuPage, tabs: tabs)

            TabView(selection: $model.menuPage) {

                ArsenalView(model: model)

                    .tag(0)

                ModeSelectView(model: model)

                    .tag(1)

                ComboAndSettingsView(model: model)

                    .tag(2)

                StyleTriggerShopView(model: model)
                    .tag(3)

                StyleTriggerSettingsView(model: model)

                    .tag(4)

            }

            .tabViewStyle(.page(indexDisplayMode: .never))

        }

    }

}

private struct ArsenalView: View {

    let model: StyleTriggerViewModel

    var body: some View {

        ScrollView {

            VStack(spacing: 18) {

                NeonHeader(

                    kicker: "BALANCED ARCHETYPES",

                    title: "ARSENAL",

                    icon: "bolt.horizontal.fill"

                )

                LazyVGrid(

                    columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],

                    spacing: 12

                ) {

                    ForEach(model.content?.weapons ?? []) { weapon in

                        let unlocked = model.progress.unlockedWeaponIDs
                            .contains(weapon.id)

                        let compatible =
                            model.selectedCharacter?.compatibleWeaponIDs
                            .contains(weapon.id) == true

                        Button {

                            model.selectWeapon(weapon.id)

                        } label: {

                            VStack(alignment: .leading, spacing: 10) {

                                WeaponIcon(

                                    type: weapon.type,

                                    color: compatible
                                        ? StyleTriggerPalette.cyan
                                        : StyleTriggerPalette.magenta

                                )

                                .frame(height: 48)

                                Text(model.localizedGameText(weapon.name))

                                    .font(
                                        .subheadline.monospaced().weight(.black)
                                    )

                                    .lineLimit(2)

                                Text(
                                    "DMG \(weapon.damage)  SPD \(weapon.attackSpeed, format: .number.precision(.fractionLength(2)))"
                                )

                                .font(.caption2.monospaced())

                                .foregroundStyle(.secondary)

                                Label(

                                    !unlocked
                                        ? "LOCKED"
                                        : (!compatible
                                            ? "INCOMPATIBLE"
                                            : (model.progress.selectedWeaponID
                                                == weapon.id
                                                ? "ACTIVE" : "EQUIP")),

                                    systemImage: !unlocked
                                        ? "lock.fill"
                                        : (model.progress.selectedWeaponID
                                            == weapon.id
                                            ? "checkmark.circle.fill"
                                            : "circle")

                                )

                                .font(.caption2.weight(.bold))

                                .foregroundStyle(
                                    compatible && unlocked
                                        ? StyleTriggerPalette.cyan : .secondary
                                )

                            }

                            .frame(
                                maxWidth: .infinity,
                                minHeight: 150,
                                alignment: .leading
                            )

                            .padding(10)

                            .background(

                                StyleTriggerPalette.panel.opacity(0.88),

                                in: RoundedRectangle(cornerRadius: 18)

                            )

                            .overlay(

                                RoundedRectangle(cornerRadius: 18)

                                    .stroke(

                                        model.progress.selectedWeaponID
                                            == weapon.id

                                            ? StyleTriggerPalette.cyan

                                            : StyleTriggerPalette.silver
                                                .opacity(0.14),

                                        lineWidth: 1.5

                                    )

                            )

                        }

                        .buttonStyle(.plain)

                        .disabled(!unlocked || !compatible)

                        .opacity(unlocked ? 1 : 0.48)

                    }

                }

                Text("Weapons change routes and timing — never raw power.")
                    .font(.caption.monospaced())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.55))
            }

            .padding(.horizontal, 20)

            .padding(.top, 14)

            .padding(.bottom, 20)

        }

    }

}

private struct ModeSelectView: View {

    let model: StyleTriggerViewModel

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 12) {

                StyleTriggerLogo()

                    .scaleEffect(0.56)

                    .frame(maxWidth: .infinity)

                    .frame(height: 138)

                Text("SELECT MODE")

                    .font(.title2.monospaced().weight(.black))

                    .foregroundStyle(StyleTriggerPalette.silver)

                LazyVGrid(

                    columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],

                    spacing: 10

                ) {

                    ForEach(model.content?.progression.modes ?? []) { mode in

                        ModeButton(

                            mode: mode,
                            localizedDescription: model.localizedGameText(
                                mode.description
                            ),

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

            .padding(.horizontal, 20)

            .padding(.top, 4)

            .padding(.bottom, 20)

        }

    }

}

private struct ModeButton: View {

    let mode: GameModeDefinition

    let localizedDescription: String

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

                Text(localizedDescription)

                    .font(.caption2)

                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.58))

                    .lineLimit(3)

                if let chapter = mode.unlockAfterStoryChapter, !isUnlocked {

                    Text("CLEAR STORY \(chapter)")

                        .font(.caption2.monospaced().weight(.bold))

                        .foregroundStyle(StyleTriggerPalette.magenta)

                }

                if let event {

                    EventCountdown(endDate: event.endsAt)

                }

            }

            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)

            .padding(10)

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

        TimelineView(.periodic(from: .now, by: 30)) { context in

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

        ScrollView {

            VStack(alignment: .leading, spacing: 10) {

                NeonHeader(

                    kicker: LocalizedStringResource(
                        stringLiteral: model.selectedWeapon?.name ?? "WEAPON"
                    ),

                    title: "COMBO BOOK",

                    icon: "book.closed.fill"

                )

                VStack(spacing: 8) {

                    ForEach(model.availableCombos) { combo in

                        ComboRow(
                            combo: combo,
                            localizedName: model.localizedGameText(combo.name)
                        )

                    }

                }
            }

            .padding(.horizontal, 20)

            .padding(.top, 14)

            .padding(.bottom, 24)

        }

    }

}

private struct ComboRow: View {

    let combo: ComboDefinition

    let localizedName: String

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            VStack(alignment: .leading, spacing: 4) {

                Text(localizedName)

                    .font(.headline.monospaced().weight(.black))

                Text(combo.isAirLauncher ? "AIR LAUNCHER" : "GROUND ROUTE")

                    .font(.caption2.monospaced())

                    .foregroundStyle(StyleTriggerPalette.magenta)

            }

            HStack {

                HStack(spacing: 5) {

                    ForEach(
                        Array(combo.inputSequence.enumerated()),
                        id: \.offset
                    ) {

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

                Spacer()

                Text("+\(combo.stylePoints)")

                    .font(.caption.monospaced().weight(.black))

                    .foregroundStyle(StyleTriggerPalette.cyan)

            }

        }

        .padding(12)

        .background(

            StyleTriggerPalette.panel.opacity(0.82),

            in: RoundedRectangle(cornerRadius: 12)

        )

    }

}

private struct MatchLobbyView: View {

    let model: StyleTriggerViewModel

    @State private var step = LobbyStep.character

    @State private var detailCharacter: GameCharacter?

    private var startButtonTitle: LocalizedStringResource {
        if model.selectedMode == .training { return "START TRAINING" }
        if model.selectedMode == .versus {
            return model.versusOpponent == .bot
                ? "START BOT FIGHT" : "FIND FIGHT"
        }
        return "START GAME"
    }

    private var startButtonIcon: String {
        if model.selectedMode == .training {
            return "figure.strengthtraining.traditional"
        }
        return model.selectedMode == .versus ? "person.2.fill" : "bolt.fill"
    }

    var body: some View {

        VStack(spacing: 12) {

            HStack {

                Button("BACK", systemImage: "chevron.left") {

                    if step == .character {

                        model.returnToMenu()

                    } else {

                        step = step.previous

                    }

                }

                Spacer()

                Text("\(step.rawValue + 1) / 3")

                    .font(.caption.monospaced().weight(.black))

                    .foregroundStyle(StyleTriggerPalette.cyan)

            }

            NeonHeader(

                kicker: model.selectedMode.displayName,

                title: step.title,

                icon: step.icon

            )

            ScrollView {

                VStack(spacing: 16) {

                    switch step {

                    case .character:

                        CharacterRosterView(
                            characters: model.content?.characters ?? [],
                            selectedCharacterID: model.progress.selectedCharacterID,
                            accountLevel: model.accountLevel,
                            isUnlocked: model.isCharacterUnlocked,
                            select: { model.selectCharacter($0.id) },
                            showDetails: { detailCharacter = $0 }
                        )

                    case .environment:
                        if model.selectedMode == .story {
                            if let chapter = model.story.selectedChapter {
                                VStack(spacing: 12) {
                                    ArenaPreview(
                                        environmentID: chapter.environmentID
                                    )
                                    .frame(height: 150)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16)
                                    )

                                    Text(chapter.title)
                                        .font(
                                            .headline.monospaced().weight(
                                                .black
                                            )
                                        )

                                    Label(
                                        chapter.environmentID
                                            .replacingOccurrences(
                                                of: "-",
                                                with: " "
                                            )
                                            .uppercased(),
                                        systemImage: "lock.fill"
                                    )
                                    .foregroundStyle(StyleTriggerPalette.cyan)

                                    Text("STORY ARENA")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                ContentUnavailableView(
                                    "NO CHAPTER SELECTED",
                                    systemImage: "book.closed",
                                    description: Text(
                                        "Select a story chapter before choosing an arena."
                                    )
                                )

                                Button("BACK TO STORY") {
                                    model.openLobby(for: .story)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(StyleTriggerPalette.cyan)
                            }
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.flexible())],
                                spacing: 14
                            ) {
                                ForEach(model.story.arenas) { arena in
                                    EnvironmentSelectionCard(
                                        id: arena.id,
                                        name: arena.name,
                                        isSelected:
                                            model.progress.selectedEnvironmentID
                                            == arena.id
                                    ) {
                                        model.selectEnvironment(arena.id)
                                    }
                                }
                            }

                            Button("RANDOM ARENA", systemImage: "shuffle") {
                                model.chooseRandomEnvironment()
                            }
                            .buttonStyle(.bordered)
                            .tint(StyleTriggerPalette.cyan)
                        }

                    case .ready:

                        ReadyMatchCard(model: model)

                        if model.selectedMode == .story {
                            Label(
                                model.selectedDifficulty,
                                systemImage: "lock.fill"
                            )
                            .foregroundStyle(StyleTriggerPalette.cyan)
                        } else {
                            StyleTriggerDifficultyPicker(
                                selection: Bindable(model).selectedDifficulty
                            )
                        }

                        if model.selectedMode == .versus {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("OPPONENT")
                                    .font(.caption.monospaced().weight(.black))
                                    .foregroundStyle(StyleTriggerPalette.cyan)

                                Picker(
                                    "Opponent",
                                    selection: Bindable(model).versusOpponent
                                ) {
                                    ForEach(VersusOpponent.allCases) {
                                        opponent in
                                        Label(
                                            opponent.title,
                                            systemImage: opponent.icon
                                        )
                                        .tag(opponent)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if model.versusOpponent == .gameCenter {
                                    Picker(
                                        "Team Size",
                                        selection: Bindable(model)
                                            .selectedTeamSize
                                    ) {
                                        ForEach(1...4, id: \.self) { size in
                                            Text("\(size)V\(size)").tag(size)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                } else {
                                    Label(
                                        "LOCAL BOT · \(model.selectedDifficulty.uppercased())",
                                        systemImage: "cpu"
                                    )
                                    .font(.caption.monospaced().weight(.bold))
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .background(
                                StyleTriggerPalette.panel.opacity(0.82),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }

                        StyleTriggerBoostLoadout(model: model)

                        Button {

                            model.startSelectedMatch()

                        } label: {

                            Label(
                                startButtonTitle,
                                systemImage: startButtonIcon
                            )

                            .font(.headline.monospaced().weight(.black))

                            .frame(maxWidth: .infinity)

                            .padding(.vertical, 14)

                        }

                        .buttonStyle(.borderedProminent)

                        .tint(StyleTriggerPalette.magenta)

                    }

                }

                .padding(.bottom, 12)

            }

            if step != .ready {

                Button {

                    step = step.next

                } label: {

                    Label("CONTINUE", systemImage: "chevron.right")

                        .font(.headline.monospaced().weight(.black))

                        .frame(maxWidth: .infinity)

                        .padding(.vertical, 12)

                }

                .buttonStyle(StyleTriggerPrimaryButtonStyle())

                .padding(.bottom, 6)

            }

        }

        .padding(.horizontal, 20)

        .padding(.top, 12)

        .buttonStyle(.plain)

        .sheet(item: $detailCharacter) { character in

            CharacterDetailView(model: model, character: character)

                .presentationDetents([.large])

                .presentationDragIndicator(.visible)

        }

    }

}

private enum LobbyStep: Int {

    case character

    case environment

    case ready

    var title: LocalizedStringResource {

        switch self {

        case .character: "CHOOSE FIGHTER"

        case .environment: "CHOOSE ARENA"

        case .ready: "READY TO FIGHT"

        }

    }

    var icon: String {

        switch self {

        case .character: "person.fill"

        case .environment: "building.2.fill"

        case .ready: "bolt.fill"

        }

    }

    var next: LobbyStep { LobbyStep(rawValue: rawValue + 1) ?? .ready }

    var previous: LobbyStep { LobbyStep(rawValue: rawValue - 1) ?? .character }

}

private struct CharacterDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let model: StyleTriggerViewModel

    let character: GameCharacter

    var body: some View {

        ZStack {

            StyleTriggerBackground()

            ScrollView {

                VStack(spacing: 14) {

                    HStack {

                        Text(character.name)

                            .font(.title.monospaced().weight(.black))

                        Spacer()

                        Button("DONE", action: dismiss.callAsFunction)

                            .font(.caption.monospaced().weight(.black))

                            .foregroundStyle(StyleTriggerPalette.cyan)

                    }

                    StyleTriggerFighterArtwork(

                        name: character.name,

                        appearance: activeAppearance

                    )

                    .frame(height: 250)

                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    Text(character.description)

                        .font(.subheadline)

                        .foregroundStyle(
                            StyleTriggerPalette.silver.opacity(0.72)
                        )

                    Label(
                        model.isCharacterUnlocked(character)
                            ? "UNLOCKED"
                            : "UNLOCKS AT LEVEL \(character.unlockLevel)",
                        systemImage: model.isCharacterUnlocked(character)
                            ? "checkmark.seal.fill"
                            : "lock.fill"
                    )
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(
                        model.isCharacterUnlocked(character)
                            ? StyleTriggerPalette.cyan
                            : StyleTriggerPalette.magenta
                    )

                    detailSection("SKINS") {

                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 150), spacing: 12)
                            ],
                            spacing: 8
                        ) {

                            ForEach(model.skins(for: character)) { skin in

                                let unlocked = model.progress.unlockedSkinIDs
                                    .contains(skin.id)

                                Button {

                                    model.selectSkin(skin.id, for: character.id)

                                } label: {

                                    Label(

                                        skin.name,

                                        systemImage: unlocked
                                            ? "circle.hexagongrid.fill"
                                            : "lock.fill"

                                    )

                                    .font(.caption.monospaced().weight(.black))

                                    .frame(maxWidth: .infinity)

                                    .padding(10)

                                    .background(

                                        selectedSkinID == skin.id

                                            ? StyleTriggerPalette.cyan.opacity(
                                                0.2
                                            )

                                            : StyleTriggerPalette.raisedPanel,

                                        in: RoundedRectangle(cornerRadius: 9)

                                    )

                                }

                                .disabled(
                                    !unlocked
                                        || !model.isCharacterUnlocked(character)
                                )

                            }

                        }

                    }

                    detailSection("WEAPONS") {

                        ForEach(model.compatibleWeapons(for: character)) {
                            weapon in

                            let equipped = equippedIDs.contains(weapon.id)

                            let unlocked = model.progress.unlockedWeaponIDs
                                .contains(weapon.id)

                            Button {

                                if model.progress.selectedCharacterID
                                    == character.id
                                {

                                    model.toggleEquippedWeapon(weapon.id)

                                }

                            } label: {

                                HStack {

                                    WeaponIcon(
                                        type: weapon.type,
                                        color: Color(
                                            hex: character.appearance
                                                .weaponColor
                                        )
                                    )

                                    .frame(width: 42, height: 42)

                                    VStack(alignment: .leading) {

                                        Text(weapon.name)

                                            .font(
                                                .caption.monospaced().weight(
                                                    .black
                                                )
                                            )

                                        Text(
                                            "DMG \(weapon.damage)  SPD \(weapon.attackSpeed, format: .number.precision(.fractionLength(2)))"
                                        )

                                        .font(.caption2.monospaced())

                                        .foregroundStyle(.secondary)

                                    }

                                    Spacer()

                                    Image(
                                        systemName: unlocked
                                            ? (equipped
                                                ? "checkmark.circle.fill"
                                                : "circle") : "lock.fill"
                                    )

                                }

                                .padding(9)

                                .background(
                                    StyleTriggerPalette.raisedPanel,
                                    in: RoundedRectangle(cornerRadius: 9)
                                )

                            }

                            .disabled(
                                !unlocked
                                    || model.progress.selectedCharacterID
                                        != character.id
                            )

                        }

                    }

                    detailSection("COMBOS") {

                        ForEach(characterCombos) { combo in

                            ComboRow(
                                combo: combo,
                                localizedName: model.localizedGameText(
                                    combo.name
                                )
                            )

                        }

                    }

                }

                .padding(18)

            }

        }

        .preferredColorScheme(.dark)

    }

    private var selectedSkinID: String? {

        model.progress.selectedSkinByCharacter[character.id]

    }

    private var activeAppearance: CharacterAppearance {

        model.skins(for: character).first { $0.id == selectedSkinID }?
            .appearance

            ?? character.appearance

    }

    private var equippedIDs: Set<String> {

        Set(
            model.progress.equippedWeaponIDsByCharacter[character.id]
                ?? character.defaultWeaponIDs
        )

    }

    private var characterCombos: [ComboDefinition] {

        let ids = Set(character.baseComboList)

        return model.content?.combos.filter { ids.contains($0.id) } ?? []

    }

    private func detailSection<Content: View>(

        _ title: LocalizedStringResource,

        @ViewBuilder content: () -> Content

    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title)

                .font(.caption.monospaced().weight(.black))

                .foregroundStyle(StyleTriggerPalette.cyan)

            content()

        }

        .frame(maxWidth: .infinity, alignment: .leading)

    }

}

private struct EnvironmentSelectionCard: View {

    let id: String

    let name: String

    let isSelected: Bool

    let action: () -> Void

    var body: some View {

        Button(action: action) {

            ZStack(alignment: .bottomLeading) {

                ArenaPreview(environmentID: id)

                    .frame(height: 106)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack {

                    Text(name)

                        .font(.headline.monospaced().weight(.black))

                    Spacer()

                    Image(
                        systemName: isSelected
                            ? "checkmark.circle.fill" : "circle"
                    )

                    .foregroundStyle(StyleTriggerPalette.cyan)

                }

                .padding(14)

            }

            .clipShape(RoundedRectangle(cornerRadius: 16))

            .overlay {

                RoundedRectangle(cornerRadius: 16)

                    .stroke(
                        isSelected
                            ? StyleTriggerPalette.cyan : .white.opacity(0.12),
                        lineWidth: 2
                    )

            }

        }

    }

}

private struct ArenaPreview: View {

    let environmentID: String

    var body: some View {

        GeometryReader { proxy in

            ZStack {

                LinearGradient(
                    colors: colors,
                    startPoint: .top,
                    endPoint: .bottom
                )

                ForEach(0..<7, id: \.self) { index in

                    Rectangle()

                        .fill(
                            index.isMultiple(of: 2)
                                ? StyleTriggerPalette.cyan.opacity(0.25)
                                : StyleTriggerPalette.magenta.opacity(0.18)
                        )

                        .frame(
                            width: proxy.size.width / 10,
                            height: CGFloat(45 + index * 15)
                        )

                        .position(
                            x: CGFloat(index) * proxy.size.width / 6,
                            y: proxy.size.height * 0.67
                        )

                }

                Path { path in

                    path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.72))

                    path.addLine(
                        to: CGPoint(
                            x: proxy.size.width,
                            y: proxy.size.height * 0.58
                        )
                    )

                    path.addLine(
                        to: CGPoint(x: proxy.size.width, y: proxy.size.height)
                    )

                    path.addLine(to: CGPoint(x: 0, y: proxy.size.height))

                    path.closeSubpath()

                }

                .fill(.black.opacity(0.62))

                Image(systemName: symbol)

                    .font(.system(size: 54, weight: .thin))

                    .foregroundStyle(StyleTriggerPalette.silver.opacity(0.5))

            }

        }

    }

    private var colors: [Color] {

        switch environmentID {

        case "void-cathedral": [Color(hex: "30103D"), Color(hex: "09050D")]

        case "chrome-subway": [Color(hex: "1B3B45"), Color(hex: "070A0B")]

        default: [Color(hex: "073D4B"), Color(hex: "090A12")]

        }

    }

    private var symbol: String {

        switch environmentID {

        case "void-cathedral": "building.columns.fill"

        case "chrome-subway": "tram.fill"

        default: "building.2.crop.circle.fill"

        }

    }

}

private struct ReadyMatchCard: View {

    let model: StyleTriggerViewModel

    var body: some View {

        VStack(spacing: 12) {

            if let character = model.selectedCharacter,

                let appearance = model.selectedAppearance

            {

                StyleTriggerFighterArtwork(

                    name: character.name,

                    appearance: appearance,

                    weaponType: model.selectedWeapon?.type

                )

                .frame(height: 130)

            }

            ArenaPreview(environmentID: model.progress.selectedEnvironmentID)

                .frame(height: 100)

                .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack {

                Text(model.selectedCharacter?.name ?? "FIGHTER")

                Spacer()

                Text(environmentName)

                    .foregroundStyle(StyleTriggerPalette.cyan)

            }

            .font(.headline.monospaced().weight(.black))

        }

        .padding(14)

        .background(
            StyleTriggerPalette.panel.opacity(0.9),
            in: RoundedRectangle(cornerRadius: 18)
        )

    }

    private var environmentName: String {

        switch model.progress.selectedEnvironmentID {

        case "void-cathedral": "VOID CATHEDRAL"

        case "chrome-subway": "CHROME SUBWAY"

        default: "NEON ROOFTOP"

        }

    }

}

private struct CombatScreen: View {

    let model: StyleTriggerViewModel

    @State private var scene = ActionGameScene(

        size: CGSize(width: 390, height: 844)

    )

    var body: some View {

        ZStack {

            SpriteView(scene: scene, options: [.ignoresSiblingOrder])

                .ignoresSafeArea()

            VStack {

                CombatHUD(model: model)

                Spacer()

            }

            .padding(.top, 34)

            VStack {
                HStack {
                    Spacer()

                    Button("EXIT", systemImage: "xmark") {
                        model.finishMatch(didWin: false)
                    }
                    .buttonStyle(.bordered)
                    .tint(StyleTriggerPalette.magenta)
                }
                .padding(.top, 200)

                Spacer()

                if model.equippedWeapons.count > 1 {
                    CombatWeaponSwitcher(
                        weapons: model.equippedWeapons,
                        activeWeaponID: model.progress.selectedWeaponID
                    ) { weaponID in
                        scene.equipWeapon(id: weaponID)
                    }
                    .padding(.bottom, 30)
                }
            }

            if model.isRevivePromptPresented {
                StyleTriggerReviveOverlay(
                    reviveCount: model.reviveCount,
                    useRevive: {
                        if model.consumeRevive() {
                            scene.revivePlayer()
                        }
                    },
                    giveUp: model.declineRevive
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(20)
            }
        }

        .animation(
            .snappy(duration: 0.24),
            value: model.isRevivePromptPresented
        )
        .onAppear {

            scene.scaleMode = .aspectFill

            if let appearance = model.selectedAppearance {

                scene.configure(

                    appearance: appearance,

                    weapons: model.equippedWeapons,

                    activeWeaponID: model.progress.selectedWeaponID,

                    combos: model.content?.combos ?? [],

                    targetFrameRate: model.progress.targetFrameRate,

                    graphicsQuality: model.progress.graphicsQuality,

                    effectsEnabled: model.progress.combatEffectsEnabled,

                    screenShakeEnabled: model.progress.screenShakeEnabled,
                    trainingMode: model.selectedMode == .training,
                    attackMultiplier: 1 + model.boostMagnitude(.attackBoost)
                        + model.boostMagnitude(.weaponDamageBoost),
                    speedMultiplier: 1 + model.boostMagnitude(.speedBoost),
                    styleMultiplier: 1 + model.boostMagnitude(.styleBoost),
                    healthMultiplier: 1 + model.boostMagnitude(.healthBoost),

                    environmentID: model.selectedMode == .story
                        ? (model.story.selectedChapter?.environmentID
                            ?? model.progress.selectedEnvironmentID)
                        : model.progress.selectedEnvironmentID,

                    storyEnemies: model.selectedMode == .story
                        ? model.story.selectedChapter.map {
                            model.story.enemies(for: $0)
                        } ?? []
                        : [],

                    isStoryMode: model.selectedMode == .story

                )

            }

            scene.onCombatSnapshot = { snapshot in

                model.receiveCombatSnapshot(snapshot)

            }

            scene.onLocalInput = { input in

                if model.selectedMode == .versus,
                    model.versusOpponent == .gameCenter
                {
                    model.multiplayer.send(input)
                }

            }

            scene.onWeaponChanged = { weaponID in

                model.selectWeapon(weaponID)

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

        HStack(spacing: 8) {

            StyleTriggerBattleBar(

                name: model.selectedCharacter?.name ?? "VEX",

                health: model.combat.playerHealth,

                color: StyleTriggerPalette.cyan,

                alignment: .leading

            )

            VStack(spacing: 2) {

                Text(timeString)

                    .font(
                        .system(.headline, design: .monospaced, weight: .black)
                    )

                Text(model.combat.styleRank.letter)

                    .font(

                        .system(.title, design: .rounded, weight: .black)

                    )

                    .foregroundStyle(StyleTriggerPalette.magenta)

            }

            .frame(width: 68)

            StyleTriggerBattleBar(

                name: model.selectedMode == .training
                    ? "TRAINING DUMMY"
                    : (model.content?.enemies.first?.name ?? "WRAITH"),

                health: model.combat.enemyHealth,

                color: StyleTriggerPalette.magenta,

                alignment: .trailing

            )

        }

        .padding(.horizontal, 12)

        .padding(.top, 8)

    }

    private var timeString: String {
        if model.selectedMode == .training {
            return "∞"
        }

        return String(

            format: "%02d:%02d",

            model.remainingSeconds / 60,

            model.remainingSeconds % 60

        )

    }

}

private struct MatchResultsView: View {

    let model: StyleTriggerViewModel

    var body: some View {

        ScrollView {

            VStack(spacing: 16) {

                Text(model.result?.didWin == true ? "JACKPOT!" : "STYLE BROKEN")

                    .font(
                        .system(
                            .largeTitle,
                            design: .monospaced,
                            weight: .black
                        )
                    )

                    .foregroundStyle(

                        model.result?.didWin == true

                            ? StyleTriggerPalette.cyan
                            : StyleTriggerPalette.magenta

                    )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                    spacing: 12
                ) {

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

                Button("RETURN TO MENU", systemImage: "arrow.counterclockwise")
                {

                    model.returnToMenu()

                }

                .buttonStyle(.borderedProminent)

                .tint(StyleTriggerPalette.cyan)

            }

            .padding(24)

        }

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

        .frame(maxWidth: .infinity, minHeight: 92)

        .padding(16)

        .background(

            StyleTriggerPalette.panel,

            in: RoundedRectangle(cornerRadius: 14)

        )

    }

}

struct StyleTriggerBackground: View {

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
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        let expanded: String
        switch cleaned.count {
        case 3, 4:
            expanded = cleaned.map { "\($0)\($0)" }.joined()
        case 6, 8:
            expanded = cleaned
        default:
            self = .clear
            return
        }

        guard let value = UInt64(expanded, radix: 16) else {
            self = .clear
            return
        }

        let hasAlpha = expanded.count == 8
        let red = hasAlpha ? (value >> 24) & 0xFF : (value >> 16) & 0xFF
        let green = hasAlpha ? (value >> 16) & 0xFF : (value >> 8) & 0xFF
        let blue = hasAlpha ? (value >> 8) & 0xFF : value & 0xFF
        let alpha = hasAlpha ? value & 0xFF : 255

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

#Preview("Menü") {
    StyleTriggerMainView()
}

#Preview("Kampf") {
    StyleTriggerCombatPreview()
}

// Preview-only wrapper: lädt echte Spieldaten und startet einen lokalen Kampf.
private struct StyleTriggerCombatPreview: View {
    @State private var model = StyleTriggerViewModel()

    var body: some View {
        ZStack {
            StyleTriggerBackground()

            if model.screen == .combat {
                CombatScreen(model: model)
            } else if let error = model.loadError {
                DataErrorView(message: error) {
                    Task { await prepareCombat() }
                }
            } else {
                ProgressView("LOADING COMBAT PREVIEW")
                    .tint(StyleTriggerPalette.cyan)
            }
        }
        .preferredColorScheme(.dark)
        .task { await prepareCombat() }
    }

    @MainActor
    private func prepareCombat() async {
        if model.content == nil {
            await model.load()
        }
        guard model.content != nil, model.screen != .combat else { return }
        model.openLobby(for: .arcade)
        model.startMatch()
    }
}
