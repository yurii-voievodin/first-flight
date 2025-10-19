import SpriteKit

class VirtualJoystick: SKNode {

    // Visual components
    private let outerCircle: SKShapeNode
    private let innerKnob: SKShapeNode
    private var directionArrows: [SKShapeNode] = []

    // Configuration
    private let outerRadius: CGFloat = 40
    private let knobRadius: CGFloat = 20
    private let maxKnobDistance: CGFloat = 30 // How far knob can move from center

    // State
    private var isActive: Bool = false
    private var touchStartLocation: CGPoint = .zero
    var currentDirection: CGVector = .zero

    override init() {
        // Create outer base circle
        outerCircle = SKShapeNode(circleOfRadius: outerRadius)
        outerCircle.fillColor = SKColor(white: 0.2, alpha: 0.6)
        outerCircle.strokeColor = SKColor(white: 0.4, alpha: 0.8)
        outerCircle.lineWidth = 2

        // Create inner knob circle
        innerKnob = SKShapeNode(circleOfRadius: knobRadius)
        innerKnob.fillColor = SKColor(white: 0.5, alpha: 0.6)
        innerKnob.strokeColor = SKColor(white: 0.7, alpha: 0.8)
        innerKnob.lineWidth = 2

        super.init()

        // Add visual components
        addChild(outerCircle)
        addChild(innerKnob)

        // Create directional arrows
        createDirectionalArrows()

        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createDirectionalArrows() {
        let arrowLength: CGFloat = 12
        let arrowWidth: CGFloat = 2
        let arrowDistance = outerRadius - 8

        // 8 directions: N, NE, E, SE, S, SW, W, NW
        let directions: [(angle: CGFloat, label: String)] = [
            (CGFloat.pi / 2, "N"),           // Up
            (CGFloat.pi / 4, "NE"),          // Up-Right
            (0, "E"),                         // Right
            (-CGFloat.pi / 4, "SE"),         // Down-Right
            (-CGFloat.pi / 2, "S"),          // Down
            (-3 * CGFloat.pi / 4, "SW"),     // Down-Left
            (CGFloat.pi, "W"),                // Left
            (3 * CGFloat.pi / 4, "NW")       // Up-Left
        ]

        for (angle, _) in directions {
            let arrow = createArrow(length: arrowLength, width: arrowWidth)
            arrow.position = CGPoint(
                x: cos(angle) * arrowDistance,
                y: sin(angle) * arrowDistance
            )
            arrow.zRotation = angle - CGFloat.pi / 2 // Rotate to point in correct direction
            arrow.alpha = 0.5

            outerCircle.addChild(arrow)
            directionArrows.append(arrow)
        }
    }

    private func createArrow(length: CGFloat, width: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()

        // Arrow shaft
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: length))

        // Arrow head
        let headSize: CGFloat = 4
        path.move(to: CGPoint(x: 0, y: length))
        path.addLine(to: CGPoint(x: -headSize / 2, y: length - headSize))
        path.move(to: CGPoint(x: 0, y: length))
        path.addLine(to: CGPoint(x: headSize / 2, y: length - headSize))

        let arrow = SKShapeNode(path: path)
        arrow.strokeColor = SKColor(white: 0.9, alpha: 0.8)
        arrow.lineWidth = width
        arrow.lineCap = .round

        return arrow
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if touch is within outer circle
        let distance = hypot(location.x, location.y)
        if distance <= outerRadius {
            isActive = true
            touchStartLocation = location
            updateKnobPosition(touchLocation: location)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isActive, let touch = touches.first else { return }
        let location = touch.location(in: self)
        updateKnobPosition(touchLocation: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetJoystick()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetJoystick()
    }

    private func updateKnobPosition(touchLocation: CGPoint) {
        var direction = CGVector(dx: touchLocation.x, dy: touchLocation.y)
        let distance = hypot(direction.dx, direction.dy)

        // Normalize direction
        if distance > 0 {
            direction.dx /= distance
            direction.dy /= distance
        }

        // Clamp knob position within max distance
        let clampedDistance = min(distance, maxKnobDistance)
        let knobPosition = CGPoint(
            x: direction.dx * clampedDistance,
            y: direction.dy * clampedDistance
        )

        // Update knob visual position
        innerKnob.position = knobPosition

        // Update current direction (only if moved significantly from center)
        if distance > 5 { // Dead zone
            currentDirection = direction
            highlightActiveDirection()
        } else {
            currentDirection = .zero
            resetArrowHighlights()
        }
    }

    private func highlightActiveDirection() {
        // Highlight the arrow closest to current direction
        guard currentDirection != .zero else {
            resetArrowHighlights()
            return
        }

        let angle = atan2(currentDirection.dy, currentDirection.dx)
        let directions: [CGFloat] = [
            CGFloat.pi / 2,           // Up
            CGFloat.pi / 4,           // Up-Right
            0,                         // Right
            -CGFloat.pi / 4,          // Down-Right
            -CGFloat.pi / 2,          // Down
            -3 * CGFloat.pi / 4,      // Down-Left
            CGFloat.pi,                // Left
            3 * CGFloat.pi / 4        // Up-Left
        ]

        // Find closest direction
        var closestIndex = 0
        var minDifference = CGFloat.infinity

        for (index, dirAngle) in directions.enumerated() {
            var diff = abs(angle - dirAngle)
            // Handle wrap around at -π/π
            if diff > CGFloat.pi {
                diff = 2 * CGFloat.pi - diff
            }

            if diff < minDifference {
                minDifference = diff
                closestIndex = index
            }
        }

        // Highlight closest arrow
        for (index, arrow) in directionArrows.enumerated() {
            arrow.alpha = (index == closestIndex) ? 1.0 : 0.3
        }
    }

    private func resetArrowHighlights() {
        for arrow in directionArrows {
            arrow.alpha = 0.5
        }
    }

    private func resetJoystick() {
        isActive = false
        currentDirection = .zero

        // Animate knob back to center
        let moveAction = SKAction.move(to: .zero, duration: 0.1)
        moveAction.timingMode = .easeOut
        innerKnob.run(moveAction)

        resetArrowHighlights()
    }
}
