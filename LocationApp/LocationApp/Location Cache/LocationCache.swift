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
    
    static var shared = LocationCache()
    
    var cacheCycleDateString: String?           // cache cycle date string
    var recordNames: [String]?                  // list of all cache record nanes
    var recordsCache: [LocationCacheItem]?      // list of al cache records

    private init() {
   }
    
    func didFetchRecords(_ records: [CKRecord]) {
        print("Did Fetch \(records.count) records")
    }
    
    func didStartFetchingRecords() {
        print("Started Fetching records")
        recordNames = [String]()
        recordsCache = [LocationCacheItem]()
    }
    
    func didFinishFetchingRecords(_ records: [CKRecord]) {
        print("Finshed Fetching \(records.count) records")
        DispatchQueue.global().async {
            self.makeCache(withRecords: records)
            self.saveCache()
          
            try? self.loadCache()
      }
    }
    
    func makeCache(withRecords records: [CKRecord]) {
        self.recordsCache = [LocationCacheItem]()
        self.recordNames = [String]()
        for record in records {
            self.recordNames?.append(record.recordID.recordName)
            if let locationCacheItem = LocationCacheItem(withRecord: record) {
                self.recordsCache?.append(locationCacheItem)
            }
        }
    }
    
    // Load the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
    func loadCache() throws {
        let path = self.cacheFilePath()
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        DispatchQueue.global().async {
            print("Loading the Locations Cache")
            let startTime = Date()
            let cacheFileURL = URL(fileURLWithPath: path)
            guard let cacheData = try? Data(contentsOf: cacheFileURL) else {
                print("Error loading LocationCache data")
                return
            }
            guard let locationsCache = try? JSONDecoder().decode(LocationCache.self,
                                                                 from: cacheData) else {
                print("Error decoding LocationCache from data")
                return
            }
            let endTime = Date()
            let elapsed = endTime.timeIntervalSince(startTime)
  
            print("Loaded \(locationsCache.recordNames!.count) IDs & \(locationsCache.recordsCache!.count) records")
            print("Loaded LocationCache in \(elapsed) seconds")
 
            LocationCache.shared = locationsCache
        }
    }

    // Save the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
    func saveCache() {
         guard let count = self.recordsCache?.count, (count > 0) else {
             return
         }
        print("Saving the Locations Cache")
        guard let cacheData = try? JSONEncoder().encode(self) else {
            print("Error encoding LocationCache data")
            return
        }
        
        let cacheFileURL = URL(fileURLWithPath: self.cacheFilePath())
        try? FileManager.default.removeItem(at: cacheFileURL)
        guard let file = try? cacheData.write(to: cacheFileURL) else {
            return
        }
        print("Saved \(self.recordNames!.count) IDs & \(self.recordsCache!.count) records")
    }
    
    // Path to the locations cache file
    func cacheFilePath() -> String {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDirectory.appendingPathComponent("LocationsCache.txt")
        print("Cache file path = \(url.path).")
        return url.path
    }
}
