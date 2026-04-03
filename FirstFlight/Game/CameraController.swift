import SpriteKit

final class CameraController {
    private let camera: SKCameraNode
    private weak var scene: SKScene?
    private var mapSize: CGSize = .zero
    private let lerpFactor: CGFloat = 0.1

    init(camera: SKCameraNode, scene: SKScene) {
        self.camera = camera
        self.scene = scene
    }

    func setMapSize(_ size: CGSize) {
        mapSize = size
    }

    func follow(_ target: SKNode) {
        let currentX = camera.position.x
        let currentY = camera.position.y
        let newX = currentX + (target.position.x - currentX) * lerpFactor
        let newY = currentY + (target.position.y - currentY) * lerpFactor
        camera.position = CGPoint(x: newX, y: newY)
    }

    func updateConstraints() {
        guard let view = scene?.view, mapSize != .zero else { return }

        let viewportWidth = view.bounds.width
        let viewportHeight = view.bounds.height

        let xRange = SKRange(lowerLimit: viewportWidth / 2, upperLimit: mapSize.width - viewportWidth / 2)
        let yRange = SKRange(lowerLimit: viewportHeight / 2, upperLimit: mapSize.height - viewportHeight / 2)

        let edgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        edgeConstraint.referenceNode = scene

        camera.constraints = [edgeConstraint]
    }

    func applyJitter(intensity: CGFloat = 0.5) {
        camera.position.x += CGFloat.random(in: -intensity...intensity)
        camera.position.y += CGFloat.random(in: -intensity...intensity)
    }

    func shake(intensity: CGFloat = 2, duration: TimeInterval = 0.15) {
        let camShake = SKAction.customAction(withDuration: duration) { [weak self] _, t in
            guard let cam = self?.camera else { return }
            let k = 1.0 - (t / CGFloat(duration))
            cam.position.x += CGFloat.random(in: -intensity...intensity) * k
            cam.position.y += CGFloat.random(in: -intensity...intensity) * k
        }
        camera.run(camShake)
    }
}
