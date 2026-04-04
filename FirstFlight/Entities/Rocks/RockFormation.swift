import SpriteKit

enum RockFormationType: String {
    case boulder
    case cave
    case overhang
    case cluster
    case spire
    case hydrogenDeposit
}

/// Uses identity-based Hashable (inherited from NSObject) — relied upon by
/// Set<RockFormation> and Dictionary<RockFormation, ...> in GameScene.
/// Do not override hash(into:) or == without updating those collections.
class RockFormation: SKShapeNode {
    /// Extra collision padding so the player can't get too close (helps avoid head/rock z-overlap issues)
    private static let collisionPadding: CGFloat = 8
    private let formationType: RockFormationType
    private var debugLabel: SKLabelNode?
    
    var type: RockFormationType { formationType }
    
    // Strength system
    let rockSize: CGSize
    let maxStrength: CGFloat
    private(set) var currentStrength: CGFloat
    
    // Resource composition (only Tier 1 / base elements; rare elements come from crystals)
    let composition: [ElementType: Float]

    // Element extraction tracking
    /// Total elements this rock can yield (based on size)
    let totalYield: Int
    /// Elements already extracted during mining
    private(set) var extractedTotal: Int = 0

    // Debug information
    var debugInfo: [String: String] = [:]
    
    // MARK: - Computed Geometry Properties
    
    /// Maximum radius (half of the larger dimension) - useful for targeting
    var maxRadius: CGFloat {
        max(rockSize.width, rockSize.height) / 2
    }
    
    /// Visual center point of the rock in parent coordinates
    var centerPosition: CGPoint {
        guard let path = self.path else { return position }
        let bounds = path.boundingBox
        return CGPoint(x: position.x + bounds.midX, y: position.y + bounds.midY)
    }
    
    init(type: RockFormationType, size: CGSize, position: CGPoint, seed: UInt64) {
        self.formationType = type
        self.rockSize = size
        self.maxStrength = (size.width + size.height) / 2
        self.currentStrength = (size.width + size.height) / 2
        self.composition = Self.generateBaseComposition(for: type, size: size, seed: seed)
        // Total yield scales with rock size (roughly 1 element per 2 HP)
        self.totalYield = Int((size.width + size.height) / 8)
        super.init()
        
        self.position = position
        createRockShape(size: size)
        setupPhysics()
        setupVisuals()
        
         debugInfo["comp"] = Self.formatComposition(self.composition)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.formationType = .boulder
        self.rockSize = CGSize(width: 100, height: 100)
        self.maxStrength = 100
        self.currentStrength = 100
        self.composition = [
            .iron: 0.45,
            .silicon: 0.25,
            .carbon: 0.10,
            .aluminum: 0.10,
            .copper: 0.10
        ]
        self.totalYield = 50
        super.init(coder: aDecoder)
    }
    
    // MARK: - Damage System
    
    /// Apply damage to the rock
    /// - Parameter amount: The amount of damage to apply
    /// - Returns: True if the rock is destroyed (strength <= 0)
    func applyDamage(_ amount: CGFloat) -> Bool {
        currentStrength -= amount
        return currentStrength <= 0
    }

    // MARK: - Element Extraction

    /// How many elements remain to be extracted
    var remainingYield: Int {
        max(0, totalYield - extractedTotal)
    }

    /// Extract a random element based on composition weights
    /// - Returns: The element type extracted, or nil if rock is depleted
    func extractRandomElement() -> ElementType? {
        guard remainingYield > 0, !composition.isEmpty else { return nil }

        // Weighted random selection
        let totalWeight = composition.values.reduce(0, +)
        guard totalWeight > 0 else { return nil }

        let roll = Float.random(in: 0..<totalWeight)
        var cumulative: Float = 0

        for (element, weight) in composition {
            cumulative += weight
            if roll < cumulative {
                extractedTotal += 1
                return element
            }
        }

        // Fallback to first element
        extractedTotal += 1
        return composition.keys.first
    }

