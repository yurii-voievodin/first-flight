//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit


class GameScene: SKScene {

    let astronaut = Player()
    private var gameCamera: SKCameraNode!
    private var rockFormations: [RockFormation] = []
    private var lakes: [LakeNode] = []
    private var boundaryRocks: [RockFormation] = []
    private var virtualJoystick: VirtualJoystick!

    // Debug mode flag
    var showDebugLabels: Bool = false

    // Beam damage system
    private var rocksBeingDamaged: [RockFormation: CGPoint] = [:]
    private var lastUpdateTime: TimeInterval = 0
    private let beamDamagePerSecond: CGFloat = 100

    // Particle effect system
    private var particleSpawnTimer: TimeInterval = 0
    private let particleSpawnInterval: TimeInterval = 0.04

    // Proximity targeting system
    private let sightRadius: CGFloat = 150
    private var closestRockInRange: RockFormation?
    private var currentTarget: RockFormation?
    private var sightRadiusDebugCircle: SKShapeNode?
    private var targetButton: SKShapeNode?

    override func didMove(to view: SKView) {
        setupScene()
        createCharacters()
        loadMapFromJSON()
        setupCamera()
        setupJoystick()
        setupTargetingSystem()
        updateCameraConstraints() // Apply constraints after view is available
    }

    private func setupScene() {
        // Set fixed map size of 2000x2000 for larger exploration area
        size = CGSize(width: 2000, height: 2000)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        backgroundColor = SKColor.systemGray
    }

    private func createCharacters() {
        astronaut.position = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
        addChild(astronaut)
    }

