//
//  Locations.swift
//  LocationApp
//
//  Created by Szöllősi László on 2023. 05. 11..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

protocol Locations {
    func synchronize(loaded: @escaping ((Int) -> Void))
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem]
    
    func count(by: (LocationRecordCacheItem) -> Bool) -> Int
    
    func save(item: LocationRecordCacheItem)
}

class LocationsCK : Locations {
    let database = CKContainer.default().publicCloudDatabase
    var cache: Cache?
    let reachability = Reachability()!
    let dispatchGroup = DispatchGroup()

    private init() {
        reachability.whenReachable = reachable
        do {
            try reachability.startNotifier()
        }
        catch {
            print("Unable to start notifier")
        }
    }
    
    static var shared: Locations = LocationsCK()
    
    func synchronize(loaded: @escaping  ((Int) -> Void)) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        if self.cache == nil {
            self.cache = Cache.load() ?? Cache()
        }
        
        let lastDate = self.cache!.locations
            .filter({ $0.modifiedDate != nil })
            .max(by: { a,b -> Bool in a.modifiedDate! < b.modifiedDate!})

        var predicate = NSPredicate(value: true)
        if lastDate != nil {
            predicate = NSPredicate(format: "modifiedDate > %@", argumentArray: [lastDate!.modifiedDate!])
        }

        self.query(predicate: predicate, sortDescriptors: [], pageSize: 50, loaded:loaded, completionHandler: self.queryCompletionHandler)
    }
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem] {
        dispatchGroup.wait()
        dispatchGroup.enter()
        defer { dispatchGroup.leave() }
        return self.cache!.locations.filter(by)
    }
    
    func count(by: (LocationRecordCacheItem) -> Bool) -> Int {
        dispatchGroup.wait()
        dispatchGroup.enter()
        defer { dispatchGroup.leave() }
        return self.cache!.locations.reduce(0, { (count, e) in count + (by(e) ? 1 : 0) })
    }
    
    func save(item: LocationRecordCacheItem) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        self.cache?.addChange(item)
        dispatchGroup.leave()
        if (self.reachability.connection != .none) {
            self.reachable(self.reachability)
        }        
    }
    
    private func reachable(_ : Reachability) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        if self.cache == nil {
            self.cache = Cache.load() ?? Cache()
        }
        if (!self.cache!.changes.isEmpty) {
            var records = [CKRecord]()
            for item in self.cache!.changes {
                records.append(item.toRecord())
            }
            
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
            
            self.database.add(operation)
            self.cache?.changes.removeAll()
            operation.waitUntilFinished()
        }
        dispatchGroup.leave()
        self.synchronize(loaded: { _ in print("Synchronization from reachability") })
    }
    
    func queryCompletionHandler(records :[LocationRecordDelegate], completed: Bool?, error: Error?, loaded: @escaping ((Int) -> Void))  {
        if let error = error {
            dispatchGroup.leave()
            print(error.localizedDescription)
            return
        }
        
        if (!records.isEmpty){
            for record in records {
                if let item = LocationRecordCacheItem(withRecord: record as! CKRecord) {
                    cache!.add(item)
                }
            }
        }
        
        if let completed = completed {
            if completed {
                print("Location query completed.")
                cache!.save()
                loaded(cache!.locations.count)
                dispatchGroup.leave()
            }
        }
    }
    
    func query(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], pageSize:Int,  loaded: @escaping ((Int) -> Void), completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?,@escaping ((Int) -> Void)) -> Void)  {
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = sortDescriptors
        let operation = CKQueryOperation(query: query)
        add(operation, loaded: loaded, completionHandler: completionHandler)
    }
    
    private func add(_ query : CKQueryOperation, loaded: @escaping ((Int) -> Void), completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?,@escaping ((Int) -> Void)) -> Void) {
        var result: [LocationRecordDelegate] = []
        let operation = query
        operation.resultsLimit = 500
        operation.recordFetchedBlock = { record in result.append(record) }
        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                completionHandler([], nil, error, loaded)
                return
            }
            if let cursor = cursor {
                completionHandler(result, false, nil, loaded)
                result = []
                let operation = CKQueryOperation(cursor: cursor)
                self.add(operation, loaded:loaded, completionHandler:  completionHandler)
                return
            }
            completionHandler(result, true, nil, loaded)
        }
        database.add(operation)
    }
}
