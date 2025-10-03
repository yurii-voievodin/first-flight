import SpriteKit


class Player: SKNode {
    private let bodyRadius: CGFloat = 20.0

    // Body parts
    private var body: SKShapeNode!
    private var shoulderArmor: SKShapeNode!
    private var head: SKShapeNode!

    // Arms (multi-segment)
    private var leftUpperArm: SKShapeNode!
    private var leftElbow: SKShapeNode!
    private var leftForearm: SKShapeNode!
    private var rightUpperArm: SKShapeNode!
    private var rightElbow: SKShapeNode!
    private var rightForearm: SKShapeNode!

    // Legs (multi-segment)
    private var leftThigh: SKShapeNode!
    private var leftKnee: SKShapeNode!
    private var leftCalf: SKShapeNode!
    private var rightThigh: SKShapeNode!
    private var rightKnee: SKShapeNode!
    private var rightCalf: SKShapeNode!

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

        // Left Upper Arm - anchor at shoulder
        let upperArmSize = CGSize(width: 8, height: 14)
        let leftUpperArmPath = CGPath(
            roundedRect: CGRect(x: -upperArmSize.width / 2, y: -upperArmSize.height * 0.85, width: upperArmSize.width, height: upperArmSize.height),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        leftUpperArm = SKShapeNode(path: leftUpperArmPath)
        leftUpperArm.fillColor = .white
        leftUpperArm.strokeColor = .clear
        leftUpperArm.position = CGPoint(x: -16, y: 8) // Left shoulder
        leftUpperArm.zPosition = 0
        addChild(leftUpperArm)

        // Left Elbow - joint circle (child of upper arm)
        leftElbow = SKShapeNode(circleOfRadius: 3)
        leftElbow.fillColor = .systemGray
        leftElbow.strokeColor = .clear
        leftElbow.position = CGPoint(x: 0, y: -12) // Bottom of upper arm
        leftElbow.zPosition = 0.5
        leftUpperArm.addChild(leftElbow)

        // Left Forearm - child of upper arm, positioned at elbow
        let forearmSize = CGSize(width: 7, height: 12)
        let leftForearmPath = CGPath(
            roundedRect: CGRect(x: -forearmSize.width / 2, y: -forearmSize.height * 0.85, width: forearmSize.width, height: forearmSize.height),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        leftForearm = SKShapeNode(path: leftForearmPath)
        leftForearm.fillColor = .white
        leftForearm.strokeColor = .clear
        leftForearm.position = CGPoint(x: 0, y: -12) // At elbow joint
        leftForearm.zPosition = 0
        leftUpperArm.addChild(leftForearm)

        // Right Upper Arm - anchor at shoulder
        let rightUpperArmPath = CGPath(
            roundedRect: CGRect(x: -upperArmSize.width / 2, y: -upperArmSize.height * 0.85, width: upperArmSize.width, height: upperArmSize.height),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        rightUpperArm = SKShapeNode(path: rightUpperArmPath)
        rightUpperArm.fillColor = .white
        rightUpperArm.strokeColor = .clear
        rightUpperArm.position = CGPoint(x: 16, y: 8) // Right shoulder
        rightUpperArm.zPosition = 0
        addChild(rightUpperArm)

        // Right Elbow - joint circle (child of upper arm)
        rightElbow = SKShapeNode(circleOfRadius: 3)
        rightElbow.fillColor = .systemGray
        rightElbow.strokeColor = .clear
        rightElbow.position = CGPoint(x: 0, y: -12) // Bottom of upper arm
        rightElbow.zPosition = 0.5
        rightUpperArm.addChild(rightElbow)

        // Right Forearm - child of upper arm, positioned at elbow
        let rightForearmPath = CGPath(
            roundedRect: CGRect(x: -forearmSize.width / 2, y: -forearmSize.height * 0.85, width: forearmSize.width, height: forearmSize.height),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        rightForearm = SKShapeNode(path: rightForearmPath)
        rightForearm.fillColor = .white
        rightForearm.strokeColor = .clear
        rightForearm.position = CGPoint(x: 0, y: -12) // At elbow joint
        rightForearm.zPosition = 0
        rightUpperArm.addChild(rightForearm)

        // Left Thigh - anchor at hip
        let thighSize = CGSize(width: 10, height: 16)
        let leftThighPath = CGPath(
            roundedRect: CGRect(x: -thighSize.width / 2, y: -thighSize.height * 0.9, width: thighSize.width, height: thighSize.height),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        leftThigh = SKShapeNode(path: leftThighPath)
        leftThigh.fillColor = .white
        leftThigh.strokeColor = .clear
        leftThigh.position = CGPoint(x: -8, y: -16) // Left hip
        leftThigh.zPosition = 0
        addChild(leftThigh)

        // Left Knee - joint circle (child of thigh)
        leftKnee = SKShapeNode(circleOfRadius: 4)
        leftKnee.fillColor = .systemGray
        leftKnee.strokeColor = .clear
        leftKnee.position = CGPoint(x: 0, y: -14) // Bottom of thigh
        leftKnee.zPosition = 0.5
        leftThigh.addChild(leftKnee)

        // Left Calf - child of thigh, positioned at knee
        let calfSize = CGSize(width: 9, height: 14)
        let leftCalfPath = CGPath(
            roundedRect: CGRect(x: -calfSize.width / 2, y: -calfSize.height * 0.9, width: calfSize.width, height: calfSize.height),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        leftCalf = SKShapeNode(path: leftCalfPath)
        leftCalf.fillColor = .white
        leftCalf.strokeColor = .clear
        leftCalf.position = CGPoint(x: 0, y: -14) // At knee joint
        leftCalf.zPosition = 0
        leftThigh.addChild(leftCalf)

        // Right Thigh - anchor at hip
        let rightThighPath = CGPath(
            roundedRect: CGRect(x: -thighSize.width / 2, y: -thighSize.height * 0.9, width: thighSize.width, height: thighSize.height),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        rightThigh = SKShapeNode(path: rightThighPath)
        rightThigh.fillColor = .white
        rightThigh.strokeColor = .clear
        rightThigh.position = CGPoint(x: 8, y: -16) // Right hip
        rightThigh.zPosition = 0
        addChild(rightThigh)

        // Right Knee - joint circle (child of thigh)
        rightKnee = SKShapeNode(circleOfRadius: 4)
        rightKnee.fillColor = .systemGray
        rightKnee.strokeColor = .clear
        rightKnee.position = CGPoint(x: 0, y: -14) // Bottom of thigh
        rightKnee.zPosition = 0.5
        rightThigh.addChild(rightKnee)

        // Right Calf - child of thigh, positioned at knee
        let rightCalfPath = CGPath(
            roundedRect: CGRect(x: -calfSize.width / 2, y: -calfSize.height * 0.9, width: calfSize.width, height: calfSize.height),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        rightCalf = SKShapeNode(path: rightCalfPath)
        rightCalf.fillColor = .white
        rightCalf.strokeColor = .clear
        rightCalf.position = CGPoint(x: 0, y: -14) // At knee joint
        rightCalf.zPosition = 0
        rightThigh.addChild(rightCalf)
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
        // Step duration for each limb movement
        let stepDuration: TimeInterval = 0.25

        // Movement angles
        let thighSwingAngle: CGFloat = .pi / 5 // 36 degrees
        let kneeBendAngle: CGFloat = .pi / 6 // 30 degrees
        let upperArmSwingAngle: CGFloat = .pi / 6 // 30 degrees
        let elbowBendAngle: CGFloat = .pi / 7 // 25 degrees

        // === RIGHT LEG (Phase 1: steps first) ===
        // Thigh swings the whole leg
        let rightThighCycle = SKAction.sequence([
            SKAction.rotate(toAngle: thighSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration),
            SKAction.rotate(toAngle: -thighSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration)
        ])

        // Calf bends at knee (relative to thigh)
        let rightCalfCycle = SKAction.sequence([
            SKAction.rotate(toAngle: -kneeBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
        ])

        // === LEFT ARM (Phase 1: swings with right leg) ===
        let leftUpperArmCycle = SKAction.sequence([
            SKAction.rotate(toAngle: upperArmSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration),
            SKAction.rotate(toAngle: -upperArmSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration)
        ])

        let leftForearmCycle = SKAction.sequence([
            SKAction.rotate(toAngle: -elbowBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -elbowBendAngle * 0.5, duration: stepDuration),
            SKAction.rotate(toAngle: -elbowBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -elbowBendAngle * 0.5, duration: stepDuration)
        ])

        // === LEFT LEG (Phase 3: steps after right leg) ===
        let leftThighCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.rotate(toAngle: thighSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration),
            SKAction.rotate(toAngle: -thighSwingAngle, duration: stepDuration * 0) // Instant reset
        ])

        let leftCalfCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.rotate(toAngle: -kneeBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration)
        ])

        // === RIGHT ARM (Phase 3: swings with left leg) ===
        let rightUpperArmCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.rotate(toAngle: upperArmSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration),
            SKAction.rotate(toAngle: -upperArmSwingAngle, duration: stepDuration * 0) // Instant reset
        ])

        let rightForearmCycle = SKAction.sequence([
            SKAction.rotate(toAngle: -elbowBendAngle * 0.5, duration: stepDuration * 2),
            SKAction.rotate(toAngle: -elbowBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -elbowBendAngle * 0.5, duration: stepDuration)
        ])

        // Run all animations on individual limb segments
        rightThigh.run(SKAction.repeatForever(rightThighCycle), withKey: "walk")
        rightCalf.run(SKAction.repeatForever(rightCalfCycle), withKey: "walk")
        leftUpperArm.run(SKAction.repeatForever(leftUpperArmCycle), withKey: "walk")
        leftForearm.run(SKAction.repeatForever(leftForearmCycle), withKey: "walk")
        leftThigh.run(SKAction.repeatForever(leftThighCycle), withKey: "walk")
        leftCalf.run(SKAction.repeatForever(leftCalfCycle), withKey: "walk")
        rightUpperArm.run(SKAction.repeatForever(rightUpperArmCycle), withKey: "walk")
        rightForearm.run(SKAction.repeatForever(rightForearmCycle), withKey: "walk")
    }

    private func stopWalkingAnimation() {
        // Stop all limb animations
        leftThigh.removeAction(forKey: "walk")
        leftCalf.removeAction(forKey: "walk")
        rightThigh.removeAction(forKey: "walk")
        rightCalf.removeAction(forKey: "walk")
        leftUpperArm.removeAction(forKey: "walk")
        leftForearm.removeAction(forKey: "walk")
        rightUpperArm.removeAction(forKey: "walk")
        rightForearm.removeAction(forKey: "walk")

        // Reset all segments to neutral position
        let resetDuration: TimeInterval = 0.2
        leftThigh.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        leftCalf.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightThigh.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightCalf.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        leftUpperArm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        leftForearm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightUpperArm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightForearm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
    }
}
