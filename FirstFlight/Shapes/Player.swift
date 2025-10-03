import SpriteKit


class Player: SKNode {
    private let bodyRadius: CGFloat = 20.0

    // Body parts
    private var body: SKShapeNode!
    private var shoulderArmor: SKShapeNode!
    private var head: SKShapeNode!
    private var leftArm: SKShapeNode!
    private var rightArm: SKShapeNode!
    private var leftLeg: SKShapeNode!
    private var rightLeg: SKShapeNode!

    override init() {
        super.init()

        setupBodyParts()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBodyParts()
        setupPhysics()
    }

    private func setupBodyParts() {
        // Body (torso) - main body part with rounded corners
        let bodySize = CGSize(width: 24, height: 32)
        let bodyPath = CGPath(
            roundedRect: CGRect(x: -bodySize.width / 2, y: -bodySize.height / 2, width: bodySize.width, height: bodySize.height),
            cornerWidth: 6,
            cornerHeight: 6,
            transform: nil
        )
        body = SKShapeNode(path: bodyPath)
        body.fillColor = .lightGray
        body.strokeColor = .clear
        body.position = CGPoint(x: 0, y: 0)
        body.zPosition = 1
        addChild(body)

        // Shoulder armor - half circle arc on shoulders
        let shoulderPath = CGMutablePath()
        let shoulderRadius: CGFloat = 14
        let shoulderCenter = CGPoint(x: 0, y: 10) // Top of body

        // Create arc from left to right (semicircle on top)
        shoulderPath.addArc(
            center: shoulderCenter,
            radius: shoulderRadius,
            startAngle: .pi, // Left (180 degrees)
            endAngle: 0,     // Right (0 degrees)
            clockwise: false
        )

        shoulderArmor = SKShapeNode(path: shoulderPath)
        shoulderArmor.strokeColor = .systemGray
        shoulderArmor.lineWidth = 6
        shoulderArmor.lineCap = .round // Rounded ends
        shoulderArmor.position = CGPoint(x: 0, y: 0)
        shoulderArmor.zPosition = 1.5 // Between body and head, above arms
        addChild(shoulderArmor)

        // Head (helmet) - rounded for smooth look
        let headSize = CGSize(width: 20, height: 20)
        let headPath = CGPath(
            roundedRect: CGRect(x: -headSize.width / 2, y: -headSize.height / 2, width: headSize.width, height: headSize.height),
            cornerWidth: 6,
            cornerHeight: 6,
            transform: nil
        )
        head = SKShapeNode(path: headPath)
        head.fillColor = .white
        head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 26) // Above body
        head.zPosition = 2
        addChild(head)

