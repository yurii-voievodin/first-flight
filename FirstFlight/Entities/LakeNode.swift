import SpriteKit
import GameplayKit

class LakeNode: SKShapeNode {
    private let lakeDepth: CGFloat
    private let randomSource: GKLinearCongruentialRandomSource
    private let debugShowDepth: Bool
    private var depthLabel: SKLabelNode?

    // Layer nodes used when rendering cropped layers
    private var cropNode: SKCropNode?
    private var gradientSprite: SKSpriteNode?
    private var ripplesSprite: SKSpriteNode?

    // MARK: - Texture names (assets)
    private static let waterTextureName = "water_tile"
    private static let waterRipplesTextureName = "water_ripples_tile"

    init(
        position: CGPoint,
        size: CGSize,
        depth: CGFloat = 1.0,
        debugShowDepth: Bool = false
    ) {
        self.lakeDepth = max(depth, 0.0)
        let seed = LakeNode.computeSeed(from: position)
        self.randomSource = GKLinearCongruentialRandomSource(seed: seed)
        self.debugShowDepth = debugShowDepth
        super.init()

        self.position = position
        createLakeShape(size: size)
        setupVisuals(size: size)
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        self.lakeDepth = 1.0
        self.randomSource = GKLinearCongruentialRandomSource()
        self.debugShowDepth = false
        super.init(coder: aDecoder)
    }

    private func createLakeShape(size: CGSize) {
        let path = createOrganicWaterPath(size: size)
        self.path = path
    }

    private func setupVisuals(size: CGSize) {
        // Expanded visual range: depth 0...60 gives more perceivable steps
        let depthFactor = min(lakeDepth / 60.0, 1.0)
        let deepBlue = CGFloat(0.5 + depthFactor * 0.3)
        let greenComponent = CGFloat(0.4 + depthFactor * 0.2)

        // Baseline style for the outline.
        strokeColor = .clear
        lineWidth = 2.5
        zPosition = -20

        // Common tint used by both rendering modes.
        let tint = SKColor(
            red: 0.0,
            green: greenComponent,
            blue: deepBlue,
            // Deeper lakes appear darker and denser
            alpha: 0.50 + depthFactor * 0.35
        )

        // Always render using cropped layers (depth gradient + ripples)
        fillTexture = nil
        fillColor = .clear

        buildOrUpdateCroppedLayers(size: size, tint: tint, depthFactor: depthFactor)
        if debugShowDepth {
            if depthLabel == nil {
                let label = SKLabelNode(fontNamed: "Menlo")
                label.fontSize = 14
                label.horizontalAlignmentMode = .center
                label.verticalAlignmentMode = .center
                label.zPosition = 100
                addChild(label)
                depthLabel = label
            }

            depthLabel?.text = String(format: "depth=%.1f  factor=%.2f", lakeDepth, depthFactor)
            depthLabel?.position = .zero
            depthLabel?.fontColor = .white
            depthLabel?.alpha = 0.85
        } else {
            depthLabel?.removeFromParent()
            depthLabel = nil
        }
    }

    private func setupPhysics() {
        guard let lakePath = path else { return }
        // Use edge-based body: works with concave paths and is appropriate
        // for a non-dynamic sensor (no collisions, contact detection only).
        physicsBody = SKPhysicsBody(edgeLoopFrom: lakePath)
        physicsBody?.categoryBitMask = PhysicsCategory.terrain
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.friction = 0.2
        physicsBody?.restitution = 0.0
    }

