//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit
import GameplayKit

class Player: SKShapeNode {
    private let walkingSpeed: CGFloat = 120.0 // points per second
    private let radius: CGFloat = 20.0

    override init() {
        super.init()

        // Create circular path
        let circlePath = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circlePath
        self.fillColor = .white
        self.strokeColor = .clear

        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPhysics()
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.wall
        physicsBody?.collisionBitMask = PhysicsCategory.wall
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.1
    }

    func moveTo(position: CGPoint) {
        // Calculate distance to target position
        let currentPosition = self.position
        let deltaX = position.x - currentPosition.x
        let deltaY = position.y - currentPosition.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)

        // Calculate duration based on walking speed (distance / speed)
        let duration = TimeInterval(distance / walkingSpeed)

        // Create move action with calculated duration and linear timing
        let moveAction = SKAction.move(to: position, duration: duration)
        moveAction.timingMode = .linear
        run(moveAction)
    }
}

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let wall: UInt32 = 0b10
}

class GameScene: SKScene {

    private var player: Player!
    private var gameCamera: SKCameraNode!
    private var walls: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        setupScene()
        createPlayer()
        createWalls()
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

        // Add obstacles distributed across the larger map
        createObstacle(at: CGPoint(x: 400, y: 300), size: CGSize(width: 150, height: 40))
        createObstacle(at: CGPoint(x: 800, y: 600), size: CGSize(width: 200, height: 30))
        createObstacle(at: CGPoint(x: 1200, y: 400), size: CGSize(width: 180, height: 50))
        createObstacle(at: CGPoint(x: 1600, y: 800), size: CGSize(width: 160, height: 35))
        createObstacle(at: CGPoint(x: 600, y: 1200), size: CGSize(width: 220, height: 45))
        createObstacle(at: CGPoint(x: 1000, y: 1500), size: CGSize(width: 140, height: 40))
        createObstacle(at: CGPoint(x: 1400, y: 1200), size: CGSize(width: 190, height: 30))
        createObstacle(at: CGPoint(x: 300, y: 1600), size: CGSize(width: 170, height: 50))
        createObstacle(at: CGPoint(x: 1700, y: 600), size: CGSize(width: 130, height: 60))
        createObstacle(at: CGPoint(x: 500, y: 900), size: CGSize(width: 250, height: 25))
    }

    private func createObstacle(at position: CGPoint, size: CGSize) {
        let obstacle = SKSpriteNode(color: .systemBrown, size: size)
        obstacle.position = position
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.wall
        obstacle.physicsBody?.isDynamic = false
        addChild(obstacle)
        walls.append(obstacle)
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
