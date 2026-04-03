import SpriteKit

class SpaceShuttle: SKNode {
    private let shuttleScale: CGFloat
    private var renderedSize: CGSize = .zero

    // MARK: - Inventory
    private(set) var inventory: Inventory

    init(scale: CGFloat = 0.6, inventory: Inventory) {
        self.shuttleScale = scale
        self.inventory = inventory
        super.init()
        zPosition = -11 // Below player (player is at -10)
        setupSprite()
        setupShadowAndHighlight()
        applyPhysics(using: shuttlePolygonPoints())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSprite() {
        let texture = SKTexture(imageNamed: "space shuttle")
        texture.filteringMode = .linear

        // Get natural texture size and calculate rendered size
        let naturalSize = texture.size()
        renderedSize = CGSize(
            width: naturalSize.width * shuttleScale,
            height: naturalSize.height * shuttleScale
        )

        let sprite = SKSpriteNode(texture: texture)
        sprite.setScale(shuttleScale)
        sprite.name = "shuttle-sprite"
        sprite.zPosition = 0
        addChild(sprite)
    }

    private func setupShadowAndHighlight() {
        let offset = CGSize(width: renderedSize.width * 0.04, height: renderedSize.height * 0.04)

        // Scale blur radius proportionally (base 200x160 used radius 5/4)
        let scaleFactor = renderedSize.width / 200.0
        let shadowBlurRadius = 5.0 * scaleFactor * 0.53
        let highlightBlurRadius = 4.0 * scaleFactor * 0.5

        // Soft shadow with blur
        let shadowTexture = SKTexture(imageNamed: "space shuttle")
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.setScale(shuttleScale)
        shadowSprite.color = .black
        shadowSprite.colorBlendFactor = 1.0
        shadowSprite.alpha = 0.45
        shadowSprite.blendMode = .multiply

        let shadowEffect = SKEffectNode()
        shadowEffect.name = "shuttle-shadow"
        shadowEffect.shouldRasterize = true
        shadowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: shadowBlurRadius])
        shadowEffect.position = CGPoint(x: offset.width, y: -offset.height)
        shadowEffect.zPosition = -1
        shadowEffect.addChild(shadowSprite)
        addChild(shadowEffect)

        // Highlight with blur
        let highlightTexture = SKTexture(imageNamed: "space shuttle")
        let highlightSprite = SKSpriteNode(texture: highlightTexture)
        highlightSprite.setScale(shuttleScale * 0.92)
        highlightSprite.color = .white
        highlightSprite.colorBlendFactor = 1.0
        highlightSprite.alpha = 0.18
        highlightSprite.blendMode = .add

