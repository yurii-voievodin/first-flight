import SpriteKit
import GameplayKit

class TerrainGenerator {

    static let shared = TerrainGenerator()

    private init() {}

    // MARK: - Organic Path Generation

    func createOrganicPath(from startPoint: CGPoint, to endPoint: CGPoint, roughness: Float = 0.3) -> CGPath {
        let path = CGMutablePath()
        path.move(to: startPoint)

        let distance = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2))
        let segments = Int(distance / 50) + 2 // Create segments every ~50 points

        var currentPoint = startPoint

        for i in 1..<segments {
            let progress = Float(i) / Float(segments)

            // Linear interpolation between start and end
            let baseX = startPoint.x + (endPoint.x - startPoint.x) * CGFloat(progress)
            let baseY = startPoint.y + (endPoint.y - startPoint.y) * CGFloat(progress)

            // Add organic variation using noise
            let noiseX = CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * CGFloat(roughness) * 100
            let noiseY = CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * CGFloat(roughness) * 100

            let nextPoint = CGPoint(x: baseX + noiseX, y: baseY + noiseY)

            // Create control points for smooth curves
            let midX = (currentPoint.x + nextPoint.x) / 2
            let midY = (currentPoint.y + nextPoint.y) / 2
            let controlOffset = CGFloat(30)

            let control1 = CGPoint(
                x: midX + CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * controlOffset,
                y: midY + CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5) * controlOffset
            )

            path.addQuadCurve(to: nextPoint, control: control1)
            currentPoint = nextPoint
        }

        // Final curve to exact end point
        let finalControl = CGPoint(
            x: (currentPoint.x + endPoint.x) / 2,
            y: (currentPoint.y + endPoint.y) / 2
        )
        path.addQuadCurve(to: endPoint, control: finalControl)

        return path
    }

    // MARK: - Natural Rock Placement

    func generateNaturalRockPlacements(in area: CGRect, density: Float = 0.3) -> [RockPlacement] {
        var placements: [RockPlacement] = []

        let gridSize: CGFloat = 200 // Base grid for placement
        let cols = Int(area.width / gridSize)
        let rows = Int(area.height / gridSize)

        for row in 0..<rows {
            for col in 0..<cols {
                // Skip some cells based on density
                if GKRandomSource.sharedRandom().nextUniform() > density {
                    continue
                }

                let baseX = area.minX + CGFloat(col) * gridSize
                let baseY = area.minY + CGFloat(row) * gridSize

                // Add random offset within the grid cell
                let offsetX = CGFloat(GKRandomSource.sharedRandom().nextUniform()) * gridSize * 0.8
                let offsetY = CGFloat(GKRandomSource.sharedRandom().nextUniform()) * gridSize * 0.8

                let position = CGPoint(x: baseX + offsetX, y: baseY + offsetY)
                let size = generateRandomRockSize()
                let type = generateRandomRockType()

                placements.append(RockPlacement(type: type, size: size, position: position))
            }
        }

        return placements
    }

    // MARK: - Procedural Cave System

    func generateCaveSystem(in area: CGRect, complexity: Int = 3) -> [CaveFormation] {
        var caves: [CaveFormation] = []

        // Generate main cave chambers
        for _ in 0..<complexity {
            let centerX = area.minX + CGFloat(GKRandomSource.sharedRandom().nextUniform()) * area.width
            let centerY = area.minY + CGFloat(GKRandomSource.sharedRandom().nextUniform()) * area.height
            let center = CGPoint(x: centerX, y: centerY)

            let width = CGFloat(150 + GKRandomSource.sharedRandom().nextInt(upperBound: 200))
            let height = CGFloat(100 + GKRandomSource.sharedRandom().nextInt(upperBound: 150))
            let size = CGSize(width: width, height: height)

            caves.append(CaveFormation(center: center, size: size))
        }

        return caves
    }

    // MARK: - Utility Functions

    private func generateRandomRockSize() -> CGSize {
        let baseSize: CGFloat = 80
        let variation: CGFloat = 60

        let width = baseSize + CGFloat(GKRandomSource.sharedRandom().nextUniform()) * variation
        let height = baseSize + CGFloat(GKRandomSource.sharedRandom().nextUniform()) * variation

        return CGSize(width: width, height: height)
    }

    private func generateRandomRockType() -> RockFormationType {
        let types: [RockFormationType] = [.boulder, .cave, .overhang, .cluster, .spire]
        let weights: [Float] = [0.4, 0.15, 0.2, 0.15, 0.1] // Boulder most common

        let random = GKRandomSource.sharedRandom().nextUniform()
        var accumulator: Float = 0

        for (index, weight) in weights.enumerated() {
            accumulator += weight
            if random <= accumulator {
                return types[index]
            }
        }

        return .boulder // fallback
    }

    // MARK: - Perlin Noise Terrain

    func generatePerlinTerrain(size: CGSize, frequency: Float = 0.01) -> [[Float]] {
        let noiseSource = GKPerlinNoiseSource(frequency: Double(frequency), octaveCount: 4, persistence: 0.5, lacunarity: 2.0, seed: 42)
        let noise = GKNoise(noiseSource)
        let noiseMap = GKNoiseMap(noise, size: vector2(1.0, 1.0), origin: vector2(0, 0), sampleCount: vector2(Int32(size.width), Int32(size.height)), seamless: false)

        var terrain: [[Float]] = []

        for y in 0..<Int(size.height) {
            var row: [Float] = []
            for x in 0..<Int(size.width) {
                let value = noiseMap.value(at: vector2(Int32(x), Int32(y)))
                row.append(value)
            }
            terrain.append(row)
        }

        return terrain
    }
}

// MARK: - Data Structures

struct RockPlacement {
    let type: RockFormationType
    let size: CGSize
    let position: CGPoint
}

struct CaveFormation {
    let center: CGPoint
    let size: CGSize

    var entrancePoints: [CGPoint] {
        // Generate potential entrance points around the cave
        let angles: [Float] = [0, .pi/2, .pi, 3 * .pi/2] // N, E, S, W
        return angles.map { angle in
            let x = center.x + CGFloat(cos(angle)) * size.width / 2
            let y = center.y + CGFloat(sin(angle)) * size.height / 2
            return CGPoint(x: x, y: y)
        }
    }
}