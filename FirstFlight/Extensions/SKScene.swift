import SpriteKit

extension SKScene {
    func spawnDebrisParticle(at position: CGPoint, texture: SKTexture) {
        let size = CGFloat.random(in: 4...8)
        let particle = SKSpriteNode(texture: texture, size: CGSize(width: size, height: size))
        particle.color = SKColor(white: 0.7, alpha: 1.0)
        particle.colorBlendFactor = 0.35
        particle.position = position
        particle.zPosition = 50
        addChild(particle)

        // Random velocity outward with gravity effect
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let speed = CGFloat.random(in: 30...60)
        let dx = cos(angle) * speed
        let dy = sin(angle) * speed

        let move = SKAction.move(by: CGVector(dx: dx, dy: dy - 40), duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        let group = SKAction.group([move, fade])
        let remove = SKAction.removeFromParent()
        particle.run(SKAction.sequence([group, remove]))
    }
}
