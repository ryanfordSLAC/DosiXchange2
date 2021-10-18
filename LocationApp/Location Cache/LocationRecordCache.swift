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

    // Location records cache dictionary of all cached location cache items.
    // [key = QRCode,value = LocationRecordCacheItem]
    var  locationRecordCacheDict: [String: [LocationRecordCacheItem]]?

    // Maximum location record cache item modification date.
    var maxLocationRecordCacheItemModificationDate: Date?
    
    static var shared = LocationRecordCache()

    private init() {
    }
    
    // MARK: Fetching Location Records
    func didStartFetchingRecords() {
        cycleDateString = RecordsUpdate.generateCycleDate()
        if let currentCycleDateString = cycleDateString {
            priorCycleDateString = RecordsUpdate.generatePriorCycleDate(cycleDate: currentCycleDateString)
        }
        if cycleLocationRecordCacheDict == nil {
            cycleLocationRecordCacheDict = [:]
        }
        if priorCycleLocationRecordCacheDict == nil {
            priorCycleLocationRecordCacheDict = [:]
        }
        
        if locationRecordCacheDict == nil {
            locationRecordCacheDict = [:]
        }
   }
    
    func didFetchLocationRecord(_ locationRecord: CKRecord) {

        if self.locationRecordCacheDict == nil {
            self.locationRecordCacheDict = [:]
        }

        guard let QRCode = locationRecord["QRCode"] as? String else {
            print("Error: QRCode in record (CKRecord) = nil in LocationReoordCache.didFetchLocationRecord(")
            return
        }
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
        
        // Create a new location record cache item for the fetched location record.
        if let locationRecordCacheItem = LocationRecordCacheItem(withRecord: locationRecord) {
            
            print("Made new LocationRecordCacheItem for QRCode: \(QRCode)")
            
            // get the list of location record cache items for the record's associated QRCode.
            var QRCodeLocationCachetems = self.locationRecordCacheDict?[QRCode] as? [LocationRecordCacheItem] ?? [LocationRecordCacheItem]()
            
            print(" \(QRCode) LocationRecordCacheItem array has:\(QRCodeLocationCachetems.count) items Before append()")
            
            // append the new location record cache item to the list.
            QRCodeLocationCachetems.append(locationRecordCacheItem)
            
            print(" \(QRCode) LocationRecordCacheItem array has:\(QRCodeLocationCachetems.count) items After append()")

            // save the new list of location record cache items for the record's associated QRCode
            // back in the location record cache dictionary.
            self.locationRecordCacheDict![QRCode] = QRCodeLocationCachetems
            
            print("Set new LocationRecordCacheItem for QRCode: \(QRCode)")

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
    
    // Get the maximu location record cache item modificatio date.
    func maxLocationRecordModificationDate() -> Date? {
        var maxLocationRecordModificatonDate: Date?
        
        // Search all current cycle location record cache items for the maximum modification time.
        if let cycleLocationRecordCacheItems = self.cycleLocationRecordCacheDict?.values {
            for (_, locationRecordCacheItem) in cycleLocationRecordCacheItems.enumerated() {
                if let locationRecordModificationDate = locationRecordCacheItem.modificationDate {
                    if let maxModificatonDate = maxLocationRecordModificatonDate,
                       (locationRecordModificationDate.timeIntervalSinceReferenceDate < maxModificatonDate.timeIntervalSinceReferenceDate) {
                        maxLocationRecordModificatonDate = maxModificatonDate
                    }
                    else  {
                        maxLocationRecordModificatonDate = locationRecordModificationDate
                    }
                }
             }
        }
  
        // Search all prior cycle location record cache items for the maximum modification time.
        if let priorCycleLocationRecordCacheItems = self.priorCycleLocationRecordCacheDict?.values {
            for (_, locationRecordCacheItem) in priorCycleLocationRecordCacheItems.enumerated() {
                if let locationRecordModificationDate = locationRecordCacheItem.modificationDate {
                    if let maxModificatonDate = maxLocationRecordModificatonDate,
                       (locationRecordModificationDate.timeIntervalSinceReferenceDate < maxModificatonDate.timeIntervalSinceReferenceDate) {
                        maxLocationRecordModificatonDate = maxModificatonDate
                   }
                    else  {
                        maxLocationRecordModificatonDate = locationRecordModificationDate
                    }
                }
             }
        }
        
        print("*** Most Recent Cached Location Record Time = \(maxLocationRecordModificatonDate!)")

        return maxLocationRecordModificatonDate
    }
       
    // MARK: Location
    // Test if the location record cache file exists on disk.
    func locationRecordCacheFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: pathToLocationRecordCache())
    }
    
    // Test if the location record cache file is loaded into memory.
    func cacheIsLoaded() -> Bool {
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
        
        
        print("Fetchin locations from cache")       // TESTING
        debugCache()
        
        DispatchQueue.global().async {
             
             if let QRCode = fetchQRCode {
                 // Fetch and process a location record cache item with the
                 // given QRCode and in the current cycle.
                 if let locationRecordCacheItem = self.cycleLocationRecordCacheDict?[QRCode] {
                     processRecord(locationRecordCacheItem)
                 }
                 // Fetch and process a location record cache item with the
                 // given QRCode and in the prior cycle.
                  else if let locationRecordCacheItem = self.priorCycleLocationRecordCacheDict?[QRCode] {
                     processRecord(locationRecordCacheItem)
                 }
             }
             else {
                 // Fetch and process a location record cache item with the QRCode
                 // and in the current cycle.
                 for locationRecordCacheItem in self.cycleLocationRecordCacheDict!.values {
                     processRecord(locationRecordCacheItem)
                 }
                 // Fetch and process a location record cache item with the QRCode
                 // and in the prior cycle.
                for locationRecordCacheItem in self.priorCycleLocationRecordCacheDict!.values {
                     processRecord(locationRecordCacheItem)
                 }
             }
            completion()
        }
    }

    // Save the Location records cache file.
    func saveLocationRecordCache() {
        guard cacheIsLoaded() else {
             return
         }
        guard let cacheData = try? JSONEncoder().encode(self) else {
            print("Error encoding DosimeterRecordCache data")
            return
        }
        
        // compute the maximum cached location record modification time.
        self.maxLocationRecordCacheItemModificationDate = self.maxLocationRecordModificationDate()

        // delete the locations record cache file if it exists.
        let cacheFileURL = URL(fileURLWithPath: self.pathToLocationRecordCache())
        try? FileManager.default.removeItem(at: cacheFileURL)
        
        // save the locations record cahe data.
        guard let _ = try? cacheData.write(to: cacheFileURL) else {
            return
        }
        print("Saving the Location Record Cache")
        debugCache()
    }
    
    func pathToLocationRecordCache() -> String {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDirectory.appendingPathComponent("LocationsCache.txt")
        return url.path
    }
    
    func debugCache() {
        
        print("--------------------- Debug Locaton Cache -------------------------------------")
        
        if (cycleLocationRecordCacheDict != nil) {
            print("Cache has \(cycleLocationRecordCacheDict!.keys.count) Current Cycle Records")
        }
        else {
            print("Cache has 0 Current Cycle Records")
            }

        if (priorCycleLocationRecordCacheDict != nil) {
            print("Cache has \(priorCycleLocationRecordCacheDict!.keys.count) Prior Cycle Records")
        }
        else {
            print("Cache has 0 Prior Cycle Records")
        }
    }
}
