import Foundation

enum InventoryKey: String {
    case player = "inventory"
    case shuttle = "shuttle_inventory"

    var filename: String { rawValue + ".json" }
}

enum InventoryStorage {

    private static func inventoryURL(for key: InventoryKey) throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)
        return dir.appendingPathComponent(key.filename)
    }

    // MARK: - Multi-inventory API

    static func save(_ state: InventoryState, for key: InventoryKey) throws {
        let data = try JSONEncoder().encode(state)
        let url = try inventoryURL(for: key)
        try data.write(to: url, options: [.atomic])
    }

    static func loadOrCreate(for key: InventoryKey, defaultMaxSlots: Int) throws -> InventoryState {
        let url = try inventoryURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return InventoryState(maxSlots: defaultMaxSlots)
        }
        let data = try Data(contentsOf: url)
        var state = try JSONDecoder().decode(InventoryState.self, from: data)

        // Protect against maxSlots changes (soft migration)
        if state.slots.count != state.maxSlots {
            state.slots = Array(state.slots.prefix(state.maxSlots)) + Array(repeating: nil, count: max(0, state.maxSlots - state.slots.count))
        }
        return state
    }
}
