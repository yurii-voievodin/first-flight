import SpriteKit

class EnergyBar: SKNode {
    private let barWidth: CGFloat = 120
    private let barHeight: CGFloat = 12
    private let cornerRadius: CGFloat = 6
    private let iconSize: CGFloat = 16
    private let iconSpacing: CGFloat = 12

    private var iconNode: SKSpriteNode!
    private var backgroundBar: SKShapeNode!
    private var fillBar: SKShapeNode!
    private var fillCropNode: SKCropNode!

    private var currentEnergy: CGFloat = 0
    private var maxEnergy: CGFloat = 1

    override init() {
        super.init()
        setupBar()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBar()
    }

    private func setupBar() {
        // Background bar (dark with more transparency) - centered
        let backgroundPath = CGPath(
            roundedRect: CGRect(x: -barWidth / 2, y: -barHeight / 2, width: barWidth, height: barHeight),
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        backgroundBar = SKShapeNode(path: backgroundPath)
        backgroundBar.fillColor = SKColor(white: 0.2, alpha: 0.3)
        backgroundBar.strokeColor = SKColor(white: 1.0, alpha: 0.2)
        backgroundBar.lineWidth = 1
        backgroundBar.zPosition = 0
        addChild(backgroundBar)

        // Crop node for fill bar animation
        fillCropNode = SKCropNode()
        fillCropNode.zPosition = 1

        // Mask for the crop node (full bar shape)
        let maskNode = SKShapeNode(path: backgroundPath)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        fillCropNode.maskNode = maskNode

        // Fill bar (light color with more transparency)
        let fillPath = CGPath(
            roundedRect: CGRect(x: -barWidth / 2, y: -barHeight / 2, width: barWidth, height: barHeight),
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        fillBar = SKShapeNode(path: fillPath)
        fillBar.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.5)
        fillBar.strokeColor = .clear
        fillCropNode.addChild(fillBar)

        addChild(fillCropNode)

        // Energy icon using SF Symbol (on the right side)
        setupIcon()

        updateFillBar(animated: false)
    }

    private func setupIcon() {
        let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
        guard let image = UIImage(systemName: "bolt.fill", withConfiguration: config) else { return }

        // Render the SF Symbol to a texture
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: iconSize, height: iconSize))
        let renderedImage = renderer.image { _ in
            // Tint the image with light color
            let tintColor = UIColor(white: 1.0, alpha: 0.6)
            image.withTintColor(tintColor, renderingMode: .alwaysOriginal).draw(in: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
        }

        let texture = SKTexture(image: renderedImage)
        iconNode = SKSpriteNode(texture: texture, size: CGSize(width: iconSize, height: iconSize))
        iconNode.position = CGPoint(x: barWidth / 2 + iconSpacing, y: 0)
        iconNode.zPosition = 2
        addChild(iconNode)
    }

    func update(currentEnergy: CGFloat, maxEnergy: CGFloat, animated: Bool = true) {
        self.currentEnergy = currentEnergy
        self.maxEnergy = max(1, maxEnergy)
        updateFillBar(animated: animated)
    }

    private func updateFillBar(animated: Bool) {
        let fillRatio = currentEnergy / maxEnergy
        // When fillRatio = 1.0, targetX = 0 (fully visible)
        // When fillRatio = 0.0, targetX = -barWidth (hidden to the left)
        let targetX = -barWidth * (1 - fillRatio)

        if animated {
            let moveAction = SKAction.moveTo(x: targetX, duration: 0.2)
            moveAction.timingMode = .easeOut
            fillBar.run(moveAction)
        } else {
            fillBar.position.x = targetX
        }
    }
}
