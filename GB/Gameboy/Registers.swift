//
//  Registers.swift
//  GB
//
//  Created by Nathan Gelman on 7/2/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

struct Registers {
    var A: UInt8 = 0x1
    var F: UInt8 {
        get {
            return UInt8(flags.zero ? 0x80 : 0x00) +
            (flags.subtract ? 0x40 : 0x00) +
            (flags.halfCarry ? 0x20 : 0x00) +
            (flags.carry ? 0x10 : 0x00)
        }
        set {
            flags.zero = 0x80 & newValue > 0
            flags.subtract = 0x40 & newValue > 0
            flags.halfCarry = 0x20 & newValue > 0
            flags.carry = 0x10 & newValue > 0
        }
    }
    var B: UInt8 = 0
    var C: UInt8 = 0x13
    var D: UInt8 = 0
    var E: UInt8 = 0xD8
    var H: UInt8 = 0x01
    var L: UInt8 = 0x4D
    var IX: UInt16 = 0
    var IY: UInt16 = 0
    var SP: UInt16 = 0xFFFE
    var I: UInt8 = 0
    var R: UInt8 = 0
    var PC: UInt16 = 0x100
    
    struct Flags {
        var zero: Bool = false
        var subtract: Bool = false
        var halfCarry: Bool = false
        var carry: Bool = false
    }
    
    var flags: Flags = Flags()
    
    /*var zero: Bool {
        get {
            return F & 0b10000000 > 0
        }
        set {
            if newValue {
                F |= 0b10000000
            } else {
                F &= 0b01111111
            }
        }
    }*/
    
    var AF: UInt16 {
        get {
            let upper = UInt16(A) << 8
            let lower = UInt16(F)
            return upper | lower
        }
        set {
            A = UInt8((newValue & 0xFF00) >> 8)
            F = UInt8(newValue & 0x00FF)
        }
    }
    
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




