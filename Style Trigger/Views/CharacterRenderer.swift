//
//  CharacterRenderer.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SpriteKit
import SwiftUI

@MainActor

final class StyleTriggerFighterRig: SKNode {

    enum Motion: String, CaseIterable {

        case idle, slash, punch, jump

    }

    struct Theme {

        var primary: SKColor = .cyan

        var secondary: SKColor = SKColor(white: 0.30, alpha: 1)

        var visor: SKColor = .cyan

        var weapon: SKColor = .white

    }

    private enum Layout {

        static let shoulderY: CGFloat = 49

        static let shoulderX: CGFloat = 17

        static let upperArm: CGFloat = 29

        static let forearm: CGFloat = 27

        static let hipX: CGFloat = 9

        static let thigh: CGFloat = 37

        static let shin: CGFloat = 37

    }

    private struct JointPose {

        let node: SKNode

        let position: CGPoint

        let rotation: CGFloat

        let scaleX: CGFloat

        let scaleY: CGFloat

    }

    private let torso = SKNode()

    private let head = SKNode()

    private let leftShoulder = SKNode()

    private let rightShoulder = SKNode()

    private let leftElbow = SKNode()

    private let rightElbow = SKNode()

    private let leftHand = SKNode()

    private let rightHand = SKNode()

    private let leftHip = SKNode()

    private let rightHip = SKNode()

    private let leftKnee = SKNode()

    private let rightKnee = SKNode()

    private let leftFoot = SKNode()

    private let rightFoot = SKNode()

    private let leftWeaponSocket = SKNode()

    private let rightWeaponSocket = SKNode()

    private var weaponNode: SKNode?

    private var restPose: [JointPose] = []

    private var animationGeneration = 0

    private(set) var currentMotion: Motion = .idle

    private let theme: Theme

    private let bodyColor = SKColor(

        red: 0.08,

        green: 0.10,

        blue: 0.15,

        alpha: 1

    )

    private static func radians(_ degrees: CGFloat) -> CGFloat {

        degrees * .pi / 180

    }

    override convenience init() {

        self.init(theme: Theme())

    }

    init(theme: Theme) {

        self.theme = theme

        super.init()

        buildRig()

        captureRestPose()

        equipSword()

        play(.idle)

    }

    required init?(coder: NSCoder) {

        return nil

    }

    private func segment(

        from start: CGPoint,

        to end: CGPoint,

        width: CGFloat,

        color: SKColor? = nil,

        glow: CGFloat = 0.5

    ) -> SKShapeNode {

        let path = CGMutablePath()

        path.move(to: start)

        path.addLine(to: end)

        let shape = SKShapeNode(path: path)

        shape.strokeColor = color ?? theme.secondary

        shape.lineWidth = width

        shape.lineCap = .round

        shape.glowWidth = glow

        shape.isAntialiased = true

        return shape

    }

