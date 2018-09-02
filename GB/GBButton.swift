//
//  GBButton.swift
//  GB
//
//  Created by Nathan Gelman on 8/9/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import UIKit

class GBButton: UIButton {

    enum Button {
        case up
        case down
        case left
        case right
        case a
        case b
        case start
        case select
    }
    
    var gbButtonType: Button!

}
