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
  
  init() {
    
    // Init Frame Queue Here
    GlobalFunctions.clearDocumentsDiretory()
    GlobalFunctions.createDirectory(withName: self.imageFolder)
    GlobalFunctions.createDirectory(withName: self.poseFolder)
    GlobalFunctions.createDirectory(withName: self.intrinsicsFolder)
    
  }
  
  func writeARFrameToDisk(frame: ARFrame, id:Int){
  
    writeARImageToDisk(pixelBufferFrame: frame.capturedImage, id: id)
    writeARPoseToDisk(transform: frame.camera.transform, id: id)
    writeIntrinsicsToDisk(intrinsics: frame.camera.intrinsics, id: id)
  
  }
  
  
  func writeARImageToDisk(pixelBufferFrame: CVPixelBuffer, id:Int){
    
    let imageName = "frame_" + String(id)
    let fileURL = GlobalFunctions.getDocumentsDirectory().appendingPathComponent(self.imageFolder, isDirectory: true).appendingPathComponent(imageName+".png")
    
    DispatchQueue.global(qos: .utility).async {
      
      let width = 640
      let height = 480
      
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
  
  func writeARPoseToDisk(transform : matrix_float4x4, id:Int){
  
      let fileName = "pose_" + String(id)
      let fileURL = GlobalFunctions.getDocumentsDirectory().appendingPathComponent(self.poseFolder, isDirectory: true).appendingPathComponent(fileName+".txt")
      let contents = transform.debugDescription
    
      DispatchQueue.global(qos: .utility).async {
        guard let _ = try? contents.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
        else
        {
          os_log("writeARPoseToDisk: %@", log: self.oslog, type: .fault, "coult not write pose to disk")
          return
        }
      }
  }
  
  func writeIntrinsicsToDisk(intrinsics: matrix_float3x3, id:Int){
  
  let fileName = "intrinsics_" + String(id)
      let fileURL = GlobalFunctions.getDocumentsDirectory().appendingPathComponent(self.intrinsicsFolder, isDirectory: true).appendingPathComponent(fileName+".txt")
      let contents = intrinsics.debugDescription
    
      DispatchQueue.global(qos: .utility).async {
        guard let _ = try? contents.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
        else
        {
          os_log("writeARIntrinsicsToDisk: %@", log: self.oslog, type: .fault, "coult not write intrinsics to disk")
          return
        }
      }
  
  }
  
}

