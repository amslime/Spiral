//
//  ZenModeScene.swift
//  Spiral
//
//  Created by 杨萧玉 on 15/5/1.
//  Copyright (c) 2015年 杨萧玉. All rights reserved.
//

import SpriteKit

class ZenModeScene: GameScene {
    let map:ZenMap
    let display:ZenDisplay
    let background:Background
    var nextShapeName = "Killer"
    let nextShape: SKSpriteNode
    let eyes = [Eye(), Eye(), Eye(), Eye()]
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override init(size:CGSize){
        GameKitHelper.sharedGameKitHelper.authenticateLocalPlayer()
        Data.sharedData.currentMode = .Zen
        let center = CGPointMake(size.width/2, size.height/2)
        map = ZenMap(origin:center, layer: 5, size:size)
        
        display = ZenDisplay()
        Data.sharedData.display = display
        background = Background(size: size)
        background.position = center
        nextShape = SKSpriteNode(imageNamed: "killer")
        nextShape.size = CGSize(width: 50, height: 50)
        nextShape.position = map.points[.right]![0]
        nextShape.physicsBody = nil
        nextShape.alpha = 0.4
        nextShape.zPosition = 100
        super.init(size:size)
        player.position = map.points[player.pathOrientation]![player.lineNum]
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        addChild(background)
        addChild(map)
        addChild(player)
        addChild(display)
        addChild(nextShape)
        for (i,eye) in eyes.enumerate() {
            eye.zPosition = 100
            eye.position = map.points[PathOrientation(rawValue: i)!]!.last!
            addChild(eye)
            eye.lookAtNode(player)
        }
        display.setPosition()
        player.runInZenMap(map)
        nodeFactory()
        
        resume()
        
        //Observe Notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameControlProtocol.pause), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameControlProtocol.pause), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameControlProtocol.pause), name: WantGamePauseNotification, object: nil)
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
        soundManager.stopBackGround()
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        
        
    }
    
    //MARK: - UI control methods
    
    override func tap(){
        super.tap()
        if Data.sharedData.gameOver {
            //                restartGame()
        }
        else if view?.paused == true{
            resume()
        }
        else if player.lineNum>0{
            calNewLocationOfShape(player)
            player.runInZenMap(map)
            soundManager.playJump()
        }
    }
    
    override func allShapesJumpIn(){
        super.allShapesJumpIn()
        if !Data.sharedData.gameOver && view?.paused == false {
            for node in children {
                if let shape = node as? Shape {
                    if shape.lineNum>0 {
                        calNewLocationOfShape(shape)
                        shape.runInZenMap(map)
                    }
                }
            }
            soundManager.playJump()
        }
    }
    
    override func createReaper(){
        super.createReaper()
        if !Data.sharedData.gameOver && view?.paused == false {
            if Data.sharedData.reaperNum>0 {
                Data.sharedData.reaperNum -= 1
                for pathNum in 0...3 {
                    let shape = Reaper()
                    shape.lineNum = 0
                    shape.pathOrientation = PathOrientation(rawValue: pathNum)!
                    shape.position = self.map.points[shape.pathOrientation]![shape.lineNum]
                    shape.runInZenMap(map)
                    self.addChild(shape)
                }
            }
        }
    }
    
    func speedUp(){
        for node in children{
            if let shape = node as? Shape {
                shape.removeAllActions()
                shape.moveSpeed += Data.sharedData.speedScale * shape.speedUpBase
                shape.runInZenMap(map)
            }
        }
    }
    
    func hideGame(){
        map.alpha = 0.2
        for eye in eyes {
            eye.alpha = 0.2
        }
        background.alpha = 0.2
        for node in children{
            if let shape = node as? Shape {
                shape.alpha = 0.2
            }
        }
        soundManager.pauseBackGround()
    }
    
    func showGame(){
        map.alpha = 1
        for eye in eyes {
            eye.alpha = 1
        }
        background.alpha = 0.5
        for node in children{
            if let shape = node as? Shape {
                shape.alpha = 1
            }
        }
        soundManager.resumeBackGround()
    }
    
