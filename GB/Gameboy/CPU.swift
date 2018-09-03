//
//  CPU.swift
//  GB
//
//  Created by Nathan Gelman on 5/10/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation



class CPU {
    
    static var cpu: CPU = CPU()
    
    static var registers = Registers()
    
    static var mmu: MMU = MMU.mmu
    
    //static var currentInstruction: Instruction = CPU.basicTable[0]
    
    static var cycles: UInt = 0
    
    static fileprivate var prevInstCycles: UInt = 0
    
    static var interruptEnabled = false {
        didSet {
            Interrupt.IF = 0x00
        }
    }
    
    static var debugMode = false
    static var prevInstruction = ""
    static var totalInstructions = 0
    static var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    
    static var isHalted = false
    
    private init() {
        
    }
    
    static func execNextInstruction() -> UInt {
        
        if CPU.isHalted {
            return 4
        } else {
            CPU.prevInstCycles = 0
            /*if (0x7880...0x789D).contains(CPU.registers.PC) {
                print("\(CPU.registers.A)")
            }*/
            CPU.fetchInstruction()()
            //totalInstructions += 1
            return prevInstCycles
            //return 32
        }
        
    }
    
    enum Interrupt: UInt16 {
        case VBlank = 0x40
        case LCD = 0x48
        case Timer = 0x50
        //case Serial
        case Joypad = 0x60
        
        static var VBlankRequested = false
        static var LCDRequested = false
        static var TimerRequested = false
        static var SerialRequested = false
        static var JoypadRequested = false
        
        static var IF: UInt8 {
            get {
                return UInt8(VBlankRequested ? 0x1 : 0x0) |
                    (LCDRequested ? 0x2 : 0x0) |
                    (TimerRequested ? 0x4 : 0x0) |
                    (SerialRequested ? 0x8 : 0x0) |
                    (JoypadRequested ? 0x10 : 0x0)
            }
            set {
                VBlankRequested = (newValue & 0x1) > 0
                LCDRequested = (newValue & 0x2) > 0
                TimerRequested = (newValue & 0x4) > 0
                SerialRequested = (newValue & 0x8) > 0
                JoypadRequested = (newValue & 0x10) > 0
            }
        }
        
        static var VBlankEnabled = false
        static var LCDEnabled = false
        static var TimerEnabled = false
        static var SerialEnabled = false
        static var JoypadEnabled = false
        
        static var IE: UInt8 {
            get {
                return UInt8(VBlankEnabled ? 0x1 : 0) |
                    (LCDEnabled ? 0x2 : 0) |
                    (TimerEnabled ? 0x4 : 0) |
                    (SerialEnabled ? 0x8 : 0) |
                    (JoypadEnabled ? 0x10 : 0)
            }
            set {
                VBlankEnabled = (newValue & 0x1) > 0
                LCDEnabled = (newValue & 0x2) > 0
                TimerEnabled = (newValue & 0x4) > 0
                SerialEnabled = (newValue & 0x8) > 0
                JoypadEnabled = (newValue & 0x10) > 0
            }
        }
        
        static func processInterrupts() {
            if interruptEnabled {
                if VBlankRequested && VBlankEnabled {
                    VBlankRequested = false
                    serviceInterrupt(for: .VBlank)
                } else if LCDEnabled && LCDRequested {
                    LCDRequested = false
                    serviceInterrupt(for: .LCD)
                } else if TimerEnabled && TimerRequested {
                    TimerRequested = false
                    serviceInterrupt(for: .Timer)
                } else if JoypadEnabled && JoypadRequested {
                    JoypadRequested = false
                    serviceInterrupt(for: .Joypad)
                }
            }
        }
        
        static func serviceInterrupt(for type: Interrupt) {
            pushPC()
            CPU.registers.PC = type.rawValue
            CPU.isHalted = false
        }
        
        static func requestInterrupt(for interrupt: Interrupt) {
            if interruptEnabled {
                switch interrupt {
                case .VBlank:
                    Interrupt.VBlankRequested = true
                case .LCD:
                    Interrupt.LCDRequested = true
                case .Timer:
                    Interrupt.TimerRequested = true
                case .Joypad:
                    Interrupt.JoypadRequested = true
                }
            }
            
        }
    }
    
    static func fetchInstruction() -> ()->() {
        if (0xFF00..<0xFF80).contains(Int(CPU.registers.PC)) || (0xE000..<0xFF00).contains(Int(CPU.registers.PC)) {
            fatalError("\(CPU.registers.PC)")
        }
        let opcode = CPU.mmu[CPU.registers.PC]
        CPU.registers.PC += 1
        return CPU.basicTable[opcode]
        
    }
    
    static func readByteImmediate() -> UInt8 {
        let immed = CPU.mmu[CPU.registers.PC]
        CPU.registers.PC += 1
        return immed
    }
    
    static func readWordImmediate() -> UInt16 {
        let h = CPU.mmu[CPU.registers.PC + 1]
        let l = CPU.mmu[CPU.registers.PC]
        CPU.registers.PC += 2
        return (UInt16(h) << 8) | UInt16(l)
    }

