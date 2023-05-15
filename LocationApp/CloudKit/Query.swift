//
//  Query.swift
//  LocationApp
//
//  Created by Szöllősi László on 2023. 05. 11..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

class Query {
    
    var operation: Operation
    
    init (operation: Operation) {
        self.operation = operation
    }
    
    func set(_ operation: Operation) {
        self.operation = operation
    }
    
    func cancel() {
        operation.cancel()
    }
}

class QueryCK : Query {
    init (operation: CKQueryOperation) {
        super.init(operation: operation)
    }
    
    var ckOperation: CKQueryOperation {
        return operation as! CKQueryOperation
    }
}