    func restartGame(){
        enumerateChildNodesWithName("Killer", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        enumerateChildNodesWithName("Score", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        enumerateChildNodesWithName("Shield", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        enumerateChildNodesWithName("Reaper", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        map.alpha = 1
        for eye in eyes {
            eye.alpha = 1
            if eye.parent == nil {
                addChild(eye)
            }
        }
        background.alpha = 0.5
        Data.sharedData.reset()
        player.restart()
        player.position = map.points[player.pathOrientation]![player.lineNum]
        nodeFactory()
        player.runInZenMap(map)
        soundManager.playBackGround()
    }
    
    //MARK: help methods
    
    func calNewLocationOfShape(shape:Shape){
        if shape.lineNum == 0 {
            return
        }

        let scale = CGFloat(shape.lineNum-1)/CGFloat(shape.lineNum)
        let newDistance = shape.calDistanceInZenMap(map)*scale
        shape.lineNum -= 1
        shape.pathOrientation = PathOrientation(rawValue: (shape.pathOrientation.rawValue + 1)%4)!
        shape.removeAllActions()
        let nextPoint = map.points[shape.pathOrientation]![shape.lineNum+1]
        switch (shape.lineNum + shape.pathOrientation.rawValue)%4{
        case 0:
            //go right
            shape.position = CGPointMake(nextPoint.x-newDistance, nextPoint.y)
        case 1:
            //go down
            shape.position = CGPointMake(nextPoint.x, nextPoint.y+newDistance)
        case 2:
            //go left
            shape.position = CGPointMake(nextPoint.x+newDistance, nextPoint.y)
        case 3:
            //go up
            shape.position = CGPointMake(nextPoint.x, nextPoint.y-newDistance)
        default:
            print("Why?", terminator: "")
        }
        if shape.lineNum == 0 {
            shape.lineNum += 1
        }
    }
    
    func nodeFactory(){
        let createNextShape = SKAction.runBlock({
            if !Data.sharedData.gameOver {
                
                let type = arc4random_uniform(4)
                switch type {
                case 0,1:
                    self.nextShapeName = "Killer"
                    self.nextShape.texture = SKTexture(imageNamed: "killer")
                case 2:
                    self.nextShapeName = "Score"
                    self.nextShape.texture = SKTexture(imageNamed: "score")
                case 3:
                    self.nextShapeName = "Shield"
                    self.nextShape.texture = SKTexture(imageNamed: "shield")
                default:
                    self.nextShapeName = "Killer"
                    self.nextShape.texture = SKTexture(imageNamed: "killer")
                    print(type, terminator: "")
                }
                self.nextShape.setScale(1)
            }
        })
        let scale = SKAction.scaleTo(0.4, duration: 5)
        let run = SKAction.runBlock({ () -> Void in
            if !Data.sharedData.gameOver {
                var shape:Shape
                switch self.nextShapeName {
                case "Killer":
                    shape = Killer()
                case "Score":
                    shape = Score()
                case "Shield":
                    shape = Shield()
                default:
                    print(self.nextShapeName, terminator: "")
                    shape = Killer()
                }
                shape.lineNum = 0
                shape.position = self.map.points[shape.pathOrientation]![shape.lineNum]
                shape.runInZenMap(self.map)
                self.addChild(shape)
            }
        })
        let sequenceAction = SKAction.sequence([createNextShape, scale, run])
        let repeatAction = SKAction.repeatActionForever(sequenceAction)
        nextShape.runAction(repeatAction)
    }
    
    //MARK: lifecycle callback
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
    }
    
    override func didSimulatePhysics() {

    }
    
    //MARK: pause&resume game
    
    override func pause() {
        super.pause()
        if !Data.sharedData.gameOver {
            self.runAction(SKAction.runBlock({ [unowned self]() -> Void in
                self.display.pause()
                }), completion: { [unowned self]() -> Void in
                    self.view?.paused = true
                })
        }
    }
    
    override func resume() {
        display.resume()
        view?.paused = false
    }
}
