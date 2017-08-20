/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import UIKit
import os.log

class ViewController: UIViewController {
  
  // MARK: - ARKit Config Properties
  
  var screenCenter: CGPoint?
  
  let session = ARSession()
  let standardConfiguration: ARWorldTrackingSessionConfiguration = {
    let configuration = ARWorldTrackingSessionConfiguration()
    configuration.planeDetection = .horizontal
    return configuration
  }()
  
  // MARK: - Virtual Object Manipulation Properties
  
  var dragOnInfinitePlanesEnabled = false
  
  var isLoadingObject: Bool = false {
    didSet {
      DispatchQueue.main.async {
        self.settingsButton.isEnabled = !self.isLoadingObject
        self.captureButton.isEnabled = !self.isLoadingObject
        self.restartExperienceButton.isEnabled = !self.isLoadingObject
      }
    }
  }
  
  // MARK: - Other Properties
  
  let oslog : OSLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: "OSLOG - ViewController")
  let visionManager: VisionManager = VisionManager()
  
  var textManager: TextManager!
  var restartExperienceButtonIsEnabled = true
  var isCapturing = false
  var frameCounter: Int = 0
  
  // MARK: - UI Elements
  
  var spinner: UIActivityIndicatorView?
  
  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet weak var messagePanel: UIView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var messagePanel_SE3: UIView!
  @IBOutlet weak var messageLabel_SE3: UILabel!
  @IBOutlet weak var settingsButton: UIButton!
  @IBOutlet weak var captureButton: UIButton!
  @IBOutlet weak var restartExperienceButton: UIButton!
  
  // MARK: - Queues
  
  let serialQueue = DispatchQueue(label: "com.apple.arkitexample.serialSceneKitQueue")
  
  
  // MARK: - View Controller Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    Setting.registerDefaults()
    setupUIControls()
    setupScene()
    
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // Prevent the screen from being dimmed after a while.
    UIApplication.shared.isIdleTimerDisabled = true
    
    if ARWorldTrackingSessionConfiguration.isSupported {
      // Start the ARSession.
      resetTracking()
    } else {
      // This device does not support 6DOF world tracking.
      let sessionErrorMsg = "This app requires world tracking. World tracking is only available on iOS devices with A9 processor or newer. " +
      "Please quit the application."
      displayErrorMessage(title: "Unsupported platform", message: sessionErrorMsg, allowRestart: false)
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    session.pause()
  }
  
  // MARK: - Setup
  
  func setupScene() {
    
    // set up scene view
    sceneView.setup()
    sceneView.delegate = self
    sceneView.session = session
    // sceneView.showsStatistics = true
    
    sceneView.scene.enableEnvironmentMapWithIntensity(25, queue: serialQueue)
    
    setupFocusSquare()
    
    DispatchQueue.main.async {
      self.screenCenter = self.sceneView.bounds.mid
    }
  }
  
  func setupUIControls() {
    textManager = TextManager(viewController: self)
    
    // Set appearance of message output panel
    messagePanel.layer.cornerRadius = 3.0
    messagePanel.clipsToBounds = true
    messagePanel.isHidden = true
    messageLabel.text = ""
    
    messagePanel_SE3.layer.cornerRadius = 3.0
    messagePanel_SE3.clipsToBounds = true
    messagePanel_SE3.isHidden = false
    messageLabel_SE3.text = "TestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTest"
    
  }
  
  // MARK: - Planes
  
  var planes = [ARPlaneAnchor: Plane]()
  
  func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
    
    let plane = Plane(anchor)
    planes[anchor] = plane
    node.addChildNode(plane)
    
    textManager.cancelScheduledMessage(forType: .planeEstimation)
    textManager.showMessage("SURFACE DETECTED")
  }
  
  func updatePlane(anchor: ARPlaneAnchor) {
    if let plane = planes[anchor] {
      plane.update(anchor)
    }
  }
  
  func removePlane(anchor: ARPlaneAnchor) {
    if let plane = planes.removeValue(forKey: anchor) {
      plane.removeFromParentNode()
    }
  }
  
  func resetTracking() {
    session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
    
    textManager.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT",
                                inSeconds: 7.5,
                                messageType: .planeEstimation)
  }
  
  // MARK: - Focus Square
  
  var focusSquare: FocusSquare?
  
  func setupFocusSquare() {
    serialQueue.async {
      self.focusSquare?.isHidden = false   
      self.focusSquare?.removeFromParentNode()
      self.focusSquare = FocusSquare()
      self.sceneView.scene.rootNode.addChildNode(self.focusSquare!)
    }
    
    textManager.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
  }
  
  func updateFocusSquare() {
    guard let screenCenter = screenCenter else { return }
    
    DispatchQueue.main.async {
      
      let (worldPos, planeAnchor, _) = self.worldPositionFromScreenPosition(screenCenter,
                                                                            in: self.sceneView,
                                                                            objectPos: self.focusSquare?.simdPosition)
      if let worldPos = worldPos {
        self.serialQueue.async {
          self.focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
        }
        self.textManager.cancelScheduledMessage(forType: .focusSquare)
      }
    }
  }
  
  // MARK: - Error handling
  
  func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
    // Blur the background.
    textManager.blurBackground()
    
    if allowRestart {
      // Present an alert informing about the error that has occurred.
      let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
        self.textManager.unblurBackground()
        self.restartExperience(self)
      }
      textManager.showAlert(title: title, message: message, actions: [restartAction])
    } else {
      textManager.showAlert(title: title, message: message, actions: [])
    }
  }
  
  //   // MARK: - Transformation
  
  func worldPositionFromScreenPosition(_ position: CGPoint,
                                       in sceneView: ARSCNView,
                                       objectPos: float3?,
                                       infinitePlane: Bool = false) -> (position: float3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
    
    let dragOnInfinitePlanesEnabled = UserDefaults.standard.bool(for: .dragOnInfinitePlanes)
    
    // -------------------------------------------------------------------------------
    // 1. Always do a hit test against exisiting plane anchors first.
    //    (If any such anchors exist & only within their extents.)
    
    let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
    if let result = planeHitTestResults.first {
      
      let planeHitTestPosition = result.worldTransform.translation
      let planeAnchor = result.anchor
      
      // Return immediately - this is the best possible outcome.
      return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
    }
    
    // -------------------------------------------------------------------------------
    // 2. Collect more information about the environment by hit testing against
    //    the feature point cloud, but do not return the result yet.
    
    var featureHitTestPosition: float3?
    var highQualityFeatureHitTestResult = false
    
    let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
    
    if !highQualityfeatureHitTestResults.isEmpty {
      let result = highQualityfeatureHitTestResults[0]
      featureHitTestPosition = result.position
      highQualityFeatureHitTestResult = true
    }
    
    // -------------------------------------------------------------------------------
    // 3. If desired or necessary (no good feature hit test result): Hit test
    //    against an infinite, horizontal plane (ignoring the real world).
    
    if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
      
      if let pointOnPlane = objectPos {
        let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
        if pointOnInfinitePlane != nil {
          return (pointOnInfinitePlane, nil, true)
        }
      }
    }
    
    // -------------------------------------------------------------------------------
    // 4. If available, return the result of the hit test against high quality
    //    features if the hit tests against infinite planes were skipped or no
    //    infinite plane was hit.
    
    if highQualityFeatureHitTestResult {
      return (featureHitTestPosition, nil, false)
    }
    
    // -------------------------------------------------------------------------------
    // 5. As a last resort, perform a second, unfiltered hit test against features.
    //    If there are no features in the scene, the result returned here will be nil.
    
    let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
    if !unfilteredFeatureHitTestResults.isEmpty {
      let result = unfilteredFeatureHitTestResults[0]
      return (result.position, nil, false)
    }
    
    return (nil, nil, false)
  }
  
  
}

