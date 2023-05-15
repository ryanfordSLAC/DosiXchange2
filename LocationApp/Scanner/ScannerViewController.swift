//
//  Barcode.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 11/23/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import AVFoundation
import UIKit
import CloudKit
import CoreLocation

//MARK:  Class
class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var recordsupdate = RecordsUpdate()
    var zoomFactor:CGFloat = 3
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var counter:Int64 = 0
    let dispatchGroup = DispatchGroup()
    var beepSound: AVAudioPlayer?
    var records = [CKRecord]()
    var itemRecord:CKRecord?
    var tempRecords = [CKRecord]()
    var locationManager = CLLocationManager()
    let database = CKContainer.default().publicCloudDatabase
    var alertTextField: UITextField!
    
    @IBOutlet weak var innerView: UIView!
    
    struct variables {  //key variables needed in other classes
        
        static var dosiNumber:String?
        static var QRCode:String?
        static var codeType:String?
        static var dosiLocation:String?
        static var collected:Int64?
        static var mismatch:Int64?
        static var active:Int64?
        static var cycle:String?
        static var latitude:String?
        static var longitude:String?
        static var moderator:Int64?

    } //end struct

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        captureSession = AVCaptureSession()
    
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
 
        
    //set zoom factor to 3x
        do {
            try    videoCaptureDevice.lockForConfiguration()
            
        } catch {
            // handle error
            return
        }

        // When this point is reached, we can be sure that the locking succeeded

        
    //end set zoom factor to 3X
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        }
        catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
            
        }
        else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            //Location barcode is a QR Code (.qr)
            //Dosimeter barcoce is a CODE 128 barcode (.code128)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128]
        }
        
        else {
            failed()
            return
        }//end else
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame.size = innerView.frame.size
        innerView.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = AVLayerVideoGravity.resize
        videoCaptureDevice.videoZoomFactor = zoomFactor
        videoCaptureDevice.unlockForConfiguration()
        captureSession.startRunning()
        
    }//end viewDidLoad()
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func failed() {
        
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
        
    }//end failed
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        self.previewLayer.frame.size = self.innerView.frame.size
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
        
    }//end viewWillAppear
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        
    }//end viewWillDisappear
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        if let metadataObject = metadataObjects.first {
            
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            switch readableObject.type {
                
            case .qr:

                variables.codeType = "QRCode"
                
            case .code128:

                variables.codeType = "Code128"
            
            default:
                print("Code not found")
                
            }//end switch
            
            scannerLogic(code: stringValue)
            
        }//end if let

    }//end function meetadataOutput
    

    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
        
    } //end supportedInterfaceOrientations
    
}   //end class

/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 All methods, alerts, handlers and queries needed to
 implement the scanner logic (see figures under "other assets")
 by Ryan M. Ford 2019
 */
// MARK:  ScannerViewController
//MARK:  Extension
extension ScannerViewController {
    
