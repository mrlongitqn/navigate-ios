//
//  RGSharedDataManager.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

class RGSharedDataManager: NSObject {
    
    // App mode
    static var appMode: AppMode = .prod {
        didSet {
            MapViewController.resetView(for: appMode)
        }
    }
    
    // Room information
    static var selectedRoom: String?
    
    // Floor information
    static var floor: Floor! {
        didSet {
            selectedRoom = ""
            
            if floor.tiles?.count == 0 {
                createTiles(for: floor)
            }
            
            MapViewController.resetView(for: appMode)
            MapViewController.changeMap(to: floor.image)
        }
    }
    
    // Map sizes
    static var numberOfRows: Int!
    static var numberOfColumns: Int!
    
    // Bluetooth Low Energy service
    static let ble = BLEService()
    
    // Detect location on changing value of the json
    static var jsonData: Any! {
        didSet {        
            RGLocalisation.detectLocation()
        }
    }
    
    // The tile size in meters
    static var tileLength: Float = 3
    
    // The selected tileType
    static var tileType: CDTileType?
    
    /**
     Init data for when the application is open for the first time.
     
     - parameter floorLevel: The level of the floor.
     - parameter mapImage: The image of the map for the floor level.
     */
    static func initData(floorLevel: Int, mapImage: NSData) {
        do {
            // Get number of floors from CoreData
            let numberOfFloors = try PersistenceService.context.count(for: NSFetchRequest(entityName: "Floor"))
            
            // If there are no floors, create the initial one
            if numberOfFloors == 0 {
                // Create a new floor
                let _ = addFloor(level: floorLevel, mapImage: mapImage)
                setFloor(level: floorLevel)
                
                // Set the app mode to dev to display log and develop app
                RGSharedDataManager.appMode = .dev
            } else {
                debugPrint("Data already created. Setting floor to default \(floorLevel).")
                setFloor(level: floorLevel)
                
                // Get the data from the cloud
                getFromCloud()
            }
        } catch {
            debugPrint("Error in Floor Count fetchRequest")
        }
    }
    
    static func encodeData() -> String? {
        let encodedData = try? JSONEncoder().encode(floor).base64EncodedString(options: .endLineWithLineFeed)
        return encodedData
    }
    
    static func decodeData() {
        DispatchQueue.main.async {
            MapViewController.devLog(data: "Error in getting data from the cloud.")
        }
        
        return
    }
}
