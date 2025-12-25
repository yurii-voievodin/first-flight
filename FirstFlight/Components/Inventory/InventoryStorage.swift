import Foundation

enum InventoryStorage {
    static func inventoryURL() throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)
        return dir.appendingPathComponent("inventory.json")
    }
    
    static func save(_ state: InventoryState) throws {
        let data = try JSONEncoder().encode(state)
        let url = try inventoryURL()
        try data.write(to: url, options: [.atomic])
    }
    
    static func loadOrCreate(defaultMaxSlots: Int) throws -> InventoryState {
        let url = try inventoryURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return InventoryState(maxSlots: defaultMaxSlots)
        }
        let data = try Data(contentsOf: url)
        var state = try JSONDecoder().decode(InventoryState.self, from: data)
        
        // Захист від зміни maxSlots у майбутньому (м’яка міграція)
        if state.slots.count != state.maxSlots {
            state.slots = Array(state.slots.prefix(state.maxSlots)) + Array(repeating: nil, count: max(0, state.maxSlots - state.slots.count))
        }
        return state
    }
}
