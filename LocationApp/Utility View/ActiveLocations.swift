//
//  ActiveLocationsViewController.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/1/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import UIKit
import CloudKit

//MARK:  Class
class ActiveLocations: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    let database = CKContainer.default().publicCloudDatabase
    let dispatchGroup = DispatchGroup()
    
    var segment:Int = 0
    var displayInfo = [[(LocationRecordDelegate, String, String)]]()
    var checkQR = ""
    var searches = [[(LocationRecordDelegate, String, String)]]()
    var searching = false
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activesTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
        
        //Do any additional setup after loading the view.
        activesTableView.delegate = self
        activesTableView.dataSource = self
        searchBar.delegate = self
        segmentedControl.selectedSegmentIndex = segment
        
        //Table View SetUp

        //this query will populate the tableView when the view loads.
        queryDatabase()
        
        //wait for query to finish
        dispatchGroup.notify(queue: .main) {
            self.activesTableView.reloadData()
            //stop activityIndicator
            self.activityIndicator.stopAnimating()
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh Locations")
        //this query will populate the table when the table is pulled.
        refreshControl.addTarget(self, action: #selector(queryDatabase), for: .valueChanged)
        self.activesTableView.refreshControl = refreshControl
        
    } //end viewDidLoad
    
    //MARK:  Table View
    @IBAction func tableSwitch(_ sender: UISegmentedControl) {
        segment = sender.selectedSegmentIndex
        activesTableView.reloadData()
    }
    
    //table functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searching ? searches[segment].count : displayInfo[segment].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        dispatchGroup.wait()
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QRCell", for: indexPath)
        
        activesTableView.estimatedRowHeight = 60
        activesTableView.rowHeight = UITableView.automaticDimension
        
        let QRCode = searching ? searches[segment][indexPath.row].1 : displayInfo[segment][indexPath.row].1
        let locdescription = searching ? searches[segment][indexPath.row].2 : displayInfo[segment][indexPath.row].2
        
        //format cell title
        cell.textLabel?.font = UIFont(name: "Arial", size: 16)
        cell.textLabel?.text = "\(QRCode)"
        //format cell subtitle
        cell.detailTextLabel?.font = UIFont(name: "Arial", size: 12)
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.detailTextLabel?.text = "\(locdescription)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "LocationDetails") as! LocationDetails
        
        vc.record = searching ? searches[segment][indexPath.row].0 : displayInfo[segment][indexPath.row].0
        
        self.present(vc, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let segment0 = displayInfo[0].filter({$0.1.lowercased().contains(searchText.lowercased()) || $0.2.lowercased().contains(searchText.lowercased())})
        let segment1 = displayInfo[1].filter({$0.1.lowercased().contains(searchText.lowercased()) || $0.2.lowercased().contains(searchText.lowercased())})
        
        searches = [segment0, segment1]
        
        searching = true
        activesTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        searchBar.endEditing(true)
        activesTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
}

//query and helper functions
//MARK:  Extensions
extension ActiveLocations {

    @objc func queryDatabase() {
                
        // try to load the records from the locations cache in memory
        if LocationRecordCache.shared.cacheIsLoaded() {

            DebugLocations.shared.start(presentingViewController: self,
                                        description: "All Locations Cache")       // TESTING

            LocationRecordCache.shared.fetchLocationRecordsFromCache(withQRCode: nil,
                                                                     processRecord: self.processLocationRecord,
                                                                     completion: self.finishedLoadingCachedLocationRecords)
            // Fetch only the location records from CloudKit that have a modificationDate after the maximum modified time of
            // all the cached location records.
            queryCloudKitForDatabase(afterdModifiedDate: LocationRecordCache.shared.maxLocationRecordCacheItemModificationDate)
        }
        else if LocationRecordCache.shared.locationRecordCacheFileExists() {

            LocationRecordCache.shared.loadLocationsRecordCacheFile { [self] didLoad in
                if didLoad {
                    DebugLocations.shared.start(presentingViewController: self,
                                                description: "Location Details Cache")       // TESTING

                    LocationRecordCache.shared.fetchLocationRecordsFromCache(withQRCode: nil,
                                                                             processRecord: self.processLocationRecord,
                                                                             completion: self.finishedLoadingCachedLocationRecords)
                    
                    // Fetch only the location records from CloudKit that have a modificationDate after the maximum modified time of
                    // all the cached location records.
                    queryCloudKitForDatabase(afterdModifiedDate: LocationRecordCache.shared.maxLocationRecordCacheItemModificationDate)
                }
            }
        }
        else {
            // Fetch all of the Location records from CloudKit.
            queryCloudKitForDatabase()
        }
   } //end func
    
    
  
    //query locations from CloudKit after a given record modified date,
    //else fetch all locations if the given record modified date is nil (default)
    func queryCloudKitForDatabase(afterdModifiedDate recordModifiedDate: Date? = nil) {
    
        
        DebugLocations.shared.start(presentingViewController: self,
                                    description: "All Locations")       // TESTING

        // Notify the locations cache that we started fetching records from CloudKit.
        LocationRecordCache.shared.didStartFetchingRecords()
                
        print("-------------------------- queryCloudKitForDatabase -------------------------------")
        dispatchGroup.enter()
        //reset array
        displayInfo = [[(CKRecord, String, String)]]()
        displayInfo.append([(CKRecord, String, String)]())
        displayInfo.append([(CKRecord, String, String)]())
        
        var predicate: NSPredicate?
        if let modificationTime = LocationRecordCache.shared.maxLocationRecordCacheItemModificationDate {
            predicate = NSPredicate(format: "modificationDate >= %@", argumentArray: [modificationTime])       // IT WORKS!
            print("CloudKit Query predicate = (modificationDate >= \(modificationTime)")
       }
        else {
            // Predicate is for debugging CloudKit fetches only!
//            predicate = NSPredicate(format: "QRCode = %@", argumentArray: ["GALRY-050"])       // IT WORKS!
//            print("CloudKit Query predicate:  QRCode = GALRY-050")

            predicate = NSPredicate(value: true)
            print("CloudKit Query predicate:  true")
        }
        let sort1 = NSSortDescriptor(key: "QRCode", ascending: true)
        //let sort2 = NSSortDescriptor(key: "creationDate", ascending: false)
        let sort2 = NSSortDescriptor(key: "createdDate", ascending: false) //Ver 1.2
        let query = CKQuery(recordType: "Location", predicate: predicate!)
        query.sortDescriptors = [sort1, sort2]
        let operation = CKQueryOperation(query: query)
        addOperation(operation: operation)
    }

    func finishedLoadingCachedLocationRecords() {
        DebugLocations.shared.finish()       // TESTING

        DispatchQueue.main.async {
            if self.activesTableView != nil {
                self.activesTableView.refreshControl?.endRefreshing()
                self.activesTableView.reloadData()
        
                //stop activityIndicator
                self.activityIndicator.stopAnimating()
         }
        }
        dispatchGroup.leave()
    }
    
    #if false
    @objc func queryDatabase() {
        
        DebugLocations.shared.start(presentingViewController: self,
                                    description: "All Locations View")       // TESTING

        dispatchGroup.enter()
        //reset array
        displayInfo = [[(CKRecord, String, String)]]()
        displayInfo.append([(CKRecord, String, String)]())
        displayInfo.append([(CKRecord, String, String)]())
        
        let predicate = NSPredicate(value: true)
        let sort1 = NSSortDescriptor(key: "QRCode", ascending: true)
        //let sort2 = NSSortDescriptor(key: "creationDate", ascending: false)
        let sort2 = NSSortDescriptor(key: "createdDate", ascending: false) //Ver 1.2
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort1, sort2]
        let operation = CKQueryOperation(query: query)
        addOperation(operation: operation)

    } //end function
    #endif
    
    //add query operation
    func addOperation(operation: CKQueryOperation) {
        operation.resultsLimit = 200 //max 400; 200 to be safe
        operation.recordFetchedBlock = self.recordFetchedBlock //to be executed for each fetched record
        operation.queryCompletionBlock = self.queryCompletionBlock //to be executed after each query (query fetches 200 records at a time)
        
        database.add(operation)
    } //end func
    
    
    //to be executed after each query (query fetches 200 records at a time)
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

        DebugLocations.shared.finish()       // TESTING

        DispatchQueue.main.async {
            if self.activesTableView != nil {
                self.activesTableView.refreshControl?.endRefreshing()
                self.activesTableView.reloadData()
            }
        }
        dispatchGroup.leave()
    } //end func
    
    
    // Process a Location record that was fetched from CloudKit
    // or thr local location records cache.
    func processLocationRecord(_ record: LocationRecordDelegate) {
 
        //if record is active ("active" = 1), record is appended to the first array (flag = 0)
        //else record is appended to the second array (flag = 1)
        
        switch record["active"] {
        
        case nil:
            //handle rare cases where active is nil, prevent app crashes.
            print("record skipped")
            alert12()
            return
            
            
        default:
            
            //fetch active flag, QRCode and locdescription.
            if let active:Int64 = record["active"] as? Int64,
               let currentQR:String = record["QRCode"] as? String,
               let currentLoc:String = record["locdescription"] as? String {
                
                //Original
                let flag = active == 1 ? 0 : 1
                                
                //if QRCode is not the same as previous record
                if currentQR != self.checkQR {
                    //append (QRCode, locdescription) tuple displayInfo
                    displayInfo[flag].append((record, currentQR, currentLoc))
                }
                
                DebugLocations.shared.didFetchRecord()      // TESTING
                
                self.checkQR = currentQR
          }
                  
        }
    } //end func
    
    //to be executed for each fetched record
    //MARK:  Loading Tableview
    func recordFetchedBlock(record: CKRecord) {
        
        //if record is active ("active" = 1), record is appended to the first array (flag = 0)
        //else record is appended to the second array (flag = 1)
        
        switch record["active"] {
        
        case nil:
            //handle rare cases where active is nil, prevent app crashes.
            print("record skipped")
            alert12()
            return
            
            
        default:
            //Original
            let flag = record["active"]! == 1 ? 0 : 1
            
            //fetch QRCode and locdescription
            let currentQR:String = record["QRCode"]!
            let currentLoc:String = record["locdescription"]!
            
            //if QRCode is not the same as previous record
            if currentQR != self.checkQR {
                //append (QRCode, locdescription) tuple displayInfo
                displayInfo[flag].append((record, currentQR, currentLoc))
            }
            
            DebugLocations.shared.didFetchRecord()      // TESTING
            
            self.checkQR = currentQR
        }
    } //end func
    
//MARK:  Alert 12
    
    //Handle nils in active field (rare - set by system)
    func alert12() {
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            
        let alert = UIAlertController(title: "Contact Administrator", message: "Incomplete records were suppressed from this view. \n You can continue using the app.", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
        
        }
    } //end alert12
    
    }
