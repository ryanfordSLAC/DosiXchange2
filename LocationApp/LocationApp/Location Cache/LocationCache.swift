//
//  LocationCache.swift
//  LocationApp
//
//  Created by Matt Lintlop on 10/10/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

enum LocationCacheError: Error {
    case recordDataError                // a dosimeter record fied is nil
}

class LocationCache: Codable {
    
    static let shared = LocationCache()
    
    var recordNames: [String]?     //
    var recordsCache: [LocationCacheItem]?     //

    private init() {
        recordNames = [String]()
        recordsCache = [LocationCacheItem]()
   }
    
    func didFetchRecords(_ records: [CKRecord]) {
        print("Did Fetch \(records.count) records")

        for record in records {
            self.recordNames!.append(record.recordID.recordName)
        }
    }
    
    func didStartFetchingRecords() {
        print("Started Fetching records")
    }
    
    func didFinishFetchingRecords(_ records: [CKRecord]) {
        print("Finshed Fetching \(records.count) records")
    }
    
    // Load the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
    func loadCache() throws {
        
    }

    // Save the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
     func savedCache() throws {
        
    }
}
