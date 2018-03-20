//
//  MapViewController
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 01/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SpriteKit
import CoreLocation

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // A container view for visual effects
    @IBOutlet weak var containerView: UIView!
    
    // The scene that holds the map nodes
    static var scene: SKScene!
    
    // Vars for gesture recognisers
    var lastScale: CGFloat = 0.0
    var previousLocation = CGPoint.zero
    var initialRotation: CGFloat = 0.0
    
    // Limits for the map
    let minWidth: CGFloat = 300
    let minHeight: CGFloat = 533
    let maxWidth: CGFloat = 1400
    let maxHeight: CGFloat = 4000
    
    // Map node
    static var map: SKTileMapNode!
    
    // The bottom view controller
    let bottomSheetVC = ScrollableBottomSheetViewController()
    
    // Map control buttons
    var mapButtonsView: MapButtonsView!
    
    // The current location node
    static var locationNode: SKSpriteNode!
    
    // The background node
    static var backgroundNode: SKSpriteNode!
    
    // Booleans for the visuals controlled by the map buttons
    static var shouldCenterMap = false
    static var shouldRotateMap = false
    
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let oldFrame = view.frame
        view = SKView(frame: oldFrame)
        view.backgroundColor = .white
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "MapTilemapScene") {
                MapViewController.scene = scene
                
                // Initialise the static map
                MapViewController.map = scene.childNode(withName: "tileMap") as? SKTileMapNode
                MapViewController.map.zPosition = 0
                
                // Move backgroundNode (image map) under the tile map
                MapViewController.backgroundNode = scene.childNode(withName: "backgroundNode") as? SKSpriteNode
                MapViewController.backgroundNode?.zPosition = -1
                
                // Init the location node
                MapViewController.locationNode = scene.childNode(withName: "locationNode") as? SKSpriteNode
                
                // Set the scale mode to scale to fit the window
                MapViewController.scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(MapViewController.scene)
                view.ignoresSiblingOrder = true
                
                // Add the camera node
                let cameraNode = SKCameraNode()
                MapViewController.scene.addChild(cameraNode)
                MapViewController.scene.camera = cameraNode
                
                // Add the gesture to the view
                self.addGesturesRecognisers()
            }
        }
        
        // Init the core model
        initModel()
        
        // Add the map control buttons
        addMapButtonsView()
        
        // Add the bottom view
        addBottomSheetView()
        
        // Activate the tiles that have access points stored in core data
        MapViewController.resetTiles()
        
        // Set the delegate for location manager to self for the bearing data
        locationManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            RGSharedDataManager.disconnect()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? AdminViewController {
            destinationVC.modalPresentationStyle = .overFullScreen
            destinationVC.parentVC = self
        }
    }
    
    /**
     Initialise the model.
     */
    fileprivate func initModel() {
        // Connect to device that scans for Wi-Fi APs
        RGSharedDataManager.connect(to: "0x12AB")
        
        // Set the number of rows and columns for the map logic
        RGSharedDataManager.numberOfRows = MapViewController.map.numberOfRows
        RGSharedDataManager.numberOfColumns = MapViewController.map.numberOfRows
        
        // Set the floor level to 6
        RGSharedDataManager.floorLevel = 6
        RGSharedDataManager.setFloor(level: 6)
        RGSharedDataManager.mapImage = UIImagePNGRepresentation(UIImage(named: "bh_6th")!) as NSData?
        
        // Initiliase data model in CoreData
        RGSharedDataManager.initData()
        
        // Set the app mode to dev to display log
        RGSharedDataManager.appMode = .dev
    }
    
    /**
     Add gesture recognisers to the scene.
    */
    fileprivate func addGesturesRecognisers() {
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(MapViewController.handlePinch))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        // Add pan gesture for movement
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.handlePan))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        // Add tap gesture for dev/client
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.handleTapFrom))
        tapGesture.numberOfTapsRequired = 2
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    /**
     Initialises the bottom view and adds it to the view.
    */
    fileprivate func addBottomSheetView() {
        self.addChildViewController(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParentViewController: self)
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: view.frame.width, height: view.frame.height)
        bottomSheetVC.updatePickerData()
        bottomSheetVC.updateTableData()
    }
    
    /**
     Initialises the control buttons for the map and adds it to the view.
    */
    fileprivate func addMapButtonsView() {
        // Add the control buttons
        mapButtonsView = MapButtonsView(frame: CGRect(x: view.bounds.maxX - 60, y: view.bounds.minY + 60, width: 40, height: 131))
        mapButtonsView.backgroundColor = .clear
        mapButtonsView.parentVC = self
        self.view.addSubview(mapButtonsView)
    }
    
    /**
     Set tile blue as "active"
     
     - parameter column: The column of the tile.
     - parameter row: The row of the tile.
     - parameter type: The group type of the tile (as expressed by the RGTileType class)
     */
    static func setTileColor(column: Int, row: Int, type: RGTileType) {
        var tileGroup: SKTileGroup!
        
        switch type {
        case .sample:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "sample"})
            }
        case .saved:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "saved"})
            }
        case .location:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "location"})
            }
        case .none:
            do {
                tileGroup = SKTileGroup.empty()
            }
        }
        
        MapViewController.map.setTileGroup(tileGroup, forColumn: column, row: row)
    }
    
    /**
     Display tiles for the developer.
    */
    fileprivate static func displayDevTiles(column: Int, row: Int) {
        if RGSharedDataManager.tileHasData(column: column, row: row) {
            MapViewController.setTileColor(column: column, row: row, type: .saved)
        } else {
            MapViewController.setTileColor(column: column, row: row, type: .sample)
        }
    }
    
    /**
     Reset all tiles to their color
     */
    static func resetTiles() {
        for row in 0...MapViewController.map.numberOfRows {
            for column in 0...MapViewController.map.numberOfColumns {
                if RGSharedDataManager.appMode == .dev {
                    displayDevTiles(column: column, row: row)
                }
            }
        }
    }
    
    /**
     A method that shows a node on the map that represents the location of the device.
     
     - parameter currentLocation: A pair that represents the row and column of the position.
    */
    static func showCurrentLocation(_ currentLocation: (Int, Int)) {
        // If the locationNode is hidden, change alpha to 1 to display it
        if locationNode.alpha < 1 {
            locationNode.alpha = 1
        }
        
        // Get the location of the center of the tile that represents the current location
        let location = MapViewController.map.centerOfTile(atColumn: currentLocation.1, row: currentLocation.0)
        
        // Animate moving from the last location to the new position in the number of seconds
        let move = SKAction.move(to: location, duration: 0.3)
        
        // Add ease out effect
        move.timingMode = .easeInEaseOut
        
        // Run the animation
        locationNode.run(move, withKey: "moving")
        
        // Center the map if option is activated
        if shouldCenterMap {
            centerToLocation()
        }
    }
    
    /**
     A method that displays development logs to the view and console.
     
     - parameter data: String containing data to be displayed.
    */
    static func devLog(data: String) {
        if RGSharedDataManager.appMode == .dev {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSSS"
            
            debugPrint("\(formatter.string(from: date)) \(data)")
            prodLog("\(formatter.string(from: date)) \(data)")
        }
    }
    
    /**
     Displays as a status label the current log for production mode.
     
     - parameter data: String containing data to be displayed.
    */
    static func prodLog(_ data: String) {
        ScrollableBottomSheetViewController.status = data
    }
    
    /**
     Centers the camera view to the current location of the device.
    */
    static func centerToLocation() {
        let tileLocation = RGLocalisation.currentLocation
        
        // If no location was found stop
        if tileLocation == (-1, -1) { return }
        
        // Get the new position of the camera node for the current location
        let newPosition = map.centerOfTile(atColumn: tileLocation.1, row: tileLocation.0)
        
        // Animate moving from the last location to the new position in the number of seconds
        let move = SKAction.move(to: newPosition, duration: 0.3)
        
        // Add ease out effect
        move.timingMode = .easeOut
        
        // Run the animation
        MapViewController.scene.camera?.run(move, withKey: "localising")
    }
    
    /**
     Resets the camera rotation to initial angle (0) and stops the *shouldRotate* event.
     */
    static func resetCameraRotation() {
        MapViewController.shouldRotateMap = false
        let rotation = SKAction.rotate(toAngle: 0, duration: 0.3, shortestUnitArc: true)
        rotation.timingMode = .linear
        MapViewController.scene.camera?.run(rotation, withKey: "moving")
    }
}

