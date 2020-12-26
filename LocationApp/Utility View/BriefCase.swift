//
//  BriefCase.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 12/20/20.
//  Copyright © 2020 Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit

/*requires field in data schema for briefCase as integer
1 = record was changed (set in briefcase load and sent to server during sync
0 = record is not changed
requires button on home screen to turn on briefcase mode
very unlikely two people will try to exchange the same dosimeter because
    they're assigned to areas and can see the new dosimeter color when exchanging.
changes from 1 to 0 during upload
*/

class BriefCase: UIViewController {

    let reachability = Reachability()!
    
    @IBOutlet weak var synchronize_button: UIButton!
    @IBOutlet weak var briefcaseIsActive_button: UIButton!
    @IBOutlet weak var saveLocal_button: UIButton!
    @IBOutlet weak var saveServer_button: UIButton!
    @IBOutlet weak var setCoordinates_button: UIButton!
    @IBOutlet weak var modifyBriefcase_button: UIButton!
    @IBOutlet weak var setBriefcaseFlag_button: UIButton!
    @IBOutlet weak var clearBriefcase_button: UIButton!
    @IBOutlet weak var connectivity: UILabel!
    
    override func viewDidLoad() {
        //set to light mode.
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        super.viewDidLoad()
        
        // Detect Wifi:
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
                self.connectivity.text = "Connected via Wifi"
            }
            else {
                print("Reachable via Cellular")
                self.connectivity.text = "Connected via Cellular"
            }
        }
        
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            self.connectivity.text = "Network Unavailable..."
            let alert = UIAlertController(title: "WiFi Connection Error", message: "Must be connected to WiFi to identify position and save data to cloud", preferredStyle: .alert)
            let OK = UIAlertAction(title: "OK", style: .default) { (_) in return }
            alert.addAction(OK)
            
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            } //async end
        
        }//end when unreachable
        
        do {
            try reachability.startNotifier()
        }
        catch {
            print("Unable to start notifier")
        }  //end catch
        //end Detect Wifi...
        
    }

    @IBAction func synchronize_touchUpInside(_ sender: Any) {
        //check if briefcase is active
        //check if briefcase is empty or full
        //check for wifi (needed to pull new records)
        //if full:  check for changes locally (indicated as "1" in briefCase field)
        //      then:  upload changed records
        //      then:  clear briefcase
        //if empty: download new records
        //issue alert with report (## records modified & uploaded)
        print("synchronize_touchUpInside")
    }
    
    @IBAction func briefcaseIsActive_touchUpInside(_ sender: Any) {
        //check if we're in briefcase mode or wifi mode
        print("Is briefcase active?: \(briefcaseIsActive())")
    }
    
    func briefcaseIsActive() -> Int {
        //check if we're in briefcase mode or wifi mode
        
        return 1
    }
    
    @IBAction func saveLocal_touchUpInside(_ sender: Any) {
        //download new records
        print("saveLocal")
    }
    
    @IBAction func saveServer_touchUpInside(_ sender: Any) {
        //upload changed records
        print("saveServer")
    }
    
    @IBAction func setCoordinates_touchUpInside(_ sender: Any) {
        //for the record in question:
        //check if the location exits
        //if location does not exist supply generic coordinates
        //if location exists supply prior coordinates
        print("setCoordinates")
    }
    
    @IBAction func modifyBriefcase_touchUpInside(_ sender: Any) {
        //identify record
        //make changes
        //set the briefcase flag
        //ready for upload
        print("modifyBriefcase")
    }
    
    @IBAction func setBriefcaseFlag_touchUpInside(_ sender: Any) {
        //
        //set briefcase field/index to 1
        print("setBriefcaseFlag")
    }
    
    @IBAction func clearBriefcase_touchUpInside(_ sender: Any) {
        
        print("Is briefcase clear? \(clearBriefcase())")
    }
    
    func clearBriefcase() -> Int {
        //runs after data is uploaded
        
        return 1  //briefcase is full
    }
    
    
}//end class
