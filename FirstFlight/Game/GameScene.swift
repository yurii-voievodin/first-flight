//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit


class GameScene: SKScene {

    private var player: Player!
    private var gameCamera: SKCameraNode!
    private var walls: [SKSpriteNode] = []
    private var rockFormations: [RockFormation] = []
    private var boundaryRocks: [RockFormation] = []

    override func didMove(to view: SKView) {
        setupScene()
        createPlayer()
        loadMapFromJSON()
        setupCamera()
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

    private func createPlayer() {
        player = Player()
        // Initial position will be updated by loadMapFromJSON()
        player.position = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
        addChild(player)
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
            player.position = startPosition

            // Create all rock formations from JSON
            let rocks = MapLoader.shared.createAllRocks(from: mapData)

            // Add boundary rocks
            boundaryRocks = rocks.boundary
            for rock in boundaryRocks {
                addChild(rock)
            }

            // Add interior rocks
            for rock in rocks.interior {
                addChild(rock)
                rockFormations.append(rock)
            }

            // Add signature formations
            for rock in rocks.signature {
                addChild(rock)
                rockFormations.append(rock)
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

        gameCamera.position = player.position
    }

    func touchDown(atPoint pos : CGPoint) {
        // Конвертуємо координати дотику з екрана в світові координати сцени
        let worldPos = convertPoint(fromView: pos)
        player.moveTo(position: worldPos)
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
        guard let view = view else { return }

        let targetX = player.position.x
        let targetY = player.position.y

        // Розмір області перегляду (viewport)
        let viewportWidth = view.bounds.width
        let viewportHeight = view.bounds.height

        // Обмеження камери в межах сцени
        let minX = viewportWidth / 2
        let maxX = size.width - viewportWidth / 2
        let minY = viewportHeight / 2
        let maxY = size.height - viewportHeight / 2

        // Якщо сцена менша за viewport, центруємо камеру
        let clampedX = size.width > viewportWidth ? max(minX, min(maxX, targetX)) : size.width / 2
        let clampedY = size.height > viewportHeight ? max(minY, min(maxY, targetY)) : size.height / 2

        // Плавний рух камери
        let currentX = gameCamera.position.x
        let currentY = gameCamera.position.y
        let lerpFactor: CGFloat = 0.1

        let newX = currentX + (clampedX - currentX) * lerpFactor
        let newY = currentY + (clampedY - currentY) * lerpFactor

        gameCamera.position = CGPoint(x: newX, y: newY)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Обробка колізій між персонажем і стінами
    }
}
