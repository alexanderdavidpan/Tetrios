//
//  GameViewController.swift
//  Tetrios
//
//  Created by Alexander Pan on 7/16/17.
//  Copyright (c) 2017 Alex Pan. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, TetriosDelegate, UIGestureRecognizerDelegate {
    
    var scene: GameScene!
    var tetrios:Tetrios!
    var panPointReference:CGPoint?
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
        
        tetrios = Tetrios()
        tetrios.delegate = self
        tetrios.beginGame()

        // Present the scene.
        skView.presentScene(scene)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func didTick() {
        tetrios.letShapeFall()
    }
    
    @IBAction func didTick(sender: UITapGestureRecognizer) {
        tetrios.rotateShape()
    }
    
    func nextShape() {
        let newShapes = tetrios.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
        self.scene.movePreviewShape(fallingShape) {
            self.view.userInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    func gameDidBegin(tetrios: Tetrios) {
        levelLabel.text = "\(tetrios.level)"
        scoreLabel.text = "\(tetrios.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if tetrios.nextShape != nil && tetrios.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(tetrios.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(tetrios: Tetrios) {
        view.userInteractionEnabled = false
        scene.stopTicking()
        scene.playSound("Sounds/gameover.mp3")
        scene.animateCollapsingLines(tetrios.removeAllBlocks(), fallenBlocks: tetrios.removeAllBlocks()) {
            tetrios.beginGame()
        }
    }
    
    func gameDidLevelUp(tetrios: Tetrios) {
        levelLabel.text = "\(tetrios.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("Sounds/levelup.mp3")
    }
    
    func gameShapeDidDrop(tetrios: Tetrios) {
        scene.stopTicking()
        scene.redrawShape(tetrios.fallingShape!) {
            tetrios.letShapeFall()
        }
        scene.playSound("Sounds/drop.mp3")
    }
    
    func gameShapeDidLand(tetrios: Tetrios) {
        scene.stopTicking()
        self.view.userInteractionEnabled = false
        
        let removedLines = tetrios.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(tetrios.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                self.gameShapeDidLand(tetrios)
            }
            scene.playSound("Sounds/bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(tetrios: Tetrios) {
        scene.redrawShape(tetrios.fallingShape!) {}
    }
    
    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translationInView(self.view)
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocityInView(self.view).x > CGFloat(0) {
                    tetrios.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    tetrios.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .Began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer) {
        tetrios.dropShape()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
    
}
