import SpriteKit

// MARK: - Inventory Overlay UI

final class InventoryOverlayNode: SKNode {

    private let dimBackground = SKShapeNode()
    private let panel = SKShapeNode()
    private let titleLabel = SKLabelNode(text: "Inventory")
    private let closeLabel = SKLabelNode(text: "✕")

    private let gridNode = SKNode()

    private var panelRect: CGRect = .zero
    
    var onClose: (() -> Void)?

    // Grid config
    private let columns: Int = 4
    private let slotSize = CGSize(width: 64, height: 64)
    private let slotSpacing: CGFloat = 12

    override init() {
        super.init()

        addChild(dimBackground)
        addChild(panel)
        addChild(titleLabel)
        addChild(closeLabel)
        addChild(gridNode)

        dimBackground.fillColor = SKColor(white: 0.0, alpha: 0.65)
        dimBackground.strokeColor = .clear

        panel.fillColor = SKColor(white: 0.08, alpha: 0.95)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        panel.lineWidth = 2

        titleLabel.fontSize = 20
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center

        closeLabel.fontSize = 22
        closeLabel.name = "close"
        closeLabel.horizontalAlignmentMode = .center
        closeLabel.verticalAlignmentMode = .center
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func layout(for sceneSize: CGSize) {
        // Fullscreen dim
        let bgRect = CGRect(
            x: -sceneSize.width / 2,
            y: -sceneSize.height / 2,
            width: sceneSize.width,
            height: sceneSize.height
        )
        dimBackground.path = CGPath(rect: bgRect, transform: nil)

        // Center panel
        let panelWidth = min(sceneSize.width * 0.85, 520)
        let panelHeight = min(sceneSize.height * 0.75, 520)
        panelRect = CGRect(
            x: -panelWidth / 2,
            y: -panelHeight / 2,
            width: panelWidth,
            height: panelHeight
        )
        panel.path = CGPath(roundedRect: panelRect, cornerWidth: 16, cornerHeight: 16, transform: nil)

        // Header
        titleLabel.position = CGPoint(x: panelRect.minX + 18, y: panelRect.maxY - 28)
        closeLabel.position = CGPoint(x: panelRect.maxX - 18, y: panelRect.maxY - 28)

        // Grid origin
        gridNode.position = CGPoint(x: panelRect.minX + 18, y: panelRect.maxY - 64)
    }

    func render(state: InventoryState, defsById: [String: ItemDef]) {
        gridNode.removeAllChildren()

        // Compute rows for current capacity
        let totalSlots = state.maxSlots
        let rows = Int(ceil(Double(totalSlots) / Double(columns)))

        for slotIndex in 0..<totalSlots {
            let col = slotIndex % columns
            let row = slotIndex / columns

            let x = CGFloat(col) * (slotSize.width + slotSpacing)
            let y = -CGFloat(row) * (slotSize.height + slotSpacing)

            let slotFrame = CGRect(x: x, y: y - slotSize.height, width: slotSize.width, height: slotSize.height)

            let slotBorder = SKShapeNode(rect: slotFrame, cornerRadius: 10)
            slotBorder.strokeColor = SKColor(white: 1.0, alpha: 0.18)
            slotBorder.lineWidth = 2
            slotBorder.fillColor = SKColor(white: 1.0, alpha: 0.04)
            gridNode.addChild(slotBorder)

            guard let slot = state.slots[slotIndex] else {
                continue
            }

            switch slot {
            case .stack(let defId, let quantity):
                if let def = defsById[defId] {
                    let icon = SKSpriteNode(imageNamed: def.iconName)
                    icon.size = CGSize(width: 44, height: 44)
                    icon.position = CGPoint(x: slotFrame.midX, y: slotFrame.midY)
                    gridNode.addChild(icon)

                    let qty = SKLabelNode(text: "\(quantity)")
                    qty.fontSize = 14
                    qty.horizontalAlignmentMode = .right
                    qty.verticalAlignmentMode = .bottom
                    qty.position = CGPoint(x: slotFrame.maxX - 8, y: slotFrame.minY + 6)
                    gridNode.addChild(qty)
                }

            case .unique(let item):
                if let def = defsById[item.defId] {
                    let icon = SKSpriteNode(imageNamed: def.iconName)
                    icon.size = CGSize(width: 44, height: 44)
                    icon.position = CGPoint(x: slotFrame.midX, y: slotFrame.midY)
                    gridNode.addChild(icon)
                }
            }
        }

        // If panel is too small for all rows, we can add paging/scroll later.
        _ = rows
    }

    func handleTouch(from touch: UITouch, in scene: SKScene) {
        guard let cam = scene.camera else {
            onClose?()
            removeFromParent()
            return
        }

        let p = touch.location(in: cam)

        // Close button
        if closeLabel.contains(p) {
            onClose?()
            removeFromParent()
            return
        }

        // Tap outside the panel closes the overlay
        if !panelRect.contains(p) {
            onClose?()
            removeFromParent()
            return
        }
    }
}
