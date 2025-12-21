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

    @Test @MainActor func playerFiringTogglesBeamVisibility() {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 512, height: 384))
        let scene = SKScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)

        let player = Player()
        player.position = CGPoint(x: 100, y: 100)
        scene.addChild(player)

        player.startFiringBlaster(at: 0, distance: 120)
        #expect(player.isFiring)

        let beamDeadline = Date().addingTimeInterval(0.3)
        var beamVisible = false

        while Date() < beamDeadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            if player.isBeamVisibleForTesting {
                beamVisible = true
                break
            }
        }

        #expect(beamVisible)

        player.stopFiringBlaster()
        #expect(player.isFiring == false)
        #expect(player.isBeamVisibleForTesting == false)
    }

    @Test @MainActor func tapNearestRockDamagesAndDestroysIt() {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        defer { scene.stopFiringForTesting() }

        let rocks = scene.targetableRocksForTesting
        #expect(!rocks.isEmpty)

        guard let nearest = nearestRock(to: scene.playerForTesting.position, in: rocks) else {
            return
        }

        let initialStrength = nearest.currentStrength
        scene.handleTapForTesting(at: nearest.centerPosition)
        #expect(scene.playerForTesting.isFiring)
        #expect(scene.currentTargetForTesting === nearest)

        let beamDeadline = Date().addingTimeInterval(0.5)
        var beamVisible = false

        while Date() < beamDeadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            if scene.playerForTesting.isBeamVisibleForTesting {
                beamVisible = true
                break
            }
        }

        #expect(beamVisible)

        let damageDeadline = Date().addingTimeInterval(1.0)
        var damaged = false

        while Date() < damageDeadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            if nearest.currentStrength < initialStrength {
                damaged = true
                break
            }
        }

        #expect(damaged)

        let maxTime = TimeInterval((initialStrength / 100.0) + 1.0)
        let destructionDeadline = Date().addingTimeInterval(maxTime)
        var destroyed = false

        while Date() < destructionDeadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            if !scene.targetableRocksForTesting.contains(where: { $0 === nearest }) {
                destroyed = true
                break
            }
        }

        #expect(destroyed)
        #expect(scene.playerForTesting.isFiring == false)
    }

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

private func nearestRock(to position: CGPoint, in rocks: [RockFormation]) -> RockFormation? {
    guard let first = rocks.first else { return nil }
    var nearest = first
    var nearestDistance = hypot(nearest.centerPosition.x - position.x, nearest.centerPosition.y - position.y)

    for rock in rocks.dropFirst() {
        let distance = hypot(rock.centerPosition.x - position.x, rock.centerPosition.y - position.y)
        if distance < nearestDistance {
            nearestDistance = distance
            nearest = rock
        }
    }

    return nearest
}
