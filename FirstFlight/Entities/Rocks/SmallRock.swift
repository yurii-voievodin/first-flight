import SpriteKit

enum SmallRockVariation: Int, CaseIterable {
    case pebble = 0
    case stone = 1
    case chip = 2
    case fragment = 3
}

class SmallRock: SKShapeNode {

    init(position: CGPoint, variation: SmallRockVariation = .pebble) {
        super.init()

        self.position = position
        createShape(variation: variation)
        setupVisuals(variation: variation)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func createShape(variation: SmallRockVariation) {
        let path: CGPath

        switch variation {
        case .pebble:
            path = createPebblePath()
        case .stone:
            path = createStonePath()
        case .chip:
            path = createChipPath()
        case .fragment:
            path = createFragmentPath()
        }

        self.path = path
    }

    private func createPebblePath() -> CGPath {
        let path = CGMutablePath()
        // Small irregular oval shape (~10x8)
        path.move(to: CGPoint(x: 2, y: 0))
        path.addCurve(to: CGPoint(x: 10, y: 3),
                     control1: CGPoint(x: 5, y: -1),
                     control2: CGPoint(x: 8, y: 0))
        path.addCurve(to: CGPoint(x: 8, y: 8),
                     control1: CGPoint(x: 11, y: 5),
                     control2: CGPoint(x: 10, y: 7))
        path.addCurve(to: CGPoint(x: 1, y: 6),
                     control1: CGPoint(x: 5, y: 9),
                     control2: CGPoint(x: 2, y: 8))
        path.addCurve(to: CGPoint(x: 2, y: 0),
                     control1: CGPoint(x: 0, y: 4),
                     control2: CGPoint(x: 0, y: 1))
        path.closeSubpath()
        return path
    }

    private func createStonePath() -> CGPath {
        let path = CGMutablePath()
        // Angular stone shape (~12x10)
        path.move(to: CGPoint(x: 3, y: 0))
        path.addLine(to: CGPoint(x: 9, y: 1))
        path.addLine(to: CGPoint(x: 12, y: 5))
        path.addLine(to: CGPoint(x: 10, y: 9))
        path.addLine(to: CGPoint(x: 4, y: 10))
        path.addLine(to: CGPoint(x: 0, y: 6))
        path.addLine(to: CGPoint(x: 1, y: 2))
        path.closeSubpath()
        return path
    }

    private func createChipPath() -> CGPath {
        let path = CGMutablePath()
        // Small triangular chip (~8x7)
        path.move(to: CGPoint(x: 1, y: 0))
        path.addLine(to: CGPoint(x: 7, y: 2))
        path.addLine(to: CGPoint(x: 8, y: 6))
        path.addLine(to: CGPoint(x: 4, y: 7))
        path.addLine(to: CGPoint(x: 0, y: 4))
        path.closeSubpath()
        return path
    }

    private func createFragmentPath() -> CGPath {
        let path = CGMutablePath()
        // Irregular fragment (~14x11)
        path.move(to: CGPoint(x: 4, y: 0))
        path.addCurve(to: CGPoint(x: 12, y: 4),
                     control1: CGPoint(x: 8, y: 0),
                     control2: CGPoint(x: 11, y: 2))
        path.addLine(to: CGPoint(x: 14, y: 7))
        path.addCurve(to: CGPoint(x: 9, y: 11),
                     control1: CGPoint(x: 13, y: 10),
                     control2: CGPoint(x: 11, y: 11))
        path.addLine(to: CGPoint(x: 3, y: 9))
        path.addCurve(to: CGPoint(x: 0, y: 5),
                     control1: CGPoint(x: 1, y: 8),
                     control2: CGPoint(x: 0, y: 7))
        path.addLine(to: CGPoint(x: 2, y: 2))
        path.closeSubpath()
        return path
    }

    private func setupVisuals(variation: SmallRockVariation) {
        switch variation {
        case .pebble:
            fillColor = SKColor(white: 0.68, alpha: 1.0)
            strokeColor = SKColor(white: 0.68, alpha: 1.0)
        case .stone:
            fillColor = SKColor(white: 0.78, alpha: 1.0)
            strokeColor = SKColor(white: 0.78, alpha: 1.0)
        case .chip:
            fillColor = .systemBrown.withAlphaComponent(0.8)
            strokeColor = .systemBrown.withAlphaComponent(0.8)
        case .fragment:
            fillColor = .systemGray
            strokeColor = .systemGray
        }

        lineWidth = 1.0
        zPosition = -11 // Below player (player is at -10)

        addSoftShadowAndHighlight()
    }

    private func addSoftShadowAndHighlight() {
        guard let path = self.path else { return }

        let bounds = path.boundingBox
        let offset = CGSize(width: bounds.width * 0.04, height: bounds.height * 0.04)

        // Shadow: simple offset shape (no blur — imperceptible at 8-14px)
        let shadowShape = SKShapeNode(path: path)
        shadowShape.fillColor = .black
        shadowShape.strokeColor = .clear
        shadowShape.lineWidth = 0
        shadowShape.alpha = 0.25
        shadowShape.blendMode = .multiply
        shadowShape.position = CGPoint(x: offset.width, y: -offset.height)
        addChild(shadowShape)

        // Highlight: slightly scaled-down shape
        let highlightShape = SKShapeNode(path: path)
        highlightShape.fillColor = .white
        highlightShape.strokeColor = .clear
        highlightShape.lineWidth = 0
        highlightShape.alpha = 0.12
        highlightShape.blendMode = .add
        highlightShape.setScale(0.92)
        highlightShape.position = CGPoint(x: -offset.width * 0.6, y: offset.height * 0.6)
        addChild(highlightShape)
    }
}
