//
//  LocationDetails.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/16/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import UIKit
import CloudKit

//MARK:  Class
class LocationDetails: UIViewController {
    
    let locations = LocationsCK.shared
    var record: LocationRecordDelegate = CKRecord(recordType: "Location")
    var QRCode = ""
    var loc = ""
    var lat = ""
    var long = ""
    var active = 0
    
    var records = [LocationRecordDelegate]()
    var details = [(String, String, String, Int, Int)]()
    
    let dispatchGroup = DispatchGroup()
    let database = CKContainer.default().publicCloudDatabase
    
    @IBOutlet weak var QRLabel: UILabel!
    @IBOutlet weak var locDescription: UILabel!
    @IBOutlet weak var fields: UILabel!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var qrTable: UITableView!
    
    //popup outlets
    @IBOutlet weak var popupConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundButton: UIButton!
    @IBOutlet weak var editRecordPopup: UIView!
    
    @IBOutlet weak var dateCreated: UILabel!
    @IBOutlet weak var dateModified: UILabel!
    
    @IBOutlet weak var pQRCode: UILabel!
    @IBOutlet weak var pDescription: UITextField!
    @IBOutlet weak var pLatitude: UITextField!
    @IBOutlet weak var pLongitude: UITextField!
    @IBOutlet weak var pDosimeter: UITextField!
    @IBOutlet weak var pCycleDate: UITextField!
    
    @IBOutlet weak var pModerator: UISwitch!
    @IBOutlet weak var pCollected: UISwitch!
    @IBOutlet weak var pMismatch: UISwitch!
    
    var popupRecord: LocationRecordDelegate = CKRecord(recordType: "Location")
    var moderator = 0
    var collected = 0
    var mismatch = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
        
        
        //Do any additional setup after loading the view.
        
        qrTable.delegate = self
        qrTable.dataSource = self
        
        showDetails()
        
        //pre-popup set up
        backgroundButton.alpha = 0
        editRecordPopup.layer.cornerRadius = 10
        popupConstraint.constant = 600
        pModerator.addTarget(self, action: #selector(moderatorSwitch), for: .valueChanged)
        pCollected.addTarget(self, action: #selector(collectedSwitch), for: .valueChanged)
        pMismatch.addTarget(self, action: #selector(mismatchSwitch), for: .valueChanged)
        
        pDescription.delegate = self
        pLatitude.delegate = self
        pLongitude.delegate = self
        pDosimeter.delegate = self
        pCycleDate.delegate = self
        
    }
    //MARK:  Show Details
    func showDetails() {
        
        //get location details from record
        QRCode = record.value(forKey: "QRCode") as! String
        loc = record.value(forKey: "locdescription") as! String
        lat = record.value(forKey: "latitude") as! String
        long = record.value(forKey: "longitude") as! String
        active = record.value(forKey: "active") as! Int
        
        //set QRCode and Location Description text
        QRLabel.text = QRCode
        locDescription.text = loc
        
        //format details fields
        let font = UIFont(name: "ArialMT", size: 16.0)!
        let fontBold = UIFont(name: "Arial-BoldMT", size: 16.0)!
        let attributedStr = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font: font])
        
        attributedStr.append(NSAttributedString(string: "Latitude: ", attributes: [NSAttributedString.Key.font: fontBold]))
        attributedStr.append(NSAttributedString(string: lat, attributes: [NSAttributedString.Key.font: font]))
        attributedStr.append(NSAttributedString(string: "\nLongitude: ", attributes: [NSAttributedString.Key.font: fontBold]))
        attributedStr.append(NSAttributedString(string: long, attributes: [NSAttributedString.Key.font: font]))
        attributedStr.append(NSAttributedString(string: "\n\nActive: ", attributes: [NSAttributedString.Key.font: fontBold]))
        
        //set details text
        fields.attributedText = attributedStr
        
        //set active switch
        activeSwitch.isOn = active == 1 ? true : false
        
        queryLocationTable()
        
        //wait for query to finish
        dispatchGroup.notify(queue: .main) {
            if self.qrTable != nil {
                self.qrTable.refreshControl?.endRefreshing()
                self.qrTable.reloadData()
            }
        }
        
    }
    
}


//active switch controls
//MARK:  Extension
extension LocationDetails {
    
    @IBAction func activeSwitched(_ sender: Any) {
        let activeTemp = activeSwitch.isOn ? 1 : 0
        saveActiveAlert(activeTemp: activeTemp)
    }
    
