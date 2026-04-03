import Cocoa
import SpriteKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!

    private var showDebugLabels: Bool = ProcessInfo.processInfo.environment["SHOW_DEBUG_LABELS"] == "1"

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let view = skView else { return }

        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill

        view.presentScene(scene)
        view.ignoresSiblingOrder = true

        if showDebugLabels {
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = true
        }
    }
}
