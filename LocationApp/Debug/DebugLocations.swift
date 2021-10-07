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
    var presentingViewController: UIViewController?

    init() {
        didFetchRecordsFromCloudKitCount = 0
        startTime = nil
        endTime = nil
        description = nil
    }
    
    func start(presentingViewController: UIViewController,  description: String) {
        self.presentingViewController = presentingViewController
        self.description = description
        self.startTime = Date()
        self.endTime = nil
        self.didFetchRecordsFromCloudKitCount = 0
    }
    
    func finish() {
        self.endTime = Date()
        showDebugStats()
    }
 
    func didFetchRecordsFromCloudKit(_ count: Int = 1) {
        didFetchRecordsFromCloudKitCount += count
    }
    
    func showDebugStats() {
        guard let presentingViewController = self.presentingViewController,
        let startTime = self.startTime, let endTime = self.endTime else {
            return
        }
        
        DispatchQueue.main.async {
            let elapsed = endTime.timeIntervalSince(startTime)
            let elapsedString = self.stringFromTimeInterval(interval: elapsed)
            let message = "Fetched \(self.didFetchRecordsFromCloudKitCount) records in \(elapsedString) seconds."
            print(message)
            let alert = UIAlertController(title: "Debug Location View", message: message,
                preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancel)
            presentingViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func logMessage(_ message: String) {
        print("DebugLocatons: \(message)")
    }
    
    func stringFromTimeInterval(interval:TimeInterval) -> NSString {
        let ti = NSInteger(interval)
        let ms = ti * 1000
        print("time interval = \(ms) ms")
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        return NSString(format: "%0.2d:%0.2d:%0.2d.%0.2d",hours,minutes,seconds,(ms % 1000))
    }
}
