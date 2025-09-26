import SpriteKit
import GameplayKit

enum BoundaryType {
    case valley
    case canyon
    case mixed
}

enum BoundaryStyle {
    case gentle
    case steep
    case varied
}

struct BoundaryParameters {
    let type: BoundaryType
    let style: BoundaryStyle
    let roughness: Float
    let thickness: CGFloat
    let gapFrequency: Float
    let heightVariation: CGFloat

    static let valleyDefault = BoundaryParameters(
        type: .valley,
        style: .gentle,
        roughness: 0.4,
        thickness: 120,
        gapFrequency: 0.15,
        heightVariation: 50
    )

    static let canyonDefault = BoundaryParameters(
        type: .canyon,
        style: .steep,
        roughness: 0.6,
        thickness: 200,
        gapFrequency: 0.08,
        heightVariation: 150
    )

    static let mixedDefault = BoundaryParameters(
        type: .mixed,
        style: .varied,
        roughness: 0.5,
        thickness: 160,
        gapFrequency: 0.12,
        heightVariation: 100
    )
}

struct BoundaryPoint {
    let position: CGPoint
    let thickness: CGFloat
    let height: CGFloat
    let isGap: Bool
    let normal: CGVector
}

class MapBoundary {

    private let mapSize: CGSize
    private let parameters: BoundaryParameters
    private var boundaryPoints: [BoundaryPoint] = []
    private var boundaryRocks: [RockFormation] = []

    init(mapSize: CGSize, parameters: BoundaryParameters = .valleyDefault) {
        self.mapSize = mapSize
        self.parameters = parameters
    }

    // MARK: - Boundary Generation

    func generateBoundary() -> [RockFormation] {
        generateBoundaryPoints()
        createBoundaryRocks()
        return boundaryRocks
    }

    private func generateBoundaryPoints() {
        boundaryPoints.removeAll()

        // Generate points around the perimeter with organic variation
        let perimeter = mapSize.width * 2 + mapSize.height * 2
        let pointSpacing: CGFloat = 80 // Distance between boundary points
        let totalPoints = Int(perimeter / pointSpacing)

        for i in 0..<totalPoints {
            let progress = Float(i) / Float(totalPoints)
            let basePoint = getPerimeterPoint(progress: progress)
            let organicPoint = addOrganicVariation(to: basePoint, progress: progress)

            boundaryPoints.append(organicPoint)
        }

        // Smooth the boundary curve
        smoothBoundaryPoints()
    }

    private func getPerimeterPoint(progress: Float) -> BoundaryPoint {
        let perimeter = mapSize.width * 2 + mapSize.height * 2
        let currentDistance = CGFloat(progress) * perimeter

        var position: CGPoint
        var normal: CGVector

        if currentDistance < mapSize.width {
            // Bottom edge
            position = CGPoint(x: currentDistance, y: 0)
            normal = CGVector(dx: 0, dy: 1)
        } else if currentDistance < mapSize.width + mapSize.height {
            // Right edge
            let y = currentDistance - mapSize.width
            position = CGPoint(x: mapSize.width, y: y)
            normal = CGVector(dx: -1, dy: 0)
        } else if currentDistance < mapSize.width * 2 + mapSize.height {
            // Top edge
            let x = mapSize.width - (currentDistance - mapSize.width - mapSize.height)
            position = CGPoint(x: x, y: mapSize.height)
            normal = CGVector(dx: 0, dy: -1)
        } else {
            // Left edge
            let y = mapSize.height - (currentDistance - mapSize.width * 2 - mapSize.height)
            position = CGPoint(x: 0, y: y)
            normal = CGVector(dx: 1, dy: 0)
        }

        return BoundaryPoint(
            position: position,
            thickness: parameters.thickness,
            height: parameters.heightVariation,
            isGap: false,
            normal: normal
        )
    }

    private func addOrganicVariation(to point: BoundaryPoint, progress: Float) -> BoundaryPoint {
        // Use Perlin noise for organic shape variation
        let noiseScale: Float = 0.02
        let noise = GKPerlinNoiseSource(frequency: Double(noiseScale), octaveCount: 3, persistence: 0.5, lacunarity: 2.0, seed: 42)
        let noiseMap = GKNoise(noise)

        // Get noise values for position variation
        let noiseX = noiseMap.value(atPosition: vector2(progress * 10, 0))
        let noiseY = noiseMap.value(atPosition: vector2(progress * 10, 100))
        let thicknessNoise = noiseMap.value(atPosition: vector2(progress * 10, 200))
        let heightNoise = noiseMap.value(atPosition: vector2(progress * 10, 300))

        // Apply organic variation
        let variation = CGFloat(parameters.roughness) * 60
        let organicOffset = CGVector(
            dx: point.normal.dx * variation * CGFloat(noiseX),
            dy: point.normal.dy * variation * CGFloat(noiseY)
        )

        let organicPosition = CGPoint(
            x: point.position.x + organicOffset.dx,
            y: point.position.y + organicOffset.dy
        )

        // Vary thickness and height
        let organicThickness = parameters.thickness + CGFloat(thicknessNoise) * parameters.thickness * 0.3
        let organicHeight = parameters.heightVariation + CGFloat(heightNoise) * parameters.heightVariation * 0.5

        // Determine if this should be a gap
        let gapNoise = noiseMap.value(atPosition: vector2(progress * 10, 400))
        let isGap = gapNoise > (1.0 - parameters.gapFrequency * 2)

        return BoundaryPoint(
            position: organicPosition,
            thickness: max(organicThickness, 40), // Minimum thickness
            height: max(organicHeight, 20), // Minimum height
            isGap: isGap,
            normal: point.normal
        )
    }

