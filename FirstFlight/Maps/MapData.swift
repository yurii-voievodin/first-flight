import Foundation
import CoreGraphics

struct MapData: Codable {
    let metadata: MapMetadata
    let boundaryRocks: [BoundaryRockData]
    let interiorRocks: [InteriorRockData]
    let signatureFormations: [SignatureFormationData]
    let lakes: [LakeData]?
    let spaceShuttle: SpaceShuttleData?
}

struct MapMetadata: Codable {
    let version: String

    /// Grid-first tile configuration (preferred). Optional for backward compatibility.
    let tileGrid: TileGrid?

    /// Pixel map size (legacy). If `tileGrid` is present, this can be derived.
    let mapSize: MapSize

    let playerStartPosition: Position
}

struct TileGrid: Codable {
    let tileSize: Int
    let columns: Int
    let rows: Int
    let origin: String?

    var mapSize: CGSize {
        CGSize(width: CGFloat(columns * tileSize), height: CGFloat(rows * tileSize))
    }
}

struct MapSize: Codable {
    let width: Double
    let height: Double

    var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

struct Position: Codable {
    let x: Double
    let y: Double

    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}

struct Size: Codable {
    let width: Double
    let height: Double

    var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

/// Helper to decode rock formation types from raw string values.
@inline(__always)
private func rockType(from raw: String) -> RockFormationType {
    RockFormationType(rawValue: raw) ?? .boulder
}

struct BoundaryRockData: Codable {
    let position: Position
    let size: Size
    let type: String

    var rockFormationType: RockFormationType {
        rockType(from: type)
    }
}

struct InteriorRockData: Codable {
    let position: Position
    let size: Size
    let type: String
    let rotation: Double?

    var rockFormationType: RockFormationType {
        rockType(from: type)
    }
}

struct SignatureFormationData: Codable {
    let position: Position
    let size: Size
    let type: String

    var rockFormationType: RockFormationType {
        rockType(from: type)
    }
}

struct LakeData: Codable {
    let position: Position
    let size: Size
    let depth: Double?
}

struct SpaceShuttleData: Codable {
    let position: Position
    let scale: Double
}
