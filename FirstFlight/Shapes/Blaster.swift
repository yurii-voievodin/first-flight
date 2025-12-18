import SpriteKit

final class Blaster: SKNode {
    enum Orientation {
        case up
        case down
        case left
        case right
    }

    private let grip: SKShapeNode
    private let gripAnchor: SKNode
    private let gripMount: SKShapeNode
    private let body: SKShapeNode
    private let barrel: SKShapeNode
    private let emitter: SKShapeNode
    private let beam: SKSpriteNode

    private var orientation: Orientation = .down
    private var isFiring = false
    private var restingEmitterAlpha: CGFloat = 0.8

    override init() {
        let gripSize = CGSize(width: 4.5, height: 11)
        grip = SKShapeNode(rectOf: gripSize, cornerRadius: 1.6)
        gripAnchor = SKNode()
        gripMount = SKShapeNode()
        body = SKShapeNode(rectOf: CGSize(width: 6.5, height: 19), cornerRadius: 3)
        barrel = SKShapeNode(rectOf: CGSize(width: 4.2, height: 12.5), cornerRadius: 1.6)
        emitter = SKShapeNode(circleOfRadius: 2.3)
        let beamSize = CGSize(width: 6, height: 120)
        let beamTexture = Blaster.createRoundedBeamTexture(size: beamSize, cornerRadius: 3, color: SKColor.cyan.withAlphaComponent(0.5))
        beam = SKSpriteNode(texture: beamTexture, size: beamSize)

        super.init()

        position = CGPoint(x: 3, y: -4)
        zPosition = -1.0 // Low base so grip can hide behind hand

        grip.fillColor = SKColor(red: 0.2, green: 0.24, blue: 0.28, alpha: 1)
        grip.strokeColor = SKColor.black.withAlphaComponent(0.35)
        grip.lineWidth = 1
        grip.position = CGPoint(x: -4.4, y: -3.8)
        grip.zRotation = -.pi / 2.08
        grip.zPosition = -1.0 // Behind hand to show grip is inside hand
        addChild(grip)

        gripAnchor.position = CGPoint(x: 0, y: gripSize.height * 0.5 - 0.6)
        grip.addChild(gripAnchor)

        let mountPath = CGMutablePath()
        mountPath.move(to: CGPoint(x: -6.0, y: 1.2))
        mountPath.addLine(to: CGPoint(x: 1.2, y: -5.4))
        mountPath.addLine(to: CGPoint(x: 4.5, y: 2.0))
        mountPath.addQuadCurve(to: CGPoint(x: -6.0, y: 1.2), control: CGPoint(x: -0.8, y: 6.4))
        gripMount.path = mountPath
        gripMount.fillColor = SKColor(red: 0.33, green: 0.4, blue: 0.47, alpha: 1)
        gripMount.strokeColor = SKColor.black.withAlphaComponent(0.25)
        gripMount.lineWidth = 0.9
        gripMount.lineJoin = .round
        gripMount.position = CGPoint(x: -2.2, y: -3.6)
        gripMount.zPosition = 1.0 // Above hand
        addChild(gripMount)

        body.fillColor = SKColor(red: 0.45, green: 0.52, blue: 0.6, alpha: 1)
        body.strokeColor = SKColor.black.withAlphaComponent(0.28)
        body.lineWidth = 1
        body.position = CGPoint(x: 0.2, y: -9.6)
        body.zPosition = 1.5 // Above hand
        addChild(body)

        barrel.fillColor = SKColor(red: 0.72, green: 0.84, blue: 0.95, alpha: 0.9)
        barrel.strokeColor = SKColor.white.withAlphaComponent(0.4)
        barrel.lineWidth = 0.8
        barrel.position = CGPoint(x: 0.2, y: -14.5)
        barrel.zPosition = 2.0 // Above hand
        addChild(barrel)

        emitter.fillColor = SKColor.cyan.withAlphaComponent(0.8)
        emitter.strokeColor = SKColor.white.withAlphaComponent(0.6)
        emitter.lineWidth = 0.6
        emitter.position = CGPoint(x: 0.2, y: -21)
        emitter.zPosition = 2.5 // Above hand
        addChild(emitter)

        beam.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        beam.position = emitter.position
        beam.zPosition = 3.5
        beam.isHidden = true
        beam.alpha = 0
        beam.blendMode = .add
        // Physics body will be created when firing starts

        addChild(beam)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(for orientation: Orientation) {
        self.orientation = orientation

        isHidden = false
        alpha = 1
        xScale = 1
        yScale = 1
        zPosition = -1.0 // Keep low so grip stays behind hand

        body.fillColor = SKColor(red: 0.45, green: 0.52, blue: 0.6, alpha: 1)
        gripMount.fillColor = SKColor(red: 0.33, green: 0.4, blue: 0.47, alpha: 1)
        barrel.alpha = 0.9
        var emitterAlpha: CGFloat = 0.8

        grip.isHidden = false // Default: visible (hidden by zPosition for left/right)
        gripMount.isHidden = false // Default: visible

        let gripPose = orientation

        switch orientation {
        case .up:
            grip.isHidden = true
            gripMount.isHidden = true
            zPosition = -0.75
            emitterAlpha = 0.85
        case .down:
            grip.isHidden = true
            gripMount.isHidden = true
            emitterAlpha = 0.75
        case .right:
            zPosition = -1.1
            body.fillColor = SKColor(red: 0.42, green: 0.5, blue: 0.58, alpha: 1)
            gripMount.fillColor = SKColor(red: 0.37, green: 0.44, blue: 0.52, alpha: 1)
            emitterAlpha = 0.75
        case .left:
            xScale = -1 // Flip blaster horizontally to show left-facing direction
            zPosition = -1.1
            body.fillColor = SKColor(red: 0.42, green: 0.5, blue: 0.58, alpha: 1)
            gripMount.fillColor = SKColor(red: 0.37, green: 0.44, blue: 0.52, alpha: 1)
            emitterAlpha = 0.75
        }

        let anchorInBlaster = convert(gripAnchor.position, from: grip)
        let palm = palmTarget(for: gripPose)
        position = CGPoint(x: palm.x - anchorInBlaster.x, y: palm.y - anchorInBlaster.y)

        restingEmitterAlpha = emitterAlpha
        emitter.alpha = isFiring ? 1 : restingEmitterAlpha

        // Beam state is exclusively managed by startBeam() and stopBeam()
        // Do not call updateBeamState() here to avoid race conditions
    }

    private func palmTarget(for orientation: Orientation) -> CGPoint {
        switch orientation {
        case .down:
            return CGPoint(x: -0.6, y: -3.9)
        case .right:
            return CGPoint(x: 5.0, y: 1.5) // Shifted right and up to grip handle
        case .left:
            return CGPoint(x: -5.0, y: 1.5) // Shifted left and up to grip handle
        case .up:
            return CGPoint(x: -0.4, y: 3.6)
        }
    }

    func startBeam(distance: CGFloat) {
        guard !isFiring else { return }
        isFiring = true
        emitter.alpha = 1

        // Calculate beam length based on distance to target
        let beamLength = max(distance, 10) // Minimum 10 points to ensure visibility
        let beamWidth: CGFloat = 6

        // Resize beam sprite
        let newTexture = Blaster.createRoundedBeamTexture(
            size: CGSize(width: beamWidth, height: beamLength),
            cornerRadius: 3,
            color: SKColor.cyan.withAlphaComponent(0.5)
        )
        beam.texture = newTexture
        beam.size = CGSize(width: beamWidth, height: beamLength)

        // Create physics body for collision detection with new size
        let beamCenter = CGPoint(x: 0, y: -beamLength / 2)
        beam.physicsBody = SKPhysicsBody(rectangleOf: beam.size, center: beamCenter)
        beam.physicsBody?.categoryBitMask = PhysicsCategory.blasterBeam
        beam.physicsBody?.contactTestBitMask = PhysicsCategory.rock
        beam.physicsBody?.collisionBitMask = PhysicsCategory.none
        beam.physicsBody?.isDynamic = true
        beam.physicsBody?.affectedByGravity = false
        beam.physicsBody?.allowsRotation = false
        beam.physicsBody?.linearDamping = 0
        beam.physicsBody?.angularDamping = 0

        updateBeamState(animated: true)
    }

    func stopBeam() {
        guard isFiring else { return }
        isFiring = false
        emitter.alpha = restingEmitterAlpha

        // Remove physics body to stop collision detection
        beam.physicsBody = nil

        updateBeamState(animated: true)
    }

    private func updateBeamState(animated: Bool = false) {
        beam.removeAllActions()

        if isFiring {
            beam.isHidden = false
            beam.yScale = 1
            beam.position = emitter.position
            
        } else if !animated {
            beam.alpha = 0
            beam.isHidden = true
        }

        guard animated else {
            if isFiring {
                beam.alpha = 1
            }
            return
        }

        if isFiring {
            beam.alpha = 0
            let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.08)
            beam.run(fadeIn, withKey: "beamFadeIn")
        } else {
            let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.1)
            let hide = SKAction.run { [weak self] in
                self?.beam.isHidden = true
            }
            beam.run(SKAction.sequence([fadeOut, hide]), withKey: "beamFadeOut")
        }
    }

    private static func createRoundedBeamTexture(size: CGSize, cornerRadius: CGFloat, color: SKColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            color.setFill()
            path.fill()
        }
        return SKTexture(image: image)
    }
}
