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

        let minDist: CGFloat = 14
        var grid = SpatialGrid(cellSize: minDist, sceneSize: sceneSize)

        var result: [SKNode] = []
        result.reserveCapacity(totalCount)

        // 1) Anchored: place near / slightly below interior rocks
        if !interiorRocks.isEmpty, anchoredCount > 0 {
            for i in 0..<anchoredCount {
                // Round-robin through interior rocks for a more even distribution
                let anchor = interiorRocks[i % interiorRocks.count]

                if let p = findValidAnchoredPoint(near: anchor, lakes: lakes, grid: grid, minDist: minDist) {
                    grid.insert(p)
                    result.append(makeDecorativeSmallRock(at: p, variation: i))
                }
            }
        }

        // 2) Free scatter: place anywhere (but avoid lakes & overlaps)
        if freeCount > 0 {
            for i in 0..<freeCount {
                if let p = findValidFreePoint(lakes: lakes, grid: grid, minDist: minDist) {
                    grid.insert(p)
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
        grid: SpatialGrid,
        minDist: CGFloat
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
            if isValidSmallRockPoint(p, lakes: lakes, grid: grid, minDist: minDist) {
                return p
            }
        }

        return nil
    }

    func findValidFreePoint(
        lakes: [LakeNode],
        grid: SpatialGrid,
        minDist: CGFloat
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

            if isValidSmallRockPoint(p, lakes: lakes, grid: grid, minDist: minDist) {
                return p
            }
        }

        return nil
    }

    private func isValidSmallRockPoint(
        _ p: CGPoint,
        lakes: [LakeNode],
        grid: SpatialGrid,
        minDist: CGFloat
    ) -> Bool {
        // 1) Must be inside scene bounds
        if p.x < 0 || p.y < 0 || p.x > sceneSize.width || p.y > sceneSize.height {
            return false
        }

        // 2) Avoid lakes
        for lake in lakes {
            if lake.contains(p) {
                return false
            }
        }

        // 3) Avoid crowding other small rocks
        return !grid.hasNeighbor(near: p, minDist: minDist)
    }
}

// MARK: - Spatial Grid

struct SpatialGrid {
    private let cellSize: CGFloat
    private var cells: [Int: [CGPoint]] = [:]
    private let columns: Int

    init(cellSize: CGFloat, sceneSize: CGSize) {
        self.cellSize = cellSize
        self.columns = max(1, Int(ceil(sceneSize.width / cellSize)) + 1)
    }

    private func cellCoord(for point: CGPoint) -> (col: Int, row: Int) {
        (Int(floor(point.x / cellSize)), Int(floor(point.y / cellSize)))
    }

    private func key(col: Int, row: Int) -> Int {
        row * columns + col
    }

    mutating func insert(_ point: CGPoint) {
        let (col, row) = cellCoord(for: point)
        let k = key(col: col, row: row)
        cells[k, default: []].append(point)
    }

    func hasNeighbor(near point: CGPoint, minDist: CGFloat) -> Bool {
        let (col, row) = cellCoord(for: point)
        let minDistSq = minDist * minDist

        for dr in -1...1 {
            for dc in -1...1 {
                let k = key(col: col + dc, row: row + dr)
                guard let bucket = cells[k] else { continue }
                for q in bucket {
                    let dx = point.x - q.x
                    let dy = point.y - q.y
                    if dx * dx + dy * dy < minDistSq {
                        return true
                    }
                }
            }
        }
        return false
    }
}
