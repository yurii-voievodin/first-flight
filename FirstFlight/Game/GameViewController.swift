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

    private lazy var fireButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⚡︎", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        button.layer.cornerRadius = 32
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(fireButtonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(fireButtonTouchDown), for: .touchDragEnter)
        button.addTarget(self, action: #selector(fireButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to resize to fill (no scaling, 1:1 mapping)
                scene.scaleMode = .resizeFill

                if let typedScene = scene as? GameScene {
                    self.gameScene = typedScene
                }

                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }

        setupFireButton()
    }

    private func setupFireButton() {
        guard fireButton.superview == nil else { return }
        view.addSubview(fireButton)

        NSLayoutConstraint.activate([
            fireButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fireButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fireButton.widthAnchor.constraint(equalToConstant: 64),
            fireButton.heightAnchor.constraint(equalTo: fireButton.widthAnchor)
        ])
    }

    @objc private func fireButtonTouchDown() {
        guard fireButton.isEnabled else { return }
        gameScene?.beginBlasterBeam()
    }

    @objc private func fireButtonTouchUp() {
        gameScene?.endBlasterBeam()
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