    private func buildRig() {

        addChild(torso)

        torso.addChild(

            segment(from: .zero, to: CGPoint(x: 0, y: 58), width: 28)

        )

        torso.addChild(

            segment(

                from: CGPoint(x: 0, y: 8),

                to: CGPoint(x: 0, y: 51),

                width: 21,

                color: bodyColor

            )

        )

        head.position = CGPoint(x: 0, y: 70)

        torso.addChild(head)

        let helmet = SKShapeNode(

            rectOf: CGSize(width: 32, height: 37),

            cornerRadius: 8

        )

        helmet.fillColor = bodyColor

        helmet.strokeColor = theme.primary

        helmet.lineWidth = 2

        head.addChild(helmet)

        head.addChild(

            segment(

                from: CGPoint(x: -11, y: 3),

                to: CGPoint(x: 11, y: 3),

                width: 4,

                color: theme.visor,

                glow: 5

            )

        )

        leftShoulder.position = CGPoint(

            x: -Layout.shoulderX,

            y: Layout.shoulderY

        )

        rightShoulder.position = CGPoint(

            x: Layout.shoulderX,

            y: Layout.shoulderY

        )

        torso.addChild(leftShoulder)

        torso.addChild(rightShoulder)

        for shoulder in [leftShoulder, rightShoulder] {

            shoulder.addChild(

                segment(

                    from: .zero,

                    to: CGPoint(x: 0, y: -Layout.upperArm),

                    width: 11

                )

            )

        }

        leftElbow.position = CGPoint(x: 0, y: -Layout.upperArm)

        rightElbow.position = CGPoint(x: 0, y: -Layout.upperArm)

        leftShoulder.addChild(leftElbow)

        rightShoulder.addChild(rightElbow)

        for elbow in [leftElbow, rightElbow] {

            elbow.addChild(

                segment(

                    from: .zero,

                    to: CGPoint(x: 0, y: -Layout.forearm),

                    width: 9

                )

            )

        }

        leftHand.position = CGPoint(x: 0, y: -Layout.forearm)

        rightHand.position = CGPoint(x: 0, y: -Layout.forearm)

        leftElbow.addChild(leftHand)

        rightElbow.addChild(rightHand)

        for hand in [leftHand, rightHand] {

            let palm = SKShapeNode(circleOfRadius: 5)

            palm.fillColor = bodyColor

            palm.strokeColor = theme.primary

            palm.lineWidth = 1.5

            hand.addChild(palm)

        }

        leftHand.addChild(leftWeaponSocket)

        rightHand.addChild(rightWeaponSocket)

        leftHip.position = CGPoint(x: -Layout.hipX, y: 0)

        rightHip.position = CGPoint(x: Layout.hipX, y: 0)

        torso.addChild(leftHip)

        torso.addChild(rightHip)

        for hip in [leftHip, rightHip] {

            hip.addChild(

                segment(

                    from: .zero,

                    to: CGPoint(x: 0, y: -Layout.thigh),

                    width: 14

                )

            )

        }

        leftKnee.position = CGPoint(x: 0, y: -Layout.thigh)

        rightKnee.position = CGPoint(x: 0, y: -Layout.thigh)

        leftHip.addChild(leftKnee)

        rightHip.addChild(rightKnee)

        for knee in [leftKnee, rightKnee] {

            knee.addChild(

                segment(

                    from: .zero,

                    to: CGPoint(x: 0, y: -Layout.shin),

                    width: 10

                )

            )

        }

        leftFoot.position = CGPoint(x: 0, y: -Layout.shin)

        rightFoot.position = CGPoint(x: 0, y: -Layout.shin)

        leftKnee.addChild(leftFoot)

        rightKnee.addChild(rightFoot)

        for foot in [leftFoot, rightFoot] {

            foot.addChild(

                segment(

                    from: CGPoint(x: -4, y: 0),

                    to: CGPoint(x: 12, y: 0),

                    width: 8,

                    color: bodyColor

                )

            )

        }

        // A slightly open, mirrored stance. These are radians, not degrees.

        leftShoulder.zRotation = Self.radians(-12)

        rightShoulder.zRotation = Self.radians(12)

        leftHip.zRotation = Self.radians(-7)

        rightHip.zRotation = Self.radians(7)

    }

    private var joints: [SKNode] {

        [

            torso, head, leftShoulder, rightShoulder, leftElbow, rightElbow,

            leftHand, rightHand, leftHip, rightHip, leftKnee, rightKnee,

            leftFoot, rightFoot, leftWeaponSocket, rightWeaponSocket,

        ]

    }

    private func captureRestPose() {

        restPose = joints.map {

            JointPose(

                node: $0,

                position: $0.position,

                rotation: $0.zRotation,

                scaleX: $0.xScale,

                scaleY: $0.yScale

            )

        }

    }

    func equipSword() {

        unequipWeapon()

        let sword = SKNode()

        sword.addChild(

            segment(

                from: CGPoint(x: 0, y: 8),

                to: CGPoint(x: 0, y: 87),

                width: 6,

                color: theme.weapon,

                glow: 4

            )

        )

        sword.addChild(

            segment(

                from: CGPoint(x: -13, y: 9),

                to: CGPoint(x: 13, y: 9),

                width: 5,

                color: theme.primary

            )

        )

        rightWeaponSocket.addChild(sword)

        weaponNode = sword

    }

    func unequipWeapon() {

        weaponNode?.removeFromParent()

        weaponNode = nil

    }

    /// Stops all rig animation and restores the exact captured neutral pose.

    func resetPose() {

        animationGeneration &+= 1

        removeAction(forKey: "motionCompletion")

        for pose in restPose {

            pose.node.removeAllActions()

            pose.node.position = pose.position

            pose.node.zRotation = pose.rotation

            pose.node.xScale = pose.scaleX

            pose.node.yScale = pose.scaleY

        }

        weaponNode?.isHidden = false

        currentMotion = .idle

    }

