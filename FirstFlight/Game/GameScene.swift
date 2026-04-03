//
//  GameScene.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import SpriteKit
import OSLog

final class GameScene: SKScene {
    private var inventory: Inventory!
    private var shuttleInventory: Inventory!
    private var equipmentManager: EquipmentManager!
    private var astronaut: Player!

    private var gameCamera: SKCameraNode!
    private var rockFormations: [RockFormation] = []
    private var lakes: [LakeNode] = []
    private var boundaryRocks: [RockFormation] = []
    private var spaceShuttle: SpaceShuttle?

    private var cameraController: CameraController!
    private var combatManager: CombatManager!
    private var uiManager: UIManager!

    // Debug mode flag
    var showDebugLabels: Bool = ProcessInfo.processInfo.environment["SHOW_DEBUG_LABELS"] == "1"

    private var lastUpdateTime: TimeInterval = 0

    // Map size (stored separately because scene.size changes with scaleMode)
    private var mapSize: CGSize = .zero

    override func didMove(to view: SKView) {
        setupScene()
        createCharacters()
        loadMapFromJSON()
        setupManagers()
    }

    private func setupScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }

    private func createCharacters() {
        let defs = ItemCatalog.allDefs

        // Player inventory (12 slots)
        let playerState = (try? InventoryStorage.loadOrCreate(for: .player, defaultMaxSlots: 12))
            ?? InventoryState(maxSlots: 12)
        inventory = Inventory(state: playerState, defs: defs)

        // Shuttle inventory (24 slots - double player capacity)
        var shuttleState = (try? InventoryStorage.loadOrCreate(for: .shuttle, defaultMaxSlots: 24))
            ?? InventoryState(maxSlots: 24)

        // Equipment state
        let equipmentState = (try? EquipmentStorage.loadOrCreate()) ?? EquipmentState()
        equipmentManager = EquipmentManager(state: equipmentState)

        // First launch detection: if equipment storage doesn't exist,
        // add starting equipment to shuttle inventory
        let isFirstLaunch = !EquipmentStorage.exists()
        if isFirstLaunch {
            if let backpackDef = ItemCatalog.defsById["backpack"] {
                let backpackItem = UniqueItemInstance(instanceId: UUID(), defId: backpackDef.id)
                if let emptySlot = shuttleState.slots.firstIndex(where: { $0 == nil }) {
                    shuttleState.slots[emptySlot] = .unique(item: backpackItem)
                }
            }
            if let blasterDef = ItemCatalog.defsById["blaster"] {
                let blasterItem = UniqueItemInstance(instanceId: UUID(), defId: blasterDef.id)
                if let emptySlot = shuttleState.slots.firstIndex(where: { $0 == nil }) {
                    shuttleState.slots[emptySlot] = .unique(item: blasterItem)
                }
            }
            try? EquipmentStorage.save(equipmentState)
            try? InventoryStorage.save(shuttleState, for: .shuttle)
        }

        // Migration: ensure backpack & blaster exist somewhere for old installs
        // that missed the first-launch grant
        let hasBackpack = equipmentState.equippedItems[.backpack] != nil
            || playerState.slots.contains(where: { slot in
                if case .unique(let item) = slot, item.defId == "backpack" { return true }
                return false
            })
            || shuttleState.slots.contains(where: { slot in
                if case .unique(let item) = slot, item.defId == "backpack" { return true }
                return false
            })

        let hasBlaster = equipmentState.equippedItems[.weapon] != nil
            || playerState.slots.contains(where: { slot in
                if case .unique(let item) = slot, item.defId == "blaster" { return true }
                return false
            })
            || shuttleState.slots.contains(where: { slot in
                if case .unique(let item) = slot, item.defId == "blaster" { return true }
                return false
            })

        var needsShuttleSave = false
        if !hasBackpack {
            let item = UniqueItemInstance(instanceId: UUID(), defId: "backpack")
            if let emptySlot = shuttleState.slots.firstIndex(where: { $0 == nil }) {
                shuttleState.slots[emptySlot] = .unique(item: item)
                needsShuttleSave = true
            }
        }
        if !hasBlaster {
            let item = UniqueItemInstance(instanceId: UUID(), defId: "blaster")
            if let emptySlot = shuttleState.slots.firstIndex(where: { $0 == nil }) {
                shuttleState.slots[emptySlot] = .unique(item: item)
                needsShuttleSave = true
            }
        }
        if needsShuttleSave {
            try? InventoryStorage.save(shuttleState, for: .shuttle)
        }

        shuttleInventory = Inventory(state: shuttleState, defs: defs)

        astronaut = Player(inventory: inventory, equipmentManager: equipmentManager)

        if astronaut.parent == nil {
            addChild(astronaut)
        }
    }

    private func setupManagers() {
        // Camera
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        gameCamera.position = astronaut.position

        cameraController = CameraController(camera: gameCamera, scene: self)
        cameraController.setMapSize(mapSize)
        cameraController.updateConstraints()

        // UI
        uiManager = UIManager(
            scene: self,
            camera: gameCamera,
            player: astronaut,
            inventory: inventory,
            shuttleInventory: shuttleInventory
        )
        uiManager.onSaveInventories = { [weak self] in self?.saveInventories() }
        uiManager.onSaveEquipment = { [weak self] in self?.saveEquipment() }
        #if os(macOS)
        uiManager.virtualJoystick.onJumpStart = { [weak self] in self?.handleJumpStart() }
        uiManager.virtualJoystick.onJumpEnd = { [weak self] in self?.handleJumpEnd() }
        #endif

        // Combat
        combatManager = CombatManager(scene: self, player: astronaut, energyBar: uiManager.energyBar)
        combatManager.onRockDestroyed = { [weak self] rock in self?.destroyRock(rock) }
    }

    private func loadMapFromJSON() {
        do {
            let mapData = try MapLoader.shared.loadMap(named: "Map1")

            let grid = MapLoader.shared.getTileGrid(from: mapData)
            let tileMap = TileMap(grid: grid)

            mapSize = CGSize(
                width: CGFloat(tileMap.tileColumns) * tileMap.tileSize,
                height: CGFloat(tileMap.tileRows) * tileMap.tileSize
            )
            size = mapSize

            // Invisible physics boundary
            let mapRect = CGRect(origin: .zero, size: mapSize)
            let boundary = SKNode()
            boundary.physicsBody = SKPhysicsBody(edgeLoopFrom: mapRect)
            boundary.physicsBody?.categoryBitMask = PhysicsCategory.wall
            boundary.physicsBody?.collisionBitMask = PhysicsCategory.player
            addChild(boundary)

            addChild(tileMap.createNode())

            if showDebugLabels {
                Logger.game.debug("Loaded: tileSize: \(tileMap.tileSize), columns: \(tileMap.tileColumns), rows: \(tileMap.tileRows), scene.size: \(self.size.width)x\(self.size.height)")
            }

            astronaut.position = MapLoader.shared.getPlayerStartPosition(from: mapData)

            if let shuttle = MapNodeFactory.createSpaceShuttle(from: mapData, inventory: shuttleInventory) {
                addChild(shuttle)
                spaceShuttle = shuttle
            }

            let rocks = MapNodeFactory.createAllRocks(from: mapData)

            boundaryRocks = rocks.boundary
            for rock in boundaryRocks {
                addChild(rock)
                if showDebugLabels { rock.addDebugLabel() }
            }

            for rock in rocks.interior {
                addChild(rock)
                rockFormations.append(rock)
                if showDebugLabels { rock.addDebugLabel() }
            }

            for rock in rocks.signature {
                addChild(rock)
                rockFormations.append(rock)
                if showDebugLabels { rock.addDebugLabel() }
            }

            lakes = MapNodeFactory.createLakes(from: mapData)
            for lake in lakes { addChild(lake) }

            let rockGenerator = DecorativeRockGenerator(sceneSize: size)
            let smallRocks = rockGenerator.generateDecorativeSmallRocks(
                totalCount: 150,
                anchoredFraction: 0.8,
                interiorRocks: rocks.interior,
                lakes: lakes
            )
            for smallRock in smallRocks { addChild(smallRock) }

        } catch {
            Logger.game.error("Failed to load Map1.json: \(error.localizedDescription)")
            showMapLoadError(error)
        }
    }

    private func showMapLoadError(_ error: Error) {
        backgroundColor = .black
        let label = SKLabelNode(text: "Failed to load map")
        label.fontColor = .red
        label.fontSize = 24
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 10_000
        addChild(label)

        let detail = SKLabelNode(text: error.localizedDescription)
        detail.fontColor = .gray
        detail.fontSize = 14
        detail.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        detail.zPosition = 10_000
        detail.preferredMaxLayoutWidth = size.width - 40
        detail.numberOfLines = 0
        addChild(detail)
    }

    // MARK: - Persistence

    private func saveInventories() {
        do { try InventoryStorage.save(inventory.state, for: .player) }
        catch { Logger.persistence.error("Failed to save player inventory: \(error)") }
        do { try InventoryStorage.save(shuttleInventory.state, for: .shuttle) }
        catch { Logger.persistence.error("Failed to save shuttle inventory: \(error)") }
    }

    private func saveEquipment() {
        do { try EquipmentStorage.save(equipmentManager.state) }
        catch { Logger.persistence.error("Failed to save equipment: \(error)") }
    }

    // MARK: - Input Handling

    private func pointerLocation(in node: SKNode, from point: CGPoint) -> CGPoint {
        guard let cam = camera else { return point }
        return cam.convert(point, from: node)
    }

    private func handlePointerBegan(at scenePoint: CGPoint) {
        guard let cam = camera else { return }
        let camPoint = convert(scenePoint, to: cam)
        if uiManager.handleOverlayPointerBegan(at: camPoint) { return }
        handleTap(at: scenePoint)
    }

    private func handlePointerMoved(at scenePoint: CGPoint) {
        guard let cam = camera else { return }
        let camPoint = convert(scenePoint, to: cam)
        _ = uiManager.handleOverlayPointerMoved(at: camPoint)
    }

    private func handlePointerEnded(at scenePoint: CGPoint) {
        guard let cam = camera else { return }
        let camPoint = convert(scenePoint, to: cam)
        _ = uiManager.handleOverlayPointerEnded(at: camPoint)
    }

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handlePointerBegan(at: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handlePointerMoved(at: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handlePointerEnded(at: touch.location(in: self))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handlePointerEnded(at: touch.location(in: self))
    }
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        handlePointerBegan(at: event.location(in: self))
    }

    override func mouseDragged(with event: NSEvent) {
        handlePointerMoved(at: event.location(in: self))
    }

    override func mouseUp(with event: NSEvent) {
        handlePointerEnded(at: event.location(in: self))
    }

    override func keyDown(with event: NSEvent) {
        uiManager.virtualJoystick.handleKeyDown(event.keyCode)
    }

    override func keyUp(with event: NSEvent) {
        uiManager.virtualJoystick.handleKeyUp(event.keyCode)
    }
    #endif

    private func handleTap(at location: CGPoint) {
        let tappedNodes = nodes(at: location)
        if tappedNodes.contains(where: { $0 === astronaut || $0.inParentHierarchy(astronaut) }) {
            uiManager.toggleInventoryOverlay()
            return
        }

        if let shuttle = spaceShuttle,
           let bodyAtLocation = physicsWorld.body(at: location),
           bodyAtLocation === shuttle.physicsBody {
            uiManager.toggleTransferOverlay()
            return
        }

        guard astronaut.hasBlaster else { return }
        for node in tappedNodes {
            if let rock = node as? RockFormation {
                combatManager.startFiring(at: rock)
                return
            }
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        uiManager?.updateLayout(for: size)
        cameraController?.updateConstraints()
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        updateCharacterMovement()
        cameraController.follow(astronaut)
        combatManager.update(deltaTime: deltaTime)
        if astronaut.isFiring {
            cameraController.applyJitter()
        }
        uiManager.updateEnergyRecharge(deltaTime: deltaTime)
    }

    private func updateCharacterMovement() {
        guard let joystick = uiManager.virtualJoystick else { return }
        let direction = joystick.currentDirection

        guard let aimAngle = joystick.currentAngle else {
            astronaut.stopMovement()
            return
        }

        if combatManager.currentTarget == nil {
            astronaut.updatePlayerDirection(angle: aimAngle)
        }

        let magnitude = hypot(direction.dx, direction.dy)
        let movementThreshold: CGFloat = 0.5

        if magnitude > movementThreshold || astronaut.isWalking {
            if combatManager.currentTarget != nil {
                combatManager.stopFiring()
            }
            astronaut.moveInDirection(direction: direction)
        } else {
            astronaut.stopMovement()
        }
    }

    // MARK: - Jump

    #if os(macOS)
    private func handleJumpStart() {
        guard !astronaut.isJumping else { return }

        if astronaut.equipmentManager.hasBackpack {
            // Start normal jump immediately, but schedule jetpack transition
            astronaut.jump()
            let jetpackDelay = SKAction.sequence([
                SKAction.wait(forDuration: 0.15),
                SKAction.run { [weak self] in
                    guard let self else { return }
                    // If still jumping (space held), transition to jetpack
                    if self.astronaut.isJumping && !self.astronaut.isJetpackJumping {
                        self.astronaut.jetpackJump()
                    }
                }
            ])
            run(jetpackDelay, withKey: "jetpackHoldTimer")
        } else {
            astronaut.jump()
        }
    }

    private func handleJumpEnd() {
        removeAction(forKey: "jetpackHoldTimer")
        if astronaut.isJetpackJumping {
            astronaut.endJetpackJump()
        }
    }
    #endif

    // MARK: - Rock Destruction

    private func destroyRock(_ rock: RockFormation) {
        if let index = rockFormations.firstIndex(of: rock) {
            rockFormations.remove(at: index)
        }

        if combatManager.currentTarget === rock {
            combatManager.stopFiring()
        }

        // Extract remaining elements
        let remainingElements = rock.extractAllRemaining()
        if !remainingElements.isEmpty {
            var actuallyAdded: [ElementType: Int] = [:]
            for (element, amount) in remainingElements {
                guard amount > 0 else { continue }
                let added = astronaut.inventory.add(element, amount: amount)
                if added > 0 {
                    actuallyAdded[element, default: 0] += added
                }
            }
            if !actuallyAdded.isEmpty {
                ElementPopup.spawn(elements: actuallyAdded, at: rock.centerPosition, in: self)
            }
        }

        rock.spawnDestructionParticles(in: self)

        // Camera shake if near the player
        let center = rock.centerPosition
        if hypot(center.x - astronaut.position.x, center.y - astronaut.position.y) < 220 {
            cameraController.shake()
        }

        rock.performDestructionAnimation { }
    }
}