    /// Extract all remaining elements at once
    /// - Returns: Dictionary of elements and their amounts
    func extractAllRemaining() -> [ElementType: Int] {
        var result: [ElementType: Int] = [:]
        let remaining = remainingYield

        guard remaining > 0, !composition.isEmpty else { return result }

        let totalWeight = composition.values.reduce(0, +)
        guard totalWeight > 0 else { return result }

        // Distribute remaining elements according to normalized composition weights
        var distributed = 0
        for (element, weight) in composition {
            let amount = Int(Float(remaining) * (weight / totalWeight))
            if amount > 0 {
                result[element] = amount
                distributed += amount
            }
        }

        // Assign any rounding remainder to the first element
        let remainder = remaining - distributed
        if remainder > 0, let firstElement = composition.keys.first {
            result[firstElement, default: 0] += remainder
        }

        extractedTotal = totalYield
        return result
    }
    
    private func createRockShape(size: CGSize) {
        let path = CGMutablePath()
        
        switch formationType {
        case .boulder:
            path.addPath(createBoulderPath(size: size))
        case .cave:
            path.addPath(createCavePath(size: size))
        case .overhang:
            path.addPath(createOverhangPath(size: size))
        case .cluster:
            path.addPath(createClusterPath(size: size))
        case .spire:
            path.addPath(createSpirePath(size: size))
        case .hydrogenDeposit:
            path.addPath(createHydrogenDepositPath(size: size))
        }
        
        self.path = path
    }
    
    private func createBoulderPath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Create an irregular boulder using bezier curves
        path.move(to: CGPoint(x: centerX * 0.3, y: 0))
        path.addCurve(to: CGPoint(x: size.width * 0.9, y: centerY * 0.4),
                      control1: CGPoint(x: size.width * 0.7, y: -centerY * 0.2),
                      control2: CGPoint(x: size.width * 1.1, y: centerY * 0.1))
        path.addCurve(to: CGPoint(x: size.width * 0.8, y: size.height * 0.9),
                      control1: CGPoint(x: size.width * 1.0, y: centerY * 0.7),
                      control2: CGPoint(x: size.width * 0.9, y: size.height * 0.7))
        path.addCurve(to: CGPoint(x: centerX * 0.2, y: size.height * 0.8),
                      control1: CGPoint(x: centerX * 0.6, y: size.height * 1.1),
                      control2: CGPoint(x: centerX * 0.3, y: size.height * 0.9))
        path.addCurve(to: CGPoint(x: centerX * 0.3, y: 0),
                      control1: CGPoint(x: -centerX * 0.1, y: centerY * 0.6),
                      control2: CGPoint(x: centerX * 0.1, y: centerY * 0.2))
        path.closeSubpath()
        
