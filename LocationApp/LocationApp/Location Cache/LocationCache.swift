//
//  LocationCache.swift
//  LocationApp
//
//  Created by Matt Lintlop on 10/10/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

class LocationCache {
    
    static let shared = LocationCache()
    
    var dosimeterRecordIDs: [CKRecord.ID]?
    
    private init() {
    }
    
    func didFetchRecords(_ records: [CKRecord]) {
        if self.dosimeterRecordIDs == nil {
            self.dosimeterRecordIDs = [CKRecord.ID]()
        }
        for record in records {
            self.dosimeterRecordIDs!.append(record.recordID)
        }
    }
    
    func didStartFetchingRecords() {
        print("Started fetching records")
    }
    
    func didFinishFetchingRecords(_ records: [CKRecord]) {
        print("Finshed fetching \(records.count) records")
    }
}
