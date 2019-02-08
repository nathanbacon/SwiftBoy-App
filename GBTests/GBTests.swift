//
//  GBTests.swift
//  GBTests
//
//  Created by Nathan Gelman on 2/7/19.
//  Copyright © 2019 Nathan Gelman. All rights reserved.
//

import XCTest
@testable import GB

class GBTests: XCTestCase {
    
    var carry: Bool {
        get {
            return CPU.registers.flags.carry
        }
        set {
            CPU.registers.flags.carry = newValue
        }
    }
    
    var halfCarry: Bool {
        get {
            return CPU.registers.flags.halfCarry
        }
    }
    
    var zero: Bool {
        get {
            return CPU.registers.flags.zero
        }
    }
    
    var subtract: Bool {
        get {
            return CPU.registers.flags.subtract
        }
    }
    
    var A: UInt8 {
        get {
            return CPU.registers.A
        }
        set {
            CPU.registers.A = newValue
        }
    }
    
    var C: UInt8 {
        get {
            return CPU.registers.C
        }
        set {
            CPU.registers.C = newValue
        }
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        CPU.registers.PC = 0xC000
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        CPU.registers = Registers()
        //MMU.mmu = MMU()
    }

    func testLd16() {
        CPU.mmu[CPU.registers.PC] = 0x34
        CPU.mmu[CPU.registers.PC+1] = 0x12
        let ld1234 = I(.LD16, .BC, .Immed16)
        ld1234()
        XCTAssertEqual(0x1234, CPU.registers.BC)
    }

    func testLd8() {
        CPU.mmu[CPU.registers.PC] = 0x12
        let ldff = I(.LD8, .B, .Immed8)
        ldff()
        XCTAssertEqual(0x12, CPU.registers.B)
    }
    
    func testAdd8() {
        CPU.mmu[CPU.registers.PC] = 0x8F
        CPU.registers.B = 0x8F
        let add = I(.ADD8, .B, .Immed8)
        add()
        XCTAssertEqual(0x1E, CPU.registers.B)
        XCTAssert(CPU.registers.flags.carry)
        XCTAssert(CPU.registers.flags.halfCarry)
        XCTAssertFalse(CPU.registers.flags.subtract)
        XCTAssertFalse(CPU.registers.flags.zero)
        
        CPU.mmu[CPU.registers.PC] = 0x01
        CPU.registers.B = 0x01
        add()
        XCTAssertEqual(0x02, CPU.registers.B)
        XCTAssertFalse(CPU.registers.flags.carry)
        XCTAssertFalse(CPU.registers.flags.halfCarry)
        XCTAssertFalse(CPU.registers.flags.zero)
        
        let addBetweenReg = I(.ADD8, .B, .C)
        CPU.registers.B = 0
        CPU.registers.C = 0
        addBetweenReg()
        XCTAssert(CPU.registers.flags.zero)
    }
    
    func testAdd16() {
        let add16 = I(.ADD16, .HL, .BC)
        CPU.registers.HL = 0x1111
        CPU.registers.BC = 0x2222
        add16()
        XCTAssertEqual(0x1111 + 0x2222, CPU.registers.HL)
        XCTAssertFalse(carry)
        XCTAssertFalse(halfCarry)
        XCTAssertFalse(subtract)
        XCTAssertFalse(zero)
        
        CPU.registers.HL = 0xFFFF
        CPU.registers.BC = 0x0001
        add16()
        XCTAssert(carry)
        XCTAssert(halfCarry)
        XCTAssertEqual(0, CPU.registers.HL)
    }
    
    func testADC() {
        let adc = I(.ADC, .A, .C)
        carry = true
        
        CPU.registers.A = 0x00
        CPU.registers.C = 0x00
        adc()
        XCTAssertEqual(0x01, CPU.registers.A)
        XCTAssertFalse(subtract)
        XCTAssertFalse(zero)
        XCTAssertFalse(halfCarry)
        XCTAssertFalse(carry)
        
        CPU.registers.A = 0xE1
        CPU.registers.C = 0x0F
        carry = true
        adc()
        XCTAssertEqual(0xF1, CPU.registers.A)
        XCTAssertTrue(halfCarry)
        XCTAssertFalse(carry)
        XCTAssertFalse(zero)
        
        CPU.registers.A = 0xE1
        CPU.registers.C = 0x1E
        carry = true
        adc()
        XCTAssertEqual(0, CPU.registers.A)
        XCTAssertTrue(zero)
    }
    
    func testSBC() {
        let SBC = I(.SBC, .A, .C)
        A = 0x3B
        C = 0x2A
        carry = true
        SBC()
        XCTAssertEqual(0x10, A)
        XCTAssertFalse(zero)
        XCTAssertFalse(halfCarry)
        XCTAssertFalse(carry)
        XCTAssertTrue(subtract)
        
        A = 0x3B
        C = 0x4F
        carry = true
        SBC()
        XCTAssertEqual(0xEB, A)
        XCTAssertTrue(halfCarry)
        XCTAssertTrue(carry)
        XCTAssertFalse(zero)
        
        A = 0x3B
        C = 0x3A
        carry = true
        SBC()
        XCTAssertEqual(0, A)
        XCTAssertTrue(zero)
        XCTAssertFalse(halfCarry)
        XCTAssertFalse(carry)
    }

}
