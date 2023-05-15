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
}

class LocationsCK : Locations {
    let database = CKContainer.default().publicCloudDatabase
    var cache: Cache?
    let queue = DispatchQueue(label: "Locations")
    
    static var shared: Locations = LocationsCK()
    
    func synchronize(loaded: @escaping  ((Int) -> Void)) {
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

            _ = self.query(predicate: predicate, sortDescriptors: [], pageSize: 50, loaded:loaded, completionHandler: queryCompletionHandler)
        }
    }
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem] {
        queue.sync {
            return self.cache!.locations.filter(by)
        }
    }
    
    func queryCompletionHandler(records :[LocationRecordDelegate], completed: Bool?, error: Error?, loaded: @escaping ((Int) -> Void))  {
        if let error = error {
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
            }
        }
    }
    
    func query(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], pageSize:Int,  loaded: @escaping ((Int) -> Void), completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?,@escaping ((Int) -> Void)) -> Void) -> Query {
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = sortDescriptors
        let operation = CKQueryOperation(query: query)
        let queryOp = QueryCK(operation: operation)
        add(queryOp, loaded: loaded, completionHandler: completionHandler)
        return queryOp
    }
    
    private func add(_ queryCK : QueryCK, loaded: @escaping ((Int) -> Void), completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?,@escaping ((Int) -> Void)) -> Void) {
        var result: [LocationRecordDelegate] = []
        let operation = queryCK.ckOperation
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
                queryCK.set(operation)
                self.add(queryCK, loaded:loaded, completionHandler:  completionHandler)
                return
            }
            completionHandler(result, true, nil, loaded)
        }
        database.add(operation)
    }
}
