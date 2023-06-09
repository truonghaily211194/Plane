//
//  GameScene.swift
//  DriveFast
//
//  Created by Atilla Özder on 10.10.2019.
//  Copyright © 2019 Atilla Özder. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

// MARK: - SceneDelegate

protocol SceneDelegate: AnyObject {
    func scene(_ scene: GameScene, didUpdateScore score: Double)
    func scene(_ scene: GameScene, willUpdateLifeCount count: Int)
    func scene(_ scene: GameScene, didFinishGameWithScore score: Double)
    func scene(_ scene: GameScene, didUpdateGameState state: GameState)
    func scene(_ scene: GameScene, didUpdateRemainingFuel fuel: Float)
}

// MARK: - GameScene

class GameScene: SKScene {
    
    // MARK: - Properties
    
    /// safe area insets of the game view controller
    lazy var insets: UIEdgeInsets = .zero
    private var gotReward: Bool = false
    private var gameOver: Bool = false
    
    private var stayPaused = false
    var gameStarted: Bool { true }
    
    override var isPaused: Bool {
        get {
            return super.isPaused
        } set {
            if (!stayPaused) {
                super.isPaused = newValue
            }
            stayPaused = false
        }
    }
    
    private let motionManager = CMMotionManager()
    let props = GameProps()
    
    weak var sceneDelegate: SceneDelegate?
    
    private(set) lazy var playerNode: SKSpriteNode = { buildPlayerNode() }()
    private(set) lazy var roadNode: SKShapeNode = { buildRoadShapeNode() }()
    private lazy var roadLineNode: SKSpriteNode = { buildRoadLineNode() }()
    
    private lazy var singleCoin = Coin(frame: frame, type: .single)
    private lazy var multipleCoins = Coin(frame: frame, type: .multiple)
    private lazy var coinBag = Coin(frame: frame, type: .bag)
    private lazy var fuelNode = Fuel(frame: frame)

    var score: Double = 0 {
        willSet (newScore) {
            guard newScore > 0 else { return }
            let diff = abs(newScore - score)
            let divisor: Double = 100
            
            if diff >= 10 {
                // it means a coin has taken
                let division = (newScore / divisor).rounded(.down)
                if score < (divisor * division) && newScore > (divisor * division) {
                    self.updateDifficulty()
                }
            } else {
                if newScore.truncatingRemainder(dividingBy: divisor) == 0 {
                    self.updateDifficulty()
                }
            }
        } didSet {
            sceneDelegate?.scene(self, didUpdateScore: score)
        }
    }
    
    var fuel: Float = 100 {
        didSet {
            DispatchQueue.main.async {
                if self.fuel <= 0 {
                    self.gameDidFinish(forReason: .runningOutOfFuel)
                }
                self.sceneDelegate?.scene(
                    self, didUpdateRemainingFuel: self.fuel)
            }
        }
    }
    
    var lifeCount: Int = 3 {
        willSet {
            sceneDelegate?.scene(self, willUpdateLifeCount: newValue)
            if newValue == 0 {
                gameDidFinish(forReason: .crash)
            }
        }
    }
        
    private lazy var roadRect: RoadRect = {
        let w = playerNode.size.width / 2
        let h = playerNode.size.height / 2
        
        let minX = self.frame.minX + w
        let maxX = self.frame.maxX - w
        let minY = self.frame.minY + h + 10
        let maxY = self.frame.maxY - h
        
        return .init(minY: minY, minX: minX, maxY: maxY, maxX: maxX)
    }()
        
    // MARK: - Game Life Cycle
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        resetGame()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.backgroundColor = .road
        initiateGame()
        
        self.addChild(roadNode)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        if UIDevice.current.isPad {
            addFlatRoadLine()
        } else {
            DispatchQueue.main.async {
                let addRoadLineSq: SKAction = .sequence([
                    .wait(forDuration: 0.05),
                    .run(self.addRoadLine, queue: .global())
                ])
                self.run(.repeatForever(addRoadLineSq))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.initiateCarSequence()
        }
    }
        
    func resetPlayerPosition() {
        playerNode.position = .init(x: self.frame.midX, y: roadRect.minY)
    }
    
    func initiateGame() {
        GameManager.shared.gameCount += 1
        resetPlayerPosition()
        addChild(playerNode)
        
        startMotionManager()
        
        let addCoinSq: SKAction = .sequence([
            .wait(forDuration: Coin.waitForDuration),
            .run(addCoin, queue: .init(label: "\(Globals.bundleID).serialQueue.addCoin"))
        ])
        
        run(.repeatForever(addCoinSq), withKey: Globals.Keys.kAddCoin.rawValue)
        
        initiateFuelSequence()
        
        let setFuelSq: SKAction = .sequence([
            .wait(forDuration: 1),
            .run(setFuel, queue: .global())
        ])
        
        run(.repeatForever(setFuelSq))
    }
        
