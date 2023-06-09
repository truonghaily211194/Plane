//
//  Coin.swift
//  DriveFast
//
//  Created by Ly Truong H. VN.Danang on 09/05/2023.
//

import SpriteKit

// MARK: - Coin

final class Coin: SKSpriteNode {
    
    // MARK: - CoinType
    
    enum CoinType: String {
        case single = "single_coin"
        case multiple = "multiple_coins"
        case bag = "coin_bag"
    }
    
    // MARK: - Properties
    
    static var waitForDuration: TimeInterval {
        return 5
    }
    
    var type: CoinType!
    
    var value: Double {
        switch type {
        case .single:
            return 10
        case .multiple:
            return 25
        case .bag:
            return 50
        default:
            return 0
        }
    }
    
    convenience init(frame: CGRect, type: CoinType) {
        let texture = SKTexture(imageNamed: type.rawValue)
        self.init(texture: texture)
        
        self.type = type
        self.size = CGSize(width: 10, height: 10)
        self.position = CGPoint(x: 0, y: frame.size.height + self.size.height)
        self.zPosition = 0
        self.name = type.rawValue
        
        let ratio = UIDevice.current.isPad ? frame.width / 3 : frame.width / 1.5
        self.setScale(to: ratio)
        
        let physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = Category.coin.rawValue
        physicsBody.contactTestBitMask = Category.player.rawValue
        physicsBody.collisionBitMask = 0
        self.physicsBody = physicsBody
    }
}
