import SpriteKit

final class ActionGameScene: SKScene {
    var onGameOver: ((Int) -> Void)?

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

    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
    private let comboLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    private let styleLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
    private let healthBar = SKShapeNode(rectOf: CGSize(width: 112, height: 8), cornerRadius: 4)
    private let enemyHealthBar = SKShapeNode(rectOf: CGSize(width: 116, height: 7), cornerRadius: 3.5)

    private var playerState: PlayerState = .idle
    private var touchStart = CGPoint.zero
    private var touchStartTime: TimeInterval = 0
    private var lastAttackTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var enemyAttackTime: TimeInterval = 0
    private var combo = 0
    private var score = 0
    private var wave = 1
    private var playerHealth: CGFloat = 100
    private var enemyHealth: CGFloat = 100
    private var isGameOver = false
    private var hasStarted = false

    private let floorY: CGFloat = 190
    private var playerHome = CGPoint(x: 104, y: 226)
    private var enemyHome = CGPoint(x: 292, y: 226)

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = .zero
        backgroundColor = SKColor(red: 0.018, green: 0.022, blue: 0.055, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        guard !hasStarted else { return }
        hasStarted = true
        view.isMultipleTouchEnabled = false
        physicsWorld.gravity = CGVector(dx: 0, dy: -8)
        addChild(worldNode)
        worldNode.addChild(effectsNode)
        buildArena()
        buildHUD()
        buildPlayer()
        spawnEnemy()
        showCallout("TAP TO SLASH", color: .cyan)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasStarted else { return }
        playerHome = CGPoint(x: size.width * 0.27, y: floorY + 36)
        enemyHome = CGPoint(x: size.width * 0.74, y: floorY + 36)
    }

    private func buildArena() {
        let backdrop = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        backdrop.fillColor = backgroundColor
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
            let building = SKShapeNode(rectOf: CGSize(width: buildingWidth, height: buildingHeight))
            building.position = CGPoint(
                x: CGFloat(index) * size.width / 8,
                y: floorY + buildingHeight / 2
            )
            building.fillColor = SKColor(red: 0.025, green: 0.035, blue: 0.075, alpha: 1)
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

    private func buildHUD() {
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 22, y: size.height - 58)
        scoreLabel.zPosition = 50
        worldNode.addChild(scoreLabel)

        healthBar.fillColor = .cyan
        healthBar.strokeColor = .white.withAlphaComponent(0.3)
        healthBar.position = CGPoint(x: 78, y: size.height - 78)
        healthBar.zPosition = 50
        worldNode.addChild(healthBar)

        styleLabel.text = "D"
        styleLabel.fontSize = 66
        styleLabel.fontColor = .white
        styleLabel.position = CGPoint(x: size.width - 50, y: size.height - 90)
        styleLabel.zRotation = -0.1
        styleLabel.zPosition = 50
        worldNode.addChild(styleLabel)

        comboLabel.fontSize = 18
        comboLabel.fontColor = .cyan
        comboLabel.position = CGPoint(x: size.width - 62, y: size.height - 116)
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

        let coatPath = CGMutablePath()
        coatPath.move(to: CGPoint(x: -18, y: -34))
        coatPath.addLine(to: CGPoint(x: -25, y: 12))
        coatPath.addLine(to: CGPoint(x: -14, y: 32))
        coatPath.addLine(to: CGPoint(x: 8, y: 36))
        coatPath.addLine(to: CGPoint(x: 22, y: 16))
        coatPath.addLine(to: CGPoint(x: 16, y: -34))
        coatPath.addLine(to: CGPoint(x: 2, y: -12))
        coatPath.closeSubpath()
        let coat = SKShapeNode(path: coatPath)
        coat.fillColor = SKColor(red: 0.12, green: 0.02, blue: 0.08, alpha: 1)
        coat.strokeColor = .systemPink
        coat.lineWidth = 3
        coat.glowWidth = 3
        player.addChild(coat)

        let head = SKShapeNode(path: helmetPath())
        head.position = CGPoint(x: 0, y: 44)
        head.fillColor = .black
        head.strokeColor = .white
        head.lineWidth = 2
        player.addChild(head)

        let visor = SKShapeNode(rectOf: CGSize(width: 22, height: 4), cornerRadius: 2)
        visor.position = CGPoint(x: 5, y: 45)
        visor.fillColor = .cyan
        visor.strokeColor = .white
        visor.glowWidth = 7
        player.addChild(visor)

        let sword = SKShapeNode(path: swordPath())
        sword.name = "sword"
        sword.position = CGPoint(x: 12, y: 5)
        sword.fillColor = .white
        sword.strokeColor = .cyan
        sword.lineWidth = 2
        sword.glowWidth = 4
        sword.zRotation = -.pi / 5
        sword.zPosition = -1
        player.addChild(sword)
    }

