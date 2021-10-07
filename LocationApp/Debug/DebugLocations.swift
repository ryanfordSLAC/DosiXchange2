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

    var presentingViewController: UIViewController?
    
    var startTime: Date?
    var endTime: Date?
    var didFetchRecordsFromCloudKitCount: Int
    var descreption: String?
    var elapsed: DateInterval?
    
    init() {
        didFetchRecordsFromCloudKitCount = 0
        startTime = nil
        endTime = nil
        descreption = nil
    }
    
    func start(descreption: String) {
        self.descreption = descreption
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
        print("DebugLocation did fetch \(count) records")
    }
    
    func showDebugStats() {
        if presentingViewController == nil {
            presentingViewController = UIViewController()
        }
        DispatchQueue.main.async {
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
