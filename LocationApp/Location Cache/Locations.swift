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
    
    func save(item: LocationRecordCacheItem, completionHandler: (() -> Void)?)
    
    func save(items: [LocationRecordCacheItem], completionHandler: (() -> Void)?)
    
    func reset(_ loaded: @escaping  ((Int) -> Void))
}

class LocationsCK : Locations, SettingsService {
    
    let database = CKContainer.default().publicCloudDatabase
    var timer: Timer?
    let timerSec = 300.0
    var cache: Cache?
    let reachability = Reachability()!
    let semaphore = DispatchSemaphore(value: 1)

    init() {
        reachability.whenReachable = reachable
        timer = Timer.scheduledTimer(withTimeInterval: timerSec, repeats: true) { _ in
            DispatchQueue.global(qos: .background).async {
                if self.reachability.connection != .none {
                    print("Synchronization from timer")
                    self.synchronize(loaded: { _ in })
                }
            }
        }
        do {
            try reachability.startNotifier()
        }
        catch {
            print("Unable to start notifier")
        }
    }
        
    func synchronize(loaded: @escaping  ((Int) -> Void)) {
        semaphore.wait()
        if self.cache == nil {
            self.cache = Cache.load() ?? Cache()
        }
        
        if reachability.connection != .none {
            updateSettings()
            let lastDate = self.cache!.locations
                .filter({ $0.modifiedDate != nil })
                .max(by: { a,b -> Bool in a.modifiedDate! < b.modifiedDate!})

            var predicate = NSPredicate(value: true)
            if lastDate != nil {
                predicate = NSPredicate(format: "modifiedDate > %@", argumentArray: [lastDate!.modifiedDate!])
            }

            print("Location query started")
            self.query(predicate: predicate, sortDescriptors: [], pageSize: 50, loaded:{
                self.semaphore.signal()
                loaded($0)
            }, completionHandler: self.queryCompletionHandler)
            self.saveChanges()
        }
        else {
            semaphore.signal()
            loaded(self.cache!.locations.count)
        }
    }
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem] {
        semaphore.wait()
        defer { semaphore.signal() }
        return self.cache!.locations.filter(by)
    }
    
    func filter(by: @escaping (LocationRecordCacheItem) -> Bool, completionHandler: @escaping ([LocationRecordCacheItem]) -> Void) {
        semaphore.wait()
        DispatchQueue.global(qos: .background).async {
            let items = self.cache!.locations.filter(by)
            self.semaphore.signal()
            completionHandler(items)
        }
    }
    
    func groups(completionHandler: @escaping ([String]) -> Void) {
        semaphore.wait()
        DispatchQueue.global(qos: .background).async {
            let items = self.cache!.locations.filter({ $0.reportGroup != nil }).map({ $0.reportGroup! })
            self.semaphore.signal()
            completionHandler(Array(Set(items)))
        }
    }
    
    func count(by: (LocationRecordCacheItem) -> Bool) -> Int {
        semaphore.wait()
        defer { semaphore.signal() }
        return self.cache!.locations.reduce(0, { (count, e) in count + (by(e) ? 1 : 0) })
    }
    
    func save(item: LocationRecordCacheItem, completionHandler: (() -> Void)?) {
        self.save(items: [item], completionHandler: completionHandler)
    }
    
    func save(items: [LocationRecordCacheItem], completionHandler: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.semaphore.wait()
            for item in items {
                self.reportGroupUpdate(item)
                self.cache?.add(item)
                self.cache?.addChange(item)
            }
            self.cache?.save()
            self.semaphore.signal()
            self.saveChanges()
            DispatchQueue.main.async {
                completionHandler?()
            }
        }
    }
    
    func reset(_ loaded: @escaping  ((Int) -> Void)) {
        semaphore.wait()
        self.cache?.clear()
        semaphore.signal()
        self.synchronize(loaded: loaded)
    }
    
    private func reachable(_ : Reachability) {
        DispatchQueue.global(qos: .background).async {
            self.semaphore.wait()
            if self.cache == nil {
                self.cache = Cache.load() ?? Cache()
            }
            self.semaphore.signal()
            self.setUser(completionHandler: {
                self.cache?.setUser(name: $0)
                self.saveChanges()
            })
            self.synchronize(loaded: { _ in print("Synchronization from reachability") })
        }
    }
    
    fileprivate func uploadChanges(_ records: [CKRecord]) {
        let size = 400
        var page = 1
        var total = 0
        print("Prepare to save \(records.count) records.")
        while (records.count > total) {
            let count = records.count >= page * size ? size : records.count - total
            let slice = Array(records[total...total + count - 1])
            total = page * size
            page += 1
   
            let operation = CKModifyRecordsOperation(recordsToSave: slice, recordIDsToDelete: nil)
            operation.savePolicy = .allKeys
            operation.modifyRecordsResultBlock = { result in
                switch result {
                    case .success : print("Saved locations.")
                    case .failure(let error) :print(error.localizedDescription)
                }
            }
            self.database.add(operation)
            operation.waitUntilFinished()
        }
    }
    
    private func saveChanges() {
        if reachability.connection != .none {
            DispatchQueue.global(qos: .background).async {
                self.semaphore.wait()
                if (!self.cache!.changes.isEmpty) {
                    var records = [CKRecord]()
                    for item in self.cache!.changes {
                        records.append(item.to())
                    }
                    
                    self.uploadChanges(records)
                    self.cache?.changes.removeAll()
                    self.cache?.save()
                    self.semaphore.signal()
                }
                else {
                    self.semaphore.signal()
                }
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
    
    func getSettings(completionHandler: @escaping (Settings) -> Void) {
        semaphore.wait()
        DispatchQueue.global(qos: .background).async {
            let settings = self.cache!.settings
            self.semaphore.signal()
            completionHandler(settings)
        }
    }
    
    private func add(_ query : CKQueryOperation, loaded: @escaping ((Int) -> Void), completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?,@escaping ((Int) -> Void)) -> Void) {
        var result: [LocationRecordDelegate] = []
        let operation = query
        operation.resultsLimit = 500
        operation.recordMatchedBlock = { _, res in
            switch res {
                case .success(let record) : result.append(record)
                case .failure(let error) :print(error.localizedDescription)
            }
        }
        operation.queryResultBlock = { res in
            switch res {
            case .success(let cursor) :
                if let cursor {
                    completionHandler(result, false, nil, loaded)
                    result = []
                    let operation = CKQueryOperation(cursor: cursor)
                    self.add(operation, loaded:loaded, completionHandler:  completionHandler)
                }
                else {
                    completionHandler(result, true, nil, loaded)
                }
            case .failure(let error) :
                print(error.localizedDescription)
                completionHandler([], nil, error, loaded)
            }
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
    
    private func updateSettings() {
        let dispatchgroup = DispatchGroup()
        dispatchgroup.enter()
        let query = CKQuery(recordType: "Settings", predicate: NSPredicate(value: true))
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1, completionHandler: { results in
            switch results {
            case .failure(let error) : print(error.localizedDescription)
            case .success((let matches, _)) :
                switch matches.first!.1 {
                case .failure(let error) : print(error.localizedDescription)
                case .success(let record) :
                    let settings = Settings()
                    settings.dosimeterMinimumLength = record["dosimeterMinimumLength"] as? Int ?? 11
                    settings.dosimeterMaximumLength = record["dosimeterMaximumLength"] as? Int ?? 11
                    self.cache!.setSettings(settings: settings)
                }
            }            
            dispatchgroup.leave()
        })
        dispatchgroup.wait()
    }
    
    private func reportGroupUpdate(_ item: LocationRecordCacheItem) {
        if item.reportGroup == nil || item.reportGroup!.isEmpty, let location = cache!.locations.first(where: { l in l.reportGroup != nil && !l.reportGroup!.isEmpty}) {
            item.reportGroup = location.reportGroup
        }
    }
                                        
}
