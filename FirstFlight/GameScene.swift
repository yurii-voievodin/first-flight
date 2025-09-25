//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit
import GameplayKit

class Player: SKSpriteNode {
    init() {
        let texture = SKTexture()
        super.init(texture: texture, color: .systemBlue, size: CGSize(width: 40, height: 40))

        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPhysics()
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.ground
        physicsBody?.collisionBitMask = PhysicsCategory.ground
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.1
    }

    func moveTo(position: CGPoint) {
        let moveAction = SKAction.move(to: position, duration: 1.0)
        moveAction.timingMode = .easeInEaseOut
        run(moveAction)
    }
}

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let ground: UInt32 = 0b10
}

class GameScene: SKScene {

    private var player: Player!
    private var gameCamera: SKCameraNode!
    private var ground: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        setupScene()
        createPlayer()
        createGround()
        setupCamera()
    }

    private func setupScene() {
        size = CGSize(width: 1000, height: 800)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        backgroundColor = SKColor.systemMint
    }

    private func createPlayer() {
        player = Player()
        player.position = CGPoint(x: 100, y: 400)
        addChild(player)
    }

    private func createGround() {
        // Main ground platform
        let mainGround = SKSpriteNode(color: .systemBrown, size: CGSize(width: 1000, height: 60))
        mainGround.position = CGPoint(x: 500, y: 30)
        mainGround.physicsBody = SKPhysicsBody(rectangleOf: mainGround.size)
        mainGround.physicsBody?.categoryBitMask = PhysicsCategory.ground
        mainGround.physicsBody?.isDynamic = false
        addChild(mainGround)
        ground.append(mainGround)

        // Additional platforms
        let platform1 = SKSpriteNode(color: .systemBrown, size: CGSize(width: 200, height: 30))
        platform1.position = CGPoint(x: 300, y: 200)
        platform1.physicsBody = SKPhysicsBody(rectangleOf: platform1.size)
        platform1.physicsBody?.categoryBitMask = PhysicsCategory.ground
        platform1.physicsBody?.isDynamic = false
        addChild(platform1)
        ground.append(platform1)

        let platform2 = SKSpriteNode(color: .systemBrown, size: CGSize(width: 200, height: 30))
        platform2.position = CGPoint(x: 700, y: 300)
        platform2.physicsBody = SKPhysicsBody(rectangleOf: platform2.size)
        platform2.physicsBody?.categoryBitMask = PhysicsCategory.ground
        platform2.physicsBody?.isDynamic = false
        addChild(platform2)
        ground.append(platform2)

        // Side walls
        let leftWall = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 800))
        leftWall.position = CGPoint(x: 5, y: 400)
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.size)
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.ground
        leftWall.physicsBody?.isDynamic = false
        addChild(leftWall)

        let rightWall = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 800))
        rightWall.position = CGPoint(x: 995, y: 400)
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.size)
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.ground
        rightWall.physicsBody?.isDynamic = false
        addChild(rightWall)
    }

    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)

        gameCamera.position = player.position
    }

    func touchDown(atPoint pos : CGPoint) {
        let worldPos = convertPoint(fromView: pos)
        player.moveTo(position: worldPos)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchDown(atPoint: t.location(in: self))
        }
    }

    override func update(_ currentTime: TimeInterval) {
        updateCamera()
    }

    private func updateCamera() {
        let targetX = player.position.x
        let targetY = player.position.y

        // Обмеження камери в межах сцени
        let minX = frame.width / 2
        let maxX = size.width - frame.width / 2
        let minY = frame.height / 2
        let maxY = size.height - frame.height / 2

        let clampedX = max(minX, min(maxX, targetX))
        let clampedY = max(minY, min(maxY, targetY))

        gameCamera.position = CGPoint(x: clampedX, y: clampedY)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Обробка колізій між персонажем і поверхнею
    }
}