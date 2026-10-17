//
//  NeonHeader.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SwiftUI

struct NeonHeader: View {

    let kicker: LocalizedStringResource

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
