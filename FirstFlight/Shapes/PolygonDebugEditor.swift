import SpriteKit

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
