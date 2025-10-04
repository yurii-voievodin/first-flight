import SpriteKit


class Spider: SKNode {
    private let bodyRadius: CGFloat = 18.0

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
        let headSize = CGSize(width: 18, height: 22)
        let headPath = CGPath(
            ellipseIn: CGRect(x: -headSize.width / 2, y: -headSize.height / 2, width: headSize.width, height: headSize.height),
            transform: nil
        )
        head = SKShapeNode(path: headPath)
        head.fillColor = .lightGray
        head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 8) // Front part
        head.zPosition = 2
        addChild(head)

        // Abdomen (rear body part, larger) - no legs attached
        let abdomenSize = CGSize(width: 26, height: 38)
        let abdomenPath = CGPath(
            ellipseIn: CGRect(x: -abdomenSize.width / 2, y: -abdomenSize.height / 2, width: abdomenSize.width, height: abdomenSize.height),
            transform: nil
        )
        abdomen = SKShapeNode(path: abdomenPath)
        abdomen.fillColor = .systemGray2
        abdomen.strokeColor = .clear
        abdomen.position = CGPoint(x: 0, y: -15) // Behind cephalothorax
        abdomen.zPosition = 1
        addChild(abdomen)

        // Leg dimensions - long and thin
        let upperLegSize = CGSize(width: 2.2, height: 32)
        let lowerLegSize = CGSize(width: 1.9, height: 28)

        // Mid leg dimensions - slightly smaller
        let midUpperLegSize = CGSize(width: 2.2, height: 28)
        let midLowerLegSize = CGSize(width: 1.9, height: 24)

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
            xOffset: 12,
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
            xOffset: 14,
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
            xOffset: 14,
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
            xOffset: 12,
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

        // Parameters
        let cycleDuration: TimeInterval = 0.6   // seconds per full stride
        let upperAmp: CGFloat = .pi / 18        // ~15° swing around the base angle
        let lowerAmp: CGFloat = .pi / 18        // ~10° knee modulation around the base bend

        // Small left/right side desync (fraction of cycle); left starts slightly earlier
        let sidePhaseOffset: CGFloat = 0.12
        let leftSideΔ: CGFloat = -sidePhaseOffset * 0.5
        let rightSideΔ: CGFloat =  sidePhaseOffset * 0.5

        // Helper to run a continuous oscillation for a leg pair (upper+lower)
        func runLeg(upper: SKShapeNode?, lower: SKShapeNode?, phase: CGFloat, key: String) {
            guard let upper = upper, let lower = lower else { return }
            let baseUpper = upper.zRotation
            let baseLower = lower.zRotation

            let osc = SKAction.customAction(withDuration: cycleDuration) { _, t in
                let u = CGFloat(t / CGFloat(cycleDuration))
                let theta = 2 * .pi * (u + phase)

                // Upper segment swings around its base angle (fore–aft)
                upper.zRotation = baseUpper + sin(theta) * upperAmp

                // Lower segment bends a bit opposite to swing to suggest lift/stance
                // Using cosine to offset relative to upper
                lower.zRotation = baseLower + (-cos(theta)) * lowerAmp
            }
            let forever = SKAction.repeatForever(SKAction.sequence([osc]))
            upper.run(forever, withKey: key)
            lower.run(forever, withKey: key)
        }

        // Phase map for alternating tetrapod gait
        // Set A (phase 0): R1, L2, R3, L4
        // Set B (phase 0.5): L1, R2, L3, R4
        // Indices by name variables below

        // Set A
        runLeg(upper: frontRightUpperLeg, lower: frontRightLowerLeg, phase: 0.0 + rightSideΔ, key: "gait")
        runLeg(upper: midFrontLeftUpperLeg, lower: midFrontLeftLowerLeg, phase: 0.0 + leftSideΔ, key: "gait")
        runLeg(upper: midBackRightUpperLeg, lower: midBackRightLowerLeg, phase: 0.0 + rightSideΔ, key: "gait")
        runLeg(upper: backLeftUpperLeg, lower: backLeftLowerLeg, phase: 0.0 + leftSideΔ, key: "gait")

        // Set B (half-cycle offset)
        runLeg(upper: frontLeftUpperLeg, lower: frontLeftLowerLeg, phase: 0.5 + leftSideΔ, key: "gait")
        runLeg(upper: midFrontRightUpperLeg, lower: midFrontRightLowerLeg, phase: 0.5 + rightSideΔ, key: "gait")
        runLeg(upper: midBackLeftUpperLeg, lower: midBackLeftLowerLeg, phase: 0.5 + leftSideΔ, key: "gait")
        runLeg(upper: backRightUpperLeg, lower: backRightLowerLeg, phase: 0.5 + rightSideΔ, key: "gait")
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

        for leg in allUpperLegs { leg?.removeAction(forKey: "walk"); leg?.removeAction(forKey: "gait") }
        for leg in allLowerLegs { leg?.removeAction(forKey: "walk"); leg?.removeAction(forKey: "gait") }

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
