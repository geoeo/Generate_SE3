//
//  VisionManager.swift
//  Generate SE3
//
//  Created by Marc Haubenstock on 20/08/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import ARKit
import os.log

class VisionManager{

  let oslog : OSLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: "OSLOG - VisionManager")
  
  let imageFolder = "Images"
  let poseFolder  = "Poses"
  let intrinsicsFolder = "Intrinsics"
  var sessionId = -1
  var frameCounter = 0
  
  fileprivate func createDirectoryStructure() {
    let sessionDir = String(self.sessionId)
    GlobalFunctions.createDirectory(withName: String() , withSession: sessionDir)
    GlobalFunctions.createDirectory(withName: self.imageFolder, withSession:sessionDir)
    GlobalFunctions.createDirectory(withName: self.poseFolder,withSession:sessionDir)
    GlobalFunctions.createDirectory(withName: self.intrinsicsFolder,withSession:sessionDir)
  }
  
  fileprivate func buildFilePath(sessionId: Int,folderName:String, fileName:String) -> URL {
    return GlobalFunctions.getDocumentsDirectory().appendingPathComponent(String(self.sessionId), isDirectory: true).appendingPathComponent(folderName, isDirectory: true).appendingPathComponent(fileName)
  }
  
 func createNewCaptureSession(){
    self.sessionId += 1
    self.frameCounter = 0
    createDirectoryStructure()
  }
  
  init() {
    
    // Init Frame Queue Here
    GlobalFunctions.clearDocumentsDiretory()
    
  }
  
  func writeARFrameToDisk(frame: ARFrame, id:Int){
  
    writeARImageToDisk(pixelBufferFrame: frame.capturedImage, id: id)
    writeARPoseToDisk(transform: frame.camera.transform, id: sessionId)
    writeIntrinsicsToDisk(intrinsics: frame.camera.intrinsics, id: sessionId)
    self.frameCounter += 1
  
  }
  
  
  fileprivate func writeARImageToDisk(pixelBufferFrame: CVPixelBuffer, id:Int){
    
    let imageName = "frame_" + String(self.frameCounter)
    let fileURL = buildFilePath(sessionId: self.sessionId,folderName: self.imageFolder, fileName: imageName.appending(".png"))
    
    DispatchQueue.global(qos: .utility).async {
      
      // orginal 1280 * 720
      
      let width = 640
      let height = 480
      
//      let width = 640
//      let height = 360
      
      // Hierarchy: CVPixelBuffer -> CoreImage -> CoreGraphics -> UIImage
      
      let ci_image = CIImage(cvPixelBuffer: pixelBufferFrame)
      let context = CIContext()
      
      guard let cgImg = context.createCGImage(ci_image, from: ci_image.extent) else {
        os_log("writeARFrameToDisk: %@", log: self.oslog, type: .fault, "Could not create cg img")
        return
      }
      
      guard let cgContext = CGContext(data: nil,width: width,height: height,bitsPerComponent: cgImg.bitsPerComponent,bytesPerRow: cgImg.bytesPerRow,space: cgImg.colorSpace!,bitmapInfo: cgImg.bitmapInfo.rawValue) else {
        os_log("writeARFrameToDisk: %@", log: self.oslog, type: .fault, "Could not create cgContext")
        
        return
      }
      
      cgContext.interpolationQuality = .high
      cgContext.draw(cgImg, in: CGRect(x: 0, y: 0, width: width, height: height))
      guard let cgImgResized = cgContext.makeImage() else {
        os_log("writeARFrameToDisk: %@", log: self.oslog, type: .fault, "Unable to generate resized image")
        return
      }
      
      let image = UIImage(cgImage: cgImgResized)
      
      guard let data = UIImagePNGRepresentation(image) else {
        os_log("writeARFrameToDisk: %@", log: self.oslog, type: .fault, "Unable to generate png")
        return
      }
      
      guard let _ = try? data.write(to: fileURL) else {
        os_log("writeARFrameToDisk: %@", log: self.oslog, type: .fault, "Unable to save png")
        return
      }
      
//      os_log("writeARFrameToDisk: %@", log: self.oslog, type: .info, "saved png")
      
      
    } // END ASYNC #1

  }
  
  fileprivate func writeARPoseToDisk(transform : matrix_float4x4, id:Int){
  
      let fileName = "pose_" + String(self.frameCounter)
      let fileURL = buildFilePath(sessionId: self.sessionId,folderName: self.poseFolder, fileName: fileName.appending(".txt"))
      let (c1,c2,c3,c4) = transform.columns
    
      let contents = String().appending(vectorToString(vec: c1)).appending(" ").appending(vectorToString(vec: c2)).appending(" ").appending(vectorToString(vec: c3)).appending(" ").appending(vectorToString(vec: c4)).appending("\n")
    
    
      DispatchQueue.global(qos: .utility).async {
      
        let filePath = fileURL.path
      
        if(FileManager.default.fileExists(atPath: filePath)){
          guard let fileHandle = FileHandle(forWritingAtPath: filePath) else {
            os_log("writeARPoseToDisk: %@", log: self.oslog, type: .fault, "could not create file handle")
            return
          }
          
          guard let data = contents.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            os_log("writeARPoseToDisk: %@", log: self.oslog, type: .fault, "could not convert String to Data")
            return
          }
          
          fileHandle.seekToEndOfFile()
          fileHandle.write(data)
          fileHandle.closeFile()
          
        }
        else{
          guard let _ = try? contents.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
          else
          {
            os_log("writeARPoseToDisk: %@", log: self.oslog, type: .fault, "could not write pose to disk")
            return
          }
        }
      }
  }
  
  fileprivate func writeIntrinsicsToDisk(intrinsics: matrix_float3x3, id:Int){
  
      let fileName = "intrinsics_" + String(self.frameCounter)
      let fileURL = buildFilePath(sessionId: self.sessionId,folderName: self.intrinsicsFolder, fileName: fileName.appending(".txt"))
      let (c1,c2,c3) = intrinsics.columns
    
      let contents = String().appending(vectorToString(vec: c1)).appending(" ").appending(vectorToString(vec: c2)).appending(" ").appending(vectorToString(vec: c3)).appending("\n")
    
      DispatchQueue.global(qos: .utility).async {
      
        let filePath = fileURL.path
      
        if(FileManager.default.fileExists(atPath: filePath)){
         guard let fileHandle = FileHandle(forWritingAtPath: filePath) else {
            os_log("writeARIntrinsicsToDisk: %@", log: self.oslog, type: .fault, "could not create file handle")
            return
          }
          
          guard let data = contents.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            os_log("writeARIntrinsicsToDisk: %@", log: self.oslog, type: .fault, "could not convert String to Data")
            return
          }
          
          fileHandle.seekToEndOfFile()
          fileHandle.write(data)
          fileHandle.closeFile()
        }
        else{
          guard let _ = try? contents.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
          else
          {
            os_log("writeARIntrinsicsToDisk: %@", log: self.oslog, type: .fault, "coult not write intrinsics to disk")
            return
          }
        }
      }
  }
  
  fileprivate func vectorToString(vec: float4) -> String {
  
    return String().appending(String(vec.x)).appending(" ").appending(String(vec.y)).appending(" ").appending(String(vec.z)).appending(" ").appending(String(vec.w))
  }
  
    func vectorToString(vec: float3) -> String {
  
    return String().appending(String(vec.x)).appending(" ").appending(String(vec.y)).appending(" ").appending(String(vec.z))
    
  }
  
  
}