    static let basicTable: Array<()->()> = [
        I(.NOOP), // 0x00 -> NOP
        I(.LD16,.BC, .Immed16), // 0x01 -> LD BC,d16
        I( .LD8, .Mem(.BC), .A), // 0x02 -> LD (BC), A
        I(.INC16, .BC), // 0x03 -> INC BC
        I(.INC8, .B), // 0x04 -> INC B
        I(.DEC8, .B), // 0x05 -> DEC B
        I(.LD8, .B, .Immed8), // 0x06 -> LD B, d8
        I(.RLCA), // 0x07 -> RLCA
        I(.LD16, .Mem(.Immed16), .SP), // 0x08 -> LD (a16), SP
        I(.ADD16, .HL, .BC), // 0x09 -> ADD HL, BC
        I(.LD8, .A, .Mem(.BC)), // 0x0A -> LD A, (BC)
        I(.DEC16, .BC), // 0x0B -> DEC BC
        I(.INC8, .C), // 0x0C -> INC C
        I(.DEC8, .C), // 0x0D -> DEC C
        I(.LD8, .C, .Immed8), // 0x0E -> LD C, d8
        I(.RRCA), // 0x0F -> RRCA
        
        I(.STOP), // 0x10 -> STOP
        I(.LD16, .DE, .Immed16), // 0x11 -> LD DE, d16
        I(.LD8, .Mem(.DE), .A), // 0x12 -> LD (DE), A
        I(.INC16, .DE), // 0x13 -> INC DE
        I(.INC8, .D), // 0x14 -> INC D
        I(.DEC8,.D), // 0x15 -> DEC D
        I(.LD8, .D, .Immed8), // 0x16 -> LD D
        I(.RLA), // 0x17 -> RLA
        I(     .JR,    .Immed8,    nil), // 0x18 -> JR r8
        I(  .ADD16,     .HL,       .DE), // 0x19 -> ADD HL, DE
        I(    .LD8,    .A,   .Mem(.DE)), // 0x1A -> LD A, (DE)
        I(  .DEC16,    .DE,    nil), // 0x1B -> DEC DE
        I(  .INC8,    .E,    nil), // 0x1C -> INC E
        I(  .DEC8,    .E,    nil), // 0x1D -> DEC E
        I(  .LD8,    .E,    .Immed8), // 0x1E -> LD E, d8
        I(  .RRA,    nil,    nil), // 0x1F -> RRA
        
        I(  .JR,   .NZ_flag,    .Immed8), // 0x20 -> JR NZ, r8
        I(  .LD16,    .HL,    .Immed16), // 0x21 -> LD HL, d16
        I(  .LD8,    .Mem(.HLi),    .A), // 0x22 -> LD (HL+), A
        I(  .INC16,    .HL,    nil), // 0x23 -> INC HL
        I(  .INC8,    .H,    nil), // 0x24 -> INC H
        I(  .DEC8,    .H,    nil), // 0x25 -> DEC H
        I(  .LD8,    .H,    .Immed8), // 0x26 -> LD H, d8
        I(  .DAA,    nil,    nil), // 0x27 -> DAA
        I(  .JR,    .Z_flag,    .Immed8), // 0x28 -> JR Z, r8
        I(  .ADD16,    .HL,    .HL), // 0x29 -> ADD HL, HL
        I(  .LD8,    .A,    .Mem(.HLi)), // 0x2A -> LD a, (HL+)
        I(  .DEC16,    .HL,    nil), // 0x2B -> DEC HL
        I(  .INC8,    .L), // 0x2C -> INC L
        I(  .DEC8,    .L), // 0x2D -> DEC L
        I(  .LD8,    .L,    .Immed8), // 0x2E -> LD L, d8
        I(  .CPL ), // 0x2F -> CPL
        
        // TODO fix comments for the opcode description
        I(  .JR,    .NC_flag,    .Immed8), // 0x30 -> JR NC, r8
        I(  .LD16,    .SP,    .Immed16), // 0x31 -> LD SP, d16
        I(  .LD8,    .Mem(.HLd),    .A), // 0x32 -> LD (HL-), A
        I(  .INC16,    .SP,    nil), // 0x33 -> INC HL
        I(  .INC8,    .Mem(.HL),    nil), // 0x34 -> INC H
        I(  .DEC8,    .Mem(.HL),    nil), // 0x35 -> DEC H
        I(  .LD8,    .Mem(.HL),    .Immed8), // 0x36 -> LD H, d8
        I(  .SCF,    nil,    nil), // 0x37 -> DAA
        I(  .JR,    .C_flag,    .Immed8), // 0x38 -> JR Z, r8
        I(  .ADD16,    .HL,    .SP), // 0x39 -> ADD HL, HL
        I(  .LD8,    .A,    .Mem(.HLd)), // 0x3A -> LD a, (HL+)
        I(  .DEC16,    .SP,    nil), // 0x3B -> DEC HL
        I(  .INC8,    .A), // 0x3C -> INC L
        I(  .DEC8,    .A), // 0x3D -> DEC L
        I(  .LD8,    .A,    .Immed8), // 0x3E -> LD L, d8
        I(  .CCF ), // 0x3F -> CPL
        
        I(  .LD8,    .B,    .B), // 0x40 -> LD B, B
        I(  .LD8,    .B,    .C), // 0x41 -> LD B, C
        I(  .LD8,    .B,    .D), // 0x42 -> LD B, D
        I(  .LD8,    .B,    .E), // 0x43 -> LD B, E
        I(  .LD8,    .B,    .H), // 0x44 -> LD B, H
        I(  .LD8,    .B,    .L), // 0x45 -> LD B, L
        I(  .LD8,    .B,    .Mem(.HL)), // 0x46 -> LD B, (HL)
        I(  .LD8,    .B,    .A), // 0x47 -> LD B, A
        I(  .LD8,    .C,    .B), // 0x48 -> LD C, B
        I(  .LD8,    .C,    .C), // 0x49 -> LD C, C
        I(  .LD8,    .C,    .D), // 0x4A -> LD C, D
        I(  .LD8,    .C,    .E), // 0x4B -> LD C, E
        I(  .LD8,    .C,    .H), // 0x4C -> LD C, H
        I(  .LD8,    .C,    .L), // 0x4D -> LD B, L
        I(  .LD8,    .C,    .Mem(.HL)), // 0x4E -> LD B, (HL)
        I(  .LD8,    .C,    .A), // 0x4F -> LD B, A
        
        I(  .LD8,    .D,    .B), // 0x50 -> LD B, B
        I(  .LD8,    .D,    .C), // 0x51 -> LD B, C
        I(  .LD8,    .D,    .D), // 0x52 -> LD B, D
        I(  .LD8,    .D,    .E), // 0x53 -> LD B, E
        I(  .LD8,    .D,    .H), // 0x54 -> LD B, H
        I(  .LD8,    .D,    .L), // 0x55 -> LD B, L
        I(  .LD8,    .D,    .Mem(.HL)), // 0x56 -> LD B, (HL)
        I(  .LD8,    .D,    .A), // 0x57 -> LD B, A
        I(  .LD8,    .E,    .B), // 0x58 -> LD C, B
        I(  .LD8,    .E,    .C), // 0x59 -> LD C, C
        I(  .LD8,    .E,    .D), // 0x5A -> LD C, D
        I(  .LD8,    .E,    .E), // 0x5B -> LD C, E
        I(  .LD8,    .E,    .H), // 0x5C -> LD C, H
        I(  .LD8,    .E,    .L), // 0x5D -> LD B, L
        I(  .LD8,    .E,    .Mem(.HL)), // 0x5E -> LD B, (HL)
        I(  .LD8,    .E,    .A), // 0x5F -> LD B, A
        
        I(  .LD8,    .H,    .B), // 0x50 -> LD B, B
        I(  .LD8,    .H,    .C), // 0x51 -> LD B, C
        I(  .LD8,    .H,    .D), // 0x52 -> LD B, D
        I(  .LD8,    .H,    .E), // 0x53 -> LD B, E
        I(  .LD8,    .H,    .H), // 0x54 -> LD B, H
        I(  .LD8,    .H,    .L), // 0x55 -> LD B, L
        I(  .LD8,    .H,    .Mem(.HL)), // 0x56 -> LD B, (HL)
        I(  .LD8,    .H,    .A), // 0x57 -> LD B, A
        I(  .LD8,    .L,    .B), // 0x58 -> LD C, B
        I(  .LD8,    .L,    .C), // 0x59 -> LD C, C
        I(  .LD8,    .L,    .D), // 0x5A -> LD C, D
        I(  .LD8,    .L,    .E), // 0x5B -> LD C, E
        I(  .LD8,    .L,    .H), // 0x5C -> LD C, H
        I(  .LD8,    .L,    .L), // 0x5D -> LD B, L
        I(  .LD8,    .L,    .Mem(.HL)), // 0x5E -> LD B, (HL)
        I(  .LD8,    .L,    .A), // 0x5F -> LD B, A
        
        I(  .LD8,    .Mem(.HL),    .B), // 0x50 -> LD B, B
        I(  .LD8,    .Mem(.HL),    .C), // 0x51 -> LD B, C
        I(  .LD8,    .Mem(.HL),    .D), // 0x52 -> LD B, D
        I(  .LD8,    .Mem(.HL),    .E), // 0x53 -> LD B, E
        I(  .LD8,    .Mem(.HL),    .H), // 0x54 -> LD B, H
        I(  .LD8,    .Mem(.HL),    .L), // 0x55 -> LD B, L
        I(  .HALT), // 0x56 -> LD B, (HL)
        I(  .LD8,    .Mem(.HL),    .A), // 0x57 -> LD B, A
        I(  .LD8,    .A,    .B), // 0x58 -> LD C, B
        I(  .LD8,    .A,    .C), // 0x59 -> LD C, C
        I(  .LD8,    .A,    .D), // 0x5A -> LD C, D
        I(  .LD8,    .A,    .E), // 0x5B -> LD C, E
        I(  .LD8,    .A,    .H), // 0x5C -> LD C, H
        I(  .LD8,    .A,    .L), // 0x5D -> LD B, L
        I(  .LD8,    .A,    .Mem(.HL)), // 0x5E -> LD B, (HL)
        I(  .LD8,    .A,    .A), // 0x5F -> LD B, A
        
        I(  .ADD8,    .A,    .B), // 0x80
        I(  .ADD8,    .A,    .C), // 0x81
        I(  .ADD8,    .A,    .D), // 0x82
        I(  .ADD8,    .A,    .E), // 0x83
        I(  .ADD8,    .A,    .H), // 0x84
        I(  .ADD8,    .A,    .L), // 0x85
        I(  .ADD8,    .A,    .Mem(.HL)), // 0x86
        I(  .ADD8,    .A,    .A), // 0x87
        I(  .ADC,    .A,    .B), // 0x88
        I(  .ADC,    .A,    .C), // 0x89
        I(  .ADC,    .A,    .D), // 0x8A
        I(  .ADC,    .A,    .E), // 0x8B
        I(  .ADC,    .A,    .H), // 0x8C
        I(  .ADC,    .A,    .L), // 0x8D
        I(  .ADC,    .A,    .Mem(.HL)), // 0x8E
        I(  .ADC,    .A,    .A), // 0x8F
        
        I(  .SUB,    .B), // 0x90
        I(  .SUB,    .C), // 0x91
        I(  .SUB,    .D), // 0x92
        I(  .SUB,    .E), // 0x93
        I(  .SUB,    .H), // 0x94
        I(  .SUB,    .L), // 0x95
        I(  .SUB,    .Mem(.HL)), // 0x96
        I(  .SUB,    .A), // 0x97
        I(  .SBC,    .A,    .B), // 0x98
        I(  .SBC,    .A,    .C), // 0x99
        I(  .SBC,    .A,    .D), // 0x9A
        I(  .SBC,    .A,    .E), // 0x9B
        I(  .SBC,    .A,    .H), // 0x9C
        I(  .SBC,    .A,    .L), // 0x9D
        I(  .SBC,    .A,    .Mem(.HL)), // 0x9E
        I(  .SBC,    .A,    .A), // 0x9F
        
        I(  .AND,    .B), // 0xA0
        I(  .AND,    .C), // 0xA1
        I(  .AND,    .D), // 0xA2
        I(  .AND,    .E), // 0xA3
        I(  .AND,    .H), // 0xA4
        I(  .AND,    .L), // 0xA5
        I(  .AND,    .Mem(.HL)), // 0xA6
        I(  .AND,    .A), // 0xA7
        I(  .XOR,    .B), // 0xA8
        I(  .XOR,    .C), // 0xA9
        I(  .XOR,    .D), // 0xAA
        I(  .XOR,    .E), // 0xAB
        I(  .XOR,    .H), // 0xAC
        I(  .XOR,    .L), // 0xAD
        I(  .XOR,    .Mem(.HL)), // 0xAE
        I(  .XOR,    .A), // 0xAF
        
        I(  .OR,    .B), // 0xB0
        I(  .OR,    .C), // 0xB1
        I(  .OR,    .D), // 0xB2
        I(  .OR,    .E), // 0xB3
        I(  .OR,    .H), // 0xB4
        I(  .OR,    .L), // 0xB5
        I(  .OR,    .Mem(.HL)), // 0xB6
        I(  .OR,    .A), // 0xB7
        I(  .CP,    .B), // 0xB8
        I(  .CP,    .C), // 0xB9
        I(  .CP,    .D), // 0xBA
        I(  .CP,    .E), // 0xBB
        I(  .CP,    .H), // 0xBC
        I(  .CP,    .L), // 0xBD
        I(  .CP,    .Mem(.HL)), // 0xBE
        I(  .CP,    .A), // 0xBF
        
        I(  .RET,    .NZ_flag), // 0xC0
        I(  .POP,    .BC), // 0xC1
        I(  .JP,    .NZ_flag,    .Immed16), // 0xC2
        I(  .JP,    .Immed16), // 0xC3
        I(  .CALL,    .NZ_flag,    .Immed16), // 0xC4
        I(  .PUSH,    .BC), // 0xC5
        I(  .ADD8,    .A,    .Immed8), // 0xC6
        I(  .RST,    .Number(0x00)), // 0xC7
        I(  .RET,    .Z_flag), // 0xC8
        I(  .RET), // 0xC9
        I(  .JP,    .Z_flag,    .Immed16), // 0xCA
        I(  .PREFIX), // 0xCB
        I(  .CALL,    .Z_flag,    .Immed16), // 0xCC
        I(  .CALL,    .Immed16), // 0xCD
        I(  .ADC,    .A,    .Immed8), // 0xCE
        I(  .RST,    .Number(0x08)), // 0xCF
        
        I(  .RET,    .NC_flag), // 0xD0
        I(  .POP,    .DE), // 0xD1
        I(  .JP,    .NC_flag,    .Immed16), // 0xD2
        I(  .UNIMPLEMENTED), // 0xD3
        I(  .CALL,    .NC_flag,    .Immed16), // 0xD4
        I(  .PUSH,    .DE), // 0xD5
        I(  .SUB,    .Immed8), // 0xD6
        I(  .RST,    .Number(0x10)), // 0xD7
        I(  .RET,    .C_flag), // 0xD8
        I(  .RETI), // 0xD9
        I(  .JP,    .C_flag,    .Immed16), // 0xDA
        I(  .UNIMPLEMENTED), // 0xDB
        I(  .CALL,    .C_flag,    .Immed16), // 0xDC
        I(  .UNIMPLEMENTED), // 0xDD
        I(  .SBC,    .A,    .Immed8), // 0xDE
        I(  .RST,    .Number(0x18)), // 0xDF
        
        I(  .LDH,    .Mem(.Immed8), .A), // 0xE0
        I(  .POP,    .HL), // 0xE1
        I(  .LD8,    .Mem(.C),    .A), // 0xE2
        I(  .UNIMPLEMENTED), // 0xE3
        I(  .UNIMPLEMENTED), // 0xE4
        I(  .PUSH,    .HL), // 0xE5
        I(  .AND,    .Immed8), // 0xE6
        I(  .RST,    .Number(0x20)), // 0xE7
        I(  .ADD16,    .SP,    .Immed8), // 0xE8
        I(  .JP, .Mem(.HL)), // 0xE9
        I(  .LD8,    .Mem(.Immed16),    .A), // 0xEA
        I(  .UNIMPLEMENTED), // 0xEB
        I(  .UNIMPLEMENTED), // 0xEC
        I(  .UNIMPLEMENTED), // 0xED
        I(  .XOR,    .Immed8), // 0xEE
        I(  .RST,    .Number(0x28)), // 0xEF
        
        I(  .LDH,    .A, .Mem(.Immed8)), // 0xF0
        I(  .POP,    .AF), // 0xF1
        I(  .LD8,    .A,    .Mem(.C)), // 0xF2
        I(  .DI), // 0xF3
        I(  .UNIMPLEMENTED), // 0xF4
        I(  .PUSH,    .AF), // 0xF5
        I(  .OR,    .Immed8), // 0xF6
        I(  .RST,    .Number(0x30)), // 0xF7
        I(  .LD16,    .HL,    .SPr8), // 0xF8
        I(  .LD16, .SP, .HL), // 0xF9
        I(  .LD8,    .A,    .Mem(.Immed16)), // 0xFA
        I(  .EI), // 0xFB
        I(  .UNIMPLEMENTED), // 0xFC
        I(  .UNIMPLEMENTED), // 0xFD
        I(  .CP,    .Immed8), // 0xFE
        I(  .RST,    .Number(0x38)), // 0xFF
    ]
    
