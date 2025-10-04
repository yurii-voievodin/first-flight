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

    private lazy var switchCharacterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapSwitchCharacter), for: .touchUpInside)
        return button
    }()

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

        setupSwitchCharacterButton()
        setupFireButton()
        updateSwitchButtonTitle()
        updateFireButtonAvailability()
    }

    @objc private func didTapSwitchCharacter() {
        gameScene?.toggleCharacterSelection()
        updateSwitchButtonTitle()
        updateFireButtonAvailability()
    }

    private func setupSwitchCharacterButton() {
        guard switchCharacterButton.superview == nil else { return }
        view.addSubview(switchCharacterButton)

        NSLayoutConstraint.activate([
            switchCharacterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            switchCharacterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            switchCharacterButton.widthAnchor.constraint(equalToConstant: 36),
            switchCharacterButton.heightAnchor.constraint(equalToConstant: 36)
        ])
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

    private func updateSwitchButtonTitle() {
        let title = gameScene?.toggleButtonTitle ?? "⇄"
        switchCharacterButton.setTitle(title, for: .normal)
    }

    private func updateFireButtonAvailability() {
        let isEnabled = gameScene?.isBlasterAvailable ?? false
        fireButton.isEnabled = isEnabled
        fireButton.alpha = isEnabled ? 1 : 0.35
        if !isEnabled {
            fireButtonTouchUp()
        }
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
