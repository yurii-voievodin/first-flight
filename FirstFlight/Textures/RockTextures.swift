import SpriteKit

final class RockTextures {
    static let shared = RockTextures()
    private init() {}

    private let atlas = SKTextureAtlas(named: "Rocks")

    private lazy var base    = atlas.textureNamed("rock_base")
    private lazy var rough   = atlas.textureNamed("rock_rough")
    private lazy var smooth  = atlas.textureNamed("rock_smooth")
    private lazy var layered = atlas.textureNamed("rock_layered")
    private lazy var dark    = atlas.textureNamed("rock_dark")

    func baseTexture(for type: RockFormationType, seed: UInt64) -> SKTexture {
        let roll = Int(seed % 100)

        switch type {
        case .spire:
            return layered
        case .overhang:
            return roll < 70 ? layered : rough
        case .cluster:
            return roll < 55 ? rough : base
        case .cave:
            return dark
        case .boulder:
            if roll < 20 { return smooth }
            if roll < 70 { return base }
            return rough
        }
    }
}
