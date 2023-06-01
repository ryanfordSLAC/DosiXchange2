//
//  DIContainer.swift
//  LocationApp
//
//  Created by László Szöllősi on 2023. 06. 01..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation

let container = DIContainer()

class DIContainer {
    private let cacheService = LocationsCK()
            
    public var locations : Locations  {  get {return cacheService }}
    public var settings: SettingsService { get {return cacheService }}
}
