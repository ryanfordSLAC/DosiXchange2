//
//  DosimetersViewController.swift
//  LocationApp
//
//  Created by László Szöllősi on 2023. 05. 31..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit

class Dosimeter {
    var qrCode: String
    var moderator: String?
    var locationDesc: String?
    var cycleDate: String?
    var collected: Bool
    var createdDate:Date
    
    init(item: LocationRecordCacheItem) {
        qrCode = item.QRCode
        if let moderator = item.moderator {
            self.moderator = "\(moderator)"
        }
        locationDesc = item.locdescription
        cycleDate = item.cycleDate
        if let collected = item.collectedFlag {
            self.collected = collected == 1
        }
        else {
            self.collected = false
        }
        createdDate = item.createdDate!
    }
}

class DosimetersCell : UITableViewCell {
    @IBOutlet weak var qrCode: UILabel!
    @IBOutlet weak var moderator: UILabel!
    @IBOutlet weak var locationDesc: UILabel!
    @IBOutlet weak var cycleDate: UILabel!
    @IBOutlet weak var collected: UISwitch!
}

class DosimetersViewController: UIViewController {
    let locations = LocationsCK.shared
    var dosimeters = [Dosimeter]()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func doneTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
                
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        queryDatabase()
    }
    
    fileprivate func processItems(_ items: [LocationRecordCacheItem]) {
        var dosis = items.map({ item in Dosimeter(item: item)})
        dosis.sort {
            if $0.qrCode == $1.qrCode {
                return $0.createdDate > $1.createdDate
            }
            return $0.qrCode < $1.qrCode
        }
        var last : Dosimeter? = nil
        for dosi in dosis {
            if last == nil || dosi.qrCode != last!.qrCode {
                self.dosimeters.append(dosi)
            }
            last = dosi
        }
    }
    
    func queryDatabase(_ by: ((LocationRecordCacheItem) -> Bool)? = nil) {
        activityIndicator.startAnimating()
        dosimeters.removeAll()
        tableView.reloadData()
        locations.filter(by: by ?? { item in item.createdDate != nil }, completionHandler: { items in
            self.processItems(items)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
            }
        })
   }
}

extension DosimetersViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        queryDatabase({ $0.QRCode.range(of: searchText, options: .caseInsensitive) != nil})
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
        queryDatabase()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

extension DosimetersViewController : UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension DosimetersViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dosimeters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DosiCell", for: indexPath) as? DosimetersCell {
            let dosimeter = dosimeters[indexPath.row]
            cell.qrCode.text = dosimeter.qrCode
            cell.cycleDate.text = dosimeter.cycleDate
            cell.locationDesc.text = dosimeter.locationDesc
            cell.moderator.text = dosimeter.moderator
            cell.collected.isOn = dosimeter.collected
            
            return cell
        }
        return UITableViewCell()
    }        
}
