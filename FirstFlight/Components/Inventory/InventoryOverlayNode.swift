import SpriteKit

// MARK: - Inventory Overlay UI

final class InventoryOverlayNode: SKNode {

    private let dimBackground = SKShapeNode()
    private let panel = SKShapeNode()
    private let titleLabel = SKLabelNode(text: "Inventory")
    private let closeLabel = SKLabelNode(text: "✕")

    private let gridNode = SKNode()
    private let cropNode = SKCropNode()
    private let maskNode = SKShapeNode()

    private var panelRect: CGRect = .zero
    private var gridViewportRect: CGRect = .zero

    // Scrolling
    private var scrollOffsetY: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var viewportHeight: CGFloat = 0
    private var isDraggingGrid: Bool = false
    private var lastDragY: CGFloat = 0
    
    var onClose: (() -> Void)?

    // Grid config
    private let columns: Int = 4
    private let slotSize = CGSize(width: 64, height: 64)
    private let slotSpacing: CGFloat = 12

    override init() {
        super.init()

        addChild(dimBackground)
        addChild(panel)
        addChild(cropNode)
        addChild(titleLabel)
        addChild(closeLabel)

        // Mask node is used only for cropping; do not add it as a child, otherwise it will render.
        cropNode.maskNode = maskNode
        cropNode.addChild(gridNode)

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

        dimBackground.zPosition = 200
        panel.zPosition = 210
        cropNode.zPosition = 220
        titleLabel.zPosition = 230
        closeLabel.zPosition = 230

        // For SKCropNode masking, the mask must render with *opaque alpha* in the visible area.
        // It's not added as a child, so it won't be visible on screen.
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        maskNode.lineWidth = 0

        // A little padding so the first row isn't clipped by the mask
        gridNode.position = .zero
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

        // Grid viewport (inside the panel, below the header)
        let padding: CGFloat = 18
        let headerHeight: CGFloat = 64

        let viewportTopY = panelRect.maxY - headerHeight
        let viewportBottomY = panelRect.minY + padding
        viewportHeight = max(0, viewportTopY - viewportBottomY)

        gridViewportRect = CGRect(
            x: panelRect.minX + padding,
            y: viewportBottomY,
            width: panelRect.width - padding * 2,
            height: viewportHeight
        )

        // Crop mask defines visible area
        maskNode.path = CGPath(roundedRect: gridViewportRect, cornerWidth: 12, cornerHeight: 12, transform: nil)

        applyScrollAndLayout()
    }

    func render(state: InventoryState, defsById: [String: ItemDef]) {
        gridNode.removeAllChildren()

        // Compute rows for current capacity
        let totalSlots = state.maxSlots
        let rows = Int(ceil(Double(totalSlots) / Double(columns)))
        updateContentMetrics(totalSlots: totalSlots)
        applyScrollAndLayout()

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

        // Begin drag-scrolling if the touch starts inside the grid viewport
        if gridViewportRect.contains(p) {
            isDraggingGrid = true
            lastDragY = p.y
        } else {
            isDraggingGrid = false
        }
    }

    func handleTouchMoved(from touch: UITouch, in scene: SKScene) {
        guard isDraggingGrid, let cam = scene.camera else { return }
        let p = touch.location(in: cam)
        let dy = p.y - lastDragY
        lastDragY = p.y

        // Drag scrolling (UIScrollView-style): content follows the finger.
        // dy is in SpriteKit coords (positive = finger moved up).
        // Finger up  => grid up  (scroll down)
        // Finger down => grid down (scroll up)
        scrollOffsetY += dy
        applyScrollAndLayout()
    }

    func handleTouchEnded(from touch: UITouch, in scene: SKScene) {
        isDraggingGrid = false
        lastDragY = 0
    }

    private func clampScrollOffset() {
        // scrollOffsetY = 0 at top; positive values scroll down through content
        let maxOffset = max(0, contentHeight - viewportHeight)
        let clamped = max(0, min(maxOffset, scrollOffsetY))
        scrollOffsetY = clamped
    }

    private func applyScrollAndLayout() {
        clampScrollOffset()
        // Increasing scrollOffsetY moves content UP, revealing lower rows (UIScrollView behavior)
        gridNode.position = CGPoint(x: gridViewportRect.minX, y: gridViewportRect.maxY + scrollOffsetY)
    }

    private func updateContentMetrics(totalSlots: Int) {
        let rows = Int(ceil(Double(totalSlots) / Double(columns)))
        if rows <= 0 {
            contentHeight = 0
            return
        }
        contentHeight = CGFloat(rows) * slotSize.height + CGFloat(max(0, rows - 1)) * slotSpacing
    }
}
