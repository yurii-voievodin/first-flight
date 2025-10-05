import SpriteKit


class Player: SKNode {
    private let bodyRadius: CGFloat = 20.0
    private let backpackBasePosition = CGPoint(x: 0, y: -2)
    private let helmetGlassBasePosition = CGPoint(x: 0, y: 2)
    private let leftShoulderBasePosition = CGPoint(x: -16, y: 8)
    private let rightShoulderBasePosition = CGPoint(x: 16, y: 8)
    private let leftHipBasePosition = CGPoint(x: -8, y: -16)
    private let rightHipBasePosition = CGPoint(x: 8, y: -16)
    private let baseZPosition: CGFloat = -10

    private enum FacingDirection {
        case up
        case down
        case left
        case right
    }

    private var facingDirection: FacingDirection = .down
    private var isFiring = false
    private var leftArmWasSwinging = false

    // Body parts
    private var body: SKShapeNode!
    private var backpack: SKShapeNode!
    private var shoulderArmor: SKShapeNode!
    private var head: SKShapeNode!
    private var helmetGlass: SKShapeNode!

    // Equipment
    private let blaster = Blaster()

    // Arms (multi-segment)
    private var leftUpperArm: SKShapeNode!
    private var leftElbow: SKShapeNode!
    private var leftForearm: SKShapeNode!
    private var leftWrist: SKShapeNode!
    private var leftHand: SKShapeNode!
    private var rightUpperArm: SKShapeNode!
    private var rightElbow: SKShapeNode!
    private var rightForearm: SKShapeNode!
    private var rightWrist: SKShapeNode!
    private var rightHand: SKShapeNode!

    // Legs (multi-segment)
    private var leftThigh: SKShapeNode!
    private var leftKnee: SKShapeNode!
    private var leftCalf: SKShapeNode!
    private var leftAnkle: SKShapeNode!
    private var leftFoot: SKShapeNode!
    private var rightThigh: SKShapeNode!
    private var rightKnee: SKShapeNode!
    private var rightCalf: SKShapeNode!
    private var rightAnkle: SKShapeNode!
    private var rightFoot: SKShapeNode!

