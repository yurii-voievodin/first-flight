import SpriteKit


class Spider: SKNode {
    private let bodyRadius: CGFloat = 20.0

    // Body parts
    private var abdomen: SKShapeNode!
    private var head: SKShapeNode!

    // Legs (8 legs, each with 2 segments)
    // Front legs (pair 1)
    private var frontLeftUpperLeg: SKShapeNode!
    private var frontLeftJoint: SKShapeNode!
    private var frontLeftLowerLeg: SKShapeNode!
    private var frontRightUpperLeg: SKShapeNode!
    private var frontRightJoint: SKShapeNode!
    private var frontRightLowerLeg: SKShapeNode!

    // Mid-front legs (pair 2)
    private var midFrontLeftUpperLeg: SKShapeNode!
    private var midFrontLeftJoint: SKShapeNode!
    private var midFrontLeftLowerLeg: SKShapeNode!
    private var midFrontRightUpperLeg: SKShapeNode!
    private var midFrontRightJoint: SKShapeNode!
    private var midFrontRightLowerLeg: SKShapeNode!

    // Mid-back legs (pair 3)
    private var midBackLeftUpperLeg: SKShapeNode!
    private var midBackLeftJoint: SKShapeNode!
    private var midBackLeftLowerLeg: SKShapeNode!
    private var midBackRightUpperLeg: SKShapeNode!
    private var midBackRightJoint: SKShapeNode!
    private var midBackRightLowerLeg: SKShapeNode!

    // Back legs (pair 4)
    private var backLeftUpperLeg: SKShapeNode!
    private var backLeftJoint: SKShapeNode!
    private var backLeftLowerLeg: SKShapeNode!
    private var backRightUpperLeg: SKShapeNode!
    private var backRightJoint: SKShapeNode!
    private var backRightLowerLeg: SKShapeNode!

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
        // Abdomen (main body) - oval shape
        let abdomenSize = CGSize(width: 28, height: 36)
        let abdomenPath = CGPath(
            ellipseIn: CGRect(x: -abdomenSize.width / 2, y: -abdomenSize.height / 2, width: abdomenSize.width, height: abdomenSize.height),
            transform: nil
        )
        abdomen = SKShapeNode(path: abdomenPath)
        abdomen.fillColor = .lightGray
        abdomen.strokeColor = .clear
        abdomen.position = CGPoint(x: 0, y: 0)
        abdomen.zPosition = 1
        addChild(abdomen)