    private func loadMapFromJSON() {
        do {
            // Try to load Map1.json
            let mapData = try MapLoader.shared.loadMap(named: "Map1")

            // Update map size if different from default
            let mapSize = MapLoader.shared.getMapSize(from: mapData)
            if mapSize != self.size {
                self.size = mapSize
                setupScene() // Re-setup scene with new size
            }

            // Update player start position
            let startPosition = MapLoader.shared.getPlayerStartPosition(from: mapData)
            astronaut.position = startPosition

            // Create all rock formations from JSON
            let rocks = MapLoader.shared.createAllRocks(from: mapData)

            // Add boundary rocks
            boundaryRocks = rocks.boundary
            for rock in boundaryRocks {
                addChild(rock)
                if showDebugLabels {
                    rock.addDebugLabel()
                }
            }

            // Add interior rocks
            for rock in rocks.interior {
                addChild(rock)
                rockFormations.append(rock)
                if showDebugLabels {
                    rock.addDebugLabel()
                }
            }

            // Add signature formations
            for rock in rocks.signature {
                addChild(rock)
                rockFormations.append(rock)
                if showDebugLabels {
                    rock.addDebugLabel()
                }
            }

            // Add small decorative rocks
            let smallRocks = MapLoader.shared.createSmallRocks(from: mapData)
            for smallRock in smallRocks {
                addChild(smallRock)
            }

            lakes = MapLoader.shared.createLakes(from: mapData)
            for lake in lakes {
                addChild(lake)
            }

            // Print map info for debugging
            let mapInfo = MapLoader.shared.getMapInfo(from: mapData)
            print("Loaded map: \(mapInfo.name) v\(mapInfo.version) - \(mapInfo.description)")
            print("Total rocks: \(rocks.boundary.count) boundary, \(rocks.interior.count) interior, \(rocks.signature.count) signature, \(smallRocks.count) small")
            print("  Lakes: \(lakes.count)")

        } catch {
            print("ERROR: Failed to load Map1.json: \(error.localizedDescription)")
            print("Cannot start game without valid map data.")
            fatalError("Map loading failed - no valid map data available")
        }
    }


    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        gameCamera.position = astronaut.position
    }

    private func setupJoystick() {
        virtualJoystick = VirtualJoystick()
        virtualJoystick.zPosition = 100
        gameCamera.addChild(virtualJoystick)
        updateJoystickPosition()
    }

    private func updateJoystickPosition() {
        guard let view = view, virtualJoystick != nil else { return }

        let safeArea = view.safeAreaInsets
        let joystickRadius: CGFloat = 40
        let margin: CGFloat = 20

        let xPosition: CGFloat = 0
        let yPosition = -view.bounds.height / 2 + safeArea.bottom + joystickRadius + margin

        virtualJoystick.position = CGPoint(x: xPosition, y: yPosition)
    }

    private func setupTargetingSystem() {
        // Create debug circle for sight radius
        let circle = SKShapeNode(circleOfRadius: sightRadius)
        circle.strokeColor = SKColor.cyan.withAlphaComponent(0.1)
        circle.lineWidth = 1
        circle.fillColor = .clear
        circle.zPosition = 5
        circle.glowWidth = 1
        addChild(circle)
        sightRadiusDebugCircle = circle

        // Create target button (initially hidden)
        let button = SKShapeNode(circleOfRadius: 10)
        button.fillColor = SKColor.white.withAlphaComponent(0.2)
        button.strokeColor = SKColor.white.withAlphaComponent(0.2)
        button.lineWidth = 2
        button.zPosition = 100
        button.alpha = 0
        button.name = "targetButton"

        // Add crosshair design
        let crosshairSize: CGFloat = 6
        let horizontal = SKShapeNode(rectOf: CGSize(width: crosshairSize, height: 1))
        horizontal.fillColor = SKColor.white.withAlphaComponent(0.2)
        horizontal.strokeColor = .clear
        button.addChild(horizontal)

        let vertical = SKShapeNode(rectOf: CGSize(width: 1, height: crosshairSize))
        vertical.fillColor = SKColor.white.withAlphaComponent(0.2)
        vertical.strokeColor = .clear
        button.addChild(vertical)

        addChild(button)
        targetButton = button
    }

    private func updateProximityDetection() {
        let playerPos = astronaut.position

        // Update debug circle position
        sightRadiusDebugCircle?.position = playerPos

        // Find closest rock within sight radius (check both interior and boundary rocks)
        var closestRock: RockFormation?
        var closestDistance: CGFloat = CGFloat.infinity

        let allTargetableRocks = rockFormations + boundaryRocks

        for rock in allTargetableRocks {
            let rockPos = rock.position
            let dx = rockPos.x - playerPos.x
            let dy = rockPos.y - playerPos.y
            let distanceToCenter = hypot(dx, dy)

            // Calculate rock's effective radius from its bounding box
            var rockRadius: CGFloat = 0
            if let path = rock.path {
                let boundingBox = path.boundingBox
                rockRadius = (boundingBox.width + boundingBox.height) / 4
            }

            // Effective distance = distance to edge, not center
            let effectiveDistance = distanceToCenter - rockRadius

            if effectiveDistance < sightRadius && effectiveDistance < closestDistance {
                closestDistance = effectiveDistance
                closestRock = rock
            }
        }

        // Update closest rock tracking
        if closestRock !== closestRockInRange {
            closestRockInRange = closestRock
            updateTargetButton()
        }

        // If we have a target and it's destroyed, clear it
        if let target = currentTarget, target.parent == nil {
            stopFiringAtTarget()
        }
    }

    private func updateTargetButton() {
        guard let button = targetButton else { return }

        if let rock = closestRockInRange {
            // Position button at visual center of rock
            if let path = rock.path {
                let boundingBox = path.boundingBox
                button.position = CGPoint(
                    x: rock.position.x + boundingBox.midX,
                    y: rock.position.y + boundingBox.midY
                )
            } else {
                button.position = rock.position
            }

            // Show button with animation
            if button.alpha == 0 {
                button.run(SKAction.fadeIn(withDuration: 0.2))
            }
        } else {
            // Hide button
            if button.alpha > 0 {
                button.run(SKAction.fadeOut(withDuration: 0.15))
            }
        }
    }

    private func startFiringAtTarget(_ rock: RockFormation) {
        currentTarget = rock

        // Calculate rock's visual center (same as target button positioning)
        var targetPosition = rock.position
        if let path = rock.path {
            let boundingBox = path.boundingBox
            targetPosition = CGPoint(
                x: rock.position.x + boundingBox.midX,
                y: rock.position.y + boundingBox.midY
            )
        }

        // Calculate angle from player to rock center
        let dx = targetPosition.x - astronaut.position.x
        let dy = targetPosition.y - astronaut.position.y
        let angle = atan2(dy, dx)

        astronaut.startFiringBlaster(at: angle)
    }

    private func stopFiringAtTarget() {
        currentTarget = nil
        astronaut.stopFiringBlaster()
    }

    // MARK: - Touch Handling for Target Button

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if tap hit the target button
        if let button = targetButton,
           button.alpha > 0,
           let rock = closestRockInRange {
            let buttonFrame = button.frame
            if buttonFrame.contains(location) {
                startFiringAtTarget(rock)
                return
            }
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateJoystickPosition()
    }

    private func updateCameraConstraints() {
        guard let view = view, gameCamera != nil else { return }

        // Account for viewport size when constraining camera position
        let viewportWidth = view.bounds.width
        let viewportHeight = view.bounds.height

        // Camera position must be constrained so viewport edges don't exceed scene bounds
        let xRange = SKRange(lowerLimit: viewportWidth / 2, upperLimit: size.width - viewportWidth / 2)
        let yRange = SKRange(lowerLimit: viewportHeight / 2, upperLimit: size.height - viewportHeight / 2)
        let edgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        edgeConstraint.referenceNode = self

        gameCamera.constraints = [edgeConstraint]
    }

    override func update(_ currentTime: TimeInterval) {
        // Calculate delta time
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        updateProximityDetection()
        updateCharacterMovement(deltaTime: currentTime)
        updateCamera()
        updateRockDamage(deltaTime: deltaTime)
    }

    private func updateRockDamage(deltaTime: TimeInterval) {
        guard deltaTime > 0, !rocksBeingDamaged.isEmpty else { return }

        let damage = beamDamagePerSecond * CGFloat(deltaTime)
        var rocksToDestroy: [RockFormation] = []

        for (rock, _) in rocksBeingDamaged {
            if rock.applyDamage(damage) {
                rocksToDestroy.append(rock)
            }
        }

        for rock in rocksToDestroy {
            rocksBeingDamaged.removeValue(forKey: rock)
            destroyRock(rock)
        }

        // Spawn impact particles while damaging rocks
        particleSpawnTimer += deltaTime
        if particleSpawnTimer >= particleSpawnInterval {
            particleSpawnTimer = 0
            for (_, impactPoint) in rocksBeingDamaged {
                spawnImpactParticles(at: impactPoint)
            }
        }
    }

    private func updateCharacterMovement(deltaTime: TimeInterval) {
        let direction = virtualJoystick.currentDirection
        let player = astronaut
        
        guard let aimAngle = virtualJoystick.currentAngle else {
            // Joystick released - hide sight and stop
            player.stopMovement()
            return
        }

        // Only update aim sight from joystick if not targeting a rock
        if currentTarget == nil {
            player.updateAimSight(angle: aimAngle)
        }

        // Check joystick magnitude to decide between aiming and moving
        let magnitude = hypot(direction.dx, direction.dy)
        let movementThreshold: CGFloat = 0.5 // 50% of max joystick distance
        
        if magnitude > movementThreshold || player.isWalking {
            // Movement detected - stop firing at target if active
            if currentTarget != nil {
                stopFiringAtTarget()
            }

            // Strong joystick push or already walking - move player
            player.moveInDirection(direction: direction)
        } else {
            // Light joystick touch - just aim, don't move
            player.stopMovement()
        }
    }

    private func updateCamera() {
        // Simply follow the player - SKConstraint will handle bounds
        let currentX = gameCamera.position.x
        let currentY = gameCamera.position.y
        let lerpFactor: CGFloat = 0.1

        let newX = currentX + (astronaut.position.x - currentX) * lerpFactor
        let newY = currentY + (astronaut.position.y - currentY) * lerpFactor

        gameCamera.position = CGPoint(x: newX, y: newY)
    }

}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        // Debug logging
        print("🔵 COLLISION DETECTED:")
        print("  Body A: \(contact.bodyA.categoryBitMask) (\(categoryName(contact.bodyA.categoryBitMask)))")
        print("  Body B: \(contact.bodyB.categoryBitMask) (\(categoryName(contact.bodyB.categoryBitMask)))")
        print("  Combined: \(collision)")

        // Check if player collided with wall or rock
        if collision == PhysicsCategory.player | PhysicsCategory.wall ||
           collision == PhysicsCategory.player | PhysicsCategory.rock {
            print("  ➡️ Player collision - stopping movement")
            astronaut.stopMovement()
        }

        // Check if blaster beam hit a rock - start tracking damage
        if collision == PhysicsCategory.blasterBeam | PhysicsCategory.rock {
            print("  ➡️ Beam-Rock collision detected!")
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB

            if let rock = rockBody.node as? RockFormation {
                print("  ✅ Starting damage on rock (strength: \(rock.currentStrength))")
                print("  📍 Contact point: \(contact.contactPoint)")
                rocksBeingDamaged[rock] = contact.contactPoint
            } else {
                print("  ❌ Rock node not found")
            }
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        // Check if blaster beam stopped hitting a rock
        if collision == PhysicsCategory.blasterBeam | PhysicsCategory.rock {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB

            if let rock = rockBody.node as? RockFormation {
                rocksBeingDamaged.removeValue(forKey: rock)
            }
        }
    }

    private func categoryName(_ category: UInt32) -> String {
        switch category {
        case PhysicsCategory.player: return "Player"
        case PhysicsCategory.wall: return "Wall"
        case PhysicsCategory.rock: return "Rock"
        case PhysicsCategory.terrain: return "Terrain"
        case PhysicsCategory.blasterBeam: return "BlasterBeam"
        default: return "Unknown(\(category))"
        }
    }

    // MARK: - Impact Particle Effects

    private func spawnImpactParticles(at impactPoint: CGPoint) {
        // Spawn 2-3 debris particles
        for _ in 0..<Int.random(in: 2...3) {
            spawnDebrisParticle(at: impactPoint)
        }

        // Spawn 1-2 energy particles
        for _ in 0..<Int.random(in: 1...2) {
            spawnEnergyParticle(at: impactPoint)
        }
    }

    private func spawnDebrisParticle(at position: CGPoint) {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
        particle.fillColor = SKColor.brown.withAlphaComponent(0.9)
        particle.strokeColor = .clear
        particle.position = position
        particle.zPosition = 50
        addChild(particle)

        // Random velocity outward with gravity effect
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let speed = CGFloat.random(in: 30...60)
        let dx = cos(angle) * speed
        let dy = sin(angle) * speed

        let move = SKAction.move(by: CGVector(dx: dx, dy: dy - 40), duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        let group = SKAction.group([move, fade])
        let remove = SKAction.removeFromParent()
        particle.run(SKAction.sequence([group, remove]))
    }

    private func spawnEnergyParticle(at position: CGPoint) {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
        particle.fillColor = SKColor.cyan
        particle.strokeColor = .clear
        particle.blendMode = .add
        particle.position = position
        particle.zPosition = 51
        addChild(particle)

        // Fast outward movement
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let speed = CGFloat.random(in: 50...90)
        let dx = cos(angle) * speed
        let dy = sin(angle) * speed

        let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.25)
        let fade = SKAction.fadeOut(withDuration: 0.25)
        let scale = SKAction.scale(to: 0.3, duration: 0.25)
        let group = SKAction.group([move, fade, scale])
        let remove = SKAction.removeFromParent()
        particle.run(SKAction.sequence([group, remove]))
    }

    private func destroyRock(_ rock: RockFormation) {
        // Remove from rockFormations array
        if let index = rockFormations.firstIndex(of: rock) {
            rockFormations.remove(at: index)
        }

        // Create destruction animation
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])

        rock.run(sequence)
    }
}
