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
    
    func save(items: [LocationRecordCacheItem])
}

class LocationsCK : Locations {
    let database = CKContainer.default().publicCloudDatabase
    var cache: Cache?
    let reachability = Reachability()!
    let dispatchGroup = DispatchGroup()
    let saceDispatch = DispatchGroup()

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
        self.cache?.add(item)
        self.cache?.addChange(item)
        self.cache?.save()
        dispatchGroup.leave()
        if (self.reachability.connection != .none) {
            saveChanges()
        }        
    }
    
    func save(items: [LocationRecordCacheItem]) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        for item in items {
            self.cache?.add(item)
            self.cache?.addChange(item)
        }
        self.cache?.save()
        dispatchGroup.leave()
        if (self.reachability.connection != .none) {
            saveChanges()
        }
    }
    
    private func reachable(_ : Reachability) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        if self.cache == nil {
            self.cache = Cache.load() ?? Cache()
        }
        dispatchGroup.leave()
        saveChanges()
        self.synchronize(loaded: { _ in print("Synchronization from reachability") })
    }
    
    private func saveChanges() {
        dispatchGroup.wait()
        dispatchGroup.enter()
        if (!self.cache!.changes.isEmpty) {
            let changes = self.cache!.changes.count
            var records = [CKRecord]()
            for item in self.cache!.changes {
                database.fetch(withRecordID: CKRecord.ID(recordName:item.recordName!), completionHandler: { record, error in
                    if let error = error {
                        print(error.localizedDescription)
                        self.dispatchGroup.leave()
                        return
                    }
                    if let record = record {
                        item.update(newRecord: record)
                        records.append(record)
                        if records.count == changes {
                            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
                            operation.modifyRecordsCompletionBlock = { (_, _, error) in
                                if let error = error {
                                    print(error.localizedDescription)
                                }
                                
                                self.cache?.changes.removeAll()
                                self.cache?.save()
                                print("Saved \(records.count) locations.")
                                self.dispatchGroup.leave()
                            }
                            self.database.add(operation)
                            operation.waitUntilFinished()
                        }
                    }})
            }
        }
        else {
            dispatchGroup.leave()
        }
    }
    
    func queryCompletionHandler(records :[LocationRecordDelegate], completed: Bool?, error: Error?, loaded: @escaping ((Int) -> Void))  {
        if let error = error {
            print(error.localizedDescription)
            loaded(cache!.locations.count)
            dispatchGroup.leave()
            return
        }
        
        if (!records.isEmpty){
            for record in records {
                if let item = LocationRecordCacheItem(withRecord: record as! CKRecord) {
                    cache!.add(item)
                }
                else {
                    print("Record isn't acceptable.")
                }
            }
            print("Cache new records: \(records.count)")
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