    func scannerLogic(code: String) { //see Other Assets Scanner Logic diagrams
        
        switch self.counter {
            
            case 0: //first scan
                variables.QRCode = nil
                variables.dosiNumber = nil
                clearForQR()

                switch variables.codeType {
                    
                    case "QRCode":

                        variables.QRCode = code //store the QRCode
                        queryForQRFound() //use the QRCode to look up record & store values

                        dispatchGroup.notify(queue: .main) {
                            print("1 - Dispatch QR Code Notify")
                            
                            //record found
                            if self.itemRecord != nil {
                                
                                //deployed dosimeter
                                if variables.collected == 0 {
                                    self.beep()
                                    if variables.active == 1 {
                                        self.alert3a() //Exchange Dosimeter (active location)
                                    }
                                    else {
                                        self.alert3i() //Collect Dosimeter (inactive location)
                                    }
                                }
                                //collected or no dosimeter
                                else {
                                    if variables.active == 1 {
                                        self.beep()
                                        self.alert2() //Location Found [cancel/deploy]
                                    }
                                    else {
                                        self.beepFail()
                                        self.alert2a() //Inactive Location (activate to deploy)
                                    }
                                }
                            }
                            
                            //no record found
                            else {
                                self.beep()
                                self.alert2() //New Location [cancel/deploy]
                            }
                            
                        } //end dispatch group

                    case "Code128":
                        
                        variables.dosiNumber = code //store the dosi number
                        queryForDosiFound() //use the dosiNumber to look up record & store values

                        dispatchGroup.notify(queue: .main) {
                            print("1 - Dispatch Code 128 Notify")
                            
                            //record found
                            if self.itemRecord != nil {
                                
                                //deployed dosimeter
                                if variables.collected == 0 {
                                    self.beep()
                                    if variables.active == 1 {
                                        self.alert3a() //Exchange Dosimeter (active location)
                                    }
                                    else {
                                        self.alert3i() //Collect Dosimeter (inactive location)
                                    }
                                }
                                    
                                //collected dosimeter
                                else {
                                    self.beepFail()
                                    self.alert9a() //Invalid Dosimeter (already collected)
                                }
                            }
                            
                            //no record found
                            else {
                                self.beep()
                                self.alert1() //Dosimeter Not Found [cancel/deploy]
                            }
                            
                        } //end dispatch group

                    default:
                        print("Invalid Code") //exhaustive
                        alert9()
                    
                } //end switch
            
            case 1: //second scan logic
                
                //self.captureSession.startRunning()
                
                switch variables.codeType {
                    
                    case "QRCode":
                        
                        //looking for QRCode
                        if variables.QRCode == nil {
                            clearForQR()
                            queryForQRUsed(tempQR: code)
                            
                            dispatchGroup.notify(queue: .main) {
                                print("2 - Dispatch QR Code Notify")
                                
                                //existing location
                                if self.records != [] {
                                    
                                    //location in use/inactive location
                                    if variables.collected == 0 || variables.active == 0 {
                                        self.beepFail()
                                        self.alert7b(code: code)
                                    }
                                        
                                    //valid location
                                    else {
                                        self.beep()
                                        variables.QRCode = code
                                        self.alert8()
                                    }
                                }
                                    
                                //new location
                                else {
                                    self.beep()
                                    variables.QRCode = code
                                    self.alert8()
                                }
                                
                            } //end dispatch group
                            
                        }
                            
                        //not looking for QRCode
                        else {
                            beepFail()
                            alert6b()
                        }
                    
                    case "Code128":
                        
                        //looking for barcode
                        if variables.dosiNumber == nil {
                            queryForDosiUsed(tempDosi: code)
                            
                            dispatchGroup.notify(queue: .main) {
                                print("2 - Dispatch Code 128 Notify")
                                
                                //duplicate dosimeter
                                if self.records != [] {
                                    self.beepFail()
                                    self.alert7a(code: code)
                                }
                                    
                                //new dosimeter
                                else {
                                    self.beep()
                                    variables.dosiNumber = code
                                    self.alert8()
                                }
                                
                            } //end dispatch group
                            
                        } //looking for barcode
                            
                        //not looking for barcode
                        else {
                            beepFail()
                            alert6a()
                        }
                    
                    default:
                        print("Invalid Code")
                        if variables.QRCode == nil { alert6a() }
                        else if variables.dosiNumber == nil { alert6b() }
                }
            
            default:
                print("Invalid Scan")
                counter = 0
                self.captureSession.startRunning()
        }
    } //end func
    
//MARK:  Collect
    
    func collect(collected: Int64, mismatch: Int64, modifiedDate: Date) {
        
        self.dispatchGroup.enter()
        
        itemRecord!.setValue(collected, forKey: "collectedFlag")
        itemRecord!.setValue(mismatch, forKey: "mismatch")
        itemRecord!.setValue(modifiedDate, forKey: "modifiedDate")
        
        let operation = CKModifyRecordsOperation(recordsToSave: [itemRecord!], recordIDsToDelete: nil)
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            self.dispatchGroup.leave()
        }
        
