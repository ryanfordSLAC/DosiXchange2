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
    func start()
    
    func filter(by: (LocationRecordCacheItem) -> Bool) -> [LocationRecordCacheItem]
    
    func query(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], pageSize: Int, completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?) -> Void) -> Query
}

class LocationsCK : Locations {
    let database = CKContainer.default().publicCloudDatabase
    var cache: Cache?
    let queue = DispatchQueue(label: "Locations")
    let dispatchGroup = DispatchGroup()
    
    static var shared: Locations = LocationsCK()
    
    func start() {
        if cache != nil {
            return
        }
        
        self.cache = Cache.load() ?? Cache()
        synchronize()
    }
    
    func synchronize() {
        queue.sync {
            dispatchGroup.enter()
            let lastDate = cache!.locations
                .filter({ $0.modifiedDate != nil })
                .max(by: { a,b -> Bool in a.modifiedDate! < b.modifiedDate!})
            
            var predicate = NSPredicate(value: true)
            if lastDate != nil {
                predicate = NSPredicate(format: "modifiedDate > %@", argumentArray: [lastDate!.modifiedDate!])
            }
            _ = self.query(predicate: predicate, sortDescriptors: [], pageSize: 50, completionHandler: queryCompletionHandler)
            dispatchGroup.wait()
            cache!.save()
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

    
    func query(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], pageSize:Int,  completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?) -> Void) -> Query {
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = sortDescriptors
        let operation = CKQueryOperation(query: query)
        let queryOp = QueryCK(operation: operation)
        add(queryOp, pageSize: pageSize, completionHandler: completionHandler)
        return queryOp
    }
    
    private func add(_ queryCK : QueryCK, pageSize:Int, completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?) -> Void) {
        var result: [LocationRecordDelegate] = []
        let operation = queryCK.ckOperation
        operation.resultsLimit = pageSize
        operation.recordFetchedBlock = { record in result.append(record) }
        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                completionHandler([], nil, error)
                return
            }
            if let cursor = cursor {
                completionHandler(result, false, nil)
                result = []
                let operation = CKQueryOperation(cursor: cursor)
                queryCK.set(operation)
                self.add(queryCK, pageSize: pageSize, completionHandler:  completionHandler)
                return
            }
            completionHandler(result, true, nil)
        }
        database.add(operation)
    }
}
