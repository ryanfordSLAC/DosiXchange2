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
}
