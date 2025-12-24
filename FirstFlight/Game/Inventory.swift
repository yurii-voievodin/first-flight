import Foundation

/// Stores the player's collected elements from mining rocks
class Inventory {
    private(set) var elements: [ElementType: Int] = [:]

    /// Add elements to the inventory
    func add(_ element: ElementType, amount: Int) {
        guard amount > 0 else { return }
        elements[element, default: 0] += amount
    }

    /// Add multiple elements at once
    func add(_ collected: [ElementType: Int]) {
        for (element, amount) in collected {
            add(element, amount: amount)
        }
    }

    /// Get the amount of a specific element
    func getAmount(for element: ElementType) -> Int {
        elements[element, default: 0]
    }

    /// Get total count of all elements
    func total() -> Int {
        elements.values.reduce(0, +)
    }

    /// Check if inventory has at least the specified amount of an element
    func has(_ element: ElementType, amount: Int) -> Bool {
        getAmount(for: element) >= amount
    }

    /// Remove elements from inventory (for crafting)
    /// Returns true if successful, false if insufficient
    func remove(_ element: ElementType, amount: Int) -> Bool {
        guard has(element, amount: amount) else { return false }
        elements[element, default: 0] -= amount
        if elements[element] == 0 {
            elements.removeValue(forKey: element)
        }
        return true
    }
}