    override init() {
        super.init()

        configureBaseLayer()
        setupBodyParts()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureBaseLayer()
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

        // Backpack - rounded capsule sitting behind the torso
        let backpackSize = CGSize(width: bodySize.width + 6, height: bodySize.height - 4)
        let backpackPath = CGPath(
            roundedRect: CGRect(
                x: -backpackSize.width / 2,
                y: -backpackSize.height / 2,
                width: backpackSize.width,
                height: backpackSize.height
            ),
            cornerWidth: 8,
            cornerHeight: 8,
            transform: nil
        )
        backpack = SKShapeNode(path: backpackPath)
        backpack.fillColor = SKColor(red: 0.27, green: 0.31, blue: 0.36, alpha: 1)
        backpack.strokeColor = SKColor.black.withAlphaComponent(0.25)
        backpack.lineWidth = 1.5
        backpack.position = backpackBasePosition
        backpack.zPosition = 0.2
        addChild(backpack)

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

        helmetGlass = SKShapeNode(rectOf: CGSize(width: 14, height: 12), cornerRadius: 5)
        helmetGlass.fillColor = SKColor.cyan.withAlphaComponent(0.35)
        helmetGlass.strokeColor = SKColor.white.withAlphaComponent(0.45)
        helmetGlass.lineWidth = 1.2
        helmetGlass.position = helmetGlassBasePosition
        helmetGlass.zPosition = 0.5
        head.addChild(helmetGlass)

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
        leftUpperArm.position = leftShoulderBasePosition // Left shoulder
        leftUpperArm.zPosition = 2
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
        leftForearm.zPosition = 0.2
        leftUpperArm.addChild(leftForearm)

        leftWrist = SKShapeNode(circleOfRadius: 2.5)
        leftWrist.fillColor = .systemGray
        leftWrist.strokeColor = .clear
        leftWrist.position = CGPoint(x: 0, y: -11)
        leftWrist.zPosition = 0.3
        leftForearm.addChild(leftWrist)

        leftHand = SKShapeNode(rectOf: CGSize(width: 6, height: 8), cornerRadius: 2)
        leftHand.fillColor = .white
        leftHand.strokeColor = .clear
        leftHand.position = CGPoint(x: 0, y: -8)
        leftHand.zPosition = 0.4
        leftWrist.addChild(leftHand)

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
        rightUpperArm.position = rightShoulderBasePosition // Right shoulder
        rightUpperArm.zPosition = 2
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
        rightForearm.zPosition = 0.2
        rightUpperArm.addChild(rightForearm)

        rightWrist = SKShapeNode(circleOfRadius: 2.5)
        rightWrist.fillColor = .systemGray
        rightWrist.strokeColor = .clear
        rightWrist.position = CGPoint(x: 0, y: -11)
        rightWrist.zPosition = 0.3
        rightForearm.addChild(rightWrist)

        rightHand = SKShapeNode(rectOf: CGSize(width: 6, height: 8), cornerRadius: 2)
        rightHand.fillColor = .white
        rightHand.strokeColor = .clear
        rightHand.position = CGPoint(x: 0, y: -8)
        rightHand.zPosition = 0.4
        rightWrist.addChild(rightHand)

        leftHand.addChild(blaster)

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
        leftThigh.position = leftHipBasePosition // Left hip
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

        leftAnkle = SKShapeNode(circleOfRadius: 3)
        leftAnkle.fillColor = .systemGray
        leftAnkle.strokeColor = .clear
        leftAnkle.position = CGPoint(x: 0, y: -12)
        leftAnkle.zPosition = 0.6
        leftCalf.addChild(leftAnkle)

        leftFoot = SKShapeNode(rectOf: CGSize(width: 12, height: 6), cornerRadius: 2)
        leftFoot.fillColor = .white
        leftFoot.strokeColor = .clear
        leftFoot.position = CGPoint(x: 0, y: -5)
        leftFoot.zPosition = 0.2
        leftAnkle.addChild(leftFoot)

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
        rightThigh.position = rightHipBasePosition // Right hip
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

        rightAnkle = SKShapeNode(circleOfRadius: 3)
        rightAnkle.fillColor = .systemGray
        rightAnkle.strokeColor = .clear
        rightAnkle.position = CGPoint(x: 0, y: -12)
        rightAnkle.zPosition = 0.6
        rightCalf.addChild(rightAnkle)

        rightFoot = SKShapeNode(rectOf: CGSize(width: 12, height: 6), cornerRadius: 2)
        rightFoot.fillColor = .white
        rightFoot.strokeColor = .clear
        rightFoot.position = CGPoint(x: 0, y: -5)
        rightFoot.zPosition = 0.2
        rightAnkle.addChild(rightFoot)

        applyAppearance(for: facingDirection)
    }

    private func configureBaseLayer() {
        zPosition = baseZPosition
    }

    private func setFacingDirection(_ direction: FacingDirection) {
        guard direction != facingDirection else { return }
        facingDirection = direction
        applyAppearance(for: direction)
    }

    private func updateFacingDirection(dx: CGFloat, dy: CGFloat) {
        let threshold: CGFloat = 2
        if abs(dx) < threshold && abs(dy) < threshold {
            return
        }

        if abs(dx) > abs(dy) {
            setFacingDirection(dx > 0 ? .right : .left)
        } else {
            setFacingDirection(dy > 0 ? .up : .down)
        }
    }

