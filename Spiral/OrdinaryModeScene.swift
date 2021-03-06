//
//  OrdinaryModeScene.swift
//  Spiral
//
//  Created by 杨萧玉 on 15/5/3.
//  Copyright (c) 2015年 杨萧玉. All rights reserved.
//

import SpriteKit

class OrdinaryModeScene: GameScene {
    
    let map:OrdinaryMap
    let display:OrdinaryDisplay
    
    let background:Background
    var nextShapeName = "Killer"
    let nextShape = SKSpriteNode(imageNamed: "killer")
    let eye = Eye()
    
    override init(size:CGSize){
        GameKitHelper.sharedGameKitHelper.authenticateLocalPlayer()
        Data.sharedData.currentMode = .Ordinary
        let center = CGPointMake(size.width/2, size.height/2)
        map = OrdinaryMap(origin:center, layer: 5, size:size)
        
        display = OrdinaryDisplay()
        Data.sharedData.display = display
        background = Background(size: size)
        background.position = center
        nextShape.size = CGSize(width: 50, height: 50)
        nextShape.position = self.map.points[0]
        nextShape.physicsBody = nil
        nextShape.alpha = 0.4
        nextShape.zPosition = 100
        eye.zPosition = 100
        eye.position = map.points.last! as CGPoint
        super.init(size:size)
        player.position = map.points[player.lineNum]
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        addChild(background)
        addChild(map)
        addChild(player)
        addChild(display)
        addChild(nextShape)
        addChild(eye)
        eye.lookAtNode(player)
        display.setPosition()
        player.runInOrdinaryMap(map)
        nodeFactory()
        
        resume()
        
        //Observe Notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameControlProtocol.pause), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameControlProtocol.pause), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameControlProtocol.pause), name: WantGamePauseNotification, object: nil)
        
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
    }
    
    //MARK: UI control methods
    
    override func tap(){
        super.tap()
        if Data.sharedData.gameOver {
            //                restartGame()
        }
        else if view?.paused == true{
            resume()
        }
        else if player.lineNum>3{
            calNewLocationOfShape(player)
            player.runInOrdinaryMap(map)
            soundManager.playJump()
        }
    }
    
    override func allShapesJumpIn(){
        super.allShapesJumpIn()
        if !Data.sharedData.gameOver && view?.paused == false {
            for node in children {
                if let shape = node as? Shape {
                    if shape.lineNum>3 {
                        calNewLocationOfShape(shape)
                        shape.runInOrdinaryMap(map)
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
                let shape = Reaper()
                Data.sharedData.reaperNum -= 1
                shape.lineNum = 0
                shape.position = self.map.points[shape.lineNum]
                shape.runInOrdinaryMap(map)
                self.addChild(shape)
            }
        }
    }
    
    func speedUp(){
        for node in children{
            if let shape = node as? Shape {
                shape.removeAllActions()
                shape.moveSpeed += Data.sharedData.speedScale * shape.speedUpBase
                shape.runInOrdinaryMap(map)
            }
        }
    }
    
    func hideGame(){
        map.alpha = 0.2
        eye.alpha = 0.2
        background.alpha = 0.2
        for node in children{
            if let shape = node as? Shape {
                shape.alpha = 0.2
            }
        }
//        soundManager.stopBackGround()
        soundManager.pauseBackGround()
    }
    
    func showGame(){
        map.alpha = 1
        eye.alpha = 1
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
        eye.alpha = 1
        if eye.parent == nil {
            addChild(eye)
        }
        background.alpha = 0.5
        Data.sharedData.reset()
        player.restart()
        player.position = map.points[player.lineNum]
        nodeFactory()
        player.runInOrdinaryMap(map)
        soundManager.playBackGround()
    }
    
    //MARK: help methods
    
    func calNewLocationOfShape(shape:Shape){
        if shape.lineNum <= 3 {
            return
        }

        let scale = CGFloat((shape.lineNum/4-1)*2+1)/CGFloat(shape.lineNum/4*2+1)
        let newDistance = shape.calDistanceInOrdinaryMap(map)*scale
        shape.lineNum-=4
        shape.removeAllActions()
        let nextPoint = map.points[shape.lineNum+1]
        switch shape.lineNum%4{
        case 0:
            shape.position = CGPointMake(nextPoint.x, nextPoint.y+newDistance)
        case 1:
            shape.position = CGPointMake(nextPoint.x+newDistance, nextPoint.y)
        case 2:
            shape.position = CGPointMake(nextPoint.x, nextPoint.y-newDistance)
        case 3:
            shape.position = CGPointMake(nextPoint.x-newDistance, nextPoint.y)
        default:
            print("Why?", terminator: "")
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
                shape.position = self.map.points[shape.lineNum]
                shape.runInOrdinaryMap(self.map)
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
