import SpriteKit

extension SKScene {
    func spawnDebrisParticle(at position: CGPoint) {
        // Tiny dark fragments (no textures)
        let w = CGFloat.random(in: 2...4)
        let h = CGFloat.random(in: 2...5)

        // SKSpriteNode with color is cheaper than textured sprites and avoids texture sampling
        let particle = SKSpriteNode(color: SKColor(white: 0.35, alpha: 1.0), size: CGSize(width: w, height: h))
        particle.position = position
        particle.zPosition = 50
        particle.zRotation = CGFloat.random(in: 0..<(2 * .pi))
        particle.alpha = CGFloat.random(in: 0.75...1.0)
        addChild(particle)

        // Random velocity outward (slight upward bias) + gravity-ish pull
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let speed = CGFloat.random(in: 55...120)
        let dx = cos(angle) * speed
        var dy = sin(angle) * speed
        dy = max(dy, 10) // keep some pop so fragments don't look "stuck" to the rock

        let duration: TimeInterval = 0.35

        let move = SKAction.move(by: CGVector(dx: dx, dy: dy - 45), duration: duration)
        let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3.0...3.0), duration: duration)
        let fade = SKAction.fadeOut(withDuration: duration)
        let shrink = SKAction.scale(to: CGFloat.random(in: 0.35...0.7), duration: duration)

        let group = SKAction.group([move, rotate, fade, shrink])
        particle.run(.sequence([group, .removeFromParent()]))
    }
}
