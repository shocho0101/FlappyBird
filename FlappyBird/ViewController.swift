//
//  ViewController.swift
//  FlappyBird
//
//  Created by 張翔 on 2017/10/02.
//  Copyright © 2017年 sho. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //SKViewに型を変換する
        let skView = self.view as! SKView
        
        //FPSの表示
        skView.showsFPS = true
        
        //ノード数の表示
        skView.showsNodeCount = true
        
        //viewと同じサイズでsceneを設定
        let scene = GameScene(size: skView.frame.size)
        
        //ビューにシーンを表示
        skView.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        get{
            return true
        }
    }

}

