//
//  PhotoViewController.swift
//  LocationApp
//
//  Created by László Szöllősi on 2023. 07. 11..
//  Copyright © 2023. Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var photoView: UIImageView!
    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        super.viewDidLoad()
    }
}
