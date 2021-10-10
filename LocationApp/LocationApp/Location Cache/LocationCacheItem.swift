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
 record["createdDate”]
 record["modifiedDate"]
 */

// Location Cache Item CloudKit Record Keys
enum LocationCacheItemRecordKeys {
    case QRCode(code:String)
    case latitutude
    case longitude
 }

// Location Cache Item stores all of the properties of a dosimeter CloudKit record
struct LocationCacheItem {
    var QRCode:String = ""
    var latitude:String = ""
    var longitude:String = ""
    var loc:String = ""
    var active:Int64 = 0
    var dosimeter:String = ""
    var collectedFlag:Int64?
    var cycle:String = ""
    var mismatch:Int64?
    var collectedFlagStr:String = ""
    var mismatchStr:String = ""
    var csvText = ""
    var moderator = ""
    var createdDate:Date?  //during testing the date field may contain nothing
    var dateModified:Date?

    // Initialize with a CloudKit Record
    init?(record: CKRecord) {
   
    }
}