    static let prefixTable: Array<()->()> = [
        I(  .RLC,    .B), // 0x<#code#>
        I(  .RLC,    .C), // 0x<#code#>
        I(  .RLC,    .D), // 0x<#code#>
        I(  .RLC,    .E), // 0x<#code#>
        I(  .RLC,    .H), // 0x<#code#>
        I(  .RLC,    .L), // 0x<#code#>
        I(  .RLC,    .Mem(.HL)), // 0x<#code#>
        I(  .RLC,    .A), // 0x<#code#>
        I(  .RRC,    .B), // 0x<#code#>
        I(  .RRC,    .C), // 0x<#code#>
        I(  .RRC,    .D), // 0x<#code#>
        I(  .RRC,    .E), // 0x<#code#>
        I(  .RRC,    .H), // 0x<#code#>
        I(  .RRC,    .L), // 0x<#code#>
        I(  .RRC,    .Mem(.HL)), // 0x<#code#>
        I(  .RRC,    .A), // 0x<#code#>
        
        I(  .RL,    .B), // 0x<#code#>
        I(  .RL,    .C), // 0x<#code#>
        I(  .RL,    .D), // 0x<#code#>
        I(  .RL,    .E), // 0x<#code#>
        I(  .RL,    .H), // 0x<#code#>
        I(  .RL,    .L), // 0x<#code#>
        I(  .RL,    .Mem(.HL)), // 0x<#code#>
        I(  .RL,    .A), // 0x<#code#>
        I(  .RR,    .B), // 0x<#code#>
        I(  .RR,    .C), // 0x<#code#>
        I(  .RR,    .D), // 0x<#code#>
        I(  .RR,    .E), // 0x<#code#>
        I(  .RR,    .H), // 0x<#code#>
        I(  .RR,    .L), // 0x<#code#>
        I(  .RR,    .Mem(.HL)), // 0x<#code#>
        I(  .RR,    .A), // 0x<#code#>
        
        I(  .SLA,    .B), // 0x<#code#>
        I(  .SLA,    .C), // 0x<#code#>
        I(  .SLA,    .D), // 0x<#code#>
        I(  .SLA,    .E), // 0x<#code#>
        I(  .SLA,    .H), // 0x<#code#>
        I(  .SLA,    .L), // 0x<#code#>
        I(  .SLA,    .Mem(.HL)), // 0x<#code#>
        I(  .SLA,    .A), // 0x<#code#>
        I(  .SRA,    .B), // 0x<#code#>
        I(  .SRA,    .C), // 0x<#code#>
        I(  .SRA,    .D), // 0x<#code#>
        I(  .SRA,    .E), // 0x<#code#>
        I(  .SRA,    .H), // 0x<#code#>
        I(  .SRA,    .L), // 0x<#code#>
        I(  .SRA,    .Mem(.HL)), // 0x<#code#>
        I(  .SRA,    .A), // 0x<#code#>
        
        I(  .SWAP,    .B), // 0x<#code#>
        I(  .SWAP,    .C), // 0x<#code#>
        I(  .SWAP,    .D), // 0x<#code#>
        I(  .SWAP,    .E), // 0x<#code#>
        I(  .SWAP,    .H), // 0x<#code#>
        I(  .SWAP,    .L), // 0x<#code#>
        I(  .SWAP,    .Mem(.HL)), // 0x<#code#>
        I(  .SWAP,    .A), // 0x<#code#>
        I(  .SRL,    .B), // 0x<#code#>
        I(  .SRL,    .C), // 0x<#code#>
        I(  .SRL,    .D), // 0x<#code#>
        I(  .SRL,    .E), // 0x<#code#>
        I(  .SRL,    .H), // 0x<#code#>
        I(  .SRL,    .L), // 0x<#code#>
        I(  .SRL,    .Mem(.HL)), // 0x<#code#>
        I(  .SRL,    .A), // 0x<#code#>
        
        I(  .BIT, .Number(0),    .B), // 0x<#code#>
        I(  .BIT, .Number(0),   .C), // 0x<#code#>
        I(  .BIT, .Number(0),   .D), // 0x<#code#>
        I(  .BIT, .Number(0),   .E), // 0x<#code#>
        I(  .BIT,  .Number(0),  .H), // 0x<#code#>
        I(  .BIT,  .Number(0),  .L), // 0x<#code#>
        I(  .BIT,  .Number(0),  .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(0),   .A), // 0x<#code#>
        I(  .BIT, .Number(1),   .B), // 0x<#code#>
        I(  .BIT, .Number(1),   .C), // 0x<#code#>
        I(  .BIT, .Number(1),   .D), // 0x<#code#>
        I(  .BIT, .Number(1),   .E), // 0x<#code#>
        I(  .BIT, .Number(1),   .H), // 0x<#code#>
        I(  .BIT, .Number(1),   .L), // 0x<#code#>
        I(  .BIT, .Number(1),   .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(1),   .A), // 0x<#code#>
        
        I(  .BIT, .Number(2),    .B), // 0x<#code#>
        I(  .BIT, .Number(2),   .C), // 0x<#code#>
        I(  .BIT, .Number(2),   .D), // 0x<#code#>
        I(  .BIT, .Number(2),   .E), // 0x<#code#>
        I(  .BIT,  .Number(2),  .H), // 0x<#code#>
        I(  .BIT,  .Number(2),  .L), // 0x<#code#>
        I(  .BIT,  .Number(2),  .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(2),   .A), // 0x<#code#>
        I(  .BIT, .Number(3),   .B), // 0x<#code#>
        I(  .BIT, .Number(3),   .C), // 0x<#code#>
        I(  .BIT, .Number(3),   .D), // 0x<#code#>
        I(  .BIT, .Number(3),   .E), // 0x<#code#>
        I(  .BIT, .Number(3),   .H), // 0x<#code#>
        I(  .BIT, .Number(3),   .L), // 0x<#code#>
        I(  .BIT, .Number(3),   .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(3),   .A), // 0x<#code#>
        
        I(  .BIT, .Number(4),    .B), // 0x<#code#>
        I(  .BIT, .Number(4),   .C), // 0x<#code#>
        I(  .BIT, .Number(4),   .D), // 0x<#code#>
        I(  .BIT, .Number(4),   .E), // 0x<#code#>
        I(  .BIT,  .Number(4),  .H), // 0x<#code#>
        I(  .BIT,  .Number(4),  .L), // 0x<#code#>
        I(  .BIT,  .Number(4),  .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(4),   .A), // 0x<#code#>
        I(  .BIT, .Number(5),   .B), // 0x<#code#>
        I(  .BIT, .Number(5),   .C), // 0x<#code#>
        I(  .BIT, .Number(5),   .D), // 0x<#code#>
        I(  .BIT, .Number(5),   .E), // 0x<#code#>
        I(  .BIT, .Number(5),   .H), // 0x<#code#>
        I(  .BIT, .Number(5),   .L), // 0x<#code#>
        I(  .BIT, .Number(5),   .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(5),   .A), // 0x<#code#>
        
        I(  .BIT, .Number(6),    .B), // 0x<#code#>
        I(  .BIT, .Number(6),   .C), // 0x<#code#>
        I(  .BIT, .Number(6),   .D), // 0x<#code#>
        I(  .BIT, .Number(6),   .E), // 0x<#code#>
        I(  .BIT,  .Number(6),  .H), // 0x<#code#>
        I(  .BIT,  .Number(6),  .L), // 0x<#code#>
        I(  .BIT,  .Number(6),  .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(6),   .A), // 0x<#code#>
        I(  .BIT, .Number(7),   .B), // 0x<#code#>
        I(  .BIT, .Number(7),   .C), // 0x<#code#>
        I(  .BIT, .Number(7),   .D), // 0x<#code#>
        I(  .BIT, .Number(7),   .E), // 0x<#code#>
        I(  .BIT, .Number(7),   .H), // 0x<#code#>
        I(  .BIT, .Number(7),   .L), // 0x<#code#>
        I(  .BIT, .Number(7),   .Mem(.HL)), // 0x<#code#>
        I(  .BIT, .Number(7),   .A), // 0x<#code#>
        
        I(  .RES, .Number(0),    .B), // 0x<#code#>
        I(  .RES, .Number(0),   .C), // 0x<#code#>
        I(  .RES, .Number(0),   .D), // 0x<#code#>
        I(  .RES, .Number(0),   .E), // 0x<#code#>
        I(  .RES,  .Number(0),  .H), // 0x<#code#>
        I(  .RES,  .Number(0),  .L), // 0x<#code#>
        I(  .RES,  .Number(0),  .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(0),   .A), // 0x<#code#>
        I(  .RES, .Number(1),   .B), // 0x<#code#>
        I(  .RES, .Number(1),   .C), // 0x<#code#>
        I(  .RES, .Number(1),   .D), // 0x<#code#>
        I(  .RES, .Number(1),   .E), // 0x<#code#>
        I(  .RES, .Number(1),   .H), // 0x<#code#>
        I(  .RES, .Number(1),   .L), // 0x<#code#>
        I(  .RES, .Number(1),   .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(1),   .A), // 0x<#code#>
        
        I(  .RES, .Number(2),    .B), // 0x<#code#>
        I(  .RES, .Number(2),   .C), // 0x<#code#>
        I(  .RES, .Number(2),   .D), // 0x<#code#>
        I(  .RES, .Number(2),   .E), // 0x<#code#>
        I(  .RES,  .Number(2),  .H), // 0x<#code#>
        I(  .RES,  .Number(2),  .L), // 0x<#code#>
        I(  .RES,  .Number(2),  .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(2),   .A), // 0x<#code#>
        I(  .RES, .Number(3),   .B), // 0x<#code#>
        I(  .RES, .Number(3),   .C), // 0x<#code#>
        I(  .RES, .Number(3),   .D), // 0x<#code#>
        I(  .RES, .Number(3),   .E), // 0x<#code#>
        I(  .RES, .Number(3),   .H), // 0x<#code#>
        I(  .RES, .Number(3),   .L), // 0x<#code#>
        I(  .RES, .Number(3),   .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(3),   .A), // 0x<#code#>
        
        I(  .RES, .Number(4),    .B), // 0x<#code#>
        I(  .RES, .Number(4),   .C), // 0x<#code#>
        I(  .RES, .Number(4),   .D), // 0x<#code#>
        I(  .RES, .Number(4),   .E), // 0x<#code#>
        I(  .RES,  .Number(4),  .H), // 0x<#code#>
        I(  .RES,  .Number(4),  .L), // 0x<#code#>
        I(  .RES,  .Number(4),  .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(4),   .A), // 0x<#code#>
        I(  .RES, .Number(5),   .B), // 0x<#code#>
        I(  .RES, .Number(5),   .C), // 0x<#code#>
        I(  .RES, .Number(5),   .D), // 0x<#code#>
        I(  .RES, .Number(5),   .E), // 0x<#code#>
        I(  .RES, .Number(5),   .H), // 0x<#code#>
        I(  .RES, .Number(5),   .L), // 0x<#code#>
        I(  .RES, .Number(5),   .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(5),   .A), // 0x<#code#>
        
        I(  .RES, .Number(6),    .B), // 0x<#code#>
        I(  .RES, .Number(6),   .C), // 0x<#code#>
        I(  .RES, .Number(6),   .D), // 0x<#code#>
        I(  .RES, .Number(6),   .E), // 0x<#code#>
        I(  .RES,  .Number(6),  .H), // 0x<#code#>
        I(  .RES,  .Number(6),  .L), // 0x<#code#>
        I(  .RES,  .Number(6),  .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(6),   .A), // 0x<#code#>
        I(  .RES, .Number(7),   .B), // 0x<#code#>
        I(  .RES, .Number(7),   .C), // 0x<#code#>
        I(  .RES, .Number(7),   .D), // 0x<#code#>
        I(  .RES, .Number(7),   .E), // 0x<#code#>
        I(  .RES, .Number(7),   .H), // 0x<#code#>
        I(  .RES, .Number(7),   .L), // 0x<#code#>
        I(  .RES, .Number(7),   .Mem(.HL)), // 0x<#code#>
        I(  .RES, .Number(7),   .A), // 0x<#code#>
        
        I(  .SET, .Number(0),    .B), // 0x<#code#>
        I(  .SET, .Number(0),   .C), // 0x<#code#>
        I(  .SET, .Number(0),   .D), // 0x<#code#>
        I(  .SET, .Number(0),   .E), // 0x<#code#>
        I(  .SET,  .Number(0),  .H), // 0x<#code#>
        I(  .SET,  .Number(0),  .L), // 0x<#code#>
        I(  .SET,  .Number(0),  .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(0),   .A), // 0x<#code#>
        I(  .SET, .Number(1),   .B), // 0x<#code#>
        I(  .SET, .Number(1),   .C), // 0x<#code#>
        I(  .SET, .Number(1),   .D), // 0x<#code#>
        I(  .SET, .Number(1),   .E), // 0x<#code#>
        I(  .SET, .Number(1),   .H), // 0x<#code#>
        I(  .SET, .Number(1),   .L), // 0x<#code#>
        I(  .SET, .Number(1),   .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(1),   .A), // 0x<#code#>
        
        I(  .SET, .Number(2),    .B), // 0x<#code#>
        I(  .SET, .Number(2),   .C), // 0x<#code#>
        I(  .SET, .Number(2),   .D), // 0x<#code#>
        I(  .SET, .Number(2),   .E), // 0x<#code#>
        I(  .SET,  .Number(2),  .H), // 0x<#code#>
        I(  .SET,  .Number(2),  .L), // 0x<#code#>
        I(  .SET,  .Number(2),  .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(2),   .A), // 0x<#code#>
        I(  .SET, .Number(3),   .B), // 0x<#code#>
        I(  .SET, .Number(3),   .C), // 0x<#code#>
        I(  .SET, .Number(3),   .D), // 0x<#code#>
        I(  .SET, .Number(3),   .E), // 0x<#code#>
        I(  .SET, .Number(3),   .H), // 0x<#code#>
        I(  .SET, .Number(3),   .L), // 0x<#code#>
        I(  .SET, .Number(3),   .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(3),   .A), // 0x<#code#>
        
        I(  .SET, .Number(4),    .B), // 0x<#code#>
        I(  .SET, .Number(4),   .C), // 0x<#code#>
        I(  .SET, .Number(4),   .D), // 0x<#code#>
        I(  .SET, .Number(4),   .E), // 0x<#code#>
        I(  .SET,  .Number(4),  .H), // 0x<#code#>
        I(  .SET,  .Number(4),  .L), // 0x<#code#>
        I(  .SET,  .Number(4),  .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(4),   .A), // 0x<#code#>
        I(  .SET, .Number(5),   .B), // 0x<#code#>
        I(  .SET, .Number(5),   .C), // 0x<#code#>
        I(  .SET, .Number(5),   .D), // 0x<#code#>
        I(  .SET, .Number(5),   .E), // 0x<#code#>
        I(  .SET, .Number(5),   .H), // 0x<#code#>
        I(  .SET, .Number(5),   .L), // 0x<#code#>
        I(  .SET, .Number(5),   .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(5),   .A), // 0x<#code#>
        
        I(  .SET, .Number(6),    .B), // 0x<#code#>
        I(  .SET, .Number(6),   .C), // 0x<#code#>
        I(  .SET, .Number(6),   .D), // 0x<#code#>
        I(  .SET, .Number(6),   .E), // 0x<#code#>
        I(  .SET,  .Number(6),  .H), // 0x<#code#>
        I(  .SET,  .Number(6),  .L), // 0x<#code#>
        I(  .SET,  .Number(6),  .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(6),   .A), // 0x<#code#>
        I(  .SET, .Number(7),   .B), // 0x<#code#>
        I(  .SET, .Number(7),   .C), // 0x<#code#>
        I(  .SET, .Number(7),   .D), // 0x<#code#>
        I(  .SET, .Number(7),   .E), // 0x<#code#>
        I(  .SET, .Number(7),   .H), // 0x<#code#>
        I(  .SET, .Number(7),   .L), // 0x<#code#>
        I(  .SET, .Number(7),   .Mem(.HL)), // 0x<#code#>
        I(  .SET, .Number(7),   .A), // 0x<#code#>
    ]
    



}

