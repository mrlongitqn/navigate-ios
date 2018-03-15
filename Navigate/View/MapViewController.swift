//
//  MapViewController
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 01/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SpriteKit

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // The scene that holds the map nodes
    var scene: SKScene!
    
    // Developer label to display information
    fileprivate static var devLabel: UILabel!
    
    // Vars for gesture recognisers
    var lastScale: CGFloat = 0.0
    var previousLocation = CGPoint.zero
    
    static var map: SKTileMapNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initModel()
        
        let oldFrame = view.frame
        view = SKView(frame: oldFrame)
        view.backgroundColor = .white
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "MapTilemapScene") {
                self.scene = scene
                
                MapViewController.map = scene.childNode(withName: "tileMap") as? SKTileMapNode
                
                // Set the scale mode to scale to fit the window
                self.scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(self.scene)
                view.ignoresSiblingOrder = true
                
                // Add the camera node
                let cameraNode = SKCameraNode()
                self.scene.addChild(cameraNode)
                self.scene.camera = cameraNode
                
                // Add the gesture to the view
                self.addGesturesRecognisers()
            }
        }
        
        // Add the developer label to show different events
        addDevLabel()
        
        // Activate the tiles that have access points stored in core data
        MapViewController.activateTiles()
        
        addBottomSheetView()
    }
    
    /**
     Initialise the model.
     */
    fileprivate func initModel() {
        // Connect to device that scans for Wi-Fi APs
        RGSharedDataManager.connect(to: "0x12AB")
        
        // Set the floor level
        RGSharedDataManager.setFloor(level: 6)
        
        // Set the app mode to dev to display log
        RGSharedDataManager.appMode = .dev
    }
    
    fileprivate func addGesturesRecognisers() {
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(MapViewController.handlePinch))
        view.addGestureRecognizer(pinchGesture)
        pinchGesture.delegate = self
        
        // Add pan gesture for movement
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.handlePan))
        view.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        // Add tap gesture for dev/client
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.handleTapFrom))
        tapGesture.numberOfTapsRequired = 2
        tapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
    }
    
    /**
     Construct and add development label to the view.
     */
    fileprivate func addDevLabel() {
        if RGSharedDataManager.appMode == .dev {
            MapViewController.devLabel = UILabel(frame: CGRect(x: 0, y: view.frame.height - 100, width: view.frame.width, height: 100))
            MapViewController.devLabel.backgroundColor = .black
            MapViewController.devLabel.text = "#"
            MapViewController.devLabel.numberOfLines = 4
            MapViewController.devLabel.textColor = .white
            MapViewController.devLabel.textAlignment = .center
            view.addSubview(MapViewController.devLabel)
        }
    }
    
    /**
     Set tile blue as "active"
     
     - parameter column: The column of the tile.
     - parameter row: The row of the tile.
     - parameter color: The color that can be .cyan or .purple
     */
    static func setTileColor(column: Int, row: Int, color: TileColor) {
        var tileGroup: SKTileGroup!
        
        switch color {
        case .cyan:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "cyan_box"})
            }
        case .purple:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "purple_box"})
            }
        case .green:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "green_box"})
            }
        case .grey:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "grey_box"})
            }
        }
        MapViewController.map.setTileGroup(tileGroup, forColumn: column, row: row)
    }
    
    /**
     Display blue tile if it contains data.
     */
    static func activateTiles() {
        for row in 0...MapViewController.map.numberOfRows {
            for column in 0...MapViewController.map.numberOfColumns {
                if RGSharedDataManager.accessPointHasData(column: column, row: row) {
                    MapViewController.setTileColor(column: column, row: row, color: .cyan)
                } else {
                    MapViewController.setTileColor(column: column, row: row, color: .grey)
                }
            }
        }
    }
    
    /**
     Disconnect the bluetooth device and stop it on shaking device.
     */
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            RGSharedDataManager.disconnect()
        }
    }
    
    static func devLog(data: String) {
        if RGSharedDataManager.appMode == .dev {
            debugPrint(data)
            devLabel.text = data
        }
    }
    
    // https://stackoverflow.com/questions/37967555/how-to-mimic-ios-10-maps-bottom-sheet
    fileprivate func addBottomSheetView() {
        // 1 - Init bottomSheetVC
        let bottomSheetVC = SheetViewController()
        
        // 2 - Add bottomSheetVC as a child view
        self.addChildViewController(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParentViewController: self)
        
        // 3 - Adjust bottomSheet frame and initial position.
        let height = view.frame.height
        let width  = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
    }
}

