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
  
  }
  
  
  func writeARImageToDisk(pixelBufferFrame: CVPixelBuffer, id:Int){
    
    let imageName = "frame_" + String(id)
    let filename = GlobalFunctions.getDocumentsDirectory().appendingPathComponent(self.imageFolder, isDirectory: true).appendingPathComponent(imageName+".png")
    
    DispatchQueue.global(qos: .utility).async {
      
      let width = 640
      let height = 480
      
      let ci_image = CIImage(cvPixelBuffer: pixelBufferFrame)
      let context = CIContext() // Prepare for create CGImage
      
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
      
      guard let _ = try? data.write(to: filename) else {
        os_log("writeARFrameToDisk: %@", log: self.oslog, type: .fault, "Unable to save png")
        return
      }
      
      os_log("writeARFrameToDisk: %@", log: self.oslog, type: .info, "saved png")
      
      
    } // END ASYNC #1
    
    
    
  }
  
}

