//
//  DosimeterRecordCacheItem.swift
//  LocationApp
//
// Used to cache Location Cloudit records to disk.
//
//  Created by Matt Lintlop on 10/10/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

protocol LocationRecordDelegate {
    subscript(key: String) -> CKRecordValue? {get}
}

extension CKRecord: LocationRecordDelegate{
    // CKRecord already implements the DosimeterRecordDelegate protocol
    // to access properties with a subscript so this protocol is empty.
}

// Dosimetr Cache Item stores all of the properties of a dosimeter CloudKit record
struct LocationRecordCacheItem: Codable, LocationRecordDelegate{
    
    /* CloudKit Location Scheme
     active          INT64 QUERYABLE SORTABLE,
     collectedFlag   INT64 QUERYABLE SORTABLE,
     createdDate     TIMESTAMP QUERYABLE SORTABLE,
     cycleDate       STRING QUERYABLE SORTABLE,
     dosinumber      STRING QUERYABLE SEARCHABLE SORTABLE,
     latitude        STRING QUERYABLE SORTABLE,
     locdescription  STRING QUERYABLE SEARCHABLE SORTABLE,
     longitude       STRING QUERYABLE SORTABLE,
     mismatch        INT64 QUERYABLE SORTABLE,
     moderator       INT64 QUERYABLE SORTABLE,
     modifiedDate    TIMESTAMP QUERYABLE SORTABLE,
     */

    // Properties to cache the CloidKit Location Record
    
    var QRCode:String = ""              // QR Code
    var latitude:String = ""            // latitude
    var longitude:String = ""           // longitude
    var locdescription:String = ""      // location Description
    var active:Int64 = 0                // active
    var dosinumber:String?              // dosinumber field may contain nothing
    var collectedFlag:Int64?            // collectedFlag field may contain nothing
    var cycleDate:String?               // cycleDate field may contain nothing
    var mismatch:Int64?                 // mismatch field may contain nothing
    var moderator:Int64?                // moderator field may contain nothing
    var createdDate:Date?               // creation date
    var modifiedDate:Date?              // modified date
  
    // Initialize with a CloudKit Record
    init?(withRecord record: CKRecord) {
          
        // set the QRCode
        guard let QRCode = record["QRCode"] as? String else {
            print("ERROR: Location record QRCode is empty")
            return nil
        }
        self.QRCode = QRCode

        // set the latitude
        guard let latitude = record["latitude"] as? String else {
            print("ERROR: Location record latitude is empty")
            return nil
        }
        self.latitude = latitude
        
        // set the longitude
        guard let longitude = record["longitude"] as? String else {
            print("ERROR: Location record longitude is empty")
            return nil
        }
        self.longitude = longitude
        
        // set the description
        guard let locdescription = record["locdescription"] as? NSString else {
            print("ERROR: Location record locdescription is empty")
            return nil
        }
        self.locdescription = locdescription as String
        
        // set the active state
        guard let active = record["active"] as? Int64 else {
            print("ERROR: Location record active is empty")
            return nil
        }
        self.active = active
        
        // set the dosimeter
        guard let dosinumber = record["dosinumber"] as? NSString else {
            print("ERROR: Location record dosinumber is empty")
           return nil
        }
        self.dosinumber = dosinumber as String

        // set the collected flag
        guard let collectedFlag = record["collectedFlag"] as? Int64 else {
            print("ERROR: Location record collectedFlag is empty")
            return nil
        }
        self.collectedFlag = collectedFlag

        // set the cycle date
        guard let cycleDate = record["cycleDate"] as? NSString else {
            print("ERROR: Location record cycleDate is empty")
            return nil
        }
        self.cycleDate = cycleDate as String

        // set the mismatch flag
        if let mismatch = record["mismatch"] as? Int64 {
            self.mismatch = mismatch
        }
        
        // set the moderator
        guard let moderator = record["moderator"] as? Int64 else {
            print("ERROR: Location record moderator is empty")
            return nil
       }
        self.moderator = moderator

        // set the creation date
        // Note: createdDate can be null while debugging
        let createdDate = record["createdDate"] as? NSString

//      Deugging: Uncomment code for Production
//        guard let createdDate = record["createdDate"] as? NSString else {
//            print("ERROR: Location record createdDate is empty")
//            return nil
//        }
        if createdDate != nil {
            print("Location: \(self.locdescription) : createDate = \(createdDate!)")
 
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateFormat = "MM/dd/yyyy"
        }
//        self.createdDate = createdDate

        // set the modified date
        // Note: modifiedDate can be null while debugging
        let modifiedDate = record["modifiedDate"] as? NSString
        
//      Deugging: Uncomment code for Production
//        guard let modifiedDate = record["modifiedDate"] as? NSString else {
//            print("ERROR: Location record modifiedDate is empty")
//            return nil
//       }
        if modifiedDate != nil {
            print("Location: \(self.locdescription) : modifiedDate = \(modifiedDate!)")

            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateFormat = "MM/dd/yyyy"
        }
//        self.modifiedDate = modifiedDate
   }
    
    // Subscript operator overload used to access properties.
    subscript(key: String) -> CKRecordValue? {
        get {
            switch key {
                case "QRCode":
                    return QRCode as CKRecordValue
                   
                case "active":
                  return active as CKRecordValue
                   
                case "latitude":
                  return latitude as CKRecordValue
               
                case "longitude":
                   return longitude as CKRecordValue
                   
                case "locdescription":
                   return locdescription as CKRecordValue

                case "dosinumber":
                    if dosinumber != nil {
                        return dosinumber! as CKRecordValue
                    }
                    else {
                        return nil
                    }

                case "collectedFlag":
                    if collectedFlag != nil {
                        return collectedFlag! as CKRecordValue
                    }
                    else {
                        return nil
                    }

                case "cycleDate":
                    if cycleDate != nil {
                        return cycleDate! as CKRecordValue
                    }
                    else {
                        return nil
                    }

               case "mismatch":
                    if mismatch != nil {
                        return mismatch! as CKRecordValue
                    }
                    else {
                        return nil
                    }

               case "moderator":
                    if moderator != nil {
                        return moderator! as CKRecordValue
                    }
                    else {
                        return nil
                    }

               case "createdDate":
                    if createdDate != nil {
                        return createdDate! as CKRecordValue
                    }
                    else {
                        return nil
                    }

               case "modifiedDate":
                    if modifiedDate != nil {
                        return modifiedDate! as CKRecordValue
                    }
                    else {
                        return nil
                    }

               default:
                  return nil
               }
           }
    }
}
