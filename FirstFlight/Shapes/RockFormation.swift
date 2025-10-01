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

    // Debug information
    var debugInfo: [String: String] = [:]

    init(type: RockFormationType, size: CGSize, position: CGPoint) {
        self.formationType = type
        super.init()

        self.position = position
        createRockShape(size: size)
        setupPhysics()
        setupVisuals()
    }

    required init?(coder aDecoder: NSCoder) {
        self.formationType = .boulder
        super.init(coder: aDecoder)
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

        // Create multiple connected boulders
        let boulder1Size = CGSize(width: size.width * 0.6, height: size.height * 0.6)
        let boulder1Path = createBoulderPath(size: boulder1Size)
        path.addPath(boulder1Path)

        // Second boulder, offset and smaller
        let boulder2Size = CGSize(width: size.width * 0.4, height: size.height * 0.5)
        var boulder2Path = createBoulderPath(size: boulder2Size)
        var transform = CGAffineTransform(translationX: size.width * 0.5, y: size.height * 0.3)
        boulder2Path = boulder2Path.copy(using: &transform)!
        path.addPath(boulder2Path)

        // Third boulder, smaller and offset
        let boulder3Size = CGSize(width: size.width * 0.3, height: size.height * 0.4)
        var boulder3Path = createBoulderPath(size: boulder3Size)
        transform = CGAffineTransform(translationX: size.width * 0.1, y: size.height * 0.5)
        boulder3Path = boulder3Path.copy(using: &transform)!
        path.addPath(boulder3Path)

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
        physicsBody?.contactTestBitMask = PhysicsCategory.player
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
        for (key, value) in debugInfo.sorted(by: { $0.key < $1.key }) {
            if !labelText.isEmpty {
                labelText += ", "
            }
            labelText += "\(key): \(value)"
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
