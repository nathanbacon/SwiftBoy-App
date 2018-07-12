//
//  Registers.swift
//  GB
//
//  Created by Nathan Gelman on 7/2/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

struct Registers {
    var A: UInt8 = 0
    var F: UInt8 = 0
    var B: UInt8 = 0
    var C: UInt8 = 0
    var D: UInt8 = 0
    var E: UInt8 = 0
    var H: UInt8 = 0
    var L: UInt8 = 0
    var IX: UInt16 = 0
    var IY: UInt16 = 0
    var SP: UInt16 = 0
    var I: UInt8 = 0
    var R: UInt8 = 0
    var PC: UInt16 = 0
    
    var BC: UInt16 {
        get {
            return (UInt16(B) << 8) | UInt16(C)
        }
        set {
            B = UInt8(newValue >> 8)
            C = UInt8(newValue & 0x00FF)
        }
    }
    
    var DE: UInt16 {
        get {
            return (UInt16(D) << 8) | UInt16(E)
        }
        set {
            D = UInt8(newValue >> 8)
            E = UInt8(newValue & 0x00FF)
        }
    }
    
    var HL: UInt16 {
        get {
            return (UInt16(H) << 8) | UInt16(L)
        }
        set {
            H = UInt8(newValue >> 8)
            L = UInt8(newValue & 0x00FF)
        }
    }
    
}



