//
//  Queries.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/30/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit


//Potentially a place to move all queries and consolidate/shrink
//some queries in their respective view controllers.

class Queries {
        
    func getCollectedNum() -> Int {
        let locations = container.locations
        let cycleDate = RecordsUpdate.generateCycleDate()
        let priorCycleDate = RecordsUpdate.generatePriorCycleDate(cycleDate: cycleDate)
        return locations.count(by: { $0.collectedFlag == 1 && $0.active == 1 && $0.cycleDate == priorCycleDate})
    }
    

    
    func getNotCollectedNum() -> Int {
        let locations = container.locations
        let cycleDate = RecordsUpdate.generateCycleDate()
        let priorCycleDate = RecordsUpdate.generatePriorCycleDate(cycleDate: cycleDate)
        return locations.count(by: { $0.collectedFlag == 0 && $0.active == 1 && $0.cycleDate == priorCycleDate})
    }
    


} //end class
