//
//  DebugLocations.swift
//  LocationApp
//
//  Created by Lintlop, Matt David on 10/6/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation

class DebugLocations {
    
    var startTime: Date?
    var endTime: Date?
    var fetchedRecordsCount: Int
    let descreption: String
    var elapsed: DateInterval?
    
    init(descreption: String) {
        self.descreption = descreption
        self.fetchedRecordsCount = 0
        startTime = nil
        endTime = nil
    }
    
    func start() {
        self.startTime = Date()
        self.endTime = nil
        self.fetchedRecordsCount = 0
    }
    
    func finish() {
        self.endTime = Date()
        if let startTime = self.startTime {
            self.elapsed = DateInterval(start: startTime, end: endTime!)
        }
    }
 
    func fetchedRecords(_ count: Int = 1) {
        fetchedRecordsCount += count
    }
    func showDebugStats() {
        DispatchQueue.main.async {
            // TODO
        }
    }
}
