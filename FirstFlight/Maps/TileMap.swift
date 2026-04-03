import SpriteKit

final class TileMap {

    let tileSize: CGFloat
    let tileColumns: Int
    let tileRows: Int

    init(grid: TileGrid) {
        self.tileColumns = grid.columns
        self.tileRows = grid.rows
        self.tileSize = CGFloat(grid.tileSize)
    }

    /// Creates the tile map node asynchronously (texture generation runs off main thread).
    func createNode(completion: @escaping (SKTileMapNode) -> Void) {
        let cols = tileColumns
        let rows = tileRows
        let size = tileSize

        TerrainTextureFactory.generateTerrainTextures(tileColumns: cols, tileRows: rows, tileSize: size) { tileSet in
            let tileMapNode = SKTileMapNode(
                tileSet: tileSet,
                columns: cols,
                rows: rows,
                tileSize: CGSize(width: size, height: size)
            )

            tileMapNode.name = "ground"
            tileMapNode.zPosition = -100
            tileMapNode.anchorPoint = CGPoint(x: 0, y: 0)
            tileMapNode.position = .zero

            let groups = tileSet.tileGroups
            for r in 0..<rows {
                for c in 0..<cols {
                    let idx = (r * cols) + c
                    tileMapNode.setTileGroup(groups[idx], forColumn: c, row: r)
                }
            }

            completion(tileMapNode)
        }
    }
}