        database.add(operation)
        
    } //end collect
    
    
    func deploy() {
        
        self.counter = 1
        
    } //end deploy
    
    
    func clearData() {
        
        variables.codeType = nil
        variables.dosiNumber = nil
        variables.QRCode = nil
        variables.latitude = nil
        variables.longitude = nil
        variables.dosiLocation = nil
        variables.collected = nil
        variables.mismatch = nil
        variables.active = nil
        variables.moderator = nil
        variables.cycle = nil
        itemRecord = nil
        counter = 0
        
    }  //end clear data
    
    
    func clearForQR() {
        variables.dosiLocation = nil
        variables.collected = nil
        variables.mismatch = nil
        variables.active = nil
        variables.moderator = nil
    }
    
    
    func getCoordinates() {
        
        locationManager.requestAlwaysAuthorization()
        var currentLocation = CLLocation()
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways) {
            
            currentLocation = locationManager.location!
            
        }  //end if
        
        let latitude = String(format: "%.8f", currentLocation.coordinate.latitude)
        let longitude = String(format: "%.8f", currentLocation.coordinate.longitude)
        
        variables.latitude = latitude
        variables.longitude = longitude
        
    }
    
    
    @objc func beepFail() {
        
        //"Buzz!"
        guard let path = Bundle.main.path(forResource: "beep-5", ofType: "wav") else {
            print("URL Not Found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            self.beepSound = try AVAudioPlayer(contentsOf: url)
            self.beepSound?.play()
        }
        catch {
            print(error.localizedDescription)
        }
    } //end beep fail
    
    
    @objc func beep() {
        
        //"Beep!"
        guard let path = Bundle.main.path(forResource: "scannerbeep", ofType: "mp3") else {
            print("URL Not Found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            self.beepSound = try AVAudioPlayer(contentsOf: url)
            self.beepSound?.play()
        }
        catch {
            print(error.localizedDescription)
        }
    } //end beep()
    
} //end extension methods
/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */

//MARK:  Extension ScannerViewController

extension ScannerViewController {  //queries
    
    func queryForDosiFound() {
        dispatchGroup.enter()
        let predicate = NSPredicate(format: "dosinumber == %@", variables.dosiNumber!)
        //let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let sort = NSSortDescriptor(key: "createdDate", ascending: false) //Ver 1.2
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            if records != [] {
                variables.active = records[0]["active"] as? Int64
                variables.collected = records[0]["collectedFlag"] as? Int64
                variables.QRCode = records[0]["QRCode"] as? String
                variables.dosiLocation = records[0]["locdescription"] as? String
                variables.cycle = records[0]["cycleDate"] as? String
                if records[0]["moderator"] != nil { variables.moderator = records[0]["moderator"] as? Int64 }
                if records[0]["mismatch"] != nil { variables.mismatch = records[0]["mismatch"] as? Int64 }
                
                self.itemRecord = records[0]
            }
            
            self.records = records
            self.dispatchGroup.leave()
            
        } //end perform query
        
    } //end queryforDosiFound
    
    
    func queryForQRFound() {
        dispatchGroup.enter()
        let predicate = NSPredicate(format: "QRCode == %@", variables.QRCode!)
        //let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let sort = NSSortDescriptor(key: "createdDate", ascending: false) //Ver 1.2
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            if records != [] {
                variables.active = records[0]["active"] as? Int64
                variables.dosiLocation = records[0]["locdescription"] as? String
                if records[0]["collectedFlag"] != nil { variables.collected = records[0]["collectedFlag"] as? Int64 }
                if records[0]["dosinumber"] != nil { variables.dosiNumber = records[0]["dosinumber"] as? String }
                if records[0]["moderator"] != nil { variables.moderator = records[0]["moderator"] as? Int64 }
                if records[0]["mismatch"] != nil { variables.mismatch = records[0]["mismatch"] as? Int64 }
                if records[0]["cycleDate"] != nil { variables.cycle = records[0]["cycleDate"] as? String }
                
                self.itemRecord = records[0]
            }
            
            self.records = records
            self.dispatchGroup.leave()
            
        }  //end perform query
        
    } //end queryForQRFound
    
    
    func queryForDosiUsed(tempDosi: String) {
        dispatchGroup.enter()
        let predicate = NSPredicate(format: "dosinumber == %@", tempDosi)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            self.records = records
            self.dispatchGroup.leave()
            
        } //end perform query

    } //end queryForDosiUsed
    
    
    func queryForQRUsed(tempQR: String) {
        dispatchGroup.enter()
        let predicate = NSPredicate(format: "QRCode == %@", tempQR)
        //let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let sort = NSSortDescriptor(key: "createdDate", ascending: false)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            if records != [] {
                variables.active = records[0]["active"] as? Int64
                variables.dosiLocation = records[0]["locdescription"] as? String
                if records[0]["collectedFlag"] != nil { variables.collected = records[0]["collectedFlag"] as? Int64}
                if records[0]["moderator"] != nil { variables.moderator = records[0]["moderator"] as? Int64 }
                if records[0]["mismatch"] != nil { variables.mismatch = records[0]["mismatch"] as? Int64 }
            }
            
            self.records = records
            self.dispatchGroup.leave()
            
        }  //end perform query

    } //end queryForQRUsed

} //end extension queries
    