    private func rotate(

        _ node: SKNode,

        degrees: CGFloat,

        duration: TimeInterval

    ) -> SKAction {

        .rotate(

            toAngle: Self.radians(degrees),

            duration: duration,

            shortestUnitArc: true

        )

    }

    private func returnToIdle(after duration: TimeInterval) {

        let generation = animationGeneration

        run(

            .sequence([

                .wait(forDuration: duration),

                .run { [weak self] in

                    guard let self, self.animationGeneration == generation

                    else { return }

                    self.play(.idle)

                },

            ]),

            withKey: "motionCompletion"

        )

    }

    func play(_ motion: Motion) {

        resetPose()

        currentMotion = motion

        switch motion {

        case .idle:

            let sway = SKAction.sequence([

                rotate(torso, degrees: 2, duration: 0.55),

                rotate(torso, degrees: -2, duration: 0.55),

            ])

            torso.run(.repeatForever(sway), withKey: "idle")

        case .slash:

            let windup = rotate(rightShoulder, degrees: -115, duration: 0.16)

            let strike = rotate(rightShoulder, degrees: 100, duration: 0.12)

            strike.timingMode = .easeIn

            let recover = rotate(rightShoulder, degrees: 12, duration: 0.20)

            rightShoulder.run(.sequence([windup, strike, recover]))

            rightElbow.run(

                .sequence([

                    rotate(rightElbow, degrees: 35, duration: 0.16),

                    rotate(rightElbow, degrees: 15, duration: 0.12),

                    rotate(rightElbow, degrees: 0, duration: 0.20),

                ])

            )

            torso.run(

                .sequence([

                    rotate(torso, degrees: -7, duration: 0.16),

                    rotate(torso, degrees: 10, duration: 0.12),

                    rotate(torso, degrees: 0, duration: 0.20),

                ])

            )

            returnToIdle(after: 0.48)

        case .punch:

            // Keep equipped weapon intact; hide it only for this animation.

            weaponNode?.isHidden = true

            rightShoulder.run(

                .sequence([

                    rotate(rightShoulder, degrees: -60, duration: 0.12),

                    rotate(rightShoulder, degrees: 90, duration: 0.09),

                    rotate(rightShoulder, degrees: 12, duration: 0.17),

                ])

            )

            rightElbow.run(

                .sequence([

                    rotate(rightElbow, degrees: -45, duration: 0.12),

                    rotate(rightElbow, degrees: 0, duration: 0.09),

                    rotate(rightElbow, degrees: 0, duration: 0.17),

                ])

            )

            returnToIdle(after: 0.38)

        case .jump:

            // Move the torso, not the root SKNode, so the scene owns world position.

            let rise = SKAction.moveBy(x: 0, y: 50, duration: 0.22)

            rise.timingMode = .easeOut

            let fall = SKAction.moveBy(x: 0, y: -50, duration: 0.30)

            fall.timingMode = .easeIn

            torso.run(.sequence([rise, fall]), withKey: "jump")

            leftHip.run(

                .sequence([

                    rotate(leftHip, degrees: -38, duration: 0.16),

                    rotate(leftHip, degrees: -7, duration: 0.36),

                ])

            )

            rightHip.run(

                .sequence([

                    rotate(rightHip, degrees: 45, duration: 0.16),

                    rotate(rightHip, degrees: 7, duration: 0.36),

                ])

            )

            leftKnee.run(

                .sequence([

                    rotate(leftKnee, degrees: 30, duration: 0.16),

                    rotate(leftKnee, degrees: 0, duration: 0.36),

                ])

            )

            rightKnee.run(

                .sequence([

                    rotate(rightKnee, degrees: -30, duration: 0.16),

                    rotate(rightKnee, degrees: 0, duration: 0.36),

                ])

            )

            returnToIdle(after: 0.52)

        }

    }

}

// MARK: - Procedural character silhouettes

/// SwiftUI body silhouette used by the character preview.
struct FighterBodyShape: Shape {
    let style: BodyStyle

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let center = rect.midX
        let shoulderRatio: CGFloat
        let waistRatio: CGFloat
        let bottomRatio: CGFloat

