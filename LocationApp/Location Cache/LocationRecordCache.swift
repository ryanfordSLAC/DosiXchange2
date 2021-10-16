//
//  LocationRecordCache.swift
//  LocationApp
//
//  Created by Matt Lintlop on 10/10/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

// MARK: LocationRecordCache Class
class LocationRecordCache: Codable {
    
    // MARK: Codable Properties
    var version: Float = 1.0                                    // location cache file version #
    var cycleDateString: String?                                // current cycle date string
    var priorCycleDateString: String?                           // prior cycle date string

    // Current cycle location records cache dictionary.
    // [key = QRCode,value = LocationRecordCacheItem]
    var cycleLocationRecordCacheDict: [String: LocationRecordCacheItem]?
 
    // Prior cycle location records cache dictionary.
    // [key = QRCode,value = LocationRecordCacheItem]
    var priorCycleLocationRecordCacheDict: [String: LocationRecordCacheItem]?

    static var shared = LocationRecordCache()

    private init() {
    }
    
    // MARK: Fetching Location Records
    func didStartFetchingRecords() {
        cycleDateString = RecordsUpdate.generateCycleDate()
        if let currentCycleDateString = cycleDateString {
            priorCycleDateString = RecordsUpdate.generatePriorCycleDate(cycleDate: currentCycleDateString)
        }
        cycleLocationRecordCacheDict = [:]
        priorCycleLocationRecordCacheDict = [:]
   }
    
    func didFetchLocationRecord(_ locationRecord: CKRecord) {

        var isCurrentCycleRecord: Bool = false
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
            if isCurrentCycleRecord
            {
                self.cycleLocationRecordCacheDict![locationRecordCacheItem.QRCode] = locationRecordCacheItem
            }
            else {
                self.priorCycleLocationRecordCacheDict![locationRecordCacheItem.QRCode] = locationRecordCacheItem
           }
        }
   }
    
    func didFinishFetchingRecords() {
        DispatchQueue.global().async {
            self.saveLocationRecordCache()
      }
    }
    
    // MARK: Location
    // Test if the location record cache file exists on disk.
    func locationRecordCacheFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: pathToLocationRecordCache())
    }
    
    // Test if the location record cache file is loaded into memory.
    func chacheIsLoaded() -> Bool {
        if self.cycleLocationRecordCacheDict != nil,
            self.cycleLocationRecordCacheDict!.keys.count  > 0 {
            return true
        }
        else if self.priorCycleLocationRecordCacheDict != nil,
            self.priorCycleLocationRecordCacheDict!.keys.count  > 0 {
            return true
        }
        else {
            return false
        }
    }

    func resetCache() {
        // delete the location records cached in memory.
        self.cycleLocationRecordCacheDict = nil
        self.priorCycleLocationRecordCacheDict = nil

        // delete the locatioms record cache file.
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
            
            var recordCount = 0
            if let cycleLocationsDict = locationsCache.cycleLocationRecordCacheDict,
                let priorCycleLocationsDict = locationsCache.priorCycleLocationRecordCacheDict {
                recordCount = cycleLocationsDict.keys.count + priorCycleLocationsDict.keys.count
                print("Loaded locations cache file: \(recordCount) LocationRecordCacheItem records")    // TESTING
 
                if recordCount > 0 {
                    LocationRecordCache.shared = locationsCache
                }
             }
            completion(recordCount > 0)
        }
    }
   
    // Fetch Location records from the locations cache for a given list of QRCodes,
    // or fetch all locations if the QRCOde parameter is nil.
    func fetchLocationRecordsFromCache(withQRCode fetchQRCode: String?,
                                       processRecord: @escaping (LocationRecordCacheItem) -> Void,
                                       completion: @escaping () -> Void) {
        
        DispatchQueue.global().async {
             
             if let QRCode = fetchQRCode {
                 // Fetch and process a location record cache item with the
                 // given QRCode and in the current cycle.
                 if let locationRecordCacheItem = self.cycleLocationRecordCacheDict?[QRCode] {
                     processRecord(locationRecordCacheItem)
                     DebugLocations.shared.didFetchRecord()     // TESTING
                 }
                 // Fetch and process a location record cache item with the
                 // given QRCode and in the prior cycle.
                  else if let locationRecordCacheItem = self.priorCycleLocationRecordCacheDict?[QRCode] {
                     processRecord(locationRecordCacheItem)
                     DebugLocations.shared.didFetchRecord()     // TESTING
                 }
             }
             else {
                 // Fetch and process a location record cache item with the QRCode
                 // and in the current cycle.
                 for locationRecordCacheItem in self.cycleLocationRecordCacheDict!.values {
                     processRecord(locationRecordCacheItem)
                     DebugLocations.shared.didFetchRecord()     // TESTING
                 }
                 // Fetch and process a location record cache item with the QRCode
                 // and in the prior cycle.
                for locationRecordCacheItem in self.priorCycleLocationRecordCacheDict!.values {
                     processRecord(locationRecordCacheItem)
                     DebugLocations.shared.didFetchRecord()     // TESTING
                 }
             }
            completion()
        }
    }

    // Save the Location records cache file.
    func saveLocationRecordCache() {
        guard chacheIsLoaded() else {
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
