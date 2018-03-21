//
//  Util.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 07/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import UIKit

/**
 Commands available from the search bar.
 */
enum SecretCommands: String {
    case switchToDevMode = "chamber of secrets"
    case switchToProdMode = "cowboy"
}

/**
 Commands available for the external bluetooth device.
 */
enum RGCommands: String {
    case stopPi = "sudo shutdown now"
    case updateServer = "cd /root/navigate-server && git pull && forever restartall"
    case restartServer = "cd /root/navigate-server && forever restartall"
}

/**
 An enum used for tile types.
 */
enum RGTileType {
    case saved
    case sample
    case location
    case none
}

/**
 An enum used to define the application mode.
 */
enum AppMode {
    case dev
    case prod
}

// Credits: https://www.raywenderlich.com/80818/operator-overloading-in-swift-tutorial
extension CGPoint {
    public static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    public static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    public static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    public static func / (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x / right.x, y: left.y / right.y)
    }
    
    public static func * (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x * right.x, y: left.y * right.y)
    }
}

// Credits: https://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
    
    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
}

// Credits: https://medium.com/swiftly-swift/how-to-build-a-compass-app-in-swift-2b6647ae25e8
extension Double {
    var toRadians: Double { return self * .pi / 180 }
    var toDegrees: Double { return self * 180 / .pi }
}

extension CGFloat {
    var toRadians: CGFloat { return self * .pi / 180 }
    var toDegrees: CGFloat { return self * 180 / .pi }
}

extension UIViewController {
    func presentAlert(title: String, message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: completion)
    }
}
