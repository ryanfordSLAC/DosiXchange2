//
//  UploadToCloud.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/26/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit



//This class takes a list of recordNames and deletes them.
//Used on 12/25/2020 to wipe the entire production DB to start over with upload
//because the cycleDate was formatted incorrectly.

class RepairCycleDate {

    var record = CKRecord.ID()
    let database = CKContainer.default().publicCloudDatabase  //establish database
    var recordName: String = ""


    func loadArray() {
        
        var array:[[String]] = [[""]] //initialize the array
        
        do {
            
            let fileName = "Data_File" //change depending on which file
            let path = Bundle.main.path(forResource: fileName, ofType: "csv")
            let data = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            let rows = data.components(separatedBy: "\n")  //removed \r

            for row in rows {
                let values = row.components(separatedBy: ",")
                array.append(values)
            } //end for
            print(array)
        } //end do
            
        catch {
            print("\(Error.self): Unable to read file")
            
        } //end catch
        
        var j = 1  //first row [0] contains ""
        let end = array.count //don't go too far or get fatal error
        while j < end - 1 {
            print("arrayj0: \(array[j][0])")
            modifyAllRecords(myrecordName: array[j][0])
            
        j += 1
            
        }
    }
    
    func modifyAllRecords(myrecordName:String) {
        
        
        
        //fetch the record
        let recID = CKRecord.ID(recordName: myrecordName)
        print("recID: \(recID)")
        database.fetch(withRecordID: recID) { (fetch, error) in
            if (error != nil) { // this will be equal to whatever value is set in this method call
                print("Error1: \(error.debugDescription)")
            } else {
                print(fetch!)
                self.record = fetch!.recordID
                print("success")
            }
        }
        //delete fetched record
        database.delete(withRecordID: recID) { (recordZone, error) in
            if (error != nil) { // this will be equal to whatever value is set in this method call
                print("Error2: \(error.debugDescription)")
            } else {
                print("deleted!")
            }
        }
    
    
    }//end func



    
}//end class
