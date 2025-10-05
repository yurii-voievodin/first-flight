//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit

fileprivate protocol ControllableEntity: AnyObject {
    func moveTo(position: CGPoint)
    func stopMovement()
}

extension Player: ControllableEntity {}
extension Spider: ControllableEntity {}


class GameScene: SKScene {

    private enum CharacterSelection {
        case astronaut
        case spider
    }

    private var astronaut: Player!
    private var spiderCharacter: Spider!
    private var activeCharacter: (SKNode & ControllableEntity)?
    private var activeSelection: CharacterSelection = .astronaut
    private var gameCamera: SKCameraNode!
    private var walls: [SKSpriteNode] = []
    private var rockFormations: [RockFormation] = []
    private var boundaryRocks: [RockFormation] = []

    // Debug mode flag
    var showDebugLabels: Bool = false

    override func didMove(to view: SKView) {
        setupScene()
        createCharacters()
        loadMapFromJSON()
        setupCamera()
        updateCameraConstraints() // Apply constraints after view is available
    }

    private func setupScene() {
        // Set fixed map size of 2000x2000 for larger exploration area
        size = CGSize(width: 2000, height: 2000)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        // Set background to grey (this will be the color outside map walls)
        backgroundColor = SKColor.systemGray4

        // Create a large grey background that extends beyond scene bounds
        let largeBackgroundSize = CGSize(width: size.width * 2, height: size.height * 2)
        let largeBackground = SKSpriteNode(color: .systemGray4, size: largeBackgroundSize)
        largeBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        largeBackground.zPosition = -100
        addChild(largeBackground)
    }

    private func createCharacters() {
        astronaut = Player()
        astronaut.position = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
        addChild(astronaut)
        activeCharacter = astronaut
        activeSelection = .astronaut

        spiderCharacter = Spider()
        spiderCharacter.zPosition = astronaut.zPosition
        spiderCharacter.position = astronaut.position
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
            spiderCharacter.position = startPosition

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

            // Print map info for debugging
            let mapInfo = MapLoader.shared.getMapInfo(from: mapData)
            print("Loaded map: \(mapInfo.name) v\(mapInfo.version) - \(mapInfo.description)")
            print("Total rocks: \(rocks.boundary.count) boundary, \(rocks.interior.count) interior, \(rocks.signature.count) signature")

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

        if let activeCharacter = activeCharacter {
            gameCamera.position = activeCharacter.position
        }
    }

    private func updateCameraConstraints() {
        guard let view = view else { return }

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

    func touchDown(atPoint pos : CGPoint) {
        // Конвертуємо координати дотику з екрана в світові координати сцени
        let worldPos = convertPoint(fromView: pos)
        activeCharacter?.moveTo(position: worldPos)

        // Show tap indicator
        showTapIndicator(at: worldPos)
    }

    func toggleCharacterSelection() {
        guard activeCharacter != nil else { return }
        let nextSelection: CharacterSelection = activeSelection == .astronaut ? .spider : .astronaut
        switchToCharacter(nextSelection)
    }

    var toggleButtonTitle: String {
        "⇄"
    }

    var isBlasterAvailable: Bool {
        activeSelection == .astronaut
    }

    func beginBlasterBeam() {
        guard activeSelection == .astronaut, let astronaut else { return }
        astronaut.startFiringBlaster()
    }

    func endBlasterBeam() {
        guard let astronaut else { return }
        astronaut.stopFiringBlaster()
    }

    private func showTapIndicator(at position: CGPoint) {
        let radius: CGFloat = 20.0 // Match player size
        let circlePath = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)

        let indicator = SKShapeNode(path: circlePath)
        indicator.fillColor = .white.withAlphaComponent(0.5)
        indicator.strokeColor = .clear
        indicator.position = position
        indicator.zPosition = 10 // Above most elements

        addChild(indicator)

        // Fade out and remove
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])

        indicator.run(sequence)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if let view = view {
                self.touchDown(atPoint: t.location(in: view))
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        updateCamera()
    }

    private func updateCamera() {
        // Simply follow the player - SKConstraint will handle bounds
        let currentX = gameCamera.position.x
        let currentY = gameCamera.position.y
        let lerpFactor: CGFloat = 0.1

        guard let activeCharacter = activeCharacter else { return }

        let newX = currentX + (activeCharacter.position.x - currentX) * lerpFactor
        let newY = currentY + (activeCharacter.position.y - currentY) * lerpFactor

        gameCamera.position = CGPoint(x: newX, y: newY)
    }

    private func switchToCharacter(_ selection: CharacterSelection) {
        guard selection != activeSelection else { return }
        guard let currentCharacter = activeCharacter else { return }

        if activeSelection == .astronaut, let astronaut {
            astronaut.stopFiringBlaster()
        }

        let currentPosition = currentCharacter.position
        currentCharacter.stopMovement()
        currentCharacter.removeFromParent()

        let newCharacter = character(for: selection)
        newCharacter.position = currentPosition
        addChild(newCharacter)
        activeCharacter = newCharacter
        activeSelection = selection
        activeCharacter?.stopMovement()
        gameCamera?.position = currentPosition
    }

    private func character(for selection: CharacterSelection) -> (SKNode & ControllableEntity) {
        switch selection {
        case .astronaut:
            return astronaut
        case .spider:
            return spiderCharacter
        }
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
            activeCharacter?.stopMovement()
        }

        // Check if blaster beam hit a rock
        if collision == PhysicsCategory.blasterBeam | PhysicsCategory.rock {
            print("  ➡️ Beam-Rock collision detected!")
            // Determine which body is the rock
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB

            // Get the rock node
            if let rock = rockBody.node as? RockFormation {
                print("  ✅ Destroying rock")
                destroyRock(rock)
            } else {
                print("  ❌ Rock node not found")
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
