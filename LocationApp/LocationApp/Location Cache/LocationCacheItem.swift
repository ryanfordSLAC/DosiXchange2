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
    var dosimeter:NSString?     // dosimeter field may contain nothing
    var collectedFlag:Int64?    // collectedFlag field may contain nothing
    var cycleDate:NSString?     // cycleDate field may contain nothing
    var mismatch:NSString?      // mismatch field may contain nothing
    var moderator:NSString?     // moderator field may contain nothing
    var createdDate:Date?       //during testing the date field may contain nothing
    var modifiedDate:Date?

    // Initialize with a CloudKit Record
    init?(withRecord record: CKRecord) {
        // set the QRCode
        guard let QRCode = record["QRCode"] as? NSString else {
            print("ERROR: LocationCacheItem QRCode = nil")
            return nil
        }
        self.QRCode = QRCode

        // set the latitude
        guard let latitude = record["latitude"] as? NSString else {
            print("ERROR: LocationCacheItem latitude = nil")
            return nil
        }
        self.latitude = latitude
        
        // set the longitude
        guard let longitude = record["longitude"] as? NSString else {
            print("ERROR: LocationCacheItem longitude = nil")
            return nil
        }
        self.longitude = longitude
        
        // set the description
        guard let description = record["locdescription"] as? NSString else {
            print("ERROR: LocationCacheItem description = nil")
            return nil
        }
        self.description = description
        
        // set the active state
        guard let active = record["active"] as? Int64 else {
            print("ERROR: LocationCacheItem active = nil")
            return nil
        }
        self.active = active
        
        // set the dosimeter
        if let dosimeter = record["dosinumber"] as? NSString {
            self.dosimeter = dosimeter
       }
        
        // set the collected flag
        if let collectedFlag = record["collectedFlag"] as? Int64 {
            self.collectedFlag = collectedFlag
        }

        // set the cyclebdate
        if let cycleDate = record["cycleDate"] as? NSString {
            self.cycleDate = cycleDate
        }
        
        // set the mismatch flag
        if let mismatch = record["mismatch"] as? NSString  {
            self.mismatch = mismatch
       }
        
        // set the moderator
        if let moderator = record["moderator"] as? NSString {
            self.moderator = moderator
        }

        // set the creation date
        if let createdDate = record["createdDate"] as? NSString {
            print("TODO: Handle createdDate = \(createdDate)")
        }

        // set the modified date
        if let modifiedDate = record["modifiedDate"] as? NSString {
            print("TODO: Handle modifiedDate = \(modifiedDate)")
        }
    }
}
