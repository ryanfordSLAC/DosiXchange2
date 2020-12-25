//
//  UploadToCloud.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/26/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit
import UIKit


class Save {

    
    let database = CKContainer.default().publicCloudDatabase
    
/*  this class takes data which can be pasted into the blank file
    and writes it into an array
     
    The array is then parsed and pushed up into the CloudKit as CKRecords
     
    The function can be run by revising the "btnlogdata" outlet temporarily
*/
    
    
    func uploadToCloud() {  //-> Array<Any> {  //probably doesn't need to return anything.
        
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
            
        } //end do
            
        catch {
            print("\(Error.self): Unable to read file")
            
        } //end catch
        
        //write to database
        
        var j = 1  //first row [0] contains ""
        let end = array.count //don't go too far or get fatal error
        
        while j < end - 1 {
            
            let newrecord = CKRecord(recordType: "Location")
            
            //csv data populated fields
            newrecord.setValue(String(array[j][0]), forKey: "QRCode") //first column, index 0
            newrecord.setValue(String(array[j][1]), forKey: "latitude")
            newrecord.setValue(String(array[j][2]), forKey: "longitude")
            newrecord.setValue(String(array[j][3]), forKey: "locdescription")
            newrecord.setValue(Int64(array[j][4]), forKey: "moderator")
            newrecord.setValue(Int64(array[j][5]), forKey: "active")
            newrecord.setValue(String(array[j][6]), forKey: "dosinumber")
            newrecord.setValue(Int64(array[j][7]), forKey: "collectedFlag")
            newrecord.setValue(String(array[j][8]), forKey: "cycleDate")
            newrecord.setValue(Int64(array[j][11]), forKey: "mismatch")
            
            //dates need converstion from string to Date format before writing
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "MM/dd/yy"
            let stringDate = array[j][12]
            let formattedDate = dateformatter.date(from: stringDate)
            newrecord.setValue(formattedDate, forKey: "createdDate")
            
            let dateformatter2 = DateFormatter()
            dateformatter2.dateFormat = "MM/dd/yy"
            let stringDate1 = array[j][13]
            let formattedDate1 = dateformatter2.date(from: stringDate1)
            newrecord.setValue(formattedDate1, forKey: "modifiedDate")
            
            database.save(newrecord) { (record, error) in guard record != nil else { return }
                
            } //end database save
            
            j += 1
            
        }  //end while
    print("Done")
    //return array

    }//end func
    
}//end class
