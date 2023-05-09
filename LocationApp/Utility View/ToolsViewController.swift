//
//  ToolsViewController.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/12/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import CloudKit
import AVFoundation
//MARK:  Class
class ToolsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let readwrite = readWriteText()  //make external class available locally
    let database = CKContainer.default().publicCloudDatabase  //establish database
    let dispatchGroup = DispatchGroup()
    let saveToCloud = Save()
    let queries = Queries()
    let repair = RepairCycleDate()
    
    var QRCode:String = ""
    var latitude:String = ""
    var longitude:String = ""
    var loc:String = ""
    var active:Int64 = 0
    var dosimeter:String = ""
    var collectedFlag:Int64?
    var cycle:String = ""
    var mismatch:Int64?
    var collectedFlagStr:String = ""
    var mismatchStr:String = ""
    var csvText = ""
    var moderator = ""
    var mycreatedDate:Date?  //during testing the date field may contain nothing
    var myDateModified:Date?

    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var resetCacheButton: UIButton!

    
    let borderColorUp = UIColor(red: 0.580723, green: 0.0667341, blue: 0, alpha: 1).cgColor
    let borderColorDown = UIColor(red: 0.580723, green: 0.0667341, blue: 0, alpha: 0.25).cgColor
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        
        //format buttons
        button1.layer.borderWidth = 1.5
        button1.layer.borderColor = borderColorUp
        button1.layer.cornerRadius = 22
        
        button2.layer.borderWidth = 1.5
        button2.layer.borderColor = borderColorUp
        button2.layer.cornerRadius = 22
        
        button3.layer.borderWidth = 1.5
        button3.layer.borderColor = borderColorUp
        button3.layer.cornerRadius = 22
 
        resetCacheButton.layer.borderWidth = 1.5
        resetCacheButton.layer.borderColor = borderColorUp
        resetCacheButton.layer.cornerRadius = 22
    }
    
    //@IBAction func uploadToCloud(_ sender: Any) {
     //   activityIndicator.startAnimating()
      //  saveToCloud.uploadToCloud()
     //   activityIndicator.stopAnimating()
        
        
    //}
    @IBAction func button1down(_ sender: Any) {
        button1.layer.borderColor = borderColorDown
    }
    
    @IBAction func button1up(_ sender: Any) {
        button1.layer.borderColor = borderColorUp
    }
    
    @IBAction func button2down(_ sender: Any) {
        button2.layer.borderColor = borderColorDown
    }
    
    @IBAction func button2up(_ sender: Any) {
        button2.layer.borderColor = borderColorUp
    }
    
    @IBAction func button3down(_ sender: Any) {
        button3.layer.borderColor = borderColorDown
        //start activityIndicator
        activityIndicator.startAnimating()
    }
    
    @IBAction func button3up(_ sender: Any) {
        button3.layer.borderColor = borderColorUp
        //release Email Data button from outside
        //stop activityIndicator
        activityIndicator.stopAnimating()
    }