    private func spawnEnemy() {
        enemy.removeFromParent()
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
        body.fillColor = SKColor(red: 0.04, green: 0.015, blue: 0.08, alpha: 1)
        body.strokeColor = .systemPurple
        body.lineWidth = 3
        body.glowWidth = 5
        enemy.addChild(body)

        let hornLeft = SKShapeNode(path: hornPath(mirrored: false))
        hornLeft.position = CGPoint(x: -8, y: 30)
        hornLeft.fillColor = .systemPurple
        hornLeft.strokeColor = .systemPink
        enemy.addChild(hornLeft)

        let hornRight = SKShapeNode(path: hornPath(mirrored: true))
        hornRight.position = CGPoint(x: 8, y: 30)
        hornRight.fillColor = .systemPurple
        hornRight.strokeColor = .systemPink
        enemy.addChild(hornRight)

        let eye = SKShapeNode(rectOf: CGSize(width: 24, height: 4), cornerRadius: 2)
        eye.position = CGPoint(x: -3, y: 19)
        eye.fillColor = .systemPink
        eye.strokeColor = .white
        eye.glowWidth = 8
        enemy.addChild(eye)

        enemyHealthBar.fillColor = .systemPink
        enemyHealthBar.strokeColor = .white.withAlphaComponent(0.25)
        enemyHealthBar.position = CGPoint(x: 0, y: 66)
        enemy.addChild(enemyHealthBar)

        enemyHealth = 80 + CGFloat(wave * 18)
        enemyAttackTime = lastUpdateTime + 1.25
        worldNode.addChild(enemy)
        enemy.setScale(0.1)
        enemy.alpha = 0
        enemy.run(.group([
            .scale(to: 1, duration: 0.25),
            .fadeIn(withDuration: 0.2)
        ]))
        showCallout("WAVE \(wave)", color: .systemPink)
    }

