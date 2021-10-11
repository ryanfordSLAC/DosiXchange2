//
//  LocationCache.swift
//  LocationApp
//
//  Created by Matt Lintlop on 10/10/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

class LocationCache: Codable {
    
    static let shared = LocationCache()
    
    var dosimeterRecordNames: [String]?
    
    private init() {
    }
    
    func didFetchRecords(_ records: [CKRecord]) {
        if self.dosimeterRecordNames == nil {
            self.dosimeterRecordNames = [String]()
        }
        for record in records {
            self.dosimeterRecordNames!.append(record.recordID.recordName)
        }
    }
    
    func didStartFetchingRecords() {
        print("Started fetching records")
    }
    
    func didFinishFetchingRecords(_ records: [CKRecord]) {
        print("Finshed fetching \(records.count) records")
    }
}
