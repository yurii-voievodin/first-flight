import SpriteKit


class Player: SKShapeNode {
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
        physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.rock
        physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.rock
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.1
    }

    func moveTo(position: CGPoint) {
        // Stop any current movement
        removeAction(forKey: "move")

        // Reset velocity to prevent inertia
        physicsBody?.velocity = .zero

        // Calculate distance and duration for consistent speed
        let distance = hypot(position.x - self.position.x, position.y - self.position.y)
        let speed: CGFloat = 150.0 // points per second
        let duration = TimeInterval(distance / speed)

        // Move directly to position with no overshoot
        let moveAction = SKAction.move(to: position, duration: duration)
        moveAction.timingMode = .linear
        run(moveAction, withKey: "move")
    }
}
