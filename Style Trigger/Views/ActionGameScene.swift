//
//  ActionGameScene.swift
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

import SpriteKit

final class ActionGameScene: SKScene {

    var onGameOver: ((Int) -> Void)?

    var onCombatSnapshot: ((CombatSnapshot) -> Void)?

    var onLocalInput: ((CombatInput) -> Void)?

    var onWeaponChanged: ((String) -> Void)?

    private enum PlayerState {

        case idle

        case attacking

        case dashing

        case airborne

    }

    private enum AttackKind {

        case slash

        case launcher

        case dive

        var damage: CGFloat {

            switch self {

            case .slash: 24

            case .launcher: 34

            case .dive: 46

            }

        }

        var color: SKColor {

            switch self {

            case .slash: .cyan

            case .launcher: .systemPink

            case .dive: .systemOrange

            }

        }

    }

    private let worldNode = SKNode()

    private let effectsNode = SKNode()

    private let player = SKNode()

    private var enemy = SKNode()

    private let comboDetector = ComboDetector()

    private let scoreLabel = SKLabelNode(

        fontNamed: "AvenirNextCondensed-HeavyItalic"

    )

    private let comboLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")

    private let styleLabel = SKLabelNode(

        fontNamed: "AvenirNextCondensed-HeavyItalic"

    )

    private let healthBar = SKShapeNode(

        rectOf: CGSize(width: 112, height: 8),

        cornerRadius: 4

    )

    private let enemyHealthBar = SKShapeNode(

        rectOf: CGSize(width: 116, height: 7),

        cornerRadius: 3.5

    )

    private var playerState: PlayerState = .idle

    private var touchStart = CGPoint.zero

    private var touchStartTime: TimeInterval = 0

    private var lastAttackTime: TimeInterval = 0

    private var lastUpdateTime: TimeInterval = 0

    private var enemyAttackTime: TimeInterval = 0

    private var combo = 0

    private var score = 0

    private var totalDamage = 0

    private var highestStyleRank: StyleRank = .d

    private var wave = 1

    private var playerHealth: CGFloat = 100

    private var enemyHealth: CGFloat = 100

    private var isGameOver = false
    private var isEnemyDefeated = false
    private var waveGeneration = 0

    private var hasStarted = false

    private var appearance: CharacterAppearance?

    private var weapons: [Weapon] = []

    private var weaponIndex = 0

    private var allCombos: [ComboDefinition] = []

    private var effectsEnabled = true

    private var screenShakeEnabled = true

    private var particleMultiplier = 0.7

    private var targetFrameRate = 60
    private var trainingMode = false
    private var environmentID = "neon-rooftop"
    private var storyEnemies: [EnemyDefinition] = []
    private var isStoryMode = false
    private var maximumEnemyHealth: CGFloat = 98
    private var attackMultiplier = 1.0
    private var speedMultiplier = 1.0
    private var styleMultiplier = 1.0
    private var maximumPlayerHealth: CGFloat = 100

    private let floorY: CGFloat = 190

    private var playerHome = CGPoint(x: 104, y: 226)

    private var enemyHome = CGPoint(x: 292, y: 226)

