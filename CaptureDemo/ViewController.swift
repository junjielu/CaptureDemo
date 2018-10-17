//
//  ViewController.swift
//  CaptureDemo
//
//  Created by 陆俊杰 on 2018/10/17.
//  Copyright © 2018 陆俊杰. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {
    let renderView = RenderView(frame: UIScreen.main.bounds, device: nil)
    var camera: Camera?
    var filter: BasicOperation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.addSubview(renderView)
        
        do {
            let camera = try Camera(sessionPreset:.vga640x480)
            let filter = SaturationAdjustment()
            camera --> filter --> renderView
            camera.startCapture()
            
            self.camera = camera
            self.filter = filter
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }
}

