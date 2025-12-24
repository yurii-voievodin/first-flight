import Foundation
import SpriteKit

enum MapLoadError: Error {
    case fileNotFound(String)
    case invalidJSON(String)
    case parsingError(String)
    case invalidMapData(String)
}

class MapLoader {

    static let shared = MapLoader()

    private init() {}

    // MARK: - Public API

    func loadMap(named mapName: String) throws -> MapData {
        // First try to find the file in the bundle root (where Xcode copies it)
        guard let path = Bundle.main.path(forResource: mapName, ofType: "json") else {
            // If not found, provide debugging information
            let bundleContents = getBundleContents()
            let availableMaps = getAvailableMaps()

            var errorMessage = "Map file '\(mapName).json' not found in bundle.\n"
            errorMessage += "Available maps: \(availableMaps)\n"
            errorMessage += "Bundle contents (first 10): \(Array(bundleContents.prefix(10)))"

            throw MapLoadError.fileNotFound(errorMessage)
        }

        guard let jsonData = NSData(contentsOfFile: path) as Data? else {
            throw MapLoadError.invalidJSON("Could not read data from '\(mapName).json'")
        }

        do {
            let mapData = try JSONDecoder().decode(MapData.self, from: jsonData)
            try validateMapData(mapData)
            return mapData
        } catch let decodingError as DecodingError {
            throw MapLoadError.parsingError("JSON parsing failed: \(decodingError.localizedDescription)")
        } catch let validationError as MapLoadError {
            throw validationError
        } catch {
            throw MapLoadError.parsingError("Unknown parsing error: \(error.localizedDescription)")
        }
    }

    // MARK: - Rock Formation Creation

    func createBoundaryRocks(from mapData: MapData) -> [RockFormation] {
        var rocks: [RockFormation] = []

        for boundaryRock in mapData.boundaryRocks {
            let seed = rockSeed(x: boundaryRock.position.x, y: boundaryRock.position.y, extra: 1)

            let rock = RockFormation(
                type: boundaryRock.rockFormationType,
                size: boundaryRock.size.cgSize,
                position: boundaryRock.position.cgPoint,
                seed: seed
            )
            rock.applyProceduralTextures(seed: seed)

            // Add debug info
            rock.debugInfo["type"] = boundaryRock.type
            rock.debugInfo["position"] = "(\(Int(boundaryRock.position.x)), \(Int(boundaryRock.position.y)))"
            rock.debugInfo["composition"] = RockFormation.formatComposition(rock.composition)

            rocks.append(rock)
        }

        return rocks
    }

    func createInteriorRocks(from mapData: MapData) -> [RockFormation] {
        var rocks: [RockFormation] = []

        for interiorRock in mapData.interiorRocks {
            let seed = rockSeed(x: interiorRock.position.x, y: interiorRock.position.y, extra: 2)

            let rock = RockFormation(
                type: interiorRock.rockFormationType,
                size: interiorRock.size.cgSize,
                position: interiorRock.position.cgPoint,
                seed: seed
            )

            // Apply rotation if specified
            if let rotation = interiorRock.rotation {
                rock.zRotation = CGFloat(rotation * .pi / 180) // Convert degrees to radians
            }
            rock.applyProceduralTextures(seed: seed)

            // Add debug info
            rock.debugInfo["type"] = interiorRock.type
            rock.debugInfo["position"] = "(\(Int(interiorRock.position.x)), \(Int(interiorRock.position.y)))"
            rock.debugInfo["composition"] = RockFormation.formatComposition(rock.composition)

            rocks.append(rock)
        }

        return rocks
    }

    func createSignatureFormations(from mapData: MapData) -> [RockFormation] {
        var rocks: [RockFormation] = []

        for signatureFormation in mapData.signatureFormations {
            let seed = rockSeed(x: signatureFormation.position.x, y: signatureFormation.position.y, extra: 3)

            let rock = RockFormation(
                type: signatureFormation.rockFormationType,
                size: signatureFormation.size.cgSize,
                position: signatureFormation.position.cgPoint,
                seed: seed
            )
            rock.applyProceduralTextures(seed: seed)

            // Add debug info
            rock.debugInfo["type"] = signatureFormation.type
            rock.debugInfo["position"] = "(\(Int(signatureFormation.position.x)), \(Int(signatureFormation.position.y)))"
            rock.debugInfo["composition"] = RockFormation.formatComposition(rock.composition)

            rocks.append(rock)
        }

        return rocks
    }

    func createLakes(from mapData: MapData) -> [LakeNode] {
        guard let lakeData = mapData.lakes else {
            return []
        }

        return lakeData.map { data in
            LakeNode(
                position: data.position.cgPoint,
                size: data.size.cgSize,
                depth: CGFloat(data.depth ?? 1.0)
            )
        }
    }

    func createAllRocks(from mapData: MapData) -> (boundary: [RockFormation], interior: [RockFormation], signature: [RockFormation]) {
        let boundaryRocks = createBoundaryRocks(from: mapData)
        let interiorRocks = createInteriorRocks(from: mapData)
        let signatureRocks = createSignatureFormations(from: mapData)

        return (boundary: boundaryRocks, interior: interiorRocks, signature: signatureRocks)
    }

    // MARK: - Map Information

    // MARK: - Tile Grid (grid-first maps)