        let highlightEffect = SKEffectNode()
        highlightEffect.name = "shuttle-highlight"
        highlightEffect.shouldRasterize = true
        highlightEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: highlightBlurRadius])
        highlightEffect.position = CGPoint(x: -offset.width * 0.6, y: offset.height * 0.6)
        highlightEffect.zPosition = 1
        highlightEffect.addChild(highlightSprite)
        addChild(highlightEffect)
    }

    private func shuttlePolygonPoints() -> [CGPoint] {
        let w = renderedSize.width
        let h = renderedSize.height

        return [
            CGPoint(x: w * -0.264, y: h * 0.065), // 0  (-158, 30)
            CGPoint(x: w * -0.331, y: h * 0.157), // 1  (-198, 75)
            CGPoint(x: w * -0.451, y: h * 0.267), // 2  (-270, 128)
            CGPoint(x: w * -0.345, y: h * 0.293), // 3  (-207, 140)
            CGPoint(x: w * -0.284, y: h * 0.257), // 4  (-170, 123)
            CGPoint(x: w * -0.232, y: h * 0.228), // 5  (-139, 109)
            CGPoint(x: w * -0.147, y: h * 0.222), // 6  (-88, 106)
            CGPoint(x: w * 0.008, y: h * 0.268), // 7  (4, 128)
            CGPoint(x: w * 0.087, y: h * 0.395), // 8  (52, 189)
            CGPoint(x: w * 0.202, y: h * 0.503), // 9  (121, 241)
            CGPoint(x: w * 0.229, y: h * 0.297), // 10  (137, 142)
            CGPoint(x: w * 0.367, y: h * 0.258), // 11  (220, 123)
            CGPoint(x: w * 0.370, y: h * 0.124), // 12  (222, 59)
            CGPoint(x: w * 0.311, y: h * 0.072), // 13  (186, 34)
            CGPoint(x: w * 0.500, y: h * 0.000), // 14  (300, 0)
            CGPoint(x: w * 0.483, y: h * -0.041), // 15  (289, -19)
            CGPoint(x: w * 0.488, y: h * -0.069), // 16  (292, -33)
            CGPoint(x: w * 0.433, y: h * -0.099), // 17  (259, -47)
            CGPoint(x: w * 0.342, y: h * -0.090), // 18  (205, -43)
            CGPoint(x: w * 0.273, y: h * -0.093), // 19  (163, -44)
            CGPoint(x: w * 0.182, y: h * -0.072), // 20  (109, -34)
            CGPoint(x: w * 0.062, y: h * -0.123), // 21  (37, -59)
            CGPoint(x: w * -0.083, y: h * -0.133), // 22  (-49, -63)
            CGPoint(x: w * -0.212, y: h * -0.190), // 23  (-126, -91)
            CGPoint(x: w * -0.278, y: h * -0.238), // 24  (-166, -114)
            CGPoint(x: w * -0.367, y: h * -0.232), // 25  (-219, -111)
            CGPoint(x: w * -0.395, y: h * -0.185), // 26  (-236, -89)
            CGPoint(x: w * -0.340, y: h * -0.019), // 27  (-204, -9)
        ]
    }

    private func applyPhysics(using points: [CGPoint]) {
        guard let body = makePhysicsBody(from: points) else { return }
        physicsBody = body
        physicsBody?.categoryBitMask = PhysicsCategory.spaceShuttle
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.player
        physicsBody?.isDynamic = false
        physicsBody?.friction = 0.8
        physicsBody?.restitution = 0.1
    }

    private func makePhysicsBody(from points: [CGPoint]) -> SKPhysicsBody? {
        guard points.count >= 3 else { return nil }
        if points.count == 3 {
            return SKPhysicsBody(polygonFrom: makePath(points))
        }

        let triangles = triangulate(points)
        guard !triangles.isEmpty else {
            return SKPhysicsBody(polygonFrom: makePath(points))
        }

        let bodies = triangles.map { SKPhysicsBody(polygonFrom: makePath($0)) }
        return SKPhysicsBody(bodies: bodies)
    }

    private func makePath(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    // Ear clipping triangulation for concave polygons.
    private func triangulate(_ points: [CGPoint]) -> [[CGPoint]] {
        let epsilon: CGFloat = 0.0001
        var vertices = points
        if polygonArea(vertices) < 0 {
            vertices.reverse()
        }

        var indices = Array(vertices.indices)
        var triangles: [[CGPoint]] = []
        var guardCounter = 0

        while indices.count > 3 && guardCounter < 1000 {
            var earFound = false
            let count = indices.count

            for i in 0..<count {
                let prevIndex = indices[(i - 1 + count) % count]
                let currIndex = indices[i]
                let nextIndex = indices[(i + 1) % count]

                let a = vertices[prevIndex]
                let b = vertices[currIndex]
                let c = vertices[nextIndex]

                if cross(a, b, c) <= epsilon {
                    continue
                }

                var hasPointInside = false
                for otherIndex in indices where otherIndex != prevIndex && otherIndex != currIndex && otherIndex != nextIndex {
                    if pointInTriangle(vertices[otherIndex], a, b, c) {
                        hasPointInside = true
                        break
                    }
                }
                if hasPointInside {
                    continue
                }

                triangles.append([a, b, c])
                indices.remove(at: i)
                earFound = true
                break
            }

            if !earFound {
                break
            }
            guardCounter += 1
        }

        if indices.count == 3 {
            let a = vertices[indices[0]]
            let b = vertices[indices[1]]
            let c = vertices[indices[2]]
            triangles.append([a, b, c])
        }

        return triangles
    }

    private func polygonArea(_ points: [CGPoint]) -> CGFloat {
        guard points.count >= 3 else { return 0 }
        var area: CGFloat = 0
        for i in 0..<points.count {
            let p1 = points[i]
            let p2 = points[(i + 1) % points.count]
            area += (p1.x * p2.y) - (p2.x * p1.y)
        }
        return area * 0.5
    }

    private func cross(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    }

    private func pointInTriangle(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Bool {
        let v0 = CGPoint(x: c.x - a.x, y: c.y - a.y)
        let v1 = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let v2 = CGPoint(x: p.x - a.x, y: p.y - a.y)

        let dot00 = v0.x * v0.x + v0.y * v0.y
        let dot01 = v0.x * v1.x + v0.y * v1.y
        let dot02 = v0.x * v2.x + v0.y * v2.y
        let dot11 = v1.x * v1.x + v1.y * v1.y
        let dot12 = v1.x * v2.x + v1.y * v2.y

        let denom = (dot00 * dot11 - dot01 * dot01)
        if abs(denom) < 0.0001 { return false }

        let invDenom = 1 / denom
        let u = (dot11 * dot02 - dot01 * dot12) * invDenom
        let v = (dot00 * dot12 - dot01 * dot02) * invDenom

        return u >= 0 && v >= 0 && (u + v) <= 1
    }
}
