//
//  BriefCase.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 12/20/20.
//  Copyright © 2020 Ford, Ryan M. All rights reserved.
//

import Foundation

class BriefCase {
    /*requires field in data schema for briefCase as integer
    1 = record was changed (set in briefcase load and sent to server during sync
    0 = record is not changed
    requires button on home screen to turn on briefcase mode
    very unlikely two people will try to exchange the same dosimeter because
        they're assigned to areas and can see the new dosimeter color when exchanging.
    changes from 1 to 0 during upload
    
    */
    
    func synchronize() {
        //check if briefcase is active
        //check if briefcase is empty or full
        //check for wifi (needed to pull new records)
        //if full:  check for changes locally (indicated as "1" in briefCase field)
        //      then:  upload changed records
        //      then:  clear briefcase
        //if empty: download new records

        //issue alert with report (## records modified & uploaded)
    
    }
    
    
    func briefcaseIsActive() -> Int {
        //check if we're in briefcase mode or wifi mode
        
        return 1
    }
    
    
    func saveLocal() {
        //download new records
        
    }
    
    func saveServer() {
        //upload changed records
        
    }
    
    func setCoordinates() {
        //for the record in question:
        //check if the location exits
        //if location does not exist supply generic coordinates
        //if location exists supply prior coordinates
        
    }
    
    func modifyBriefcase() {
        //identify record
        //make changes
        //set the briefcase flag
        //ready for upload
        
    }
    
    func setBriefcaseFlag() {
        //
        //set briefcase field/index to 1
        
        
    }
    
    func clearBriefcase() -> Int {
        //runs after data is uploaded
        
        
        return 1  //briefcase is full
        
    
    }

}