func I(operation: InstType, arg1: Argument?, arg2: Argument?) -> ()->() {
    let exec: (()->())?
    // set execution
    // return {
    //      debug code
    //      execution()
    // }
    switch operation {
    case .NOOP:
        exec = { CPU.prevInstCycles += 4 }
    case .STOP:
        exec = { CPU.prevInstCycles += 4 }
    case .LDH:
        fallthrough
    case .LD8:
        exec = generateBinOp8({$1}, arg1!, arg2!)
    case .LD16:
        exec = generateBinOp16({$1}, arg1!, arg2!)
    case .INC8:
        let adder: (UInt8) -> UInt8 = { b in
            CPU.registers.flags.halfCarry = b & 0b1111 == 0b1111 // will only be a half carry if this value is 0b1111
            CPU.registers.flags.subtract = false
            let c = b &+ 1
            CPU.registers.flags.zero = c == 0
            return c
        }
        exec = generateUnaryOp8(adder, arg1!)
    case .INC16:
        let adder: (UInt16) -> UInt16 = { b in
            return b &+ 1
        }
        exec = generateUnaryOp16(adder, arg1!)
    case .DEC8:
        let decrementer: (UInt8) -> UInt8 = { b in
            CPU.registers.flags.halfCarry = b & 0xF == 0
            CPU.registers.flags.subtract = true
            
            let c = b &- 1
            CPU.registers.flags.zero = c == 0
            return c
        }
        exec = generateUnaryOp8(decrementer, arg1!)
    case .DEC16:
        let decrementer: (UInt16) -> (UInt16) = { b in
            return b &+ UInt16(bitPattern: -1)
        }
        exec = generateUnaryOp16(decrementer, arg1!)
    case .ADD8:
        let adder: (UInt8, UInt8) -> UInt8 = { a, b in
            // it's not necessary to even convert to integer for arithmetic, the binary will be the same,
            // numeric answers only depend on whether we read it as 2's complement
            // as long as we use unsafe operation, we'll get the right answer
            let c = a.addingReportingOverflow(b)
            CPU.registers.flags.carry = c.overflow
            CPU.registers.flags.halfCarry = ((a & 0xF) + (b & 0xF)) & 0x10 > 0
            CPU.registers.flags.subtract = false
            CPU.registers.flags.zero = c.partialValue == 0
            return c.partialValue
        }
        exec = generateBinOp8(adder, arg1!, arg2!)
    case .ADD16:
        let adder: (UInt16, UInt16) -> UInt16 = { a, b in
            let c = a.addingReportingOverflow(b)
            CPU.registers.flags.carry = c.overflow
            // the below operation might be really slow
            CPU.registers.flags.halfCarry = (((a & 0x0FFF) + (b & 0x0FFF)) & 0xF000) > 0
            CPU.registers.flags.subtract = false
            return c.partialValue
        }
        exec = generateBinOp16(adder, arg1!, arg2!)
    case .ADC:
        let adder: (UInt8, UInt8) -> UInt8 = { a, b in
            let carry: UInt8 = CPU.registers.flags.carry ? 1 : 0
            let firstAddition = b.addingReportingOverflow(carry)
            let secondAddition = a.addingReportingOverflow(firstAddition.partialValue)
            CPU.registers.flags.carry = secondAddition.overflow || firstAddition.overflow
            CPU.registers.flags.halfCarry = ((a & 0xF) + (b & 0xF) + carry) & 0x10 > 0
            CPU.registers.flags.subtract = false
            CPU.registers.flags.zero = secondAddition.partialValue == 0
            return secondAddition.partialValue
        }
        exec = generateBinOp8(adder, arg1!, arg2!)
    case .SBC:
        let subtracter: (UInt8, UInt8) -> UInt8 = { a, b in
            let carry: UInt8 = CPU.registers.flags.carry ? 1 : 0
            let firstAddition = b.addingReportingOverflow(carry)
            let c = a.subtractingReportingOverflow(firstAddition.partialValue)
            CPU.registers.flags.carry = c.overflow || firstAddition.overflow
            CPU.registers.flags.halfCarry = ((a & 0xF) &- (b & 0xF) &- carry) & 0x10 > 0
            CPU.registers.flags.subtract = true
            CPU.registers.flags.zero = c.partialValue == 0
            return c.partialValue
        }
        exec = generateBinOp8(subtracter, arg1!, arg2!)
    case .SUB:
        let subtracter: (UInt8, UInt8) -> UInt8 = { a, b in
            let c = a.subtractingReportingOverflow(b)
            CPU.registers.flags.carry = c.overflow
            // is the minus operator correct for the half carry? it must be the same as addition but it converts the second op to 2's comp
            // which may not be what you want to happen
            // on second thought, subtracting might be right
            CPU.registers.flags.halfCarry = ((a & 0xF) &- (b & 0xF)) & 0x10 > 0
            CPU.registers.flags.subtract = true
            CPU.registers.flags.zero = c.partialValue == 0
            return c.partialValue
        }
        exec = generateBinOp8(subtracter, .A, arg1!) // even though SUB B is unary, it has the semantic of binary with A as the default
    case .AND:
        let and: (UInt8, UInt8) -> UInt8 = { a, b in
            let c = CPU.registers.A & b
            CPU.registers.flags.zero = c == 0
            CPU.registers.flags.halfCarry = true
            CPU.registers.flags.carry = false
            CPU.registers.flags.subtract = false
            return c
        }
        exec = generateBinOp8(and, .A, arg1!)
    case .OR:
        let or: (UInt8, UInt8) -> UInt8 = { a, b in
            let c = CPU.registers.A | b
            CPU.registers.flags.zero = c == 0
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.carry = false
            CPU.registers.flags.subtract = false
            return c
        }
        exec = generateBinOp8(or, .A, arg1!)
    case .XOR:
        let xor: (UInt8, UInt8) -> UInt8 = { a, b in
            let c = CPU.registers.A ^ b
            CPU.registers.flags.zero = c == 0
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.carry = false
            CPU.registers.flags.subtract = false
            return c
        }
        exec = generateBinOp8(xor, .A, arg1!)
    case .CP:
        let cp: (UInt8, UInt8) -> UInt8 = { a, b in
            let sub = a.subtractingReportingOverflow(b)
            let halfSub = (0x0F & a).subtractingReportingOverflow(0x0F & b)
            CPU.registers.flags.zero = sub.partialValue == 0
            CPU.registers.flags.halfCarry = halfSub.overflow
            CPU.registers.flags.carry = sub.overflow
            CPU.registers.flags.subtract = true
            return a
        }
        exec = generateBinOp8(cp, .A, arg1!)
    case .SWAP:
        let swap: (UInt8) -> UInt8 = { a in
            let l = a & 0x0F
            let h = a & 0xF0
            let b = (l << 4) | (h >> 4)
            CPU.registers.flags.zero = b == 0
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.carry = false
            CPU.registers.flags.subtract = false
            return b
        }
        exec = generateUnaryOp8(swap, arg1!)
    case .RLCA:
        exec = {
            let rotate = CPU.registers.A.rotatingLeftCircular()
            CPU.registers.A = rotate.result
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            CPU.registers.flags.zero = rotate.result == 0
            CPU.prevInstCycles = 4
        }
    case .RRCA:
        exec = {
            let rotate = CPU.registers.A.rotatingRightCircular()
            CPU.registers.A = rotate.result
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            CPU.registers.flags.zero = rotate.result == 0
            CPU.prevInstCycles = 4
        }
    case .RRA:
        exec = {
            let rotate = CPU.registers.A.rotatingRightThrough(carry: CPU.registers.flags.carry)
            CPU.registers.A = rotate.result
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            CPU.registers.flags.zero = rotate.result == 0
            CPU.prevInstCycles = 4
        }
    case .RLA:
        exec = {
            let rotate = CPU.registers.A.rotatingLeftThrough(carry: CPU.registers.flags.carry)
            CPU.registers.A = rotate.result
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            CPU.registers.flags.zero = rotate.result == 0
            CPU.prevInstCycles = 4
        }
    case .RL:
        let rotateLeft: (UInt8) -> UInt8 = { a in
            let rotate = a.rotatingLeftThrough(carry: CPU.registers.flags.carry)
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.zero = rotate.result == 0
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            return rotate.result
        }
        exec = generateUnaryOp8(rotateLeft, arg1!)
    case .RLC:
        let rotateLeft: (UInt8) -> UInt8 = { a in
            let rotate = a.rotatingLeftCircular()
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.zero = rotate.result == 0
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            return rotate.result
        }
        exec = generateUnaryOp8(rotateLeft, arg1!)
    case .RR:
        let rotateRight: (UInt8) -> UInt8 = { a in
            let rotate = a.rotatingRightThrough(carry: CPU.registers.flags.carry)
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.zero = rotate.result == 0
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            return rotate.result
        }
        exec = generateUnaryOp8(rotateRight, arg1!)
    case .RRC:
        let rotateRightCarry: (UInt8) -> UInt8 = { a in
            let rotate = a.rotatingRightCircular()
            CPU.registers.flags.carry = rotate.carry
            CPU.registers.flags.zero = rotate.result == 0
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.subtract = false
            return rotate.result
        }
        exec = generateUnaryOp8(rotateRightCarry, arg1!)
    case .SRL:
        let shiftRight: (UInt8) -> UInt8 = {
            let a = $0 >> 1
            CPU.registers.flags.carry = ($0 & 0x01) > 0
            CPU.registers.flags.zero = a == 0x0
            CPU.registers.flags.subtract = false
            CPU.registers.flags.halfCarry = false
            return a
        }
        exec = generateUnaryOp8(shiftRight, arg1!)
    case .SLA:
        let shiftLeft: (UInt8) -> UInt8 = {
            let a = $0 << 1
            CPU.registers.flags.carry = ($0 & 0x80) > 0
            CPU.registers.flags.zero = a == 0
            CPU.registers.flags.subtract = false
            CPU.registers.flags.halfCarry = false
            return a
        }
        exec = generateUnaryOp8(shiftLeft, arg1!)
    case .SRA:
        let shiftRight: (UInt8) -> UInt8 = {
            // TODO: Fix this so that msb is maintained
            let bit7 = 0x80 & $0
            let a = ($0 >> 1) | bit7
            CPU.registers.flags.carry = ($0 & 0x01) > 0
            CPU.registers.flags.zero = a == 0
            CPU.registers.flags.subtract = false
            CPU.registers.flags.halfCarry = false
            return a
        }
        exec = generateUnaryOp8(shiftRight, arg1!)
    case .SCF:
        exec = {
            CPU.registers.flags.carry = true
            CPU.registers.flags.subtract = false
            CPU.registers.flags.halfCarry = false
            CPU.prevInstCycles = 4
        }
    case .CCF:
        exec = {
            CPU.registers.flags.carry = !CPU.registers.flags.carry
            CPU.registers.flags.subtract = false
            CPU.registers.flags.halfCarry = false
            CPU.prevInstCycles = 4
        }
    case .POP:
        let pop: (UInt16) -> UInt16 = { _ in
            let l = CPU.mmu[CPU.registers.SP]
            CPU.registers.SP += 1
            let h = CPU.mmu[CPU.registers.SP]
            CPU.registers.SP += 1
            CPU.prevInstCycles = 12
            return (UInt16(h) << 8) | UInt16(l)
        }
        exec = generateUnaryOp16(pop, arg1!)
    case .PUSH:
        let push: (UInt16) -> UInt16 = { a in
            CPU.registers.SP -= 1
            CPU.mmu[CPU.registers.SP] = UInt8((a & 0xFF00) >> 8)
            CPU.registers.SP -= 1
            CPU.mmu[CPU.registers.SP] = UInt8((a & 0x00FF))
            CPU.prevInstCycles = 12
            return a
        }
        
        exec = generateUnaryOp16(push, arg1!)
    case .CPL:
        exec = {
            CPU.registers.flags.subtract = true
            CPU.registers.flags.halfCarry = true
            CPU.registers.A = ~CPU.registers.A
            CPU.prevInstCycles = 4
        }
    case .RST:
        guard case .Number(let addr)? = arg1 else { fatalError() }
        exec = {
            pushPC()
            CPU.registers.PC = UInt16(addr)
            CPU.prevInstCycles = 16
        }
    case .CALL:
        if case .Immed16? = arg1 {
            exec = {
                let i = CPU.readWordImmediate()
                /*if i == 0x36e0 && CPU.registers.A > 0 {
                    print("\(CPU.registers.PC) \(CPU.registers.SP)")
                }*/
                pushPC()
                CPU.registers.PC = i
                CPU.prevInstCycles = 24
            }
        } else {
            let condition: (()->(Bool))
            switch arg1! {
            case .Z_flag:
                condition = { CPU.registers.flags.zero }
            case .NZ_flag:
                condition = { !CPU.registers.flags.zero }
            case .C_flag:
                condition = { CPU.registers.flags.carry }
            case .NC_flag:
                condition = { !CPU.registers.flags.carry }
            default:
                condition = { fatalError() }
            }
            
            exec = {
                let i = CPU.readWordImmediate()
                if condition() {
                    pushPC()
                    CPU.registers.PC = i
                    CPU.prevInstCycles = 24
                } else {
                    CPU.prevInstCycles = 12
                }
            }
        }
    case .RET:
        if let flag = arg1 {
            let condition: (()->(Bool))
            switch flag {
            case .Z_flag:
                condition = { CPU.registers.flags.zero }
            case .NZ_flag:
                condition = { !CPU.registers.flags.zero }
            case .C_flag:
                condition = { CPU.registers.flags.carry }
            case .NC_flag:
                condition = { !CPU.registers.flags.carry }
            default:
                condition = { fatalError() }
            }
            
            exec = {
                if condition() {
                    popPC()
                    CPU.prevInstCycles = 20
                } else {
                    CPU.prevInstCycles = 8
                }
            }
        } else {
            exec = popPC
            CPU.prevInstCycles = 16
        }
    case .RETI:
        exec = {
            popPC()
            CPU.interruptEnabled = true
            CPU.prevInstCycles = 16
        }
    case .JP:
        fallthrough
    case .JR:
        
        exec = generateJump(operation, arg1!, arg2)
    case .PREFIX:
        exec = {
            let opcode = CPU.mmu[CPU.registers.PC]
            CPU.registers.PC += 1
            CPU.prefixTable[opcode]()
            CPU.prevInstCycles += 4
        }
        
    case .BIT:
        guard case .Number(let a)? = arg1 else { fatalError() }
        let bit: (UInt8) -> (UInt8) = { b in
            let bitSelect: UInt8 = 0x01 << a
            CPU.registers.flags.zero = (b & bitSelect) == 0
            CPU.registers.flags.halfCarry = true
            CPU.registers.flags.subtract = false
            return b
        }
        exec = generateUnaryOp8(bit, arg2!)
    case .RES:
        guard case .Number(let a)? = arg1 else { fatalError() }
        let res: (UInt8) -> (UInt8) = { b in
            let bitSelect: UInt8 = (0x01 << a) ^ 0xFF
            return b & bitSelect
        }
        exec = generateUnaryOp8(res, arg2!)
    case .SET:
        guard case .Number(let a)? = arg1 else { fatalError() }
        let set: (UInt8) -> (UInt8) = { b in
            let bitSelect: UInt8 = (0x01 << a)
            return b | bitSelect
        }
        exec = generateUnaryOp8(set, arg2!)
    case .DI:
        return {
            CPU.interruptEnabled = false
            CPU.prevInstCycles = 4
        }
    case .EI:
        exec = {
            CPU.interruptEnabled = true
            CPU.prevInstCycles = 4
        }
    case .HALT:
        exec = {
            CPU.isHalted = true
            CPU.prevInstCycles = 4
        }
    case .DAA:
        exec = {
            let a = CPU.registers.A
            //let l = a & 0x0F
            //let h = (a & 0xF0) >> 4
            var num: UInt16 = UInt16(a)
            // this algorithm was lifted from MAME
            if !CPU.registers.flags.subtract {
                if CPU.registers.flags.halfCarry || (num & 0x0F) > 9 {
                    num += 6
                }
                if CPU.registers.flags.carry || num > 0x9F {
                    num += 0x60
                }
            } else {
                if CPU.registers.flags.halfCarry {
                    num = (num &- 6) & 0xFF
                    /*if !CPU.registers.flags.carry {
                        num &= 0xFF
                    }*/
                }
                if CPU.registers.flags.carry {
                    num = num &- 0x60
                }
            }
            
            
            
            CPU.registers.flags.halfCarry = false
            CPU.registers.flags.carry = (num & 0x100) > 0
            CPU.registers.flags.zero = num == 0
            CPU.registers.A = UInt8(num & 0xFF)
            
            /*if CPU.registers.flags.subtract {
                
                if CPU.registers.flags.carry {
                    
                    if CPU.registers.flags.halfCarry {
                        if (0x6...0xF).contains(h) && (0x6...0xF).contains(l) {
                            num = 0x9A
                        }
                    } else {
                        if (0x7...0xF).contains(h) && (0x0...0x9).contains(l) {
                            num = 0xA0
                        }
                    }
                    
                } else {
                    
                    if CPU.registers.flags.halfCarry {
                        if (0x0...0x8).contains(h) && (0x6...0xF).contains(l) {
                            // CY = 0 H = 1
                            num = 0xFA
                        }
                    } else {
                        // CY = 0 H = 0
                        if (0x0...0x9).contains(h) && (0x0...0x9).contains(l) {
                            num = 0x00
                        }
                    }
                    
                }
                
            } else {
                
                if CPU.registers.flags.carry {
                    // CY = 1
                    if CPU.registers.flags.halfCarry {
                        // CY = 1 H = 1
                        if (0x0...0x3).contains(h) && (0x0...0x3).contains(l) {
                            num = 0x66
                        }
                    } else {
                        // CY = 1 H = 0
                        if (0x0...0x2).contains(h) {
                            if (0x0...0x9).contains(l) {
                                num = 0x60
                            } else {
                                num = 0x66
                            }
                        }
                    }
                } else {
                    // CY = 0
                    if CPU.registers.flags.halfCarry {
                        // CY = 0 H = 1
                        if (0x0...0x9).contains(h) {
                            if (0x0...0x3).contains(l) {
                                num = 0x06
                            }
                        } else {
                            if (0x0...0x3).contains(l) {
                                num = 0x66
                            }
                        }
                        
                    } else {
                        // CY = 0 H = 0
                        if (0x0...0x9).contains(h) {
                            if (0x0...0x9).contains(l) {
                                num = 0x00
                            } else {
                                num = 0x06
                            }
                        } else {
                            if (0x0...0x9).contains(l) {
                                num = 0x60
                            } else {
                                num = 0x66
                            }
                        }
                        
                    }
                }

                CPU.registers.flags.carry = (0x60 & num) > 0
                
            }
            
            CPU.registers.A = CPU.registers.A &+ num*/
        
        }
    default:
        exec = {
            //fatalError("\(CPU.registers.PC)")
            fatalError("Unimplemented operation! \(operation) \(String(describing: arg1)) \(String(describing: arg2))")
        }
    }
    
    if CPU.debugMode {
        return {
            CPU.prevInstruction = "\(String(describing: operation)) \(arg1 != nil ? String(describing: arg1!) : "") \(arg2 != nil ? String(describing: arg2!) : "")"
            (exec ?? { fatalError() })()
        }
    } else {
        return exec ?? { fatalError() }
    }
    
}

