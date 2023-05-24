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
    
    func filter(by: @escaping (LocationRecordCacheItem) -> Bool, completionHandler: @escaping ([LocationRecordCacheItem]) -> Void)
    
    func groups(completionHandler: @escaping ([String]) -> Void)
    
    func count(by: (LocationRecordCacheItem) -> Bool) -> Int
    
    func save(item: LocationRecordCacheItem)
    
    func save(items: [LocationRecordCacheItem])
    
    func reset(_ loaded: @escaping  ((Int) -> Void))
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
        
        if reachability.connection != .none {
            let lastDate = self.cache!.locations
                .filter({ $0.modifiedDate != nil })
                .max(by: { a,b -> Bool in a.modifiedDate! < b.modifiedDate!})

            var predicate = NSPredicate(value: true)
            if lastDate != nil {
                predicate = NSPredicate(format: "modifiedDate > %@", argumentArray: [lastDate!.modifiedDate!])
            }

            self.query(predicate: predicate, sortDescriptors: [], pageSize: 50, loaded:{
                self.dispatchGroup.leave()
                loaded($0)
            }, completionHandler: self.queryCompletionHandler)
        }
        else {
            dispatchGroup.leave()
            loaded(self.cache!.locations.count)
        }
    }
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem] {
        dispatchGroup.wait()
        dispatchGroup.enter()
        defer { dispatchGroup.leave() }
        return self.cache!.locations.filter(by)
    }
    
    func filter(by: @escaping (LocationRecordCacheItem) -> Bool, completionHandler: @escaping ([LocationRecordCacheItem]) -> Void) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        DispatchQueue.global(qos: .background).async {
            let items = self.cache!.locations.filter(by)
            completionHandler(items)
            self.dispatchGroup.leave()
        }
    }
    
    func groups(completionHandler: @escaping ([String]) -> Void) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        DispatchQueue.global(qos: .background).async {
            let items = self.cache!.locations.filter({ $0.reportGroup != nil }).map({ $0.reportGroup! })
            self.dispatchGroup.leave()
            completionHandler(Array(Set(items)))
        }
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
    
    func reset(_ loaded: @escaping  ((Int) -> Void)) {
        dispatchGroup.wait()
        dispatchGroup.enter()
        self.cache?.clear()
        dispatchGroup.leave()
        self.synchronize(loaded: loaded)
    }
    
    private func reachable(_ : Reachability) {
        DispatchQueue.global(qos: .background).async {
            self.dispatchGroup.wait()
            self.dispatchGroup.enter()
            if self.cache == nil {
                self.cache = Cache.load() ?? Cache()
            }
            self.dispatchGroup.leave()
            self.setUser(completionHandler: {
                self.cache?.setUser(name: $0)
                self.saveChanges()
            })
            self.synchronize(loaded: { _ in print("Synchronization from reachability") })
        }
    }
    
    private func saveChanges() {
        DispatchQueue.global(qos: .background).async {
            self.dispatchGroup.wait()
            self.dispatchGroup.enter()
            if (!self.cache!.changes.isEmpty) {
                var records = [CKRecord]()
                for item in self.cache!.changes {
                    records.append(item.to())
                }
                let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
                operation.savePolicy = .allKeys
                operation.modifyRecordsCompletionBlock = { (_, _, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    else {
                        print("Saved \(records.count) locations.")
                    }
                    
                    self.cache?.changes.removeAll()
                    self.cache?.save()
                    self.dispatchGroup.leave()
                }
                self.database.add(operation)
                operation.waitUntilFinished()
            }
            else {
                self.dispatchGroup.leave()
            }
        }
    }
    
    func queryCompletionHandler(records :[LocationRecordDelegate], completed: Bool?, error: Error?, loaded: @escaping ((Int) -> Void))  {
        if let error = error {
            print(error.localizedDescription)
            loaded(cache!.locations.count)
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
    
    private func setUser(completionHandler: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            CKContainer.default().requestApplicationPermission(.userDiscoverability) { (status, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                if status == .granted {
                        CKContainer.default().fetchUserRecordID { (record, error) in
                            CKContainer.default().discoverUserIdentity(withUserRecordID: record!, completionHandler: { (userID, error) in
                                if let givenName = userID?.nameComponents?.givenName, let familyName = userID?.nameComponents?.familyName {
                                    completionHandler("\(givenName) \(familyName)")
                                }
                                else {
                                    completionHandler(userID?.lookupInfo?.emailAddress ?? "")
                                }
                            })
                        }
                    }
                completionHandler("")
            }
        }
    }
}
