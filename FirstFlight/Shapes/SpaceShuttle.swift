import SpriteKit

class SpaceShuttle: SKNode {
    private let shuttleScale: CGFloat
    private var renderedSize: CGSize = .zero

    // MARK: - Debug editor (optional)
    private let debugEditorEnabled: Bool = true
    private var debugEditor: PolygonDebugEditor?

    init(scale: CGFloat = 0.6) {
        self.shuttleScale = scale
        super.init()
        zPosition = -11 // Below player (player is at -10)
        setupSprite()
        setupShadowAndHighlight()
        setupPhysics()
        if debugEditorEnabled {
            let editor = PolygonDebugEditor(
                size: renderedSize,
                baselinePointsProvider: { [weak self] in
                    return self?.shuttlePolygonPoints() ?? []
                },
                currentPointsProvider: { [weak self] in
                    return self?.currentPolygonPoints() ?? []
                },
                onPointsChanged: { [weak self] points, rebuildPhysics in
                    self?.applyPhysics(using: points)
                    if rebuildPhysics {
                        // nothing else for now
                    }
                },
                onPointsCommitted: { [weak self] points in
                    // Print normalized points for copy/paste
                    self?.printPointsToConsole(points)
                }
            )
            editor.zPosition = 999
            addChild(editor)
            debugEditor = editor
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.shuttleScale = 0.6
        super.init(coder: aDecoder)
    }

    private func setupSprite() {
        let texture = SKTexture(imageNamed: "space shuttle")
        texture.filteringMode = .linear

        // Get natural texture size and calculate rendered size
        let naturalSize = texture.size()
        renderedSize = CGSize(
            width: naturalSize.width * shuttleScale,
            height: naturalSize.height * shuttleScale
        )

        let sprite = SKSpriteNode(texture: texture)
        sprite.setScale(shuttleScale)
        sprite.name = "shuttle-sprite"
        sprite.zPosition = 0
        addChild(sprite)
    }

    private func setupShadowAndHighlight() {
        let offset = CGSize(width: renderedSize.width * 0.04, height: renderedSize.height * 0.04)

        // Scale blur radius proportionally (base 200x160 used radius 5/4)
        let scaleFactor = renderedSize.width / 200.0
        let shadowBlurRadius = 5.0 * scaleFactor * 0.53
        let highlightBlurRadius = 4.0 * scaleFactor * 0.5

        // Soft shadow with blur
        let shadowTexture = SKTexture(imageNamed: "space shuttle")
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.setScale(shuttleScale)
        shadowSprite.color = .black
        shadowSprite.colorBlendFactor = 1.0
        shadowSprite.alpha = 0.45
        shadowSprite.blendMode = .multiply

        let shadowEffect = SKEffectNode()
        shadowEffect.name = "shuttle-shadow"
        shadowEffect.shouldRasterize = true
        shadowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: shadowBlurRadius])
        shadowEffect.position = CGPoint(x: offset.width, y: -offset.height)
        shadowEffect.zPosition = -1
        shadowEffect.addChild(shadowSprite)
        addChild(shadowEffect)

        // Highlight with blur
        let highlightTexture = SKTexture(imageNamed: "space shuttle")
        let highlightSprite = SKSpriteNode(texture: highlightTexture)
        highlightSprite.setScale(shuttleScale * 0.92)
        highlightSprite.color = .white
        highlightSprite.colorBlendFactor = 1.0
        highlightSprite.alpha = 0.18
        highlightSprite.blendMode = .add

