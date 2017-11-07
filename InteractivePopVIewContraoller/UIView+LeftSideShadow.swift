//
//  UIView+LeftSideShadow.swift
//  InteractivePopVIewContraoller
//
//  Created by Khemmachart Chutapetch on 11/7/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

extension UIView {
    
    func addLeftSideShadow() {
        let shadowWidth: CGFloat = 4.0
        let shadowRect = CGRect(x: -shadowWidth, y: 0, width: shadowWidth, height: frame.height)
        let shadowPath = UIBezierPath(rect: shadowRect)
        layer.shadowPath = shadowPath.cgPath
        layer.shadowOpacity = 0.2
    }
}