    func saveActiveAlert(activeTemp: Int) {
        
        let title = activeTemp == 1 ? "Set Location to Active?" : "Set Location to Inactive?"
        
        let alertPrompt = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let yes = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.active = activeTemp
            self.saveActiveStatus()
            
            //wait for records to save
            self.dispatchGroup.wait()

            //refresh and show Active Locations TableView
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "ActiveLocations") as! ActiveLocations
            vc.segment = self.active == 1 ? 0 : 1
            self.show(vc, sender: self)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.activeSwitch.isOn = self.active == 1 ? true : false
        }
        
        alertPrompt.addAction(yes)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
    } //end saveActiveAlert
    
    func saveActiveStatus() {
        
        //dispatchGroup.enter()
        
        //set active flag for all records in current location
 /*       for var record in records {
            record.setValue(active, forKey: "active")
            locations.save(item: LocationRecordCacheItem(withRecord: record)!)
        }
        */
        
    /*
        #if false       // TODO: Hande saving LocationRecordCacheItem to CloudKit
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        operation.perRecordCompletionBlock = { (record, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }

        }
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        database.add(operation)
        #else
        self.dispatchGroup.leave()
        #endif
      */
    } //end saveActiveStatus
    
}


//table view functions and helpers
//MARK:  Extension 2
extension LocationDetails: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return details.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return details[section].0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        
        qrTable.rowHeight = 80
        
        //fetch record details
        let dosimeter = details[indexPath.section].1
        let cycleDate = details[indexPath.section].2
        let modFlagStr:String
        let collectedFlagStr:String
        
        switch details[indexPath.section].3 {
        case 0:
            modFlagStr = "No"
        case 1:
            modFlagStr = "Yes"
        default:
            modFlagStr = "n/a"
        }
        
        switch details[indexPath.section].4 {
        case 0:
            collectedFlagStr = "No"
        case 1:
            collectedFlagStr = "Yes"
        default:
            collectedFlagStr = "n/a"
        }
        
        //set cell text
        cell.textLabel?.text = "Dosimeter:\nWear Period:\nModerator:\nCollected:"
        cell.detailTextLabel?.text = "\(dosimeter)\n\(cycleDate)\n\(modFlagStr)\n\(collectedFlagStr)"
        
        return cell
        
    }
    
    //popup pop up
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        setPopupDetails(record: records[indexPath.section])
        self.popupConstraint.constant = 0
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.backgroundButton.alpha = 0.5
        })
    }
    
    //query for location records table
    func queryLocationTable() {
        dispatchGroup.enter()
        
        records = [LocationRecordDelegate]()
        details = [(String, String, String, Int, Int)]()
        
        let predicate = NSPredicate(format: "QRCode == %@", QRCode)
        //let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let sort = NSSortDescriptor(key: "createdDate", ascending: false) //Ver 1.2
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 100 //assume less than 100 records
        operation.recordFetchedBlock = self.recordFetchedBlock //to be executed for each fetched record
        operation.queryCompletionBlock = self.queryCompletionBlock //to be executed after each the query
        
        database.add(operation)
    } //end func
    
    
    //to be executed after each query (query fetches 100 records)
    func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        DispatchQueue.main.async {
            if self.qrTable != nil {
                self.qrTable.refreshControl?.endRefreshing()
                self.qrTable.reloadData()
            }
        }
        dispatchGroup.leave()
    } //end func
    
    
    //to be executed for each fetched record
    func recordFetchedBlock(record: CKRecord) {
        
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "MM/dd/yyyy, hh:mm a"
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        //let creationDate = "Record Created: \(dateFormatter.string(from: record.creationDate!))"
        //print(record["createdDate"] as! Date)
        let createdDate = "Record Created: \(dateFormatter.string(from: record["createdDate"] as! Date))" //Ver 1.2"
        let dosimeter = record["dosinumber"] != "" ? String(describing: record["dosinumber"]!) : "n/a"
        let wearperiod = record["cycleDate"] != nil && record["cycleDate"] != "" ? String(describing: record["cycleDate"]!) : "n/a"
        let collectedFlag = record["collectedFlag"] != nil ? record["collectedFlag"]! as Int : 2
        let modFlag = record["moderator"] != nil ? record["moderator"]! as Int : 2
        
        self.details.append((createdDate, dosimeter, wearperiod, modFlag, collectedFlag))
        self.records.append(record)
        
    }
    
    
    @IBAction func dismissDetails(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
}