        return path
    }
    
    private func createCavePath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        
        // Create outer rock formation
        let outerPath = createBoulderPath(size: size)
        path.addPath(outerPath)
        
        // Create cave opening (hole in the middle)
        let caveSize = CGSize(width: size.width * 0.4, height: size.height * 0.3)
        let caveX = (size.width - caveSize.width) / 2
        let caveY = (size.height - caveSize.height) / 2
        
        let cavePath = CGMutablePath()
        cavePath.addEllipse(in: CGRect(x: caveX, y: caveY, width: caveSize.width, height: caveSize.height))
        
        // Subtract the cave from the rock (create hole)
        // Note: We'll handle the physics separately to create a proper cave
        return outerPath
    }
    
    private func createOverhangPath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        
        // More organic overhang: rounded corners + subtle bulges (avoid straight edges)
        let w = size.width
        let h = size.height
        
        // Start near bottom-left, slightly inset
        path.move(to: CGPoint(x: w * 0.06, y: h * 0.08))
        
        // Bottom edge with a gentle bulge
        path.addCurve(
            to: CGPoint(x: w * 0.70, y: h * 0.06),
            control1: CGPoint(x: w * 0.22, y: h * 0.00),
            control2: CGPoint(x: w * 0.48, y: h * 0.02)
        )
        
        // Bottom-right turn into the "leg" of the overhang (rounded)
        path.addCurve(
            to: CGPoint(x: w * 0.94, y: h * 0.26),
            control1: CGPoint(x: w * 0.84, y: h * 0.08),
            control2: CGPoint(x: w * 0.95, y: h * 0.14)
        )
        
        // Right side up with a slight inward bend (less rectangular)
        path.addCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.92),
            control1: CGPoint(x: w * 0.98, y: h * 0.46),
            control2: CGPoint(x: w * 0.96, y: h * 0.78)
        )
        
        // Top edge drifting left (subtle sag)
        path.addCurve(
            to: CGPoint(x: w * 0.42, y: h * 0.95),
            control1: CGPoint(x: w * 0.82, y: h * 1.02),
            control2: CGPoint(x: w * 0.60, y: h * 1.02)
        )
        
        // Inner notch of the overhang (the "L" cut) with rounded corner
        path.addCurve(
            to: CGPoint(x: w * 0.30, y: h * 0.72),
            control1: CGPoint(x: w * 0.36, y: h * 0.90),
            control2: CGPoint(x: w * 0.30, y: h * 0.83)
        )
        
        // Left inner drop (irregular)
        path.addCurve(
            to: CGPoint(x: w * 0.12, y: h * 0.56),
            control1: CGPoint(x: w * 0.28, y: h * 0.62),
            control2: CGPoint(x: w * 0.20, y: h * 0.58)
        )
        
        // Outer left contour back to start (rounded)
        path.addCurve(
            to: CGPoint(x: w * 0.06, y: h * 0.08),
            control1: CGPoint(x: w * 0.02, y: h * 0.52),
            control2: CGPoint(x: w * 0.00, y: h * 0.22)
        )
        
        path.closeSubpath()
        return path
    }
    
    private func createClusterPath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        
        // Create a single unified cluster shape with 3 interconnected rock formations
        let w = size.width
        let h = size.height
        
        // Start from the left boulder
        path.move(to: CGPoint(x: w * 0.05, y: h * 0.5))
        
        // Left boulder - bottom to top
        path.addCurve(to: CGPoint(x: w * 0.15, y: h * 0.85),
                      control1: CGPoint(x: w * 0.0, y: h * 0.65),
                      control2: CGPoint(x: w * 0.05, y: h * 0.8))
        path.addCurve(to: CGPoint(x: w * 0.35, y: h * 0.95),
                      control1: CGPoint(x: w * 0.2, y: h * 0.92),
                      control2: CGPoint(x: w * 0.27, y: h * 0.95))
        
        // Transition to middle boulder
        path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.88),
                      control1: CGPoint(x: w * 0.4, y: h * 0.93),
                      control2: CGPoint(x: w * 0.45, y: h * 0.9))
        
        // Middle boulder - bottom to top
        path.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.7),
                      control1: CGPoint(x: w * 0.6, y: h * 0.85),
                      control2: CGPoint(x: w * 0.65, y: h * 0.78))
        
        // Transition to right boulder
        path.addCurve(to: CGPoint(x: w * 0.8, y: h * 0.6),
                      control1: CGPoint(x: w * 0.7, y: h * 0.68),
                      control2: CGPoint(x: w * 0.75, y: h * 0.63))
        
        // Right boulder - side to top
        path.addCurve(to: CGPoint(x: w * 0.85, y: h * 0.4),
                      control1: CGPoint(x: w * 0.88, y: h * 0.55),
                      control2: CGPoint(x: w * 0.9, y: h * 0.47))
        path.addCurve(to: CGPoint(x: w * 0.75, y: h * 0.25),
                      control1: CGPoint(x: w * 0.82, y: h * 0.32),
                      control2: CGPoint(x: w * 0.8, y: h * 0.27))
        
        // Top of middle boulder
        path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.2),
                      control1: CGPoint(x: w * 0.68, y: h * 0.22),
                      control2: CGPoint(x: w * 0.58, y: h * 0.2))
        
        // Top of left boulder
        path.addCurve(to: CGPoint(x: w * 0.2, y: h * 0.3),
                      control1: CGPoint(x: w * 0.4, y: h * 0.2),
                      control2: CGPoint(x: w * 0.28, y: h * 0.24))
        
        // Back to start
        path.addCurve(to: CGPoint(x: w * 0.05, y: h * 0.5),
                      control1: CGPoint(x: w * 0.12, y: h * 0.38),
                      control2: CGPoint(x: w * 0.07, y: h * 0.42))
        
        path.closeSubpath()
        
        return path
    }
    
    private func createSpirePath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        let centerX = size.width / 2
        
        // ~20% shorter + ~20% wider (avoid the "arrow" silhouette)
        path.move(to: CGPoint(x: centerX * 0.72, y: 0))
        
        // Left side up to a lower peak
        path.addCurve(
            to: CGPoint(x: centerX * 0.50, y: size.height * 0.62),
            control1: CGPoint(x: centerX * 0.22, y: size.height * 0.24),
            control2: CGPoint(x: centerX * 0.12, y: size.height * 0.50)
        )
        
        // Across the top (rounder cap, lower)
        path.addCurve(
            to: CGPoint(x: centerX * 1.50, y: size.height * 0.58),
            control1: CGPoint(x: centerX * 0.86, y: size.height * 0.76),
            control2: CGPoint(x: centerX * 1.18, y: size.height * 0.74)
        )
        
        // Right side down (wider shoulder)
        path.addCurve(
            to: CGPoint(x: centerX * 1.70, y: size.height * 0.18),
            control1: CGPoint(x: centerX * 1.82, y: size.height * 0.46),
            control2: CGPoint(x: centerX * 1.92, y: size.height * 0.30)
        )
        
        // Close back to base with a softer bottom curvature
        path.addCurve(
            to: CGPoint(x: centerX * 0.72, y: 0),
            control1: CGPoint(x: centerX * 1.34, y: size.height * 0.07),
            control2: CGPoint(x: centerX * 1.06, y: -size.height * 0.05)
        )
        
        path.closeSubpath()
        return path
    }

    private func createHydrogenDepositPath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Organic rounded shape similar to boulder
        path.move(to: CGPoint(x: centerX * 0.35, y: size.height * 0.05))
        path.addCurve(to: CGPoint(x: size.width * 0.85, y: centerY * 0.45),
                      control1: CGPoint(x: size.width * 0.65, y: -centerY * 0.1),
                      control2: CGPoint(x: size.width * 0.95, y: centerY * 0.15))
        path.addCurve(to: CGPoint(x: size.width * 0.78, y: size.height * 0.85),
                      control1: CGPoint(x: size.width * 0.92, y: centerY * 0.75),
                      control2: CGPoint(x: size.width * 0.88, y: size.height * 0.68))
        path.addCurve(to: CGPoint(x: centerX * 0.25, y: size.height * 0.75),
                      control1: CGPoint(x: centerX * 0.65, y: size.height * 1.0),
                      control2: CGPoint(x: centerX * 0.35, y: size.height * 0.88))
        path.addCurve(to: CGPoint(x: centerX * 0.35, y: size.height * 0.05),
                      control1: CGPoint(x: -centerX * 0.05, y: centerY * 0.55),
                      control2: CGPoint(x: centerX * 0.15, y: centerY * 0.15))
        path.closeSubpath()
        return path
    }
    
    private func setupPhysics() {
        guard let path = self.path else { return }
        
        // Inflate the collision shape so the player is kept a bit farther from the visual rock.
        // This is a cheap way to avoid situations where the head gets visually occluded by rocks.
        let bounds = path.boundingBox
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let padding = Self.collisionPadding
        
        // Inflate "like an outline": grow the path by ~padding on each side using bounding-box scaling.
        // This keeps the silhouette similar while adding roughly a constant margin.
        let oldW = max(bounds.width, 0.001)
        let oldH = max(bounds.height, 0.001)
        let newW = oldW + 2 * padding
        let newH = oldH + 2 * padding
        
        let sx = newW / oldW
        let sy = newH / oldH
        
        var t = CGAffineTransform(translationX: center.x, y: center.y)
        t = t.scaledBy(x: sx, y: sy)
        t = t.translatedBy(x: -center.x, y: -center.y)
        
        let inflatedPath = path.copy(using: &t) ?? path
        
        // Create physics body from the (inflated) shape path
        physicsBody = SKPhysicsBody(polygonFrom: inflatedPath)
        physicsBody?.categoryBitMask = PhysicsCategory.rock
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.blasterBeam
        physicsBody?.collisionBitMask = PhysicsCategory.player
        physicsBody?.isDynamic = false
        physicsBody?.friction = 0.8
        physicsBody?.restitution = 0.1
    }
    
    private func setupVisuals() {
        strokeColor = .clear
        lineWidth = 0
    }
    
    // MARK: - Debug Functionality
    
    func addDebugLabel() {
        // Remove existing label if any
        debugLabel?.removeFromParent()
        
        // Create label text from debug info
        var labelText = ""
        for (_, value) in debugInfo.sorted(by: { $0.key < $1.key }) {
            if !labelText.isEmpty {
                labelText += ", "
            }
            labelText += value
        }
        
        guard !labelText.isEmpty else { return }
        
        // Create label node
        let label = SKLabelNode(fontNamed: "Courier")
        label.text = labelText
        label.numberOfLines = 0
        label.fontSize = 12
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        
        // Create background for better visibility
        let background = SKShapeNode(rectOf: CGSize(width: label.frame.width + 8, height: label.frame.height + 4), cornerRadius: 3)
        background.fillColor = .black.withAlphaComponent(0.7)
        background.strokeColor = .white
        background.lineWidth = 1
        background.zPosition = 100
        
        // Position label above the rock (calculate bounds)
        if let path = self.path {
            let boundingBox = path.boundingBox
            background.position = CGPoint(x: boundingBox.midX, y: boundingBox.maxY + 15)
        } else {
            background.position = CGPoint(x: 0, y: 50)
        }
        
        // Add label to background
        label.position = CGPoint.zero
        label.zPosition = 1
        background.addChild(label)
        
        // Add background to this node
        addChild(background)
        debugLabel = label
    }
    
    func applyProceduralTextures(seed: UInt64) {
        // 1) базова текстура через окремий спрайт (щоб не тайлилась)
        addBaseTexture(seed: seed)
        
        // 2) легка “живість” без зламу кольорів
        let roll = CGFloat((seed % 1000)) / 1000.0
        let alphaJitter = 0.92 + roll * 0.08  // 0.92...1.0
        self.alpha = alphaJitter
        
        // 2.5) окрема тінь/блік поверх базової текстури
        addShadowAndHighlight(seed: seed)
    }
    
    private func addBaseTexture(seed: UInt64) {
        guard let path = self.path else { return }
        
        // прибрати попередню базу, якщо є
        childNode(withName: "rock-base")?.removeFromParent()
        
        let tex = RockTextures.shared.baseTexture(for: formationType, seed: seed)
        tex.filteringMode = .linear
        
        let bounds = path.boundingBox
        
        // спрайт розтягнутий під розмір каменя
        let sprite = SKSpriteNode(texture: tex)
        sprite.name = "rock-base-sprite"
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sprite.position = CGPoint(x: bounds.midX, y: bounds.midY)
        sprite.size = bounds.size
        sprite.zPosition = 0
        
        // маска під форму
        let mask = SKShapeNode(path: path)
        mask.fillColor = .white
        mask.strokeColor = .clear
        mask.lineWidth = 0
        
        let crop = SKCropNode()
        crop.name = "rock-base"
        crop.maskNode = mask
        crop.addChild(sprite)
        crop.zPosition = 0
        
        // вимикаємо заливку шейпа, щоб не дублювати
        fillTexture = nil
        fillColor = .clear
        strokeColor = .clear
        
        addChild(crop)
    }
    
    private func addShadowAndHighlight(seed: UInt64) {
        guard let path = self.path else { return }

        // Remove old depth nodes if method is called again
        childNode(withName: "rock-shadow")?.removeFromParent()
        childNode(withName: "rock-highlight")?.removeFromParent()

        addDepthOutline(path: path)
    }

    private func addDepthOutline(path: CGPath) {
        // Dark outline behind texture gives depth and volume
        let outline = SKShapeNode(path: path)
        outline.name = "rock-shadow"
        outline.fillColor = .clear
        outline.strokeColor = SKColor(white: 0.0, alpha: 0.5)
        outline.lineWidth = 3.0
        outline.glowWidth = 2.0
        outline.zPosition = -1
        addChild(outline)
    }
    
    // MARK: - Destruction Effects
    
    /// Spawns rock chips and dust particles for destruction effect
    func spawnDestructionParticles(in scene: SKScene) {
        let debrisTexture = RockTextures.shared.baseTexture(for: .boulder, seed: 42)
        let position = centerPosition
        
        // Chips
        let chipCount = Int.random(in: 14...22)
        for _ in 0..<chipCount {
            let size = CGFloat.random(in: 5...12)
            let chip = SKSpriteNode(texture: debrisTexture, size: CGSize(width: size, height: size))
            chip.color = SKColor(white: CGFloat.random(in: 0.55...0.8), alpha: 1.0)
            chip.colorBlendFactor = 0.35
            
            // Spawn from within the rock radius
            let a = CGFloat.random(in: 0...(2 * .pi))
            let d = CGFloat.random(in: 0...(max(6, maxRadius) * 0.35))
            chip.position = CGPoint(x: position.x + cos(a) * d, y: position.y + sin(a) * d)
            
            chip.zPosition = 60
            scene.addChild(chip)
            
            // Ballistic pop outward + small drop
            let outAngle = CGFloat.random(in: 0...(2 * .pi))
            let outSpeed = CGFloat.random(in: 40...90)
            let dx = cos(outAngle) * outSpeed
            let dy = sin(outAngle) * outSpeed
            
            let drift = SKAction.move(by: CGVector(
                dx: dx * 0.18,
                dy: dy * 0.18 - CGFloat.random(in: 15...35)
            ), duration: 0.30)
            drift.timingMode = .easeOut
            
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: 0.30)
            let fade = SKAction.fadeOut(withDuration: 0.30)
            let shrink = SKAction.scale(to: 0.35, duration: 0.30)
            
            chip.run(.sequence([
                .group([drift, spin, fade, shrink]),
                .removeFromParent()
            ]))
        }
        
        // Dust puff (cheap emitter)
        let dust = SKEmitterNode()
        dust.particleTexture = debrisTexture
        dust.particleBirthRate = 0
        dust.numParticlesToEmit = 65
        dust.particleLifetime = 0.35
        dust.particleLifetimeRange = 0.15
        dust.emissionAngleRange = 2 * .pi
        dust.particleSpeed = 60
        dust.particleSpeedRange = 35
        dust.particleAlpha = 0.35
        dust.particleAlphaRange = 0.15
        dust.particleAlphaSpeed = -0.9
        dust.particleScale = 0.18
        dust.particleScaleRange = 0.10
        dust.particleScaleSpeed = -0.35
        dust.particleColor = SKColor(white: 0.7, alpha: 1.0)
        dust.particleColorBlendFactor = 1.0
        dust.position = position
        dust.zPosition = 55
        scene.addChild(dust)
        dust.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))
        
        // Secondary small puff a moment later to sell the "dissolve"
        let dust2 = SKEmitterNode()
        dust2.particleTexture = debrisTexture
        dust2.particleBirthRate = 0
        dust2.numParticlesToEmit = 35
        dust2.particleLifetime = 0.30
        dust2.particleLifetimeRange = 0.12
        dust2.emissionAngleRange = 2 * .pi
        dust2.particleSpeed = 35
        dust2.particleSpeedRange = 20
        dust2.particleAlpha = 0.22
        dust2.particleAlphaRange = 0.10
        dust2.particleAlphaSpeed = -0.9
        dust2.particleScale = 0.14
        dust2.particleScaleRange = 0.08
        dust2.particleScaleSpeed = -0.30
        dust2.particleColor = SKColor(white: 0.7, alpha: 1.0)
        dust2.particleColorBlendFactor = 1.0
        dust2.position = position
        dust2.zPosition = 56
        
        scene.addChild(dust2)
        dust2.run(.sequence([.wait(forDuration: 0.45), .removeFromParent()]))
    }
    
    /// Performs shake/dissolve destruction animation and removes node
    func performDestructionAnimation(completion: @escaping () -> Void) {
        // Stop physics interactions immediately
        physicsBody = nil
        removeAllActions()
        
        let basePos = position
        
        // Crumble: short shake + slight squash, then fade/rotate/scale down
        let shake = SKAction.customAction(withDuration: 0.18) { node, t in
            let k = 1.0 - (t / 0.18)
            let jx = CGFloat.random(in: -2...2) * k
            let jy = CGFloat.random(in: -2...2) * k
            node.position = CGPoint(x: basePos.x + jx, y: basePos.y + jy)
        }
        
        let squash = SKAction.scaleX(to: 1.08, y: 0.92, duration: 0.10)
        let unsquash = SKAction.scale(to: 1.0, duration: 0.08)
        let preCrumble = SKAction.group([shake, .sequence([squash, unsquash])])
        
        // Dissolve instead of shrinking
        let duration: TimeInterval = 0.35
        let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -0.35...0.35), duration: duration)
        
        let dissolve = SKAction.customAction(withDuration: duration) { node, t in
            guard let shape = node as? SKShapeNode else { return }
            let p = max(0, min(1, t / duration))
            
            // Ease-out fade
            let a = CGFloat(1.0 - p * p)
            shape.alpha = a
            
            // Soften the outline as it dissolves
            if shape.lineWidth > 0 {
                shape.lineWidth = max(0.0, shape.lineWidth * (1.0 - 0.85 * CGFloat(p)))
            }
        }
        
        let resetPosition = SKAction.run { [weak self] in
            self?.position = basePos
        }
        
        let remove = SKAction.removeFromParent()
        let callCompletion = SKAction.run { completion() }
        
        run(.sequence([preCrumble, resetPosition, .group([rotate, dissolve]), remove, callCompletion]))
    }
    
    
    // MARK: - Composition (Base Elements Only)
    
    /// We only embed Tier 1 / base elements in rocks.
    /// Rare elements (Tier 2) should come from separate crystal nodes.
    private static let baseElements: [ElementType] = [
        .iron, .silicon, .aluminum, .carbon, .sulfur,
        .copper, .nickel, .cobalt,
        .oxygen, .nitrogen
    ]
    
    /// Defines what elements are more likely for each rock formation type.
    /// Values are weights; they do not need to sum to 1.
    private static func baseWeights(for type: RockFormationType) -> [(ElementType, Double)] {
        switch type {
        case .boulder:
            // Generic surface rock: iron + silicates dominate.
            return [
                (.iron, 6), (.silicon, 6), (.aluminum, 3), (.carbon, 2), (.sulfur, 2),
                (.copper, 2), (.nickel, 1.5), (.cobalt, 1),
                (.oxygen, 1.2), (.nitrogen, 0.6)
            ]
            
        case .cave:
            // More volatile pockets + darker deposits.
            return [
                (.iron, 4), (.silicon, 4), (.aluminum, 2), (.carbon, 3), (.sulfur, 3),
                (.copper, 1.5), (.nickel, 1.5), (.cobalt, 1.2),
                (.oxygen, 1.6), (.nitrogen, 1.8)
            ]
            
        case .overhang:
            // Wind/erosion exposed: lighter metals a bit more visible.
            return [
                (.iron, 4.5), (.silicon, 5), (.aluminum, 3.5), (.carbon, 2), (.sulfur, 1.8),
                (.copper, 2.2), (.nickel, 1.2), (.cobalt, 0.9),
                (.oxygen, 1.2), (.nitrogen, 0.5)
            ]
            
        case .cluster:
            // Mixed formation: more copper/nickel/cobalt variance.
            return [
                (.iron, 4.5), (.silicon, 4.5), (.aluminum, 2.5), (.carbon, 2.2), (.sulfur, 2.0),
                (.copper, 3.0), (.nickel, 2.2), (.cobalt, 2.0),
                (.oxygen, 1.2), (.nitrogen, 0.6)
            ]
            
        case .spire:
            // Upthrust/mineralized: conductive elements slightly favored.
            return [
                (.iron, 4.0), (.silicon, 4.0), (.aluminum, 2.0), (.carbon, 1.6), (.sulfur, 2.2),
                (.copper, 3.2), (.nickel, 2.6), (.cobalt, 2.2),
                (.oxygen, 1.0), (.nitrogen, 0.5)
            ]
        case .hydrogenDeposit:
            // Exclusive hydrogen source. Composition is enforced elsewhere as 100% hydrogen.
            // We keep this branch for completeness and future expansion.
            return [
                (.hydrogen, 1.0)
            ]
        }
    }
    
    /// Generates a small, varied element composition for this rock.
    /// - Important: Returns only base elements (Tier 1). Total sums to ~1.0.
    private static func generateBaseComposition(for type: RockFormationType, size: CGSize, seed: UInt64) -> [ElementType: Float] {
        // Hydrogen is an exclusive resource: only hydrogenDeposit rocks can yield it.
        if type == .hydrogenDeposit {
            return [.hydrogen: 1.0]
        }
        var rng = SplitMix64(
            seed: seed
            ^ UInt64(bitPattern: Int64(type.hashValue))
            ^ UInt64(size.width.bitPattern)
            ^ (UInt64(size.height.bitPattern) << 1)
        )
        let weights = baseWeights(for: type)
        
        // Choose how many distinct elements this rock will yield (2...5)
        let targetCount = Int(rng.nextInt(in: 2...5))
        
        // Weighted sampling without replacement
        var pool = weights
        var chosen: [(ElementType, Double)] = []
        chosen.reserveCapacity(targetCount)
        
        for _ in 0..<targetCount {
            let totalW = pool.reduce(0.0) { $0 + $1.1 }
            if totalW <= 0 { break }
            let r = rng.nextDouble() * totalW
            var acc = 0.0
            var pickedIndex = 0
            for (i, item) in pool.enumerated() {
                acc += item.1
                if r <= acc {
                    pickedIndex = i
                    break
                }
            }
            chosen.append(pool.remove(at: pickedIndex))
        }
        
        // Assign amounts (skewed so 1-2 main elements dominate)
        // Use a simple "random power" distribution.
        var raw: [ElementType: Double] = [:]
        var sum = 0.0
        for (idx, (el, _)) in chosen.enumerated() {
            let base = 0.3 + rng.nextDouble() * 0.7
            let dominance = idx == 0 ? 1.4 : (idx == 1 ? 1.15 : 0.9)
            let v = pow(base, 1.2) * dominance
            raw[el] = v
            sum += v
        }
        
        // Normalize to 1.0
        guard sum > 0 else { return [.iron: 1.0] }
        var result: [ElementType: Float] = [:]
        for (el, v) in raw {
            result[el] = Float(v / sum)
        }
        
        // Optionally ensure oxygen appears sometimes in rocky types (silicates)
        if type != .cave, result[.silicon] != nil, result[.oxygen] == nil, rng.nextDouble() < 0.35 {
            // Inject a little oxygen by taking from the largest element
            if let maxPair = result.max(by: { $0.value < $1.value }) {
                let take = min(0.12, maxPair.value * 0.35)
                result[maxPair.key] = max(0.0, maxPair.value - take)
                result[.oxygen] = take
            }
        }
        
        // Renormalize after oxygen injection
        let total = result.values.reduce(0, +)
        if total > 0 {
            for k in result.keys {
                result[k] = (result[k] ?? 0) / total
            }
        }
        
        return result
    }
    
    private static func formatComposition(_ composition: [ElementType: Float]) -> String {
        composition
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "\($0.key.symbol) \(Int(($0.value * 100).rounded()))%" }
            .joined(separator: " · ")
    }
    
    /// Small deterministic RNG for stable generation by seed.
    private struct SplitMix64 {
        private var state: UInt64
        init(seed: UInt64) { self.state = seed &+ 0x9E3779B97F4A7C15 }
        
        mutating func nextUInt64() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        
        mutating func nextDouble() -> Double {
            // 53 bits precision
            Double(nextUInt64() >> 11) * (1.0 / 9007199254740992.0)
        }
        
        mutating func nextInt(in range: ClosedRange<Int>) -> Int {
            let span = UInt64(range.upperBound - range.lowerBound + 1)
            let v = nextUInt64() % span
            return range.lowerBound + Int(v)
        }
    }
}