    private func helmetPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -14, y: -12))
        path.addLine(to: CGPoint(x: -20, y: 5))
        path.addLine(to: CGPoint(x: -10, y: 18))
        path.addLine(to: CGPoint(x: 13, y: 15))
        path.addLine(to: CGPoint(x: 20, y: 0))
        path.addLine(to: CGPoint(x: 10, y: -14))
        path.closeSubpath()
        return path
    }

    private func swordPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -4, y: -8))
        path.addLine(to: CGPoint(x: -5, y: 50))
        path.addLine(to: CGPoint(x: 0, y: 67))
        path.addLine(to: CGPoint(x: 7, y: 48))
        path.addLine(to: CGPoint(x: 5, y: -8))
        path.closeSubpath()
        return path
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

        if distance < 32 {
            performAttack(.slash)
        } else if abs(delta.dy) > abs(delta.dx), delta.dy > 0 {
            performAttack(.launcher)
        } else if abs(delta.dy) > abs(delta.dx), delta.dy < 0 {
            performAttack(.dive)
        } else if delta.dx > 0 {
            dash()
        } else {
            evade()
        }
    }

    private func performAttack(_ kind: AttackKind) {
        guard playerState != .dashing else { return }
        playerState = kind == .launcher ? .airborne : .attacking
        combo = lastUpdateTime - lastAttackTime < 0.72 ? combo + 1 : 1
        lastAttackTime = lastUpdateTime

        let nearEnemy = abs(player.position.x - enemy.position.x) < 205
        let lunge: CGFloat = min(48, max(0, enemy.position.x - player.position.x - 72))
        let start = player.position
        let destination = CGPoint(x: start.x + lunge, y: kind == .launcher ? start.y + 34 : start.y)

        player.removeAction(forKey: "attack")
        player.run(.sequence([
            .move(to: destination, duration: 0.055),
            .wait(forDuration: 0.07),
            .move(to: playerHome, duration: 0.13),
            .run { [weak self] in self?.playerState = .idle }
        ]), withKey: "attack")

        if let sword = player.childNode(withName: "sword") {
            sword.removeAllActions()
            let angle: CGFloat = kind == .launcher ? 1.9 : -2.8
            sword.run(.sequence([
                .rotate(byAngle: angle, duration: 0.08),
                .rotate(toAngle: -.pi / 5, duration: 0.12)
            ]))
        }

        createSlash(kind: kind, at: CGPoint(x: player.position.x + 58, y: player.position.y + 10))

        guard nearEnemy else {
            combo = 0
            updateHUD()
            return
        }

        let multiplier = 1 + min(CGFloat(combo) * 0.035, 0.5)
        enemyHealth -= kind.damage * multiplier
        score += Int(kind.damage) * max(1, combo)
        flashEnemy(color: kind.color)

        switch kind {
        case .slash:
            enemy.run(.sequence([.moveBy(x: 13, y: 0, duration: 0.05), .move(to: enemyHome, duration: 0.12)]))
        case .launcher:
            enemy.run(.sequence([
                .moveBy(x: 12, y: 92, duration: 0.14),
                .wait(forDuration: 0.08),
                .move(to: enemyHome, duration: 0.22)
            ]))
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

    private func dash() {
        guard playerState == .idle else { return }
        playerState = .dashing
        let destination = CGPoint(x: min(enemy.position.x - 62, size.width - 70), y: playerHome.y)
        createAfterimages()
        player.run(.sequence([
            .move(to: destination, duration: 0.1),
            .wait(forDuration: 0.07),
            .move(to: playerHome, duration: 0.18),
            .run { [weak self] in self?.playerState = .idle }
        ]))
        showCallout("TRIGGER DASH", color: .cyan)
    }

    private func evade() {
        guard playerState == .idle else { return }
        playerState = .dashing
        createAfterimages()
        player.run(.sequence([
            .moveBy(x: -46, y: 18, duration: 0.09),
            .rotate(byAngle: .pi * 2, duration: 0.18),
            .move(to: playerHome, duration: 0.12),
            .run { [weak self] in self?.playerState = .idle }
        ]))
    }

    private func createSlash(kind: AttackKind, at position: CGPoint) {
        let path = CGMutablePath()
        switch kind {
        case .slash:
            path.move(to: CGPoint(x: -42, y: 52))
            path.addQuadCurve(to: CGPoint(x: 58, y: -42), control: CGPoint(x: 46, y: 34))
        case .launcher:
            path.move(to: CGPoint(x: -38, y: -42))
            path.addQuadCurve(to: CGPoint(x: 52, y: 58), control: CGPoint(x: 40, y: -20))
        case .dive:
            path.move(to: CGPoint(x: -48, y: 18))
            path.addQuadCurve(to: CGPoint(x: 66, y: -8), control: CGPoint(x: 8, y: 34))
        }

        for layer in 0..<3 {
            let slash = SKShapeNode(path: path)
            slash.position = position
            slash.strokeColor = layer == 0 ? .white : kind.color
            slash.lineWidth = CGFloat(7 - layer * 2)
            slash.glowWidth = CGFloat(12 + layer * 5)
            slash.alpha = 1 - CGFloat(layer) * 0.2
            slash.zPosition = 30
            slash.blendMode = .add
            effectsNode.addChild(slash)
            slash.run(.sequence([
                .group([.scale(to: 1.25, duration: 0.11), .fadeOut(withDuration: 0.18)]),
                .removeFromParent()
            ]))
        }
    }

    private func createImpact(at position: CGPoint) {
        for index in 0..<10 {
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
            let angle = CGFloat(index) / 10 * .pi
            let vector = CGVector(dx: cos(angle) * 95, dy: sin(angle) * 70)
            shard.run(.sequence([
                .group([.move(by: vector, duration: 0.24), .fadeOut(withDuration: 0.24)]),
                .removeFromParent()
            ]))
        }
    }

    private func createAfterimages() {
        for index in 1...3 {
            let echo = SKShapeNode(path: helmetPath())
            echo.position = CGPoint(x: player.position.x - CGFloat(index * 18), y: player.position.y + 44)
            echo.strokeColor = .cyan
            echo.fillColor = .clear
            echo.lineWidth = 2
            echo.glowWidth = 6
            echo.alpha = 0.55
            echo.zPosition = 6
            effectsNode.addChild(echo)
            echo.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
        }
    }

    private func flashEnemy(color: SKColor) {
        enemy.run(.sequence([
            .colorize(with: color, colorBlendFactor: 1, duration: 0.03),
            .colorize(withColorBlendFactor: 0, duration: 0.08)
        ]))
    }

    private func defeatEnemy() {
        score += wave * 500
        combo += 2
        shake(amount: 12)
        createImpact(at: enemy.position)
        enemy.run(.sequence([
            .group([.scale(to: 1.45, duration: 0.12), .fadeOut(withDuration: 0.2)]),
            .removeFromParent(),
            .wait(forDuration: 0.35),
            .run { [weak self] in
                guard let self else { return }
                self.wave += 1
                self.spawnEnemy()
            }
        ]))
    }

    private func enemyAttack() {
        guard playerState != .dashing, enemy.parent != nil else { return }
        enemyAttackTime = lastUpdateTime + max(0.65, 1.5 - Double(wave) * 0.06)
        let original = enemy.position
        enemy.run(.sequence([
            .moveBy(x: -22, y: 0, duration: 0.12),
            .move(to: CGPoint(x: player.position.x + 52, y: player.position.y), duration: 0.16),
            .run { [weak self] in self?.takeDamage() },
            .move(to: original, duration: 0.22)
        ]))
    }

    private func takeDamage() {
        guard playerState != .dashing else {
            showCallout("PERFECT!", color: .cyan)
            score += 150
            return
        }
        playerHealth -= CGFloat(10 + wave * 2)
        combo = 0
        shake(amount: 7)
        player.run(.sequence([
            .colorize(with: .systemRed, colorBlendFactor: 1, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.12)
        ]))
        updateHUD()
        if playerHealth <= 0 {
            endGame()
        }
    }

    private func shake(amount: CGFloat) {
        worldNode.removeAction(forKey: "shake")
        let actions = (0..<7).flatMap { _ in
            [
                SKAction.moveBy(x: CGFloat.random(in: -amount...amount), y: CGFloat.random(in: -amount...amount), duration: 0.025),
                SKAction.move(to: .zero, duration: 0.025)
            ]
        }
        worldNode.run(.sequence(actions), withKey: "shake")
    }

    private func showCallout(_ text: String, color: SKColor) {
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
        label.text = text
        label.fontSize = 25
        label.fontColor = color
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        label.zPosition = 80
        label.setScale(0.5)
        addChild(label)
        label.run(.sequence([
            .group([.scale(to: 1.15, duration: 0.1), .fadeIn(withDuration: 0.08)]),
            .wait(forDuration: 0.3),
            .group([.moveBy(x: 0, y: 30, duration: 0.18), .fadeOut(withDuration: 0.18)]),
            .removeFromParent()
        ]))
    }

    private func updateHUD() {
        scoreLabel.text = "SCORE  \(score)   WAVE  \(wave)"
        comboLabel.text = combo > 1 ? "\(combo) HIT COMBO" : "KEEP MOVING"
        let rank: String
        let color: SKColor
        switch combo {
        case 0...2: (rank, color) = ("D", .white)
        case 3...5: (rank, color) = ("C", .cyan)
        case 6...8: (rank, color) = ("B", .systemBlue)
        case 9...12: (rank, color) = ("A", .systemPurple)
        case 13...17: (rank, color) = ("S", .systemPink)
        default: (rank, color) = ("SSS", .systemOrange)
        }
        styleLabel.text = rank
        styleLabel.fontColor = color
        styleLabel.setScale(1.25)
        styleLabel.run(.scale(to: 1, duration: 0.12))

        let playerScale = max(0.001, playerHealth / 100)
        healthBar.xScale = playerScale
        healthBar.fillColor = playerHealth < 30 ? .systemRed : .cyan

        let maximumEnemyHealth = 80 + CGFloat(wave * 18)
        enemyHealthBar.xScale = max(0.001, enemyHealth / maximumEnemyHealth)
    }

    private func endGame() {
        isGameOver = true
        player.removeAllActions()
        enemy.removeAllActions()
        let panel = SKShapeNode(rectOf: CGSize(width: 310, height: 180), cornerRadius: 24)
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
        childNode(withName: "gameOver")?.removeFromParent()
        isGameOver = false
        score = 0
        combo = 0
        wave = 1
        playerHealth = 100
        enemyHealth = 100
        player.position = playerHome
        player.zRotation = 0
        playerState = .idle
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
        if currentTime >= enemyAttackTime {
            enemyAttack()
        }
    }
}