    private func randomCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let span = range.upperBound - range.lowerBound
        return range.lowerBound + CGFloat(randomSource.nextUniform()) * span
    }

    private func createOrganicWaterPath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        let pointCount = randomSource.nextInt(upperBound: 6) + 12

        let radiusX = size.width / 2
        let radiusY = size.height / 2
        let jitterX = max(10, radiusX * 0.2)
        let jitterY = max(10, radiusY * 0.2)

        var points: [CGPoint] = []
        for index in 0..<pointCount {
            let angle = CGFloat(index) / CGFloat(pointCount) * .pi * 2
            let noiseX = randomCGFloat(in: -jitterX...jitterX)
            let noiseY = randomCGFloat(in: -jitterY...jitterY)
            let x = cos(angle) * radiusX + noiseX
            let y = sin(angle) * radiusY + noiseY
            points.append(CGPoint(x: x, y: y))
        }

        guard !points.isEmpty else {
            return path
        }

        path.move(to: points[0])
        for i in 0..<points.count {
            let current = points[i]
            let next = points[(i + 1) % points.count]
            let midPoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            path.addQuadCurve(to: midPoint, control: current)
        }
        path.closeSubpath()

        return path
    }

    // MARK: - Rendering helpers

    private static func makeTiledTexture(named name: String) -> SKTexture? {
        let texture = SKTexture(imageNamed: name)
        texture.filteringMode = .linear
        return texture
    }

    private func buildOrUpdateCroppedLayers(size: CGSize, tint: SKColor, depthFactor: CGFloat) {
        // Rebuild if missing.
        if cropNode == nil {
            guard let lakePath = path else { 
                return
            }
            
            let crop = SKCropNode()

            // Mask: same path as the lake, filled solid.
            let mask = SKShapeNode(path: lakePath)
            mask.fillColor = .white
            mask.strokeColor = .clear
            mask.lineWidth = 0
            crop.maskNode = mask

            // Depth gradient layer (a pre-rendered radial gradient texture works well).
            // You can add an asset named "lake_depth_gradient" (square, radial from light edge to dark center).
            let gradient = SKSpriteNode(texture: SKTexture(imageNamed: "lake_depth_gradient"))
            gradient.size = size
            gradient.position = .zero
            gradient.zPosition = 0
            // Stronger depth contrast
            gradient.alpha = 0.45 + depthFactor * 0.55
            gradient.color = tint
            gradient.colorBlendFactor = 0.85

            // Ripples layer (tileable), lightly tinted.
            let ripplesTex = LakeNode.makeTiledTexture(named: LakeNode.waterRipplesTextureName)
            let ripples = SKSpriteNode(texture: ripplesTex)
            ripples.size = size
            ripples.position = .zero
            ripples.zPosition = 1
            // Deep water is calmer, shallow water shows more surface detail
            ripples.alpha = 0.08 + (1.0 - depthFactor) * 0.25
            ripples.color = tint
            ripples.colorBlendFactor = 0.25

            // Gentle movement to avoid a static look.
            let drift = SKAction.sequence([
                SKAction.moveBy(x: 8, y: 5, duration: 3.8),
                SKAction.moveBy(x: -8, y: -5, duration: 3.8)
            ])
            ripples.run(SKAction.repeatForever(drift))

            crop.addChild(gradient)
            crop.addChild(ripples)

            // Place water surface between player legs and torso
            // Parent (LakeNode) is at -20, so +11 gives absolute -9
            crop.zPosition = 11
            addChild(crop)

            self.cropNode = crop
            self.gradientSprite = gradient
            self.ripplesSprite = ripples
        }

        // Update sizing/tint in case the node is reused/resized.
        gradientSprite?.size = size
        gradientSprite?.position = .zero
        gradientSprite?.color = tint
        gradientSprite?.alpha = 0.45 + depthFactor * 0.55

        ripplesSprite?.size = size
        ripplesSprite?.position = .zero
        ripplesSprite?.color = tint
        ripplesSprite?.alpha = 0.08 + (1.0 - depthFactor) * 0.25

        // Ensure mask follows current path.
        if let mask = cropNode?.maskNode as? SKShapeNode {
            mask.path = path
        }
    }

    private static func computeSeed(from position: CGPoint) -> UInt64 {
        let xSeed = UInt64(abs(Int(position.x * 1000))) & 0xFFFFFFFF
        let ySeed = UInt64(abs(Int(position.y * 1000))) & 0xFFFFFFFF
        return (xSeed << 32) | ySeed
    }
}
