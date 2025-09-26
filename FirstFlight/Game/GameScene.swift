//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit
import GameplayKit


class GameScene: SKScene {

    private var player: Player!
    private var gameCamera: SKCameraNode!
    private var walls: [SKSpriteNode] = []
    private var rockFormations: [RockFormation] = []

    override func didMove(to view: SKView) {
        setupScene()
        createPlayer()
        createWalls()
        createRockFormations()
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

        // Create playable area background (mint color) inside the walls
        let playableAreaSize = CGSize(width: size.width - 20, height: size.height - 20) // Account for wall thickness
        let playableBackground = SKSpriteNode(color: .systemMint, size: playableAreaSize)
        playableBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        playableBackground.zPosition = -50
        addChild(playableBackground)
    }

    private func createPlayer() {
        player = Player()
        // Start player closer to center of the larger map for better exploration
        player.position = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
        addChild(player)
    }

    private func createWalls() {
        // Create boundary walls around the entire 2000x2000 map
        let wallThickness: CGFloat = 10

        // Bottom wall
        let bottomWall = SKSpriteNode(color: .systemBrown, size: CGSize(width: size.width, height: wallThickness))
        bottomWall.position = CGPoint(x: size.width / 2, y: wallThickness / 2)
        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: bottomWall.size)
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        bottomWall.physicsBody?.isDynamic = false
        addChild(bottomWall)
        walls.append(bottomWall)

        // Top wall
        let topWall = SKSpriteNode(color: .systemBrown, size: CGSize(width: size.width, height: wallThickness))
        topWall.position = CGPoint(x: size.width / 2, y: size.height - wallThickness / 2)
        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        topWall.physicsBody?.isDynamic = false
        addChild(topWall)
        walls.append(topWall)

        // Left wall
        let leftWall = SKSpriteNode(color: .systemBrown, size: CGSize(width: wallThickness, height: size.height))
        leftWall.position = CGPoint(x: wallThickness / 2, y: size.height / 2)
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.size)
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        leftWall.physicsBody?.isDynamic = false
        addChild(leftWall)
        walls.append(leftWall)

        // Right wall
        let rightWall = SKSpriteNode(color: .systemBrown, size: CGSize(width: wallThickness, height: size.height))
        rightWall.position = CGPoint(x: size.width - wallThickness / 2, y: size.height / 2)
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.size)
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        rightWall.physicsBody?.isDynamic = false
        addChild(rightWall)
        walls.append(rightWall)

    }

    private func createRockFormations() {
        // Create diverse rock formations across the map
        let mapArea = CGRect(x: 100, y: 100, width: size.width - 200, height: size.height - 200)

        // Generate natural rock placements using the terrain generator
        let placements = TerrainGenerator.shared.generateNaturalRockPlacements(in: mapArea, density: 0.25)

        for placement in placements {
            let rock = RockFormation(type: placement.type, size: placement.size, position: placement.position)
            addChild(rock)
            rockFormations.append(rock)
        }

        // Add some specific interesting formations manually
        createSignatureRockFormations()
    }

    private func createSignatureRockFormations() {
        // Large cave system in the center-north area
        let caveSystem = RockFormation(type: .cave, size: CGSize(width: 300, height: 200), position: CGPoint(x: 1000, y: 1400))
        addChild(caveSystem)
        rockFormations.append(caveSystem)

        // Dramatic overhang in the west
        let overhang = RockFormation(type: .overhang, size: CGSize(width: 250, height: 180), position: CGPoint(x: 400, y: 1000))
        addChild(overhang)
        rockFormations.append(overhang)

        // Rock cluster creating a natural maze in the east
        let cluster1 = RockFormation(type: .cluster, size: CGSize(width: 200, height: 150), position: CGPoint(x: 1600, y: 800))
        let cluster2 = RockFormation(type: .cluster, size: CGSize(width: 180, height: 160), position: CGPoint(x: 1500, y: 600))
        let cluster3 = RockFormation(type: .cluster, size: CGSize(width: 220, height: 140), position: CGPoint(x: 1700, y: 650))

        addChild(cluster1)
        addChild(cluster2)
        addChild(cluster3)
        rockFormations.append(contentsOf: [cluster1, cluster2, cluster3])

        // Tall spires creating landmark navigation points
        let spire1 = RockFormation(type: .spire, size: CGSize(width: 80, height: 300), position: CGPoint(x: 600, y: 600))
        let spire2 = RockFormation(type: .spire, size: CGSize(width: 90, height: 280), position: CGPoint(x: 1200, y: 1200))

        addChild(spire1)
        addChild(spire2)
        rockFormations.append(contentsOf: [spire1, spire2])
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
