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
        let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
        guard let image = UIImage(systemName: "arrow.2.circlepath", withConfiguration: config) else { return }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: iconSize, height: iconSize))
        let renderedImage = renderer.image { _ in
            let tintColor = UIColor(white: 1.0, alpha: 0.8)
            image.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
        }

        let texture = SKTexture(image: renderedImage)
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

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isButtonActive, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if touch is within button circle
        let distance = hypot(location.x, location.y)
        if distance <= buttonSize / 2 {
            // Visual feedback - slight press effect
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.05)
            backgroundCircle.run(scaleDown)
            iconNode.run(scaleDown)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Restore scale
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        backgroundCircle.run(scaleUp)
        iconNode.run(scaleUp)

        guard isButtonActive, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if touch ended within button
        let distance = hypot(location.x, location.y)
        if distance <= buttonSize / 2 {
            onTap?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Restore scale if touch was cancelled
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        backgroundCircle.run(scaleUp)
        iconNode.run(scaleUp)
    }
}
