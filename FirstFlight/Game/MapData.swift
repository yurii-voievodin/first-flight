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
    let mapSize: MapSize
    let playerStartPosition: Position
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
    let name: String
    let description: String
    let position: Position
    let size: Size
    let type: String
    let properties: [String: String]?

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
    let name: String?
    let description: String?
    let position: Position
    let size: Size
    let depth: Double?
    let shorelineProperties: [String: String]?
}
