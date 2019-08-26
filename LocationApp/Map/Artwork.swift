//
//  Artwork.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/9/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import MapKit
import Contacts

//Artwork class contains properties and methods for displaying the pin color & info.

class Artwork: NSObject, MKAnnotation {
    
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let cycleDate: String?
    let active: Int64
    let collected: Int64?
    let getcycleDate = recordsUpdate()
    
    
    init(title: String, locDescription: String, active: Int64, coordinate: CLLocationCoordinate2D, cycleDate: String?, collected: Int64?) {
        self.title = title
        self.subtitle = locDescription
        self.coordinate = coordinate
        self.cycleDate = cycleDate
        self.active = active
        self.collected = collected
        super.init()
    }
    
    
    var markerTintColor: UIColor {
        //change to cycledate
        let cycle = getcycleDate.generateCycleDate() //fetch the current cycle
        let color:UIColor
        
        //active location
        if self.active == 1 {
            
            //deployed dosimeter
            if self.collected == 0 {
                //current cycle (stop)
                if self.cycleDate == cycle { color = .red }
                //any other cycle (exchange)
                else { color = .green }
            }
            //no dosimeter (deploy)
            else { color = .orange }
        }
            
        //inactive location
        else {
            
            //deployed dosimeter
            if self.collected == 0 {
                //current cycle (stop)
                if self.cycleDate == cycle { color = .purple }
                //any other cycle (collect)
                else { color = .blue }
            }
            //no dosimeter
            else { color = .yellow }
        }
        
        return color
        
    } //end markerTintColor
    
}
