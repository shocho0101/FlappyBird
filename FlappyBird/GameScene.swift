//
//  GameScene.swift
//  FlappyBird
//
//  Created by 張翔 on 2017/10/02.
//  Copyright © 2017年 sho. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var itemNode: SKNode!
    var bird: SKSpriteNode!
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    
    //スコア
    var score = 0
    var itemScore = 0
    var scoreLabelNode: SKLabelNode!
    var bestScoreNode: SKLabelNode!
    var itemScoreLabelNode: SKLabelNode!
    var bestItemScoreNode: SKLabelNode!
    let userDefaults: UserDefaults = UserDefaults.standard
    
    var audioPlayer = AVAudioPlayer()
    
    //SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //アイテム用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        //各種スプライトを生成する
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupItem()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else{
            restart()
        }
    }
    
    
    
    func setupGround(){
        //地面の画像を埋め込む
        let groundTexture = SKTexture(image: #imageLiteral(resourceName: "ground"))
        groundTexture.filteringMode = SKTextureFilteringMode.nearest
        
        //必要な枚数を計算
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        //スクロールするアクションを作成
        //左方向に一画面分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        stride(from: 0.0, to: needNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: (i * sprite.size.width) + (sprite.size.width / 2) , y: groundTexture.size().height / 2)
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理演算を追加する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突のカテゴリーを設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突の際に動かないようにする。
            sprite.physicsBody?.isDynamic = false
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
        
    }
    
    func setupCloud(){
        //雲の画像を読み込む
        let cloudTexture = SKTexture(image: #imageLiteral(resourceName: "cloud"))
        cloudTexture.filteringMode = SKTextureFilteringMode.nearest
        
        //必要な枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        //スクロールするアクションを作成
        //左画面に画像一枚分スクロールするアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        stride(from: 0.0, to: needCloudNumber, by: 1.0).forEach { (i) in
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようにする
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
            
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall(){
        //壁の画像を読み込む
        let wallTexture = SKTexture(image: #imageLiteral(resourceName: "wall"))
        wallTexture.filteringMode = SKTextureFilteringMode.linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let wallAnimation  = SKAction.sequence([moveWall, removeWall])
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run ({
            //壁関連のノードを載せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width, y: 0.0)
            wall.zPosition = -50.0 //雲より手前、地面より奥
            
            //画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            //下の壁のY軸の下限
            let under_wall_lowest_y = UInt32(center_y - wallTexture.size().height / 2 - random_y_range / 2)
            //1〜random_y_rangeまでのランダムな整数を作成
            let random_y = arc4random_uniform(UInt32(random_y_range))
            //Y軸の下限にランダムな値を足して下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            //キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 6
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            //スプライトに物理演算を追加する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の際に動かないようにする
            under.physicsBody?.isDynamic = false
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を追加する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の際に動かないようにする
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
            
            
            
        })
        
        //次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成->待ち時間->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupItem(){
        let itemTexture = SKTexture(image: #imageLiteral(resourceName: "star"))
        itemTexture.filteringMode = .linear
        
        let groundTexture = SKTexture(image: #imageLiteral(resourceName: "ground"))
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        
        //自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let itemAnimation  = SKAction.sequence([moveItem, removeItem])
        
        let createItem = SKAction.run {
            let item = SKSpriteNode(texture: itemTexture)
            
            let randomRange = self.frame.size.height - groundTexture.size().height - itemTexture.size().height
            let random = arc4random_uniform(UInt32(randomRange))
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width, y: CGFloat(random) + groundTexture.size().height + itemTexture.size().height / 2)
            
            item.run(itemAnimation)
            self.itemNode.addChild(item)
            
            item.physicsBody = SKPhysicsBody(circleOfRadius: itemTexture.size().height / 2)
            item.physicsBody?.isDynamic = false
            item.physicsBody?.categoryBitMask = self.itemCategory
        }
        
        let waitAnimation1 = SKAction.wait(forDuration: 1)
        let waitAnimation2 = SKAction.wait(forDuration: 2)
        
        let repeatAnimation = SKAction.repeatForever(SKAction.sequence([createItem, waitAnimation2]))
        
        itemNode.run(SKAction.sequence([waitAnimation1, repeatAnimation]))
        
        
    }
    
    func setupBird(){
        
        //鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(image: #imageLiteral(resourceName: "bird_a"))
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(image: #imageLiteral(resourceName: "bird_b"))
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.1)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突したときに回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | itemCategory
        
        //アニメーションを追加
        bird.run(flap)
        
        //スプライトを追加
        addChild(bird)
    }
    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreNode = SKLabelNode()
        bestScoreNode.fontColor = UIColor.black
        bestScoreNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreNode.zPosition = 100
        bestScoreNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestscore = userDefaults.integer(forKey: "BEST")
        bestScoreNode.text = "Best Score:\(bestscore)"
        self.addChild(bestScoreNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        bestItemScoreNode = SKLabelNode()
        bestItemScoreNode.fontColor = UIColor.black
        bestItemScoreNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        bestItemScoreNode.zPosition = 100
        bestItemScoreNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestItemScore = userDefaults.integer(forKey: "BESTITEM")
        bestItemScoreNode.text = "Best Item Score:\(bestItemScore)"
        self.addChild(bestItemScoreNode)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask ) == scoreCategory{
            //スコア用の物体と衝突した
            print("scoreUP")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore{
                bestScore = score
                bestScoreNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }else if contact.bodyA.categoryBitMask == itemCategory || contact.bodyB.categoryBitMask == itemCategory{
            if contact.bodyA.categoryBitMask == itemCategory{
                contact.bodyA.node?.removeFromParent()
            }else{
                contact.bodyB.node?.removeFromParent()
            }
            
            itemScore += 1
            itemScoreLabelNode.text = "ItemScore:\(itemScore)"
            
            var bestItemScore = userDefaults.integer(forKey: "BESTITEM")
            if  itemScore > bestItemScore{
                bestItemScore = itemScore
                bestItemScoreNode.text = "Best Item Score:\(bestItemScore)"
                userDefaults.set(bestItemScore, forKey: "BESTITEM")
                userDefaults.synchronize()
            }
            
            if let sound = NSDataAsset(name: "decision9") {
                audioPlayer = try! AVAudioPlayer(data: sound.data)
                audioPlayer.play()
            }
        }else{
            //壁か地面と衝突した
            print("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat.pi * CGFloat(bird.position.y) * 0.01, duration: 1)
            let stop = SKAction.run {
                self.bird.speed = 0
            }
            bird.run(SKAction.sequence([roll, stop]), withKey: "roll")
        }
        
    }
    
    func restart(){
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScore = 0
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
            bird.zRotation = 0.0
            bird.removeAction(forKey: "roll")
            
            wallNode.removeAllChildren()
            itemNode.removeAllChildren()
            
            bird.speed = 1
            scrollNode.speed = 1
            
            print("restart")
            
        }
    
    
    
    
    
    
    
    
}






