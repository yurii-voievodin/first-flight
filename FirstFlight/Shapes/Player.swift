import SpriteKit


class Player: SKNode {
    private let bodyRadius: CGFloat = 20.0
    private let backpackBasePosition = CGPoint(x: 0, y: -2)
    private let helmetGlassBasePosition = CGPoint(x: 0, y: 2)
    private let leftShoulderBasePosition = CGPoint(x: -13, y: 10)
    private let rightShoulderBasePosition = CGPoint(x: 13, y: 10)
    private let leftHipBasePosition = CGPoint(x: -6, y: -14)
    private let rightHipBasePosition = CGPoint(x: 6, y: -14)
    private let baseZPosition: CGFloat = -10

    // MARK: - Textures

    private enum TextureName {
        static let body = "body"
        static let backpack = "backpack"
        static let head = "head"
        static let helmetGlass = "helmet_glass"

        static let upperArm = "upper_arm"
        static let forearm = "forearm"
        static let hand = "hand"
        static let elbowJoint = "elbow_joint"
        static let wristJoint = "wrist_joint"

        static let thigh = "thigh"
        static let calf = "calf"
        static let kneeJoint = "knee_joint"
        static let ankleJoint = "ankle_joint"
        static let foot = "foot"
    }

    private func makeTexture(named name: String) -> SKTexture {
        let texture = SKTexture(imageNamed: name)
        texture.filteringMode = .nearest
        return texture
    }