func popPC() {
    let l = CPU.mmu[CPU.registers.SP]
    CPU.registers.SP += 1
    let h = CPU.mmu[CPU.registers.SP]
    CPU.registers.SP += 1
    CPU.registers.PC = (UInt16(h) << 8) | UInt16(l)
}

func pushPC() {
    CPU.registers.SP -= 1
    CPU.mmu[CPU.registers.SP] = UInt8((CPU.registers.PC & 0xFF00) >> 8)
    CPU.registers.SP -= 1
    CPU.mmu[CPU.registers.SP] = UInt8((CPU.registers.PC & 0x00FF))
}

func generateJump(_ operation: InstType, _ arg1: Argument, _ arg2: Argument?) -> ()->() {
    
    let condition: (()->(Bool))?

    switch arg1 {
    case .NZ_flag:
        condition = { !CPU.registers.flags.zero }
    case .C_flag:
        condition = { CPU.registers.flags.carry }
    case .Z_flag:
        condition = { CPU.registers.flags.zero }
    case .NC_flag:
        condition = { !CPU.registers.flags.carry }
    default:
        condition = nil
    }
    
    if let condition = condition {
        if case .JP = operation {
            return {
                if condition() {
                    CPU.prevInstCycles = 16
                    CPU.registers.PC = CPU.readWordImmediate()
                } else {
                    CPU.registers.PC += 2
                    CPU.prevInstCycles = 12
                }
            }
        } else {
            return {
                if condition() {
                    let a = CPU.readByteImmediate()
                    let neg = a & 0x80 > 0
                    let result = CPU.registers.PC &+ (UInt16(a) | (neg ? 0xFF00 : 0x0000))
                    CPU.registers.PC = result
                    CPU.prevInstCycles = 12
                } else {
                    CPU.registers.PC += 1
                    CPU.prevInstCycles = 8
                }
            }
        }
    } else {
        if case .JP = operation {
            
            if case .Mem(.HL) = arg1 {
                return {
                    CPU.prevInstCycles = 4
                    CPU.registers.PC = CPU.registers.HL
                }
            } else {
                return {
                    CPU.prevInstCycles = 16
                    CPU.registers.PC = CPU.readWordImmediate()
                }
            }
            
        } else {
            return {
                let a = CPU.readByteImmediate()
                let neg = a & 0x80 > 0
                let result = CPU.registers.PC &+ (UInt16(a) | (neg ? 0xFF00 : 0x0000))
                CPU.registers.PC = result
                CPU.prevInstCycles = 12
            }
        }
    }

    
}

