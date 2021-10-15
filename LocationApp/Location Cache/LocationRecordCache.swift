//
//  LocationRecordCache.swift
//  LocationApp
//
//  Created by Matt Lintlop on 10/10/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

enum LocationRecordCacheError: Error {
    case recordDataError                                        // a dosimeter record fied is empty (nil)
}

class LocationRecordCache: Codable {
    
    static var fetchedLocationRecords: [CKRecord]?
    
    static var shared = LocationRecordCache()
    
    var version = 1                                             // location cache file version #
    
    var cacheCycleDateString: String?                           // cache cycle date string
   
    // cache records dictionary. [dictionary key = Location record name,
    // dictionary value = list of cached location records in same order as
    // returned by the CloudKit fetch
    var locationItemCacheDict: [String: [LocationRecordCacheItem]]?
    
    private init() {
        deleteLocationRecordCache()       // delete the cache file (TESTING)
   }
    
    func didStartFetchingRecords() {
        locationItemCacheDict = [String: [LocationRecordCacheItem]]()
   }
    
    func didFetchLocationRecord(_ locationRecord: CKRecord) {
        // process the fetched CloudKit records in the background and
        // initialize  the cached location record items.
        DispatchQueue.global().async {
            if let locationRecordCacheItem = LocationRecordCacheItem(withRecord: locationRecord) {
                if var locationItemRecords = self.locationItemCacheDict?[locationRecord.recordID.recordName] {
                    locationItemRecords.append(locationRecordCacheItem)
                }
                else {
                    self.locationItemCacheDict![locationRecord.recordID.recordName] = [locationRecordCacheItem]
                }
            }
        }
    }
    
    func didFinishFetchingRecords(_ records: [CKRecord]) {
        DispatchQueue.global().async {
            self.saveLocationRecordCache()
      }
    }
    
    // Test if the locations cache file exists.
    func doesLocationRecordCacheExist() -> Bool {
        return FileManager.default.fileExists(atPath: pathToLocationRecordCache())
    }
    
    func deleteLocationRecordCache() {
        let path = self.pathToLocationRecordCache()
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        try? FileManager.default.removeItem(atPath: path)
     }
    
    // Load the cached location records cache file
    func loadLocationsCacheFile(completion: @escaping (LocationRecordCache?) -> Void) {
        let path = self.pathToLocationRecordCache()
        guard FileManager.default.fileExists(atPath: path) else {
            completion(nil)
            return
        }
        DispatchQueue.global().async {
            let cacheFileURL = URL(fileURLWithPath: path)
            guard let cacheData = try? Data(contentsOf: cacheFileURL) else {
                print("Error loading LocationRecordCache data")     // TESTING
                completion(nil)
                return
            }
            guard let locationsCache = try? JSONDecoder().decode(LocationRecordCache.self,
                                                                 from: cacheData) else {
                print("Error decoding LocationRecordCache from data")    // TESTING
                completion(nil)
                return
            }
            
            if let locationsDict = locationsCache.locationItemCacheDict {
                print("Loaded locations cache file: \(locationsDict.keys.count) LocationRecordCacheItem records")    // TESTING
 
                if locationsDict.keys.count > 0 {
                    LocationRecordCache.shared = locationsCache
                    completion(locationsCache)
                }
             }
            else {
                completion(nil)
            }
        }
    }

    func fetchLocationRecordsFromCache(withRecordNames: [String]?,
                                       processRecord: @escaping (LocationRecordCacheItem) -> Void,
                                       completion: @escaping (Bool) -> Void) {
        
        guard let locationsCacheDict = self.locationItemCacheDict else {
            print("Error: locationItemCacheDict = nil in LocationRecordCache.fetchLocationRecords()")   // TESTING
            completion(false)
            return
        }
        print("Loaded \(locationsCacheDict.keys.count) LocationRecordCacheItem records")

         DispatchQueue.global().async {
             
             for locationQRCode in locationsCacheDict.keys {
                 if let cachedLocationRecordItems = locationsCacheDict[locationQRCode] {
                     for locationRecordCacheItem in cachedLocationRecordItems {
                         DebugLocations.shared.didFetchRecord()      // TESTING
                         
                         // call the process location callback function
                         processRecord(locationRecordCacheItem)
                     }
                 }
             }

            // call the completion function with the new Locations cache
            completion(true)
        }
    }

    // Save the dosimeter CloudKit records from disk.
    // Throws a DosimeterRecordCacheError is a required record field is nil.
    func saveLocationRecordCache() {
        guard let count = self.locationItemCacheDict?.keys.count, (count > 0) else {
             return
         }
        guard let cacheData = try? JSONEncoder().encode(self) else {
            print("Error encoding DosimeterRecordCache data")
            return
        }
        
        let cacheFileURL = URL(fileURLWithPath: self.pathToLocationRecordCache())
        try? FileManager.default.removeItem(at: cacheFileURL)
        guard let _ = try? cacheData.write(to: cacheFileURL) else {
            return
        }
    }
    
    // Path to the locations cache file
    func pathToLocationRecordCache() -> String {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDirectory.appendingPathComponent("LocationsCache.txt")
        return url.path
    }
}
