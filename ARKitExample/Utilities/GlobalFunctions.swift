//
//  GlobalFunctions.swift
//  Generate SE3
//
//  Created by Marc Haubenstock on 20/08/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARKit
import os.log

class GlobalFunctions {

  static let oslog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: "GlobalFunc")

  // Mark: Geometry
  class func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {
  
    let direction = simd_normalize(direction)

    // Special case handling: Check if the ray is horizontal as well.
  if direction.y == 0 {
    if rayOrigin.y == planeY {
      // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
      // Therefore we simply return the ray origin.
      return rayOrigin
    } else {
      // The ray is parallel to the plane and never intersects.
      return nil
    }
  }
  
  // The distance from the ray's origin to the intersection point on the plane is:
  //   (pointOnPlane - rayOrigin) dot planeNormal
  //  --------------------------------------------
  //          direction dot planeNormal
  
  // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
  let dist = (planeY - rayOrigin.y) / direction.y

  // Do not return intersections behind the ray's origin.
  if dist < 0 {
    return nil
  }
  
  // Return the intersection point.
  return rayOrigin + (direction * dist)


}

  // MARK: File System
  class func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
  class func createDirectory(withName: String) {
  
    let documentDirectoryURL = getDocumentsDirectory()
    let directoryURL = documentDirectoryURL.appendingPathComponent(withName, isDirectory: true)
    guard let _ = try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
    else{
      os_log("Create Directory: %@", log: GlobalFunctions.oslog, type: .fault, "Unable to create directory: " + withName)
      return
    }
    
    
  }
  
  class func clearDocumentsDiretory() {
  
    let path = GlobalFunctions.getDocumentsDirectory().path
    guard let directoryContents = try? FileManager.default.contentsOfDirectory(atPath: path) else{
      return
    }
    
    for item in directoryContents{
      let fullPath = path.appending("/").appending(item)
      if let _ = try? FileManager.default.removeItem(atPath: fullPath){
        os_log("Removed File: %@", log: GlobalFunctions.oslog, type: .info, fullPath)
      }
    }
  }
  
  
}
