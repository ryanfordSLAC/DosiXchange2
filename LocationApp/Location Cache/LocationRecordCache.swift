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
 
    // Location records cache dictionary of all cached location cache items.
    // [key = QRCode,value = LocationRecordCacheItem]
    var locationRecordCacheDict: [String: [LocationRecordCacheItem]]

    // Maximum location record cache item modification date.
    var maxLocationRecordCacheItemModificationDate: Date?
    
    // all location resource cache item-sorted by alphabetical order
    var sortedLocationResourceCacheItems: [LocationRecordCacheItem]?
    
    static var shared = LocationRecordCache()

    private init() {
        locationRecordCacheDict = [:]
    }
    
    // MARK: Fetching Location Records
    func didStartFetchingRecords() {
    }
    
    func didFetchLocationRecord(_ locationRecord: CKRecord) {

        guard let QRCode = locationRecord["QRCode"] as? String else {
            print("Error: QRCode in record (CKRecord) = nil in LocationReoordCache.didFetchLocationRecord(")
            return
        }

        // Create a new location record cache item for the fetched location record.
        if let locationRecordCacheItem = LocationRecordCacheItem(withRecord: locationRecord) {
             // get the list of location record cache items for the record's associated QRCode.
            var QRCodeLocationCachetems = self.locationRecordCacheDict[QRCode] ?? [LocationRecordCacheItem]()
             
            // append the new location record cache item to the list.
            QRCodeLocationCachetems.append(locationRecordCacheItem)
  
            // save the new list of location record cache items for the record's associated QRCode
            // back in the location record cache dictionary.
            self.locationRecordCacheDict[QRCode] = QRCodeLocationCachetems
        }
   }
    
    func didFinishFetchingRecords() {
        DispatchQueue.global().async {
            self.saveLocationRecordCache()
      }
    }

    // Get the maximum locationm record cache item modification date.
    func maxLocationRecordModificationDate() -> Date? {
        var maxLocationRecordModificatonDate: Date?
 
        for QRCode in self.locationRecordCacheDict.keys {
            if let QRCodeLocationRecordCacheItems = self.locationRecordCacheDict[QRCode] {
                for locationRecordCacheItem in QRCodeLocationRecordCacheItems {
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
        }
        return maxLocationRecordModificatonDate
    }
       
    // MARK: Location
    // Test if the location record cache file exists on disk.
    func locationRecordCacheFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: pathToLocationRecordCache())
    }
    
    // Test if the location record cache file is loaded into memory.
    func cacheIsLoaded() -> Bool {
        
        return cachedLocationRecordCount()  > 0
    }

    func resetCache() {
        // delete the location records cached in memory.
        self.locationRecordCacheDict = [:]
        
        // delete the sorted location resource items
        self.sortedLocationResourceCacheItems = nil

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
            for QRCode in self.locationRecordCacheDict.keys {
                if let QRCodeLocationRecordCacheItems = self.locationRecordCacheDict[QRCode] {
                    recordCount += QRCodeLocationRecordCacheItems.count
                }
            }

            if recordCount > 0 {
                LocationRecordCache.shared = locationsCache
            }
            
            LocationRecordCache.shared.debugSortedResourceCacheItems()      // TESTINGF
            
            completion(recordCount > 0)
        }
    }
   
    // Count the total # of location recprd cache items in the cache.
    func cachedLocationRecordCount() -> Int {
        var recordCount = 0
        for QRCode in self.locationRecordCacheDict.keys {
            if let QRCodeLocationRecordCacheItems = self.locationRecordCacheDict[QRCode] {
                recordCount += QRCodeLocationRecordCacheItems.count
            }
        }

        return recordCount
    }

    // Fetch Location records from the locations cache for a given list of QRCodes,
    // or fetch all locations if the QRCOde parameter is nil.
    func fetchLocationRecordsFromCache(withQRCode fetchQRCode: String?,
                                       processRecord: @escaping (LocationRecordCacheItem) -> Void,
                                       completion: @escaping () -> Void) {
        
        DispatchQueue.global().async {
             
             if let QRCode = fetchQRCode,
                // Fetch and process the location record cache items with the given QRCode.
                 let QRCodeLocationRecordCacheItems = self.locationRecordCacheDict[QRCode]{
                 for locationRecordCacheItem in QRCodeLocationRecordCacheItems {
                     processRecord(locationRecordCacheItem)
                 }
             }
             else {
                 if let sortedLocationCacheItems = self.sortedLocationResourceCacheItems {
                     // Fetch and process the location record cache items in alphabetical order.
                     for locationRecordCacheItem in sortedLocationCacheItems {
                         processRecord(locationRecordCacheItem)
                     }
                 }
                 else {
                     // Fetch and process all location record cache items.
                     for QRCode in self.locationRecordCacheDict.keys {
                         if let QRCodeLocationRecordCacheItems = self.locationRecordCacheDict[QRCode] {
                             for locationRecordCacheItem in QRCodeLocationRecordCacheItems {
                                 processRecord(locationRecordCacheItem)
                           }
                         }
                     }
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
        
        // sort the location resourc eitem QTCodes alphabetically.
        let _ = sortByQTCodeAlphabetically()
        
        // compute the maximum cached location record modification time.
        self.maxLocationRecordCacheItemModificationDate = self.maxLocationRecordModificationDate()

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
    
    // Sort all of the location resource items by QRCode in alphabetical order.
    func sortByQTCodeAlphabetically() -> [LocationRecordCacheItem]? {
        
        self.sortedLocationResourceCacheItems = [LocationRecordCacheItem]()
   
        for QRCode in self.locationRecordCacheDict.keys {
            if let QRCodeLocationRecordCacheItems = self.locationRecordCacheDict[QRCode] {
                for (_, locationRecordCacheItem) in QRCodeLocationRecordCacheItems.enumerated() {
                    self.sortedLocationResourceCacheItems?.append(locationRecordCacheItem)
                }
            }
        }

        let  sortedRecordCacheItems = self.sortedLocationResourceCacheItems?.sorted(by: { (locationResourceCacheItem1, locationResourceCacheItem2) in
             return locationResourceCacheItem1.QRCode < locationResourceCacheItem2.QRCode
         })
                                                                                    
        self.sortedLocationResourceCacheItems = sortedRecordCacheItems
        
        return sortedRecordCacheItems
    }
    
    func debugSortedResourceCacheItems() {
        print("----------------- Sorted Location Resource Items -------------------------")
        if sortedLocationResourceCacheItems == nil {
            print("sortedLocationResourceCacheItems = nil")
            return
        }
        for (index, locationRecordCacheItem) in sortedLocationResourceCacheItems!.enumerated() {
            print("\(index): \(locationRecordCacheItem.QRCode), cycleDate: \(locationRecordCacheItem.cycleDate!) ,modifictionDate: \(locationRecordCacheItem.modificationDate!)")
        }
    }
    
    func debugCache() {
        print("--------------------- Debug Location Cache -------------------------------------")
        print("\(cachedLocationRecordCount()) LocationRecordCacheItems in cache" )
        for QRCode in self.locationRecordCacheDict.keys {
            if let QRCodeLocationRecordCacheItems = self.locationRecordCacheDict[QRCode] {
                print("QRCode: \(QRCode) has \(QRCodeLocationRecordCacheItems.count) cached location records")
                for (index, locationRecordCacheItem) in QRCodeLocationRecordCacheItems.enumerated() {
                    print("\(index): \(QRCode), cycleDate: \(locationRecordCacheItem.cycleDate!) ,modifictionDate: \(locationRecordCacheItem.modificationDate!)")
                }
            }
        }
    }
}
