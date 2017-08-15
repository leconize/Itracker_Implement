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

class CameraController: NSObject{
    
    enum CameraControllerError: Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    let testModel: TestModel = TestModel()
    
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
        
        DispatchQueue(label: "prepare").async {
            do{
                createCaptureSession()
                try configureCaptureDevice()
                try addCaptureDevice()
                try configureVideoOutput()
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
    
    func detectEye(on image: CIImage){
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyLow]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: image)
        for face in faces as! [CIFaceFeature] {
            if face.hasLeftEyePosition{
                print("Left eye bounds are \(face.leftEyePosition)")
                
            }
            if face.hasRightEyePosition{
                print("Right eye bounds are \(face.rightEyePosition)")
            }
            let sendImage = image.cropped(to: face.bounds)
            let scale = sendImage.extent.size.width / 224
            let faceScaleImage = scaleImage(sendImage, scale: Float(scale))
            let leftEyeImage = image.cropped(to: getEyeImageRect(posX: face.leftEyePosition.x, posY: face.leftEyePosition.y, size: 224))
            let rightEyeImage = image.cropped(to: getEyeImageRect(posX: face.rightEyePosition.x, posY: face.rightEyePosition.y, size: 224))
            let facegrid = calculateFaceGrid(imageBound: image.extent, gridSize: 25, faceBound: face.bounds)
            
            let faceArray = preprocess(image: faceScaleImage)
            let leftEyeArray = preprocess(image: leftEyeImage)
            let rightEyeArray = preprocess(image: rightEyeImage)
            
            do{
                let result = try testModel.prediction(facegrid: facegrid!, image_face: faceArray!, image_left: leftEyeArray!, image_right: rightEyeArray!)
                for index in 0...5{
                    print(result.fc3[index])
                }
            }
            catch{
                
            }
            
        }
    }
    
    func preprocess(image: CIImage) -> MLMultiArray?{
        
        guard let pixels = image.pixelData() else { return nil }
        guard let array = try? MLMultiArray(shape: [1, 3, 224, 224], dataType: .double) else {
            return nil
        }
        
        let r = pixels.enumerated().filter { $0.offset % 4 == 0 }.map { $0.element }
        let g = pixels.enumerated().filter { $0.offset % 4 == 1 }.map { $0.element }
        let b = pixels.enumerated().filter { $0.offset % 4 == 2 }.map { $0.element }
        
        let combination = r + g + b
        for (index, element) in combination.enumerated() {
            array[index] = NSNumber(value: element)
        }
        
        return array
        
        
    }
    
    func calculateFaceGrid(imageBound: CGRect, gridSize:CGFloat, faceBound:CGRect) -> MLMultiArray?{
        let scaleX = imageBound.width / gridSize
        let scaleY = imageBound.height / gridSize
        
        guard let faceGridArray = try? MLMultiArray(shape: [625,1, 1], dataType: .double) else{
            return nil
        }
        
        var xLow = faceBound.origin.x * scaleX
        var yLow = faceBound.origin.y * scaleY
        
        let width = faceBound.size.width * scaleX
        let height = faceBound.size.height * scaleY
        
        var xHi = xLow + width - 1
        var yHi = yLow + height - 1
        
        xLow = min(gridSize, max(1, xLow))
        xHi = min(gridSize, max(1, xHi))
        yLow = min(gridSize, max(1, yLow))
        yHi = min(gridSize, max(1, yHi))
        
        for index in 0..<(Int(gridSize*gridSize)){
            let row = round( CGFloat(index) / gridSize)
            let column = CGFloat(index%Int(gridSize))
            if(row <= xHi && row >= xLow && column <= yHi && column >= yLow){
                faceGridArray[index] = 1
            }
            else{
                faceGridArray[index] = 0
            }
        }
        return faceGridArray
    }
    
    func getEyeImageRect(posX: CGFloat, posY: CGFloat, size: CGFloat) -> CGRect{
        return CGRect(x: posX+size/2, y: posY+size/2, width: -size, height: -size)
    }
    
    func scaleImage(_ image: CIImage, scale:Float) -> CIImage{
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        return filter.value(forKey: "outputImage") as! CIImage
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue(label: "getPos").async {
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            let image = CIImage.init(cvImageBuffer: imageBuffer!)
            self.detectEye(on: image)
        }
    }
}

extension CIImage{
    func pixelData() -> [UInt8]? {
        
        let dataSize = extent.size.width * extent.size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData, width: Int(extent.size.width), height: Int(extent.size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(extent.size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: extent.size.width, height: extent.size.height))
        
        return pixelData
    }
}