    fileprivate func stopGame() {
        if !gotReward {
            self.setPausedAndNotify(true)
            self.sceneDelegate?.scene(self, didUpdateGameState: .advertisement)
        } else {
            self.sceneDelegate?.scene(self, didUpdateGameState: .home)
        }
    }
        
    func gameDidFinish(forReason reason: GameOverReason) {
        self.gameOver = true
        
        switch reason {
        case .crash:
            let explosionEffect = GameManager.shared.explosionEffect
            explosionEffect.position = playerNode.position
            self.addChild(explosionEffect)
            
            props.playEffect(.crash, in: self)
            playerNode.removeFromParent()
            
            self.run(.wait(forDuration: 1)) { [weak self] in
                guard let self = self else { return }
                explosionEffect.removeFromParent()
                self.stopGame()
            }
        case .runningOutOfFuel:
            self.stopGame()
        }
        
        self.sceneDelegate?.scene(self, didFinishGameWithScore: score)
    }
        
    func didGetReward() {
        AudioPlayer.shared.playMusic()
        resetPlayerPosition()
        if playerNode.parent == nil {
            addChild(playerNode)
        }
        
        self.lifeCount = max(1, lifeCount)
        self.fuel = 100
        self.gameOver = false
        self.setPausedAndNotify(false)
    }
    