        switch style {
        case .slim:
            shoulderRatio = 0.32
            waistRatio = 0.19
            bottomRatio = 0.24
        case .athletic:
            shoulderRatio = 0.43
            waistRatio = 0.25
            bottomRatio = 0.29
        case .heavy:
            shoulderRatio = 0.46
            waistRatio = 0.39
            bottomRatio = 0.37
        case .armored:
            shoulderRatio = 0.49
            waistRatio = 0.32
            bottomRatio = 0.35
        case .agile:
            shoulderRatio = 0.35
            waistRatio = 0.20
            bottomRatio = 0.27
        }

        let top = rect.minY + height * 0.08
        let shoulders = rect.minY + height * 0.20
        let waist = rect.minY + height * 0.60
        let bottom = rect.maxY - height * 0.04

        var path = Path()
        path.move(to: CGPoint(x: center - width * 0.19, y: top))
        path.addLine(to: CGPoint(x: center + width * 0.19, y: top))
        path.addLine(
            to: CGPoint(x: center + width * shoulderRatio, y: shoulders)
        )
        path.addLine(to: CGPoint(x: center + width * waistRatio, y: waist))
        path.addLine(to: CGPoint(x: center + width * bottomRatio, y: bottom))
        path.addLine(to: CGPoint(x: center - width * bottomRatio, y: bottom))
        path.addLine(to: CGPoint(x: center - width * waistRatio, y: waist))
        path.addLine(
            to: CGPoint(x: center - width * shoulderRatio, y: shoulders)
        )
        path.closeSubpath()
        return path
    }
}

/// SwiftUI helmet silhouette used by the character preview.
struct FighterHelmetShape: Shape {
    let style: HelmetStyle

    func path(in rect: CGRect) -> Path {
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height
        var path = Path()

        switch style {
        case .rounded:
            path.addRoundedRect(
                in: rect.insetBy(dx: w * 0.06, dy: h * 0.03),
                cornerSize: CGSize(width: w * 0.34, height: h * 0.32)
            )
        case .angular:
            path.move(to: CGPoint(x: x + w * 0.20, y: y + h * 0.04))
            path.addLine(to: CGPoint(x: x + w * 0.80, y: y + h * 0.04))
            path.addLine(to: CGPoint(x: x + w * 0.98, y: y + h * 0.28))
            path.addLine(to: CGPoint(x: x + w * 0.84, y: y + h * 0.94))
            path.addLine(to: CGPoint(x: x + w * 0.16, y: y + h * 0.94))
            path.addLine(to: CGPoint(x: x + w * 0.02, y: y + h * 0.28))
            path.closeSubpath()
        case .pointed:
            path.move(to: CGPoint(x: x + w * 0.50, y: y))
            path.addLine(to: CGPoint(x: x + w * 0.92, y: y + h * 0.27))
            path.addLine(to: CGPoint(x: x + w * 0.83, y: y + h * 0.96))
            path.addLine(to: CGPoint(x: x + w * 0.17, y: y + h * 0.96))
            path.addLine(to: CGPoint(x: x + w * 0.08, y: y + h * 0.27))
            path.closeSubpath()
        case .horned:
            path.move(to: CGPoint(x: x + w * 0.06, y: y))
            path.addLine(to: CGPoint(x: x + w * 0.32, y: y + h * 0.17))
            path.addLine(to: CGPoint(x: x + w * 0.68, y: y + h * 0.17))
            path.addLine(to: CGPoint(x: x + w * 0.94, y: y))
            path.addLine(to: CGPoint(x: x + w * 0.89, y: y + h * 0.91))
            path.addLine(to: CGPoint(x: x + w * 0.11, y: y + h * 0.91))
            path.closeSubpath()
        case .masked:
            path.move(to: CGPoint(x: x + w * 0.20, y: y + h * 0.06))
            path.addLine(to: CGPoint(x: x + w * 0.80, y: y + h * 0.06))
            path.addLine(to: CGPoint(x: x + w * 0.96, y: y + h * 0.36))
            path.addLine(to: CGPoint(x: x + w * 0.70, y: y + h * 0.98))
            path.addLine(to: CGPoint(x: x + w * 0.30, y: y + h * 0.98))
            path.addLine(to: CGPoint(x: x + w * 0.04, y: y + h * 0.36))
            path.closeSubpath()
        case .visor:
            path.addRoundedRect(
                in: rect.insetBy(dx: w * 0.03, dy: h * 0.08),
                cornerSize: CGSize(width: w * 0.18, height: h * 0.16)
            )
        }
        return path
    }
}

