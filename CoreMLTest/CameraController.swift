//
//  File.swift
//  CoreMLTest
//
//  Created by Supphawit Getmark on 8/11/2560 BE.
//  Copyright © 2560 Supphawit Getmark. All rights reserved.
//

import Foundation
import AVFoundation

class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    enum CameraControllerError: Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    var captureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureInput?
    var videoOutput: AVCaptureVideoDataOutput?
    
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
            
            self.videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video data buffer"))
            if captureSession.canAddOutput(self.videoOutput!) {
                captureSession.addOutput(self.videoOutput!)
            }
                        captureSession.startRunning()
        }
        

    }
}