    private func makeSprite(named name: String, size: CGSize, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: makeTexture(named: name), size: size)
        sprite.anchorPoint = anchorPoint
        return sprite
    }

    private enum FacingDirection {
        case up
        case down
        case left
        case right
    }

    private var facingDirection: FacingDirection = .down
    private(set) var isFiring = false
    private(set) var isWalking = false
    private(set) var isInWater = false
    private var lastWalkingDirection: FacingDirection?

    // MARK: - Energy System

    private(set) var currentEnergy: Int = 50
    private(set) var maxEnergy: Int = 50

    // Body parts
    private var body: SKSpriteNode!
    private var backpack: SKSpriteNode!
    private var head: SKSpriteNode!
    private var helmetGlass: SKSpriteNode!

    // Equipment
    private let blaster = Blaster()

    // Arms (multi-segment)
    private var leftUpperArm: SKSpriteNode!
    private var leftElbow: SKSpriteNode!
    private var leftForearm: SKSpriteNode!
    private var leftWrist: SKSpriteNode!
    private var leftHand: SKSpriteNode!
    private var rightUpperArm: SKSpriteNode!
    private var rightElbow: SKSpriteNode!
    private var rightForearm: SKSpriteNode!
    private var rightWrist: SKSpriteNode!
    private var rightHand: SKSpriteNode!

    // Legs (multi-segment)
    private var leftThigh: SKSpriteNode!
    private var leftKnee: SKSpriteNode!
    private var leftCalf: SKSpriteNode!
    private var leftAnkle: SKSpriteNode!
    private var leftFoot: SKSpriteNode!
    private var rightThigh: SKSpriteNode!
    private var rightKnee: SKSpriteNode!
    private var rightCalf: SKSpriteNode!
    private var rightAnkle: SKSpriteNode!
    private var rightFoot: SKSpriteNode!
    
    var leftArm: [SKNode] {
        [leftUpperArm, leftElbow, leftForearm, leftWrist, leftHand]
    }

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

        // Backpack is intentionally narrower than the torso
        let backpackSize = CGSize(width: bodySize.width - 2, height: bodySize.height - 6)
        backpack = makeSprite(named: TextureName.backpack, size: backpackSize)
        backpack.position = backpackBasePosition
        backpack.zPosition = 0.2
        addChild(backpack)

        body = makeSprite(named: TextureName.body, size: bodySize)
        body.position = CGPoint(x: 0, y: 0)
        body.zPosition = 1
        addChild(body)

        // Head (helmet) - rounded for smooth look
        let headSize = CGSize(width: 20, height: 20)
        head = makeSprite(named: TextureName.head, size: headSize)
        // Slight overlap to compensate for transparent padding inside the texture
        head.position = CGPoint(x: 0, y: 22) // Above body
        head.zPosition = 2
        addChild(head)

        let helmetGlassSize = CGSize(width: 14, height: 12)
        helmetGlass = makeSprite(named: TextureName.helmetGlass, size: helmetGlassSize)
        helmetGlass.position = helmetGlassBasePosition
        helmetGlass.zPosition = 0.5
        helmetGlass.alpha = 1
        head.addChild(helmetGlass)

        // Left Upper Arm - anchor at shoulder
        let upperArmSize = CGSize(width: 8, height: 14)
        leftUpperArm = makeSprite(named: TextureName.upperArm, size: upperArmSize, anchorPoint: CGPoint(x: 0.5, y: 0.85))
        leftUpperArm.position = leftShoulderBasePosition // Left shoulder
        leftUpperArm.zPosition = 2
        addChild(leftUpperArm)

        leftElbow = makeSprite(named: TextureName.elbowJoint, size: CGSize(width: 6, height: 6))
        leftElbow.position = CGPoint(x: 0, y: -12) // Bottom of upper arm
        leftElbow.zPosition = 0.5
        leftUpperArm.addChild(leftElbow)

        let forearmSize = CGSize(width: 7, height: 12)
        leftForearm = makeSprite(named: TextureName.forearm, size: forearmSize, anchorPoint: CGPoint(x: 0.5, y: 0.85))
        leftForearm.position = CGPoint(x: 0, y: -12) // At elbow joint
        leftForearm.zPosition = 0.2
        leftUpperArm.addChild(leftForearm)

        leftWrist = makeSprite(named: TextureName.wristJoint, size: CGSize(width: 5, height: 5))
        leftWrist.position = CGPoint(x: 0, y: -9)
        leftWrist.zPosition = 0.3
        leftForearm.addChild(leftWrist)

        leftHand = makeSprite(named: TextureName.hand, size: CGSize(width: 6, height: 8))
        leftHand.position = CGPoint(x: 0, y: -5)
        leftHand.zPosition = 0.4
        leftWrist.addChild(leftHand)

        // Right Upper Arm - anchor at shoulder
        rightUpperArm = makeSprite(named: TextureName.upperArm, size: upperArmSize, anchorPoint: CGPoint(x: 0.5, y: 0.85))
        rightUpperArm.position = rightShoulderBasePosition // Right shoulder
        rightUpperArm.zPosition = 2
        addChild(rightUpperArm)

        rightElbow = makeSprite(named: TextureName.elbowJoint, size: CGSize(width: 6, height: 6))
        rightElbow.position = CGPoint(x: 0, y: -12) // Bottom of upper arm
        rightElbow.zPosition = 0.5
        rightUpperArm.addChild(rightElbow)

        rightForearm = makeSprite(named: TextureName.forearm, size: forearmSize, anchorPoint: CGPoint(x: 0.5, y: 0.85))
        rightForearm.position = CGPoint(x: 0, y: -12) // At elbow joint
        rightForearm.zPosition = 0.2
        rightUpperArm.addChild(rightForearm)

        rightWrist = makeSprite(named: TextureName.wristJoint, size: CGSize(width: 5, height: 5))
        rightWrist.position = CGPoint(x: 0, y: -9)
        rightWrist.zPosition = 0.3
        rightForearm.addChild(rightWrist)

        rightHand = makeSprite(named: TextureName.hand, size: CGSize(width: 6, height: 8))
        rightHand.position = CGPoint(x: 0, y: -5)
        rightHand.zPosition = 0.4
        rightWrist.addChild(rightHand)

        leftHand.addChild(blaster)

        // Left Thigh - anchor at hip
        let thighSize = CGSize(width: 10, height: 16)
        leftThigh = makeSprite(named: TextureName.thigh, size: thighSize, anchorPoint: CGPoint(x: 0.5, y: 0.9))
        leftThigh.position = leftHipBasePosition // Left hip
        leftThigh.zPosition = 0
        addChild(leftThigh)

        leftKnee = makeSprite(named: TextureName.kneeJoint, size: CGSize(width: 8, height: 8))
        leftKnee.position = CGPoint(x: 0, y: -14) // Bottom of thigh
        leftKnee.zPosition = 0.5
        leftThigh.addChild(leftKnee)

        let calfSize = CGSize(width: 9, height: 14)
        leftCalf = makeSprite(named: TextureName.calf, size: calfSize, anchorPoint: CGPoint(x: 0.5, y: 0.9))
        leftCalf.position = CGPoint(x: 0, y: -14) // At knee joint
        leftCalf.zPosition = 0
        leftThigh.addChild(leftCalf)

        leftAnkle = makeSprite(named: TextureName.ankleJoint, size: CGSize(width: 6, height: 6))
        leftAnkle.position = CGPoint(x: 0, y: -12)
        leftAnkle.zPosition = 0.6
        leftCalf.addChild(leftAnkle)

        leftFoot = makeSprite(named: TextureName.foot, size: CGSize(width: 12, height: 6))
        leftFoot.position = CGPoint(x: 0, y: -5)
        leftFoot.zPosition = 0.2
        leftAnkle.addChild(leftFoot)

        // Right Thigh - anchor at hip
        rightThigh = makeSprite(named: TextureName.thigh, size: thighSize, anchorPoint: CGPoint(x: 0.5, y: 0.9))
        rightThigh.position = rightHipBasePosition // Right hip
        rightThigh.zPosition = 0
        addChild(rightThigh)

        rightKnee = makeSprite(named: TextureName.kneeJoint, size: CGSize(width: 8, height: 8))
        rightKnee.position = CGPoint(x: 0, y: -14) // Bottom of thigh
        rightKnee.zPosition = 0.5
        rightThigh.addChild(rightKnee)

        rightCalf = makeSprite(named: TextureName.calf, size: calfSize, anchorPoint: CGPoint(x: 0.5, y: 0.9))
        rightCalf.position = CGPoint(x: 0, y: -14) // At knee joint
        rightCalf.zPosition = 0
        rightThigh.addChild(rightCalf)

        rightAnkle = makeSprite(named: TextureName.ankleJoint, size: CGSize(width: 6, height: 6))
        rightAnkle.position = CGPoint(x: 0, y: -12)
        rightAnkle.zPosition = 0.6
        rightCalf.addChild(rightAnkle)

        rightFoot = makeSprite(named: TextureName.foot, size: CGSize(width: 12, height: 6))
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
            leftKnee.isHidden = true
            rightKnee.isHidden = true
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
            helmetGlass.position = CGPoint(x: 4.2, y: 2)
            blasterOrientation = .right
        case .left:
            // No xScale mirroring - create left-facing appearance manually
            backpack.alpha = 0.75
            backpack.zPosition = 0.9
            backpack.xScale = 0.7
            backpack.position = CGPoint(x: 3, y: -2) // Flipped horizontally (positive x)
            helmetGlass.alpha = 0.85
            helmetGlass.xScale = 0.75
            helmetGlass.position = CGPoint(x: -4.2, y: 2) // Flipped horizontally (negative x)
            // Don't swap arms/legs - keep blaster in left hand and legs natural
            blasterOrientation = .left
        }
        
        blaster.update(for: blasterOrientation)
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

    func updatePlayerDirection(angle: CGFloat) {
        // Determine facing direction from aim angle (not from movement!)
        // Normalize angle to 0-2π range
        var normalizedAngle = angle.truncatingRemainder(dividingBy: 2 * .pi)
        if normalizedAngle < 0 {
            normalizedAngle += 2 * .pi
        }

        // Map to cardinal directions
        // 0° = right, 90° = up, 180° = left, 270° = down
        let newDirection: FacingDirection
        if normalizedAngle < .pi / 4 || normalizedAngle >= 7 * .pi / 4 {
            newDirection = .right
        } else if normalizedAngle >= .pi / 4 && normalizedAngle < 3 * .pi / 4 {
            newDirection = .up
        } else if normalizedAngle >= 3 * .pi / 4 && normalizedAngle < 5 * .pi / 4 {
            newDirection = .left
        } else {
            newDirection = .down
        }

        // Update facing direction (this may change xScale)
        setFacingDirection(newDirection)
    }

    private func resetLeftArmPose(manageWalkCycle: Bool, animated: Bool) {
        let duration: TimeInterval = animated ? 0.15 : 0

        rotate(leftUpperArm, to: 0, duration: duration, key: "resetUpper")
        rotate(leftForearm, to: 0, duration: duration, key: "resetFore")
        rotate(leftWrist, to: 0, duration: duration, key: "resetWrist")
        rotate(leftHand, to: 0, duration: duration, key: "resetHand")

        if manageWalkCycle {
            if action(forKey: "move") != nil {
                startWalkingAnimation()
            }
        }
    }

    private func poseLeftArmForAiming(angle: CGFloat) {
        let duration: TimeInterval = 0.08

        // Upper arm rotation - swing toward aim direction
        // Arm hangs down by default, so add π/2 offset
        let upperArmRotation = angle + .pi / 2

        // Forearm and wrist stay straight for extension
        let forearmRotation: CGFloat = 0
        let wristRotation: CGFloat = 0

        rotateForAiming(leftUpperArm, to: upperArmRotation, duration: duration, key: "aim")
        rotateForAiming(leftForearm, to: forearmRotation, duration: duration, key: "aim")
        rotateForAiming(leftWrist, to: wristRotation, duration: duration, key: "aim")
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

    private func rotateForAiming(_ node: SKNode?, to targetAngle: CGFloat, duration: TimeInterval, key: String) {
        guard let node = node else { return }
        node.removeAction(forKey: key)

        // Adjust target to be within π of current rotation to avoid going the long way
        var adjustedAngle = targetAngle
        let currentRotation = node.zRotation
        while adjustedAngle - currentRotation > .pi {
            adjustedAngle -= 2 * .pi
        }
        while adjustedAngle - currentRotation < -.pi {
            adjustedAngle += 2 * .pi
        }

        // Set rotation directly (no animation)
        node.zRotation = adjustedAngle
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

    func moveInDirection(direction: CGVector) {
        // Apply velocity directly to physics body for continuous movement
        let baseSpeed: CGFloat = 75.0
        let waterSpeedMultiplier: CGFloat = 0.5  // 50% speed in water
        let speed: CGFloat = isInWater ? baseSpeed * waterSpeedMultiplier : baseSpeed
        let velocity = CGVector(dx: direction.dx * speed, dy: direction.dy * speed)
        physicsBody?.velocity = velocity

        // Ensure rotation stays zero
        zRotation = 0

        // Determine if leg phasing should change (only matters for left vs non-left)
        let needsLeftLegLeading = facingDirection == .left
        let hadLeftLegLeading = lastWalkingDirection == .left

        // Restart animation if not walking or leg phasing changed
        if !isWalking || needsLeftLegLeading != hadLeftLegLeading {
            startWalkingAnimation()
            lastWalkingDirection = facingDirection  // Set after starting animation
        }
    }

    func stopMovement() {
        removeAction(forKey: "move")
        physicsBody?.velocity = .zero
        zRotation = 0

        // Stop walking animation
        stopWalkingAnimation()
    }

    func startFiringBlaster(at angle: CGFloat, distance: CGFloat) {
        guard !isFiring else { return }

        isFiring = true

        leftArm.forEach { node in
            // Stop walk animation for left arm
            node.removeAction(forKey: .walk)
            
            // Stop reset actions that may be running
            node.removeAction(forKey: .reset)
        }
        
        poseLeftArmForAiming(angle: angle)
        blaster.startBeam(distance: distance)
    }

    func stopFiringBlaster() {
        guard isFiring else { return }
        isFiring = false
        blaster.stopBeam()
        blaster.update(for: blasterOrientation(for: facingDirection))
        resetLeftArmPose(manageWalkCycle: true, animated: true)
    }

    func spawnBeamDebris(in scene: SKScene, count: Int) {
        blaster.spawnBeamDebris(in: scene, count: count)
    }

    var isBeamVisibleForTesting: Bool {
        blaster.isBeamVisibleForTesting
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
        let elbowBendAngle: CGFloat = .pi / -12     // ~15 degrees
        let wristFlickAngle: CGFloat = .pi / 18    // ~10 degrees
        let ankleRollAngle: CGFloat = .pi / 14     // ~13 degrees

        // Direction multiplier for leg animations - reverse when facing left
        let legDirectionMultiplier: CGFloat = facingDirection == .left ? -1 : 1

        // Phase timing: swap leading leg when facing left
        let rightLegDelay: TimeInterval = facingDirection == .left ? stepDuration * 2 : 0
        let leftLegDelay: TimeInterval = facingDirection == .left ? 0 : stepDuration * 2

        // Helper closure to repeat action forever
        func cycle(_ actions: SKAction...) -> SKAction {
            SKAction.sequence(actions)
        }

        // === RIGHT LEG ===
        let rightThighCycle = cycle(
            SKAction.rotate(toAngle: thighSwingAngle * legDirectionMultiplier, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration),
            SKAction.rotate(toAngle: -thighSwingAngle * legDirectionMultiplier, duration: stepDuration),
            SKAction.wait(forDuration: stepDuration)
        )

        let rightCalfCycle = cycle(
            SKAction.rotate(toAngle: -kneeBendAngle * legDirectionMultiplier, duration: stepDuration),
            SKAction.rotate(toAngle: -kneeBendAngle * 0.3 * legDirectionMultiplier, duration: stepDuration),
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

        // === LEFT LEG ===
        let leftThighCycle = SKAction.sequence([
            SKAction.wait(forDuration: leftLegDelay),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: thighSwingAngle * legDirectionMultiplier, duration: stepDuration),
                SKAction.wait(forDuration: stepDuration),
                SKAction.rotate(toAngle: -thighSwingAngle * legDirectionMultiplier, duration: stepDuration),
                SKAction.wait(forDuration: stepDuration)
            ))
        ])

        let leftCalfCycle = SKAction.sequence([
            SKAction.wait(forDuration: leftLegDelay),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: -kneeBendAngle * legDirectionMultiplier, duration: stepDuration),
                SKAction.rotate(toAngle: -kneeBendAngle * 0.3 * legDirectionMultiplier, duration: stepDuration),
                SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
            ))
        ])

        let leftAnkleCycle = SKAction.sequence([
            SKAction.wait(forDuration: leftLegDelay),
            SKAction.repeatForever(cycle(
                SKAction.rotate(toAngle: ankleRollAngle, duration: stepDuration),
                SKAction.rotate(toAngle: -ankleRollAngle * 0.6, duration: stepDuration),
                SKAction.rotate(toAngle: 0, duration: stepDuration * 2)
            ))
        ])

        let leftFootCycle = SKAction.sequence([
            SKAction.wait(forDuration: leftLegDelay),
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

        // Run animations with conditional delays
        let rightThighSequence = SKAction.sequence([
            SKAction.wait(forDuration: rightLegDelay),
            SKAction.repeatForever(rightThighCycle)
        ])
        let rightCalfSequence = SKAction.sequence([
            SKAction.wait(forDuration: rightLegDelay),
            SKAction.repeatForever(rightCalfCycle)
        ])
        let rightAnkleSequence = SKAction.sequence([
            SKAction.wait(forDuration: rightLegDelay),
            SKAction.repeatForever(rightAnkleCycle)
        ])
        let rightFootSequence = SKAction.sequence([
            SKAction.wait(forDuration: rightLegDelay),
            SKAction.repeatForever(rightFootCycle)
        ])

        rightThigh.run(rightThighSequence, withKey: .walk)
        rightCalf.run(rightCalfSequence, withKey: .walk)
        rightAnkle.run(rightAnkleSequence, withKey: .walk)
        rightFoot.run(rightFootSequence, withKey: .walk)

        leftUpperArm.run(SKAction.repeatForever(leftUpperArmCycle), withKey: .walk)
        leftForearm.run(SKAction.repeatForever(leftForearmCycle), withKey: .walk)
        leftWrist.run(SKAction.repeatForever(leftWristCycle), withKey: .walk)
        leftHand.run(SKAction.repeatForever(leftHandCycle), withKey: .walk)

        leftThigh.run(leftThighCycle, withKey: .walk)
        leftCalf.run(leftCalfCycle, withKey: .walk)
        leftAnkle.run(leftAnkleCycle, withKey: .walk)
        leftFoot.run(leftFootCycle, withKey: .walk)

        rightUpperArm.run(rightUpperArmCycle, withKey: .walk)
        rightForearm.run(rightForearmCycle, withKey: .walk)
        rightWrist.run(rightWristCycle, withKey: .walk)
        rightHand.run(rightHandCycle, withKey: .walk)

        isWalking = true
    }

    private func stopWalkingAnimation() {
        // Stop all limb animations
        leftThigh.removeAction(forKey: .walk)
        leftCalf.removeAction(forKey: .walk)
        leftAnkle.removeAction(forKey: .walk)
        leftFoot.removeAction(forKey: .walk)
        rightThigh.removeAction(forKey: .walk)
        rightCalf.removeAction(forKey: .walk)
        rightAnkle.removeAction(forKey: .walk)
        rightFoot.removeAction(forKey: .walk)
        leftUpperArm.removeAction(forKey: .walk)
        leftForearm.removeAction(forKey: .walk)
        leftWrist.removeAction(forKey: .walk)
        leftHand.removeAction(forKey: .walk)
        rightUpperArm.removeAction(forKey: .walk)
        rightForearm.removeAction(forKey: .walk)
        rightWrist.removeAction(forKey: .walk)
        rightHand.removeAction(forKey: .walk)

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
        leftUpperArm.run(SKAction.rotate(toAngle: 0, duration: resetDuration), withKey: .reset)
        leftForearm.run(SKAction.rotate(toAngle: 0, duration: resetDuration), withKey: .reset)
        leftWrist.run(SKAction.rotate(toAngle: 0, duration: resetDuration), withKey: .reset)
        leftHand.run(SKAction.rotate(toAngle: 0, duration: resetDuration), withKey: .reset)
        rightUpperArm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightForearm.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightWrist.run(SKAction.rotate(toAngle: 0, duration: resetDuration))
        rightHand.run(SKAction.rotate(toAngle: 0, duration: resetDuration))

        isWalking = false
        lastWalkingDirection = nil  // Reset direction tracking
    }

    // MARK: - Water State

    func setInWater(_ inWater: Bool) {
        guard inWater != isInWater else { return }
        isInWater = inWater

        // Adjust leg z-positions so they render behind water surface
        // Water surface is at absolute -9, player base is at -10
        // Lowering thigh z-position by 10 puts legs at -20 (behind water at -9)
        let legZOffset: CGFloat = inWater ? -10 : 0

        leftThigh.zPosition = legZOffset
        rightThigh.zPosition = legZOffset
    }

    // MARK: - Energy Methods

    @discardableResult
    func spendEnergy(_ amount: Int) -> Bool {
        guard currentEnergy >= amount else { return false }
        currentEnergy -= amount
        return true
    }

    func addEnergy(_ amount: Int) {
        currentEnergy = min(currentEnergy + amount, maxEnergy)
    }

    func setMaxEnergy(_ newMax: Int) {
        maxEnergy = max(1, newMax)
        currentEnergy = min(currentEnergy, maxEnergy)
    }
}

extension String {
    static var walk: String { "walk" }
    static var reset: String { "reset" }
}
