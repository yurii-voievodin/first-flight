import Foundation

/// Basic chemical elements used as raw resources in the game.
///
/// Design goals:
/// - Compact, easy to balance drop tables.
/// - Clearly communicates what each resource is for (crafting / upgrades).
/// - Grouped by progression tiers.
///
/// Notes:
/// - These are *game* resources inspired by real elements.
/// - If you later introduce fictional/planet-specific materials, add them as a separate enum
///   (e.g. `ExoticElementType`) or extend this one with a new tier.

enum ElementType: String, CaseIterable, Codable, Hashable {

    // MARK: - Tier 1 (Core / Early Game)

    // Lithosphere / rocky surface
    case iron
    case silicon
    case aluminum
    case carbon
    case sulfur

    // Volatiles / ice / subsurface pockets
    case hydrogen
    case oxygen
    case nitrogen

    // Conductive / energy-adjacent basics
    case copper
    case nickel
    case cobalt

    // MARK: - Tier 2 (Rare / Mid–Late Game)

    case titanium
    case lithium
    case uranium
    case gold

    // MARK: - Progression

    enum Tier: Int, Codable, Hashable, Comparable {
        case tier1 = 1
        case tier2 = 2

        static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Tier of this element for progression, drop rates, and crafting gates.
    var tier: Tier {
        switch self {
        case .iron, .silicon, .aluminum, .carbon, .sulfur,
             .hydrogen, .oxygen, .nitrogen,
             .copper, .nickel, .cobalt:
            return .tier1

        case .titanium, .lithium, .uranium, .gold:
            return .tier2
        }
    }

    // MARK: - UI

    /// The in-game display name (Ukrainian). Use this for UI labels.
    var displayName: String {
        switch self {
        case .iron: return "Залізо"
        case .silicon: return "Кремній"
        case .aluminum: return "Алюміній"
        case .carbon: return "Вуглець"
        case .sulfur: return "Сірка"

        case .hydrogen: return "Водень"
        case .oxygen: return "Кисень"
        case .nitrogen: return "Азот"

        case .copper: return "Мідь"
        case .nickel: return "Нікель"
        case .cobalt: return "Кобальт"

        case .titanium: return "Титан"
        case .lithium: return "Літій"
        case .uranium: return "Уран"
        case .gold: return "Золото"
        }
    }

    /// Short chemical-style symbol used in UI, icons, and compact inventory views.
    var symbol: String {
        switch self {
        case .iron: return "Fe"
        case .silicon: return "Si"
        case .aluminum: return "Al"
        case .carbon: return "C"
        case .sulfur: return "S"

        case .hydrogen: return "H"
        case .oxygen: return "O"
        case .nitrogen: return "N"

        case .copper: return "Cu"
        case .nickel: return "Ni"
        case .cobalt: return "Co"

        case .titanium: return "Ti"
        case .lithium: return "Li"
        case .uranium: return "U"
        case .gold: return "Au"
        }
    }

    /// Short usage hints for UI tooltips / inventory.
    /// Keep it actionable: what the player typically crafts/upgrades with this.
    var usageDescription: String {
        switch self {
        // Tier 1
        case .iron:
            return "Каркаси, базова броня, механічні модулі. Часто трапляється у камінні."
        case .silicon:
            return "Електроніка, сенсори, плати, оптичні модулі."
        case .aluminum:
            return "Легкі корпуси, панелі, модулі руху/маневрування."
        case .carbon:
            return "Композити, фільтри, теплоізоляція, підсилення спорядження."
        case .sulfur:
            return "Хімічні реакції, паливні суміші, технології переробки."

        case .hydrogen:
            return "Паливні системи, реактори, енергетичні суміші (ризик перегріву)."
        case .oxygen:
            return "Окислювач для енергії/хімії, системи підтримки життя, переробка."
        case .nitrogen:
            return "Стабілізатори сумішей, охолодження/ізоляція, технологічні реагенти."

        case .copper:
            return "Провідники, кабелі, апгрейди бластера (стабільність/ефективність)."
        case .nickel:
            return "Магнітні системи, сплави, екранізація, модулі індукції."
        case .cobalt:
            return "Батареї, енергокомірки, силові ядра та апгрейди живлення."

        // Tier 2
        case .titanium:
            return "Просунута броня й корпуси: міцність без великої ваги."
        case .lithium:
            return "Потужні акумулятори, дрони/гаджети, енергоємні апгрейди."
        case .uranium:
            return "Реакторні модулі: великий приріст енергії з ризиком радіації."
        case .gold:
            return "Надточна електроніка: топові сенсори, фокус-оптика, контрольні модулі."
        }
    }

    /// Optional: handy grouping for screens, drop tables, and filters.
    static var tier1: [ElementType] { allCases.filter { $0.tier == .tier1 } }
    static var tier2: [ElementType] { allCases.filter { $0.tier == .tier2 } }
}

// MARK: - Crafting Examples

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
