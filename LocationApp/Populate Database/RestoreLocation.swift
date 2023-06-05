//
//  RestoreLocation.swift
//  LocationApp
//
//  Created by László Szöllősi on 2023. 06. 05..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

class RestoreLocation {
    static func restore(completionHandler: (() -> Void)?) {
        let database = CKContainer.default().publicCloudDatabase
        
        DispatchQueue.global(qos: .background).async {
            print("Restoring locations.")
            for location in BackupLocations {
                database.fetch(withRecordID: CKRecord.ID(recordName:location.key),
                               completionHandler: { record, error in
                    if let error = error {
                        print("Failed to read record from CK: \(location.key), \(error.localizedDescription)")
                    }
                    if let record = record {
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeStyle = .none
                        dateFormatter.dateFormat = "MM/dd/yy"
                        let modifiedDate = dateFormatter.date(from: location.value)
                        record.setValue(modifiedDate, forKey: "modifiedDate")
                        database.save(record, completionHandler: { record, error in
                         if let error = error {
                             print("Failed to save record to CK: \(location.key), \(error.localizedDescription)")
                         }
                         })
                    }
                })
            }
            print("Restore ended.")
            completionHandler?()
        }
    }
}
