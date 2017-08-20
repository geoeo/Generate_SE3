/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 UI Actions for the main view controller.
 */

import UIKit
import SceneKit
import os.log

extension ViewController: UIPopoverPresentationControllerDelegate {
  
  enum SegueIdentifier: String {
    case showSettings
    case showObjects
  }
  
  // MARK: - Interface Actions
  
  @IBAction func startCapture(_ button: UIButton) {
    // Set global property for capturing SE3 properties of the scene
    
    self.isCapturing = !self.isCapturing
    
    os_log("startCapture: %@, %@", log: self.oslog, type: .info, "Button Pressed", String(self.isCapturing))
    
    
    
  }
  
  /// - Tag: restartExperience
  @IBAction func restartExperience(_ sender: Any) {
    guard restartExperienceButtonIsEnabled, !isLoadingObject else { return }
    
    DispatchQueue.main.async {
      self.restartExperienceButtonIsEnabled = false
      
      self.textManager.cancelAllScheduledMessages()
      self.textManager.dismissPresentedAlert()
      self.textManager.showMessage("STARTING A NEW SESSION")
      
      self.focusSquare?.isHidden = true
      
      self.resetTracking()
      
      self.restartExperienceButton.setImage(#imageLiteral(resourceName: "restart"), for: [])
      
      // Show the focus square after a short delay to ensure all plane anchors have been deleted.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
        self.setupFocusSquare()
      })
      
      // Disable Restart button for a while in order to give the session enough time to restart.
      DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
        self.restartExperienceButtonIsEnabled = true
      })
    }
  }
  
  // MARK: - UIPopoverPresentationControllerDelegate
  
  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return .none
  }
}