//edit record pop-up controls
extension LocationDetails: UITextFieldDelegate {
    
    
    @IBAction func popupCancel(_ sender: Any) {
        
        view.endEditing(true)
        popupConstraint.constant = 600
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.backgroundButton.alpha = 0
        })
    }
    
    @IBAction func popupSave(_ sender: Any) {
        
        view.endEditing(true)
        savePopupRecord()
        //dispatchGroup.wait()
        
        //refresh and show Active Locations TableView
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "ActiveLocations") as! ActiveLocations
        vc.segment = active == 1 ? 0 : 1
        self.show(vc, sender: self)
        
    }
    
    func savePopupRecord() {
        
//        dispatchGroup.enter()
        
        let text = pDescription.text?.replacingOccurrences(of: ",", with: "-")
        
        //set new record information
        record.setValue(text, forKey: "locdescription")
        record.setValue(pLatitude.text, forKey: "latitude")
        record.setValue(pLongitude.text, forKey: "longitude")
        record.setValue(pDosimeter.text, forKey: "dosinumber")
        record.setValue(moderator, forKey: "moderator")
        if pDosimeter.text != "" {

            record.setValue(pCycleDate.text, forKey: "cycleDate")
            record.setValue(collected, forKey: "collectedFlag")
            record.setValue(mismatch, forKey: "mismatch")
        }
        //not handled if dosimeter number is empty.  Therefore can't set collected flag.
   
        locations.save(item: record as! LocationRecordCacheItem)
  //      dispatchGroup.leave()
        //
 /*       #if false
        // TODO: Handdle saving LocationRecordCacheItem to disk.
        let operation = CKModifyRecordsOperation(recordsToSave: [popupRecord], recordIDsToDelete: nil)
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let error = error {
                print(error.localizedDescription)
            }
         
            self.dispatchGroup.leave()
        }
        database.add(operation)
        #else
        self.dispatchGroup.leave()
        #endif*/
        
     } //end saveActiveStatus
    
    func setPopupDetails(record: LocationRecordDelegate) {
        
        popupRecord = record
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy, h:mm a"
        //dateFormatter.dateFormat = "MM/dd/yyyy"
        
        //let creationDate = dateFormatter.string(from: record.creationDate!)
        let createdDate = dateFormatter.string(from: record["createdDate"] as! Date)  //Ver 1.2
        //let modifiedDate = dateFormatter.string(from: record.modificationDate!)
        let modifiedDate = dateFormatter.string(from: record["modifiedDate"] as! Date)
        //dateCreated.text = "Date Created: \(creationDate)"
        dateCreated.text = "Date Created: \(createdDate)"
        dateModified.text = "Date Last Modified: \(modifiedDate)"
        
        if let QRCode = record.value(forKey: "QRCode") as? String {
            pQRCode.text = QRCode
        }
        pDescription.text = record.value(forKey: "locdescription") as? String
        pLatitude.text = record.value(forKey: "latitude") as? String
        pLongitude.text = record.value(forKey: "longitude") as? String
        
        if let dosimeter = record["dosinumber"]  as? String {
            pDosimeter.text = String(describing: dosimeter)
        }
        else {
            pDosimeter.text = ""
        }
       
        if let cycleDate = record["cycleDate"]  as? String {
            pCycleDate.text = String(describing: cycleDate)
        }
        else {
            pCycleDate.text = nil
        }
        
        if let moderator = record["moderator"] as? Int {
            self.moderator = moderator
        }
        else {
            self.moderator = 0
        }
        
        if let collected = record["collectedFlag"] as? Int {
            self.collected = collected
        }
        else {
            self.collected = 0
        }
        
        if let mismatch = record["mismatch"] as? Int {
            self.mismatch = mismatch
        }
        else {
            self.mismatch = 0
        }

        pModerator.isOn = moderator == 1 ? true : false
        pCollected.isOn = collected == 1 ? true : false
        pMismatch.isOn = mismatch == 1 ? true : false
        
    }
    
    @objc func moderatorSwitch(_ sender: UISwitch!) {
        moderator = sender.isOn ? 1 : 0
    }
    
    @objc func collectedSwitch(_ sender: UISwitch!) {
        collected = sender.isOn ? 1 : 0
    }
    
    @objc func mismatchSwitch(_ sender: UISwitch!) {
        mismatch = sender.isOn ? 1 : 0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
}
