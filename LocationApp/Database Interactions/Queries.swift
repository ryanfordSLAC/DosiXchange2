//
//  Queries.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/30/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit


//Potentially a place to move all queries and consolidate/shrink
//some queries in their respective view controllers.

class Queries {
    var qrCode:String = ""
    var dosiNumber:String = ""
    var count = Int()
    var countCFNo = Int()
    var countCFYes = Int()
    let recordsupdate = recordsUpdate()
    let dispatchGroup = DispatchGroup()
    var records = [CKRecord]()
    let database = CKContainer.default().publicCloudDatabase
    
    func getPriorCycleCountCFYes() {
        
        
        dispatchGroup.wait()
        dispatchGroup.enter()
        count = 0
        
        //get current Cycle Date
        let cycleDate = self.recordsupdate.generateCycleDate()
        let priorCycleDate = self.recordsupdate.generatePriorCycleDate(cycleDate: cycleDate)
        let flag = 1
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "cycleDate == %@", priorCycleDate)
        let p3 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])
        
        //  Query fields in Location to set up the artwork on the drop pins
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.queryCompletionBlock = self.queryCompletionBlockCFYes
        addOperation(operation: operation)
        
    } //end func
    
    
    func getPriorCycleCountCFNo() {
        
        dispatchGroup.wait()
        dispatchGroup.enter()
        count = 0
        
        //get current Cycle Date
        let cycleDate = self.recordsupdate.generateCycleDate()
        let priorCycleDate = self.recordsupdate.generatePriorCycleDate(cycleDate: cycleDate)
        let flag = 0
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "cycleDate == %@", priorCycleDate)
        let p3 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])

        //  Query fields in Location to set up the artwork on the drop pins
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.queryCompletionBlock = self.queryCompletionBlockCFNo
        addOperation(operation: operation)

    } //end func
    
    
    // add query operation
    func addOperation(operation: CKQueryOperation) {
        operation.resultsLimit = 200
        operation.recordFetchedBlock = self.recordFetchedBlock
        database.add(operation)
    }
    
    
    // to be executed for each fetched record
    func recordFetchedBlock(record: CKRecord) {
        self.count += 1
    }
    
    
    // to be executed after each CFYes query (query fetches 200 records at a time)
    func queryCompletionBlockCFYes(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            operation.queryCompletionBlock = self.queryCompletionBlockCFYes
            addOperation(operation: operation)
            return
        }
        self.countCFYes = self.count
        self.count = 0
        self.dispatchGroup.leave()
    }
    
    
    // to be executed after each CFNo query (query fetches 200 records at a time)
    func queryCompletionBlockCFNo(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            operation.queryCompletionBlock = self.queryCompletionBlockCFNo
            addOperation(operation: operation)
            return
        }
        self.countCFNo = self.count
        self.count = 0
        self.dispatchGroup.leave()
    }
    
    
} //end class
