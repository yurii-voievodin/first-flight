import Foundation

enum EquipmentStorage {

    private static let filename = "equipment.json"

    private static func equipmentURL() throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)
        return dir.appendingPathComponent(filename)
    }

    static func save(_ state: EquipmentState) throws {
        let data = try JSONEncoder().encode(state)
        let url = try equipmentURL()
        try data.write(to: url, options: [.atomic])
    }

    static func loadOrCreate() throws -> EquipmentState {
        let url = try equipmentURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return EquipmentState()
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(EquipmentState.self, from: data)
    }

    static func exists() -> Bool {
        guard let url = try? equipmentURL() else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