struct WeaponGlyphShape: Shape {

    let type: WeaponType

    func path(in rect: CGRect) -> Path {

        var path = Path()

        let cx = rect.midX

        switch type {

        case .sword, .energyBlade, .katana:

            let width = type == .katana ? rect.width * 0.08 : rect.width * 0.13

            path.move(to: CGPoint(x: cx, y: rect.minY))

            path.addLine(

                to: CGPoint(x: cx + width, y: rect.minY + rect.height * 0.72)

            )

            path.addLine(

                to: CGPoint(x: cx - width, y: rect.minY + rect.height * 0.72)

            )

            path.closeSubpath()

            path.addRect(

                CGRect(

                    x: rect.minX,

                    y: rect.minY + rect.height * 0.72,

                    width: rect.width,

                    height: rect.height * 0.06

                )

            )

        case .greatsword:

            path.move(to: CGPoint(x: cx, y: rect.minY))

            path.addLine(

                to: CGPoint(

                    x: rect.minX + rect.width * 0.82,

                    y: rect.minY + rect.height * 0.7

                )

            )

            path.addLine(

                to: CGPoint(

                    x: rect.minX + rect.width * 0.18,

                    y: rect.minY + rect.height * 0.7

                )

            )

            path.closeSubpath()

            path.addRect(

                CGRect(

                    x: rect.minX,

                    y: rect.minY + rect.height * 0.7,

                    width: rect.width,

                    height: rect.height * 0.08

                )

            )

        case .dualBlades:

            path.addRect(

                CGRect(

                    x: rect.minX + rect.width * 0.18,

                    y: rect.minY,

                    width: rect.width * 0.14,

                    height: rect.height * 0.78

                )

            )

            path.addRect(

                CGRect(

                    x: rect.maxX - rect.width * 0.32,

                    y: rect.minY,

                    width: rect.width * 0.14,

                    height: rect.height * 0.78

                )

            )

        case .crossbow:

            path.move(to: CGPoint(x: rect.minX, y: rect.midY))

            path.addQuadCurve(

                to: CGPoint(x: rect.maxX, y: rect.midY),

                control: CGPoint(x: cx, y: rect.minY)

            )

            path.addLine(to: CGPoint(x: cx, y: rect.maxY))

            path.move(to: CGPoint(x: cx, y: rect.minY))

            path.addLine(to: CGPoint(x: cx, y: rect.maxY))

        case .nunchaku:

            path.addRoundedRect(

                in: CGRect(

                    x: rect.minX,

                    y: rect.minY,

                    width: rect.width * 0.24,

                    height: rect.height * 0.55

                ),

                cornerSize: CGSize(width: 3, height: 3)

            )

            path.addRoundedRect(

                in: CGRect(

                    x: rect.maxX - rect.width * 0.24,

                    y: rect.minY + rect.height * 0.45,

                    width: rect.width * 0.24,

                    height: rect.height * 0.55

                ),

                cornerSize: CGSize(width: 3, height: 3)

            )

            path.move(

                to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.midY)

            )

            path.addCurve(

                to: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.midY),

                control1: CGPoint(

                    x: rect.minX + rect.width * 0.4,

                    y: rect.maxY

                ),

                control2: CGPoint(x: rect.minX + rect.width * 0.6, y: rect.minY)

            )

        case .gauntlets:

            path.addRoundedRect(

                in: CGRect(

                    x: rect.minX,

                    y: rect.minY + rect.height * 0.25,

                    width: rect.width * 0.42,

                    height: rect.height * 0.5

                ),

                cornerSize: CGSize(width: 7, height: 7)

            )

            path.addRoundedRect(

                in: CGRect(

                    x: rect.maxX - rect.width * 0.42,

                    y: rect.minY + rect.height * 0.25,

                    width: rect.width * 0.42,

                    height: rect.height * 0.5

                ),

                cornerSize: CGSize(width: 7, height: 7)

            )

        case .scythe:

            path.addRect(

                CGRect(

                    x: cx - rect.width * 0.05,

                    y: rect.minY,

                    width: rect.width * 0.1,

                    height: rect.height

                )

            )

            path.move(to: CGPoint(x: cx, y: rect.minY))

            path.addQuadCurve(

                to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.32),

