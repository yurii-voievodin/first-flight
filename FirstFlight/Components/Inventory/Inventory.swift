import Foundation

/// Inventory that supports slot capacity + stackable/unstackable items.
///
/// - Capacity is measured in *slots*.
/// - Stackable items occupy a slot per stack and have a `maxStack`.
/// - Unstackable items occupy one slot per instance.
final class Inventory {

    // Persisted state (save/load as JSON)
    private(set) var state: InventoryState

    // Item catalog (definitions)
    private let defs: [String: ItemDef]

    init(state: InventoryState, defs: [ItemDef]) {
        self.state = state
        self.defs = Dictionary(uniqueKeysWithValues: defs.map { ($0.id, $0) })

        // Safety: ensure slots array matches maxSlots
        if self.state.slots.count != self.state.maxSlots {
            let trimmed = Array(self.state.slots.prefix(self.state.maxSlots))
            let paddingCount = max(0, self.state.maxSlots - trimmed.count)
            self.state.slots = trimmed + Array(repeating: nil, count: paddingCount)
        }
    }

    // MARK: - Capacity

    var maxSlots: Int { state.maxSlots }

    var usedSlots: Int {
        state.slots.reduce(into: 0) { acc, slot in
            if slot != nil { acc += 1 }
        }
    }

    var freeSlots: Int { maxSlots - usedSlots }

    func setMaxSlots(_ newValue: Int) {
        let clamped = max(0, newValue)
        state.maxSlots = clamped

        if state.slots.count > clamped {
            state.slots = Array(state.slots.prefix(clamped))
        } else if state.slots.count < clamped {
            state.slots.append(contentsOf: Array(repeating: nil, count: clamped - state.slots.count))
        }
    }

    // MARK: - Add

    /// Adds stackable items (or creates instances if `maxStack == nil`).
    /// - Returns: how many units were actually added.
    @discardableResult
    func add(defId: String, quantity: Int) -> Int {
        guard quantity > 0 else { return 0 }
        guard let def = defs[defId] else { return 0 }

        // Unstackable => quantity means number of instances
        if def.maxStack == nil {
            return addUnique(defId: defId, count: quantity)
        }

        let maxStack = def.maxStack!
        var remaining = quantity

        // 1) Fill existing stacks first
        for i in state.slots.indices {
            guard remaining > 0 else { break }
            if case .stack(let id, let q)? = state.slots[i], id == defId, q < maxStack {
                let canAdd = min(maxStack - q, remaining)
                state.slots[i] = .stack(defId: defId, quantity: q + canAdd)
                remaining -= canAdd
            }
        }

        // 2) Create new stacks in empty slots
        for i in state.slots.indices {
            guard remaining > 0 else { break }
            if state.slots[i] == nil {
                let put = min(maxStack, remaining)
                state.slots[i] = .stack(defId: defId, quantity: put)
                remaining -= put
            }
        }

        return quantity - remaining
    }

    /// Adds unstackable items.
    /// - Returns: how many instances were actually added.
    @discardableResult
    func addUnique(defId: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        guard let def = defs[defId], def.maxStack == nil else { return 0 }

        var remaining = count
        for i in state.slots.indices {
            guard remaining > 0 else { break }
            if state.slots[i] == nil {
                state.slots[i] = .unique(item: .init(instanceId: UUID(), defId: defId))
                remaining -= 1
            }
        }
        return count - remaining
    }

    // Convenience bridge for your existing rock-mining calls.
    // NOTE: This uses `element.rawValue` as the defId, so your ItemDef catalog should use the same id.
    @discardableResult
    func add(_ element: ElementType, amount: Int) -> Int {
        add(defId: element.rawValue, quantity: amount)
    }

    // MARK: - Remove

    /// Removes stackable units.
    /// - Returns: how many units were actually removed.
    @discardableResult
    func remove(defId: String, quantity: Int) -> Int {
        guard quantity > 0 else { return 0 }
        var remaining = quantity

        // Remove from the end to keep earlier stacks stable
        for i in state.slots.indices.reversed() {
            guard remaining > 0 else { break }
            guard case .stack(let id, let q)? = state.slots[i], id == defId else { continue }

            if q <= remaining {
                state.slots[i] = nil
                remaining -= q
            } else {
                state.slots[i] = .stack(defId: defId, quantity: q - remaining)
                remaining = 0
            }
        }

        return quantity - remaining
    }

    /// Removes an unstackable instance by id.
    /// - Returns: true if removed.
    func removeUnique(instanceId: UUID) -> Bool {
        for i in state.slots.indices {
            if case .unique(let item)? = state.slots[i], item.instanceId == instanceId {
                state.slots[i] = nil
                return true
            }
        }
        return false
    }

    // MARK: - Queries

    func totalQuantity(defId: String) -> Int {
        state.slots.reduce(into: 0) { acc, slot in
            if case .stack(let id, let q)? = slot, id == defId {
                acc += q
            }
        }
    }

    func has(defId: String, quantity: Int) -> Bool {
        totalQuantity(defId: defId) >= quantity
    }

    // Convenience bridge for existing usage.
    func getAmount(for element: ElementType) -> Int {
        totalQuantity(defId: element.rawValue)
    }

    func has(_ element: ElementType, amount: Int) -> Bool {
        has(defId: element.rawValue, quantity: amount)
    }

    /// Backwards-compatible signature: returns `true` only if full amount was removed.
    @discardableResult
    func remove(_ element: ElementType, amount: Int) -> Bool {
        let removed = remove(defId: element.rawValue, quantity: amount)
        return removed == amount
    }

    /// Total number of stackable units across all stacks (does not count unique instances).
    func totalStackedUnits() -> Int {
        state.slots.reduce(into: 0) { acc, slot in
            if case .stack(_, let q)? = slot { acc += q }
        }
    }

    /// Total occupied slots (stack slots + unique slots).
    func totalOccupiedSlots() -> Int {
        usedSlots
    }
}

// MARK: - Item Kind

enum ItemKind: String, Codable {
    case resource     // stackable (руда/пил/базові елементи)
    case crystal      // stackable або unstackable — вирішимо правилами
    case equipment    // unstackable
}

struct ItemDef: Codable, Hashable {
    let id: String              // "iron_ore", "carbon_dust", "crystal_fire"
    let kind: ItemKind
    let displayName: String
    let iconName: String        // ім'я текстури/атласу
    let maxStack: Int?          // nil => unstackable
}

struct UniqueItemInstance: Codable, Hashable {
    let instanceId: UUID
    let defId: String
}

enum InventorySlot: Codable, Hashable {
    case stack(defId: String, quantity: Int)
    case unique(item: UniqueItemInstance)
}

struct InventoryState: Codable {
    var maxSlots: Int
    var slots: [InventorySlot?]   // фіксований масив розміру maxSlots
    
    init(maxSlots: Int) {
        self.maxSlots = maxSlots
        self.slots = Array(repeating: nil, count: maxSlots)
    }
}
