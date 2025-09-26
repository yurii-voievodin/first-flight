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
        physicsBody?.contactTestBitMask = PhysicsCategory.wall
        physicsBody?.collisionBitMask = PhysicsCategory.wall
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.1
    }

    func moveTo(position: CGPoint) {
        let direction = CGVector(
            dx: (position.x - self.position.x) / 2,
            dy: (position.y - self.position.y) / 2
        )
        physicsBody?.velocity = direction
    }
}
