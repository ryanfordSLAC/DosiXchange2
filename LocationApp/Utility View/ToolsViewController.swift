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

class ToolsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let readwrite = readWriteText()  //make external class available locally
    let database = CKContainer.default().publicCloudDatabase  //establish database
    let dispatchGroup = DispatchGroup()
    
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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    let borderColorUp = UIColor(red: 0.580723, green: 0.0667341, blue: 0, alpha: 1).cgColor
    let borderColorDown = UIColor(red: 0.580723, green: 0.0667341, blue: 0, alpha: 0.25).cgColor
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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
        
    }
    
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
    
    @IBAction func emailTouchUp(_ sender: Any) {
        
        queryDatabaseForCSV() //takes up to 5 seconds
        
        dispatchGroup.wait() //wait for query to finish
        
        self.readwrite.writeText(someText: "\(csvText)")
        self.sendEmail()
        
        //stop activityIndicator
        activityIndicator.stopAnimating()
        button3.layer.borderColor = borderColorUp
    }
    
    
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
        
        controller.dismiss(animated: true)
        
    } //end func mailComposeController
}


//query and helper functions
extension ToolsViewController {
    
    func queryDatabaseForCSV() {
        
        //set first line of text file
        //should separate text file from query
        dispatchGroup.enter()
        self.csvText = "LocationID (QRCode),Latitude,Longitude,Description,Moderator (0/1),Active (0/1),Dosimeter,Collected Flag (0/1),Wear Period,Date Deployed,Date Collected,Mismatch (0/1)\n"
        let predicate = NSPredicate(value: true)
        let sort1 = NSSortDescriptor(key: "QRCode", ascending: true)
        let sort2 = NSSortDescriptor(key: "creationDate", ascending: false)
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
        QRCode = record["QRCode"]!
        latitude = record["latitude"]!
        longitude = record["longitude"]!
        loc = record["locdescription"]!
        active = record["active"]!
        if record["dosinumber"] != nil {dosimeter = record["dosinumber"]!}
        if record["cycleDate"] != nil {cycle = record["cycleDate"]!}
        if record["collectedFlag"] != nil {collectedFlagStr = String(describing: record["collectedFlag"]!)}
        if record["mismatch"] != nil {mismatchStr = String(describing: record["mismatch"]!)}
        if record["moderator"] != nil {moderator = String(describing: record ["moderator"]!)}
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let date = Date(timeInterval: 0, since: record.creationDate!)
        let formattedDate = dateFormatter.string(from: date)
        let dateModified = Date(timeInterval: 0, since: record.modificationDate!)
        let formattedDateModified = dateFormatter.string(from: dateModified)
        let newline = "\(QRCode),\(latitude),\(longitude),\(loc),\(moderator),\(active),\(dosimeter),\(collectedFlagStr),\(cycle),\(formattedDate),\(formattedDateModified),\(mismatchStr)\n"
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
    }
    
} //end class
