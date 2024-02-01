//
//  PSShadow.swift
//  ElegantPopover
//
//  Created by HIEN PHAM on 01/02/2024.
//

import UIKit

/// An object representing a shadow of the popover.
public struct PSShadow {
    public var shadowColor: UIColor?
    public var shadowOffset: CGSize = .zero
    public var shadowRadius: CGFloat = 0
    public var shadowOpacity: Float = 1
    public var shadowSpread: CGFloat = 0
    
    public init() {
        
    }
}
