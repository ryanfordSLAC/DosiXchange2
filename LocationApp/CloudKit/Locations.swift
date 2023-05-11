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
    
    func query(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], pageSize: Int, completionHandler: @escaping ([LocationRecordDelegate], Bool?, Error?) -> Void) -> Query
}

class LocationsCK : Locations {
    let database = CKContainer.default().publicCloudDatabase
    
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
