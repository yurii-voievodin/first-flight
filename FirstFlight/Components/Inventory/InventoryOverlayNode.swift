import SpriteKit

final class InventoryOverlayNode: SKNode {
    private let background = SKShapeNode()
    private let content = SKNode()
    private let closeButton = SKLabelNode(text: "Close")

    var isShown: Bool { parent != nil }

    override init() {
        super.init()
        zPosition = 10_000
        isUserInteractionEnabled = true

        addChild(background)
        addChild(content)
        addChild(closeButton)

        background.fillColor = SKColor(white: 0.0, alpha: 0.65)
        background.strokeColor = .clear

        closeButton.fontSize = 22
        closeButton.position = CGPoint(x: 0, y: 240)
        closeButton.name = "close"
    }

    required init?(coder: NSCoder) { fatalError() }

    func layout(for size: CGSize) {
        let rect = CGRect(x: -size.width * 0.45, y: -size.height * 0.35,
                          width: size.width * 0.9, height: size.height * 0.7)
        background.path = CGPath(rect: rect, transform: nil)
    }

    func render(state: InventoryState, defs: [String: ItemDef]) {
        // TODO: grid 4xN:
        // - для кожного слоту показати icon + quantity (якщо stack)
        // - пусті слоти як “порожні”
        // Важливо: реюз нодів (масив слот-нодів)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        if node.name == "close" { removeFromParent() }
    }
}
