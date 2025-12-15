//
//  GameViewController.swift
//  FirstFlight
//
//  Created by Yurii Voievodin on 25/09/2025.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    private weak var gameScene: GameScene?

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let view = self.view as? SKView else { return }
        
        let scene = GameScene(size: view.bounds.size)
        
        // Set the scale mode to resize to fill (no scaling, 1:1 mapping)
        scene.scaleMode = .resizeFill
        
        self.gameScene = scene
        
        // Present the scene
        view.presentScene(scene)
        
        view.ignoresSiblingOrder = true
        
        view.showsFPS = true
        view.showsNodeCount = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
