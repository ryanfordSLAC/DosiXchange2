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

    // Current cycle location cache item records dictionary.
    // [key = QRCode,value = LocationRecordCacheItem]
    var cycleLocationItemCacheDict: [String: LocationRecordCacheItem]?
 
    // Prior cycle location cache item records dictionary.
    // [key = QRCode,value = LocationRecordCacheItem]
    var priorCycleLocationItemCacheDict: [String: LocationRecordCacheItem]?
 
    private init() {
        deleteLocationRecordCacheFile()       // delete the cache file (TESTING)
   }
    
    func didStartFetchingRecords() {
        cycleDateString = RecordsUpdate.generateCycleDate()
        print("cycleDateString = \(cycleDateString)")
        if let currentCycleDateString = cycleDateString {
            priorCycleDateString = RecordsUpdate.generatePriorCycleDate(cycleDate: currentCycleDateString)
            print("priorCycleDateString = \(priorCycleDateString)")
        }
        cycleLocationItemCacheDict = [:]
        priorCycleLocationItemCacheDict = [:]
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
                self.cycleLocationItemCacheDict![locationRecordCacheItem.QRCode] = locationRecordCacheItem
                print("Cached current location record: cycle date = \(locationRecordCacheItem.cycleDate!)")
            }
            else {
                self.priorCycleLocationItemCacheDict![locationRecordCacheItem.QRCode] = locationRecordCacheItem
                print("Cached prior location record: cycle date = \(locationRecordCacheItem.cycleDate!)")
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
        if self.cycleLocationItemCacheDict != nil,
            self.cycleLocationItemCacheDict!.keys.count  > 0 {
            return true
        }
        else if self.priorCycleLocationItemCacheDict != nil,
            self.priorCycleLocationItemCacheDict!.keys.count  > 0 {
            return true
        }
        else {
            return false
        }
    }

    func deleteLocationRecordCacheFile() {
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
            if let cycleLocationsDict = locationsCache.cycleLocationItemCacheDict,
                let priorCycleLocationsDict = locationsCache.priorCycleLocationItemCacheDict {
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
                 // Fetch and process a location record cache item with the QRCode
                 // and in the current cycle.
                 for locationRecordCacheItem in self.cycleLocationItemCacheDict!.values {
                     processRecord(locationRecordCacheItem)
                     DebugLocations.shared.didFetchRecord()     // TESTING
                 }
                 // Fetch and process a location record cache item with the QRCode
                 // and in the prior cycle.
                for locationRecordCacheItem in self.priorCycleLocationItemCacheDict!.values {
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
