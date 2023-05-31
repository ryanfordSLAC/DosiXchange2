//
//  Slac.swift
//  LocationApp
//
//  Created by Lakatos Attila on 2023. 05. 31..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import CoreLocation

class Slac {
    static let lowerLeftCorner = CLLocation(latitude: 37.40759541613257, longitude: -122.24470618868045)
    static let upperRightCorner = CLLocation(latitude: 37.42395640703747, longitude: -122.19080451703441)
    static let defaultCoordinates = CLLocation(latitude: 37.418086519270204, longitude: -122.21908654871143)
    
    static func isLocationInRange(location: CLLocation) -> Bool{
        return ((location.coordinate.latitude >= lowerLeftCorner.coordinate.latitude) && (location.coordinate.latitude <= upperRightCorner.coordinate.latitude)) && (( (location.coordinate.longitude >= lowerLeftCorner.coordinate.longitude) && location.coordinate.longitude <= upperRightCorner.coordinate.longitude))
    }
}
