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
    
    static var shared = LocationRecordCache()
    
    var version = 1                                             // location cache file version #
    
    var cacheCycleDateString: String?                           // cache cycle date string
   
    // cache records dictionary. [key = CloudKit  Record ID, value = DosimeterRecordCacheItem]
    var locationItemCacheDict: [String: LocationRecordCacheItem]?
 
    // location items in same order as sorted CloudKit records
    var sortedDosimeterRecordCacheItems: [LocationRecordCacheItem]?
    
    private init() {
 //       deleteCacheFile()       // delete the cache file (TESTING)
   }
    
    func didStartFetchingRecords() {
    }
    
    func didFinishFetchingRecords(_ records: [CKRecord]) {
        DispatchQueue.global().async {
            self.makeCache(withRecords: records)
            self.saveCache()
      }
    }
    
    func makeCache(withRecords records: [CKRecord]) {
        locationItemCacheDict = [String: LocationRecordCacheItem]()
        sortedDosimeterRecordCacheItems = [LocationRecordCacheItem]()
        
        for record in records {
            if let DosimeterRecordCacheItem = LocationRecordCacheItem(withRecord: record) {
                sortedDosimeterRecordCacheItems!.append(DosimeterRecordCacheItem)
                locationItemCacheDict![record.recordID.recordName] = DosimeterRecordCacheItem
            }
        }
    }
    
    // Test if the locations cache file exists.
    func cacheFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: cacheFilePath())
    }
    
    func deleteCacheFile() {
        let path = self.cacheFilePath()
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        try? FileManager.default.removeItem(atPath: path)
     }
    
    // Load the dosimeter CloudKit records from disk.
    // Throws a DosimeterRecordCacheError is a required record field is nil.
    func loadCache(completion: @escaping ([LocationRecordCacheItem]?) -> Void) {
        let path = self.cacheFilePath()
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        DispatchQueue.global().async {
              let cacheFileURL = URL(fileURLWithPath: path)
            guard let cacheData = try? Data(contentsOf: cacheFileURL) else {
                print("Error loading DosimeterRecordCache data")
                return
            }
            guard let locationsCache = try? JSONDecoder().decode(LocationRecordCache.self,
                                                                 from: cacheData) else {
                print("Error decoding DosimeterRecordCache from data")
                return
            }
            LocationRecordCache.shared = locationsCache
            
            if let dosimeterRecords = locationsCache.sortedDosimeterRecordCacheItems {
                completion(dosimeterRecords)
            }
        }
    }

    // Save the dosimeter CloudKit records from disk.
    // Throws a DosimeterRecordCacheError is a required record field is nil.
    func saveCache() {
        guard let count = self.locationItemCacheDict?.keys.count, (count > 0) else {
             return
         }
        guard let cacheData = try? JSONEncoder().encode(self) else {
            print("Error encoding DosimeterRecordCache data")
            return
        }
        
        let cacheFileURL = URL(fileURLWithPath: self.cacheFilePath())
        try? FileManager.default.removeItem(at: cacheFileURL)
        guard let _ = try? cacheData.write(to: cacheFileURL) else {
            return
        }
    }
    
    // Path to the locations cache file
    func cacheFilePath() -> String {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDirectory.appendingPathComponent("LocationsCache.txt")
        return url.path
    }
}
