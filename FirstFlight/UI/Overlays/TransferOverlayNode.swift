import SpriteKit

final class TransferOverlayNode: SKNode {

    // MARK: - Callbacks

    var onClose: (() -> Void)?
    var onTransfer: (() -> Void)?
    var onEquip: ((String) -> Void)?

    // MARK: - Data

    private var playerInventory: Inventory
    private var shuttleInventory: Inventory
    private var itemDefsById: [String: ItemDef]
    private weak var player: Player?

    // MARK: - UI Elements

    private let dimBackground = SKShapeNode()
    private let containerNode = SKNode()

    private let playerPanel = SKShapeNode()
    private let shuttlePanel = SKShapeNode()

    private let playerTitleLabel = SKLabelNode(text: "Player")
    private let shuttleTitleLabel = SKLabelNode(text: "Shuttle")
    private let closeLabel = SKLabelNode(text: "✕")

    private let playerGridNode = SKNode()
    private let shuttleGridNode = SKNode()

    // Equipment section
    private let equipmentSectionLabel = SKLabelNode(text: "Equipment")
    private let equipmentSlotsNode = SKNode()
    private var backpackSlotNode = SKShapeNode()
    private var weaponSlotNode = SKShapeNode()
    private var backpackSlotRect: CGRect = .zero
    private var weaponSlotRect: CGRect = .zero

    private let playerCropNode = SKCropNode()
    private let shuttleCropNode = SKCropNode()

    private let playerMaskNode = SKShapeNode()
    private let shuttleMaskNode = SKShapeNode()

    // MARK: - Layout

    private var sceneSize: CGSize = .zero
    private var playerPanelRect: CGRect = .zero
    private var shuttlePanelRect: CGRect = .zero
    private var playerGridViewportRect: CGRect = .zero
    private var shuttleGridViewportRect: CGRect = .zero

    // Grid config
    private let columns: Int = 4
    private let slotSize = CGSize(width: 56, height: 56)
    private let slotSpacing: CGFloat = 8

    // Scrolling
    private var playerScrollOffsetY: CGFloat = 0
    private var shuttleScrollOffsetY: CGFloat = 0
    private var playerContentHeight: CGFloat = 0
    private var shuttleContentHeight: CGFloat = 0
    private var viewportHeight: CGFloat = 0

    private var isDraggingGrid: Bool = false
    private var activePanel: PanelSide?
    private var lastDragY: CGFloat = 0

    // Drag-and-drop
    private var draggedItemNode: DraggedItemNode?
    private var dragSourcePanel: PanelSide?
    private var dragSourceSlotIndex: Int?
    private var touchStartLocation: CGPoint?

    private enum PanelSide {
        case player
        case shuttle
    }

    private enum DragSource {
        case inventory(panel: PanelSide, slotIndex: Int)
        case equipment(slot: EquipmentSlot)
    }

    private var dragSource: DragSource?

    // MARK: - Init

