//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit

final class GameScene: SKScene {

    private let astronaut = Player()
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
    private let debrisTexture = RockTextures.shared.baseTexture(for: .boulder, seed: 42)

    // Targeting system
    private var currentTarget: RockFormation?
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private var hapticTimer: Timer?

    override func didMove(to view: SKView) {
        setupScene()
        loadMapFromJSON()
        createCharacters()
        setupCamera()
        setupJoystick()
        updateCameraConstraints()
    }

    private func setupScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }

    private func createCharacters() {
        // Position is set by loadMapFromJSON() (playerStartPosition)
        if astronaut.parent == nil {
            addChild(astronaut)
        }
    }
    
    private func loadMapFromJSON() {
        do {
            // Try to load Map1.json
            let mapData = try MapLoader.shared.loadMap(named: "Map1")

            // Create tile map from grid configuration
            let grid = MapLoader.shared.getTileGrid(from: mapData)
            let tileMap = TileMap(grid: grid)

            // Scene size is derived from the tile map
            size = CGSize(
                width: CGFloat(tileMap.tileColumns) * tileMap.tileSize,
                height: CGFloat(tileMap.tileRows) * tileMap.tileSize
            )

            // Add tile map node to scene
            addChild(tileMap.createNode())

            print("Loaded:")
            print("  tileSize: \(tileMap.tileSize)")
            print("  columns: \(tileMap.tileColumns), rows: \(tileMap.tileRows)")
            print("  scene.size: \(size)")

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

    private func startFiringAtTarget(_ rock: RockFormation) {
        currentTarget = rock

        // Start haptic feedback
        impactFeedback.prepare()
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.impactFeedback.impactOccurred()
        }

        // Calculate angle from player to rock center
        let targetPosition = rock.centerPosition
        let dx = targetPosition.x - astronaut.position.x
        let dy = targetPosition.y - astronaut.position.y
        let angle = atan2(dy, dx)

        // Calculate distance from player to rock edge
        let distanceToCenter = hypot(dx, dy)
        let distanceToEdge = distanceToCenter - rock.maxRadius

        astronaut.startFiringBlaster(at: angle, distance: distanceToEdge)
    }

    private func stopFiringAtTarget() {
        // Stop haptic feedback
        hapticTimer?.invalidate()
        hapticTimer = nil

        currentTarget = nil
        rocksBeingDamaged.removeAll()
        astronaut.stopFiringBlaster()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if tap hit a rock
        let tappedNodes = nodes(at: location)
        for node in tappedNodes {
            if let rock = node as? RockFormation {
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

        // Clear target if it's destroyed
        if let target = currentTarget, target.parent == nil {
            stopFiringAtTarget()
        }

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
            player.updatePlayerDirection(angle: aimAngle)
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
    }

    private func spawnDebrisParticle(at position: CGPoint) {
        let size = CGFloat.random(in: 4...8)
        let particle = SKSpriteNode(texture: debrisTexture, size: CGSize(width: size, height: size))
        particle.color = SKColor(white: 0.7, alpha: 1.0)
        particle.colorBlendFactor = 0.35
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

    private func destroyRock(_ rock: RockFormation) {
        // Remove from rockFormations array
        if let index = rockFormations.firstIndex(of: rock) {
            rockFormations.remove(at: index)
        }

        // Clear target/indicator state if needed
        if currentTarget === rock {
            stopFiringAtTarget()
        }

        // Spawn destruction particles
        rock.spawnDestructionParticles(in: self)

        // Camera shake if near the player
        let center = rock.centerPosition
        if hypot(center.x - astronaut.position.x, center.y - astronaut.position.y) < 220 {
            let camShake = SKAction.customAction(withDuration: 0.15) { [weak self] _, t in
                guard let self, let cam = self.gameCamera else { return }
                let k = 1.0 - (t / 0.15)
                cam.position.x += CGFloat.random(in: -2...2) * k
                cam.position.y += CGFloat.random(in: -2...2) * k
            }
            gameCamera.run(camShake)
        }

        // Perform destruction animation
        rock.performDestructionAnimation { }
    }
}
