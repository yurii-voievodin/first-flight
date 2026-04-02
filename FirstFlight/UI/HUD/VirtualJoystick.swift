import SpriteKit

class VirtualJoystick: SKNode {

    // Visual components
    private let outerCircle: SKShapeNode
    private let innerKnob: SKShapeNode

    // Configuration
    private let outerRadius: CGFloat = 40
    private let knobRadius: CGFloat = 20
    private let maxKnobDistance: CGFloat = 30 // How far knob can move from center

    // State
    private var isActive: Bool = false
    private var touchStartLocation: CGPoint = .zero
    var currentDirection: CGVector = .zero

    // Computed angle in radians (nil when in dead zone)
    var currentAngle: CGFloat? {
        guard currentDirection != .zero else { return nil }
        return atan2(currentDirection.dy, currentDirection.dx)
    }

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

        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Input Handling

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

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
    #endif

    #if os(macOS)
    private var pressedKeys: Set<UInt16> = []
    var onJumpStart: (() -> Void)?
    var onJumpEnd: (() -> Void)?

    // Key codes: W=13, A=0, S=1, D=2, Space=49
    func handleKeyDown(_ keyCode: UInt16) {
        if keyCode == 49 {
            onJumpStart?()
            return
        }
        pressedKeys.insert(keyCode)
        updateKeyboardDirection()
    }

    func handleKeyUp(_ keyCode: UInt16) {
        if keyCode == 49 {
            onJumpEnd?()
            return
        }
        pressedKeys.remove(keyCode)
        updateKeyboardDirection()
    }

    private func updateKeyboardDirection() {
        var dx: CGFloat = 0
        var dy: CGFloat = 0

        if pressedKeys.contains(0)  { dx -= 1 } // A
        if pressedKeys.contains(2)  { dx += 1 } // D
        if pressedKeys.contains(13) { dy += 1 } // W
        if pressedKeys.contains(1)  { dy -= 1 } // S

        if dx == 0 && dy == 0 {
            currentDirection = .zero
            innerKnob.position = .zero
        } else {
            let len = hypot(dx, dy)
            currentDirection = CGVector(dx: dx / len, dy: dy / len)
            innerKnob.position = CGPoint(x: currentDirection.dx * maxKnobDistance,
                                         y: currentDirection.dy * maxKnobDistance)
        }
    }
    #endif

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
        } else {
            currentDirection = .zero
        }
    }

    private func resetJoystick() {
        isActive = false
        currentDirection = .zero

        // Animate knob back to center
        let moveAction = SKAction.move(to: .zero, duration: 0.1)
        moveAction.timingMode = .easeOut
        innerKnob.run(moveAction)
    }
}