    private func smoothBoundaryPoints() {
        guard boundaryPoints.count > 2 else { return }

        let smoothingPasses = 2

        for _ in 0..<smoothingPasses {
            var smoothedPoints: [BoundaryPoint] = []

            for i in 0..<boundaryPoints.count {
                let prevIndex = (i - 1 + boundaryPoints.count) % boundaryPoints.count
                let nextIndex = (i + 1) % boundaryPoints.count

                let current = boundaryPoints[i]
                let prev = boundaryPoints[prevIndex]
                let next = boundaryPoints[nextIndex]

                // Smooth position
                let smoothedX = (prev.position.x + current.position.x * 2 + next.position.x) / 4
                let smoothedY = (prev.position.y + current.position.y * 2 + next.position.y) / 4
                let smoothedPosition = CGPoint(x: smoothedX, y: smoothedY)

                // Smooth thickness
                let smoothedThickness = (prev.thickness + current.thickness * 2 + next.thickness) / 4

                let smoothedPoint = BoundaryPoint(
                    position: smoothedPosition,
                    thickness: smoothedThickness,
                    height: current.height,
                    isGap: current.isGap,
                    normal: current.normal
                )

                smoothedPoints.append(smoothedPoint)
            }

            boundaryPoints = smoothedPoints
        }
    }

    // MARK: - Rock Formation Creation

    private func createBoundaryRocks() {
        boundaryRocks.removeAll()

        for i in 0..<boundaryPoints.count {
            let point = boundaryPoints[i]

            // Skip gaps in the boundary
            if point.isGap {
                continue
            }

            // Create rock formation at this boundary point
            let rock = createBoundaryRock(at: point, index: i)
            boundaryRocks.append(rock)
        }

        // Add connecting rocks between main boundary rocks
        addConnectingRocks()

        // Add layered rocks for depth
        addLayeredRocks()
    }

    private func createBoundaryRock(at point: BoundaryPoint, index: Int) -> RockFormation {
        // Choose rock type based on boundary parameters and position
        let rockType = chooseBoundaryRockType(for: point, index: index)

        // Calculate rock size based on thickness and height
        let rockSize = CGSize(
            width: point.thickness + CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * 40,
            height: point.height + CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * 30
        )

        // Position rock slightly inward from the boundary point
        let inwardOffset = point.normal * (-point.thickness / 2)
        let rockPosition = CGPoint(
            x: point.position.x + inwardOffset.dx,
            y: point.position.y + inwardOffset.dy
        )

        return RockFormation(type: rockType, size: rockSize, position: rockPosition)
    }

    private func chooseBoundaryRockType(for point: BoundaryPoint, index: Int) -> RockFormationType {
        switch parameters.type {
        case .valley:
            // Valley uses mostly boulders with occasional clusters
            return GKRandomSource.sharedRandom().nextUniform() < 0.8 ? .boulder : .cluster

        case .canyon:
            // Canyon uses more dramatic formations
            let random = GKRandomSource.sharedRandom().nextUniform()
            if random < 0.4 {
                return .spire
            } else if random < 0.7 {
                return .overhang
            } else {
                return .boulder
            }

        case .mixed:
            // Mixed uses all types with balanced distribution
            let types: [RockFormationType] = [.boulder, .cluster, .spire, .overhang]
            return types[GKRandomSource.sharedRandom().nextInt(upperBound: types.count)]
        }
    }

    private func addConnectingRocks() {
        // Add smaller rocks between main boundary rocks to fill gaps
        let connectingRockCount = boundaryPoints.count / 3

        for _ in 0..<connectingRockCount {
            let randomIndex = GKRandomSource.sharedRandom().nextInt(upperBound: boundaryPoints.count)
            let point = boundaryPoints[randomIndex]

            if point.isGap { continue }

            // Create smaller connecting rock
            let connectingSize = CGSize(
                width: point.thickness * 0.6,
                height: point.height * 0.7
            )

            let connectingPosition = CGPoint(
                x: point.position.x + CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * 60,
                y: point.position.y + CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * 60
            )

            let connectingRock = RockFormation(type: .boulder, size: connectingSize, position: connectingPosition)
            boundaryRocks.append(connectingRock)
        }
    }

    private func addLayeredRocks() {
        // Add background layer of rocks for depth perception
        let layerRockCount = boundaryPoints.count / 4

        for _ in 0..<layerRockCount {
            let randomIndex = GKRandomSource.sharedRandom().nextInt(upperBound: boundaryPoints.count)
            let point = boundaryPoints[randomIndex]

            // Position layer rock further outward
            let outwardOffset = point.normal * (-point.thickness * 1.5)
            let layerPosition = CGPoint(
                x: point.position.x + outwardOffset.dx,
                y: point.position.y + outwardOffset.dy
            )

            let layerSize = CGSize(
                width: point.thickness * 1.2,
                height: point.height * 0.8
            )

            let layerRock = RockFormation(type: .boulder, size: layerSize, position: layerPosition)
            boundaryRocks.append(layerRock)
        }
    }

    // MARK: - Utility Extensions

}

extension CGVector {
    static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
        return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }
}