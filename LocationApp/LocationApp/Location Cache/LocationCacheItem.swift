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
struct LocationCacheItem: Codable{
    var QRCode:String = ""
    var latitude:String = ""
    var longitude:String = ""
    var description:String = ""
    var active:Int64 = 0
    var dosimeter:String?     // dosimeter field may contain nothing
    var collectedFlag:Int64?    // collectedFlag field may contain nothing
    var cycleDate:String?     // cycleDate field may contain nothing
    var mismatch:String?      // mismatch field may contain nothing
    var moderator:String?     // moderator field may contain nothing
    var createdDate:Date?       //during testing the date field may contain nothing
    var modifiedDate:Date?

    // Initialize with a CloudKit Record
    init?(withRecord record: CKRecord) {
        // set the QRCode
        guard let QRCode = record["QRCode"] as? String else {
            print("ERROR: LocationCacheItem QRCode = nil")
            return nil
        }
        self.QRCode = QRCode

        // set the latitude
        guard let latitude = record["latitude"] as? String else {
            print("ERROR: LocationCacheItem latitude = nil")
            return nil
        }
        self.latitude = latitude
        
        // set the longitude
        guard let longitude = record["longitude"] as? String else {
            print("ERROR: LocationCacheItem longitude = nil")
            return nil
        }
        self.longitude = longitude
        
        // set the description
        guard let description = record["locdescription"] as? NSString else {
            print("ERROR: LocationCacheItem description = nil")
            return nil
        }
        self.description = description as String
        
        // set the active state
        guard let active = record["active"] as? Int64 else {
            print("ERROR: LocationCacheItem active = nil")
            return nil
        }
        self.active = active
        
        // set the dosimeter
        if let dosimeter = record["dosinumber"] as? NSString {
            self.dosimeter = dosimeter as String
       }
        
        // set the collected flag
        if let collectedFlag = record["collectedFlag"] as? Int64 {
            self.collectedFlag = collectedFlag
        }

        // set the cycle date
        if let cycleDate = record["cycleDate"] as? NSString {
            self.cycleDate = cycleDate as String
        }
        
        // set the mismatch flag
        if let mismatch = record["mismatch"] as? NSString  {
            self.mismatch = mismatch as String
       }
        
        // set the moderator
        if let moderator = record["moderator"] as? NSString {
            self.moderator = moderator as String
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
