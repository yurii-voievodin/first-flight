import Foundation

/// Simple crafting recipes built from base elements.
/// These are examples meant for early and mid-game progression.
struct CraftingRecipe: Hashable, Codable {

    enum Product: String, Codable {
        case energyCell
        case reinforcedPlating
        case laserFocusModule
        case basicBattery
    }

    let product: Product
    let requiredElements: [ElementType: Int]
}

extension CraftingRecipe {

    /// Battery / power source used by most devices.
    static let energyCell = CraftingRecipe(
        product: .energyCell,
        requiredElements: [
            .lithium: 2,
            .cobalt: 1,
            .carbon: 1
        ]
    )

    /// Early defensive upgrade.
    static let reinforcedPlating = CraftingRecipe(
        product: .reinforcedPlating,
        requiredElements: [
            .iron: 3,
            .carbon: 2,
            .aluminum: 1
        ]
    )

    /// Improves precision and efficiency of the blaster.
    static let laserFocusModule = CraftingRecipe(
        product: .laserFocusModule,
        requiredElements: [
            .silicon: 2,
            .gold: 1,
            .copper: 1
        ]
    )

    /// Cheap early-game power storage.
    static let basicBattery = CraftingRecipe(
        product: .basicBattery,
        requiredElements: [
            .copper: 1,
            .nickel: 1,
            .carbon: 1
        ]
    )

    static let all: [CraftingRecipe] = [
        .energyCell,
        .reinforcedPlating,
        .laserFocusModule,
        .basicBattery
    ]
}
