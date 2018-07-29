//
//  Timer.swift
//  GB
//
//  Created by Nathan Gelman on 7/28/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

struct Timer {
    
    static var counter: UInt8 = 0
    static var modulo: UInt8 = 0
    static var divider: UInt8 = 0
    private static var timerEnabled = false
    private static var clockMode: UInt8 = 4 {
        didSet {
            switch clockMode {
            case 0b00:
                overflowBit = 1 << 10
            case 0b01:
                overflowBit = 1 << 4
            case 0b10:
                overflowBit = 1 << 6
            case 0b11:
                overflowBit = 1 << 8
            default:
                fatalError("This should be impossible but I've been wrong before!")
            }
        }
    }
    private static var overflowBit: UInt = 1 << 4 // this is for selecting the bit that is high when the timer should be incremented
    private static var internalCounter: UInt = 0
    private static var internalDividerCounter: UInt = 0
    static var controllerRegister: UInt8 {
        get {
            return (timerEnabled ? 0x4 : 0x0) | clockMode
        }
        set {
            timerEnabled = (newValue & 0x04) > 0
            clockMode = newValue & 0b11
        }
    }
    
    static func updateTimer(elapsed time: UInt) {
        internalDividerCounter += time
        if internalDividerCounter & (1 << 8) > 0 { // this should trigger every 256 clock cycles
            internalDividerCounter = internalDividerCounter - 0x100
            divider = divider &+ 1
        }
        if timerEnabled {
            internalCounter += time
            if internalCounter & overflowBit > 0 {
                // increment the timer
                let a = counter.addingReportingOverflow(1)
                counter = a.partialValue
                if a.overflow {
                    CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.Timer)
                }
                // reset the internal counter
                internalCounter = 0
                // reset counter to the modulo
                counter = modulo
            }
        }
        
    }
}
