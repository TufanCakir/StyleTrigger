//
//  StyleTriggerProgressionViews.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SwiftUI

struct AccountTitleFrame: Shape {

    let tier: Int

    func path(in rect: CGRect) -> Path {

        let cut = min(rect.height * 0.32, CGFloat(6 + tier * 2))

        var path = Path()

        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))

        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))

        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))

        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))

        path.closeSubpath()

        if tier >= 4 {

            path.move(to: CGPoint(x: rect.midX - 9, y: rect.minY))

            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY - 5))

            path.addLine(to: CGPoint(x: rect.midX + 9, y: rect.minY))

        }

        return path

    }

}

struct StyleTriggerAccountHeader: View {

    let model: StyleTriggerViewModel

    var body: some View {

        HStack(spacing: 10) {

            VStack(alignment: .leading, spacing: 1) {

                Text("ACCOUNT")

                    .font(.system(size: 8, weight: .black, design: .monospaced))

                    .foregroundStyle(.secondary)

                Text("LV \(model.accountLevel)")

                    .font(.caption.monospaced().weight(.black))

                    .foregroundStyle(StyleTriggerPalette.cyan)

            }

            if let title = model.currentAccountTitle {

                Text(model.localizedGameText(title.name))

                    .font(

                        .system(size: 10, weight: .black, design: .monospaced)

                    )

                    .lineLimit(1)

                    .padding(.horizontal, 13)

                    .padding(.vertical, 7)

                    .background(

                        AccountTitleFrame(tier: title.tier)

                            .fill(Color(hex: title.color).opacity(0.13))

                    )

                    .overlay {

                        AccountTitleFrame(tier: title.tier)

                            .stroke(

                                Color(hex: title.color),

                                lineWidth: CGFloat(1 + title.tier / 3)

                            )

                    }

                    .shadow(

                        color: Color(hex: title.color).opacity(0.4),

                        radius: CGFloat(title.tier)

                    )

            }

            Spacer()

            Label(

                "\(model.progress.styleShards)",

                systemImage: "diamond.fill"

            )

            .font(.caption.monospaced().weight(.black))

            .foregroundStyle(StyleTriggerPalette.magenta)

            .accessibilityLabel("\(model.progress.styleShards) Style Shards")

        }

        .padding(.horizontal, StyleTriggerMetrics.screenPadding)

        .padding(.vertical, 7)

        .background(StyleTriggerPalette.background.opacity(0.94))

    }

}

struct StyleTriggerShopView: View {
    @Bindable var model: StyleTriggerViewModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Label("STYLE SHOP", systemImage: "cart.fill")
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(StyleTriggerPalette.magenta)

                    Spacer(minLength: 8)

                    Label(
                        "\(model.progress.styleShards)",
                        systemImage: "diamond.fill"
                    )
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(StyleTriggerPalette.cyan)
                    .accessibilityLabel(
                        "\(model.progress.styleShards) Style Shards"
                    )
                }

                shopSection("COMBO STRINGS", items: comboItems)
                shopSection("COMBAT ITEMS", items: consumables)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }

    private var comboItems: [ShopItem] {
        model.content?.shopItems.filter { $0.productType == .combo } ?? []
    }

    private var consumables: [ShopItem] {
        model.content?.shopItems.filter { $0.productType == .consumable } ?? []
    }

    private func shopSection(
        _ title: LocalizedStringResource,
        items: [ShopItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(title)
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(StyleTriggerPalette.silver)

                Spacer()

                Text("\(items.count)")
                    .font(.caption2.monospaced().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if items.isEmpty {
                Text("NO ITEMS AVAILABLE")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVStack(spacing: 9) {
                    ForEach(items) { item in
                        ShopItemRow(model: model, item: item)
                    }
                }
            }
        }
    }
}

private struct ShopItemRow: View {

    let model: StyleTriggerViewModel

    let item: ShopItem

