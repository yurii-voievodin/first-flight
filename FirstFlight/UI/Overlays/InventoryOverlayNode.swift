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

    // Equipment section
    private let equipmentSectionLabel = SKLabelNode(text: "Equipment")
    private let equipmentSlotsNode = SKNode()
    private var backpackSlotRect: CGRect = .zero
    private var weaponSlotRect: CGRect = .zero

    private var panelRect: CGRect = .zero
    private var gridViewportRect: CGRect = .zero

    // Player reference for equipment state
    private weak var player: Player?

    // Scrolling
    private var scrollOffsetY: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var viewportHeight: CGFloat = 0
    private var isDraggingGrid: Bool = false
    private var lastDragY: CGFloat = 0

    // Tap detection
    private var touchStartLocation: CGPoint?

    // Cached data for tap lookup
    private var cachedState: InventoryState?
    private var cachedDefs: [String: ItemDef] = [:]

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
        addChild(equipmentSlotsNode)

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

        // Equipment section label
        equipmentSectionLabel.fontSize = 12
        equipmentSectionLabel.fontName = "Courier-Bold"
        equipmentSectionLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        equipmentSectionLabel.horizontalAlignmentMode = .left
        equipmentSectionLabel.verticalAlignmentMode = .center
        equipmentSlotsNode.addChild(equipmentSectionLabel)

        dimBackground.zPosition = 200
        panel.zPosition = 210
        cropNode.zPosition = 220
        equipmentSlotsNode.zPosition = 220
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
        let gridWidth =
            CGFloat(columns) * slotSize.width +
            CGFloat(columns - 1) * slotSpacing

        let sidePadding: CGFloat = 18
        let panelWidth = gridWidth + sidePadding * 2
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

        // Grid viewport (inside the panel, below the header and equipment section)
        let padding: CGFloat = 18
        let headerHeight: CGFloat = 64
        let equipmentSectionHeight: CGFloat = 90

        // Equipment section layout (between header and inventory grid)
        let equipmentLabelY = panelRect.maxY - headerHeight - 4
        equipmentSectionLabel.position = CGPoint(x: panelRect.minX + padding, y: equipmentLabelY)

        // Equipment slots position (below label)
        let equipmentSlotsY = equipmentLabelY - 40
        let slotGap: CGFloat = 12
        let twoSlotsWidth = slotSize.width * 2 + slotGap
        let slotsStartX = panelRect.midX - twoSlotsWidth / 2

        // Backpack slot (left)
        backpackSlotRect = CGRect(
            x: slotsStartX,
            y: equipmentSlotsY - slotSize.height / 2,
            width: slotSize.width,
            height: slotSize.height
        )

        // Weapon slot (right)
        weaponSlotRect = CGRect(
            x: slotsStartX + slotSize.width + slotGap,
            y: equipmentSlotsY - slotSize.height / 2,
            width: slotSize.width,
            height: slotSize.height
        )

        let viewportTopY = panelRect.maxY - headerHeight - equipmentSectionHeight
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

    func render(state: InventoryState, defsById: [String: ItemDef], player: Player? = nil) {
        cachedState = state
        cachedDefs = defsById
        self.player = player
        gridNode.removeAllChildren()

        // Render equipment slots
        renderEquipmentSlots()

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
                if let def = defsById[defId], let texture = SKTexture(imageNamed: def.iconName) as SKTexture? {
                    let icon = SKSpriteNode(texture: texture)
                    icon.size = aspectFitSize(for: texture, maxSize: 44)
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
                if let def = defsById[item.defId], let texture = SKTexture(imageNamed: def.iconName) as SKTexture? {
                    let icon = SKSpriteNode(texture: texture)
                    icon.size = aspectFitSize(for: texture, maxSize: 44)
                    icon.position = CGPoint(x: slotFrame.midX, y: slotFrame.midY)
                    gridNode.addChild(icon)
                }
            }
        }

        // If panel is too small for all rows, we can add paging/scroll later.
        _ = rows
    }

    private func renderEquipmentSlots() {
        // Clear previous content except the label
        for child in equipmentSlotsNode.children where child !== equipmentSectionLabel {
            child.removeFromParent()
        }

        guard let player = player else { return }
        let equipmentState = player.equipmentManager.state

        // Render backpack slot
        renderEquipmentSlot(
            rect: backpackSlotRect,
            slot: .backpack,
            item: equipmentState.equippedItems[.backpack],
            label: "Backpk"
        )

        // Render weapon slot
        renderEquipmentSlot(
            rect: weaponSlotRect,
            slot: .weapon,
            item: equipmentState.equippedItems[.weapon],
            label: "Weapon"
        )
    }

    private func renderEquipmentSlot(rect: CGRect, slot: EquipmentSlot, item: UniqueItemInstance?, label: String) {
        // Slot background
        let slotBorder = SKShapeNode(rect: rect, cornerRadius: 10)

        if item != nil {
            // Equipped: golden border
            slotBorder.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8)
            slotBorder.lineWidth = 2
            slotBorder.fillColor = SKColor(white: 1.0, alpha: 0.08)
        } else {
            // Empty: dimmed outline
            slotBorder.strokeColor = SKColor(white: 1.0, alpha: 0.2)
            slotBorder.lineWidth = 1
            slotBorder.fillColor = SKColor(white: 1.0, alpha: 0.02)
        }
        slotBorder.name = "equipSlot_\(slot.rawValue)"
        equipmentSlotsNode.addChild(slotBorder)

        // Slot label below
        let slotLabel = SKLabelNode(text: label)
        slotLabel.fontSize = 9
        slotLabel.fontName = "Courier"
        slotLabel.fontColor = SKColor(white: 1.0, alpha: 0.5)
        slotLabel.horizontalAlignmentMode = .center
        slotLabel.verticalAlignmentMode = .top
        slotLabel.position = CGPoint(x: rect.midX, y: rect.minY - 3)
        equipmentSlotsNode.addChild(slotLabel)

        // Render equipped item icon
        if let item = item, let def = cachedDefs[item.defId] {
            let texture = SKTexture(imageNamed: def.iconName)
            let icon = SKSpriteNode(texture: texture)
            icon.size = aspectFitSize(for: texture, maxSize: 44)
            icon.position = CGPoint(x: rect.midX, y: rect.midY)
            equipmentSlotsNode.addChild(icon)
        }
    }

    func handleTouch(from touch: UITouch, in scene: SKScene) {
        guard let cam = scene.camera else {
            onClose?()
            removeFromParent()
            return
        }

        let p = touch.location(in: cam)
        touchStartLocation = p

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
        defer {
            isDraggingGrid = false
            lastDragY = 0
            touchStartLocation = nil
        }

        guard let cam = scene.camera else { return }
        let endLocation = touch.location(in: cam)

        // Check if it was a tap (not a drag scroll)
        guard let startLocation = touchStartLocation else { return }
        let dx = endLocation.x - startLocation.x
        let dy = endLocation.y - startLocation.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance < 10 else { return }

        // Check equipment slots first
        if let equipSlot = equipmentSlot(at: endLocation),
           let item = player?.equipmentManager.getEquipped(equipSlot),
           let def = cachedDefs[item.defId] {
            let slotRect = equipSlot == .backpack ? backpackSlotRect : weaponSlotRect
            let center = CGPoint(x: slotRect.midX, y: slotRect.midY)
            showTooltip(for: def, at: center)
            return
        }

        // It's a tap - check if it's on a slot with an item
        guard let index = slotIndex(at: endLocation),
              let item = itemAt(slotIndex: index) else { return }

        let center = slotCenter(for: index)
        showTooltip(for: item, at: center)
    }

    private func equipmentSlot(at point: CGPoint) -> EquipmentSlot? {
        if backpackSlotRect.contains(point) {
            return .backpack
        } else if weaponSlotRect.contains(point) {
            return .weapon
        }
        return nil
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

    /// Returns an aspect-fit size for the given texture within the max bounds.
    private func aspectFitSize(for texture: SKTexture, maxSize: CGFloat) -> CGSize {
        let textureSize = texture.size()
        let aspectRatio = textureSize.width / textureSize.height
        if aspectRatio > 1 {
            // Landscape: fit to width
            return CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            // Portrait or square: fit to height
            return CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
    }

    // MARK: - Tap Tooltip

    /// Returns the slot index at the given position in camera coordinates, or nil if outside grid.
    private func slotIndex(at cameraPoint: CGPoint) -> Int? {
        guard gridViewportRect.contains(cameraPoint) else { return nil }
        guard let state = cachedState else { return nil }

        // Convert camera coords to grid-local coords
        let gridLocalX = cameraPoint.x - gridNode.position.x
        let gridLocalY = cameraPoint.y - gridNode.position.y

        // Each slot: origin at (col * stride, -row * stride - slotSize.height)
        let strideX = slotSize.width + slotSpacing
        let strideY = slotSize.height + slotSpacing

        let col = Int(floor(gridLocalX / strideX))
        let row = Int(floor(-gridLocalY / strideY))

        guard col >= 0, col < columns, row >= 0 else { return nil }

        let index = row * columns + col
        guard index >= 0, index < state.maxSlots else { return nil }
        return index
    }

    /// Returns the ItemDef at the given slot index, or nil if empty or invalid.
    private func itemAt(slotIndex: Int) -> ItemDef? {
        guard let state = cachedState,
              slotIndex >= 0,
              slotIndex < state.slots.count,
              let slot = state.slots[slotIndex] else { return nil }

        switch slot {
        case .stack(let defId, _):
            return cachedDefs[defId]
        case .unique(let item):
            return cachedDefs[item.defId]
        }
    }

    /// Returns the center position of the slot in camera coordinates.
    private func slotCenter(for slotIndex: Int) -> CGPoint {
        let col = slotIndex % columns
        let row = slotIndex / columns

        let x = CGFloat(col) * (slotSize.width + slotSpacing)
        let y = -CGFloat(row) * (slotSize.height + slotSpacing) - slotSize.height

        let slotCenterX = x + slotSize.width / 2
        let slotCenterY = y + slotSize.height / 2

        return CGPoint(
            x: gridNode.position.x + slotCenterX,
            y: gridNode.position.y + slotCenterY
        )
    }

    /// Shows a floating tooltip with the item's display name.
    private func showTooltip(for item: ItemDef, at position: CGPoint) {
        let label = SKLabelNode(text: item.displayName)
        label.fontName = "Courier-Bold"
        label.fontSize = 14
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 300

        let padding: CGFloat = 8
        let bgWidth = label.frame.width + padding * 2
        let bgHeight = label.frame.height + padding

        let background = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: 6)
        background.fillColor = SKColor(white: 0.1, alpha: 0.9)
        background.strokeColor = SKColor(white: 1.0, alpha: 0.2)
        background.lineWidth = 1
        background.zPosition = 299

        let container = SKNode()
        container.addChild(background)
        container.addChild(label)
        container.position = CGPoint(x: position.x, y: position.y + slotSize.height / 2 + 10)
        container.alpha = 1.0
        addChild(container)

        let moveUp = SKAction.moveBy(x: 0, y: 35, duration: 1.0)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()

        container.run(SKAction.sequence([group, remove]))
    }
}
