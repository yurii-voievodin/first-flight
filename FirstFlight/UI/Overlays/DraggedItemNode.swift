import SpriteKit

final class DraggedItemNode: SKNode {

    private let iconSprite: SKSpriteNode
    private let quantityLabel: SKLabelNode?
    private let backgroundNode: SKShapeNode

    init(itemDef: ItemDef, quantity: Int) {
        let size: CGFloat = 48

        // Background circle with shadow effect
        backgroundNode = SKShapeNode(circleOfRadius: size / 2 + 6)
        backgroundNode.fillColor = SKColor(white: 0.15, alpha: 0.9)
        backgroundNode.strokeColor = SKColor(white: 1.0, alpha: 0.4)
        backgroundNode.lineWidth = 2

        // Item icon
        let texture = SKTexture(imageNamed: itemDef.iconName)
        iconSprite = SKSpriteNode(texture: texture)
        iconSprite.size = texture.aspectFitSize(maxSize: size)
        iconSprite.zPosition = 1

        // Quantity label (only for stacks)
        if quantity > 1 {
            let label = SKLabelNode(text: "\(quantity)")
            label.fontSize = 14
            label.fontName = "Courier-Bold"
            label.fontColor = .white
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .bottom
            label.position = CGPoint(x: size / 2 + 4, y: -size / 2 - 2)
            label.zPosition = 2
            quantityLabel = label
        } else {
            quantityLabel = nil
        }

        super.init()

        addChild(backgroundNode)
        addChild(iconSprite)
        if let label = quantityLabel {
            addChild(label)
        }

        // Add slight scale animation
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.1)
        scaleUp.timingMode = .easeOut
        run(scaleUp)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}
