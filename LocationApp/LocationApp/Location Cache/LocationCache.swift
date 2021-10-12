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
    
    var cacheCycleDateString: String?                              // cache cycle date string
   
    // cache records dictionary. [key = CloudKit  Record ID, value = LocationCacheItem]
    var locationItemCacheDict: [String: LocationCacheItem]?
 
    // location items in same order as sorted CloudKit records
    var sortedLocationCacheItems: [LocationCacheItem]?
    
    private init() {
   }
    
    func didFetchRecords(_ records: [CKRecord]) {
        print("Did Fetch \(records.count) records")
    }
    
    func didStartFetchingRecords() {
        print("Started Fetching records")
    }
    
    func didFinishFetchingRecords(_ records: [CKRecord]) {
        print("Finshed Fetching \(records.count) records")
        DispatchQueue.global().async {
            self.makeCache(withRecords: records)
            self.saveCache()
      }
    }
    
    func makeCache(withRecords records: [CKRecord]) {
        locationItemCacheDict = [String: LocationCacheItem]()
        sortedLocationCacheItems = [LocationCacheItem]()
        
        for record in records {
            if let locationCacheItem = LocationCacheItem(withRecord: record) {
                sortedLocationCacheItems!.append(locationCacheItem)
                locationItemCacheDict![record.recordID.recordName] = locationCacheItem
            }
        }
    }
    
    // Test if the locations cache file exists.
    func locationCacheFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: cacheFilePath())
    }
    
    // Load the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
    func loadCache() {
        let path = self.cacheFilePath()
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        DispatchQueue.global().async {
            print("Loading the Locations Cache")
            
            
            let startTime = Date()      // TESTING
            
            
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
            
            // TESTING
            let endTime = Date()
            let elapsed = endTime.timeIntervalSince(startTime)
            if let recordNames = self.locationItemCacheDict?.keys {
                print("*** Loaded \(recordNames.count) LocationCacheItems in \(elapsed) seconds")
            }
           
            LocationCache.shared = locationsCache
        }
    }

    // Save the dosimeter CloudKit records from disk.
    // Throws a LocationCacheError is a required record field is nil.
    func saveCache() {
        
        let startTime = Date()          // testing
        
        guard let count = self.locationItemCacheDict?.keys.count, (count > 0) else {
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
        
        
        // TESTING
        if let recordNames = self.locationItemCacheDict?.keys {
            let endTime = Date()          // testing
            let elapsed = endTime.timeIntervalSince(startTime)
            print("*** Saved \(recordNames.count) LocationItems in \(elapsed) seconds")
        }
        
        
    }
    
    // Path to the locations cache file
    func cacheFilePath() -> String {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDirectory.appendingPathComponent("LocationsCache.txt")
        print("Cache file path = \(url.path).")
        return url.path
    }
}
