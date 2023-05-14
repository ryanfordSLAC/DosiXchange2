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
    func synchronize(loaded: ((Int) -> Void)?)
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem]
}

class LocationsCK : Locations {
    let database = CKContainer.default().publicCloudDatabase
    var cache: Cache?
    let queue = DispatchQueue(label: "Locations")
    let dispatchGroup = DispatchGroup()
    
    static var shared: Locations = LocationsCK()
    
    func synchronize(loaded: ((Int) -> Void)?) {
        queue.sync {
            if cache == nil {
                self.cache = Cache.load() ?? Cache()
            }
            
            let lastDate = cache!.locations
                .filter({ $0.modifiedDate != nil })
                .max(by: { a,b -> Bool in a.modifiedDate! < b.modifiedDate!})

            var predicate = NSPredicate(value: true)
            if lastDate != nil {
                predicate = NSPredicate(format: "modifiedDate > %@", argumentArray: [lastDate!.modifiedDate!])
            }

            let start = DispatchTime.now()
            dispatchGroup.enter()
            _ = self.query(predicate: predicate, sortDescriptors: [], pageSize: 50, progress:{
                loaded?($0)
            }, completionHandler: queryCompletionHandler)
            dispatchGroup.wait()
            cache!.save()
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
            print(timeInterval)
        }
    }
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem] {
        queue.sync {
            return self.cache!.locations.filter(by)
        }
    }
    
    func queryCompletionHandler(records :[LocationRecordDelegate], completed: Bool?, error: Error?)  {
        if let error = error {
            print(error.localizedDescription)
            dispatchGroup.leave()
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
                dispatchGroup.leave()
            }
        }
    }
    
    func query(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], pageSize:Int, progress:@escaping ((Int) -> Void),  completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?) -> Void) -> Query {
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = sortDescriptors
        let operation = CKQueryOperation(query: query)
        let queryOp = QueryCK(operation: operation)
        add(queryOp, progress: progress, completionHandler: completionHandler)
        return queryOp
    }
    
    private func add(_ queryCK : QueryCK, progress: @escaping ((Int) -> Void), completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?) -> Void) {
        var result: [LocationRecordDelegate] = []
        let operation = queryCK.ckOperation
        operation.resultsLimit = 500
        operation.recordFetchedBlock = { record in result.append(record) }
        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                completionHandler([], nil, error)
                return
            }
            if let cursor = cursor {
                completionHandler(result, false, nil)
                progress(result.count)
                result = []
                let operation = CKQueryOperation(cursor: cursor)
                queryCK.set(operation)
                self.add(queryCK, progress:progress, completionHandler:  completionHandler)
                return
            }
            completionHandler(result, true, nil)
        }
        database.add(operation)
    }
}
