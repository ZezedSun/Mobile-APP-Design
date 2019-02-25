//
//  GameScene.swift
//  Game1
//
//  Created by SYY on 2018/9/27.
//  Copyright © 2018 Mingze Sun. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate{
    let motion = CMMotionManager()
    func startMotionUpdates(){
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.1
            self.motion.startDeviceMotionUpdates(to:
                OperationQueue.main, withHandler:self.handleMotion)
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?,error:Error?){
        if let gravity = motionData?.gravity {
            self.physicsWorld.gravity = CGVector(dx: CGFloat(9.8*gravity.x), dy: CGFloat(9.8*gravity.y))
        }
    }
    
    
    
    let spinBlock = SKSpriteNode()
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    var score:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor.white
        
        // start motion for gravity
        self.startMotionUpdates()
        
        // make sides to the screen
        self.addSidesAndTop()
        
        // self.addStaticBlockAtPoint(CGPoint(x:size.width * 0.1, y: size.height * 0.25))
        //self.addStaticBlockAtPoint(CGPoint(x:size.width * 0.1, y: size.height * 0.25))
        
        // add a spinning block
        self.addBlockAtPoint(CGPoint(x: size.width * 0.5, y: size.height * 0.35))
        self.addSprite()
        
        self.addScore()
        
        self.score = 0
        
    }
    
    func addScore(){
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.blue
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.minY)
        
        addChild(scoreLabel)
    }
    
    func addSprite(){
        let spriteA = SKSpriteNode(imageNamed: "sprite")
        spriteA.size = CGSize(width: size.width * 0.1, height: size.height * 0.05)
        spriteA.position = CGPoint(x: size.width * 0.5, y: size.height * 0.8)
        
        spriteA.physicsBody = SKPhysicsBody(rectangleOf:  spriteA.size)
        spriteA.physicsBody?.restitution = 1
        spriteA.physicsBody?.isDynamic = true
        spriteA.physicsBody?.contactTestBitMask = 0x00000001
        spriteA.physicsBody?.collisionBitMask = 0x00000001
        spriteA.physicsBody?.categoryBitMask = 0x00000001
        //spriteA.physicsBody?.affectedByGravity=true
        self.addChild(spriteA)
    }
    
    func addBlockAtPoint(_ point:CGPoint){
        spinBlock.color = UIColor.blue
        //Mark incentivize
        let currency = CGFloat(UserDefaults.standard.float(forKey: "dailyStepGoal")/1000)
        spinBlock.size = CGSize(width:size.width*0.15*currency,height:size.height * 0.05)
        spinBlock.position = point
        let yConstraint = SKConstraint.positionY(SKRange(constantValue:size.height * 0.3))
        spinBlock.constraints = [yConstraint]
        //spinBlock.position.x = position.x
        //spinBlock.position.y = size.height * 0.3
        spinBlock.physicsBody = SKPhysicsBody(rectangleOf:spinBlock.size)
        spinBlock.physicsBody?.contactTestBitMask = 0x00000000
        spinBlock.physicsBody?.collisionBitMask = 0x00000001
        spinBlock.physicsBody?.categoryBitMask = 0x00000001
        spinBlock.physicsBody?.isDynamic = false
        //spinBlock.physicsBody?.pinned = true
        spinBlock.physicsBody?.allowsRotation = false
        //spinBlock.physicsBody?.velocity = CGVector(dx: 0, dy: 1)
        self.addChild(spinBlock)
        
    }
    
    /*func addStaticBlockAtPoint(_ point:CGPoint){
     let 🔲 = SKSpriteNode()
     
     🔲.color = UIColor.red
     🔲.size = CGSize(width:size.width*0.1,height:size.height * 0.05)
     🔲.position = point
     let yConstraint = SKConstraint.positionY(SKRange(constantValue:size.height * 0.3))
     🔲.constraints = [yConstraint]
     
     🔲.physicsBody = SKPhysicsBody(rectangleOf:🔲.size)
     🔲.physicsBody?.isDynamic = true
     🔲.physicsBody?.pinned = false
     🔲.physicsBody?.allowsRotation = false
     
     self.addChild(🔲)
     
     }*/
    
    
    func addSidesAndTop(){
        let left = SKSpriteNode()
        let right = SKSpriteNode()
        let top = SKSpriteNode()
        
        left.size = CGSize(width:size.width*0.1,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        
        right.size = CGSize(width:size.width*0.1,height:size.height)
        right.position = CGPoint(x:size.width, y:size.height*0.5)
        
        top.size = CGSize(width:size.width,height:size.height*0.1)
        top.position = CGPoint(x:size.width*0.5, y:size.height)
        
        for obj in [left,right,top]{
            obj.color = UIColor.red
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = false
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            self.addChild(obj)
        }
    }
    
    // MARK: =====Delegate Functions=====
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.addSprite()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        var touchedLocation = CGPoint()
        for touch in touches{
            touchedLocation = touch.location(in: self)
            spinBlock.position.x = touchedLocation.x
            spinBlock.position.y = size.height*0.3
        }
    }
    
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node == spinBlock || contact.bodyB.node == spinBlock {
            self.score += 1
        }
    }
    
}