    private func applyAppearance(for direction: FacingDirection) {
        // Reset to a neutral front-facing look before applying directional tweaks.
        backpack.isHidden = false
        backpack.alpha = 1
        backpack.xScale = 1
        backpack.yScale = 1
        backpack.position = backpackBasePosition
        backpack.zPosition = 0.2

        helmetGlass.isHidden = false
        helmetGlass.alpha = 1
        helmetGlass.xScale = 1
        helmetGlass.yScale = 1
        helmetGlass.position = helmetGlassBasePosition

        let concealedJointNodes: [SKNode] = [
            leftElbow,
            leftWrist,
            rightElbow,
            rightWrist,
            leftKnee,
            rightKnee
        ]

        concealedJointNodes.forEach { $0.isHidden = false }

        xScale = 1

        leftUpperArm.position = leftShoulderBasePosition
        rightUpperArm.position = rightShoulderBasePosition
        leftThigh.position = leftHipBasePosition
        rightThigh.position = rightHipBasePosition

        var blasterOrientation = blasterOrientation(for: direction)

        switch direction {
        case .up:
            backpack.zPosition = 1.6
            backpack.position = CGPoint(x: 0, y: -1)
            helmetGlass.isHidden = true
            concealedJointNodes.forEach { $0.isHidden = true }
            blasterOrientation = .up
        case .down:
            backpack.isHidden = true
            blasterOrientation = .down
        case .right:
            backpack.alpha = 0.75
            backpack.zPosition = 0.9
            backpack.xScale = 0.7
            backpack.position = CGPoint(x: -3, y: -2)
            helmetGlass.alpha = 0.85
            helmetGlass.xScale = 0.75
            helmetGlass.position = CGPoint(x: 2.2, y: 2)
            blasterOrientation = .right
        case .left:
            xScale = -1
            backpack.alpha = 0.75
            backpack.zPosition = 0.9
            backpack.xScale = 0.7
            backpack.position = CGPoint(x: -3, y: -2)
            helmetGlass.alpha = 0.85
            helmetGlass.xScale = 0.75
            helmetGlass.position = CGPoint(x: 2.2, y: 2)
            leftUpperArm.position = CGPoint(x: -leftShoulderBasePosition.x, y: leftShoulderBasePosition.y)
            rightUpperArm.position = CGPoint(x: -rightShoulderBasePosition.x, y: rightShoulderBasePosition.y)
            leftThigh.position = CGPoint(x: -leftHipBasePosition.x, y: leftHipBasePosition.y)
            rightThigh.position = CGPoint(x: -rightHipBasePosition.x, y: rightHipBasePosition.y)
            blasterOrientation = .left
        }

        blaster.update(for: blasterOrientation)

        if isFiring {
            if direction == .left || direction == .right {
                configureLeftArmAimPose(manageWalkCycle: false, animated: true)
            } else {
                resetLeftArmPose(manageWalkCycle: false, animated: true)
            }
        }
    }

    private func blasterOrientation(for direction: FacingDirection) -> Blaster.Orientation {
        switch direction {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        }
    }

    private func configureLeftArmAimPose(manageWalkCycle: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        guard facingDirection == .left || facingDirection == .right else {
            completion?()
            return
        }

        if manageWalkCycle {
            leftArmWasSwinging = leftUpperArm.action(forKey: "walk") != nil
            if leftArmWasSwinging {
                leftUpperArm.removeAction(forKey: "walk")
                leftForearm.removeAction(forKey: "walk")
                leftWrist.removeAction(forKey: "walk")
                leftHand.removeAction(forKey: "walk")
            }
        }

        let duration: TimeInterval = animated ? 0.12 : 0
        let parentScaleSign: CGFloat = xScale >= 0 ? 1 : -1
        let desiredWorldSign: CGFloat = facingDirection == .left ? -1 : 1
        // Adjust for mirrored player scale so the beam matches the on-screen facing.
        let directionSign: CGFloat = desiredWorldSign * parentScaleSign

        rotate(leftUpperArm, to: directionSign * (.pi / 2), duration: duration, key: "aimUpper")
        rotate(leftForearm, to: directionSign * (.pi / 16), duration: duration, key: "aimFore")
        rotate(leftWrist, to: directionSign * (.pi / 20), duration: duration, key: "aimWrist")
        rotate(leftHand, to: directionSign * (-.pi / 24), duration: duration, key: "aimHand", completion: completion)
    }

