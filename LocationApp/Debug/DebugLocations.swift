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
    var fetchedRecordCount: Int
    var description: String?
    var presentingViewController: UIViewController?

    private init() {
        fetchedRecordCount = 0
        startTime = nil
        endTime = nil
        description = nil
    }
    
    func start(presentingViewController: UIViewController,  description: String) {
        self.presentingViewController = presentingViewController
        self.description = description
        self.startTime = Date()
        self.endTime = nil
        self.fetchedRecordCount = 0
    }
    
    func finish() {
        self.endTime = Date()
        showDebugStats()
    }
 
    func didFetchRecord() {
        fetchedRecordCount += 1
    }
    
    func showDebugStats() {
        guard let presentingViewController = self.presentingViewController,
        let startTime = self.startTime, let endTime = self.endTime else {
            return
        }
        
        DispatchQueue.main.async {
            let elapsed = endTime.timeIntervalSince(startTime)
            let message = "Loaded \(self.fetchedRecordCount) records in \(elapsed) seconds: "
            let alert = UIAlertController(title: "\(String(describing: self.description!))",
                                          message: message,
                preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancel)
            presentingViewController.present(alert, animated: true, completion: nil)
        }
    }
 }
