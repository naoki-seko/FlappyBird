//
//  GameScene.swift
//  FlappyBird
//
//  Created by 世古直輝 on 2018/03/21.
//  Copyright © 2018年 世古直輝. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    var scrollNode: SKNode!
    var wallNode: SKNode!
    var appleNode: SKNode!
    var bird: SKSpriteNode!
    
    let music = SKAudioNode(fileNamed: "BGM")
    
    let koukaon = SKAction.playSoundFileNamed("koukaon", waitForCompletion: true)
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0    //0...00001
    let groundCategory: UInt32 = 1 << 1  //0...00010
    let wallCategory: UInt32 = 1 << 2    //0...00100
    let scoreCategory: UInt32 = 1 << 3   //0...01000
    let appleCategory: UInt32 = 1 << 4   //0...10000
    
    //スコア
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemscore = 0
    var itemScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
//SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1.0)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //アイテム用のノード
        appleNode = SKNode()
        scrollNode.addChild(appleNode)
        
        // BGMを流す
        addChild(music)
        
        //各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupApple()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupItemScoreLabel()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("衝突")
        //ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        print(contact.bodyA.categoryBitMask)
        print(contact.bodyB.categoryBitMask)
        
        if (contact.bodyA.categoryBitMask & appleCategory) == appleCategory || (contact.bodyB.categoryBitMask & appleCategory) == appleCategory {
            
            print("APPLE!")
            contact.bodyA.node?.removeFromParent()
            self.run(koukaon)
            itemscore += 1
            itemScoreLabelNode.text = "Item:\(itemscore)"
            
        } else  if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }   else {
            //壁か地面と衝突した
            print("GameOver")

            //スクロールを停止させる
            scrollNode.speed = 0

            bird.physicsBody?.collisionBitMask = groundCategory

            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // いちばん手前に設定
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 //いちばん手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    
    func setupItemScoreLabel(){
        itemscore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100 // いちばん手前に設定
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item:\(itemscore)"
        self.addChild(itemScoreLabelNode)
    }
   
    
    func setupGround(){
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        //元の位置に戻すアクション
       let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
        //スプライトの表示する位置を指定する
        sprite.position = CGPoint(x: groundTexture.size().width * (CGFloat(i) + 0.5),
                                        y: groundTexture.size().height * 0.5
        )
        //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
        //スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突のカテゴリー判定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
        //衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
        //スプライトを追加する
        scrollNode.addChild(sprite)
        }
    }
    func setupCloud(){
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        
        //左にスクロール-> 元の位置-> 左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようにする
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5), y: self.size.height - cloudTexture.size().height * 0.5
            )
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall(){
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //２つのアニメーションを順に実行するアクションを生成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width, y: 0.0)
            wall.zPosition = -50.0 //雲より手前、地面より奥
            
            //画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //壁のY座標を上下ランダムにさせる時の最大値
            let random_y_range = self.frame.size.height / 4
        //下の壁のY軸の下限
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 - random_y_range / 2)
            
            // １〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform(UInt32(random_y_range))
            //y軸の加減にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            //キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 6
        
        //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            //スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0 , y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height ))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成->待ち時間->壁を作成　を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
    
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupApple(){
        //アイテムの画像を読み込む
        let appleTexture = SKTexture(imageNamed: "apple")
        appleTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingAppleDistance = CGFloat(self.frame.size.width  + appleTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveApple = SKAction.moveBy(x: -movingAppleDistance - appleTexture.size().width, y: 0, duration: 4.0)
        
        //自身を取り除くアクションを作成
        let removeApple = SKAction.removeFromParent()
        
        //２つのアニメーションを順に実行するアクションを生成
        let appleAnimation = SKAction.sequence([moveApple, removeApple])
        
        //アイテムを生成するアクションを作成
        let createAppleAnimation = SKAction.run({
           
            //アイテム関連のノードを乗せるノードを作成
            let apple = SKNode()
            
            //画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //りんごのY座標を上下ランダムにさせる時の最大値
            let random_y_range = self.frame.size.height / 2
            //りんごのY軸の下限
            let apple_lowest_y = UInt32( center_y -  appleTexture.size().height / 10 - random_y_range / 2)
            
            // １〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform(UInt32(random_y_range))
            //y軸の下限にランダムな値を足して、りんごのY座標を決定
            let apple_y = CGFloat(apple_lowest_y + random_y)
            
            apple.position = CGPoint(x: self.frame.size.width  + appleTexture.size().width  , y: apple_y)
            apple.zPosition = 30.0
            
            
            //りんごを作成
            let appSpriteNode = SKSpriteNode(texture: appleTexture)
            appSpriteNode.position = CGPoint(x: 0.0, y: 0)
            
            //スプライトに物理演算を設定する
            apple.physicsBody = SKPhysicsBody(rectangleOf: appleTexture.size())
            apple.physicsBody?.categoryBitMask = self.appleCategory
            //apple.physicsBody?.contactTestBitMask = self.birdCategory
            
            //衝突しても動かない
            apple.physicsBody?.isDynamic = false
            
            apple.addChild(appSpriteNode)
            apple.run(appleAnimation)
            
            self.appleNode.addChild(apple)
        })
        //次のアイテム作成までの待ち時間のアクションを作成
        let firstAppleWait = SKAction.wait(forDuration: 1)
        let waitAppleAnimation = SKAction.wait(forDuration: 4)
        let repeatForeverApple = SKAction.repeatForever(SKAction.sequence([createAppleAnimation, waitAppleAnimation]))
        appleNode.run(firstAppleWait)
        appleNode.run(repeatForeverApple)
    }
    
    
    func setupBird() {
        //鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //２種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimatiuon = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        
        let flap = SKAction.repeatForever(texturesAnimatiuon)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
       //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory  //跳ね返り
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | appleCategory
        
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
        
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemscore = 0
        itemScoreLabelNode.text = String("Item:\(itemscore)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory 
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        appleNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    
    //画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       if scrollNode.speed > 0 {
        //鳥の速度をゼロにする
        bird.physicsBody?.velocity = CGVector.zero
        
        //鳥に縦方向の力を加える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        print("上昇")
        }else if bird.speed == 0 {
        restart()
        }
    }
    
   
}











