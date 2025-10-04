import SpriteKit


class Spider: SKNode {
    private let bodyRadius: CGFloat = 25.0

    // Leg angles
    private let frontLegsAngle: CGFloat = -35 * .pi / 180
    private let midFrontLegsAngle: CGFloat = -10 * .pi / 180
    private let midBackLegsAngle: CGFloat = 25 * .pi / 180
    private let backLegsAngle: CGFloat = 55 * .pi / 180

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
        // Cephalothorax (head+thorax, front body part where legs attach) - smaller oval
        let headSize = CGSize(width: 24, height: 28)
        let headPath = CGPath(
            ellipseIn: CGRect(x: -headSize.width / 2, y: -headSize.height / 2, width: headSize.width, height: headSize.height),
            transform: nil
        )
        head = SKShapeNode(path: headPath)
        head.fillColor = .lightGray
        head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 10) // Front part
        head.zPosition = 2
        addChild(head)

        // Abdomen (rear body part, larger) - no legs attached
        let abdomenSize = CGSize(width: 35, height: 50)
        let abdomenPath = CGPath(
            ellipseIn: CGRect(x: -abdomenSize.width / 2, y: -abdomenSize.height / 2, width: abdomenSize.width, height: abdomenSize.height),
            transform: nil
        )
        abdomen = SKShapeNode(path: abdomenPath)
        abdomen.fillColor = .systemGray2
        abdomen.strokeColor = .clear
        abdomen.position = CGPoint(x: 0, y: -20) // Behind cephalothorax
        abdomen.zPosition = 1
        addChild(abdomen)

        // Leg dimensions - long and thin
        let upperLegSize = CGSize(width: 3, height: 40)
        let lowerLegSize = CGSize(width: 2.5, height: 35)

        // Mid leg dimensions - slightly smaller
        let midUpperLegSize = CGSize(width: 3, height: 35)
        let midLowerLegSize = CGSize(width: 2.5, height: 30)

        // FRONT LEGS (Pair 1) - Angled upward/forward (longest)
        setupLegPair(
            leftUpper: &frontLeftUpperLeg,
            leftJoint: &frontLeftJoint,
            leftLower: &frontLeftLowerLeg,
            rightUpper: &frontRightUpperLeg,
            rightJoint: &frontRightJoint,
            rightLower: &frontRightLowerLeg,
            upperSize: upperLegSize,
            lowerSize: lowerLegSize,
            position: CGPoint(x: 0, y: 0),
            xOffset: 16,
            forwardAngle: frontLegsAngle
        )

        // MID-FRONT LEGS (Pair 2) - Angled forward (shorter)
        setupLegPair(
            leftUpper: &midFrontLeftUpperLeg,
            leftJoint: &midFrontLeftJoint,
            leftLower: &midFrontLeftLowerLeg,
            rightUpper: &midFrontRightUpperLeg,
            rightJoint: &midFrontRightJoint,
            rightLower: &midFrontRightLowerLeg,
            upperSize: midUpperLegSize,
            lowerSize: midLowerLegSize,
            position: CGPoint(x: 0, y: 0),
            xOffset: 18,
            forwardAngle: midFrontLegsAngle
        )

        // MID-BACK LEGS (Pair 3) - Angled backward (shorter)
        setupLegPair(
            leftUpper: &midBackLeftUpperLeg,
            leftJoint: &midBackLeftJoint,
            leftLower: &midBackLeftLowerLeg,
            rightUpper: &midBackRightUpperLeg,
            rightJoint: &midBackRightJoint,
            rightLower: &midBackRightLowerLeg,
            upperSize: midUpperLegSize,
            lowerSize: midLowerLegSize,
            position: CGPoint(x: 0, y: 0),
            xOffset: 18,
            forwardAngle: midBackLegsAngle
        )

        // BACK LEGS (Pair 4) - Angled backward (longest)
        setupLegPair(
            leftUpper: &backLeftUpperLeg,
            leftJoint: &backLeftJoint,
            leftLower: &backLeftLowerLeg,
            rightUpper: &backRightUpperLeg,
            rightJoint: &backRightJoint,
            rightLower: &backRightLowerLeg,
            upperSize: upperLegSize,
            lowerSize: lowerLegSize,
            position: CGPoint(x: 0, y: 0),
            xOffset: 16,
            forwardAngle: backLegsAngle
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
        leftUpper.zPosition = -1
        head.addChild(leftUpper)

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
        rightUpper.zPosition = -1
        head.addChild(rightUpper)

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

        // Calculate direction angle toward target
        let deltaX = position.x - self.position.x
        let deltaY = position.y - self.position.y
        let targetAngle = atan2(deltaY, deltaX) - .pi / 2

        // Calculate shortest rotation path
        let currentAngle = zRotation
        var angleDifference = targetAngle - currentAngle

        // Normalize to [-π, π] range for shortest path
        while angleDifference > .pi {
            angleDifference -= 2 * .pi
        }
        while angleDifference < -.pi {
            angleDifference += 2 * .pi
        }

        // Rotate to face direction (quick rotation)
        let rotateAction = SKAction.rotate(byAngle: angleDifference, duration: 0.15)
        rotateAction.timingMode = .easeInEaseOut

        // Move directly to position with no overshoot
        let moveAction = SKAction.move(to: position, duration: duration)
        moveAction.timingMode = .linear

        // Stop animation when movement completes
        let stopAnimation = SKAction.run { [weak self] in
            self?.stopWalkingAnimation()
        }

        let sequence = SKAction.sequence([rotateAction, moveAction, stopAnimation])
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
        // Stop any existing animations and reset legs to initial positions
        stopWalkingAnimation()

        // Spider walking uses alternating tetrapods gait
        // Tetrapod 1: R1, L2, R3, L4 (right front, left mid-front, right mid-back, left back)
        // Tetrapod 2: L1, R2, L3, R4 (left front, right mid-front, left mid-back, right back)
        // Wave sequence creates 1-2-3-4 staggered motion within each tetrapod

        let stepDuration: TimeInterval = 0.15
        let waveLag: TimeInterval = stepDuration * 0.25 // Delay between legs in wave
        let cycleDuration = stepDuration * 4 // Full cycle time

        // Leg movement angles
        let upperLegSwing: CGFloat = .pi / 8 // 18 degrees swing
        let lowerLegBend: CGFloat = .pi / 6 // 30 degrees bend when lifted

        // Helper function to create a leg step cycle with wave offset
        func createLegCycle(startDelay: TimeInterval, swingDirection: CGFloat) -> SKAction {
            let remainingTime = max(0, cycleDuration - stepDuration * 2 - startDelay)
            return SKAction.sequence([
                SKAction.wait(forDuration: startDelay),
                SKAction.rotate(byAngle: swingDirection * upperLegSwing, duration: stepDuration),
                SKAction.rotate(byAngle: -swingDirection * upperLegSwing, duration: stepDuration),
                SKAction.wait(forDuration: remainingTime)
            ])
        }

        func createLowerLegCycle(startDelay: TimeInterval, bendDirection: CGFloat) -> SKAction {
            let remainingTime = max(0, cycleDuration - stepDuration - startDelay)
            return SKAction.sequence([
                SKAction.wait(forDuration: startDelay),
                SKAction.rotate(toAngle: bendDirection * lowerLegBend, duration: stepDuration * 0.5),
                SKAction.rotate(toAngle: 0, duration: stepDuration * 0.5),
                SKAction.wait(forDuration: remainingTime)
            ])
        }

        // TETRAPOD 1: R1 → L2 → R3 → L4 (wave sequence)
        // R1 - Front Right
        let frontRightUpperCycle = createLegCycle(startDelay: 0, swingDirection: -1)
        let frontRightLowerCycle = createLowerLegCycle(startDelay: 0, bendDirection: 1)

        // L2 - Mid-Front Left
        let midFrontLeftUpperCycle = createLegCycle(startDelay: waveLag, swingDirection: 1)
        let midFrontLeftLowerCycle = createLowerLegCycle(startDelay: waveLag, bendDirection: -1)

        // R3 - Mid-Back Right
        let midBackRightUpperCycle = createLegCycle(startDelay: waveLag * 2, swingDirection: -1)
        let midBackRightLowerCycle = createLowerLegCycle(startDelay: waveLag * 2, bendDirection: 1)

        // L4 - Back Left
        let backLeftUpperCycle = createLegCycle(startDelay: waveLag * 3, swingDirection: 1)
        let backLeftLowerCycle = createLowerLegCycle(startDelay: waveLag * 3, bendDirection: -1)

        // TETRAPOD 2: L1 → R2 → L3 → R4 (opposite phase - half cycle offset)
        let halfCycle = cycleDuration / 2

        // L1 - Front Left
        let frontLeftUpperCycle = createLegCycle(startDelay: halfCycle, swingDirection: 1)
        let frontLeftLowerCycle = createLowerLegCycle(startDelay: halfCycle, bendDirection: -1)

        // R2 - Mid-Front Right
        let midFrontRightUpperCycle = createLegCycle(startDelay: halfCycle + waveLag, swingDirection: -1)
        let midFrontRightLowerCycle = createLowerLegCycle(startDelay: halfCycle + waveLag, bendDirection: 1)

        // L3 - Mid-Back Left
        let midBackLeftUpperCycle = createLegCycle(startDelay: halfCycle + waveLag * 2, swingDirection: 1)
        let midBackLeftLowerCycle = createLowerLegCycle(startDelay: halfCycle + waveLag * 2, bendDirection: -1)

        // R4 - Back Right
        let backRightUpperCycle = createLegCycle(startDelay: halfCycle + waveLag * 3, swingDirection: -1)
        let backRightLowerCycle = createLowerLegCycle(startDelay: halfCycle + waveLag * 3, bendDirection: 1)

        // Run all leg animations
        frontRightUpperLeg.run(SKAction.repeatForever(frontRightUpperCycle), withKey: "walk")
        frontRightLowerLeg.run(SKAction.repeatForever(frontRightLowerCycle), withKey: "walk")

        midFrontLeftUpperLeg.run(SKAction.repeatForever(midFrontLeftUpperCycle), withKey: "walk")
        midFrontLeftLowerLeg.run(SKAction.repeatForever(midFrontLeftLowerCycle), withKey: "walk")

        midBackRightUpperLeg.run(SKAction.repeatForever(midBackRightUpperCycle), withKey: "walk")
        midBackRightLowerLeg.run(SKAction.repeatForever(midBackRightLowerCycle), withKey: "walk")

        backLeftUpperLeg.run(SKAction.repeatForever(backLeftUpperCycle), withKey: "walk")
        backLeftLowerLeg.run(SKAction.repeatForever(backLeftLowerCycle), withKey: "walk")

        frontLeftUpperLeg.run(SKAction.repeatForever(frontLeftUpperCycle), withKey: "walk")
        frontLeftLowerLeg.run(SKAction.repeatForever(frontLeftLowerCycle), withKey: "walk")

        midFrontRightUpperLeg.run(SKAction.repeatForever(midFrontRightUpperCycle), withKey: "walk")
        midFrontRightLowerLeg.run(SKAction.repeatForever(midFrontRightLowerCycle), withKey: "walk")

        midBackLeftUpperLeg.run(SKAction.repeatForever(midBackLeftUpperCycle), withKey: "walk")
        midBackLeftLowerLeg.run(SKAction.repeatForever(midBackLeftLowerCycle), withKey: "walk")

        backRightUpperLeg.run(SKAction.repeatForever(backRightUpperCycle), withKey: "walk")
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

        // Reset upper legs to their initial angles immediately
        frontLeftUpperLeg?.zRotation = frontLegsAngle
        frontRightUpperLeg?.zRotation = -frontLegsAngle
        midFrontLeftUpperLeg?.zRotation = midFrontLegsAngle
        midFrontRightUpperLeg?.zRotation = -midFrontLegsAngle
        midBackLeftUpperLeg?.zRotation = midBackLegsAngle
        midBackRightUpperLeg?.zRotation = -midBackLegsAngle
        backLeftUpperLeg?.zRotation = backLegsAngle
        backRightUpperLeg?.zRotation = -backLegsAngle

        // Reset lower legs to bent neutral position (downward bend) immediately
        let kneeBend: CGFloat = .pi / 6
        frontLeftLowerLeg?.zRotation = -kneeBend
        frontRightLowerLeg?.zRotation = kneeBend
        midFrontLeftLowerLeg?.zRotation = -kneeBend
        midFrontRightLowerLeg?.zRotation = kneeBend
        midBackLeftLowerLeg?.zRotation = -kneeBend
        midBackRightLowerLeg?.zRotation = kneeBend
        backLeftLowerLeg?.zRotation = -kneeBend
        backRightLowerLeg?.zRotation = kneeBend
    }
}
