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
            let rock = RockFormation(
                type: boundaryRock.rockFormationType,
                size: boundaryRock.size.cgSize,
                position: boundaryRock.position.cgPoint
            )

            // Add debug info
            rock.debugInfo["type"] = boundaryRock.type
            rock.debugInfo["position"] = "(\(Int(boundaryRock.position.x)), \(Int(boundaryRock.position.y)))"
            if let isGap = boundaryRock.isGap {
                rock.debugInfo["isGap"] = String(isGap)
            }

            rocks.append(rock)
        }

        return rocks
    }

    func createInteriorRocks(from mapData: MapData) -> [RockFormation] {
        var rocks: [RockFormation] = []

        for interiorRock in mapData.interiorRocks {
            let rock = RockFormation(
                type: interiorRock.rockFormationType,
                size: interiorRock.size.cgSize,
                position: interiorRock.position.cgPoint
            )

            // Apply rotation if specified
            if let rotation = interiorRock.rotation {
                rock.zRotation = CGFloat(rotation * .pi / 180) // Convert degrees to radians
            }

            // Add debug info
            rock.debugInfo["type"] = interiorRock.type
            rock.debugInfo["position"] = "(\(Int(interiorRock.position.x)), \(Int(interiorRock.position.y)))"

            rocks.append(rock)
        }

        return rocks
    }

    func createSignatureFormations(from mapData: MapData) -> [RockFormation] {
        var rocks: [RockFormation] = []

        for signatureFormation in mapData.signatureFormations {
            let rock = RockFormation(
                type: signatureFormation.rockFormationType,
                size: signatureFormation.size.cgSize,
                position: signatureFormation.position.cgPoint
            )

            // Store additional properties in userData for later use
            rock.userData = NSMutableDictionary()
            rock.userData?["name"] = signatureFormation.name
            rock.userData?["description"] = signatureFormation.description

            if let properties = signatureFormation.properties {
                for (key, value) in properties {
                    rock.userData?[key] = value
                }
            }

            // Add debug info
            rock.debugInfo["type"] = signatureFormation.type
            rock.debugInfo["name"] = signatureFormation.name
            rock.debugInfo["position"] = "(\(Int(signatureFormation.position.x)), \(Int(signatureFormation.position.y)))"

            rocks.append(rock)
        }

        return rocks
    }

    func createAllRocks(from mapData: MapData) -> (boundary: [RockFormation], interior: [RockFormation], signature: [RockFormation]) {
        let boundaryRocks = createBoundaryRocks(from: mapData)
        let interiorRocks = createInteriorRocks(from: mapData)
        let signatureRocks = createSignatureFormations(from: mapData)

        return (boundary: boundaryRocks, interior: interiorRocks, signature: signatureRocks)
    }

    // MARK: - Map Information

    func getPlayerStartPosition(from mapData: MapData) -> CGPoint {
        return mapData.metadata.playerStartPosition.cgPoint
    }

    func getMapSize(from mapData: MapData) -> CGSize {
        return mapData.metadata.mapSize.cgSize
    }

    func getMapInfo(from mapData: MapData) -> (name: String, description: String, version: String) {
        return (
            name: mapData.metadata.name,
            description: mapData.metadata.description,
            version: mapData.metadata.version
        )
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

    func debugBundleInfo() {
        print("=== Bundle Debug Info ===")
        print("Bundle path: \(Bundle.main.bundlePath)")
        print("Available maps: \(getAvailableMaps())")
        print("All bundle contents:")
        getBundleContents().forEach { print("  - \($0)") }
        print("========================")
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

        // Validate rock sizes are positive
        try validateRockSizes(mapData.boundaryRocks.map { $0.size }, context: "boundary")
        try validateRockSizes(mapData.interiorRocks.map { $0.size }, context: "interior")
        try validateRockSizes(mapData.signatureFormations.map { $0.size }, context: "signature")
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
}

// MARK: - Convenience Extensions

extension MapLoader {

    func loadMapQuietly(named mapName: String) -> MapData? {
        do {
            return try loadMap(named: mapName)
        } catch {
            print("Warning: Failed to load map '\(mapName)': \(error.localizedDescription)")
            return nil
        }
    }

    func createCompleteMap(from mapData: MapData, in scene: SKScene) {
        let rocks = createAllRocks(from: mapData)

        // Add all rocks to the scene
        rocks.boundary.forEach { scene.addChild($0) }
        rocks.interior.forEach { scene.addChild($0) }
        rocks.signature.forEach { scene.addChild($0) }
    }
}