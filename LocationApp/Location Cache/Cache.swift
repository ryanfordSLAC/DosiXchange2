//
//  Cache.swift
//  LocationApp
//
//  Created by Szöllősi László on 2023. 05. 12..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation

class Cache: Codable {
    var version = "1.0"
    var locations = [LocationRecordCacheItem]()
    var changes = [LocationRecordCacheItem]()
    
    static func load() -> Cache? {
        if Cache.locationRecordCacheFileExists() {
            let cacheFileURL = URL(fileURLWithPath: pathToCache())
            guard let cacheData = try? Data(contentsOf: cacheFileURL) else {
                print("Error loading Cache data")
                return nil
            }
            guard let locationsCache = try? JSONDecoder().decode(Cache.self,
                                                                 from: cacheData) else {
                print("Error decoding cache from data")
                return nil
            }
            return locationsCache
        }
        return nil
    }
    
    func add(_ item: LocationRecordCacheItem) {
        if let index = locations.firstIndex(where: { l in l.recordName == item.recordName}) {
            locations[index] = item
        }
        else {
            locations.append(item)
        }
    }
    
    func addChange(_ item: LocationRecordCacheItem) {
        if let index = changes.firstIndex(where: { l in l.recordName == item.recordName}) {
            changes[index] = item
        }
        else {
            changes.append(item)
        }
    }
    
    func clear() {
        locations.removeAll()
    }
    
    func save() {
        guard let cacheData = try? JSONEncoder().encode(self) else {
            print("Error encoding DosimeterRecordCache data")
            return
        }
        
        // delete the locations record cache file if it exists.
        let cacheFileURL = URL(fileURLWithPath: Cache.pathToCache())
        try? FileManager.default.removeItem(at: cacheFileURL)
        
        // save the locations record cahe data.
        guard let _ = try? cacheData.write(to: cacheFileURL) else {
            return
        }
    }
    
    private static func locationRecordCacheFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: pathToCache())
    }
    
    private static func pathToCache() -> String {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDirectory.appendingPathComponent("cache.txt")
        return url.path
    }
}
