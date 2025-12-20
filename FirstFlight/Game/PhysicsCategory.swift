struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let wall: UInt32 = 0b10
    static let rock: UInt32 = 0b100
    static let terrain: UInt32 = 0b1000
    static let blasterBeam: UInt32 = 0b10000
}
