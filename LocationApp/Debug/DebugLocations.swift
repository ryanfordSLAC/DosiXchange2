//
//  DebugLocations.swift
//  LocationApp
//
//  Created by Lintlop, Matt David on 10/6/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation

class DebugLocations {
    
    var startTime: Double?
    var endTime: Double?
    var fetchedRecordsCount: Int
    let descreption: String
    
    init(descreption: String) {
        self.descreption = descreption
        self.fetchedRecordsCount = 0
        startTime = nil
        endTime = nil
    }
    
}
