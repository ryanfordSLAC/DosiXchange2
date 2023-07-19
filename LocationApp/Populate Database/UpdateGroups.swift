//
//  UpdateGroups.swift
//  LocationApp
//
//  Created by Szöllősi László on 2023. 05. 23..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation

class UpdateGroups {
    
    static func update(completionHandler: (() -> Void)?) {
        let locations = container.locations
        
        let items = locations.filter(by: { _ in true })
        var changed = [LocationRecordCacheItem]()
        for item in items {
            if let group = Groups[item.QRCode], group != item.reportGroup {
                item.setValue(group, forKey: "reportGroup")
                changed.append(item)
            }
        }
        if !changed.isEmpty {
            locations.save(items: changed, completionHandler: completionHandler)
        }
        else {
            DispatchQueue.main.async {
                completionHandler?()
            }
        }
    }
    
    static func updateRGFromPreviousLocations(completionHandler: (() -> Void)?) {
        print("updateRGFromPreviousLocations")
        let locations = container.locations
               
        let all = locations.filter(by: { _ in true })
        let buff = all.filter({ l in l.QRCode == "BLG 006-005"})
        let missingGroups = all.filter({ l in l.reportGroup == nil || l.reportGroup!.isEmpty })
        if !missingGroups.isEmpty {
            var changes = [LocationRecordCacheItem]()
            for missing in missingGroups {
                if let group = all.first(where: { l in l.reportGroup != nil && !l.reportGroup!.isEmpty}).map( {l in l.reportGroup}) {
                    missing.reportGroup = group
                    changes.append(missing)
                }
            }
                        
            locations.save(items: changes, completionHandler: completionHandler)
        }
        else {
            completionHandler?()
        }
    }
}
