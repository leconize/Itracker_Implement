//
//  File.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 8/11/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
import AVFoundation
import CoreML

protocol CameraControllerDelegate{
    func didCaptureVideoFrame(image: CIImage)
}

@available(iOS 11.0, *)
class CameraController: NSObject{
    
    // MARK:- Error
    enum CameraControllerError: Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    // MARK:- Properties
    let imageCount = 0
    
    var captureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureInput?
    var videoOutput: AVCaptureVideoDataOutput?
    
    var isProcessing = false
    
    var delegate: CameraControllerDelegate?
    
    
    // MARK:- CameraSetup
    func prepare(completionHandler: @escaping (Error?) -> Void ){
        
        func createCaptureSession(){
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevice() throws {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front)
            if(session.devices.isEmpty){
                throw CameraControllerError.noCamerasAvailable
            }
            
            for camera in session.devices{
                if( camera.position == .front){
                    self.frontCamera = camera
                }
            }
            
            if(self.frontCamera == nil){
                throw CameraControllerError.noCamerasAvailable
            }
        }
        
        func addCaptureDevice() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            if let frontCamera = self.frontCamera{
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if (captureSession.canAddInput(self.frontCameraInput!)){
                    captureSession.addInput(self.frontCameraInput!)
                }
                else{ throw CameraControllerError.inputsAreInvalid }
            }
            else { throw CameraControllerError.noCamerasAvailable }
        }
        
        func configureVideoOutput() throws {
            
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            let videoSetting: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            self.videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.videoSettings = videoSetting
            videoOutput!.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video data buffer"))
            if captureSession.canAddOutput(self.videoOutput!) {
                captureSession.addOutput(self.videoOutput!)
            }
            else{
                throw CameraControllerError.inputsAreInvalid
            }
//            var movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
            
            captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async {
            do{
                print("start")
                createCaptureSession()
                try configureCaptureDevice()
                try addCaptureDevice()
                try configureVideoOutput()
                print("success")
            }
            catch{
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func stopCaptureCamera(){
        self.captureSession?.stopRunning()
    }
}

@available(iOS 11.0, *)
extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate{

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let  _delegate = self.delegate else { return }
        if(!isProcessing){
            DispatchQueue.global(qos: .background).async {
                let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                var image = CIImage.init(cvImageBuffer: imageBuffer!)
                image = image.oriented(CGImagePropertyOrientation(rawValue: 5)!)
                _delegate.didCaptureVideoFrame(image: image)
            }
        }
    }

}