/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */


extension ScannerViewController {  //alerts

        
    func alert1() {
        
        let alert = UIAlertController(title: "Dosimeter Not Found:\n\(variables.dosiNumber ?? "Nil Dosi")", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in
            variables.QRCode = nil
            self.deploy()
            self.alert4()
        } //end let
        
        alert.addAction(deployDosimeter)
        alert.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert1
    
    
    func alert2() {
        
        let title = itemRecord != nil ? "Location Found:\n\(variables.QRCode ?? "Nil QRCode")" : "New Location:\n\(variables.QRCode ?? "Nil QRCode")"
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in
            variables.dosiNumber = nil
            self.deploy()
            self.alert5()
        } //end let
        
        alert.addAction(deployDosimeter)
        alert.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert2
    
    
    func alert2a() {
        
        let message = "Please activate this location to deploy a dosimeter."
        
        //set up alert
        let alert = UIAlertController.init(title: "Inactive Location:\n\(variables.QRCode ?? "Nil QRCode")", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerCancel)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK:  Alert 3a Exchange
    func alert3a() {
        
        let message = "\nCycle Date: \(variables.cycle ?? "Nil Cycle")"
        let alert = UIAlertController(title: "Exchange Dosimeter:\n\(variables.dosiNumber ?? "Nil Dosi")\n\nLocation:\n\(variables.QRCode ?? "Nil QRCode")", message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let ExchangeDosimeter = UIAlertAction(title: "Exchange", style: .default) { (_) in
            self.collect(collected: 1, mismatch: variables.mismatch ?? 0, modifiedDate: Date(timeInterval: 0, since: Date()))
            self.alert11a()
        }

        let mismatch = UIAlertAction(title: "Mismatch", style: .default) { (_) in
            self.alert3a()
        }
        
        alert.addAction(mismatch)
        alert.view.addSubview(mismatchSwitch())
        alert.addAction(ExchangeDosimeter)
        alert.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert3a
    
    //MARK:  Alert 3i Collect
    func alert3i() {
        
        let message = "\nCycle Date: \(variables.cycle ?? "Nil Cycle")"
        let alert = UIAlertController(title: "Collect Dosimeter:\n\(variables.dosiNumber ?? "Nil Dosi")\n\nLocation:\n\(variables.QRCode ?? "Nil QRCode")", message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let collectDosimeter = UIAlertAction(title: "Collect", style: .default) { (_) in
            self.collect(collected: 1, mismatch: variables.mismatch ?? 0, modifiedDate: Date(timeInterval: 0, since: Date()))
            self.alert11()
        }
        
        let mismatch = UIAlertAction(title: "Mismatch", style: .default) { (_) in
            self.alert3i() //reopen alert
        }
        
        alert.addAction(mismatch)
        alert.view.addSubview(mismatchSwitch())
        alert.addAction(collectDosimeter)
        alert.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alert, animated: true, completion: nil)
        }
        
    } //end alert3i
    
    
    func alert3() {
        
        let message = "Please scan the new dosimeter for location \(variables.QRCode ?? "Nil Dosi").\n\n\n\n\n\n\n"
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let imageView = UIImageView(frame: CGRect(x: 75, y: 90, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Replace Dosimeter", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerOK)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert3
    
    
    func alert4() {
        
        let message = "Dosimeter barcode accepted \(variables.dosiNumber ?? "Nil Dosi"). Please scan the corresponding location code.\n\n\n\n\n\n\n"
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert4
    
    
    func alert5() {
        
        let message = "Location code accepted \(variables.QRCode ?? "Nil QR"). Please scan the corresponding dosimeter.\n\n\n\n\n\n"
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let imageView = UIImageView(frame: CGRect(x: 75, y: 100, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert5
    
    
    func alert6a() {
        
        let message = "Try again...Please scan the corresponding location code.\n\n\n\n\n\n\n"
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert6a
    
    
    func alert6b() {
        
        let message = "Try again...Please scan the corresponding dosimeter.\n\n\n\n\n\n\n"
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let imageView = UIImageView(frame: CGRect(x: 75, y: 90, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert6b
    
    
    func alert7a(code: String) {
        
        let message = "Try again...Please scan a new dosimeter.\n\n\n\n\n\n\n"
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let imageView = UIImageView(frame: CGRect(x: 75, y: 110, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Duplicate Dosimeter:\n\(code)", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert7a
    
    
    func alert7b(code: String) {
        
        let title = variables.collected == 0 ? "Location In Use:\n\(code)" : "Inactive Location:\n\(variables.QRCode ?? "Nil QRCode")"
        let message = "Try again...Please scan a different location.\n\n\n\n\n\n\n"
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let imageView = UIImageView(frame: CGRect(x: 90, y: 110, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert7b
    
//MARK:  Alert8
    func alert8() {

        let cycle = RecordsUpdate.generateCycleDate()
        variables.cycle = cycle
        getCoordinates()
        
        let alert = UIAlertController(title: "Deploy Dosimeter:\n\(variables.dosiNumber ?? "Nil Dosi")", message: "\nLocation: \(variables.QRCode ?? "Nil QRCode")", preferredStyle: .alert)
        
        let moderator = UIAlertAction(title: "Moderator", style: .default) { (_) in
            self.alert8()
        }
        
        let saveRecord = UIAlertAction(title: "Save", style: .default) { (_) in
            if let text = alert.textFields?.first?.text {
                let label = UILabel(frame: CGRect(x: 0, y: 97, width: 270, height:18))
                label.textAlignment = .center
                label.textColor = .red
                //label.font = label.font.withSize(12)
                label.font = .boldSystemFont(ofSize: 14)
                alert.view.addSubview(label)
                label.isHidden = true
                if text == ""{
                    label.text = "Please enter a location"
                    label.isHidden = false
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.recordsupdate.saveRecord(latitude: variables.latitude ?? "Nil Latitude",
                                                  longitude: variables.longitude ?? "Nil Longitude",
                                                  dosiNumber: variables.dosiNumber ?? "Nil Dosi",
                                                  text: text,
                                                  flag: 0,
                                                  cycle: cycle,
                                                  QRCode: variables.QRCode ?? "Nil QRCode",
                                                  mismatch: variables.mismatch ?? 0,
                                                  moderator: variables.moderator ?? 0,
                                                  active: 1,
                                                  createdDate: Date(timeInterval: 0, since: Date()),
                                                  modifiedDate: Date(timeInterval: 0, since: Date()))
                    self.alert10() //Succes
                }
    
            //text = text?.replacingOccurrences(of: ",", with: "-")
            //Ver 1.2 - supply default location to prevent empty string in DB.
            //rather than alert on top of alert for field valication
            //if text == "" {
             //   text = "Default Location (field left empty)"
        
        } //end if let

            
        }  //end let
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        alert.addTextField { (textfield) in
            if variables.dosiLocation != nil {
                textfield.text = variables.dosiLocation // assign self.description with the textfield information
            }
            textfield.placeholder = "Type or dictate location details" //assign self.description with the textfield information
        } // end addTextField
        
        alert.addAction(moderator)
        alert.view.addSubview(modSwitch())
        alert.addAction(saveRecord)
        alert.addAction(cancel)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert8
    
    
    func alert9() {  //invalid barcode type

        let message = "Please scan either a location barcode or a dosimeter."
      
        //set up alert
        let alert = UIAlertController.init(title: "Invalid Barcode Type", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerCancel)

        alert.addAction(OK)

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert9
    
    
    func alert9a() {  //already collected dosimeter
        
        let message = "This dosimeter has already been collected."
        
        //set up alert
        let alert = UIAlertController.init(title: "Invalid Dosimeter:\n\(variables.dosiNumber ?? "Nil Dosi")", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerCancel)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert9
    
    
    func alert10(){  //Success! (Deploy)
        
        //let message = "Data saved: \nQR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")\nLocation: \(variables.dosiLocation ?? "Nil location")\nFlag (Depl'y = 0, Collected = 1): 0\nLatitude: \(variables.latitude ?? "Nil Latitude")\nLongitude: \(variables.longitude ?? "Nil Longitude")\nWear Date: \(variables.cycle ?? "Nil cycle")\nMismatch (No = 0 Yes = 1): \(variables.mismatch ?? 0)\nModerator (No = 0 Yes = 1): \(variables.moderator ?? 0)"
        
        let message = "QR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")"
        
        //set up alert
        let alert = UIAlertController.init(title: "Save Successful!", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerCancel)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert10
    
    
    func alert11() {  //Success! (Collect)
        
        //let message = "Data Saved:\nQR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")\nLocation: \(variables.dosiLocation ?? "Nil location")\nFlag (Depl'y = 0, Collected = 1): 1 \nMismatch (No = 0 Yes = 1): \(variables.mismatch ?? 0)"
        
        let message = "QR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")"
        
        //set up alert
        let alert = UIAlertController.init(title: "Collection Successful!", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerCancel)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert11
    
    
    func alert11a() {  //Success! (Exchange)
        
        //let message = "Data Saved:\nQR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")\nLocation: \(variables.dosiLocation ?? "Nil location")\nFlag (Depl'y = 0, Collected = 1): 1 \nMismatch (No = 0 Yes = 1): \(variables.mismatch ?? 0)"
        
        let message = "QR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")"
        
        //set up alert
        let alert = UIAlertController.init(title: "Collection Successful!", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default) { (_) in
            self.deploy()
            variables.mismatch = 0
            variables.dosiNumber = nil
            self.alert3()
        }
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert11a
    
    
    //mismatch switch
    func mismatchSwitch() -> UISwitch {
        let switchControl = UISwitch(frame: CGRect(x: 200, y: 191, width: 0, height: 0))
        switchControl.tintColor = UIColor.gray
        switchControl.setOn(variables.mismatch == 1, animated: false)
        switchControl.addTarget(self, action: #selector(mismatchSwitchValueDidChange), for: .valueChanged)
        return switchControl
    }
    
    @objc func mismatchSwitchValueDidChange(_ sender: UISwitch!) {
        variables.mismatch = sender.isOn ? 1 : 0
    }
    
    
    //moderator switch
    func modSwitch() -> UISwitch {
        let switchControl = UISwitch(frame: CGRect(x: 200, y: 161, width: 0, height: 0))
        switchControl.tintColor = UIColor.gray
        switchControl.setOn(variables.moderator == 1, animated: false)
        switchControl.addTarget(self, action: #selector(modSwitchValueDidChange), for: .valueChanged)
        return switchControl
    }
    
    @objc func modSwitchValueDidChange(_ sender: UISwitch!) {
        variables.moderator = sender.isOn ? 1 : 0
    }
    
}//end extension alerts

/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */

extension ScannerViewController {  //handlers
    
    func handlerOK(alert: UIAlertAction!) {  //used for OK in the alert prompt.
        
        self.captureSession.startRunning()
        
    } //end handler
    
    func handlerCancel(alert: UIAlertAction!) {
        
        self.clearData()
        self.captureSession.startRunning()
    }
    
} //end extension
