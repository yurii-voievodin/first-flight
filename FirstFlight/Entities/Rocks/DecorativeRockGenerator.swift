import SpriteKit

struct DecorativeRockGenerator {
    let sceneSize: CGSize

    func generateDecorativeSmallRocks(
        totalCount: Int,
        anchoredFraction: CGFloat,
        interiorRocks: [RockFormation],
        lakes: [LakeNode]
    ) -> [SKNode] {
        guard totalCount > 0 else { return [] }

        let anchoredCount = min(Int(round(CGFloat(totalCount) * anchoredFraction)), totalCount)
        let freeCount = totalCount - anchoredCount

        var placedPoints: [CGPoint] = []
        placedPoints.reserveCapacity(totalCount)

        var result: [SKNode] = []
        result.reserveCapacity(totalCount)

        // 1) Anchored: place near / slightly below interior rocks
        if !interiorRocks.isEmpty, anchoredCount > 0 {
            for i in 0..<anchoredCount {
                // Round-robin through interior rocks for a more even distribution
                let anchor = interiorRocks[i % interiorRocks.count]

                if let p = findValidAnchoredPoint(near: anchor, lakes: lakes, placedPoints: placedPoints) {
                    placedPoints.append(p)
                    result.append(makeDecorativeSmallRock(at: p, variation: i))
                }
            }
        }

        // 2) Free scatter: place anywhere (but avoid lakes & overlaps)
        if freeCount > 0 {
            for i in 0..<freeCount {
                if let p = findValidFreePoint(lakes: lakes, placedPoints: placedPoints) {
                    placedPoints.append(p)
                    result.append(makeDecorativeSmallRock(at: p, variation: anchoredCount + i))
                }
            }
        }

        return result
    }

    func makeDecorativeSmallRock(at position: CGPoint, variation: Int) -> SmallRock {
        // Use the project's shape-based small rock (better silhouette than a textured sprite).
        let all = SmallRockVariation.allCases
        let v = all[abs(variation) % all.count]

        let node = SmallRock(position: position, variation: v)

        // Slight rotation variety
        node.zRotation = CGFloat(variation % 360) * (.pi / 180)

        // Optional: subtle size variance by scaling (keeps the authored paths)
        // Range ~0.85...1.25
        let t = CGFloat((variation % 17) - 8) / 40.0
        node.setScale(max(0.85, min(1.25, 1.0 + t)))

        return node
    }

    func findValidAnchoredPoint(
        near anchor: RockFormation,
        lakes: [LakeNode],
        placedPoints: [CGPoint]
    ) -> CGPoint? {
        // Try a handful of candidates around the anchor rock
        let attempts = 24

        // Place in a ring around the rock; bias Y slightly downward sometimes
        let baseRadius = max(8, anchor.maxRadius * 0.75)

        for _ in 0..<attempts {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let extra = CGFloat.random(in: 8...42)
            let r = baseRadius + extra

            let dx = cos(angle) * r
            var dy = sin(angle) * r

            // 65% chance: push slightly downward to read as "under/below" the large rock
            if CGFloat.random(in: 0...1) < 0.65 {
                dy -= CGFloat.random(in: 10...34)
            }

            let p = CGPoint(x: anchor.position.x + dx, y: anchor.position.y + dy)
            if isValidSmallRockPoint(p, lakes: lakes, placedPoints: placedPoints) {
                return p
            }
        }

        return nil
    }

    func findValidFreePoint(
        lakes: [LakeNode],
        placedPoints: [CGPoint]
    ) -> CGPoint? {
        let attempts = 80

        // Keep away from edges a bit
        let margin: CGFloat = 24
        let minX = margin
        let maxX = max(margin, sceneSize.width - margin)
        let minY = margin
        let maxY = max(margin, sceneSize.height - margin)

        guard minX < maxX, minY < maxY else { return nil }

        for _ in 0..<attempts {
            let p = CGPoint(
                x: CGFloat.random(in: minX...maxX),
                y: CGFloat.random(in: minY...maxY)
            )

            if isValidSmallRockPoint(p, lakes: lakes, placedPoints: placedPoints) {
                return p
            }
        }

        return nil
    }

    private func isValidSmallRockPoint(
        _ p: CGPoint,
        lakes: [LakeNode],
        placedPoints: [CGPoint]
    ) -> Bool {
        // 1) Avoid lakes
        for lake in lakes {
            if lake.contains(p) {
                return false
            }
        }

        // 2) Avoid crowding other small rocks
        let minDist: CGFloat = 14
        for q in placedPoints {
            if hypot(p.x - q.x, p.y - q.y) < minDist {
                return false
            }
        }

        // 3) Must be inside scene bounds
        if p.x < 0 || p.y < 0 || p.x > sceneSize.width || p.y > sceneSize.height {
            return false
        }

        return true
    }
}