    private func resetLeftArmPose(manageWalkCycle: Bool, animated: Bool) {
        let duration: TimeInterval = animated ? 0.15 : 0

        rotate(leftUpperArm, to: 0, duration: duration, key: "aimUpper")
        rotate(leftForearm, to: 0, duration: duration, key: "aimFore")
        rotate(leftWrist, to: 0, duration: duration, key: "aimWrist")
        rotate(leftHand, to: 0, duration: duration, key: "aimHand")

        if manageWalkCycle && leftArmWasSwinging {
            leftArmWasSwinging = false
            if action(forKey: "move") != nil {
                startWalkingAnimation()
            }
        }
    }

    private func rotate(_ node: SKNode?, to angle: CGFloat, duration: TimeInterval, key: String, completion: (() -> Void)? = nil) {
        guard let node = node else {
            completion?()
            return
        }
        node.removeAction(forKey: key)
        let action = SKAction.rotate(toAngle: angle, duration: duration, shortestUnitArc: true)
        if let completion = completion {
            let sequence = SKAction.sequence([action, SKAction.run(completion)])
            node.run(sequence, withKey: key)
        } else {
            node.run(action, withKey: key)
        }
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
        let deltaX = position.x - self.position.x
        let deltaY = position.y - self.position.y
        updateFacingDirection(dx: deltaX, dy: deltaY)

        let distance = hypot(deltaX, deltaY)
        let speed: CGFloat = 55.0 // points per second
        let duration = max(TimeInterval(distance / speed), 0.05)

        // Avoid needless animation if already at target
        if distance < 1 {
            let settle = SKAction.move(to: position, duration: 0.05)
            let stopAnimation = SKAction.run { [weak self] in
                self?.stopWalkingAnimation()
            }
            run(SKAction.sequence([settle, stopAnimation]), withKey: "move")
            return
        }

        // Move directly to position with no overshoot
        let moveAction = SKAction.move(to: position, duration: duration)
        moveAction.timingMode = .linear

        // Stop animation when movement completes
        let stopAnimation = SKAction.run { [weak self] in
            self?.stopWalkingAnimation()
        }

        zRotation = 0
        let sequence = SKAction.sequence([moveAction, stopAnimation])
        run(sequence, withKey: "move")

        // Start walking animation
        startWalkingAnimation()
    }

    func stopMovement() {
        removeAction(forKey: "move")
        physicsBody?.velocity = .zero
        zRotation = 0

        // Stop walking animation
        stopWalkingAnimation()
    }

    func startFiringBlaster() {
        guard !isFiring else { return }
        isFiring = true
        blaster.update(for: blasterOrientation(for: facingDirection))
        configureLeftArmAimPose(manageWalkCycle: true, animated: true) { [weak self] in
            self?.blaster.startBeam()
        }
    }

    func stopFiringBlaster() {
        guard isFiring else { return }
        isFiring = false
        blaster.stopBeam()
        blaster.update(for: blasterOrientation(for: facingDirection))
        resetLeftArmPose(manageWalkCycle: true, animated: true)
    }

    // MARK: - Animation