    /// Returns the tile-grid configuration for the map.
    ///
    /// Notes:
    /// - If the model/JSON provides `metadata.tileGrid`, you can later wire it here.
    /// - For now, this derives the grid from `metadata.mapSize` using a fixed tile size.
    func getTileGrid(from mapData: MapData, defaultTileSize: Int = 128) -> TileGrid {
        let tileSize = max(1, defaultTileSize)
        let width = max(0, Int(mapData.metadata.mapSize.width))
        let height = max(0, Int(mapData.metadata.mapSize.height))

        // Derive columns/rows from pixel mapSize.
        // Use rounding to tolerate minor mismatches (e.g. 2000px with 128px tiles).
        let columns = max(1, Int((Double(width) / Double(tileSize)).rounded()))
        let rows = max(1, Int((Double(height) / Double(tileSize)).rounded()))

        return TileGrid(
            tileSize: tileSize,
            columns: columns,
            rows: rows,
            origin: "bottom_left"
        )
    }

    func getPlayerStartPosition(from mapData: MapData) -> CGPoint {
        return mapData.metadata.playerStartPosition.cgPoint
    }

    func getMapSize(from mapData: MapData) -> CGSize {
        return mapData.metadata.mapSize.cgSize
    }

    // MARK: - Available Maps

    func getAvailableMaps() -> [String] {
        // Look for JSON files in the bundle root (where Xcode copies them)
        let bundlePath = Bundle.main.bundlePath

        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath) else {
            return []
        }

        return contents
            .filter { $0.hasSuffix(".json") }
            .filter { !$0.contains("Info.plist") } // Exclude system files
            .map { String($0.dropLast(5)) } // Remove .json extension
    }

    // MARK: - Debugging Helpers

    func getBundleContents() -> [String] {
        let bundlePath = Bundle.main.bundlePath
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath) else {
            return ["Unable to read bundle contents"]
        }
        return contents.sorted()
    }

    // MARK: - Validation

    private func validateMapData(_ mapData: MapData) throws {
        // Validate map size
        guard mapData.metadata.mapSize.width > 0 && mapData.metadata.mapSize.height > 0 else {
            throw MapLoadError.invalidMapData("Map size must be positive")
        }

        // Validate player start position is within map bounds
        let playerPos = mapData.metadata.playerStartPosition
        let mapSize = mapData.metadata.mapSize

        guard playerPos.x >= 0 && playerPos.x <= mapSize.width &&
              playerPos.y >= 0 && playerPos.y <= mapSize.height else {
            throw MapLoadError.invalidMapData("Player start position is outside map bounds")
        }

        // Validate rock formations are within map bounds
        try validateRockPositions(mapData.boundaryRocks.map { $0.position }, mapSize: mapSize, context: "boundary")
        try validateRockPositions(mapData.interiorRocks.map { $0.position }, mapSize: mapSize, context: "interior")
        try validateRockPositions(mapData.signatureFormations.map { $0.position }, mapSize: mapSize, context: "signature")
        try validateLakePositions(mapData.lakes ?? [], mapSize: mapSize)

        // Validate rock sizes are positive
        try validateRockSizes(mapData.boundaryRocks.map { $0.size }, context: "boundary")
        try validateRockSizes(mapData.interiorRocks.map { $0.size }, context: "interior")
        try validateRockSizes(mapData.signatureFormations.map { $0.size }, context: "signature")
        try validateLakeSizes(mapData.lakes ?? [])
    }

    private func validateRockPositions(_ positions: [Position], mapSize: MapSize, context: String) throws {
        for (index, position) in positions.enumerated() {
            guard position.x >= 0 && position.x <= mapSize.width &&
                  position.y >= 0 && position.y <= mapSize.height else {
                throw MapLoadError.invalidMapData("\(context.capitalized) rock at index \(index) is outside map bounds")
            }
        }
    }

    private func validateRockSizes(_ sizes: [Size], context: String) throws {
        for (index, size) in sizes.enumerated() {
            guard size.width > 0 && size.height > 0 else {
                throw MapLoadError.invalidMapData("\(context.capitalized) rock at index \(index) has invalid size")
            }
        }
    }

    private func validateLakePositions(_ lakes: [LakeData], mapSize: MapSize) throws {
        for (index, lake) in lakes.enumerated() {
            guard lake.position.x >= 0 && lake.position.x <= mapSize.width &&
                  lake.position.y >= 0 && lake.position.y <= mapSize.height else {
                throw MapLoadError.invalidMapData("Lake at index \(index) is outside map bounds")
            }
        }
    }

    private func validateLakeSizes(_ lakes: [LakeData]) throws {
        for (index, lake) in lakes.enumerated() {
            guard lake.size.width > 0 && lake.size.height > 0 else {
                throw MapLoadError.invalidMapData("Lake at index \(index) has invalid size")
            }
        }
    }
}

// MARK: - Convenience Extensions

extension MapLoader {
    
    func rockSeed(x: Double, y: Double, extra: UInt64 = 0) -> UInt64 {
        let xi = UInt64(max(0, Int(x)))
        let yi = UInt64(max(0, Int(y)))
        var h = xi &* 73856093 ^ yi &* 19349663 ^ extra &* 83492791
        h ^= (h >> 33); h &*= 0xff51afd7ed558ccd
        h ^= (h >> 33); h &*= 0xc4ceb9fe1a85ec53
        h ^= (h >> 33)
        return h
    }
}
