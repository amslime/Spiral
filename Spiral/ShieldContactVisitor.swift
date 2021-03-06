//
//  ShieldContactVisitor.swift
//  Spiral
//
//  Created by 杨萧玉 on 14-7-16.
//  Copyright (c) 2014年 杨萧玉. All rights reserved.
//

import SpriteKit

class ShieldContactVisitor: ContactVisitor {
    func visitPlayer(body:SKPhysicsBody){
        if let thisNode = self.body.node as? Shield {
            guard Data.sharedData.currentMode == .Maze else {
                thisNode.removeFromParent()
                return
            }
        }
    }
    
    func visitKiller(body:SKPhysicsBody){
        let thisNode = self.body.node
//        let otherNode = body.node
        thisNode?.removeFromParent()
    }
    
    func visitScore(body:SKPhysicsBody){
        let thisNode = self.body.node
//        let otherNode = body.node
        thisNode?.removeFromParent()
    }
    
    func visitShield(body:SKPhysicsBody){
        let thisNode = self.body.node
//        let otherNode = body.node
        thisNode?.removeFromParent()
    }
    
    func visitReaper(body:SKPhysicsBody){
        if let thisNode = self.body.node as? Shield {
            guard Data.sharedData.currentMode == .Maze else {
                thisNode.removeFromParent()
                return
            }
        }
    }
}