    override init(size: CGSize) {

        super.init(size: size)

        scaleMode = .aspectFill

        anchorPoint = .zero

        backgroundColor = SKColor(

            red: 0.018,

            green: 0.022,

            blue: 0.055,

            alpha: 1

        )

    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)

    }

    func configure(

        appearance: CharacterAppearance,

        weapons: [Weapon],

        activeWeaponID: String,

        combos: [ComboDefinition],

        targetFrameRate: Int,

        graphicsQuality: GraphicsQuality,

        effectsEnabled: Bool,

        screenShakeEnabled: Bool,
        trainingMode: Bool,
        attackMultiplier: Double,
        speedMultiplier: Double,
        styleMultiplier: Double,
        healthMultiplier: Double,
        environmentID: String,
        storyEnemies: [EnemyDefinition],
        isStoryMode: Bool
    ) {

        self.appearance = appearance

        self.weapons = weapons

        self.weaponIndex = weapons.firstIndex { $0.id == activeWeaponID } ?? 0

        self.allCombos = combos

        self.targetFrameRate = targetFrameRate

        self.particleMultiplier = graphicsQuality.particleMultiplier

        self.effectsEnabled = effectsEnabled

        self.screenShakeEnabled = screenShakeEnabled
        self.trainingMode = trainingMode
        self.attackMultiplier = attackMultiplier
        self.speedMultiplier = speedMultiplier
        self.styleMultiplier = styleMultiplier
        self.maximumPlayerHealth = 100 * healthMultiplier
        self.playerHealth = maximumPlayerHealth
        self.environmentID = environmentID
        self.storyEnemies = storyEnemies
        self.isStoryMode = isStoryMode

        configureCombosForCurrentWeapon()

    }

    private var arenaColor: SKColor {
        switch environmentID {
        case "void-cathedral":
            SKColor(red: 0.19, green: 0.06, blue: 0.24, alpha: 1)
        case "chrome-subway":
            SKColor(red: 0.10, green: 0.23, blue: 0.27, alpha: 1)
        default:
            SKColor(red: 0.02, green: 0.08, blue: 0.15, alpha: 1)
        }
    }

    func switchWeapon() {
        guard weapons.count > 1 else { return }
        let nextIndex = (weaponIndex + 1) % weapons.count
        equipWeapon(id: weapons[nextIndex].id)
    }

    func equipWeapon(id: Weapon.ID) {
        guard !isGameOver,
              let newIndex = weapons.firstIndex(where: { $0.id == id }),
              newIndex != weaponIndex
        else {
            return
        }

        weaponIndex = newIndex
        player.childNode(withName: "weapon")?.removeAllActions()
        rebuildWeapon()
        configureCombosForCurrentWeapon()
        combo = 0
        showCallout(currentWeapon?.name ?? "WEAPON", color: weaponColor)
        updateHUD()
        onWeaponChanged?(id)
    }

    func revivePlayer(healthFraction: Double = 0.5) {
        childNode(withName: "gameOver")?.removeFromParent()
        isGameOver = false
        playerHealth = maximumPlayerHealth * max(0.1, min(1, healthFraction))
        player.alpha = 1
        player.position = playerHome
        playerState = .idle
        enemyAttackTime = lastUpdateTime + 1
        showCallout("REVIVE!", color: .cyan)
        updateHUD()
    }

    func receiveRemoteInput(_ input: CombatInput) {

        guard !isGameOver else { return }

        switch input {

        case .swipeLeft, .swipeRight, .diagonalUpLeft:

            showCallout("RIVAL EVADE", color: .systemPink)

        case .swipeUp, .diagonalUpRight:

            showCallout("RIVAL LAUNCH", color: .systemPink)

            takeDamage()

        case .swipeDown, .diagonalDownLeft, .diagonalDownRight:

            showCallout("RIVAL BREAK", color: .systemOrange)

            takeDamage()

        case .tap:

            takeDamage()

        }

    }

    override func didMove(to view: SKView) {

        guard !hasStarted else { return }

        hasStarted = true

        view.isMultipleTouchEnabled = false

        view.preferredFramesPerSecond = targetFrameRate

        physicsWorld.gravity = CGVector(dx: 0, dy: -8)

        addChild(worldNode)

        worldNode.addChild(effectsNode)

        buildArena()

        buildHUD()

        buildPlayer()

        spawnEnemy()

        run(

            .sequence([

                .wait(forDuration: 0.65),

                .run { [weak self] in

                    self?.showCallout("TAP TO SLASH", color: .cyan)

                },

            ])

        )

    }

    override func didChangeSize(_ oldSize: CGSize) {

        guard hasStarted else { return }

        playerHome = CGPoint(x: size.width * 0.27, y: floorY + 36)

        enemyHome = CGPoint(x: size.width * 0.74, y: floorY + 36)

    }

    private func buildArena() {
        switch environmentID {
        case "void-cathedral":
            buildCathedralArena()
        case "chrome-subway":
            buildSubwayArena()
        default:
            buildRooftopArena()
        }
    }

    private func buildRooftopArena() {

        let backdrop = SKShapeNode(rect: CGRect(origin: .zero, size: size))

        backdrop.fillColor = arenaColor

        backdrop.strokeColor = .clear

        backdrop.zPosition = -20

        worldNode.addChild(backdrop)

        let moon = SKShapeNode(circleOfRadius: 76)

        moon.position = CGPoint(x: size.width * 0.72, y: size.height * 0.72)

        moon.fillColor = SKColor(red: 0.08, green: 0.11, blue: 0.2, alpha: 1)

        moon.strokeColor = SKColor.cyan.withAlphaComponent(0.3)

        moon.lineWidth = 2

        moon.glowWidth = 12

        moon.zPosition = -18

        worldNode.addChild(moon)

        for index in 0..<9 {

            let buildingWidth = CGFloat(34 + (index % 3) * 14)

            let buildingHeight = CGFloat(80 + (index * 37) % 150)

            let building = SKShapeNode(

                rectOf: CGSize(width: buildingWidth, height: buildingHeight)

            )

            building.position = CGPoint(

                x: CGFloat(index) * size.width / 8,

                y: floorY + buildingHeight / 2

            )

            building.fillColor = SKColor(

                red: 0.025,

                green: 0.035,

                blue: 0.075,

                alpha: 1

            )

            building.strokeColor = .clear

            building.zPosition = -15

            worldNode.addChild(building)

            let antenna = SKShapeNode(rectOf: CGSize(width: 2, height: 20))

            antenna.position = CGPoint(x: 0, y: buildingHeight / 2 + 10)

            antenna.fillColor = index.isMultiple(of: 2) ? .systemPink : .cyan

            antenna.strokeColor = .clear

            antenna.alpha = 0.6

            building.addChild(antenna)

        }

        let floorPath = CGMutablePath()

        floorPath.move(to: CGPoint(x: 0, y: floorY))

        floorPath.addLine(to: CGPoint(x: size.width, y: floorY))

        let floor = SKShapeNode(path: floorPath)

        floor.strokeColor = .cyan

        floor.lineWidth = 2

        floor.glowWidth = 8

        floor.alpha = 0.7

        floor.zPosition = -5

        worldNode.addChild(floor)

        for index in 0..<7 {

            let perspective = SKShapeNode()

            let path = CGMutablePath()

            let x = CGFloat(index) * size.width / 6

            path.move(to: CGPoint(x: size.width / 2, y: floorY))

            path.addLine(to: CGPoint(x: x, y: 0))

            perspective.path = path

            perspective.strokeColor = .cyan.withAlphaComponent(0.13)

            perspective.lineWidth = 1

            perspective.zPosition = -6

            worldNode.addChild(perspective)

        }

    }

    private func buildCathedralArena() {
        let backdrop = SKShapeNode(
            rect: CGRect(origin: .zero, size: size)
        )
        backdrop.fillColor = SKColor(
            red: 0.08,
            green: 0.025,
            blue: 0.12,
            alpha: 1
        )
        backdrop.strokeColor = .clear
        backdrop.zPosition = -20
        worldNode.addChild(backdrop)

        // Gotische Säulen
        for index in 0..<5 {
            let x = CGFloat(index) * size.width / 4

            let pillar = SKShapeNode(
                rectOf: CGSize(width: 28, height: size.height * 0.72)
            )
            pillar.position = CGPoint(
                x: x,
                y: floorY + size.height * 0.36
            )
            pillar.fillColor = SKColor(
                red: 0.12,
                green: 0.06,
                blue: 0.17,
                alpha: 1
            )
            pillar.strokeColor = .purple
            pillar.lineWidth = 1
            pillar.zPosition = -15
            worldNode.addChild(pillar)

            let capital = SKShapeNode(
                rectOf: CGSize(width: 46, height: 12)
            )
            capital.position = CGPoint(x: 0, y: -size.height * 0.36 + 18)
            capital.fillColor = .darkGray
            capital.strokeColor = .purple
            pillar.addChild(capital)
        }

        // Magisches Fenster
        let window = SKShapeNode(
            ellipseOf: CGSize(width: 110, height: 210)
        )
        window.position = CGPoint(
            x: size.width / 2,
            y: floorY + 210
        )
        window.fillColor = SKColor(
            red: 0.36,
            green: 0.07,
            blue: 0.48,
            alpha: 0.65
        )
        window.strokeColor = .systemPink
        window.lineWidth = 3
        window.glowWidth = 14
        window.zPosition = -17
        worldNode.addChild(window)

        let floor = SKShapeNode(
            rect: CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: floorY
            )
        )
        floor.fillColor = SKColor(
            red: 0.045,
            green: 0.025,
            blue: 0.08,
            alpha: 1
        )
        floor.strokeColor = .clear
        floor.zPosition = -8
        worldNode.addChild(floor)

        let floorLine = SKShapeNode(
            rectOf: CGSize(width: size.width, height: 3)
        )
        floorLine.position = CGPoint(x: size.width / 2, y: floorY)
        floorLine.fillColor = .systemPurple
        floorLine.strokeColor = .clear
        floorLine.glowWidth = 10
        floorLine.zPosition = -5
        worldNode.addChild(floorLine)
    }

    private func buildSubwayArena() {
        let backdrop = SKShapeNode(
            rect: CGRect(origin: .zero, size: size)
        )
        backdrop.fillColor = SKColor(
            red: 0.025,
            green: 0.085,
            blue: 0.105,
            alpha: 1
        )
        backdrop.strokeColor = .clear
        backdrop.zPosition = -20
        worldNode.addChild(backdrop)

        // U-Bahn-Tunnel
        let tunnel = SKShapeNode(
            rectOf: CGSize(
                width: size.width * 0.72,
                height: 240
            ),
            cornerRadius: 38
        )
        tunnel.position = CGPoint(
            x: size.width / 2,
            y: floorY + 155
        )
        tunnel.fillColor = .black
        tunnel.strokeColor = .cyan.withAlphaComponent(0.35)
        tunnel.lineWidth = 3
        tunnel.zPosition = -18
        worldNode.addChild(tunnel)

        // Metallpfeiler
        for index in 0..<4 {
            let x = CGFloat(index) * size.width / 3

            let pillar = SKShapeNode(
                rectOf: CGSize(width: 22, height: 300)
            )
            pillar.position = CGPoint(x: x, y: floorY + 150)
            pillar.fillColor = SKColor(
                red: 0.13,
                green: 0.19,
                blue: 0.22,
                alpha: 1
            )
            pillar.strokeColor = .cyan.withAlphaComponent(0.45)
            pillar.lineWidth = 2
            pillar.zPosition = -14
            worldNode.addChild(pillar)
        }

        // Neonlicht an der Decke
        for index in 0..<3 {
            let light = SKShapeNode(
                rectOf: CGSize(width: 72, height: 5)
            )
            light.position = CGPoint(
                x: CGFloat(index + 1) * size.width / 4,
                y: floorY + 320
            )
            light.fillColor = .cyan
            light.strokeColor = .clear
            light.glowWidth = 12
            light.zPosition = -10
            worldNode.addChild(light)
        }

        // Bahnsteig
        let platform = SKShapeNode(
            rect: CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: floorY
            )
        )
        platform.fillColor = SKColor(
            red: 0.055,
            green: 0.085,
            blue: 0.10,
            alpha: 1
        )
        platform.strokeColor = .clear
        platform.zPosition = -8
        worldNode.addChild(platform)

        let platformEdge = SKShapeNode(
            rectOf: CGSize(width: size.width, height: 4)
        )
        platformEdge.position = CGPoint(
            x: size.width / 2,
            y: floorY
        )
        platformEdge.fillColor = .cyan
        platformEdge.strokeColor = .clear
        platformEdge.glowWidth = 9
        platformEdge.zPosition = -5
        worldNode.addChild(platformEdge)
    }

    private func buildHUD() {

        scoreLabel.fontColor = .white

        scoreLabel.horizontalAlignmentMode = .left

        scoreLabel.fontSize = 15

        scoreLabel.position = CGPoint(x: 18, y: size.height - 176)

        scoreLabel.zPosition = 50

        worldNode.addChild(scoreLabel)

        healthBar.fillColor = .cyan

        healthBar.strokeColor = .white.withAlphaComponent(0.3)

        healthBar.position = CGPoint(x: 78, y: size.height - 196)

        healthBar.zPosition = 50

        worldNode.addChild(healthBar)

        styleLabel.text = "D"

        styleLabel.fontSize = 48

        styleLabel.fontColor = .white

        styleLabel.position = CGPoint(x: size.width - 42, y: size.height - 194)

        styleLabel.zRotation = -0.1

        styleLabel.zPosition = 50

        worldNode.addChild(styleLabel)

        comboLabel.fontSize = 13

        comboLabel.fontColor = .cyan

        comboLabel.horizontalAlignmentMode = .right

        comboLabel.position = CGPoint(x: size.width - 18, y: size.height - 220)

        comboLabel.zPosition = 50

        worldNode.addChild(comboLabel)

        let controls = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")

        controls.text = "TAP  SLASH   ↑ LAUNCH   ↓ BREAK   → DASH"

        controls.fontSize = 12

        controls.fontColor = .white.withAlphaComponent(0.55)

        controls.position = CGPoint(x: size.width / 2, y: 38)

        controls.zPosition = 50

        worldNode.addChild(controls)

        updateHUD()

    }

    private func buildPlayer() {

        player.removeAllChildren()

        player.position = playerHome

        player.zPosition = 10

        worldNode.addChild(player)

        let body = SKShapeNode(
            path: bodyPath(style: appearance?.bodyStyle ?? .slim)
        )

        body.name = "body"

        body.fillColor = secondaryColor

        body.strokeColor = appearanceColor

        body.lineWidth = appearance?.outlineWidth ?? 2

        body.glowWidth =
            effectsEnabled ? CGFloat(appearance?.glowIntensity ?? 0.8) * 4 : 0

        player.addChild(body)

        let head = SKShapeNode(
            path: helmetPath(style: appearance?.helmetStyle ?? .angular)
        )

        head.name = "head"

        head.position = CGPoint(x: 0, y: 44)

        head.fillColor = .black

        head.strokeColor = secondaryColor

        head.lineWidth = appearance?.outlineWidth ?? 2

        player.addChild(head)

        let visor = SKShapeNode(

            rectOf: CGSize(width: 22, height: 4),

            cornerRadius: 2

        )

        visor.position = CGPoint(x: 5, y: 45)

        visor.name = "visor"

        visor.fillColor = visorColor

        visor.strokeColor = .white

        visor.glowWidth =
            effectsEnabled ? CGFloat(appearance?.glowIntensity ?? 0.8) * 8 : 0

        player.addChild(visor)

        player.setScale(CGFloat(appearance?.bodyScale ?? 1))

        rebuildWeapon()

    }

    private func spawnEnemy() {

        enemy.removeAllActions()
        enemy.removeFromParent()
        isEnemyDefeated = false
        enemy = SKNode()

        enemy.position = enemyHome

        enemy.zPosition = 9

        let bodyPath = CGMutablePath()

        bodyPath.move(to: CGPoint(x: -20, y: -34))

        bodyPath.addLine(to: CGPoint(x: -30, y: 16))

        bodyPath.addLine(to: CGPoint(x: -12, y: 35))

        bodyPath.addLine(to: CGPoint(x: 16, y: 32))

        bodyPath.addLine(to: CGPoint(x: 28, y: 4))

        bodyPath.addLine(to: CGPoint(x: 19, y: -34))

        bodyPath.closeSubpath()

        let body = SKShapeNode(path: bodyPath)

        let definition = isStoryMode ? storyEnemies.first : nil
        let enemyColor = color(for: definition)

        body.fillColor = enemyColor.withAlphaComponent(0.22)

        body.strokeColor = enemyColor

        body.lineWidth = 3

        body.glowWidth = 5

        enemy.addChild(body)

        let hornLeft = SKShapeNode(path: hornPath(mirrored: false))

        hornLeft.position = CGPoint(x: -8, y: 30)

        hornLeft.fillColor = enemyColor.withAlphaComponent(0.75)

        hornLeft.strokeColor = enemyColor

        enemy.addChild(hornLeft)

        let hornRight = SKShapeNode(path: hornPath(mirrored: true))

        hornRight.position = CGPoint(x: 8, y: 30)

        hornRight.fillColor = enemyColor.withAlphaComponent(0.75)

        hornRight.strokeColor = enemyColor

        enemy.addChild(hornRight)

        let eye = SKShapeNode(

            rectOf: CGSize(width: 24, height: 4),

            cornerRadius: 2

        )

        eye.position = CGPoint(x: -3, y: 19)

        eye.fillColor = enemyColor

        eye.strokeColor = .white

        eye.glowWidth = 8

        enemy.addChild(eye)

        enemyHealthBar.fillColor = enemyColor

        enemyHealthBar.strokeColor = .white.withAlphaComponent(0.25)

        enemyHealthBar.position = CGPoint(x: 0, y: 66)

        enemy.addChild(enemyHealthBar)

        maximumEnemyHealth =
            definition.map { CGFloat($0.baseHealth) } ?? 80 + CGFloat(wave * 18)
        enemyHealth = maximumEnemyHealth

        let aggression = definition?.aggression ?? 0.55
        enemyAttackTime = lastUpdateTime + max(0.55, 1.8 - aggression)

        if let definition {
            showCallout(definition.name, color: enemyColor)
        }

        worldNode.addChild(enemy)

        enemy.setScale(0.1)

        enemy.alpha = 0

        enemy.run(

            .group([

                .scale(to: 1, duration: 0.25),

                .fadeIn(withDuration: 0.2),

            ])

        )

        showCallout("WAVE \(wave)", color: .systemPink)

    }

    private func color(for enemy: EnemyDefinition?) -> SKColor {
        switch enemy?.id {
        case "signal-hunter":
            return .cyan
        case "choir-guard":
            return .systemPurple
        case "rail-stalker":
            return .systemOrange
        case "breaker":
            return .lightGray
        default:
            return .systemPink
        }
    }

    private func helmetPath(style: HelmetStyle) -> CGPath {

        let path = CGMutablePath()

        switch style {

        case .rounded:

            path.addRoundedRect(
                in: CGRect(x: -19, y: -16, width: 38, height: 34),
                cornerWidth: 12,
                cornerHeight: 12
            )

        case .pointed:

            path.move(to: CGPoint(x: 0, y: 23))

            path.addLine(to: CGPoint(x: 20, y: 3))

            path.addLine(to: CGPoint(x: 11, y: -17))

            path.addLine(to: CGPoint(x: -12, y: -17))

            path.addLine(to: CGPoint(x: -20, y: 3))

        case .horned:

            path.move(to: CGPoint(x: -20, y: -13))

            path.addLine(to: CGPoint(x: -28, y: 23))

            path.addLine(to: CGPoint(x: -8, y: 14))

            path.addLine(to: CGPoint(x: 8, y: 14))

            path.addLine(to: CGPoint(x: 28, y: 23))

            path.addLine(to: CGPoint(x: 20, y: -13))

        case .masked:

            path.move(to: CGPoint(x: 0, y: 20))

            path.addLine(to: CGPoint(x: 20, y: 5))

            path.addLine(to: CGPoint(x: 0, y: -19))

            path.addLine(to: CGPoint(x: -20, y: 5))

        case .visor:

            path.addRoundedRect(
                in: CGRect(x: -22, y: -15, width: 44, height: 31),
                cornerWidth: 5,
                cornerHeight: 5
            )

        case .angular:

            path.move(to: CGPoint(x: -14, y: -12))

            path.addLine(to: CGPoint(x: -20, y: 5))

            path.addLine(to: CGPoint(x: -10, y: 18))

            path.addLine(to: CGPoint(x: 13, y: 15))

            path.addLine(to: CGPoint(x: 20, y: 0))

            path.addLine(to: CGPoint(x: 10, y: -14))

        }

        path.closeSubpath()

        return path

    }

    private func bodyPath(style: BodyStyle) -> CGPath {

        let halfWidth: CGFloat

        switch style {

        case .slim: halfWidth = 18

        case .athletic: halfWidth = 22

        case .heavy: halfWidth = 28

        case .armored: halfWidth = 31

        case .agile: halfWidth = 16

        }

        let path = CGMutablePath()

        path.move(to: CGPoint(x: -halfWidth * 0.72, y: -36))

        path.addLine(to: CGPoint(x: -halfWidth, y: 16))

        path.addLine(to: CGPoint(x: -halfWidth * 0.6, y: 34))

        path.addLine(to: CGPoint(x: halfWidth * 0.48, y: 35))

        path.addLine(to: CGPoint(x: halfWidth, y: 13))

        path.addLine(to: CGPoint(x: halfWidth * 0.65, y: -36))

        path.addLine(to: CGPoint(x: 2, y: -12))

        path.closeSubpath()

        return path

    }

    private func weaponPath(type: WeaponType) -> CGPath {

        let path = CGMutablePath()

        switch type {

        case .greatsword:

            path.move(to: CGPoint(x: -9, y: -12))

            path.addLine(to: CGPoint(x: -12, y: 54))

            path.addLine(to: CGPoint(x: 0, y: 76))

            path.addLine(to: CGPoint(x: 13, y: 52))

            path.addLine(to: CGPoint(x: 9, y: -12))

        case .dualBlades:

            path.addRect(CGRect(x: -13, y: -8, width: 6, height: 61))

            path.addRect(CGRect(x: 8, y: -8, width: 6, height: 61))

        case .crossbow:

            path.move(to: CGPoint(x: -30, y: 30))

            path.addQuadCurve(
                to: CGPoint(x: 30, y: 30),
                control: CGPoint(x: 0, y: 4)
            )

            path.move(to: CGPoint(x: 0, y: -8))

            path.addLine(to: CGPoint(x: 0, y: 50))

        case .nunchaku:

            path.addRect(CGRect(x: -15, y: -5, width: 7, height: 43))

            path.addRect(CGRect(x: 9, y: 25, width: 7, height: 43))

            path.move(to: CGPoint(x: -8, y: 35))

            path.addCurve(
                to: CGPoint(x: 9, y: 28),
                control1: CGPoint(x: -2, y: 53),
                control2: CGPoint(x: 5, y: 10)
            )

        case .gauntlets:

            path.addRoundedRect(
                in: CGRect(x: -31, y: 1, width: 22, height: 27),
                cornerWidth: 6,
                cornerHeight: 6
            )

            path.addRoundedRect(
                in: CGRect(x: 9, y: 1, width: 22, height: 27),
                cornerWidth: 6,
                cornerHeight: 6
            )

        case .scythe:

            path.addRect(CGRect(x: -3, y: -12, width: 6, height: 82))

            path.move(to: CGPoint(x: 0, y: 68))

            path.addQuadCurve(
                to: CGPoint(x: 38, y: 42),
                control: CGPoint(x: 38, y: 70)
            )

        case .spear:

            path.addRect(CGRect(x: -2, y: -15, width: 4, height: 88))

            path.move(to: CGPoint(x: 0, y: 84))

            path.addLine(to: CGPoint(x: 10, y: 68))

            path.addLine(to: CGPoint(x: -10, y: 68))

        case .sword, .katana, .energyBlade:

            path.move(to: CGPoint(x: -4, y: -8))

            path.addLine(to: CGPoint(x: -5, y: 50))

            path.addLine(to: CGPoint(x: 0, y: 67))

            path.addLine(to: CGPoint(x: type == .katana ? 4 : 7, y: 48))

            path.addLine(to: CGPoint(x: 5, y: -8))

        }

        path.closeSubpath()

        return path

    }

    private var currentWeapon: Weapon? {

        guard weapons.indices.contains(weaponIndex) else { return nil }

        return weapons[weaponIndex]

    }

    private var appearanceColor: SKColor {

        SKColor(hex: appearance?.primaryColor ?? "#00F6FF")

    }

    private var secondaryColor: SKColor {

        SKColor(hex: appearance?.secondaryColor ?? "#24344D")

    }

    private var visorColor: SKColor {

        SKColor(hex: appearance?.visorColor ?? "#00F6FF")

    }

    private var weaponColor: SKColor {

        SKColor(hex: appearance?.weaponColor ?? "#00F6FF")

    }

    private func rebuildWeapon() {

        player.childNode(withName: "weapon")?.removeFromParent()

        guard let weapon = currentWeapon else { return }

        let node = SKShapeNode(path: weaponPath(type: weapon.type))

        node.name = "weapon"

        node.position = CGPoint(x: weapon.type == .gauntlets ? 0 : 12, y: 5)

        node.fillColor = weapon.type == .crossbow ? .clear : .white

        node.strokeColor = weaponColor

        node.lineWidth = appearance?.outlineWidth ?? 2

        node.glowWidth =
            effectsEnabled ? CGFloat(appearance?.glowIntensity ?? 0.8) * 5 : 0

        node.zRotation =
            weapon.type == .crossbow || weapon.type == .gauntlets ? 0 : -.pi / 5

        node.zPosition = weapon.type == .gauntlets ? 2 : -1

        node.setScale(CGFloat(appearance?.weaponScale ?? 1))

        player.addChild(node)

    }

    private func configureCombosForCurrentWeapon() {

        guard let weapon = currentWeapon else {

            comboDetector.configure(with: allCombos)

            return

        }

        let ids = Set(weapon.associatedCombos)

        comboDetector.configure(with: allCombos.filter { ids.contains($0.id) })

    }

    private func hornPath(mirrored: Bool) -> CGPath {

        let direction: CGFloat = mirrored ? -1 : 1

        let path = CGMutablePath()

        path.move(to: .zero)

        path.addLine(to: CGPoint(x: 13 * direction, y: 25))

        path.addLine(to: CGPoint(x: 5 * direction, y: -2))

        path.closeSubpath()

        return path

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard !isGameOver, let touch = touches.first else {

            if isGameOver { restart() }

            return

        }

        touchStart = touch.location(in: self)

        touchStartTime = event?.timestamp ?? 0

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard !isGameOver, let touch = touches.first else { return }

        let end = touch.location(in: self)

        let delta = CGVector(dx: end.x - touchStart.x, dy: end.y - touchStart.y)

        let distance = hypot(delta.dx, delta.dy)

        let input: CombatInput

        let isDiagonal =

            distance >= 32

            && abs(abs(delta.dx) - abs(delta.dy)) < distance * 0.42

        if distance < 32 {

            input = .tap

            performAttack(.slash)

        } else if isDiagonal, delta.dx > 0, delta.dy > 0 {

            input = .diagonalUpRight

            performAttack(.launcher)

        } else if isDiagonal, delta.dx < 0, delta.dy > 0 {

            input = .diagonalUpLeft

            evade()

        } else if isDiagonal, delta.dx > 0, delta.dy < 0 {

            input = .diagonalDownRight

            performAttack(.dive)

        } else if isDiagonal {

            input = .diagonalDownLeft

            performAttack(.dive)

        } else if abs(delta.dy) > abs(delta.dx), delta.dy > 0 {

            input = .swipeUp

            performAttack(.launcher)

        } else if abs(delta.dy) > abs(delta.dx), delta.dy < 0 {

            input = .swipeDown

            performAttack(.dive)

        } else if delta.dx > 0 {

            input = .swipeRight

            dash()

        } else {

            input = .swipeLeft

            evade()

        }

        if let matchedCombo = comboDetector.register(

            input,

            at: event?.timestamp ?? lastUpdateTime

        ) {

            combo += matchedCombo.inputSequence.count

            score += Int(Double(matchedCombo.stylePoints) * styleMultiplier)

            showCallout(

                matchedCombo.name,

                color: matchedCombo.isAirLauncher ? .systemPink : .cyan

            )

            updateHUD()

        }

        onLocalInput?(input)

    }

    private func performAttack(_ kind: AttackKind) {

        guard !isGameOver, !isEnemyDefeated, enemy.parent != nil,
            playerState != .dashing
        else { return }

        playerState = kind == .launcher ? .airborne : .attacking

        combo = lastUpdateTime - lastAttackTime < 0.72 ? combo + 1 : 1

        lastAttackTime = lastUpdateTime

        let nearEnemy = abs(player.position.x - enemy.position.x) < 205

        let lunge: CGFloat = min(

            48,

            max(0, enemy.position.x - player.position.x - 72)

        )

        let start = player.position

        let destination = CGPoint(

            x: start.x + lunge,

            y: kind == .launcher ? start.y + 34 : start.y

        )

        player.removeAction(forKey: "attack")

        let speed = max(
            0.55,
            (currentWeapon?.attackSpeed ?? 1) * speedMultiplier
        )

        player.run(

            .sequence([

                .move(to: destination, duration: 0.055 / speed),

                .wait(forDuration: 0.07 / speed),

                .move(to: playerHome, duration: 0.13 / speed),

                .run { [weak self] in self?.playerState = .idle },

            ]),

            withKey: "attack"

        )

        if let weaponNode = player.childNode(withName: "weapon") {

            animateWeapon(weaponNode, kind: kind, speed: speed)

        }

        if currentWeapon?.type == .crossbow {

            createProjectile(from: player.position, to: enemy.position)

        } else {

            createSlash(

                kind: kind,

                at: CGPoint(
                    x: player.position.x + 58,
                    y: player.position.y + 10
                )

            )

        }

        guard nearEnemy else {

            combo = 0

            updateHUD()

            return

        }

        let multiplier = 1 + min(CGFloat(combo) * 0.035, 0.5)

        let baseDamage = CGFloat(currentWeapon?.damage ?? Int(kind.damage))

        let kindMultiplier: CGFloat =
            kind == .slash ? 0.72 : (kind == .launcher ? 0.9 : 1.08)

        let dealtDamage = Int(
            baseDamage * kindMultiplier * multiplier * attackMultiplier
        )

        enemyHealth = max(0, enemyHealth - CGFloat(dealtDamage))

        totalDamage += dealtDamage

        score += Int(kind.damage) * max(1, combo)

        flashEnemy(color: kind.color)

        emitHitParticles(at: enemy.position, color: weaponColor)

        switch kind {

        case .slash:

            enemy.run(

                .sequence([

                    .moveBy(x: 13, y: 0, duration: 0.05),

                    .move(to: enemyHome, duration: 0.12),

                ])

            )

        case .launcher:

            enemy.run(

                .sequence([

                    .moveBy(x: 12, y: 92, duration: 0.14),

                    .wait(forDuration: 0.08),

                    .move(to: enemyHome, duration: 0.22),

                ])

            )

            showCallout("LAUNCH!", color: .systemPink)

        case .dive:

            createImpact(at: enemy.position)

            shake(amount: 8)

            showCallout("BREAK!", color: .systemOrange)

        }

        if enemyHealth <= 0 {

            defeatEnemy()

        }

        updateHUD()

    }

    private func animateWeapon(

        _ node: SKNode,

        kind: AttackKind,

        speed: Double

    ) {

        node.removeAllActions()

        let duration = 0.1 / speed

        let resetAngle: CGFloat =
            currentWeapon?.type == .crossbow

                || currentWeapon?.type == .gauntlets ? 0 : -.pi / 5

        let action: SKAction

        switch currentWeapon?.animationType {

        case .heavySlash:

            action = .sequence([

                .rotate(toAngle: .pi * 0.72, duration: duration * 0.65),

                .rotate(toAngle: -.pi * 1.05, duration: duration * 1.35),

                .rotate(toAngle: resetAngle, duration: duration),

            ])

        case .alternating:

            action = .sequence([

                .rotate(byAngle: -.pi * 1.15, duration: duration),

                .rotate(byAngle: .pi * 2.1, duration: duration),

                .rotate(toAngle: resetAngle, duration: duration),

            ])

        case .spinning:

            action = .sequence([

                .rotate(byAngle: .pi * 3, duration: duration * 2),

                .rotate(toAngle: resetAngle, duration: duration * 0.5),

            ])

        case .boxing:

            action = .sequence([

                .moveBy(
                    x: 28,
                    y: kind == .launcher ? 28 : 0,
                    duration: duration * 0.7
                ),

                .move(to: CGPoint(x: 0, y: 5), duration: duration),

            ])

        case .projectile:

            action = .sequence([

                .scaleX(to: 0.78, duration: duration * 0.5),

                .scaleX(
                    to: CGFloat(appearance?.weaponScale ?? 1),
                    duration: duration * 0.7
                ),

            ])

        case .sweeping:

            action = .sequence([

                .rotate(byAngle: -.pi * 2, duration: duration * 2),

                .rotate(toAngle: resetAngle, duration: duration),

            ])

        case .thrusting:

            action = .sequence([

                .moveBy(x: 42, y: 0, duration: duration * 0.65),

                .move(to: CGPoint(x: 12, y: 5), duration: duration),

            ])

        case .precision:

            action = .sequence([

                .rotate(toAngle: -.pi * 0.95, duration: duration * 0.45),

                .rotate(toAngle: .pi * 0.45, duration: duration * 0.7),

                .rotate(toAngle: resetAngle, duration: duration),

            ])

        case .quickSlash, .energy, .none:

            let angle: CGFloat = kind == .launcher ? 1.9 : -2.8

            action = .sequence([

                .rotate(byAngle: angle, duration: duration * 0.8),

                .rotate(toAngle: resetAngle, duration: duration * 1.2),

            ])

        }

        node.run(action)

    }

    private func createProjectile(from start: CGPoint, to end: CGPoint) {

        let bolt = SKShapeNode(
            rectOf: CGSize(width: 30, height: 4),
            cornerRadius: 2
        )

        bolt.position = CGPoint(x: start.x + 24, y: start.y + 12)

        bolt.fillColor = weaponColor

        bolt.strokeColor = .white

        bolt.glowWidth = effectsEnabled ? 7 : 0

        bolt.zPosition = 35

        effectsNode.addChild(bolt)

        bolt.run(

            .sequence([

                .move(to: CGPoint(x: end.x - 18, y: end.y + 8), duration: 0.12),

                .removeFromParent(),

            ])

        )

    }

    private func emitHitParticles(at position: CGPoint, color: SKColor) {

        guard effectsEnabled else { return }

        let emitter = SKEmitterNode()

        emitter.position = position

        emitter.particleTexture = nil

        emitter.particleColor = color

        emitter.particleColorBlendFactor = 1

        emitter.particleBirthRate = CGFloat(90 * particleMultiplier)

        emitter.numParticlesToEmit = max(4, Int(14 * particleMultiplier))

        emitter.particleLifetime = 0.28

        emitter.particleLifetimeRange = 0.12

        emitter.emissionAngleRange = .pi * 2

        emitter.particleSpeed = 85

        emitter.particleSpeedRange = 45

        emitter.particleAlphaSpeed = -3

        emitter.particleScale = 0.08

        emitter.particleScaleRange = 0.04

        emitter.particleBlendMode = .add

        emitter.zPosition = 36

        effectsNode.addChild(emitter)

        emitter.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))

    }

    private func dash() {

        guard playerState == .idle else { return }

        playerState = .dashing

        let destination = CGPoint(

            x: min(enemy.position.x - 62, size.width - 70),

            y: playerHome.y

        )

        createAfterimages()

        player.run(

            .sequence([

                .move(to: destination, duration: 0.1),

                .wait(forDuration: 0.07),

                .move(to: playerHome, duration: 0.18),

                .run { [weak self] in self?.playerState = .idle },

            ])

        )

        showCallout("TRIGGER DASH", color: .cyan)

    }

    private func evade() {

        guard playerState == .idle else { return }

        playerState = .dashing

        createAfterimages()

        player.run(

            .sequence([

                .moveBy(x: -46, y: 18, duration: 0.09),

                .rotate(byAngle: .pi * 2, duration: 0.18),

                .move(to: playerHome, duration: 0.12),

                .run { [weak self] in self?.playerState = .idle },

            ])

        )

    }

    private func createSlash(kind: AttackKind, at position: CGPoint) {

        guard effectsEnabled else { return }

        let path = CGMutablePath()

        switch kind {

        case .slash:

            path.move(to: CGPoint(x: -42, y: 52))

            path.addQuadCurve(

                to: CGPoint(x: 58, y: -42),

                control: CGPoint(x: 46, y: 34)

            )

        case .launcher:

            path.move(to: CGPoint(x: -38, y: -42))

            path.addQuadCurve(

                to: CGPoint(x: 52, y: 58),

                control: CGPoint(x: 40, y: -20)

            )

        case .dive:

            path.move(to: CGPoint(x: -48, y: 18))

            path.addQuadCurve(

                to: CGPoint(x: 66, y: -8),

                control: CGPoint(x: 8, y: 34)

            )

        }

        let layers = max(1, Int((3 * particleMultiplier).rounded()))

        for layer in 0..<layers {

            let slash = SKShapeNode(path: path)

            slash.position = position

            slash.strokeColor = layer == 0 ? .white : kind.color

            slash.lineWidth = CGFloat(7 - layer * 2)

            slash.glowWidth = CGFloat(12 + layer * 5)

            slash.alpha = 1 - CGFloat(layer) * 0.2

            slash.zPosition = 30

            slash.blendMode = .add

            effectsNode.addChild(slash)

            slash.run(

                .sequence([

                    .group([

                        .scale(to: 1.25, duration: 0.11),

                        .fadeOut(withDuration: 0.18),

                    ]),

                    .removeFromParent(),

                ])

            )

        }

    }

    private func createImpact(at position: CGPoint) {

        guard effectsEnabled else { return }

        let particleCount = max(3, Int((10 * particleMultiplier).rounded()))

        for index in 0..<particleCount {

            let shardPath = CGMutablePath()

            shardPath.move(to: .zero)

            shardPath.addLine(to: CGPoint(x: 3, y: CGFloat(14 + index * 2)))

            let shard = SKShapeNode(path: shardPath)

            shard.position = CGPoint(x: position.x, y: floorY)

            shard.strokeColor = index.isMultiple(of: 2) ? .systemOrange : .white

            shard.lineWidth = 3

            shard.glowWidth = 5

            shard.zPosition = 25

            effectsNode.addChild(shard)

            let angle = CGFloat(index) / CGFloat(particleCount) * .pi

            let vector = CGVector(dx: cos(angle) * 95, dy: sin(angle) * 70)

            shard.run(

                .sequence([

                    .group([

                        .move(by: vector, duration: 0.24),

                        .fadeOut(withDuration: 0.24),

                    ]),

                    .removeFromParent(),

                ])

            )

        }

    }

    private func createAfterimages() {

        guard effectsEnabled else { return }

        let count = max(1, Int((3 * particleMultiplier).rounded()))

        for index in 1...count {

            let echo = SKShapeNode(
                path: helmetPath(style: appearance?.helmetStyle ?? .angular)
            )

            echo.position = CGPoint(

                x: player.position.x - CGFloat(index * 18),

                y: player.position.y + 44

            )

            echo.strokeColor = appearanceColor

            echo.fillColor = .clear

            echo.lineWidth = 2

            echo.glowWidth = 6

            echo.alpha = 0.55

            echo.zPosition = 6

            effectsNode.addChild(echo)

            echo.run(

                .sequence([.fadeOut(withDuration: 0.2), .removeFromParent()])

            )

        }

    }

    private func flashEnemy(color: SKColor) {

        enemy.run(

            .sequence([

                .colorize(with: color, colorBlendFactor: 1, duration: 0.03),

                .colorize(withColorBlendFactor: 0, duration: 0.08),

            ])

        )

    }

    private func defeatEnemy() {
        guard !isEnemyDefeated, !isGameOver else { return }
        if trainingMode {
            enemyHealth = 80 + CGFloat(wave * 18)
            enemyHealthBar.xScale = 1
            showCallout("DUMMY RESET", color: .cyan)
            updateHUD()
            return
        }
        isEnemyDefeated = true
        waveGeneration &+= 1
        let generation = waveGeneration
        enemyAttackTime = .infinity
        enemy.removeAllActions()
        enemyHealth = 0

        score += wave * 500
        combo += 2
        shake(amount: 12)
        createImpact(at: enemy.position)
        updateHUD()

        enemy.run(
            .sequence([
                .group([
                    .scale(to: 1.45, duration: 0.12),
                    .fadeOut(withDuration: 0.2),
                ]),
                .removeFromParent(),
            ]),
            withKey: "defeat"
        )

        if isStoryMode {
            return
        }

        // Schedule the next wave on the scene, not the removed enemy.
        run(
            .sequence([
                .wait(forDuration: 0.55),
                .run { [weak self] in
                    guard let self,
                        !self.isGameOver,
                        self.waveGeneration == generation
                    else { return }
                    self.wave += 1
                    self.spawnEnemy()
                    self.updateHUD()
                },
            ]),
            withKey: "nextWave"
        )
    }

    private func enemyAttack() {
        // Always advance the timer, including while the player is dashing.
        enemyAttackTime = lastUpdateTime + max(0.65, 1.5 - Double(wave) * 0.06)
        guard !isGameOver, !isEnemyDefeated, enemy.parent != nil,
            enemy.action(forKey: "enemyAttack") == nil
        else { return }

        let original = enemy.position
        enemy.run(
            .sequence([
                .moveBy(x: -22, y: 0, duration: 0.12),
                .move(
                    to: CGPoint(
                        x: player.position.x + 52,
                        y: player.position.y
                    ),
                    duration: 0.16
                ),
                .run { [weak self] in
                    guard let self, !self.isGameOver, !self.isEnemyDefeated
                    else { return }
                    self.takeDamage()
                },
                .move(to: original, duration: 0.22),
            ]),
            withKey: "enemyAttack"
        )
    }

    private func takeDamage() {

        guard !isGameOver else { return }
        guard playerState != .dashing else {

            showCallout("PERFECT!", color: .cyan)

            score += 150

            return

        }

        playerHealth -= CGFloat(10 + wave * 2)
        if trainingMode { playerHealth = max(1, playerHealth) }

        combo = 0

        shake(amount: 7)

        player.run(

            .sequence([

                .colorize(

                    with: .systemRed,

                    colorBlendFactor: 1,

                    duration: 0.05

                ),

                .colorize(withColorBlendFactor: 0, duration: 0.12),

            ])

        )

        updateHUD()

        if playerHealth <= 0 && !trainingMode {

            endGame()

        }

    }

    private func shake(amount: CGFloat) {

        guard screenShakeEnabled else { return }

        worldNode.removeAction(forKey: "shake")

        let actions = (0..<7).flatMap { _ in

            [

                SKAction.moveBy(

                    x: CGFloat.random(in: -amount...amount),

                    y: CGFloat.random(in: -amount...amount),

                    duration: 0.025

                ),

                SKAction.move(to: .zero, duration: 0.025),

            ]

        }

        worldNode.run(.sequence(actions), withKey: "shake")

    }

    private func showCallout(_ text: String, color: SKColor) {

        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")

        label.text = text

        label.fontSize = 25

        label.fontColor = color

        label.position = CGPoint(x: size.width / 2, y: size.height * 0.48)

        label.zPosition = 80

        label.setScale(0.5)

        addChild(label)

        label.run(

            .sequence([

                .group([

                    .scale(to: 1.15, duration: 0.1),

                    .fadeIn(withDuration: 0.08),

                ]),

                .wait(forDuration: 0.3),

                .group([

                    .moveBy(x: 0, y: 30, duration: 0.18),

                    .fadeOut(withDuration: 0.18),

                ]),

                .removeFromParent(),

            ])

        )

    }

    private func updateHUD() {

        scoreLabel.text = "SCORE  \(score)   WAVE  \(wave)"

        comboLabel.text = combo > 1 ? "\(combo) HIT COMBO" : "KEEP MOVING"

        let rank: String

        let styleRank: StyleRank

        let color: SKColor

        switch combo {

        case 0...2: (rank, styleRank, color) = ("D", .d, .white)

        case 3...5: (rank, styleRank, color) = ("C", .c, .cyan)

        case 6...8: (rank, styleRank, color) = ("B", .b, .systemBlue)

        case 9...12: (rank, styleRank, color) = ("A", .a, .systemPurple)

        case 13...17: (rank, styleRank, color) = ("S", .s, .systemPink)

        case 18...22: (rank, styleRank, color) = ("SS", .ss, .systemPink)
        case 23...29: (rank, styleRank, color) = ("SSS", .sss, .systemOrange)
        case 30...37: (rank, styleRank, color) = ("X", .x, .systemOrange)
        case 38...47: (rank, styleRank, color) = ("XX", .xx, .yellow)
        case 48...59: (rank, styleRank, color) = ("XXX", .xxx, .white)
        default: (rank, styleRank, color) = ("Ω", .omega, .cyan)

        }

        if styleRank > highestStyleRank {

            highestStyleRank = styleRank

            shake(amount: CGFloat(3 + styleRank.rawValue))

        }

        styleLabel.text = rank

        styleLabel.fontColor = color

        styleLabel.setScale(1.25)

        styleLabel.run(.scale(to: 1, duration: 0.12))

        let playerScale = max(0.001, playerHealth / maximumPlayerHealth)

        healthBar.xScale = playerScale

        healthBar.fillColor = playerHealth < 30 ? .systemRed : .cyan

        enemyHealthBar.xScale = max(0.001, enemyHealth / maximumEnemyHealth)

        onCombatSnapshot?(

            CombatSnapshot(

                playerHealth: Double(
                    max(0, playerHealth) / maximumPlayerHealth
                ),

                enemyHealth: Double(max(0, enemyHealth) / maximumEnemyHealth),

                comboCount: combo,

                score: score,

                totalDamage: totalDamage,

                styleRank: highestStyleRank

            )

        )

    }

    private func endGame() {

        guard !isGameOver else { return }
        isGameOver = true
        waveGeneration &+= 1
        removeAction(forKey: "nextWave")

        player.removeAllActions()

        enemy.removeAllActions()

        let panel = SKShapeNode(

            rectOf: CGSize(width: 310, height: 180),

            cornerRadius: 24

        )

        panel.name = "gameOver"

        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)

        panel.fillColor = SKColor.black.withAlphaComponent(0.88)

        panel.strokeColor = .systemPink

        panel.lineWidth = 3

        panel.glowWidth = 14

        panel.zPosition = 100

        addChild(panel)

        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")

        title.text = "STYLE BROKEN"

        title.fontSize = 38

        title.fontColor = .white

        title.position = CGPoint(x: 0, y: 32)

        panel.addChild(title)

        let result = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")

        result.text = "SCORE  \(score)  •  TAP TO RETRY"

        result.fontSize = 16

        result.fontColor = .cyan

        result.position = CGPoint(x: 0, y: -28)

        panel.addChild(result)

        onGameOver?(score)

    }

    private func restart() {
        waveGeneration &+= 1
        removeAction(forKey: "nextWave")
        player.removeAllActions()
        enemy.removeAllActions()
        player.childNode(withName: "weapon")?.removeAllActions()
        worldNode.removeAction(forKey: "shake")
        worldNode.position = .zero
        player.alpha = 1
        player.setScale(CGFloat(appearance?.bodyScale ?? 1))

        childNode(withName: "gameOver")?.removeFromParent()

        isGameOver = false

        score = 0

        combo = 0

        totalDamage = 0

        highestStyleRank = .d

        wave = 1

        playerHealth = 100

        enemyHealth = 100

        player.position = playerHome

        player.zRotation = 0

        playerState = .idle
        lastAttackTime = 0
        enemyAttackTime = 0
        lastUpdateTime = 0
        rebuildWeapon()
        comboDetector.configure(with: allCombos)
        configureCombosForCurrentWeapon()

        spawnEnemy()

        updateHUD()

    }

    override func update(_ currentTime: TimeInterval) {

        if lastUpdateTime == 0 {

            lastUpdateTime = currentTime

        }

        lastUpdateTime = currentTime

        guard !isGameOver else { return }

        if combo > 0, currentTime - lastAttackTime > 1.15 {

            combo = 0

            updateHUD()

        }

        if !isEnemyDefeated, currentTime >= enemyAttackTime {

            enemyAttack()

        }

    }

}

extension SKColor {

    fileprivate convenience init(hex: String) {

        let cleaned = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )

        let value = UInt64(cleaned, radix: 16) ?? 0

        self.init(

            red: CGFloat((value >> 16) & 0xFF) / 255,

            green: CGFloat((value >> 8) & 0xFF) / 255,

            blue: CGFloat(value & 0xFF) / 255,

            alpha: 1

        )

    }

}
