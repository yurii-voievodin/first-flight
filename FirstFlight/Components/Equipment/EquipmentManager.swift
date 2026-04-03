import Foundation

class EquipmentManager {
    private(set) var state: EquipmentState

    init(state: EquipmentState) {
        self.state = state
    }

    var hasBackpack: Bool {
        state.equippedItems[.backpack] != nil
    }

    var hasWeapon: Bool {
        state.equippedItems[.weapon] != nil
    }

    func equip(_ item: UniqueItemInstance, to slot: EquipmentSlot) {
        state.equippedItems[slot] = item
    }

    func unequip(_ slot: EquipmentSlot) -> UniqueItemInstance? {
        let item = state.equippedItems[slot]
        state.equippedItems[slot] = nil
        return item
    }

    func getEquipped(_ slot: EquipmentSlot) -> UniqueItemInstance? {
        state.equippedItems[slot]
    }

}