    func willPresentRewardBasedVideoAd() {
        self.gotReward = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.enumerateChildNodes(withName: Globals.Keys.kCar.rawValue) { (node, ptr) in
                node.removeFromParent()
            }
        }
    }
    
    func setStayPaused() {
        if (super.isPaused) {
            self.stayPaused = true
        }
    }
    
    func setPausedAndNotify(_ isPaused: Bool) {
        self.isPaused = isPaused
        self.didChangePauseState()
    }
    
    func didChangePauseState() {
        isPaused ? stopMotionManager() : startMotionManager()
        if let addCarSeq = self.action(forKey: Globals.Keys.kAddCar.rawValue) {
            addCarSeq.speed = isPaused ? 0 : 1
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func addFlatRoadLine() {
        var posX = self.roadNode.frame.minX
        for _ in 1..<Int(Car.scaleRatio) {
            let node = self.roadLineNode.copy() as! SKSpriteNode
            node.size.height = self.frame.height * 2
            
            posX += (frame.width / Car.scaleRatio)
            node.position = .init(x: posX, y: self.frame.maxY)
            
            DispatchQueue.main.async {
                self.addChild(node)
            }
        }
    }
    
    private func getRandomPosX() -> CGFloat {
        let roadMinX = Int(self.frame.minX + 30)
        let roadMaxX = Int(self.frame.maxX - 30)
        let randomDist = GKRandomDistribution(lowestValue: roadMinX, highestValue: roadMaxX)
        return CGFloat(randomDist.nextInt())
    }
    
    private func stopMotionManager() {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func startMotionManager() {
        stopMotionManager()
        motionManager.accelerometerUpdateInterval = 0.01
        motionManager.startAccelerometerUpdates(to: .init()) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            let player = self.playerNode
            let position = player.position
            var x = position.x + CGFloat(data.acceleration.x * 10)
            var y = position.y + CGFloat(data.acceleration.y * 10)
            
            let road = self.roadRect
            x = max(x, road.minX)
            x = min(x, road.maxX)
            y = max(y, road.minY)
            y = min(y, road.maxY)
            
            player.position = .init(x: x, y: y)
        }
    }
    
    private func initiateCarSequence() {
        self.removeAction(forKey: Globals.Keys.kAddCar.rawValue)
        let addCarQueue = DispatchQueue(
            label: "\(Globals.bundleID).concurrentQueue.addCar",
            qos: .default, attributes: .concurrent)
        
        let addCarSq: SKAction = .sequence([
            .wait(forDuration: props.carWaitForDuration),
            .run(self.addCar, queue: addCarQueue)
        ])
        
        self.run(.repeatForever(addCarSq), withKey: Globals.Keys.kAddCar.rawValue)
    }
    
    private func initiateFuelSequence() {
        self.removeAction(forKey: Globals.Keys.kAddFuel.rawValue)
        let addFuelSq: SKAction = .sequence([
            .wait(forDuration: props.fuelWaitForDuration),
            .run(addFuel, queue: .init(label: "\(Globals.bundleID).serialQueue.addFuel"))
        ])
        self.run(.repeatForever(addFuelSq), withKey: Globals.Keys.kAddFuel.rawValue)
    }
    
    private func updateDifficulty() {
        props.updateDifficulty()
        initiateCarSequence()
        initiateFuelSequence()
    }
    
    private func resetGame() {
        stopMotionManager()
        self.removeAllActions()
        self.removeAllChildren()
        resetPlayerPosition()
    }
    
    // MARK: - RepeatForever Actions
    
    private func addRoadLine() {
        let height = roadLineNode.size.height + 20
        let posY: CGFloat = self.frame.maxY + height
        
        var actions = [SKAction]()
        actions.append(.moveTo(y: -height, duration: 0.5))
        actions.append(.removeFromParent())
        
        var posX = self.roadNode.frame.minX
        for _ in 1..<Int(Car.scaleRatio) {
            guard let node = self.roadLineNode.copy() as? SKSpriteNode else { return }
            
            posX += (frame.width / Car.scaleRatio)
            node.position = .init(x: posX, y: posY)
            
            DispatchQueue.main.async {
                self.addChild(node)
                node.run(.sequence(actions))
            }
        }
    }
        
    private func addCar() {
        var prevCarFrame: CGRect = .zero
        
        let addCarClosure: () -> Void = { [weak self] in
            guard let self = self else { return }
            
            var cars = GameManager.shared.cars
            if cars.isEmpty {
                return
            }
            
            cars.shuffle()
            let randomCar = cars[0]
            let obj = GameManager.shared.getObjRepresentation(of: randomCar)
            let car = randomCar.copy() as! SKSpriteNode
            if car.physicsBody == nil {
                #if DEBUG
                // Debug mode is on, continue
                #else
                // Physics body is empty, if game is started dont add car to screen
                if self.gameStarted {
                    return
                }
                #endif
            }
            
            car.setScale(to: self.frame.width / obj.ratio)
            car.position = CGPoint(
                x: self.getRandomPosX(), y: self.frame.maxY + car.size.height)
            
            if UIDevice.current.isPad {
                if prevCarFrame.intersects(car.frame) {
                    return
                }
                prevCarFrame = car.frame
            }

            let move = SKAction.moveTo(
                y: -car.size.height / 2, duration: self.props.spriteMoveDuration)
            var actions = [SKAction]()
            actions.append(move)
            
            let increaseScore = SKAction.run { [unowned self] in
                if !self.gameOver {
                    self.score += 1
                }
            }

            actions.append(increaseScore)
            actions.append(.removeFromParent())
            
            DispatchQueue.main.async {
                car.run(.sequence(actions))
                self.addChild(car)
            }
        }
        
        addCarClosure()
        if UIDevice.current.isPad {
            addCarClosure()
        }
    }
    
    private func setFuel() {
        self.fuel = max(0, fuel - props.fuelConsumption)
    }
    
    private func addCoin() {
        let random = Int.random(in: 0...10)
        var coin: Coin
        
        if random >= 0 && random <= 5 {
            coin = self.singleCoin.copy() as! Coin
            coin.type = .single
        } else if random > 5 && random <= 8 {
            coin = self.multipleCoins.copy() as! Coin
            coin.type = .multiple
        } else {
            coin = self.coinBag.copy() as! Coin
            coin.type = .bag
        }
    
        addSprite(coin)
    }
        
    private func addFuel() {
        let sprite = self.fuelNode.copy() as! Fuel
        addSprite(sprite)
    }
    
    private func addSprite(_ sprite: SKSpriteNode) {
        sprite.position.x = getRandomPosX()
        var actions = [SKAction]()
        let move: SKAction = .moveTo(
            y: -sprite.size.height / 2, duration: props.spriteMoveDuration)
        actions.append(move)
        actions.append(.removeFromParent())
        
        DispatchQueue.main.async {
            self.addChild(sprite)
            sprite.run(.sequence(actions))
        }
    }
    
    private func buildPlayerNode() -> SKSpriteNode {
        // Todo: - đổi xe đua
        let player = UserDefaults.standard.playerCar
//        let player = Car(index: 0)
        let element = GameManager.shared.getDictElement(value: player)
        let spriteNode = element.key.copy() as! SKSpriteNode
        spriteNode.name = Globals.Keys.kPlayer.rawValue
        spriteNode.physicsBody?.categoryBitMask = Category.player.rawValue
        spriteNode.physicsBody?.contactTestBitMask = Category.car.rawValue
        spriteNode.setScale(to: self.frame.width / element.value.ratio)
        return spriteNode
    }
    
    private func buildRoadShapeNode() -> SKShapeNode {
        let size: CGSize = .init(width: frame.width, height: frame.height * 2)
        let shapeNode = SKShapeNode(rectOf: size)
        shapeNode.fillColor = .road
        shapeNode.strokeColor = .road
        shapeNode.position = .init(x: frame.midX, y: frame.minY)
        shapeNode.zPosition = -1
        return shapeNode
    }
    
    private func buildRoadLineNode() -> SKSpriteNode {
        let spriteNode = SKSpriteNode(imageNamed: "road-line")
        spriteNode.zPosition = -1
        spriteNode.size = .init(width: 6, height: 30)
        return spriteNode
    }
}
