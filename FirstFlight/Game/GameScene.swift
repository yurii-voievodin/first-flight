//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit

final class GameScene: SKScene {

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
    private let debrisTexture = RockTextures.shared.baseTexture(for: .boulder, seed: 42)

    // Proximity targeting system
    private let sightRadius: CGFloat = 150
    private var closestRockInRange: RockFormation?
    private var currentTarget: RockFormation?
    
    private var tileSet: SKTileSet!

    // Tile grid configuration (source of truth)
    private var tileSize: CGFloat = 128
    private var tileColumns: Int = 0
    private var tileRows: Int = 0

    override func didMove(to view: SKView) {
        setupScene()
        loadMapFromJSON()          // reads tileGrid and sets scene size
        generateTerrainTextures()  // uses fixed tileSize
        setupTileMap()             // uses columns/rows from JSON
        createCharacters()
        setupCamera()
        setupJoystick()
        updateCameraConstraints() // Apply constraints after view is available
    }

    private func setupScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor.systemGray
    }

    private func createCharacters() {
        // Position is set by loadMapFromJSON() (playerStartPosition)
        if astronaut.parent == nil {
            addChild(astronaut)
        }
    }
    
    private func generateTerrainTextures() {
        let factory = TerrainTextureFactory()
        
        var groups: [SKTileGroup] = []
        
        for _ in 0..<12 {
            let texture = factory.makeRockWithDustTexture(
                TerrainTextureFactory.Params(size: Int(tileSize), dustAmount: Float.random(in: 0.3...0.7))
            )
            
            let def = SKTileDefinition(texture: texture)
            let rule = SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: [def])
            let group = SKTileGroup(rules: [rule])
            groups.append(group)
        }
        
        tileSet = SKTileSet(tileGroups: groups)
    }
    
    private func setupTileMap() {
        guard tileSet != nil, tileColumns > 0, tileRows > 0 else { return }

        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: tileColumns,
            rows: tileRows,
            tileSize: CGSize(width: tileSize, height: tileSize)
        )

        tileMap.name = "ground"
        tileMap.zPosition = -100
        tileMap.anchorPoint = CGPoint(x: 0, y: 0)
        tileMap.position = .zero

        let groups = tileSet.tileGroups
        for c in 0..<tileColumns {
            for r in 0..<tileRows {
                tileMap.setTileGroup(groups.randomElement(), forColumn: c, row: r)
            }
        }

        addChild(tileMap)
    }


    /// Deterministic, cheap fBm-ish noise in [0, 1].
    private func fbmNoise(x: Int, y: Int, seed: UInt32) -> CGFloat {
        // 3 octaves of value noise
        let n1 = valueNoise(x: x, y: y, seed: seed, scale: 1)
        let n2 = valueNoise(x: x, y: y, seed: seed &+ 101, scale: 2)
        let n3 = valueNoise(x: x, y: y, seed: seed &+ 202, scale: 4)

        // Weighted sum (normalized)
        let v = (0.55 * n1) + (0.30 * n2) + (0.15 * n3)
        return min(1, max(0, v))
    }

    /// Deterministic value noise sampled on a grid (nearest, with implicit clustering via scale).
    private func valueNoise(x: Int, y: Int, seed: UInt32, scale: Int) -> CGFloat {
        let sx = x / max(1, scale)
        let sy = y / max(1, scale)

        let ux = UInt32(truncatingIfNeeded: sx)
        let uy = UInt32(truncatingIfNeeded: sy)

        // Hash (sx, sy, seed) -> [0,1) using wrapping 32-bit arithmetic
        var h = (ux &* 374761393) &+ (uy &* 668265263)
        h = h &+ seed &* 1442695041
        h ^= h >> 13
        h &*= 1274126177
        h ^= h >> 16

        return CGFloat(Double(h % 10_000) / 10_000.0)
    }

    private func loadMapFromJSON() {
        do {
            // Try to load Map1.json
            let mapData = try MapLoader.shared.loadMap(named: "Map1")

            // Read tile grid configuration (fixed tile size, grid defines map size)
            let grid = MapLoader.shared.getTileGrid(from: mapData)
            tileSize = CGFloat(grid.tileSize)
            tileColumns = grid.columns
            tileRows = grid.rows

            // Scene size is derived strictly from the tile grid
            size = CGSize(
                width: CGFloat(tileColumns) * tileSize,
                height: CGFloat(tileRows) * tileSize
            )
            print("🗺️ TileGrid loaded:")
            print("  tileSize: \(tileSize)")
            print("  columns: \(tileColumns), rows: \(tileRows)")
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

    private func updateProximityDetection() {
        let playerPos = astronaut.position

        // Find closest rock within sight radius (check both interior and boundary rocks)
        var closestRock: RockFormation?
        var closestDistance: CGFloat = CGFloat.infinity

        let allTargetableRocks = rockFormations + boundaryRocks

        for rock in allTargetableRocks {
            let rockPos = rock.position
            let dx = rockPos.x - playerPos.x
            let dy = rockPos.y - playerPos.y
            let distanceToCenter = hypot(dx, dy)

            // Effective distance = distance to edge, not center
            let effectiveDistance = distanceToCenter - rock.maxRadius

            if effectiveDistance < sightRadius && effectiveDistance < closestDistance {
                closestDistance = effectiveDistance
                closestRock = rock
            }
        }

        // Update closest rock tracking
        if closestRock !== closestRockInRange {
            // Hide indicator on previous rock
            closestRockInRange?.isCircleIndicatorVisible = false
            // Show indicator on new closest rock
            closestRock?.isCircleIndicatorVisible = true
            closestRockInRange = closestRock
        }

        // If we have a target and it's destroyed, clear it
        if let target = currentTarget, target.parent == nil {
            stopFiringAtTarget()
        }
    }

    private func startFiringAtTarget(_ rock: RockFormation) {
        currentTarget = rock

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
        currentTarget = nil
        rocksBeingDamaged.removeAll()
        astronaut.stopFiringBlaster()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if tap hit a highlighted rock
        let tappedNodes = nodes(at: location)
        for node in tappedNodes {
            if let rock = node as? RockFormation,
               rock.isCircleIndicatorVisible {
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

        // Create destruction animation
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])

        rock.run(sequence)
    }
}
