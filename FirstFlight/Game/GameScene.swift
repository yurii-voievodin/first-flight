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
    private var boundaryRocks: [RockFormation] = []
    private var virtualJoystick: VirtualJoystick!

    // Debug mode flag
    var showDebugLabels: Bool = false

    // Beam damage system
    private var rocksBeingDamaged: Set<RockFormation> = []
    private var lastUpdateTime: TimeInterval = 0
    private let beamDamagePerSecond: CGFloat = 100

    override func didMove(to view: SKView) {
        setupScene()
        createCharacters()
        loadMapFromJSON()
        setupCamera()
        setupJoystick()
        updateCameraConstraints() // Apply constraints after view is available
    }

    private func setupScene() {
        // Set fixed map size of 2000x2000 for larger exploration area
        size = CGSize(width: 2000, height: 2000)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        // Set background
        backgroundColor = SKColor.systemGray4

        // Create a large grey background that extends beyond scene bounds
        let largeBackgroundSize = CGSize(width: size.width * 2, height: size.height * 2)
        let largeBackground = SKSpriteNode(color: .systemGray4, size: largeBackgroundSize)
        largeBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        largeBackground.zPosition = -100
        addChild(largeBackground)
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

            // Print map info for debugging
            let mapInfo = MapLoader.shared.getMapInfo(from: mapData)
            print("Loaded map: \(mapInfo.name) v\(mapInfo.version) - \(mapInfo.description)")
            print("Total rocks: \(rocks.boundary.count) boundary, \(rocks.interior.count) interior, \(rocks.signature.count) signature, \(smallRocks.count) small")

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

        let xPosition = -view.bounds.width / 2 + safeArea.left + joystickRadius + margin
        let yPosition = -view.bounds.height / 2 + safeArea.bottom + joystickRadius + margin

        virtualJoystick.position = CGPoint(x: xPosition, y: yPosition)
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

        updateCharacterMovement(deltaTime: currentTime)
        updateCamera()
        updateRockDamage(deltaTime: deltaTime)
    }

    private func updateRockDamage(deltaTime: TimeInterval) {
        guard deltaTime > 0, !rocksBeingDamaged.isEmpty else { return }

        let damage = beamDamagePerSecond * CGFloat(deltaTime)
        var rocksToDestroy: [RockFormation] = []

        for rock in rocksBeingDamaged {
            if rock.applyDamage(damage) {
                rocksToDestroy.append(rock)
            }
        }

        for rock in rocksToDestroy {
            rocksBeingDamaged.remove(rock)
            destroyRock(rock)
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
        // Joystick is active - always update sight position
        player.updateAimSight(angle: aimAngle)
        
        // Check joystick magnitude to decide between aiming and moving
        let magnitude = hypot(direction.dx, direction.dy)
        let movementThreshold: CGFloat = 0.5 // 50% of max joystick distance
        
        if magnitude > movementThreshold || player.isWalking {
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
                rocksBeingDamaged.insert(rock)
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
                print("  🛑 Beam stopped hitting rock")
                rocksBeingDamaged.remove(rock)
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
