import SpriteKit

final class CombatManager {
    private weak var scene: GameScene?
    private weak var player: Player?
    private weak var energyBar: EnergyBar?

    // Beam damage
    var rocksBeingDamaged: Set<RockFormation> = []
    private let beamDamagePerSecond: CGFloat = 25
    private let energyDrainPerSecond: CGFloat = 5.0

    // Particle effects
    private var particleSpawnTimer: TimeInterval = 0
    private let particleSpawnInterval: TimeInterval = 0.04

    // Element extraction
    private var extractionProgress: [RockFormation: CGFloat] = [:]
    private let damagePerElement: CGFloat = 10

    // Targeting
    private(set) var currentTarget: RockFormation?
    #if os(iOS)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    #endif
    private var hapticAccumulator: TimeInterval = 0
    private let hapticInterval: TimeInterval = 0.1

    var onRockDestroyed: ((RockFormation) -> Void)?

    init(scene: GameScene, player: Player, energyBar: EnergyBar) {
        self.scene = scene
        self.player = player
        self.energyBar = energyBar
    }

    // MARK: - Targeting

    func startFiring(at rock: RockFormation) {
        guard let player, let scene else { return }
        guard player.currentEnergy > 0 else { return }

        currentTarget = rock
        hapticAccumulator = 0
        #if os(iOS)
        impactFeedback.prepare()
        #endif

        let endPoint = beamEndPoint(towards: rock, from: player, in: scene)
        let dx = endPoint.x - player.position.x
        let dy = endPoint.y - player.position.y
        let angle = atan2(dy, dx)
        let distance = hypot(dx, dy)

        player.startFiringBlaster(at: angle, distance: distance)
    }

    func stopFiring() {
        currentTarget = nil
        hapticAccumulator = 0
        rocksBeingDamaged.removeAll()
        player?.stopFiringBlaster()
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        guard let player, let scene, let energyBar else { return }
        guard deltaTime > 0, !rocksBeingDamaged.isEmpty else { return }

        // Clear target if destroyed
        if let target = currentTarget, target.parent == nil {
            stopFiring()
            return
        }

        // Haptic feedback
        #if os(iOS)
        hapticAccumulator += deltaTime
        while hapticAccumulator >= hapticInterval {
            hapticAccumulator -= hapticInterval
            impactFeedback.impactOccurred()
        }
        #endif

        // Drain energy
        let energyDrain = energyDrainPerSecond * CGFloat(deltaTime)
        player.spendEnergy(energyDrain)
        energyBar.update(currentEnergy: player.currentEnergy, maxEnergy: player.maxEnergy)

        if player.currentEnergy <= 0 {
            stopFiring()
            return
        }

        // Apply damage & extract elements
        let damage = beamDamagePerSecond * CGFloat(deltaTime)
        var rocksToDestroy: [RockFormation] = []

        for rock in rocksBeingDamaged {
            if rock.applyDamage(damage) {
                rocksToDestroy.append(rock)
            }

            extractionProgress[rock, default: 0] += damage
            while extractionProgress[rock, default: 0] >= damagePerElement {
                extractionProgress[rock, default: 0] -= damagePerElement
                if let element = rock.extractRandomElement() {
                    let added = player.inventory.add(element, amount: 1)
                    if added > 0 {
                        ElementPopup.spawn(element: element, amount: added, at: rock.centerPosition, in: scene)
                    }
                }
            }
        }

        for rock in rocksToDestroy {
            rocksBeingDamaged.remove(rock)
            extractionProgress.removeValue(forKey: rock)
            onRockDestroyed?(rock)
        }

        // Spawn impact particles
        particleSpawnTimer += deltaTime
        if particleSpawnTimer >= particleSpawnInterval {
            particleSpawnTimer = 0
            for _ in rocksBeingDamaged {
                player.spawnBeamDebris(in: scene, count: Int.random(in: 2...3))
            }
        }
    }

    // MARK: - Beam Geometry

    private func beamEndPoint(towards rock: RockFormation, from player: Player, in scene: GameScene, inset: CGFloat = 4) -> CGPoint {
        let start = player.position
        let rockFrame = rock.calculateAccumulatedFrame()
        let targetPosition = CGPoint(x: rockFrame.midX, y: rockFrame.midY)

        let dx = targetPosition.x - start.x
        let dy = targetPosition.y - start.y
        let angle = atan2(dy, dx)
        let direction = CGVector(dx: cos(angle), dy: sin(angle))

        let farDistance = hypot(dx, dy) + max(rockFrame.width, rockFrame.height) * 4
        let rayEnd = CGPoint(
            x: start.x + direction.dx * farDistance,
            y: start.y + direction.dy * farDistance
        )

        var hitPoint: CGPoint?
        scene.physicsWorld.enumerateBodies(alongRayStart: start, end: rayEnd) { body, point, _, stop in
            if body == rock.physicsBody {
                hitPoint = point
                stop.pointee = true
            }
        }

        if let hitPoint {
            return CGPoint(
                x: hitPoint.x - direction.dx * inset,
                y: hitPoint.y - direction.dy * inset
            )
        }

        let distanceToCenter = hypot(dx, dy)
        let radius = max(rockFrame.width, rockFrame.height) * 0.5
        let distanceToEdge = max(0, distanceToCenter - radius)

        return CGPoint(
            x: start.x + direction.dx * distanceToEdge,
            y: start.y + direction.dy * distanceToEdge
        )
    }
}