func generateUnaryOp8(_ operation: @escaping (UInt8) -> (UInt8), _ dest: Argument) -> (()->()) {
    
    var clocks: UInt = 4
    
    switch dest {
    case .A:
        return {
            CPU.registers.A = operation(CPU.registers.A)
            CPU.prevInstCycles += clocks
        }
    case .B:
        return {
            CPU.registers.B = operation(CPU.registers.B)
            CPU.prevInstCycles += clocks
        }
    case .C:
        return {
            CPU.registers.C = operation(CPU.registers.C)
            CPU.prevInstCycles += clocks
        }
    case .D:
        return {
            CPU.registers.D = operation(CPU.registers.D)
            CPU.prevInstCycles += clocks
        }
    case .E:
        return {
            CPU.registers.E = operation(CPU.registers.E)
            CPU.prevInstCycles += clocks
        }
    case .H:
        return {
            CPU.registers.H = operation(CPU.registers.H)
            CPU.prevInstCycles += clocks
        }
    case .Mem(.HL):
        clocks += 8
        return {
            let addr = CPU.registers.HL
            CPU.mmu[addr] = operation(CPU.mmu[addr])
            CPU.prevInstCycles += clocks
        }
    case .L:
        return {
            CPU.registers.L = operation(CPU.registers.L)
            CPU.prevInstCycles += clocks
        }
    default:
        fatalError()
    }

}

