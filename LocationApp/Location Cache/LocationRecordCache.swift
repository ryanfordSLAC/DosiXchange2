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
    
    var version: Float = 1.0                                    // location cache file version #
    
    var cycleDateString: String?                                // current cycle date string
    var priorCycleDateString: String?                           // prior cycle date string

    // Current cycle location cache em records dictionary.
    // [key = QRCode,value = LocationRecordCacheItem]
    var cycleLocationItemCacheDict: [String: LocationRecordCacheItem]?
 
    // Prior cycle location cache em records dictionary.
    // [key = QRCode,value = LocationRecordCacheItem]
    var priorCycleLocationItemCacheDict: [String: LocationRecordCacheItem]?
 
    private init() {
//        deleteLocationRecordCache()       // delete the cache file (TESTING)
   }
    
    func didStartFetchingRecords() {
        cycleDateString = RecordsUpdate.generateCycleDate()
        if let currentCycleDateString = cycleDateString {
            priorCycleDateString = RecordsUpdate.generatePriorCycleDate(cycleDate: currentCycleDateString)
        }
        cycleLocationItemCacheDict = [:]
        priorCycleLocationItemCacheDict = [:]
   }
    
    func didFetchLocationRecord(_ locationRecord: CKRecord) {

        let isCurrentCycleRecord: Bool?
        if locationRecord["cycleDate"] == cycleDateString {
            isCurrentCycleRecord = true
        }
        else if locationRecord["cycleDate"] == priorCycleDateString {
            isCurrentCycleRecord = false
        }
        else {
            return
        }
        if let locationRecordCacheItem = LocationRecordCacheItem(withRecord: locationRecord) {
            if isCurrentCycleRecord! {
                self.cycleLocationItemCacheDict?[locationRecordCacheItem.QRCode] = locationRecordCacheItem
            }
            else {
                self.priorCycleLocationItemCacheDict?[locationRecordCacheItem.QRCode] = locationRecordCacheItem
            }
        }
    }
    
    func didFinishFetchingRecords() {
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
        if let locationsCount = self.cycleLocationItemCacheDict?.keys.count,
            locationsCount > 0 {
            return true
        }
        else if let locationsCount = self.priorCycleLocationItemCacheDict?.keys.count,
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
            
            if let cycleLocationsDict = locationsCache.cycleLocationItemCacheDict,
                let priorCycleLocationsDict = locationsCache.priorCycleLocationItemCacheDict {
                let recordCount = cycleLocationsDict.keys.count + priorCycleLocationsDict.keys.count
                print("Loaded locations cache file: \(recordCount) LocationRecordCacheItem records")    // TESTING
 
                if recordCount > 0 {
                    LocationRecordCache.shared = locationsCache
                    completion(true)
                }
                else {
                    completion(false)
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
        
        guard let locationsCacheDict = self.cycleLocationItemCacheDict else {
            print("Error: locationItemCacheDict = nil in LocationRecordCache.fetchLocationRecords()")   // TESTING
            completion()
            return
        }
        print("Loaded \(locationsCacheDict.keys.count) LocationRecordCacheItem records")

        
        
         DispatchQueue.global().async {
             
             if let QRCode = fetchQRCode {
                 // Fetch and process a location record cache item with the
                 // given QRCode and in the current cycle.
                 if let locationRecordCacheItem = self.cycleLocationItemCacheDict?[QRCode] {
                     processRecord(locationRecordCacheItem)
                     DebugLocations.shared.didFetchRecord()     // TESTING
                 }
                 // Fetch and process a location record cache item with the
                 // given QRCode and in the prior cycle.
                  else if let locationRecordCacheItem = self.priorCycleLocationItemCacheDict?[QRCode] {
                     processRecord(locationRecordCacheItem)
                     DebugLocations.shared.didFetchRecord()     // TESTING
                 }
             }
             else {
                 for QRCode in locationsCacheDict.keys {
                     // Fetch and process a location record cache item with the QRCode
                     // and in the current cycle.
                     if let locationRecordCacheItem = self.cycleLocationItemCacheDict?[QRCode] {
                         processRecord(locationRecordCacheItem)
                         DebugLocations.shared.didFetchRecord()     // TESTING
                     }
                     // Fetch and process a location record cache item with the QRCode
                     // and in the prior cycle.
                     if let locationRecordCacheItem = self.priorCycleLocationItemCacheDict?[QRCode] {
                         processRecord(locationRecordCacheItem)
                         DebugLocations.shared.didFetchRecord()     // TESTING
                     }
                 }
             }
   
            completion()
        }
    }

    // Save the dosimeter CloudKit records from disk.
    // Throws a DosimeterRecordCacheError is a required record field is nil.
    func saveLocationRecordCache() {
        guard let count = self.cycleLocationItemCacheDict?.keys.count, (count > 0) else {
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
