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
    var dosimeter:NSString = ""
    var collectedFlag:Int64?
    var cycle:NSString = ""
    var mismatch:Int64?
    var moderator:NSString = ""
    var createdDate:Date?  //during testing the date field may contain nothing
    var modifiedDate:Date?

    // Initialize with a CloudKit Record
    init?(record: CKRecord) {
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
        guard let description = record["description"] as? NSString else {
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
        guard let dosimeter = record["dosimeter"] as? NSString else {
            print("ERROR: LocationCacheItem dosimeter = nil")
            return nil
        }
        self.dosimeter = dosimeter
        
        // set the collected flag
        guard let collectedFlag = record["collectedFlag"] as? Int64 else {
            print("ERROR: LocationCacheItem collectedFlag = nil")
            return nil
        }
        self.collectedFlag = collectedFlag

        // set the cycle
        guard let cycle = record["cycle"] as? NSString else {
            print("ERROR: LocationCacheItem cycle = nil")
            return nil
        }
        self.cycle = cycle
        
        // set the mismatch flag
        guard let mismatch = record["mismatch"] as? Int64 else {
            print("ERROR: LocationCacheItem mismatch = nil")
            return nil
        }
        self.mismatch = mismatch
        
        // set the moderator
        guard let moderator = record["moderator"] as? NSString else {
            print("ERROR: LocationCacheItem moderator = nil")
            return nil
        }
        self.moderator = moderator

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
