//
//  DosimetersViewController.swift
//  LocationApp
//
//  Created by László Szöllősi on 2023. 05. 31..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit

class DosimetersCell : UITableViewCell {
    

    @IBOutlet weak var qrCode: UILabel!
    @IBOutlet weak var moderator: UILabel!
    @IBOutlet weak var locationDesc: UILabel!
    @IBOutlet weak var cycleDate: UILabel!
    @IBOutlet weak var collected: UISwitch!
}

class DosimetersViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func doneTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
