import SpriteKit

class RechargeButton: SKNode {

    private let backgroundCircle: SKShapeNode
    private let iconNode: SKSpriteNode
    private let buttonSize: CGFloat

    var onTap: (() -> Void)?

    private var isButtonActive: Bool = true

    init(size: CGFloat) {
        self.buttonSize = size

        // Create circular background
        backgroundCircle = SKShapeNode(circleOfRadius: size / 2)
        backgroundCircle.fillColor = SKColor(white: 0.3, alpha: 0.5)
        backgroundCircle.strokeColor = SKColor(white: 1.0, alpha: 0.3)
        backgroundCircle.lineWidth = 1.5

        // Create icon sprite (will be set up in setupIcon)
        iconNode = SKSpriteNode()

        super.init()

        addChild(backgroundCircle)
        addChild(iconNode)

        setupIcon()

        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupIcon() {
        let iconSize = buttonSize * 0.6
        guard let texture = sfSymbolTexture(
            name: "arrow.2.circlepath",
            pointSize: iconSize,
            tintColor: SKColor(white: 1.0, alpha: 0.8)
        ) else { return }

        iconNode.texture = texture
        iconNode.size = CGSize(width: iconSize, height: iconSize)
        iconNode.zPosition = 1
    }

    func setActive(_ active: Bool) {
        isButtonActive = active

        if active {
            // Restore normal appearance
            backgroundCircle.fillColor = SKColor(white: 0.3, alpha: 0.5)
            iconNode.alpha = 1.0
        } else {
            // Grayed out appearance
            backgroundCircle.fillColor = SKColor(white: 0.2, alpha: 0.3)
            iconNode.alpha = 0.4
        }
    }

    // MARK: - Input Handling

    private func handlePointerDown(at location: CGPoint) {
        guard isButtonActive else { return }
        let distance = hypot(location.x, location.y)
        if distance <= buttonSize / 2 {
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.05)
            backgroundCircle.run(scaleDown)
            iconNode.run(scaleDown)
        }
    }

    private func handlePointerUp(at location: CGPoint) {
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        backgroundCircle.run(scaleUp)
        iconNode.run(scaleUp)

        guard isButtonActive else { return }
        let distance = hypot(location.x, location.y)
        if distance <= buttonSize / 2 {
            onTap?()
        }
    }

    private func handlePointerCancelled() {
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        backgroundCircle.run(scaleUp)
        iconNode.run(scaleUp)
    }

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handlePointerDown(at: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handlePointerUp(at: touch.location(in: self))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handlePointerCancelled()
    }
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        handlePointerDown(at: event.location(in: self))
    }

    override func mouseUp(with event: NSEvent) {
        handlePointerUp(at: event.location(in: self))
    }
    #endif
}