    init(playerInventory: Inventory, shuttleInventory: Inventory, itemDefsById: [String: ItemDef], player: Player? = nil) {
        self.playerInventory = playerInventory
        self.shuttleInventory = shuttleInventory
        self.itemDefsById = itemDefsById
        self.player = player
        super.init()
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup

    private func setupUI() {
        addChild(dimBackground)
        addChild(containerNode)

        containerNode.addChild(playerPanel)
        containerNode.addChild(shuttlePanel)
        containerNode.addChild(playerCropNode)
        containerNode.addChild(shuttleCropNode)
        containerNode.addChild(playerTitleLabel)
        containerNode.addChild(shuttleTitleLabel)
        containerNode.addChild(closeLabel)
        containerNode.addChild(equipmentSlotsNode)

        playerCropNode.maskNode = playerMaskNode
        playerCropNode.addChild(playerGridNode)

        shuttleCropNode.maskNode = shuttleMaskNode
        shuttleCropNode.addChild(shuttleGridNode)

        // Equipment section label
        equipmentSectionLabel.fontSize = 12
        equipmentSectionLabel.fontName = "Courier-Bold"
        equipmentSectionLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        equipmentSectionLabel.horizontalAlignmentMode = .left
        equipmentSectionLabel.verticalAlignmentMode = .center
        equipmentSectionLabel.zPosition = 230
        equipmentSlotsNode.addChild(equipmentSectionLabel)

        equipmentSlotsNode.zPosition = 220

        dimBackground.fillColor = SKColor(white: 0.0, alpha: 0.65)
        dimBackground.strokeColor = .clear
        dimBackground.zPosition = 200

        playerPanel.fillColor = SKColor(white: 0.08, alpha: 0.95)
        playerPanel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        playerPanel.lineWidth = 2
        playerPanel.zPosition = 210

        shuttlePanel.fillColor = SKColor(white: 0.08, alpha: 0.95)
        shuttlePanel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        shuttlePanel.lineWidth = 2
        shuttlePanel.zPosition = 210

        playerTitleLabel.fontSize = 16
        playerTitleLabel.fontName = "Courier-Bold"
        playerTitleLabel.horizontalAlignmentMode = .center
        playerTitleLabel.verticalAlignmentMode = .center
        playerTitleLabel.zPosition = 230

        shuttleTitleLabel.fontSize = 16
        shuttleTitleLabel.fontName = "Courier-Bold"
        shuttleTitleLabel.horizontalAlignmentMode = .center
        shuttleTitleLabel.verticalAlignmentMode = .center
        shuttleTitleLabel.zPosition = 230

        closeLabel.fontSize = 22
        closeLabel.name = "close"
        closeLabel.horizontalAlignmentMode = .center
        closeLabel.verticalAlignmentMode = .center
        closeLabel.zPosition = 230

        playerCropNode.zPosition = 220
        shuttleCropNode.zPosition = 220

        playerMaskNode.fillColor = .white
        playerMaskNode.strokeColor = .clear

        shuttleMaskNode.fillColor = .white
        shuttleMaskNode.strokeColor = .clear
    }

    // MARK: - Layout

    func layout(for sceneSize: CGSize) {
        self.sceneSize = sceneSize

        // Fullscreen dim
        let bgRect = CGRect(
            x: -sceneSize.width / 2,
            y: -sceneSize.height / 2,
            width: sceneSize.width,
            height: sceneSize.height
        )
        dimBackground.path = CGPath(rect: bgRect, transform: nil)

        // Detect orientation
        let isPortrait = sceneSize.height > sceneSize.width

        // Panel dimensions
        let gridWidth = CGFloat(columns) * slotSize.width + CGFloat(columns - 1) * slotSpacing
        let sidePadding: CGFloat = 16
        let panelWidth = gridWidth + sidePadding * 2
        let gap: CGFloat = 16

        let panelHeight: CGFloat
        let headerHeight: CGFloat = 48

        if isPortrait {
            // Portrait: stack panels vertically
            panelHeight = min((sceneSize.height - gap * 3) / 2, 340)
            let totalHeight = panelHeight * 2 + gap

            // Player panel (top)
            playerPanelRect = CGRect(
                x: -panelWidth / 2,
                y: totalHeight / 2 - panelHeight,
                width: panelWidth,
                height: panelHeight
            )

            // Shuttle panel (bottom)
            shuttlePanelRect = CGRect(
                x: -panelWidth / 2,
                y: -totalHeight / 2,
                width: panelWidth,
                height: panelHeight
            )
        } else {
            // Landscape: side-by-side panels
            panelHeight = min(sceneSize.height * 0.8, 420)
            let totalWidth = panelWidth * 2 + gap

            // Player panel (left)
            playerPanelRect = CGRect(
                x: -totalWidth / 2,
                y: -panelHeight / 2,
                width: panelWidth,
                height: panelHeight
            )

            // Shuttle panel (right)
            shuttlePanelRect = CGRect(
                x: playerPanelRect.maxX + gap,
                y: -panelHeight / 2,
                width: panelWidth,
                height: panelHeight
            )
        }

        playerPanel.path = CGPath(roundedRect: playerPanelRect, cornerWidth: 14, cornerHeight: 14, transform: nil)
        shuttlePanel.path = CGPath(roundedRect: shuttlePanelRect, cornerWidth: 14, cornerHeight: 14, transform: nil)

        // Headers
        playerTitleLabel.position = CGPoint(x: playerPanelRect.midX, y: playerPanelRect.maxY - 24)
        shuttleTitleLabel.position = CGPoint(x: shuttlePanelRect.midX, y: shuttlePanelRect.maxY - 24)

        // Close button (top right of player panel in portrait, shuttle panel in landscape)
        if isPortrait {
            closeLabel.position = CGPoint(x: playerPanelRect.maxX - 16, y: playerPanelRect.maxY - 24)
        } else {
            closeLabel.position = CGPoint(x: shuttlePanelRect.maxX - 16, y: shuttlePanelRect.maxY - 24)
        }

        // Equipment section layout (between header and inventory grid)
        let padding: CGFloat = 14
        let equipmentSectionHeight: CGFloat = 90 // Label + slot height + padding

        // Equipment label position
        let equipmentLabelY = playerPanelRect.maxY - headerHeight - 4
        equipmentSectionLabel.position = CGPoint(x: playerPanelRect.minX + padding, y: equipmentLabelY)

        // Equipment slots position (below label)
        let equipmentSlotsY = equipmentLabelY - 40
        let slotGap: CGFloat = 12
        let twoSlotsWidth = slotSize.width * 2 + slotGap
        let slotsStartX = playerPanelRect.midX - twoSlotsWidth / 2

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

        // Grid viewports - each panel has its own viewport
        let playerViewportTopY = playerPanelRect.maxY - headerHeight - equipmentSectionHeight
        let playerViewportBottomY = playerPanelRect.minY + padding
        let playerViewportHeight = max(0, playerViewportTopY - playerViewportBottomY)

        let shuttleViewportTopY = shuttlePanelRect.maxY - headerHeight
        let shuttleViewportBottomY = shuttlePanelRect.minY + padding
        let shuttleViewportHeight = max(0, shuttleViewportTopY - shuttleViewportBottomY)

        viewportHeight = playerViewportHeight // Used for scroll clamping

        playerGridViewportRect = CGRect(
            x: playerPanelRect.minX + padding,
            y: playerViewportBottomY,
            width: playerPanelRect.width - padding * 2,
            height: playerViewportHeight
        )

        shuttleGridViewportRect = CGRect(
            x: shuttlePanelRect.minX + padding,
            y: shuttleViewportBottomY,
            width: shuttlePanelRect.width - padding * 2,
            height: shuttleViewportHeight
        )

        // Crop masks
        playerMaskNode.path = CGPath(roundedRect: playerGridViewportRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        shuttleMaskNode.path = CGPath(roundedRect: shuttleGridViewportRect, cornerWidth: 10, cornerHeight: 10, transform: nil)

        applyScrollAndLayout()
    }

    // MARK: - Render

    func render() {
        renderGrid(playerGridNode, state: playerInventory.state, viewportRect: playerGridViewportRect, isPlayerGrid: true)
        renderGrid(shuttleGridNode, state: shuttleInventory.state, viewportRect: shuttleGridViewportRect, isPlayerGrid: false)
        renderEquipmentSlots()
        applyScrollAndLayout()
    }

    private func renderEquipmentSlots() {
        equipmentSlotsNode.removeAllChildren()
        equipmentSlotsNode.addChild(equipmentSectionLabel)

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
        let slotBorder = SKShapeNode(rect: rect, cornerRadius: 8)

        if item != nil {
            // Equipped: golden border
            slotBorder.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8)
            slotBorder.lineWidth = 2
            slotBorder.fillColor = SKColor(white: 1.0, alpha: 0.08)
        } else {
            // Empty: dimmed outline (no dashing, just lighter)
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
        if let item = item, let def = itemDefsById[item.defId] {
            let texture = SKTexture(imageNamed: def.iconName)
            let icon = SKSpriteNode(texture: texture)
            icon.size = texture.aspectFitSize(maxSize: 40)
            icon.position = CGPoint(x: rect.midX, y: rect.midY)
            equipmentSlotsNode.addChild(icon)
        }
    }

    private func renderGrid(_ gridNode: SKNode, state: InventoryState, viewportRect: CGRect, isPlayerGrid: Bool) {
        gridNode.removeAllChildren()

        let totalSlots = state.maxSlots
        updateContentMetrics(totalSlots: totalSlots, isPlayerGrid: isPlayerGrid)

        for slotIndex in 0..<totalSlots {
            let col = slotIndex % columns
            let row = slotIndex / columns

            let x = CGFloat(col) * (slotSize.width + slotSpacing)
            let y = -CGFloat(row) * (slotSize.height + slotSpacing)

            let slotFrame = CGRect(x: x, y: y - slotSize.height, width: slotSize.width, height: slotSize.height)

            let slotBorder = SKShapeNode(rect: slotFrame, cornerRadius: 8)
            slotBorder.strokeColor = SKColor(white: 1.0, alpha: 0.18)
            slotBorder.lineWidth = 2
            slotBorder.fillColor = SKColor(white: 1.0, alpha: 0.04)
            slotBorder.name = "slot_\(slotIndex)"
            gridNode.addChild(slotBorder)

            guard let slot = state.slots[slotIndex] else { continue }

            switch slot {
            case .stack(let defId, let quantity):
                if let def = itemDefsById[defId] {
                    let texture = SKTexture(imageNamed: def.iconName)
                    let icon = SKSpriteNode(texture: texture)
                    icon.size = texture.aspectFitSize(maxSize: 40)
                    icon.position = CGPoint(x: slotFrame.midX, y: slotFrame.midY)
                    gridNode.addChild(icon)

                    let qty = SKLabelNode(text: "\(quantity)")
                    qty.fontSize = 12
                    qty.fontName = "Courier-Bold"
                    qty.horizontalAlignmentMode = .right
                    qty.verticalAlignmentMode = .bottom
                    qty.position = CGPoint(x: slotFrame.maxX - 4, y: slotFrame.minY + 4)
                    gridNode.addChild(qty)
                }

            case .unique(let item):
                if let def = itemDefsById[item.defId] {
                    let texture = SKTexture(imageNamed: def.iconName)
                    let icon = SKSpriteNode(texture: texture)
                    icon.size = texture.aspectFitSize(maxSize: 40)
                    icon.position = CGPoint(x: slotFrame.midX, y: slotFrame.midY)
                    gridNode.addChild(icon)

                    // Add golden border for equipment items
                    if def.kind == .equipment {
                        let goldenBorder = SKShapeNode(rect: slotFrame.insetBy(dx: 2, dy: 2), cornerRadius: 6)
                        goldenBorder.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8)
                        goldenBorder.lineWidth = 2
                        goldenBorder.fillColor = .clear
                        goldenBorder.zPosition = 1
                        gridNode.addChild(goldenBorder)
                    }
                }
            }
        }
    }

    private func updateContentMetrics(totalSlots: Int, isPlayerGrid: Bool) {
        let rows = Int(ceil(Double(totalSlots) / Double(columns)))
        let height = CGFloat(rows) * slotSize.height + CGFloat(max(0, rows - 1)) * slotSpacing
        if isPlayerGrid {
            playerContentHeight = height
        } else {
            shuttleContentHeight = height
        }
    }

    private func applyScrollAndLayout() {
        clampScrollOffset(isPlayerGrid: true)
        clampScrollOffset(isPlayerGrid: false)

        playerGridNode.position = CGPoint(x: playerGridViewportRect.minX, y: playerGridViewportRect.maxY + playerScrollOffsetY)
        shuttleGridNode.position = CGPoint(x: shuttleGridViewportRect.minX, y: shuttleGridViewportRect.maxY + shuttleScrollOffsetY)
    }

    private func clampScrollOffset(isPlayerGrid: Bool) {
        let contentHeight = isPlayerGrid ? playerContentHeight : shuttleContentHeight
        let maxOffset = max(0, contentHeight - viewportHeight)
        if isPlayerGrid {
            playerScrollOffsetY = max(0, min(maxOffset, playerScrollOffsetY))
        } else {
            shuttleScrollOffsetY = max(0, min(maxOffset, shuttleScrollOffsetY))
        }
    }

    // MARK: - Touch Handling

    func handlePointerBegan(at p: CGPoint) {
        touchStartLocation = p

        // Close button
        if closeLabel.contains(p) {
            saveInventories()
            onClose?()
            removeFromParent()
            return
        }

        // Tap outside both panels closes the overlay
        if !playerPanelRect.contains(p) && !shuttlePanelRect.contains(p) {
            saveInventories()
            onClose?()
            removeFromParent()
            return
        }

        // Check equipment slots first (they are within player panel)
        if let equipSlot = equipmentSlot(at: p) {
            if let item = player?.equipmentManager.getEquipped(equipSlot) {
                startDragFromEquipment(slot: equipSlot, item: item, at: p)
            }
            return
        }

        // Determine which panel was tapped
        if playerGridViewportRect.contains(p) {
            activePanel = .player
            isDraggingGrid = true
            lastDragY = p.y

            // Check if tapping a slot with an item to start drag
            if let slotIndex = slotIndex(at: p, in: .player),
               let slot = playerInventory.state.slots[slotIndex] {
                startDrag(from: .player, slotIndex: slotIndex, slot: slot, at: p)
            }
        } else if shuttleGridViewportRect.contains(p) {
            activePanel = .shuttle
            isDraggingGrid = true
            lastDragY = p.y

            if let slotIndex = slotIndex(at: p, in: .shuttle),
               let slot = shuttleInventory.state.slots[slotIndex] {
                startDrag(from: .shuttle, slotIndex: slotIndex, slot: slot, at: p)
            }
        } else {
            activePanel = nil
            isDraggingGrid = false
        }
    }

    private func equipmentSlot(at point: CGPoint) -> EquipmentSlot? {
        if backpackSlotRect.contains(point) {
            return .backpack
        } else if weaponSlotRect.contains(point) {
            return .weapon
        }
        return nil
    }

    private func startDragFromEquipment(slot: EquipmentSlot, item: UniqueItemInstance, at position: CGPoint) {
        guard let def = itemDefsById[item.defId] else { return }

        dragSource = .equipment(slot: slot)
        dragSourcePanel = nil
        dragSourceSlotIndex = nil

        let dragNode = DraggedItemNode(itemDef: def, quantity: 1)
        dragNode.position = position
        dragNode.zPosition = 500
        addChild(dragNode)
        draggedItemNode = dragNode

        // Dim the equipment slot
        dimEquipmentSlot(slot)
    }

    private func dimEquipmentSlot(_ slot: EquipmentSlot) {
        let name = "equipSlot_\(slot.rawValue)"
        for child in equipmentSlotsNode.children {
            if child.name == name {
                child.alpha = 0.3
            }
        }
    }

    func handlePointerMoved(at p: CGPoint) {

        // Update dragged item position
        if let draggedNode = draggedItemNode {
            draggedNode.position = p
            updateDropHighlight(at: p)
            return
        }

        // Scroll grid if dragging
        guard isDraggingGrid, let panel = activePanel else { return }

        let dy = p.y - lastDragY
        lastDragY = p.y

        switch panel {
        case .player:
            playerScrollOffsetY += dy
        case .shuttle:
            shuttleScrollOffsetY += dy
        }
        applyScrollAndLayout()
    }

    func handlePointerEnded(at endLocation: CGPoint) {
        defer {
            cleanupDrag()
            isDraggingGrid = false
            activePanel = nil
            lastDragY = 0
            touchStartLocation = nil
            dragSource = nil
        }

        // Handle drop from equipment slot
        if draggedItemNode != nil, let source = dragSource {
            if case .equipment(let slot) = source {
                performDropFromEquipment(at: endLocation, fromSlot: slot)
                return
            }
        }

        // Handle drop from inventory
        if draggedItemNode != nil,
           let sourcePanel = dragSourcePanel,
           let sourceIndex = dragSourceSlotIndex {
            performDrop(at: endLocation, from: sourcePanel, sourceIndex: sourceIndex)
            return
        }

        // Check if it was a tap (not a drag scroll)
        guard let startLocation = touchStartLocation else { return }
        let distance = hypot(endLocation.x - startLocation.x, endLocation.y - startLocation.y)
        guard distance < 10 else { return }

        // Show tooltip on tap for equipment slots
        if let equipSlot = equipmentSlot(at: endLocation),
           let item = player?.equipmentManager.getEquipped(equipSlot),
           let def = itemDefsById[item.defId] {
            let slotRect = equipSlot == .backpack ? backpackSlotRect : weaponSlotRect
            let center = CGPoint(x: slotRect.midX, y: slotRect.midY)
            showTooltip(for: def, at: center)
            return
        }

        // Show tooltip on tap for inventory slots
        if let panel = panelAt(endLocation),
           let slotIndex = slotIndex(at: endLocation, in: panel),
           let item = itemAt(slotIndex: slotIndex, in: panel) {
            let center = slotCenter(for: slotIndex, in: panel)
            showTooltip(for: item, at: center)
        }
    }

    private func performDropFromEquipment(at position: CGPoint, fromSlot: EquipmentSlot) {
        guard let player = player else {
            render()
            return
        }

        // Can only drop to shuttle panel
        guard let targetPanel = panelAt(position), targetPanel == .shuttle else {
            render()
            return
        }

        // Check if shuttle has space
        guard shuttleInventory.freeSlots > 0 else {
            render()
            return
        }

        // Unequip the item
        let item: UniqueItemInstance?
        switch fromSlot {
        case .backpack:
            item = player.unequipBackpack()
        case .weapon:
            item = player.unequipBlaster()
        }

        guard let unequippedItem = item else {
            render()
            return
        }

        // Add to shuttle inventory, preserving the item's identity
        shuttleInventory.addExistingUnique(unequippedItem)

        onEquip?(unequippedItem.defId)
        onTransfer?()
        render()
    }

    // MARK: - Drag and Drop

    private func startDrag(from panel: PanelSide, slotIndex: Int, slot: InventorySlot, at position: CGPoint) {
        dragSourcePanel = panel
        dragSourceSlotIndex = slotIndex
        dragSource = .inventory(panel: panel, slotIndex: slotIndex)

        let defId: String
        let quantity: Int

        switch slot {
        case .stack(let id, let qty):
            defId = id
            quantity = qty
        case .unique(let item):
            defId = item.defId
            quantity = 1
        }

        guard let def = itemDefsById[defId] else { return }

        let dragNode = DraggedItemNode(itemDef: def, quantity: quantity)
        dragNode.position = position
        dragNode.zPosition = 500
        addChild(dragNode)
        draggedItemNode = dragNode

        // Dim the source slot
        dimSlot(at: slotIndex, in: panel)
    }

    private func performDrop(at position: CGPoint, from sourcePanel: PanelSide, sourceIndex: Int) {
        let sourceInventory = sourcePanel == .player ? playerInventory : shuttleInventory

        guard let slot = sourceInventory.state.slots[sourceIndex] else {
            render()
            return
        }

        // Check if dropping onto an equipment slot (only from shuttle)
        if sourcePanel == .shuttle, let targetEquipSlot = equipmentSlot(at: position) {
            if case .unique(let item) = slot,
               let def = itemDefsById[item.defId],
               def.kind == .equipment,
               let player = player {
                // Verify item matches the slot type
                let matchesSlot = (targetEquipSlot == .backpack && item.defId == ItemID.backpack) ||
                                  (targetEquipSlot == .weapon && item.defId == ItemID.blaster)
                if matchesSlot {
                    // Check if slot is already occupied
                    if player.equipmentManager.getEquipped(targetEquipSlot) == nil {
                        // Remove from shuttle and equip
                        if sourceInventory.removeUnique(instanceId: item.instanceId) {
                            if targetEquipSlot == .backpack {
                                player.equipBackpack(item: item)
                            } else {
                                player.equipBlaster(item: item)
                            }
                            onEquip?(item.defId)
                            onTransfer?()
                        }
                    }
                }
            }
            render()
            return
        }

        // Regular inventory transfer
        guard let targetPanel = panelAt(position) else {
            render()
            return
        }

        // Only allow cross-panel transfers
        guard targetPanel != sourcePanel else {
            render()
            return
        }

        let targetInventory = targetPanel == .player ? playerInventory : shuttleInventory

        // Perform transfer
        switch slot {
        case .stack(let defId, let quantity):
            // Remove from source
            let removed = sourceInventory.remove(defId: defId, quantity: quantity)
            if removed > 0 {
                // Add to target
                let added = targetInventory.add(defId: defId, quantity: removed)
                // Return excess to source if target was full
                let excess = removed - added
                if excess > 0 {
                    sourceInventory.add(defId: defId, quantity: excess)
                }
            }

        case .unique(let item):
            // Check if this is equipment being transferred to player panel (auto-equip)
            if targetPanel == .player,
               let def = itemDefsById[item.defId],
               def.kind == .equipment,
               let player = player {
                // Remove from source
                if sourceInventory.removeUnique(instanceId: item.instanceId) {
                    // Equip instead of adding to inventory
                    if item.defId == ItemID.backpack {
                        player.equipBackpack(item: item)
                    } else if item.defId == ItemID.blaster {
                        player.equipBlaster(item: item)
                    }
                    onEquip?(item.defId)
                }
            } else {
                // Regular transfer
                // Check if target has space
                guard targetInventory.freeSlots > 0 else {
                    render()
                    return
                }
                // Remove from source
                if sourceInventory.removeUnique(instanceId: item.instanceId) {
                    // Add to target
                    targetInventory.addUnique(defId: item.defId, count: 1)
                }
            }
        }

        onTransfer?()
        render()
    }

    private func updateDropHighlight(at position: CGPoint) {
        // Clear previous highlights
        clearAllHighlights()

        // Check if dragging from equipment slot
        if let source = dragSource, case .equipment = source {
            // Can only drop to shuttle
            if shuttlePanelRect.contains(position) {
                shuttlePanel.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.8)
                shuttlePanel.lineWidth = 3
            }
            return
        }

        // Check if dragging equipment to equipment slot
        if let sourcePanel = dragSourcePanel,
           sourcePanel == .shuttle,
           let targetEquipSlot = equipmentSlot(at: position) {
            highlightEquipmentSlot(targetEquipSlot)
            return
        }

        // Highlight drop zone if over different panel
        guard let targetPanel = panelAt(position),
              let sourcePanel = dragSourcePanel,
              targetPanel != sourcePanel else { return }

        let panelNode = targetPanel == .player ? playerPanel : shuttlePanel
        panelNode.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.8)
        panelNode.lineWidth = 3
    }

    private func highlightEquipmentSlot(_ slot: EquipmentSlot) {
        let name = "equipSlot_\(slot.rawValue)"
        for child in equipmentSlotsNode.children {
            if let shapeNode = child as? SKShapeNode, shapeNode.name == name {
                shapeNode.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.9)
                shapeNode.lineWidth = 3
            }
        }
    }

    private func clearAllHighlights() {
        playerPanel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        playerPanel.lineWidth = 2
        shuttlePanel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        shuttlePanel.lineWidth = 2

        // Re-render equipment slots to reset their styling
        renderEquipmentSlots()
    }

    private func dimSlot(at index: Int, in panel: PanelSide) {
        let gridNode = panel == .player ? playerGridNode : shuttleGridNode
        for child in gridNode.children {
            if child.name == "slot_\(index)" {
                child.alpha = 0.3
            }
        }
    }

    private func cleanupDrag() {
        draggedItemNode?.removeFromParent()
        draggedItemNode = nil
        dragSourcePanel = nil
        dragSourceSlotIndex = nil
        clearAllHighlights()
    }

    // MARK: - Helpers

    private func panelAt(_ point: CGPoint) -> PanelSide? {
        if playerGridViewportRect.contains(point) || playerPanelRect.contains(point) {
            return .player
        } else if shuttleGridViewportRect.contains(point) || shuttlePanelRect.contains(point) {
            return .shuttle
        }
        return nil
    }

    private func slotIndex(at cameraPoint: CGPoint, in panel: PanelSide) -> Int? {
        let viewportRect = panel == .player ? playerGridViewportRect : shuttleGridViewportRect
        let gridNode = panel == .player ? playerGridNode : shuttleGridNode
        let state = panel == .player ? playerInventory.state : shuttleInventory.state

        guard viewportRect.contains(cameraPoint) else { return nil }

        let gridLocalX = cameraPoint.x - gridNode.position.x
        let gridLocalY = cameraPoint.y - gridNode.position.y

        let strideX = slotSize.width + slotSpacing
        let strideY = slotSize.height + slotSpacing

        let col = Int(floor(gridLocalX / strideX))
        let row = Int(floor(-gridLocalY / strideY))

        guard col >= 0, col < columns, row >= 0 else { return nil }

        let index = row * columns + col
        guard index >= 0, index < state.maxSlots else { return nil }
        return index
    }

    private func itemAt(slotIndex: Int, in panel: PanelSide) -> ItemDef? {
        let state = panel == .player ? playerInventory.state : shuttleInventory.state
        guard slotIndex >= 0, slotIndex < state.slots.count,
              let slot = state.slots[slotIndex] else { return nil }

        switch slot {
        case .stack(let defId, _):
            return itemDefsById[defId]
        case .unique(let item):
            return itemDefsById[item.defId]
        }
    }

    private func slotCenter(for slotIndex: Int, in panel: PanelSide) -> CGPoint {
        let gridNode = panel == .player ? playerGridNode : shuttleGridNode

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

    private func showTooltip(for item: ItemDef, at position: CGPoint) {
        let label = SKLabelNode(text: item.displayName)
        label.fontName = "Courier-Bold"
        label.fontSize = 12
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 400

        let padding: CGFloat = 6
        let bgWidth = label.frame.width + padding * 2
        let bgHeight = label.frame.height + padding

        let background = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: 5)
        background.fillColor = SKColor(white: 0.1, alpha: 0.9)
        background.strokeColor = SKColor(white: 1.0, alpha: 0.2)
        background.lineWidth = 1
        background.zPosition = 399

        let container = SKNode()
        container.addChild(background)
        container.addChild(label)
        container.position = CGPoint(x: position.x, y: position.y + slotSize.height / 2 + 8)
        addChild(container)

        let moveUp = SKAction.moveBy(x: 0, y: 25, duration: 0.8)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()

        container.run(SKAction.sequence([group, remove]))
    }

    private func saveInventories() {
        try? InventoryStorage.save(playerInventory.state, for: .player)
        try? InventoryStorage.save(shuttleInventory.state, for: .shuttle)
    }
}
