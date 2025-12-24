import SpriteKit

/// Visual popup showing collected elements (e.g., "+3 Fe")
/// Floats upward and fades out
class ElementPopup: SKNode {
    private static let floatDistance: CGFloat = 40
    private static let duration: TimeInterval = 1.0

    /// Create and animate a popup for collected elements
    /// - Parameters:
    ///   - elements: Dictionary of elements and amounts collected
    ///   - position: World position to spawn the popup
    ///   - scene: Scene to add the popup to
    static func spawn(elements: [ElementType: Int], at position: CGPoint, in scene: SKScene) {
        guard !elements.isEmpty else { return }

        // Format text: "+3 Fe +2 Si"
        let text = elements
            .sorted { $0.value > $1.value }
            .map { "+\($0.value) \($0.key.symbol)" }
            .joined(separator: " ")

        let popup = ElementPopup(text: text)
        popup.position = position
        popup.zPosition = 150
        scene.addChild(popup)
        popup.animate()
    }

    /// Create popup for a single element
    static func spawn(element: ElementType, amount: Int, at position: CGPoint, in scene: SKScene) {
        spawn(elements: [element: amount], at: position, in: scene)
    }

    private let label: SKLabelNode
    private let background: SKShapeNode

    init(text: String) {
        label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = text
        label.fontSize = 14
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 1

        let padding: CGFloat = 6
        let size = CGSize(
            width: label.frame.width + padding * 2,
            height: label.frame.height + padding
        )
        background = SKShapeNode(rectOf: size, cornerRadius: 4)
        background.fillColor = SKColor(white: 0.1, alpha: 0.8)
        background.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        background.lineWidth = 1
        background.zPosition = 0

        super.init()

        addChild(background)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func animate() {
        let moveUp = SKAction.moveBy(x: 0, y: Self.floatDistance, duration: Self.duration)
        moveUp.timingMode = .easeOut

        let fadeOut = SKAction.fadeOut(withDuration: Self.duration * 0.6)
        fadeOut.timingMode = .easeIn

        let wait = SKAction.wait(forDuration: Self.duration * 0.4)
        let fadeSequence = SKAction.sequence([wait, fadeOut])

        let group = SKAction.group([moveUp, fadeSequence])
        let remove = SKAction.removeFromParent()

        run(SKAction.sequence([group, remove]))
    }
}
