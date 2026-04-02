import SpriteKit

/// Creates SpriteKit nodes from parsed map data.
/// Keeps MapLoader free of SpriteKit imports.
enum MapNodeFactory {

    static func createBoundaryRocks(from mapData: MapData) -> [RockFormation] {
        mapData.boundaryRocks.map { boundaryRock in
            let seed = MapLoader.shared.rockSeed(x: boundaryRock.position.x, y: boundaryRock.position.y, extra: 1)
            let rock = RockFormation(
                type: boundaryRock.rockFormationType,
                size: boundaryRock.size.cgSize,
                position: boundaryRock.position.cgPoint,
                seed: seed
            )
            rock.applyProceduralTextures(seed: seed)
            rock.debugInfo["type"] = boundaryRock.type
            rock.debugInfo["position"] = "(\(Int(boundaryRock.position.x)), \(Int(boundaryRock.position.y)))"
            return rock
        }
    }

    static func createInteriorRocks(from mapData: MapData) -> [RockFormation] {
        mapData.interiorRocks.map { interiorRock in
            let seed = MapLoader.shared.rockSeed(x: interiorRock.position.x, y: interiorRock.position.y, extra: 2)
            let rock = RockFormation(
                type: interiorRock.rockFormationType,
                size: interiorRock.size.cgSize,
                position: interiorRock.position.cgPoint,
                seed: seed
            )
            if let rotation = interiorRock.rotation {
                rock.zRotation = CGFloat(rotation * .pi / 180)
            }
            rock.applyProceduralTextures(seed: seed)
            rock.debugInfo["type"] = interiorRock.type
            rock.debugInfo["position"] = "(\(Int(interiorRock.position.x)), \(Int(interiorRock.position.y)))"
            return rock
        }
    }

    static func createSignatureFormations(from mapData: MapData) -> [RockFormation] {
        mapData.signatureFormations.map { signatureFormation in
            let seed = MapLoader.shared.rockSeed(x: signatureFormation.position.x, y: signatureFormation.position.y, extra: 3)
            let rock = RockFormation(
                type: signatureFormation.rockFormationType,
                size: signatureFormation.size.cgSize,
                position: signatureFormation.position.cgPoint,
                seed: seed
            )
            rock.applyProceduralTextures(seed: seed)
            rock.debugInfo["type"] = signatureFormation.type
            rock.debugInfo["position"] = "(\(Int(signatureFormation.position.x)), \(Int(signatureFormation.position.y)))"
            return rock
        }
    }

    static func createAllRocks(from mapData: MapData) -> (boundary: [RockFormation], interior: [RockFormation], signature: [RockFormation]) {
        (
            boundary: createBoundaryRocks(from: mapData),
            interior: createInteriorRocks(from: mapData),
            signature: createSignatureFormations(from: mapData)
        )
    }

    static func createLakes(from mapData: MapData) -> [LakeNode] {
        guard let lakeData = mapData.lakes else { return [] }
        return lakeData.map { data in
            LakeNode(
                position: data.position.cgPoint,
                size: data.size.cgSize,
                depth: CGFloat(data.depth ?? 1.0)
            )
        }
    }

    static func createSpaceShuttle(from mapData: MapData, inventory: Inventory) -> SpaceShuttle? {
        guard let shuttleData = mapData.spaceShuttle else { return nil }
        let shuttle = SpaceShuttle(scale: CGFloat(shuttleData.scale), inventory: inventory)
        shuttle.position = shuttleData.position.cgPoint
        return shuttle
    }
}
