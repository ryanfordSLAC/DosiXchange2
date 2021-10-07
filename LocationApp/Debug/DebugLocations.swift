//
//  DebugLocations.swift
//  LocationApp
//
//  Created by Lintlop, Matt David on 10/6/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import UIKit


class DebugLocations {
    
    static let shared = DebugLocations()
    var startTime: Date?
    var endTime: Date?
    var didFetchRecordsFromCloudKitCount: Int
    var description: String?
    var elapsed: DateInterval?
    let presentingViewController = UIViewController()

    init() {
        didFetchRecordsFromCloudKitCount = 0
        startTime = nil
        endTime = nil
        description = nil
    }
    
    func start(_ description: String) {
        self.description = description
        self.startTime = Date()
        self.endTime = nil
        self.didFetchRecordsFromCloudKitCount = 0
    }
    
    func finish() {
        self.endTime = Date()
        if let startTime = self.startTime {
            self.elapsed = DateInterval(start: startTime, end: endTime!)
        }
        showDebugStats()
    }
 
    func didFetchRecordsFromCloudKit(_ count: Int = 1) {
        didFetchRecordsFromCloudKitCount += count
    }
    
    func showDebugStats() {
        DispatchQueue.main.async {
            if presentingViewController == nil {
                presentingViewController = UIViewController()
            }
            let alert = UIAlertController(title: "Debug Location View", message: "Fetched \(self.didFetchRecordsFromCloudKitCount) records in \(self.elapsed) seconds.",
                preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.presentingViewController!.present(alert, animated: true, completion: nil)
        }
    }
    
    func logMessage(_ message: String) {
        print("DebugLocatons: \(message)")
    }
}
