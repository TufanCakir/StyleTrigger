//
//  CharacterIconView.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SpriteKit
import SwiftUI

struct CharacterIconView: View {
    var body: some View {
        ZStack {
            // Hintergrund-Schild
            Circle()
                .fill(Color.black)
                .frame(width: 120, height: 120)
                .overlay(Circle().stroke(Color.red, lineWidth: 3))
                .shadow(color: .red.opacity(0.5), radius: 10)

            // Der gezeichnete Helm
            Path { path in
                // Start am Kinn
                path.move(to: CGPoint(x: 60, y: 95))
                // Linke Kieferlinie nach oben
                path.addLine(to: CGPoint(x: 35, y: 60))
                // Linke Schläfe / Helm-Kante
                path.addLine(to: CGPoint(x: 30, y: 35))
                // Obere Helm-Spitze (Kantig)
                path.addLine(to: CGPoint(x: 60, y: 20))
                // Rechte Schläfe
                path.addLine(to: CGPoint(x: 90, y: 35))
                path.addLine(to: CGPoint(x: 85, y: 60))
                // Zurück zum Kinn
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [.black, .gray],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Das glühende Cyber-Visier
            Path { path in
                path.move(to: CGPoint(x: 40, y: 45))
                path.addLine(to: CGPoint(x: 80, y: 45))
                path.addLine(to: CGPoint(x: 75, y: 52))
                path.addLine(to: CGPoint(x: 45, y: 52))
                path.closeSubpath()
            }
            .fill(Color.cyan)
            .shadow(color: .cyan, radius: 8)
        }
        .frame(width: 120, height: 120)
    }

    func createAdvancedPlayer() -> SKNode {
        let playerNode = SKNode()

        // Kantiger Körper (Silhouette)
        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: -15, y: -30))
        bodyPath.addLine(to: CGPoint(x: 15, y: -30))
        bodyPath.addLine(to: CGPoint(x: 20, y: 20))
        bodyPath.addLine(to: CGPoint(x: 0, y: 35))
        bodyPath.addLine(to: CGPoint(x: -20, y: 20))
        bodyPath.closeSubpath()

        let body = SKShapeNode(path: bodyPath)
        body.fillColor = .black
        body.strokeColor = .systemRed
        body.lineWidth = 3
        playerNode.addChild(body)

        // Leuchtendes Visier
        let visorPath = CGMutablePath()
        visorPath.move(to: CGPoint(x: -5, y: 20))
        visorPath.addLine(to: CGPoint(x: 15, y: 15))
        let visor = SKShapeNode(path: visorPath)
        visor.strokeColor = .cyan
        visor.lineWidth = 4
        visor.glowWidth = 4
        playerNode.addChild(visor)

        // Das Breitschwert (als eigenes Node)
        let swordPath = CGMutablePath()
        // Klinge zeichnen (zeigt nach oben)
        swordPath.move(to: CGPoint(x: 0, y: 0))  // Griffbasis
        swordPath.addLine(to: CGPoint(x: -5, y: 15))  // Parierstange
        swordPath.addLine(to: CGPoint(x: -5, y: 70))  // Klinge links
        swordPath.addLine(to: CGPoint(x: 0, y: 85))  // Schwertspitze
        swordPath.addLine(to: CGPoint(x: 5, y: 70))  // Klinge rechts
        swordPath.addLine(to: CGPoint(x: 5, y: 15))  // Parierstange rechts
        swordPath.closeSubpath()

        let sword = SKShapeNode(path: swordPath)
        sword.name = "sword"  // WICHTIG: Name für die Suche im Code
        sword.fillColor = .lightGray
        sword.strokeColor = .white
        sword.lineWidth = 2

        // Positioniere das Schwert im Zentrum des Spielers
        sword.position = CGPoint(x: 0, y: 0)
        // Standard-Ruheposition: Leicht schräg auf dem Rücken
        sword.zRotation = CGFloat.pi / 4

        playerNode.addChild(sword)

        return playerNode
    }
}
