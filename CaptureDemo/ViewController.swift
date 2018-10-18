//
//  ViewController.swift
//  CaptureDemo
//
//  Created by 陆俊杰 on 2018/10/17.
//  Copyright © 2018 陆俊杰. All rights reserved.
//

import UIKit
import GPUImage2
import Photos

class ViewController: UIViewController {
    let renderView = RenderView(frame: UIScreen.main.bounds)
    var camera: Camera!
    var filter: SaturationAdjustment!
    var movieOutput: MovieOutput?
    
    let fileURL = try! FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true).appendingPathComponent("test.mp4")
    
    var isRecording = false
    
    let button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        button.frame = CGRect(x: (self.view.bounds.width - 80) / 2, y: self.view.bounds.height - 80 - 50, width: 80, height: 80)
        button.layer.cornerRadius = 40
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.white
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
        self.view.addSubview(renderView)
        self.view.addSubview(button)
        
        do {
            camera =  try Camera(sessionPreset: .high)
            filter = SaturationAdjustment()
            filter.saturation = 0.4
            camera --> filter --> renderView
            camera.startCapture()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }
    
    @objc func didTapButton() {
        if (!isRecording) {
            do {
                self.isRecording = true
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at:fileURL)
                }
                
                movieOutput = try MovieOutput(URL:fileURL, size:Size(width:480, height:640), liveVideo:true)
                camera.audioEncodingTarget = movieOutput
                filter --> movieOutput!
                movieOutput!.startRecording()
                DispatchQueue.main.async {
                    self.button.backgroundColor = UIColor.green
                }
            } catch {
                fatalError("Couldn't initialize movie, error: \(error)")
            }
        } else {
            movieOutput?.finishRecording {
                self.isRecording = false
                DispatchQueue.main.async {
                    self.button.backgroundColor = UIColor.white
                    
                    checkPhotoLibraryAuthorizationStatus { _ in
                        PHPhotoLibrary.shared().performChanges({
                            let creationRequest = PHAssetCreationRequest.forAsset()
                            creationRequest.addResource(with: .video, fileURL: self.fileURL, options: nil)
                        }, completionHandler: { (success, error) in
                            print("result: \(success), error: \(error)")
                        })
                    }
                }
                self.camera.audioEncodingTarget = nil
                self.movieOutput = nil
            }
        }
    }
}

func checkPhotoLibraryAuthorizationStatus(completionHandler: @escaping (Bool) -> Void) {
    func showSuggestionForOpenAlbumAuthorization() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "小贴士", message: "照片权限被关闭啦，现在去设置-即刻-照片中允许访问照片就行了", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
                completionHandler(false)
            }
            let openAction = UIAlertAction(title: "设置", style: .default) { (_) in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.openURL(url)
                }
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(openAction)
            
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return }
            rootVC.present(alertController, animated: true, completion: nil)
        }
    }
    
    switch PHPhotoLibrary.authorizationStatus() {
    case .notDetermined:
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                completionHandler(true)
            } else {
                showSuggestionForOpenAlbumAuthorization()
            }
        }
    case .authorized:
        completionHandler(true)
    case .denied, .restricted:
        showSuggestionForOpenAlbumAuthorization()
    }
}
