import Foundation

/// Central catalog of all item definitions available in the game.
enum ItemCatalog {

    /// All item definitions available in the game.
    ///
    /// Notes:
    /// - `id` is based on `ElementType.rawValue` (e.g. "iron").
    /// - `iconName` matches your current texture naming: `UIImage(named: "<rawValue>")`.
    static let allDefs: [ItemDef] = {
        let elementDefs: [ItemDef] = ElementType.allCases.map { element in
            ItemDef(
                id: element.rawValue,
                kind: .resource,
                displayName: element.displayName,
                iconName: element.rawValue,
                maxStack: 99
            )
        }

        let equipmentDefs: [ItemDef] = [
            ItemDef(id: "backpack", kind: .equipment, displayName: "Backpack", iconName: "backpack", maxStack: nil),
            ItemDef(id: "blaster", kind: .equipment, displayName: "Blaster", iconName: "blaster", maxStack: nil),
        ]

        return elementDefs + equipmentDefs
    }()

    /// Lookup table keyed by item ID for O(1) access.
    static let defsById: [String: ItemDef] = Dictionary(allDefs.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
}
