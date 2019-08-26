//
//  LocationViewController.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/12/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import UIKit
import CoreLocation

class LocationViewController: UIViewController, CLLocationManagerDelegate {

    //declare variables
    var startLocation: CLLocation! //Optional handles nils; lat long course info class
    var locationManager: CLLocationManager = CLLocationManager() //start&stop delivery of events

    @IBOutlet weak var Latitude: UILabel!
    @IBOutlet weak var Longitude: UILabel!
    @IBOutlet weak var hAccuracy: UILabel!
    @IBOutlet weak var Altitude: UILabel!
    @IBOutlet weak var vAccuracy: UILabel!
    @IBOutlet weak var Distance: UILabel!
    @IBOutlet weak var btnDist: UIButton!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.Distance.text = String(0)
        //Location Manager Setup
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self //establish view controller as delegate
        startLocation = nil

        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
    } //end view did load
    
    @IBAction func resetDistance(_ sender: Any) {
        //Sets distance label to zero
        startLocation = nil
        
    } //end reset Distance
    
    
    //didupdatelocations:  (protocol stub) tells the delegate that new location data is available.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        Latitude.text = String(format: "%.4f", latestLocation.coordinate.latitude)
        Longitude.text = String(format: "%.4f", latestLocation.coordinate.longitude)
        hAccuracy.text = String(format: "%.1f", latestLocation.horizontalAccuracy)
        Altitude.text = String(format: "%.1f", latestLocation.altitude)
        vAccuracy.text = String(format: "%.1f", latestLocation.verticalAccuracy)
        
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
        let distanceBetween: CLLocationDistance = latestLocation.distance(from: startLocation)
        let distanceBetweenFormatted = String(format: "%.2f", distanceBetween)
        Distance.text = "\(distanceBetweenFormatted) m from last reset"
        
    }  //end locationManager
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    } //end didFailWithError
    
    @IBAction func dismissLocation(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
} //end class