/*
    @IBAction func UploadtoCloud(_ sender: Any) {
        let n:Save = Save()
        n.uploadToCloud()
    } */
    
    @IBAction func emailTouchUp(_ sender: Any) {
        
        showExportAlert()
        button3.layer.borderColor = borderColorUp
    }
    
    @IBAction func resetCacheTouchUp(_ sender: Any) {
        LocationRecordCache.shared.resetCache()
    }
    
    //MARK:  Send Email
    func sendEmail() {
        
        let URL =  readwrite.messageURL
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            //mail.setToRecipients(["ryanford@slac.stanford.edu"])
            mail.setSubject("Area Dosimeter Data")
            mail.setMessageBody("The dosimeter data is attached to this e-mail.", isHTML: true)
            
            if let fileAttachment = NSData(contentsOf: URL!) {
                mail.addAttachmentData(fileAttachment as Data, mimeType: "text/csv", fileName: "Dosi_Data.csv")
            } //end if let
            
            present(mail, animated: true)
        }
            
        else {
            //show failure alert
        }
        
    } //end func sendEmail
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        //Play email sent sound
        let systemSoundID: SystemSoundID =  1001
        AudioServicesPlaySystemSound(systemSoundID)
        controller.dismiss(animated: true)
    } //end func mailComposeController
    
    func showExportAlert() {
        let alert = UIAlertController(title: "Export locations data", message: "Select cycle count", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "2 cycle", style: .default, handler: { _ in self.sendEmail(2) }))
        alert.addAction(UIAlertAction(title: "3 cycle", style: .default, handler: { _ in self.sendEmail(3) }))
        alert.addAction(UIAlertAction(title: "4 cycle", style: .default, handler: { _ in self.sendEmail(4) }))
        alert.addAction(UIAlertAction(title: "All cycle", style: .default, handler: { _ in self.sendEmail(0) }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func sendEmail(_ cycle: Int) {
        queryDatabaseForCSV(cycle) //takes up to 5 seconds
        
        dispatchGroup.wait() //wait for query to finish
        
        self.readwrite.writeText(someText: "\(csvText)")
        self.sendEmail()
        //stop activityIndicator
        activityIndicator.stopAnimating()
        button3.layer.borderColor = borderColorUp
    }
}


//query and helper functions
//MARK:  Extension
extension ToolsViewController {
    
    func queryDatabaseForCSV(_ cycles: Int) {
        
        //set first line of text file
        //should separate text file from query
        dispatchGroup.enter()
        self.csvText = "LocationID (QRCode),Latitude,Longitude,Description,Moderator (0/1),Active (0/1),Dosimeter,Collected Flag (0/1),Wear Period,System_Date Deployed,System_Date Collected,Mismatch (0/1), my_Date Deployed, my_Date Collected, recordID\n"
        var predicate = NSPredicate(value: true)
        if (cycles > 0) {
            let cycleDates = RecordsUpdate.getLastCycles(cycles: cycles)
            predicate = NSPredicate(format: "cycleDate in %@", cycleDates)
        }
        let sort1 = NSSortDescriptor(key: "QRCode", ascending: true)
        //let sort2 = NSSortDescriptor(key: "creationDate", ascending: false)
        let sort2 = NSSortDescriptor(key: "createdDate", ascending: false)  //Ver 1.2
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort1, sort2]
        let operation = CKQueryOperation(query: query)
        addOperation(operation: operation)
        
    } //end function
    
    
    // add query operation
    func addOperation(operation: CKQueryOperation) {
        operation.resultsLimit = 200 // max 400; 200 to be safe
        operation.recordFetchedBlock = self.recordFetchedBlock // to be executed for each fetched record
        operation.queryCompletionBlock = self.queryCompletionBlock // to be executed after each query (query fetches 200 records at a time)
        
        database.add(operation)
    }
    
    // to be executed after each query (query fetches 200 records at a time)
    func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            addOperation(operation: operation)
            return
        }
        csvText.append("End of File\n")
        dispatchGroup.leave()
    }
    
    // to be executed for each fetched record
    func recordFetchedBlock(record: CKRecord) {
        //Careful use of optionals to prevent crashes.
        
        //block 1:  these fields always have a value
        QRCode = record["QRCode"]!
        latitude = record["latitude"]!
        longitude = record["longitude"]!
        loc = record["locdescription"]!
        active = record["active"]!
        
        //block 2:  these fields sometimes have a value
        if record["dosinumber"] != nil {dosimeter = record["dosinumber"]!}
        if record["cycleDate"] != nil {cycle = record["cycleDate"]!}
        if record["collectedFlag"] != nil {collectedFlagStr = String(describing: record["collectedFlag"]!)}
        if record["mismatch"] != nil {mismatchStr = String(describing: record["mismatch"]!)}
        if record["moderator"] != nil {moderator = String(describing: record ["moderator"]!)}
        
        //my fields for created and modified dates:

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        //system dates - createdDate and modifiedDate Ver 1.2
        
        //block 3: these fields always have a value and are called differently than my date fields
        //let date = Date(timeInterval: 0, since: record.creationDate!)
        let date = Date(timeInterval: 0, since: record["createdDate"] as! Date) //Ver 1.2
        let formattedDate = dateFormatter.string(from: date)
        //let dateModified = Date(timeInterval: 0, since: record.modificationDate!)
        let dateModified = Date(timeInterval: 0, since: record["modifiedDate"] as! Date)
        let formattedDateModified = dateFormatter.string(from: dateModified)
        
        //block 4: may not have a value when initially set up and tested
        //but will eventually always have a value
        if record["createdDate"] != nil {
            mycreatedDate = Date(timeInterval: 0, since: record["createdDate"] as! Date)
        } else {
                //can't set the date as nil
                //but if the date is old enough it populates a nil in the field.
                //the cutoff is around -1E10 seconds ago where it stops showing dates
            mycreatedDate = Date(timeInterval: -1E15, since: Date())
        }
        let myformattedCreatedDate = dateFormatter.string(from: mycreatedDate!)
        
        if record["modifiedDate"] != nil {
            myDateModified = Date(timeInterval: 0, since: record["modifiedDate"] as! Date)
        } else {
            myDateModified = Date(timeInterval: -1E15, since: Date())
        }
        let myformattedDateModified = dateFormatter.string(from: myDateModified!)
        let recordID = record.recordID.recordName
        
        //write the data into the file.
        let newline = "\(QRCode),\(latitude),\(longitude),\(loc),\(moderator),\(active),\(dosimeter),\(collectedFlagStr),\(cycle),\(formattedDate),\(formattedDateModified),\(mismatchStr),\(myformattedCreatedDate),\(myformattedDateModified), \(recordID)\n"
        csvText.append(contentsOf: newline)
        clear()
    }
    
    // clear variable data
    func clear() {
        QRCode = ""
        latitude = ""
        longitude = ""
        loc = ""
        active = 0
        dosimeter = ""
        collectedFlag = nil
        cycle = ""
        mismatch = nil
        collectedFlagStr = ""
        mismatchStr = ""
        //not clearing date fields?
    }
    
} //end class
