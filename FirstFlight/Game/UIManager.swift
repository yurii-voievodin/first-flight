import SpriteKit

final class UIManager {
    private weak var scene: GameScene?
    private weak var camera: SKCameraNode?
    private weak var player: Player?

    private(set) var virtualJoystick: VirtualJoystick!
    private(set) var energyBar: EnergyBar!

    private var inventoryOverlay: InventoryOverlayNode?
    private var transferOverlay: TransferOverlayNode?

    private var inventory: Inventory
    private var shuttleInventory: Inventory
    private let energyRechargePerSecond: CGFloat = 2.5

    var onSaveInventories: (() -> Void)?
    var onSaveEquipment: (() -> Void)?

    init(scene: GameScene, camera: SKCameraNode, player: Player, inventory: Inventory, shuttleInventory: Inventory) {
        self.scene = scene
        self.camera = camera
        self.player = player
        self.inventory = inventory
        self.shuttleInventory = shuttleInventory

        setupJoystick()
        setupEnergyBar()
    }

    // MARK: - Setup

    private func setupJoystick() {
        virtualJoystick = VirtualJoystick()
        virtualJoystick.zPosition = 100
        #if os(iOS)
        camera?.addChild(virtualJoystick)
        #endif
        updateJoystickPosition()
    }

    private func setupEnergyBar() {
        energyBar = EnergyBar()
        energyBar.zPosition = 100
        camera?.addChild(energyBar)
        updateEnergyBarPosition()
        if let player {
            energyBar.update(currentEnergy: player.currentEnergy, maxEnergy: player.maxEnergy, animated: false)
        }
    }

    // MARK: - Layout

    func updateLayout(for sceneSize: CGSize) {
        updateJoystickPosition()
        updateEnergyBarPosition()
        inventoryOverlay?.layout(for: sceneSize)
        transferOverlay?.layout(for: sceneSize)
    }

    private func updateJoystickPosition() {
        guard let view = scene?.view, virtualJoystick != nil else { return }

        #if os(iOS)
        let safeArea = view.safeAreaInsets
        let bottomInset = safeArea.bottom
        #else
        let bottomInset: CGFloat = 30
        #endif
        let joystickRadius: CGFloat = 40
        let margin: CGFloat = 20

        let xPosition: CGFloat = 0
        let yPosition = -view.bounds.height / 2 + bottomInset + joystickRadius + margin

        virtualJoystick.position = CGPoint(x: xPosition, y: yPosition)
    }

    private func updateEnergyBarPosition() {
        guard scene?.view != nil, energyBar != nil, virtualJoystick != nil else { return }

        let joystickRadius: CGFloat = 40
        let margin: CGFloat = 20

        let xPosition: CGFloat = 0
        let yPosition = virtualJoystick.position.y - joystickRadius - margin

        energyBar.position = CGPoint(x: xPosition, y: yPosition)
    }

    // MARK: - Energy Recharge

    func updateEnergyRecharge(deltaTime: TimeInterval) {
        guard let player, deltaTime > 0 else { return }
        guard energyBar.isRecharging else { return }

        guard player.isInWater else {
            energyBar.stopRecharging()
            return
        }

        let rechargeAmount = energyRechargePerSecond * CGFloat(deltaTime)
        player.addEnergy(rechargeAmount)
        energyBar.update(currentEnergy: player.currentEnergy, maxEnergy: player.maxEnergy)

        if player.currentEnergy >= player.maxEnergy {
            energyBar.checkEnergyFull()
        }
    }

    func updateRechargeButtonVisibility() {
        guard let player else { return }
        energyBar.updateRechargeButtonVisibility(isInWater: player.isInWater)
    }

    // MARK: - Overlays

    var hasActiveOverlay: Bool {
        inventoryOverlay != nil || transferOverlay != nil
    }

    func handleOverlayPointerBegan(at point: CGPoint) -> Bool {
        if let overlay = transferOverlay {
            overlay.handlePointerBegan(at: point)
            return true
        }
        if let overlay = inventoryOverlay {
            overlay.handlePointerBegan(at: point)
            return true
        }
        return false
    }

    func handleOverlayPointerMoved(at point: CGPoint) -> Bool {
        if let overlay = transferOverlay {
            overlay.handlePointerMoved(at: point)
            return true
        }
        if let overlay = inventoryOverlay {
            overlay.handlePointerMoved(at: point)
            return true
        }
        return false
    }

    func handleOverlayPointerEnded(at point: CGPoint) -> Bool {
        if let overlay = transferOverlay {
            overlay.handlePointerEnded(at: point)
            return true
        }
        if let overlay = inventoryOverlay {
            overlay.handlePointerEnded(at: point)
            return true
        }
        return false
    }

    func toggleInventoryOverlay() {
        guard let scene, let camera, let player else { return }

        if inventoryOverlay != nil {
            inventoryOverlay?.removeFromParent()
            inventoryOverlay = nil
            return
        }

        let overlay = InventoryOverlayNode()
        overlay.onClose = { [weak self] in
            self?.inventoryOverlay = nil
        }
        overlay.zPosition = 10_000
        overlay.layout(for: scene.size)
        overlay.render(state: inventory.state, defsById: ItemCatalog.defsById, player: player)
        camera.addChild(overlay)
        inventoryOverlay = overlay
    }

    func toggleTransferOverlay() {
        guard let scene, let camera, let player else { return }

        if transferOverlay != nil {
            transferOverlay?.removeFromParent()
            transferOverlay = nil
            return
        }

        let overlay = TransferOverlayNode(
            playerInventory: inventory,
            shuttleInventory: shuttleInventory,
            itemDefsById: ItemCatalog.defsById,
            player: player
        )
        overlay.onClose = { [weak self] in
            self?.transferOverlay = nil
            self?.onSaveInventories?()
            self?.onSaveEquipment?()
        }
        overlay.onTransfer = { [weak self] in
            self?.onSaveInventories?()
        }
        overlay.onEquip = { [weak self] _ in
            self?.onSaveEquipment?()
            self?.onSaveInventories?()
        }
        overlay.zPosition = 10_000
        overlay.layout(for: scene.size)
        overlay.render()
        camera.addChild(overlay)
        transferOverlay = overlay
    }
}
