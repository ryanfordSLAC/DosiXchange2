//
//  classRecordsUpdate.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 11/30/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit
import UIKit
import CoreLocation

//Initialize other classes

class RecordsUpdate: UIViewController {
      
    //MARK:  Cycle Date
    static func generateCycleDate() -> String {
        return getLastCycles(cycles: 1)[0]
    }
    
    //MARK:  Prior Cycle Date
    static func generatePriorCycleDate(cycleDate: String) -> String {
        
        let year = Int64(cycleDate.suffix(4))!
        
        let lastYear:Int64 = year - 1
        
        switch cycleDate.first {
            
        case "1":                 //7 and subtract 1 from year
            
            return "7-1-\(String(describing: lastYear))"
            
        case "7":                 //1 and same year
            
            return "1-1-\(String(describing: year))"
            
        default:
            
            return "Prior Cycle Date Error"
            
        }
        
    }
    
    static func getLastCycles(cycles: Int) -> [String] {
        var date = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.month = components.month! < 7 ? 1 : 7
        date = calendar.date(from: components)!
        
        var result = ["\(components.month!)-1-\(components.year!)"]
        if(cycles > 1){
            for _ in 2...cycles {
                date = calendar.date(byAdding: Calendar.Component.month, value: -6, to: date)!
                components = calendar.dateComponents([.year, .month], from: date)
                result.append("\(components.month!)-1-\(components.year!)")
            }
        }
        return result
    }

} // end class