// MARK: - Physics Contact

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if showDebugLabels {
            let bodyANode = contact.bodyA.node
            let bodyBNode = contact.bodyB.node
            let bodyASize = bodyANode?.calculateAccumulatedFrame().size ?? .zero
            let bodyBSize = bodyBNode?.calculateAccumulatedFrame().size ?? .zero
            Logger.physics.debug("COLLISION: point: \(contact.contactPoint.x),\(contact.contactPoint.y) bodyA: \(contact.bodyA.categoryBitMask) (\(self.categoryName(contact.bodyA.categoryBitMask))) node: \(String(describing: bodyANode)) size: \(bodyASize.width)x\(bodyASize.height) bodyB: \(contact.bodyB.categoryBitMask) (\(self.categoryName(contact.bodyB.categoryBitMask))) node: \(String(describing: bodyBNode)) size: \(bodyBSize.width)x\(bodyBSize.height)")
        }

        if collision == PhysicsCategory.player | PhysicsCategory.wall ||
           collision == PhysicsCategory.player | PhysicsCategory.rock ||
           collision == PhysicsCategory.player | PhysicsCategory.spaceShuttle {
            astronaut.stopMovement()
        }

        if collision == PhysicsCategory.blasterBeam | PhysicsCategory.rock {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? RockFormation {
                combatManager.rocksBeingDamaged.insert(rock)
            }
        }

        if collision == PhysicsCategory.player | PhysicsCategory.terrain {
            astronaut.setInWater(true)
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsCategory.blasterBeam | PhysicsCategory.rock {
            let rockBody = contact.bodyA.categoryBitMask == PhysicsCategory.rock ? contact.bodyA : contact.bodyB
            if let rock = rockBody.node as? RockFormation {
                combatManager.rocksBeingDamaged.remove(rock)
            }
        }

        if collision == PhysicsCategory.player | PhysicsCategory.terrain {
            astronaut.setInWater(false)
        }
    }

    private func categoryName(_ category: UInt32) -> String {
        switch category {
        case PhysicsCategory.player: return "Player"
        case PhysicsCategory.wall: return "Wall"
        case PhysicsCategory.rock: return "Rock"
        case PhysicsCategory.terrain: return "Terrain"
        case PhysicsCategory.blasterBeam: return "BlasterBeam"
        case PhysicsCategory.spaceShuttle: return "SpaceShuttle"
        default: return "Unknown(\(category))"
        }
    }
}

// MARK: - Testing Hooks

extension GameScene {
    var playerForTesting: Player { astronaut }
    var targetableRocksForTesting: [RockFormation] { rockFormations }
    var currentTargetForTesting: RockFormation? { combatManager.currentTarget }
    var cameraPositionForTesting: CGPoint { gameCamera.position }

    func handleTapForTesting(at location: CGPoint) {
        handleTap(at: location)
    }

    func beginDamagingRockForTesting(_ rock: RockFormation) {
        combatManager.rocksBeingDamaged.insert(rock)
    }

    func stopFiringForTesting() {
        combatManager.stopFiring()
    }

    func setJoystickDirectionForTesting(_ direction: CGVector) {
        uiManager?.virtualJoystick?.currentDirection = direction
    }

    func setPlayerPositionForTesting(_ position: CGPoint) {
        astronaut.position = position
    }
}
