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
    
    static private var fetchedLocationRecords: [CKRecord]?
    static private let group = DispatchGroup()
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
        print(">> LocationRecordCache didStartFetchingRecords")     // TESTING
   }
    
    func didFetchLocationRecord(_ locationRecord: CKRecord) {
        print(">> LocationRecordCache didFetchLocationRecord")     // TESTING

        // process the fetched CloudKit records in the background and
        // initialize  the cached location record items.
        DispatchQueue.global().async {
            LocationRecordCache.group.wait()
            LocationRecordCache.group.enter()

            if let locationRecordCacheItem = LocationRecordCacheItem(withRecord: locationRecord) {
                let QRCode = locationRecordCacheItem.QRCode
                if let locationRecordItems = self.locationItemCacheDict?[QRCode] {
                    print("Found locationRecordItems with \(locationRecordItems.count) items")
                    var mutableLocationRecordItems = locationRecordItems
                    mutableLocationRecordItems.append(locationRecordCacheItem)
 //                   self.locationItemCacheDict?[QRCode] = mutableLocationRecordItems
 
                }
                else {
                    self.locationItemCacheDict?[QRCode] = [locationRecordCacheItem]
               }
            }
            LocationRecordCache.group.leave()
        }
    }
    
    func didFinishFetchingRecords() {
        print(">> LocationRecordCache didFinishFetchingRecords")     // TESTING
        DispatchQueue.global().async {
            self.saveLocationRecordCache()
      }
    }
    
    // Test if the location record cache file exists on disk.
    func locationRecordCacheFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: pathToLocationRecordCache())
    }
    
    // Test if the location record cache file is loaded into memory.
    func chacheIsLoaded() -> Bool {
        if let locationsCount = self.locationItemCacheDict?.keys.count,
            locationsCount > 0 {
            return true
        }
        else {
            return false
        }
    }

    func deleteLocationRecordCache() {
        let path = self.pathToLocationRecordCache()
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        try? FileManager.default.removeItem(atPath: path)
     }
    
    func loadLocationsRecordCacheFile(completion: @escaping (Bool) -> Void) {
        let path = self.pathToLocationRecordCache()
        guard FileManager.default.fileExists(atPath: path) else {
            completion(false)
            return
        }
        DispatchQueue.global().async {
            let cacheFileURL = URL(fileURLWithPath: path)
            guard let cacheData = try? Data(contentsOf: cacheFileURL) else {
                print("Error loading LocationRecordCache data")     // TESTING
                completion(false)
                return
            }
            guard let locationsCache = try? JSONDecoder().decode(LocationRecordCache.self,
                                                                 from: cacheData) else {
                print("Error decoding LocationRecordCache from data")    // TESTING
                completion(false)
                return
            }
            
            if let locationsDict = locationsCache.locationItemCacheDict {
                print("Loaded locations cache file: \(locationsDict.keys.count) LocationRecordCacheItem records")    // TESTING
 
                if locationsDict.keys.count > 0 {
                    LocationRecordCache.shared = locationsCache
                    completion(true)
                }
             }
            else {
                completion(false)
            }
        }
    }
   
    // Fetch Location records from the locations cache for a given list of QRCodes,
    // or fetch all locations if the QRCOde parameter is nil.
    func fetchLocationRecordsFromCache(withQRCode fetchQRCode: String?,
                                       processRecord: @escaping (LocationRecordCacheItem) -> Void,
                                       completion: @escaping () -> Void) {
        
        guard let locationsCacheDict = self.locationItemCacheDict else {
            print("Error: locationItemCacheDict = nil in LocationRecordCache.fetchLocationRecords()")   // TESTING
            completion()
            return
        }
        print("Loaded \(locationsCacheDict.keys.count) LocationRecordCacheItem records")

        
        
         DispatchQueue.global().async {
             
             if let QRCode = fetchQRCode {
                 // Process the locations records for the given QRCode to fetch.
                 if let cachedLocationRecordItems = locationsCacheDict[QRCode] {
                     for locationRecordCacheItem in cachedLocationRecordItems {
                         DebugLocations.shared.didFetchRecord()      // TESTING
                         
                         // call the process location callback function
                         processRecord(locationRecordCacheItem)
                     }
                 }
             }
             else {
                 // Process all cached locations  records for all QRCodes.
                 for QRCode in locationsCacheDict.keys {
                     if let cachedLocationRecordItems = locationsCacheDict[QRCode] {
                         for locationRecordCacheItem in cachedLocationRecordItems {
                             DebugLocations.shared.didFetchRecord()      // TESTING
                             
                             // call the process location callback function
                             processRecord(locationRecordCacheItem)
                         }
                     }
                 }
             }
   
            // call the completion function with the new Locations cache
            completion()
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
        
        // delete the locations record cache file if it exists.
        let cacheFileURL = URL(fileURLWithPath: self.pathToLocationRecordCache())
       try? FileManager.default.removeItem(at: cacheFileURL)
        
        // save the locations record cahe data.
        guard let _ = try? cacheData.write(to: cacheFileURL) else {
            return
        }
    }
    
    func pathToLocationRecordCache() -> String {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDirectory.appendingPathComponent("LocationsCache.txt")
        return url.path
    }
}
