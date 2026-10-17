import SwiftUI

struct CombatWeaponSwitcher: View {
    let weapons: [Weapon]
    let activeWeaponID: Weapon.ID
    let selectWeapon: (Weapon.ID) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weapons) { weapon in
                Button {
                    selectWeapon(weapon.id)
                } label: {
                    VStack(spacing: 4) {
                        WeaponIcon(
                            type: weapon.type,
                            color: activeWeaponID == weapon.id
                                ? StyleTriggerPalette.panel
                                : StyleTriggerPalette.cyan
                        )
                        .frame(width: 34, height: 28)

                        Text(weapon.name)
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: 82, height: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(
                    activeWeaponID == weapon.id
                        ? StyleTriggerPalette.panel
                        : StyleTriggerPalette.silver
                )
                .background(
                    activeWeaponID == weapon.id
                        ? StyleTriggerPalette.cyan
                        : StyleTriggerPalette.panel.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(StyleTriggerPalette.cyan.opacity(0.65))
                }
                .disabled(activeWeaponID == weapon.id)
                .accessibilityLabel(weapon.name)
                .accessibilityValue(
                    activeWeaponID == weapon.id ? "EQUIPPED" : "AVAILABLE"
                )
                .accessibilityHint("Switch weapon")
            }
        }
        .padding(8)
        .background(.black.opacity(0.55), in: Capsule())
    }
}
