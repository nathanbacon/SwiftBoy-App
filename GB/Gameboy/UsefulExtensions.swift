//
//  UsefulExtensions.swift
//  GB
//
//  Created by Nathan Gelman on 9/6/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

extension UInt8 {
    func rotatingLeft () -> (result: UInt8, carry: Bool) {
        let c = (self & 0x80) > 0
        let r = self << 1
        return (r, c)
    }
    
    func rotatingRight() -> (result: UInt8, carry: Bool) {
        let c = (self & 0x01) > 0
        let r = self >> 1
        return (r, c)
    }
    
    func rotatingRightCircular() -> (result: UInt8, carry: Bool) {
        let res = self.rotatingRight()
        return ((res.result | (res.carry ? 0x80 : 0x00)), res.carry)
    }
    
    func rotatingLeftCircular() -> (result: UInt8, carry: Bool) {
        let res = self.rotatingLeft()
        return ((res.result | (res.carry ? 0x01 : 0x00)), res.carry)
    }
    
    func rotatingRightThrough(carry: Bool) -> (result: UInt8, carry: Bool) {
        let res = self.rotatingRight()
        return ((res.result | (carry ? 0x80 : 0x00)), res.carry)
    }
    
    func rotatingLeftThrough(carry: Bool) -> (result: UInt8, carry: Bool) {
        let res = self.rotatingLeft()
        return ((res.result | (carry ? 0x01 : 0x00)), res.carry)
    }
    
}

extension Array {
    subscript(index: UInt16) -> Element {
        get { return self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
    subscript(index: UInt8) -> Element {
        get { return self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}

extension Data {
    subscript(index: UInt16) -> Element {
        get { return self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}