        let highlightEffect = SKEffectNode()
        highlightEffect.name = "shuttle-highlight"
        highlightEffect.shouldRasterize = true
        highlightEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: highlightBlurRadius])
        highlightEffect.position = CGPoint(x: -offset.width * 0.6, y: offset.height * 0.6)
        highlightEffect.zPosition = 1
        highlightEffect.addChild(highlightSprite)
        addChild(highlightEffect)
    }

    private func shuttlePolygonPoints() -> [CGPoint] {
        let w = renderedSize.width
        let h = renderedSize.height

        // Nose is to the left (-X), tail/engines to the right (+X).
        // Keep this list as the single source of truth for both physics and debug.
        return [
            CGPoint(x: w * -0.264, y: h * 0.065), // 0  (-158, 30)
            CGPoint(x: w * -0.331, y: h * 0.157), // 1  (-198, 75)
            CGPoint(x: w * -0.451, y: h * 0.267), // 2  (-270, 128)
            CGPoint(x: w * -0.345, y: h * 0.293), // 3  (-207, 140)
            CGPoint(x: w * -0.284, y: h * 0.257), // 4  (-170, 123)
            CGPoint(x: w * -0.232, y: h * 0.228), // 5  (-139, 109)
            CGPoint(x: w * -0.147, y: h * 0.222), // 6  (-88, 106)
            CGPoint(x: w * 0.008, y: h * 0.268), // 7  (4, 128)
            CGPoint(x: w * 0.087, y: h * 0.395), // 8  (52, 189)
            CGPoint(x: w * 0.202, y: h * 0.503), // 9  (121, 241)
            CGPoint(x: w * 0.229, y: h * 0.297), // 10  (137, 142)
            CGPoint(x: w * 0.367, y: h * 0.258), // 11  (220, 123)
            CGPoint(x: w * 0.370, y: h * 0.124), // 12  (222, 59)
            CGPoint(x: w * 0.311, y: h * 0.072), // 13  (186, 34)
            CGPoint(x: w * 0.500, y: h * 0.000), // 14  (300, 0)
            CGPoint(x: w * 0.483, y: h * -0.041), // 15  (289, -19)
            CGPoint(x: w * 0.488, y: h * -0.069), // 16  (292, -33)
            CGPoint(x: w * 0.433, y: h * -0.099), // 17  (259, -47)
            CGPoint(x: w * 0.342, y: h * -0.090), // 18  (205, -43)
            CGPoint(x: w * 0.273, y: h * -0.093), // 19  (163, -44)
            CGPoint(x: w * 0.182, y: h * -0.072), // 20  (109, -34)
            CGPoint(x: w * 0.062, y: h * -0.123), // 21  (37, -59)
            CGPoint(x: w * -0.083, y: h * -0.133), // 22  (-49, -63)
            CGPoint(x: w * -0.212, y: h * -0.190), // 23  (-126, -91)
            CGPoint(x: w * -0.278, y: h * -0.238), // 24  (-166, -114)
            CGPoint(x: w * -0.367, y: h * -0.232), // 25  (-219, -111)
            CGPoint(x: w * -0.395, y: h * -0.185), // 26  (-236, -89)
            CGPoint(x: w * -0.340, y: h * -0.019), // 27  (-204, -9)
        ]
    }

    private func currentPolygonPoints() -> [CGPoint] {
        return debugEditor?.currentPoints ?? shuttlePolygonPoints()
    }

    private func createShuttlePath() -> CGPath {
        let pts = currentPolygonPoints()
        let path = CGMutablePath()

        guard let first = pts.first else { return path }
        path.move(to: first)
        for p in pts.dropFirst() {
            path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }

    private func setupPhysics() {
        applyPhysics(using: currentPolygonPoints())
    }

    private func applyPhysics(using points: [CGPoint]) {
        let path = CGMutablePath()
        guard let first = points.first else { return }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()

        physicsBody = SKPhysicsBody(polygonFrom: path)
        physicsBody?.categoryBitMask = PhysicsCategory.rock
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.player
        physicsBody?.isDynamic = false
        physicsBody?.friction = 0.8
        physicsBody?.restitution = 0.1
    }

    // Print normalized points for copy/paste
    private func printPointsToConsole(_ points: [CGPoint]) {
        let w = renderedSize.width
        let h = renderedSize.height

        func fmt(_ v: CGFloat) -> String {
            return String(format: "%.3f", Double(v))
        }

        print("\n--- SpaceShuttle polygon points (normalized) ---")
        print("return [")
        for (i, p) in points.enumerated() {
            let nx = p.x / w
            let ny = p.y / h
            print("    CGPoint(x: w * \(fmt(nx)), y: h * \(fmt(ny))), // \(i)  (\(Int(p.x)), \(Int(p.y)))")
        }
        print("]")
        print("--- end ---\n")
    }

    // (Touch editing handled by debug editor)
}
