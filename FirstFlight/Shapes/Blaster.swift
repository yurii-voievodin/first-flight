import SpriteKit

final class Blaster: SKNode {
    enum Orientation {
        case up
        case down
        case left
        case right
    }

    private let grip: SKShapeNode
    private let body: SKShapeNode
    private let barrel: SKShapeNode
    private let emitter: SKShapeNode

    override init() {
        grip = SKShapeNode(rectOf: CGSize(width: 5, height: 9), cornerRadius: 1.5)
        body = SKShapeNode(rectOf: CGSize(width: 6, height: 18), cornerRadius: 3)
        barrel = SKShapeNode(rectOf: CGSize(width: 4, height: 12), cornerRadius: 1.6)
        emitter = SKShapeNode(circleOfRadius: 2.3)

        super.init()

        position = CGPoint(x: 3, y: -4)
        zPosition = 2.4

        grip.fillColor = SKColor(red: 0.19, green: 0.22, blue: 0.26, alpha: 1)
        grip.strokeColor = SKColor.black.withAlphaComponent(0.35)
        grip.lineWidth = 1
        grip.position = CGPoint(x: 0, y: -1.5)
        addChild(grip)

        body.fillColor = SKColor(red: 0.45, green: 0.52, blue: 0.6, alpha: 1)
        body.strokeColor = SKColor.black.withAlphaComponent(0.3)
        body.lineWidth = 1
        body.position = CGPoint(x: 0, y: -9)
        addChild(body)

        barrel.fillColor = SKColor(red: 0.72, green: 0.84, blue: 0.95, alpha: 0.9)
        barrel.strokeColor = SKColor.white.withAlphaComponent(0.4)
        barrel.lineWidth = 0.8
        barrel.position = CGPoint(x: 0, y: -14)
        addChild(barrel)

        emitter.fillColor = SKColor.cyan.withAlphaComponent(0.8)
        emitter.strokeColor = SKColor.white.withAlphaComponent(0.6)
        emitter.lineWidth = 0.6
        emitter.position = CGPoint(x: 0, y: -20.5)
        addChild(emitter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(for orientation: Orientation) {
        isHidden = false
        alpha = 1
        xScale = 1
        yScale = 1
        zRotation = 0
        zPosition = 2.4
        position = CGPoint(x: 3, y: -4)

        body.fillColor = SKColor(red: 0.45, green: 0.52, blue: 0.6, alpha: 1)
        barrel.alpha = 0.9
        emitter.alpha = 0.8

        switch orientation {
        case .up:
            zPosition = 1.8
            alpha = 0.85
        case .down:
            emitter.alpha = 0.9
        case .right:
            position = CGPoint(x: 5.5, y: -2.5)
            zRotation = .pi / 2
            zPosition = 2.3
            body.fillColor = SKColor(red: 0.42, green: 0.5, blue: 0.58, alpha: 1)
            emitter.alpha = 0.75
        case .left:
            position = CGPoint(x: 5.5, y: -2.5)
            zRotation = .pi / 2
            zPosition = 2.3
            body.fillColor = SKColor(red: 0.42, green: 0.5, blue: 0.58, alpha: 1)
            emitter.alpha = 0.75
        }
    }
}
