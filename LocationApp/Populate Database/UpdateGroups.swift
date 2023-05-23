//
//  UpdateGroups.swift
//  LocationApp
//
//  Created by Szöllősi László on 2023. 05. 23..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation

class UpdateGroups {
    
    func update() {
        let locations = LocationsCK.shared
        
        let items = locations.filter(by: { _ in true })
        for item in items {
            item.setValue(Groups[item.QRCode], forKey: <#T##String#>)
        }
    }
}