func generateUnaryOp16(_ operation: @escaping (UInt16) -> (UInt16), _ dest: Argument) -> (()->()) {
    
    switch dest {
    case .BC:
        return {
            CPU.prevInstCycles = 8
            CPU.registers.BC = operation(CPU.registers.BC)
        }
    case .DE:
        return {
            CPU.prevInstCycles = 8
            CPU.registers.DE = operation(CPU.registers.DE)
        }
    case .HL:
        return {
            CPU.prevInstCycles = 8
            CPU.registers.HL = operation(CPU.registers.HL)
        }
    case .SP:
        return {
            CPU.prevInstCycles = 8
            CPU.registers.SP = operation(CPU.registers.SP)
        }
    case .AF:
        return {
            CPU.prevInstCycles = 8
            CPU.registers.AF = operation(CPU.registers.AF)
        }
        
    default:
        return { fatalError() }
    }

}

func generateBinOp8(_ operation :@escaping (UInt8, UInt8)->(UInt8),_ dest: Argument,_ source: Argument) -> (() -> ()) {
    
    var reader: () -> (UInt8)
    var clocks: UInt = 4
    
    switch source {
    case .A:
        reader = { return CPU.registers.A }
    case .B:
        reader = { return CPU.registers.B }
    case .C:
        reader = { return CPU.registers.C }
    case .D:
        reader = { return CPU.registers.D }
    case .E:
        reader = { return CPU.registers.E }
    case .H:
        reader = { return CPU.registers.H }
    case .L:
        reader = { return CPU.registers.L }
    case .Immed8:
        reader = CPU.readByteImmediate
    case .Mem(let target):
        clocks += 4
        switch target {
        case .HL:
            reader = { return CPU.mmu[CPU.registers.HL] }
        case .BC:
            reader = { return CPU.mmu[CPU.registers.BC] }
        case .DE:
            reader = { return CPU.mmu[CPU.registers.DE] }
        case .HLi:
            reader = {
                let a = CPU.mmu[CPU.registers.HL]
                CPU.registers.HL += 1
                return a
            }
        case .HLd:
            reader = {
                let a = CPU.mmu[CPU.registers.HL]
                CPU.registers.HL -= 1
                return a
            }
            /*
             LD A,(C) has alternative mnemonic LD A,($FF00+C)
             LD C,(A) has alternative mnemonic LD ($FF00+C),A
             LDH A,(a8) has alternative mnemonic LD A,($FF00+a8)
             LDH (a8),A has alternative mnemonic LD ($FF00+a8),A
             */
        case .Immed8:
            clocks += 4
            reader = {
                let a = CPU.readByteImmediate()
                return CPU.mmu[UInt16(a) | 0xFF00]
            }
        case .Immed16:
            clocks += 8
            reader = {
                let a = CPU.readWordImmediate()
                return CPU.mmu[a]
            }
        case .C:
            reader = {
                let a = CPU.registers.C
                return CPU.mmu[UInt16(a) | 0xFF00]
            }
        case .A:
            reader = {
                let a = CPU.registers.A
                return CPU.mmu[UInt16(a) | 0xFF00]
            }
        default:
            reader = { fatalError() }
        }
    default:
        reader = { fatalError() }
    }
    
    switch dest {
    case .A:
        return {
            CPU.prevInstCycles = clocks
            CPU.registers.A = operation(CPU.registers.A, reader())
        }
    case .B:
        return {
            CPU.prevInstCycles = clocks
            CPU.registers.B = operation(CPU.registers.B, reader())
        }
    case .C:
        return {
            CPU.prevInstCycles = clocks
            CPU.registers.C = operation(CPU.registers.C, reader())
        }
    case .D:
        return {
            CPU.prevInstCycles = clocks
            CPU.registers.D = operation(CPU.registers.D, reader())
        }
    case .E:
        return {
            CPU.prevInstCycles = clocks
            CPU.registers.E = operation(CPU.registers.E, reader())
        }
    case .H:
        return {
            CPU.prevInstCycles = clocks
            CPU.registers.H = operation(CPU.registers.H, reader())
        }
    case .L:
        return {
            CPU.prevInstCycles = clocks
            CPU.registers.L = operation(CPU.registers.L, reader())
        }
    
        
    case .Mem(let target):
        clocks += 4
        switch target {
        case .C:
            return {
                CPU.prevInstCycles = clocks
                CPU.mmu[UInt16(CPU.registers.C) | 0xFF00] = operation(0, reader())
            }
        case .BC:
            return {
                // it's probably unnecessary to execute operation because destination indirection is only done using the LD operation
                // pass 0 because there's no arithmetic between the two operands
                CPU.prevInstCycles = clocks
                CPU.mmu[CPU.registers.BC] = operation(0, reader())
            }
        case .DE:
            return {
                CPU.prevInstCycles = clocks
                CPU.mmu[CPU.registers.DE] = operation(0, reader())
            }
        case .HL:
            return {
                CPU.prevInstCycles = clocks
                CPU.mmu[CPU.registers.HL] = operation(0, reader())
            }
        case .HLi:
            return {
                CPU.prevInstCycles = clocks
                CPU.mmu[CPU.registers.HL] = operation(0, reader())
                CPU.registers.HL += 1
            }
        case .HLd:
            return {
                CPU.prevInstCycles = clocks
                CPU.mmu[CPU.registers.HL] = operation(0, reader())
                CPU.registers.HL -= 1
            }
        case .Immed8:
            return {
                CPU.prevInstCycles = clocks
                CPU.mmu[0xFF00 | UInt16(CPU.readByteImmediate())] = operation(0, reader())
            }
        case .Immed16:
            return {
                CPU.prevInstCycles = clocks
                let a = UInt16(CPU.readWordImmediate())
                CPU.mmu[a] = operation(0, reader())
            }
        default:
            return { fatalError() }
        }
    default:
        return { fatalError() }
    }

}

