import SpriteKit

class SpaceShuttle: SKNode {
    private let shuttleSize: CGSize

    // MARK: - Debug editor (optional)
    private let debugEditorEnabled: Bool = false
    private var debugEditor: PolygonDebugEditor?

    init(size: CGSize = CGSize(width: 600, height: 480)) {
        self.shuttleSize = size
        super.init()
        setupSprite()
        setupShadowAndHighlight()
        setupPhysics()
        if debugEditorEnabled {
            let editor = PolygonDebugEditor(
                size: shuttleSize,
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
        self.shuttleSize = CGSize(width: 600, height: 480)
        super.init(coder: aDecoder)
    }

    private func setupSprite() {
        let texture = SKTexture(imageNamed: "space shuttle")
        texture.filteringMode = .linear

        let sprite = SKSpriteNode(texture: texture, size: shuttleSize)
        sprite.name = "shuttle-sprite"
        sprite.zPosition = 0
        addChild(sprite)
    }

    private func setupShadowAndHighlight() {
        let offset = CGSize(width: shuttleSize.width * 0.04, height: shuttleSize.height * 0.04)

        // Scale blur radius proportionally (base 200x160 used radius 5/4, now 3x larger uses 8/6)
        let scaleFactor = shuttleSize.width / 200.0
        let shadowBlurRadius = 5.0 * scaleFactor * 0.53  // Results in ~8 for 600 width
        let highlightBlurRadius = 4.0 * scaleFactor * 0.5  // Results in ~6 for 600 width

        // Soft shadow with blur
        let shadowTexture = SKTexture(imageNamed: "space shuttle")
        let shadowSprite = SKSpriteNode(texture: shadowTexture, size: shuttleSize)
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
        let highlightSprite = SKSpriteNode(texture: highlightTexture, size: shuttleSize)
        highlightSprite.color = .white
        highlightSprite.colorBlendFactor = 1.0
        highlightSprite.alpha = 0.18
        highlightSprite.blendMode = .add
        highlightSprite.setScale(0.92)

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
        let w = shuttleSize.width
        let h = shuttleSize.height

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
        let w = shuttleSize.width
        let h = shuttleSize.height

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


// MARK: - Reusable polygon debug editor

final class PolygonDebugEditor: SKNode {
    let size: CGSize

    // Public read-only current points used by the owner
    private(set) var currentPoints: [CGPoint]

    private let baselinePointsProvider: () -> [CGPoint]
    private let currentPointsProvider: () -> [CGPoint]
    private let onPointsChanged: (_ points: [CGPoint], _ rebuildPhysics: Bool) -> Void
    private let onPointsCommitted: (_ points: [CGPoint]) -> Void

    // Visual toggles
    private let showGrid: Bool = true
    private let showVertexLabels: Bool = true
    private let showSpriteCornerLabels: Bool = true
    private let showEditorHandles: Bool = true
    private let showBorder: Bool = true

    private weak var activeHandle: SKNode?
    private var lastPhysicsRebuildTime: TimeInterval = 0

    init(
        size: CGSize,
        baselinePointsProvider: @escaping () -> [CGPoint],
        currentPointsProvider: @escaping () -> [CGPoint],
        onPointsChanged: @escaping (_ points: [CGPoint], _ rebuildPhysics: Bool) -> Void,
        onPointsCommitted: @escaping (_ points: [CGPoint]) -> Void
    ) {
        self.size = size
        self.baselinePointsProvider = baselinePointsProvider
        self.currentPointsProvider = currentPointsProvider
        self.onPointsChanged = onPointsChanged
        self.onPointsCommitted = onPointsCommitted
        self.currentPoints = currentPointsProvider()
        super.init()
        isUserInteractionEnabled = true
        rebuildOverlay()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func rebuildOverlay() {
        removeAllChildren()

        // Keep in sync if owner changed points externally
        currentPoints = currentPointsProvider()

        let w = size.width
        let h = size.height

        // Root overlay node
        let overlay = SKNode()
        overlay.name = "debug-overlay"
        addChild(overlay)

        // 1) Grid + axis
        if showGrid {
            let step: CGFloat = max(40, min(w, h) / 8.0)
            let gridPath = CGMutablePath()

            var x: CGFloat = -w * 0.6
            while x <= w * 0.6 {
                gridPath.move(to: CGPoint(x: x, y: -h * 0.6))
                gridPath.addLine(to: CGPoint(x: x, y:  h * 0.6))
                x += step
            }

            var y: CGFloat = -h * 0.6
            while y <= h * 0.6 {
                gridPath.move(to: CGPoint(x: -w * 0.6, y: y))
                gridPath.addLine(to: CGPoint(x:  w * 0.6, y: y))
                y += step
            }

            let grid = SKShapeNode(path: gridPath)
            grid.strokeColor = .white
            grid.lineWidth = 1.0
            grid.alpha = 0.10
            overlay.addChild(grid)

            let axisPath = CGMutablePath()
            axisPath.move(to: CGPoint(x: -w * 0.6, y: 0))
            axisPath.addLine(to: CGPoint(x:  w * 0.6, y: 0))
            axisPath.move(to: CGPoint(x: 0, y: -h * 0.6))
            axisPath.addLine(to: CGPoint(x: 0, y:  h * 0.6))

            let axis = SKShapeNode(path: axisPath)
            axis.strokeColor = .yellow
            axis.lineWidth = 1.5
            axis.alpha = 0.35
            overlay.addChild(axis)
        }

        // 2) Sprite bounds
        if showSpriteCornerLabels {
            let corners: [(String, CGPoint)] = [
                ("TL", CGPoint(x: -w * 0.5, y:  h * 0.5)),
                ("TR", CGPoint(x:  w * 0.5, y:  h * 0.5)),
                ("BR", CGPoint(x:  w * 0.5, y: -h * 0.5)),
                ("BL", CGPoint(x: -w * 0.5, y: -h * 0.5))
            ]

            let rect = CGRect(x: -w * 0.5, y: -h * 0.5, width: w, height: h)
            let rectNode = SKShapeNode(rect: rect)
            rectNode.strokeColor = .cyan
            rectNode.lineWidth = 2.0
            rectNode.alpha = 0.5
            overlay.addChild(rectNode)

            for (name, p) in corners {
                let dot = SKShapeNode(circleOfRadius: 3)
                dot.fillColor = .cyan
                dot.strokeColor = .clear
                dot.position = p
                overlay.addChild(dot)

                let label = SKLabelNode(fontNamed: "Menlo")
                label.fontSize = 10
                label.horizontalAlignmentMode = .left
                label.verticalAlignmentMode = .center
                label.fontColor = .cyan
                label.text = "\(name) (\(Int(p.x)), \(Int(p.y)))"
                label.position = CGPoint(x: p.x + 6, y: p.y)
                overlay.addChild(label)
            }
        }

        // 3) Border
        if showBorder {
            let path = CGMutablePath()
            if let first = currentPoints.first {
                path.move(to: first)
                for p in currentPoints.dropFirst() { path.addLine(to: p) }
                path.closeSubpath()

                let border = SKShapeNode(path: path)
                border.name = "debug-border"
                border.strokeColor = .green
                border.lineWidth = 2.0
                border.fillColor = .clear
                border.alpha = 0.9
                overlay.addChild(border)
            }
        }

        // 4) Vertices + handles
        if showVertexLabels {
            for (i, p) in currentPoints.enumerated() {
                let dot = SKShapeNode(circleOfRadius: 3)
                dot.fillColor = .green
                dot.strokeColor = .clear
                dot.position = p
                overlay.addChild(dot)

                if showEditorHandles {
                    let handle = SKShapeNode(circleOfRadius: 18)
                    handle.name = "poly-handle-\(i)"
                    handle.strokeColor = .clear
                    handle.fillColor = .clear
                    handle.position = p
                    handle.userData = ["index": i]
                    overlay.addChild(handle)
                }

                let label = SKLabelNode(fontNamed: "Menlo")
                label.fontSize = 10
                label.horizontalAlignmentMode = .left
                label.verticalAlignmentMode = .center
                label.fontColor = .green
                label.text = "#\(i) (\(Int(p.x)), \(Int(p.y)))"

                let dx: CGFloat = (p.x >= 0) ? 8 : -60
                let dy: CGFloat = (p.y >= 0) ? 10 : -10
                label.position = CGPoint(x: p.x + dx, y: p.y + dy)
                overlay.addChild(label)
            }
        }
    }

    // MARK: - Touch editing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // Ensure we have a mutable copy based on baseline if current is empty
        if currentPoints.isEmpty {
            currentPoints = baselinePointsProvider()
        }

        let loc = touch.location(in: self)
        let nodes = nodes(at: loc)

        if let handle = nodes.first(where: { $0.name?.hasPrefix("poly-handle-") == true }) {
            activeHandle = handle
        } else {
            activeHandle = nil
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let handle = activeHandle,
              let idx = handle.userData?["index"] as? Int,
              idx >= 0, idx < currentPoints.count else { return }

        let loc = touch.location(in: self)
        currentPoints[idx] = loc

        // Update overlay immediately
        rebuildOverlay()

        // Notify owner; throttle heavy rebuilds
        onPointsChanged(currentPoints, false)

        let now = touch.timestamp
        if now - lastPhysicsRebuildTime > 0.12 {
            lastPhysicsRebuildTime = now
            onPointsChanged(currentPoints, true)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeHandle = nil
        onPointsChanged(currentPoints, true)
        onPointsCommitted(currentPoints)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeHandle = nil
    }
}