                control: CGPoint(x: rect.maxX, y: rect.minY)

            )

            path.addQuadCurve(

                to: CGPoint(x: cx, y: rect.minY + rect.height * 0.18),

                control: CGPoint(

                    x: rect.minX + rect.width * 0.78,

                    y: rect.minY + rect.height * 0.3

                )

            )

        case .spear:

            path.addRect(

                CGRect(

                    x: cx - rect.width * 0.04,

                    y: rect.minY + rect.height * 0.15,

                    width: rect.width * 0.08,

                    height: rect.height * 0.85

                )

            )

            path.move(to: CGPoint(x: cx, y: rect.minY))

            path.addLine(

                to: CGPoint(

                    x: cx + rect.width * 0.18,

                    y: rect.minY + rect.height * 0.2

                )

            )

            path.addLine(

                to: CGPoint(

                    x: cx - rect.width * 0.18,

                    y: rect.minY + rect.height * 0.2

                )

            )

            path.closeSubpath()

        }

        return path

    }

}

struct StyleTriggerFighterArtwork: View {

    let name: String

    let appearance: CharacterAppearance

    var weaponType: WeaponType? = nil

    var body: some View {

        GeometryReader { proxy in

            let scale = max(

                0,

                min(proxy.size.width / 130, proxy.size.height / 200)

            )

            ZStack {

                LinearGradient(

                    colors: [

                        primary.opacity(0.22), StyleTriggerPalette.background,

                    ],

                    startPoint: .top,

                    endPoint: .bottom

                )

                ZStack {

                    FighterBodyShape(style: appearance.bodyStyle)

                        .fill(

                            LinearGradient(

                                colors: [

                                    secondary, StyleTriggerPalette.background,

                                ],

                                startPoint: .top,

                                endPoint: .bottom

                            )

                        )

                        .overlay {

                            FighterBodyShape(style: appearance.bodyStyle)

                                .stroke(

                                    primary,

                                    lineWidth: max(0, appearance.outlineWidth)

                                )

                        }

                        .frame(width: 94, height: 132)

                        .offset(y: 31)

                    FighterHelmetShape(style: appearance.helmetStyle)

                        .fill(StyleTriggerPalette.background)

                        .overlay {

                            FighterHelmetShape(style: appearance.helmetStyle)

                                .stroke(

                                    secondary,

                                    lineWidth: max(0, appearance.outlineWidth)

                                )

                        }

                        .frame(width: 48, height: 54)

                        .offset(y: -61)

                    Capsule()

                        .fill(visor)

                        .frame(width: 30, height: 5)

                        .shadow(

                            color: visor,

                            radius: 7 * max(0, appearance.glowIntensity)

                        )

                        .offset(y: -61)

                    WeaponGlyphShape(type: weaponType ?? appearance.weaponStyle)

                        .fill(

                            LinearGradient(

                                colors: [

                                    StyleTriggerPalette.silver, weaponColor,

                                ],

                                startPoint: .top,

                                endPoint: .bottom

                            )

                        )

                        .frame(width: 42, height: 126)

                        .scaleEffect(appearance.weaponScale)

                        .rotationEffect(.degrees(24))

                        .offset(x: 43, y: 4)

                        .shadow(

                            color: weaponColor,

                            radius: 6 * max(0, appearance.glowIntensity)

                        )

                }

                .frame(width: 130, height: 200)

                .scaleEffect(scale * max(0.1, appearance.bodyScale))

                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

            }

        }

        .colorEffect(

            ShaderLibrary.neonPulse(.float(Float(appearance.glowIntensity))),

            isEnabled: appearance.glowIntensity >= 0.9

        )

        .accessibilityLabel("\(name) fighter")

    }

    private var primary: Color { Color(hex: appearance.primaryColor) }

    private var secondary: Color { Color(hex: appearance.secondaryColor) }

    private var visor: Color { Color(hex: appearance.visorColor) }

    private var weaponColor: Color { Color(hex: appearance.weaponColor) }

}

struct WeaponIcon: View {

    let type: WeaponType

    let color: Color

    var body: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 9)

                .fill(StyleTriggerPalette.background)

            WeaponGlyphShape(type: type)

                .stroke(

                    color,

                    style: StrokeStyle(

                        lineWidth: 3,

                        lineCap: .round,

                        lineJoin: .round

                    )

                )

                .padding(8)

                .shadow(color: color, radius: 4)

        }

        .accessibilityLabel(type.rawValue)

    }

}
