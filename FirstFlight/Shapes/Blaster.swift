import SpriteKit

final class Blaster: SKNode {
    enum Orientation {
        case up
        case down
        case left
        case right
    }

    private let grip: SKShapeNode
    private let body: SKShapeNode
    private let barrel: SKShapeNode
    private let emitter: SKShapeNode
    private let beam: SKSpriteNode

    private var orientation: Orientation = .down
    private var isFiring = false
    private var restingEmitterAlpha: CGFloat = 0.8

    override init() {
        grip = SKShapeNode(rectOf: CGSize(width: 5, height: 9), cornerRadius: 1.5)
        body = SKShapeNode(rectOf: CGSize(width: 6, height: 18), cornerRadius: 3)
        barrel = SKShapeNode(rectOf: CGSize(width: 4, height: 12), cornerRadius: 1.6)
        emitter = SKShapeNode(circleOfRadius: 2.3)
        beam = SKSpriteNode(color: SKColor.cyan.withAlphaComponent(0.55), size: CGSize(width: 6, height: 180))

        super.init()

        position = CGPoint(x: 3, y: -4)
        zPosition = 2.4

        grip.fillColor = SKColor(red: 0.19, green: 0.22, blue: 0.26, alpha: 1)
        grip.strokeColor = SKColor.black.withAlphaComponent(0.35)
        grip.lineWidth = 1
        grip.position = CGPoint(x: 0, y: -1.5)
        addChild(grip)

        body.fillColor = SKColor(red: 0.45, green: 0.52, blue: 0.6, alpha: 1)
        body.strokeColor = SKColor.black.withAlphaComponent(0.3)
        body.lineWidth = 1
        body.position = CGPoint(x: 0, y: -9)
        addChild(body)

        barrel.fillColor = SKColor(red: 0.72, green: 0.84, blue: 0.95, alpha: 0.9)
        barrel.strokeColor = SKColor.white.withAlphaComponent(0.4)
        barrel.lineWidth = 0.8
        barrel.position = CGPoint(x: 0, y: -14)
        addChild(barrel)

        emitter.fillColor = SKColor.cyan.withAlphaComponent(0.8)
        emitter.strokeColor = SKColor.white.withAlphaComponent(0.6)
        emitter.lineWidth = 0.6
        emitter.position = CGPoint(x: 0, y: -20.5)
        addChild(emitter)

        beam.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        beam.position = emitter.position
        beam.zPosition = 3.5
        beam.isHidden = true
        beam.alpha = 0
        beam.blendMode = .add
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
        zRotation = 0
        zPosition = 2.4
        position = CGPoint(x: 3, y: -4)

        body.fillColor = SKColor(red: 0.45, green: 0.52, blue: 0.6, alpha: 1)
        barrel.alpha = 0.9
        var emitterAlpha: CGFloat = 0.8

        switch orientation {
        case .up:
            zRotation = .pi
            zPosition = 2.5
            emitterAlpha = 0.85
        case .down:
            emitterAlpha = 0.9
        case .right:
            position = CGPoint(x: 5.5, y: -2.5)
            zRotation = .pi / 2
            zPosition = 2.3
            body.fillColor = SKColor(red: 0.42, green: 0.5, blue: 0.58, alpha: 1)
            emitterAlpha = 0.75
        case .left:
            position = CGPoint(x: 5.5, y: -2.5)
            zRotation = .pi / 2
            zPosition = 2.3
            body.fillColor = SKColor(red: 0.42, green: 0.5, blue: 0.58, alpha: 1)
            emitterAlpha = 0.75
        }

        restingEmitterAlpha = emitterAlpha
        emitter.alpha = isFiring ? 1 : restingEmitterAlpha

        updateBeamState()
    }

    func startBeam() {
        guard !isFiring else { return }
        isFiring = true
        emitter.alpha = 1
        updateBeamState(animated: true)
    }

    func stopBeam() {
        guard isFiring else { return }
        isFiring = false
        emitter.alpha = restingEmitterAlpha
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
}
