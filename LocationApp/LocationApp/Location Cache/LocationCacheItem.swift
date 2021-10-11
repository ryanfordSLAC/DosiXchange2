//
//  LocationCacheItem.swift
//  LocationApp
//
// Used to cache Location Cloudit records to disk.
//
//  Created by Matt Lintlop on 10/10/21.
//  Copyright © 2021 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit

 
/*
 record["QRCode"]
 record["latitude"]
 record["longitude"]
 record["locdescription"]
 record["active"]
 record["dosinumber"]
 record["cycleDate"]
 record["collectedFlag"]
 record["mismatch"
 record["moderator"
 record["                                                                                                                                                                                                                                                                                                                                                                                                                                         ”]
 record["modifiedDate"]
 */

// Location Cache Item CloudKit Record Keys
enum LocationCacheItemRecordKeys:NSString {
    case QRCode
    case latitutude
    case longitude
    case description
    case active
    case dosimeter
    case collectedFlag
    case cycle
    case mismatch
    case collectedFlagStr
    case mismatchStr
    case moderator
    case createdDate
    case modifiedDate
 }

// Location Cache Item stores all of the properties of a dosimeter CloudKit record
struct LocationCacheItem {
    var QRCode:NSString = ""
    var latitude:NSString = ""
    var longitude:NSString = ""
    var description:NSString = ""
    var active:Int64 = 0
    var dosimeter:NSString = ""
    var collectedFlag:Int64?
    var cycle:NSString = ""
    var mismatch:Int64?
    var collectedFlagStr:NSString = ""
    var mismatchStr:NSString = ""
    var moderator = ""
    var createdDate:Date?  //during testing the date field may contain nothing
    var modifiedDate:Date?

    // Initialize with a CloudKit Record
    init?(record: CKRecord) {
        // init the QRCode
        guard let QRCode = record["QRCode"] as? NSString else {
            print("ERROR: LocationCacheItem QRCode = nil")
            return nil
        }
        self.QRCode = QRCode

        // init the latitude
        guard let latitude = record["latitude"] as? NSString else {
            print("ERROR: LocationCacheItem QRCode = nil")
            return nil
        }
        self.latitude = latitude
        
        // init the longitude
        guard let longitude = record["longitude"] as? NSString else {
            print("ERROR: LocationCacheItem QRCode = nil")
            return nil
        }
        self.longitude = longitude
        
        // init the description
        guard let description = record["description"] as? NSString else {
            print("ERROR: LocationCacheItem QRCode = nil")
            return nil
        }
        self.description = description
    }
}
