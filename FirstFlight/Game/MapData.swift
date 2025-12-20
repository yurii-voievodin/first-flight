import Foundation
import CoreGraphics

struct MapData: Codable {
    let metadata: MapMetadata
    let boundaryRocks: [BoundaryRockData]
    let interiorRocks: [InteriorRockData]
    let signatureFormations: [SignatureFormationData]
    let smallRocks: [SmallRockData]?
    let lakes: [LakeData]?
}

struct MapMetadata: Codable {
    let name: String
    let version: String
    let description: String

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

struct BoundaryRockData: Codable {
    let position: Position
    let size: Size
    let type: String
    let thickness: Double?
    let isGap: Bool?

    var rockFormationType: RockFormationType {
        switch type.lowercased() {
        case "boulder": return .boulder
        case "cave": return .cave
        case "overhang": return .overhang
        case "cluster": return .cluster
        case "spire": return .spire
        default: return .boulder
        }
    }
}

struct InteriorRockData: Codable {
    let position: Position
    let size: Size
    let type: String
    let rotation: Double?

    var rockFormationType: RockFormationType {
        switch type.lowercased() {
        case "boulder": return .boulder
        case "cave": return .cave
        case "overhang": return .overhang
        case "cluster": return .cluster
        case "spire": return .spire
        default: return .boulder
        }
    }
}

struct SignatureFormationData: Codable {
    let position: Position
    let size: Size
    let type: String

    var rockFormationType: RockFormationType {
        switch type.lowercased() {
        case "boulder": return .boulder
        case "cave": return .cave
        case "overhang": return .overhang
        case "cluster": return .cluster
        case "spire": return .spire
        default: return .boulder
        }
    }
}

struct SmallRockData: Codable {
    let position: Position
    let variation: Int?

    var smallRockVariation: SmallRockVariation {
        guard let variation = variation,
              let rockVariation = SmallRockVariation(rawValue: variation) else {
            return .pebble
        }
        return rockVariation
    }
}

struct LakeData: Codable {
    let position: Position
    let size: Size
    let depth: Double?
}
