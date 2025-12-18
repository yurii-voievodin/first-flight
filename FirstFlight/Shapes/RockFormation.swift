import SpriteKit

enum RockFormationType {
    case boulder
    case cave
    case overhang
    case cluster
    case spire
}

class RockFormation: SKShapeNode {
    private let formationType: RockFormationType
    private let rockColor: SKColor = .systemBrown
    private var debugLabel: SKLabelNode?
    private var circleIndicator: SKShapeNode?

    // Circle indicator visibility
    var isCircleIndicatorVisible: Bool = false {
        didSet {
            circleIndicator?.isHidden = !isCircleIndicatorVisible
        }
    }

    // Strength system
    private let rockSize: CGSize
    let maxStrength: CGFloat
    private(set) var currentStrength: CGFloat

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

    init(type: RockFormationType, size: CGSize, position: CGPoint) {
        self.formationType = type
        self.rockSize = size
        self.maxStrength = (size.width + size.height) / 2
        self.currentStrength = (size.width + size.height) / 2
        super.init()

        self.position = position
        createRockShape(size: size)
        setupPhysics()
        setupVisuals()
        setupCircleIndicator()
    }

    required init?(coder aDecoder: NSCoder) {
        self.formationType = .boulder
        self.rockSize = CGSize(width: 100, height: 100)
        self.maxStrength = 100
        self.currentStrength = 100
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

        // Create L-shaped overhang
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: size.width * 0.7, y: 0))
        path.addCurve(to: CGPoint(x: size.width, y: size.height * 0.3),
                     control1: CGPoint(x: size.width * 0.9, y: size.height * 0.1),
                     control2: CGPoint(x: size.width, y: size.height * 0.2))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: size.width * 0.4, y: size.height))
        path.addCurve(to: CGPoint(x: size.width * 0.3, y: size.height * 0.6),
                     control1: CGPoint(x: size.width * 0.35, y: size.height * 0.8),
                     control2: CGPoint(x: size.width * 0.3, y: size.height * 0.7))
        path.addCurve(to: CGPoint(x: 0, y: size.height * 0.4),
                     control1: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                     control2: CGPoint(x: size.width * 0.1, y: size.height * 0.4))
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

        // Create tall, narrow spire
        path.move(to: CGPoint(x: centerX * 0.8, y: 0))
        path.addCurve(to: CGPoint(x: centerX * 0.4, y: size.height * 0.9),
                     control1: CGPoint(x: centerX * 0.2, y: size.height * 0.3),
                     control2: CGPoint(x: centerX * 0.1, y: size.height * 0.7))
        path.addCurve(to: CGPoint(x: centerX * 1.2, y: size.height * 0.8),
                     control1: CGPoint(x: centerX * 0.7, y: size.height * 0.95),
                     control2: CGPoint(x: centerX * 1.0, y: size.height * 0.9))
        path.addCurve(to: CGPoint(x: centerX * 1.6, y: size.height * 0.2),
                     control1: CGPoint(x: centerX * 1.4, y: size.height * 0.6),
                     control2: CGPoint(x: centerX * 1.8, y: size.height * 0.4))
        path.addCurve(to: CGPoint(x: centerX * 0.8, y: 0),
                     control1: CGPoint(x: centerX * 1.3, y: size.height * 0.1),
                     control2: CGPoint(x: centerX * 1.1, y: -size.height * 0.1))
        path.closeSubpath()

        return path
    }

    private func setupPhysics() {
        guard let path = self.path else { return }

        // Create physics body from the shape path
        physicsBody = SKPhysicsBody(polygonFrom: path)
        physicsBody?.categoryBitMask = PhysicsCategory.rock
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.blasterBeam
        physicsBody?.collisionBitMask = PhysicsCategory.player
        physicsBody?.isDynamic = false
        physicsBody?.friction = 0.8
        physicsBody?.restitution = 0.1
    }

    private func setupVisuals() {
        fillColor = rockColor
        strokeColor = .brown
        lineWidth = 2.0

        // Add some texture variation
        switch formationType {
        case .boulder:
            fillColor = .systemBrown
        case .cave:
            fillColor = .brown
        case .overhang:
            fillColor = .systemGray
        case .cluster:
            fillColor = .systemBrown
        case .spire:
            fillColor = .systemGray2
        }
    }

    private func setupCircleIndicator() {
        let circle = SKShapeNode(circleOfRadius: maxRadius)
        circle.lineWidth = 2
        circle.strokeColor = UIColor.white.withAlphaComponent(0.2)
        circle.fillColor = .clear
        circle.isHidden = true
        circle.zPosition = self.zPosition - 1

        // Center on rock's bounding box
        if let path = self.path {
            let bounds = path.boundingBox
            circle.position = CGPoint(x: bounds.midX, y: bounds.midY)
        }

        addChild(circle)
        circleIndicator = circle
    }

    // Special handling for cave formations
    func createCavePhysics() -> [SKPhysicsBody] {
        guard formationType == .cave else { return [] }

        // For caves, we need to create separate physics bodies for the rock walls
        // leaving the cave opening as a passable area
        var bodies: [SKPhysicsBody] = []

        // This would create multiple physics bodies around the cave opening
        // For now, we'll use the default single body but this could be expanded
        if let mainBody = physicsBody {
            bodies.append(mainBody)
        }

        return bodies
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

    func removeDebugLabel() {
        debugLabel?.parent?.removeFromParent()
        debugLabel = nil
    }
}
