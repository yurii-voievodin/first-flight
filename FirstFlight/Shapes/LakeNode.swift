import SpriteKit
import GameplayKit

class LakeNode: SKShapeNode {
    private let lakeDepth: CGFloat
    private let shorelineProperties: [String: String]?
    private let lakeName: String?
    private let lakeDescription: String?
    private let randomSource: GKLinearCongruentialRandomSource

    init(
        name: String?,
        description: String?,
        position: CGPoint,
        size: CGSize,
        depth: CGFloat = 1.0,
        shorelineProperties: [String: String]? = nil
    ) {
        self.lakeName = name
        self.lakeDescription = description
        self.shorelineProperties = shorelineProperties
        self.lakeDepth = max(depth, 0.0)
        let seed = LakeNode.computeSeed(from: position)
        self.randomSource = GKLinearCongruentialRandomSource(seed: seed)
        super.init()

        self.position = position
        createLakeShape(size: size)
        setupVisuals(size: size)
        setupPhysics()
        populateUserData()
    }

    required init?(coder aDecoder: NSCoder) {
        self.lakeDepth = 1.0
        self.shorelineProperties = nil
        self.lakeName = nil
        self.lakeDescription = nil
        self.randomSource = GKLinearCongruentialRandomSource()
        super.init(coder: aDecoder)
    }

    private func createLakeShape(size: CGSize) {
        let path = createOrganicWaterPath(size: size)
        self.path = path
    }

    private func setupVisuals(size: CGSize) {
        let depthFactor = min(lakeDepth / 60.0, 1.0)
        let deepBlue = CGFloat(0.5 + depthFactor * 0.3)
        let greenComponent = CGFloat(0.4 + depthFactor * 0.2)
        fillColor = SKColor(red: 0.0, green: greenComponent, blue: deepBlue, alpha: 0.55 + depthFactor * 0.25)
        strokeColor = SKColor.white.withAlphaComponent(0.6)
        lineWidth = 2.5
        zPosition = -20
        name = lakeName ?? "Lake"

        // Optional shoreline hints alter outline style
        if let shoreline = shorelineProperties {
            if shoreline["shallowGradient"] == "true" {
                strokeColor = SKColor.cyan.withAlphaComponent(0.7)
                lineWidth = 3.5
            }
            if shoreline["boulderRim"] == "true" {
                lineWidth = 4.0
            }
        }
    }

    private func setupPhysics() {
        guard let lakePath = path else { return }
        physicsBody = SKPhysicsBody(polygonFrom: lakePath)
        physicsBody?.categoryBitMask = PhysicsCategory.terrain
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.player
        physicsBody?.isDynamic = false
        physicsBody?.friction = 0.2
        physicsBody?.restitution = 0.0
    }

    private func populateUserData() {
        let data = NSMutableDictionary()
        if let name = lakeName {
            data["name"] = name
        }
        if let description = lakeDescription {
            data["description"] = description
        }
        if let properties = shorelineProperties {
            for (key, value) in properties {
                data[key] = value
            }
        }
        if data.count > 0 {
            userData = data
        }
    }

    private func randomCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let span = range.upperBound - range.lowerBound
        return range.lowerBound + CGFloat(randomSource.nextUniform()) * span
    }

    private func createOrganicWaterPath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        let pointCount = randomSource.nextInt(upperBound: 6) + 12

        let radiusX = size.width / 2
        let radiusY = size.height / 2
        let jitterX = max(10, radiusX * 0.2)
        let jitterY = max(10, radiusY * 0.2)

        var points: [CGPoint] = []
        for index in 0..<pointCount {
            let angle = CGFloat(index) / CGFloat(pointCount) * .pi * 2
            let noiseX = randomCGFloat(in: -jitterX...jitterX)
            let noiseY = randomCGFloat(in: -jitterY...jitterY)
            let x = cos(angle) * radiusX + noiseX
            let y = sin(angle) * radiusY + noiseY
            points.append(CGPoint(x: x, y: y))
        }

        guard !points.isEmpty else {
            return path
        }

        path.move(to: points[0])
        for i in 0..<points.count {
            let current = points[i]
            let next = points[(i + 1) % points.count]
            let midPoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            path.addQuadCurve(to: midPoint, control: current)
        }
        path.closeSubpath()

        return path
    }

    private static func computeSeed(from position: CGPoint) -> UInt64 {
        let xSeed = UInt64(abs(Int(position.x * 1000))) & 0xFFFFFFFF
        let ySeed = UInt64(abs(Int(position.y * 1000))) & 0xFFFFFFFF
        return (xSeed << 32) | ySeed
    }
}
