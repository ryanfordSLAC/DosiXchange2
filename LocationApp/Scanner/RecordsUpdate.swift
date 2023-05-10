//
//  classRecordsUpdate.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 11/30/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit
import UIKit
import CoreLocation

//Initialize other classes

let svController = ScannerViewController()

class RecordsUpdate: UIViewController {
    
    //variables used to populate the database record

    var locationManager = CLLocationManager()
    var data = [CKRecord]()
    let database = CKContainer.default().publicCloudDatabase
    let dispatchGroup = DispatchGroup()

    func handler(alert: UIAlertAction!){  //used for cancel in the alert prompt.
        
        svController.captureSession.startRunning()
        
    }
    //MARK:  Save Record
    func saveRecord(latitude:String, longitude:String, dosiNumber:String, text:String, flag:Int64, cycle:String, QRCode:String, mismatch:Int64, moderator:Int64, active:Int64, createdDate:Date, modifiedDate:Date) {
                
        //save data to database
        let newRecord = CKRecord(recordType: "Location")
        newRecord.setValue(latitude, forKey: "latitude")
        newRecord.setValue(longitude, forKey: "longitude")
        newRecord.setValue(text, forKey: "locdescription")
        newRecord.setValue(dosiNumber, forKey: "dosinumber")
        newRecord.setValue(flag, forKey: "collectedFlag")
        newRecord.setValue(cycle, forKey: "cycleDate")
        newRecord.setValue(QRCode, forKey: "QRCode")
        newRecord.setValue(moderator, forKey: "moderator")
        newRecord.setValue(active, forKey: "active")
        newRecord.setValue(createdDate, forKey: "createdDate")
        newRecord.setValue(modifiedDate, forKey: "modifiedDate")
        
        let operation = CKModifyRecordsOperation(recordsToSave: [newRecord], recordIDsToDelete: nil)
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        database.add(operation)
        
    }  //end saveRecord
    
    //MARK:  Cycle Date
    static func generateCycleDate() -> String {

        //return the dosimeter wear date for the CKRecord as a string (date format not necessary - will be converted in excel)
        //The wear date is important for post processing the CSV file
        //And for color coding the map pins.
        //There are two cycles per year:  one is January 1 wear date, the other is July 1 wear date
        //(The dosimeters aren't always deployed in January and June)
        
        let currentDate = Date()
        
        let dateFormatterMonth = DateFormatter()
        dateFormatterMonth.dateFormat = "MMMM"
        let dateStringMonth = dateFormatterMonth.string(from: currentDate)
        
        let dateFormatterYear = DateFormatter()
        dateFormatterYear.dateFormat = "yyyy"
        let dateStringYear = dateFormatterYear.string(from: currentDate)
        
        switch dateStringMonth {
            
        case "January":
            return "1-1-\(dateStringYear)"
        case "February":
            return "1-1-\(dateStringYear)"
        case "March":
            return "1-1-\(dateStringYear)"
        case "April":
            return "1-1-\(dateStringYear)"
        case "May":
            return "1-1-\(dateStringYear)"
        case "June":
            return "1-1-\(dateStringYear)" //temp update to 7-1 to allow early deployment.
                                            //rescinded 9/29/2020 
        case "July":
            return "7-1-\(dateStringYear)"
        case "August":
            return "7-1-\(dateStringYear)"
        case "September":
            return "7-1-\(dateStringYear)"
        case "October":
            return "7-1-\(dateStringYear)"
        case "November":
            return "7-1-\(dateStringYear)"
        case "December":
            return "7-1-\(dateStringYear)"
        default:
            return "Cycle Date Error"
            
        } //end switch
        
    } //end generateCycleDate
    
    //MARK:  Prior Cycle Date
    static func generatePriorCycleDate(cycleDate: String) -> String {
        
        let year = Int64(cycleDate.suffix(4))!
        
        let lastYear:Int64 = year - 1
        
        switch cycleDate.first {
            
        case "1":                 //7 and subtract 1 from year
            
            return "7-1-\(String(describing: lastYear))"
            
        case "7":                 //1 and same year
            
            return "1-1-\(String(describing: year))"
            
        default:
            
            return "Prior Cycle Date Error"
            
        }
        
    }
    
    static func getLastCycles(cycles: Int) -> [String] {
        var date = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.month = components.month! < 7 ? 1 : 7
        date = calendar.date(from: components)!
        
        var result = ["\(components.month!)-1-\(components.year!)"]
        for _ in 2...cycles {
            date = calendar.date(byAdding: Calendar.Component.month, value: -6, to: date)!
            components = calendar.dateComponents([.year, .month], from: date)
            result.append("\(components.month!)-1-\(components.year!)")
        }
        return result
    }

} // end class
