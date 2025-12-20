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

    func createNode() -> SKTileMapNode {
        let tileSet = TerrainTextureFactory.generateTerrainTextures(
            tileColumns: tileColumns,
            tileRows: tileRows,
            tileSize: tileSize
        )

        let tileMapNode = SKTileMapNode(
            tileSet: tileSet,
            columns: tileColumns,
            rows: tileRows,
            tileSize: CGSize(width: tileSize, height: tileSize)
        )

        tileMapNode.name = "ground"
        tileMapNode.zPosition = -100
        tileMapNode.anchorPoint = CGPoint(x: 0, y: 0)
        tileMapNode.position = .zero

        let groups = tileSet.tileGroups
        for r in 0..<tileRows {
            for c in 0..<tileColumns {
                let idx = (r * tileColumns) + c
                tileMapNode.setTileGroup(groups[idx], forColumn: c, row: r)
            }
        }

        return tileMapNode
    }
}
