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
    
    let locations = LocationsCK()
    var searchQuery: Query?
    var allQuery: Query?
    
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
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh Locations")
        //this query will populate the table when the table is pulled.
        refreshControl.addTarget(self, action: #selector(queryDatabase), for: .valueChanged)
        self.activesTableView.refreshControl = refreshControl
        
        //this query will populate the tableView when the view loads.
        queryDatabase()
        
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
        if searchText.count < 3 {
            return
        }
            
        searching = true
        allQuery?.cancel()
        searchQuery?.cancel()

        searches = [[(LocationRecordDelegate, String, String)]]()
        searches.append([(LocationRecordDelegate, String, String)]())
        searches.append([(LocationRecordDelegate, String, String)]())
        activesTableView.reloadData()
        
        let qrPred = NSPredicate(format: "QRCode BEGINSWITH %@", searchText)
        searchQuery = locations.query(predicate: qrPred, sortDescriptors: [], pageSize: 20, completionHandler: queryCompletionHandler)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchQuery?.cancel()
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
        allQuery?.cancel()
        
        displayInfo[0].max(by: { a, b -> Bool in
            a.0[""] < b.0[""]
        } )
        
        //reset array
        displayInfo = [[(CKRecord, String, String)]]()
        displayInfo.append([(CKRecord, String, String)]())
        displayInfo.append([(CKRecord, String, String)]())
            
        queryCloudKitForDatabase()
   } //end func
        
  
    //query locations from CloudKit after a given record modified date,
    //else fetch all locations if the given record modified date is nil (default)
    func queryCloudKitForDatabase(afterdModifiedDate recordModifiedDate: Date? = nil) {
        var predicate: NSPredicate?
        if let modificationDate = recordModifiedDate {
            predicate = NSPredicate(format: "modificationDate > %@", argumentArray: [modificationDate])
        }
        let sort1 = NSSortDescriptor(key: "QRCode", ascending: true)
        let sort2 = NSSortDescriptor(key: "createdDate", ascending: false) //Ver 1.2
        allQuery = locations.query(predicate: predicate!, sortDescriptors: [sort1, sort2], pageSize: 20, completionHandler: queryCompletionHandler)
    }

    func queryCompletionHandler(records :[LocationRecordDelegate], completed: Bool?, error: Error?)  {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        if (!records.isEmpty){
            for record in records {
                self.processLocationRecord(record)
            }
            DispatchQueue.main.async {
                if self.activesTableView != nil {
                    self.activesTableView.refreshControl?.endRefreshing()
                    self.activesTableView.reloadData()
                }
            }
        }
        
        if let completed = completed {
            if completed {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }}
        }
    }
    
    
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
                    if searching {
                        searches[flag].append((record, currentQR, currentLoc))
                    }
                    else {
                        displayInfo[flag].append((record, currentQR, currentLoc))
                    }
                }
                
                self.checkQR = currentQR
          }
                  
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
