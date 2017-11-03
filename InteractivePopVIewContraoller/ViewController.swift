//
//  ViewController.swift
//  InteractivePopVIewContraoller
//
//  Created by Khemmachart Chutapetch on 11/2/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(navigationController?.viewControllers.count ?? 0)"
    }
}

