//
//  FirstFlightTests.swift
//  FirstFlightTests
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import Foundation
import SpriteKit
import Testing
@testable import FirstFlight

struct FirstFlightTests {

    @Test @MainActor func joystickInputSetsPlayerVelocity() {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)

        scene.setJoystickDirectionForTesting(CGVector(dx: 1, dy: 0))
        scene.update(1.0)

        let velocity = scene.playerForTesting.physicsBody?.velocity ?? .zero
        #expect(hypot(velocity.dx, velocity.dy) > 0.1)
    }

    @Test @MainActor func cameraFollowsPlayer() {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)

        let initialCamera = scene.cameraPositionForTesting
        scene.setPlayerPositionForTesting(CGPoint(x: initialCamera.x + 200, y: initialCamera.y + 120))
        scene.update(1.0)

        let updatedCamera = scene.cameraPositionForTesting
        #expect(hypot(updatedCamera.x - initialCamera.x, updatedCamera.y - initialCamera.y) > 0.1)
    }
}
