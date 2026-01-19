import Foundation

enum EquipmentSlot: String, Codable {
    case backpack
    case weapon
}

struct EquipmentState: Codable {
    var equippedItems: [EquipmentSlot: UniqueItemInstance]

    init() {
        self.equippedItems = [:]
    }

    init(equippedItems: [EquipmentSlot: UniqueItemInstance]) {
        self.equippedItems = equippedItems
    }
}