    var body: some View {

        StyleTriggerPanel {

            HStack(spacing: 10) {

                Image(systemName: icon)

                    .font(.title3)

                    .foregroundStyle(

                        item.productType == .combo

                            ? StyleTriggerPalette.cyan

                            : StyleTriggerPalette.magenta

                    )

                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {

                    Text(model.localizedGameText(item.name))

                        .font(.caption.monospaced().weight(.black))

                    Text(model.localizedGameText(item.description))

                        .font(.caption2)

                        .foregroundStyle(.secondary)

                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if item.productType == .consumable {

                        Text(

                            "OWNED \(model.progress.consumableInventory[item.id, default: 0])"

                        )

                        .font(

                            .system(

                                size: 9,

                                weight: .black,

                                design: .monospaced

                            )

                        )

                        .foregroundStyle(StyleTriggerPalette.cyan)

                    }

                }

                Spacer()

                Button {

                    _ = model.purchase(item)

                } label: {

                    if isOwnedCombo {

                        Image(systemName: "checkmark")

                    } else {

                        Label("\(item.price)", systemImage: "diamond.fill")

                    }

                }

                .font(.caption2.monospaced().weight(.black))

                .buttonStyle(.bordered)

                .tint(StyleTriggerPalette.magenta)

                .disabled(

                    isOwnedCombo || model.progress.styleShards < item.price

                )

            }

        }

    }

    private var isOwnedCombo: Bool {

        guard let comboID = item.comboID else { return false }

        return model.progress.purchasedComboIDs.contains(comboID)

    }

    private var icon: String {

        switch item.effect {

        case .revive: "heart.circle.fill"

        case .attackBoost: "burst.fill"

        case .experienceBoost: "star.fill"

        case .speedBoost: "hare.fill"

        case .styleBoost: "s.circle.fill"

        case .healthBoost: "cross.case.fill"

        case .weaponDamageBoost: "bolt.fill"

        case .none: "text.badge.plus"

        }

    }

}

struct StyleTriggerBoostLoadout: View {

    let model: StyleTriggerViewModel

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("MATCH BOOSTS")

                .font(.caption2.monospaced().weight(.black))

                .foregroundStyle(.secondary)

            LazyVGrid(

                columns: [GridItem(.flexible()), GridItem(.flexible())],

                spacing: 7

            ) {

                ForEach(boosts) { item in

                    let active = model.progress.activeBoostIDs.contains(item.id)

                    Button {

                        model.toggleBoost(item)

                    } label: {

                        HStack {

                            Text(item.name)

                                .lineLimit(1)

                            Spacer()

                            Text(

                                active

                                    ? "ON"

                                    : "×\(model.progress.consumableInventory[item.id, default: 0])"

                            )

                        }

                        .font(

                            .system(

                                size: 9,

                                weight: .black,

                                design: .monospaced

                            )

                        )

                        .padding(8)

                        .foregroundStyle(

                            active

                                ? StyleTriggerPalette.background

                                : StyleTriggerPalette.silver

                        )

                        .background(

                            active

                                ? StyleTriggerPalette.cyan

                                : StyleTriggerPalette.raisedPanel,

                            in: RoundedRectangle(cornerRadius: 8)

                        )

                    }

                    .buttonStyle(.plain)

                    .disabled(

                        !active

                            && model.progress.consumableInventory[

                                item.id,

                                default: 0

                            ] == 0

                    )

                }

            }

        }

    }

    private var boosts: [ShopItem] {

        model.content?.shopItems.filter {

            $0.productType == .consumable && $0.effect != .revive

        } ?? []

    }

}

struct StyleTriggerReviveOverlay: View {

    let reviveCount: Int

    let useRevive: () -> Void

    let giveUp: () -> Void

    var body: some View {

        ZStack {

            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 14) {

                Image(systemName: "heart.circle.fill")

                    .font(.system(size: 54))

                    .foregroundStyle(StyleTriggerPalette.magenta)

                    .shadow(color: StyleTriggerPalette.magenta, radius: 14)

                Text("STYLE BROKEN")

                    .font(.title.monospaced().weight(.black))

                Text(

                    "Use a Revive Core and return with \(0.5, format: .percent) HP?"

                )

                .font(.subheadline)

                .foregroundStyle(.secondary)

                .multilineTextAlignment(.center)

                Button(

                    "REVIVE  ×\(reviveCount)",

                    systemImage: "bolt.heart.fill",

                    action: useRevive

                )

                .buttonStyle(

                    StyleTriggerPrimaryButtonStyle(

                        color: StyleTriggerPalette.magenta

                    )

                )

                Button("END RUN", action: giveUp)

                    .font(.caption.monospaced().weight(.black))

                    .foregroundStyle(.secondary)

            }

            .padding(24)

            .frame(maxWidth: 330)

            .background(

                StyleTriggerPalette.panel,

                in: RoundedRectangle(cornerRadius: 20)

            )

            .overlay {

                RoundedRectangle(cornerRadius: 20)

                    .stroke(StyleTriggerPalette.magenta, lineWidth: 2)

            }

        }

    }

}
