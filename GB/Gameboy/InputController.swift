//
//  InputController.swift
//  GB
//
//  Created by Nathan Gelman on 8/9/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

class InputController {
    
    private enum InputMode: UInt8 {
        case Undefined = 0x30
        case P14 = 0x10
        case P15 = 0x20
    }
    
    private var inputMode = InputMode.P14
    
    var buttonPressed = false {
        didSet {
            if buttonPressed {
                CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.Joypad)
            }
        }
    }
    
    var a = false
    var b = false
    var up = false
    var down = false
    var left = false
    var right = false
    var select = false
    var start = false
    
    var register: UInt8 {
        get {
            if inputMode == .P14 {
                return UInt8(down ? 0b0111 : 0xF) &
                            (up ? 0b1011 : 0xF) &
                            (left ? 0b1101 : 0xF) &
                            (right ? 0b1110 : 0xF)
            } else {
                return UInt8(start ? 0b0111 : 0xF) &
                            (select ? 0b1011 : 0xF) &
                            (b ? 0b1101 : 0xF) &
                            (a ? 0b1110 : 0xF)
            }
        }
        set {
            inputMode = InputMode(rawValue: (~newValue) & 0x30) ?? InputMode.Undefined
        }
    }
}

protocol InputInterfacing {
    var register: UInt8 { get set }
}
