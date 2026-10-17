//
//  ScoreSummary.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import GameKit
import SpriteKit
import SwiftUI
import UIKit

struct ScoreSummary: View {

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