        // Left Arm - rounded corners, anchor at shoulder
        let armSize = CGSize(width: 8, height: 24)
        let leftArmPath = CGPath(
            roundedRect: CGRect(x: -armSize.width / 2, y: -armSize.height * 0.85, width: armSize.width, height: armSize.height),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        leftArm = SKShapeNode(path: leftArmPath)
        leftArm.fillColor = .white
        leftArm.strokeColor = .clear
        leftArm.position = CGPoint(x: -16, y: 8) // Left side of body
        leftArm.zPosition = 0 // Behind body
        addChild(leftArm)

        // Right Arm - rounded corners, anchor at shoulder
        let rightArmPath = CGPath(
            roundedRect: CGRect(x: -armSize.width / 2, y: -armSize.height * 0.85, width: armSize.width, height: armSize.height),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        rightArm = SKShapeNode(path: rightArmPath)
        rightArm.fillColor = .white
        rightArm.strokeColor = .clear
        rightArm.position = CGPoint(x: 16, y: 8) // Right side of body
        rightArm.zPosition = 0 // Behind body
        addChild(rightArm)

        // Left Leg - rounded corners, anchor at hip
        let legSize = CGSize(width: 10, height: 28)
        let leftLegPath = CGPath(
            roundedRect: CGRect(x: -legSize.width / 2, y: -legSize.height * 0.9, width: legSize.width, height: legSize.height),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        leftLeg = SKShapeNode(path: leftLegPath)
        leftLeg.fillColor = .white
        leftLeg.strokeColor = .clear
        leftLeg.position = CGPoint(x: -8, y: -16) // Left side, below body
        leftLeg.zPosition = 0
        addChild(leftLeg)

        // Right Leg - rounded corners, anchor at hip
        let rightLegPath = CGPath(
            roundedRect: CGRect(x: -legSize.width / 2, y: -legSize.height * 0.9, width: legSize.width, height: legSize.height),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        rightLeg = SKShapeNode(path: rightLegPath)
        rightLeg.fillColor = .white
        rightLeg.strokeColor = .clear
        rightLeg.position = CGPoint(x: 8, y: -16) // Right side, below body
        rightLeg.zPosition = 0
        addChild(rightLeg)
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.rock
        physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.rock
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.1
    }

    func moveTo(position: CGPoint) {
        // Stop any current movement
        removeAction(forKey: "move")

        // Reset velocity to prevent inertia
        physicsBody?.velocity = .zero

        // Calculate distance and duration for consistent speed
        let distance = hypot(position.x - self.position.x, position.y - self.position.y)
        let speed: CGFloat = 150.0 // points per second
        let duration = TimeInterval(distance / speed)

        // Move directly to position with no overshoot
        let moveAction = SKAction.move(to: position, duration: duration)
        moveAction.timingMode = .linear

        // Stop animation when movement completes
        let stopAnimation = SKAction.run { [weak self] in
            self?.stopWalkingAnimation()
        }

        let sequence = SKAction.sequence([moveAction, stopAnimation])
        run(sequence, withKey: "move")

        // Start walking animation
        startWalkingAnimation()
    }

    func stopMovement() {
        removeAction(forKey: "move")
        physicsBody?.velocity = .zero

        // Stop walking animation
        stopWalkingAnimation()
    }

    // MARK: - Animation

    private func startWalkingAnimation() {
        // Walking cycle duration
        let swingDuration: TimeInterval = 0.3

        // Leg swing angles (in radians)
        let legSwingAngle: CGFloat = .pi / 6 // 30 degrees

        // Left leg swings forward first
        let leftLegSwing = SKAction.sequence([
            SKAction.rotate(toAngle: legSwingAngle, duration: swingDuration),
            SKAction.rotate(toAngle: -legSwingAngle, duration: swingDuration * 2),
            SKAction.rotate(toAngle: 0, duration: swingDuration)
        ])

        // Right leg swings backward first (opposite of left)
        let rightLegSwing = SKAction.sequence([
            SKAction.rotate(toAngle: -legSwingAngle, duration: swingDuration),
            SKAction.rotate(toAngle: legSwingAngle, duration: swingDuration * 2),
            SKAction.rotate(toAngle: 0, duration: swingDuration)
        ])

        // Arms swing opposite to legs (smaller angle)
        let armSwingAngle: CGFloat = .pi / 8 // 22.5 degrees

        // Left arm swings opposite to left leg
        let leftArmSwing = SKAction.sequence([
            SKAction.rotate(toAngle: -armSwingAngle, duration: swingDuration),
            SKAction.rotate(toAngle: armSwingAngle, duration: swingDuration * 2),
            SKAction.rotate(toAngle: 0, duration: swingDuration)
        ])

        // Right arm swings opposite to right leg
        let rightArmSwing = SKAction.sequence([
            SKAction.rotate(toAngle: armSwingAngle, duration: swingDuration),
            SKAction.rotate(toAngle: -armSwingAngle, duration: swingDuration * 2),
            SKAction.rotate(toAngle: 0, duration: swingDuration)
        ])

        // Run animations on limbs
        leftLeg.run(SKAction.repeatForever(leftLegSwing), withKey: "walk")
        rightLeg.run(SKAction.repeatForever(rightLegSwing), withKey: "walk")
        leftArm.run(SKAction.repeatForever(leftArmSwing), withKey: "walk")
        rightArm.run(SKAction.repeatForever(rightArmSwing), withKey: "walk")
    }

    private func stopWalkingAnimation() {
        // Remove walking animations
        leftLeg.removeAction(forKey: "walk")
        rightLeg.removeAction(forKey: "walk")
        leftArm.removeAction(forKey: "walk")
        rightArm.removeAction(forKey: "walk")

        // Reset limbs to neutral position
        leftLeg.run(SKAction.rotate(toAngle: 0, duration: 0.2))
        rightLeg.run(SKAction.rotate(toAngle: 0, duration: 0.2))
        leftArm.run(SKAction.rotate(toAngle: 0, duration: 0.2))
        rightArm.run(SKAction.rotate(toAngle: 0, duration: 0.2))
    }
}
