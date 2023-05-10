//
//  Fuel.swift
//  DriveFast
//
//  Created by Ly Truong H. VN.Danang on 09/05/2023.
//

import Foundation
import SpriteKit

// MARK: - Fuel

final class Fuel: SKSpriteNode {
          
    // MARK: - Constructor
    
    convenience init(frame: CGRect) {
        let texture = SKTexture(imageNamed: Asset.fuel.rawValue)
        self.init(texture: texture)
        self.size = CGSize(width: 10, height: 10)
        self.position = CGPoint(x: 0, y: frame.size.height + self.size.height)
        self.zPosition = 0
        
        let ratio = UIDevice.current.isPad ? frame.width / 3 : frame.width / 1.5
        self.setScale(to: ratio)
        
        let physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = Category.fuel.rawValue
        physicsBody.contactTestBitMask = (Category.player.rawValue | Category.coin.rawValue | Category.car.rawValue)
        physicsBody.collisionBitMask = 0
        self.physicsBody = physicsBody
    }
}