func generateBinOp16(_ operation :@escaping (UInt16, UInt16)->(UInt16),_ dest: Argument,_ source: Argument) -> (() -> ()) {
    
    var reader: () -> (UInt16)
    var clocks: UInt = 4
    switch source {
    case .BC:
        clocks += 4
        reader = { return CPU.registers.BC }
    case .DE:
        clocks += 4
        reader = { return CPU.registers.DE }
    case .SP:
        clocks += 4
        reader = { return CPU.registers.SP }

    case .Immed16:
        clocks += 8
        reader = CPU.readWordImmediate
    case .HL:
        clocks += 4
        reader = { return CPU.registers.HL }
    case .SPr8:
        clocks += 12
        reader = {
            let immed = CPU.readByteImmediate()
            //let signedImmed = Int(Int8(bitPattern: immed))
            //let result = CPU.registers.SP
            let neg = (0x80 & immed) > 0 // use neg for sign extending
            let signExt = UInt16(immed) | (neg ? 0xFF00 : 0)
            let res = CPU.registers.SP.addingReportingOverflow(signExt)
            CPU.registers.flags.carry = res.overflow
            CPU.registers.flags.halfCarry = (((CPU.registers.SP & 0x0FFF) + (signExt & 0x0FFF)) & 0xF000) > 0
            CPU.registers.flags.zero = false
            CPU.registers.flags.subtract = false
            return res.partialValue
        }
    case .Immed8:
        clocks += 12
        reader = {
            let immed = CPU.readByteImmediate()
            let signExtended = UInt16(bitPattern: Int16(Int8(bitPattern: immed)))
            //let neg = (0x80 & immed) > 0 // use neg for sign extending
            //let signExt = UInt16(immed) | (neg ? 0xFF00 : 0)
            return signExtended
        }
    default:
        reader = { fatalError("Invalid") }
    }
    
    switch dest {
    
    case .BC:
        return {
            CPU.prevInstCycles += clocks
            CPU.registers.BC = operation(CPU.registers.BC, reader())
        }
    case .DE:
        return {
            CPU.prevInstCycles += clocks
            CPU.registers.DE = operation(CPU.registers.DE, reader())
        }
    case .SP:
        return {
            CPU.prevInstCycles += clocks
            CPU.registers.SP = operation(CPU.registers.SP, reader())
        }
    case .HL:
        return {
            CPU.prevInstCycles += clocks
            CPU.registers.HL = operation(CPU.registers.HL, reader())
        }
    case .Mem(let target):
        clocks += 4
        switch target {
        case .Immed16:
            return {
                // it seems this scenario only is used to store SP in memory
                CPU.prevInstCycles += clocks
                // this reader is definitely the stack pointer
                let word = reader()
                let lower = UInt8(word & 0x00FF)
                let upper = UInt8((word >> 8) & 0x00FF)
                let addr = CPU.readWordImmediate()
                CPU.mmu[addr] = lower
                CPU.mmu[addr + 1] = upper
            }
        default:
            return { fatalError() }
        }
    default:
        return { fatalError("Invalid destination for opcode!") }
    }
    
}

func I(_ operation: InstType,_ dest: Argument?,_ source: Argument?) -> ()->() {
    return I(operation: operation, arg1: dest, arg2: source)
}

func I(_ unaryOp: InstType, _ dest: Argument) -> ()->() {
    return I(unaryOp, dest, nil)
}

func I(_ operation: InstType) -> ()->() {
    return I(operation, nil, nil)
}

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

