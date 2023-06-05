//
//  SettingsService.swift
//  LocationApp
//
//  Created by László Szöllősi on 2023. 06. 01..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation

protocol SettingsService {
    
    func getSettings(completionHandler: @escaping (Settings) -> Void)
}
