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
    
    var cacheCycleDateString: String?           // cache cycle date string
    var recordNames: [String]?                  // list of all cache record nanes
    var recordsCache: [LocationCacheItem]?      // list of al cache records

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
        savedCache()
    }
    
    // Load the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
    func loadCache() throws {
        print("Loading the Locations Cache")
        let path = cacheFilePath()
    }

    // Save the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
     func savedCache() {
         DispatchQueue.global().async {
             print("Saving the Locations Cache")
             guard let cacheData = try? JSONEncoder().encode(self) else {
                 print("Error encoding LocationCache data")
                 return
             }
             let cacheFileURL = URL(fileURLWithPath: self.cacheFilePath())
             guard let file = try? cacheData.write(to: cacheFileURL) else {
                 return
             }
             print("Saved \(self.recordNames!.count) IDs & \(self.recordsCache!.count) records")
         }
    }

    
    // Path to the locations cache file
    func cacheFilePath() -> String {
        return "~/Library/Cache/LocationsCache.txt"
    }
}