    private func startWalkingAnimation() {
        stopWalkingAnimation()

        // Step duration for each limb movement
        let stepDuration: TimeInterval = 0.12

        // Movement angles
        let thighSwingAngle: CGFloat = .pi / 14 // ~13 degrees
        let kneeBendAngle: CGFloat = .pi / 7    // ~26 degrees
        let upperArmSwingAngle: CGFloat = .pi / 20 // ~9 degrees
        let elbowBendAngle: CGFloat = .pi / 12     // ~15 degrees
        let wristFlickAngle: CGFloat = .pi / 18    // ~10 degrees
        let ankleRollAngle: CGFloat = .pi / 14     // ~13 degrees

        // Helper closure to repeat action forever
        func cycle(_ actions: SKAction...) -> SKAction {
            SKAction.sequence(actions)
        }

        // === RIGHT LEG (Phase 1: steps first) ===
        let rightThighCycle = cycle(
            SKAction.rotate(toAngle: thighSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration),
            SKAction.rotate(toAngle: -thighSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration)
        )

        let rightCalfCycle = cycle(
            SKAction.rotate(toAngle: -kneeBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -kneeBendAngle * 0.3, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
        )

        let rightAnkleCycle = cycle(
            SKAction.rotate(toAngle: ankleRollAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -ankleRollAngle * 0.6, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
        )

        let rightFootCycle = cycle(
            SKAction.rotate(toAngle: -ankleRollAngle * 0.7, duration: stepDuration),
            SKAction.rotate(toAngle: ankleRollAngle * 0.4, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
        )

        // === LEFT ARM (Phase 1: swings with right leg) ===
        let leftUpperArmCycle = cycle(
            SKAction.rotate(toAngle: upperArmSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration),
            SKAction.rotate(toAngle: -upperArmSwingAngle, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration)
        )

        let leftForearmCycle = cycle(
            SKAction.rotate(toAngle: -elbowBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -elbowBendAngle * 0.4, duration: stepDuration),
            SKAction.rotate(toAngle: -elbowBendAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -elbowBendAngle * 0.4, duration: stepDuration)
        )

        let leftWristCycle = cycle(
            SKAction.rotate(toAngle: wristFlickAngle, duration: stepDuration),
            SKAction.rotate(toAngle: -wristFlickAngle * 0.8, duration: stepDuration),
            SKAction.rotate(toAngle: wristFlickAngle * 0.3, duration: stepDuration),
            SKAction.rotate(toAngle: -wristFlickAngle * 0.3, duration: stepDuration)
        )

        let leftHandCycle = cycle(
            SKAction.rotate(toAngle: -wristFlickAngle * 0.5, duration: stepDuration),
            SKAction.rotate(toAngle: wristFlickAngle * 0.4, duration: stepDuration),
            SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
        )

        // === LEFT LEG (Phase 3: steps after right leg) ===
        let leftThighCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: thighSwingAngle, duration: stepDuration),
                SKAction.wait(forDuration: stepDuration),
                SKAction.rotate(toAngle: -thighSwingAngle, duration: stepDuration),
                SKAction.wait(forDuration: stepDuration)
            ))
        ])

        let leftCalfCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: -kneeBendAngle, duration: stepDuration),
                SKAction.rotate(toAngle: -kneeBendAngle * 0.3, duration: stepDuration),
                SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
            ))
        ])

        let leftAnkleCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: ankleRollAngle, duration: stepDuration),
                SKAction.rotate(toAngle: -ankleRollAngle * 0.6, duration: stepDuration),
                SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
            ))
        ])

        let leftFootCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: -ankleRollAngle * 0.7, duration: stepDuration),
                SKAction.rotate(toAngle: ankleRollAngle * 0.4, duration: stepDuration),
                SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
            ))
        ])

        // === RIGHT ARM (Phase 3: swings with left leg) ===
        let rightUpperArmCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: upperArmSwingAngle, duration: stepDuration),
                SKAction.wait(forDuration: stepDuration),
                SKAction.rotate(toAngle: -upperArmSwingAngle, duration: stepDuration),
                SKAction.wait(forDuration: stepDuration)
            ))
        ])

        let rightForearmCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: -elbowBendAngle, duration: stepDuration),
                SKAction.rotate(toAngle: -elbowBendAngle * 0.4, duration: stepDuration),
                SKAction.rotate(toAngle: -elbowBendAngle, duration: stepDuration),
                SKAction.rotate(toAngle: -elbowBendAngle * 0.4, duration: stepDuration)
            ))
        ])

        let rightWristCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: wristFlickAngle, duration: stepDuration),
                SKAction.rotate(toAngle: -wristFlickAngle * 0.8, duration: stepDuration),
                SKAction.rotate(toAngle: wristFlickAngle * 0.3, duration: stepDuration),
                SKAction.rotate(toAngle: -wristFlickAngle * 0.3, duration: stepDuration)
            ))
        ])

        let rightHandCycle = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 2),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: -wristFlickAngle * 0.5, duration: stepDuration),
                SKAction.rotate(toAngle: wristFlickAngle * 0.4, duration: stepDuration),
                SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
            ))
        ])

        // Run animations
        rightThigh.run(SKAction.repeatForever(rightThighCycle), withKey: "walk")
        rightCalf.run(SKAction.repeatForever(rightCalfCycle), withKey: "walk")
        rightAnkle.run(SKAction.repeatForever(rightAnkleCycle), withKey: "walk")
        rightFoot.run(SKAction.repeatForever(rightFootCycle), withKey: "walk")

        if !(isFiring && (facingDirection == .left || facingDirection == .right)) {
            leftUpperArm.run(SKAction.repeatForever(leftUpperArmCycle), withKey: "walk")
            leftForearm.run(SKAction.repeatForever(leftForearmCycle), withKey: "walk")
            leftWrist.run(SKAction.repeatForever(leftWristCycle), withKey: "walk")
            leftHand.run(SKAction.repeatForever(leftHandCycle), withKey: "walk")
        }

        leftThigh.run(leftThighCycle, withKey: "walk")
        leftCalf.run(leftCalfCycle, withKey: "walk")
        leftAnkle.run(leftAnkleCycle, withKey: "walk")
        leftFoot.run(leftFootCycle, withKey: "walk")

        rightUpperArm.run(rightUpperArmCycle, withKey: "walk")
        rightForearm.run(rightForearmCycle, withKey: "walk")
        rightWrist.run(rightWristCycle, withKey: "walk")
        rightHand.run(rightHandCycle, withKey: "walk")

        if isFiring && (facingDirection == .left || facingDirection == .right) {
            configureLeftArmAimPose(manageWalkCycle: false, animated: false)
        }
    }

    private func stopWalkingAnimation() {
        // Stop all limb animations
        leftThigh.removeAction(forKey: "walk")
        leftCalf.removeAction(forKey: "walk")
        leftAnkle.removeAction(forKey: "walk")
        leftFoot.removeAction(forKey: "walk")
        rightThigh.removeAction(forKey: "walk")
        rightCalf.removeAction(forKey: "walk")
        rightAnkle.removeAction(forKey: "walk")
        rightFoot.removeAction(forKey: "walk")
        leftUpperArm.removeAction(forKey: "walk")
        leftForearm.removeAction(forKey: "walk")
        leftWrist.removeAction(forKey: "walk")
        leftHand.removeAction(forKey: "walk")
        rightUpperArm.removeAction(forKey: "walk")
        rightForearm.removeAction(forKey: "walk")
        rightWrist.removeAction(forKey: "walk")
        rightHand.removeAction(forKey: "walk")

        // Reset all segments to neutral position
        let resetDuration: TimeInterval = 0.2
        leftThigh.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        leftCalf.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        leftAnkle.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        leftFoot.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightThigh.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightCalf.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightAnkle.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightFoot.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        if !isFiring {
            leftUpperArm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
            leftForearm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
            leftWrist.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
            leftHand.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        }
        rightUpperArm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightForearm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightWrist.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightHand.run(SKAction.rotate(toAngle: 0, duration: resetDuration))

        if isFiring && (facingDirection == .left || facingDirection == .right) {
            configureLeftArmAimPose(manageWalkCycle: false, animated: false)
        }
    }
}