        // Head - smaller oval
        let headSize = CGSize(width: 20, height: 20)
        let headPath = CGPath(
            ellipseIn: CGRect(x: -headSize.width / 2, y: -headSize.height / 2, width: headSize.width, height: headSize.height),
            transform: nil
        )
        head = SKShapeNode(path: headPath)
        head.fillColor = .white
        head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 24) // Above abdomen
        head.zPosition = 2
        addChild(head)

        // Leg dimensions
        let upperLegSize = CGSize(width: 5, height: 18)
        let lowerLegSize = CGSize(width: 4, height: 16)

        // FRONT LEGS (Pair 1) - Attached to front of abdomen
        setupLegPair(
            leftUpper: &frontLeftUpperLeg,
            leftJoint: &frontLeftJoint,
            leftLower: &frontLeftLowerLeg,
            rightUpper: &frontRightUpperLeg,
            rightJoint: &frontRightJoint,
            rightLower: &frontRightLowerLeg,
            upperSize: upperLegSize,
            lowerSize: lowerLegSize,
            position: CGPoint(x: 0, y: 12),
            xOffset: 16,
            forwardAngle: .pi / 3 // 60 degrees forward
        )

        // MID-FRONT LEGS (Pair 2)
        setupLegPair(
            leftUpper: &midFrontLeftUpperLeg,
            leftJoint: &midFrontLeftJoint,
            leftLower: &midFrontLeftLowerLeg,
            rightUpper: &midFrontRightUpperLeg,
            rightJoint: &midFrontRightJoint,
            rightLower: &midFrontRightLowerLeg,
            upperSize: upperLegSize,
            lowerSize: lowerLegSize,
            position: CGPoint(x: 0, y: 4),
            xOffset: 18,
            forwardAngle: .pi / 6 // 30 degrees forward
        )

        // MID-BACK LEGS (Pair 3)
        setupLegPair(
            leftUpper: &midBackLeftUpperLeg,
            leftJoint: &midBackLeftJoint,
            leftLower: &midBackLeftLowerLeg,
            rightUpper: &midBackRightUpperLeg,
            rightJoint: &midBackRightJoint,
            rightLower: &midBackRightLowerLeg,
            upperSize: upperLegSize,
            lowerSize: lowerLegSize,
            position: CGPoint(x: 0, y: -4),
            xOffset: 18,
            forwardAngle: -.pi / 6 // 30 degrees backward
        )

        // BACK LEGS (Pair 4) - Attached to back of abdomen
        setupLegPair(
            leftUpper: &backLeftUpperLeg,
            leftJoint: &backLeftJoint,
            leftLower: &backLeftLowerLeg,
            rightUpper: &backRightUpperLeg,
            rightJoint: &backRightJoint,
            rightLower: &backRightLowerLeg,
            upperSize: upperLegSize,
            lowerSize: lowerLegSize,
            position: CGPoint(x: 0, y: -12),
            xOffset: 16,
            forwardAngle: -.pi / 3 // 60 degrees backward
        )
    }

    private func setupLegPair(
        leftUpper: inout SKShapeNode!,
        leftJoint: inout SKShapeNode!,
        leftLower: inout SKShapeNode!,
        rightUpper: inout SKShapeNode!,
        rightJoint: inout SKShapeNode!,
        rightLower: inout SKShapeNode!,
        upperSize: CGSize,
        lowerSize: CGSize,
        position: CGPoint,
        xOffset: CGFloat,
        forwardAngle: CGFloat
    ) {
        // Left leg - draw horizontally extending to the left
        let leftUpperPath = CGPath(
            roundedRect: CGRect(x: -upperSize.height, y: -upperSize.width / 2, width: upperSize.height, height: upperSize.width),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        leftUpper = SKShapeNode(path: leftUpperPath)
        leftUpper.fillColor = .white
        leftUpper.strokeColor = .clear
        leftUpper.position = position
        leftUpper.zRotation = forwardAngle // Forward/backward tilt only
        leftUpper.zPosition = 0
        abdomen.addChild(leftUpper)

        // Left joint
        leftJoint = SKShapeNode(circleOfRadius: 2.5)
        leftJoint.fillColor = .systemGray
        leftJoint.strokeColor = .clear
        leftJoint.position = CGPoint(x: -upperSize.height, y: 0) // End of upper leg
        leftJoint.zPosition = 0.5
        leftUpper.addChild(leftJoint)

        // Left lower leg - also horizontal
        let leftLowerPath = CGPath(
            roundedRect: CGRect(x: -lowerSize.height, y: -lowerSize.width / 2, width: lowerSize.height, height: lowerSize.width),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        leftLower = SKShapeNode(path: leftLowerPath)
        leftLower.fillColor = .white
        leftLower.strokeColor = .clear
        leftLower.position = CGPoint(x: -upperSize.height, y: 0) // At joint
        leftLower.zRotation = -.pi / 6 // Bend downward for spider stance
        leftLower.zPosition = 0
        leftUpper.addChild(leftLower)

        // Right leg - draw horizontally extending to the right
        let rightUpperPath = CGPath(
            roundedRect: CGRect(x: 0, y: -upperSize.width / 2, width: upperSize.height, height: upperSize.width),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        rightUpper = SKShapeNode(path: rightUpperPath)
        rightUpper.fillColor = .white
        rightUpper.strokeColor = .clear
        rightUpper.position = position
        rightUpper.zRotation = -forwardAngle // Forward/backward tilt (mirrored)
        rightUpper.zPosition = 0
        abdomen.addChild(rightUpper)

        // Right joint
        rightJoint = SKShapeNode(circleOfRadius: 2.5)
        rightJoint.fillColor = .systemGray
        rightJoint.strokeColor = .clear
        rightJoint.position = CGPoint(x: upperSize.height, y: 0) // End of upper leg
        rightJoint.zPosition = 0.5
        rightUpper.addChild(rightJoint)

        // Right lower leg - also horizontal
        let rightLowerPath = CGPath(
            roundedRect: CGRect(x: 0, y: -lowerSize.width / 2, width: lowerSize.height, height: lowerSize.width),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        rightLower = SKShapeNode(path: rightLowerPath)
        rightLower.fillColor = .white
        rightLower.strokeColor = .clear
        rightLower.position = CGPoint(x: upperSize.height, y: 0) // At joint
        rightLower.zRotation = .pi / 6 // Bend downward for spider stance
        rightLower.zPosition = 0
        rightUpper.addChild(rightLower)
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
        let speed: CGFloat = 55.0 // points per second
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
        // Spider walking uses alternating tripod gait
        // Left side: legs 1, 3 move together
        // Right side: legs 2, 4 move together

        let stepDuration: TimeInterval = 0.12

        // Leg movement angles
        let upperLegSwing: CGFloat = .pi / 12 // 15 degrees
        let lowerLegBend: CGFloat = .pi / 8 // 22.5 degrees

        // LEFT SIDE LEGS (1 & 3) - Move together
        // Front left (leg 1)
        let frontLeftCycle = SKAction.sequence([
            SKAction.rotate(byAngle: upperLegSwing, duration: stepDuration),
            SKAction.rotate(byAngle: -upperLegSwing * 2, duration: stepDuration),
            SKAction.rotate(byAngle: upperLegSwing, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration)
        ])

        let frontLeftLowerCycle = SKAction.sequence([
            SKAction.rotate(toAngle: -lowerLegBend, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration * 2)
        ])

        // Mid-back left (leg 3)
        let midBackLeftCycle = frontLeftCycle
        let midBackLeftLowerCycle = frontLeftLowerCycle

        // RIGHT SIDE LEGS (2 & 4) - Move together (offset phase)
        // Mid-front right (leg 2)
        let midFrontRightCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.rotate(byAngle: -upperLegSwing, duration: stepDuration),
            SKAction.rotate(byAngle: upperLegSwing * 2, duration: stepDuration),
            SKAction.rotate(byAngle: -upperLegSwing, duration: stepDuration * 0)
        ])

        let midFrontRightLowerCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.rotate(toAngle: -lowerLegBend, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration)
        ])

        // Back right (leg 4)
        let backRightCycle = midFrontRightCycle
        let backRightLowerCycle = midFrontRightLowerCycle

        // MIDDLE LEGS - Subtle movement for stability
        let midFrontLeftCycle = SKAction.sequence([
            SKAction.rotate(byAngle: upperLegSwing * 0.5, duration: stepDuration * 2),
            SKAction.rotate(byAngle: -upperLegSwing * 0.5, duration: stepDuration * 2)
        ])

        let midBackRightCycle = midFrontLeftCycle

        // Run all leg animations
        frontLeftUpperLeg.run(SKAction.repeatForever(frontLeftCycle), withKey: "walk")
        frontLeftLowerLeg.run(SKAction.repeatForever(frontLeftLowerCycle), withKey: "walk")

        midFrontLeftUpperLeg.run(SKAction.repeatForever(midFrontLeftCycle), withKey: "walk")

        midBackLeftUpperLeg.run(SKAction.repeatForever(midBackLeftCycle), withKey: "walk")
        midBackLeftLowerLeg.run(SKAction.repeatForever(midBackLeftLowerCycle), withKey: "walk")

        backLeftUpperLeg.run(SKAction.repeatForever(frontLeftCycle), withKey: "walk")
        backLeftLowerLeg.run(SKAction.repeatForever(frontLeftLowerCycle), withKey: "walk")

        frontRightUpperLeg.run(SKAction.repeatForever(midFrontRightCycle), withKey: "walk")
        frontRightLowerLeg.run(SKAction.repeatForever(midFrontRightLowerCycle), withKey: "walk")

        midFrontRightUpperLeg.run(SKAction.repeatForever(midFrontRightCycle), withKey: "walk")
        midFrontRightLowerLeg.run(SKAction.repeatForever(midFrontRightLowerCycle), withKey: "walk")

        midBackRightUpperLeg.run(SKAction.repeatForever(midBackRightCycle), withKey: "walk")

        backRightUpperLeg.run(SKAction.repeatForever(backRightCycle), withKey: "walk")
        backRightLowerLeg.run(SKAction.repeatForever(backRightLowerCycle), withKey: "walk")
    }

    private func stopWalkingAnimation() {
        // Stop all leg animations
        let allUpperLegs = [
            frontLeftUpperLeg, frontRightUpperLeg,
            midFrontLeftUpperLeg, midFrontRightUpperLeg,
            midBackLeftUpperLeg, midBackRightUpperLeg,
            backLeftUpperLeg, backRightUpperLeg
        ]

        let allLowerLegs = [
            frontLeftLowerLeg, frontRightLowerLeg,
            midFrontLeftLowerLeg, midFrontRightLowerLeg,
            midBackLeftLowerLeg, midBackRightLowerLeg,
            backLeftLowerLeg, backRightLowerLeg
        ]

        for leg in allUpperLegs {
            leg?.removeAction(forKey: "walk")
        }

        for leg in allLowerLegs {
            leg?.removeAction(forKey: "walk")
        }

        // Reset upper legs to neutral position (0 relative rotation)
        let resetDuration: TimeInterval = 0.2
        for leg in allUpperLegs {
            leg?.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        }

        // Reset lower legs to bent neutral position (downward bend)
        let kneeBend: CGFloat = .pi / 6
        frontLeftLowerLeg?.run(SKAction.rotate(toAngle: -kneeBend, duration: resetDuration))
        frontRightLowerLeg?.run(SKAction.rotate(toAngle: kneeBend, duration: resetDuration))
        midFrontLeftLowerLeg?.run(SKAction.rotate(toAngle: -kneeBend, duration: resetDuration))
        midFrontRightLowerLeg?.run(SKAction.rotate(toAngle: kneeBend, duration: resetDuration))
        midBackLeftLowerLeg?.run(SKAction.rotate(toAngle: -kneeBend, duration: resetDuration))
        midBackRightLowerLeg?.run(SKAction.rotate(toAngle: kneeBend, duration: resetDuration))
        backLeftLowerLeg?.run(SKAction.rotate(toAngle: -kneeBend, duration: resetDuration))
        backRightLowerLeg?.run(SKAction.rotate(toAngle: kneeBend, duration: resetDuration))
    }
}
