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
    
    static var clockCounter: UInt = 0
    
    private init() {
        
    }
    
    static let basicTable: Array<()->()> = [
        I(operation: .NOOP, dest: nil, source: nil), // 0x00 -> NOP
        I(operation: .LD16, dest: .BC, source: .Immed16), // 0x01 -> LD BC,d16
        I(operation: .LD8, dest: .Mem(.BC), source: .A), // 0x02 -> LD (BC), A
        I(operation: .INC16, dest: .BC, source: nil), // 0x03 -> INC BC
        I(operation: .INC8, dest: .B, source: nil), // 0x04 -> INC B
        I(operation: .DEC8, dest: .B, source: nil), // 0x05 -> DEC B
        I(operation: .LD8, dest: .B, source: .Immed8), // 0x06 -> LD B, d8
        I(operation: .RLCA, dest: nil, source: nil), // 0x07 -> RLCA
        I(operation: .LD16, dest: .Mem(.Immed16), source: .SP), // 0x08 -> LD (a16), SP
        I(operation: .ADD16, dest: .HL, source: .BC), // 0x09 -> ADD HL, BC
        I(operation: .LD16, dest: .A, source: .Mem(.BC)), // 0x0A -> LD A, (BC)
        I(operation: .DEC16, dest: .BC, source: nil), // 0x0B -> DEC BC
        I(operation: .INC8, dest: .C, source: nil), // 0x0C -> INC C
        I(operation: .DEC8, dest: .C, source: nil), // 0x0D -> DEC C
        I(operation: .LD8, dest: .C, source: .Immed8), // 0x0E -> LD C, d8
        I(operation:  .RRCA, dest: nil, source: nil), // 0x0F -> RRCA
        
        I(operation:  .STOP, dest: nil, source: nil), // 0x10 -> STOP
        I(operation:  .LD16, dest: .DE, source: .Immed16), // 0x11 -> LD DE, d16
        I(operation:  .LD8, dest: .Mem(.DE), source: .A), // 0x12 -> LD (DE), A
        I(operation:  .INC16, dest: .DE, source: nil), // 0x13 -> INC DE
        I(operation:  .INC8, dest: .D, source: nil), // 0x14 -> INC D
        I(operation:  .DEC8, dest: .D, source: nil), // 0x15 -> DEC D
        I(operation:  .LD8, dest: .D, source: .Immed8), // 0x16 -> LD D
        I(operation:  .RLA, dest: nil, source: nil), // 0x17 -> RLA
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
        I(  .LD8,    .Mem(.HLd),    .Immed8), // 0x32 -> LD (HL-), A
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
        
        I(  .LDH,    .Mem(.Immed8), .A), // 0xC0
        I(  .POP,    .HL), // 0x<#code#>
        I(  .LD8,    .Mem(.C),    .A), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .PUSH,    .HL), // 0x<#code#>
        I(  .AND,    .Immed8), // 0x<#code#>
        I(  .RST,    .Number(0x20)), // 0x<#code#>
        I(  .ADD8,    .SP,    .Immed8), // 0x<#code#>
        I(  .JP, .Mem(.HL)), // 0x<#code#>
        I(  .LD8,    .Mem(.Immed16),    .A), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .XOR,    .Immed8), // 0x<#code#>
        I(  .RST,    .Number(0x28)), // 0x<#code#>
        
        I(  .LDH,    .A, .Mem(.Immed8)), // 0xC0
        I(  .POP,    .AF), // 0x<#code#>
        I(  .LD8,    .A,    .Mem(.C)), // 0x<#code#>
        I(  .DI), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .PUSH,    .AF), // 0x<#code#>
        I(  .OR,    .Immed8), // 0x<#code#>
        I(  .RST,    .Number(0x30)), // 0x<#code#>
        I(  .LD16,    .HL,    .SPr8), // 0x<#code#>
        I(  .LD16, .SP, .HL), // 0x<#code#>
        I(  .LD8,    .A,    .Mem(.Immed16)), // 0x<#code#>
        I(  .EI), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .UNIMPLEMENTED), // 0x<#code#>
        I(  .CP,    .Immed8), // 0x<#code#>
        I(  .RST,    .Number(0x38)), // 0x<#code#>
    ]
    
    static let secondaryTable: Array<()->()> = [
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
    
    static func fetchInstruction(index: UInt16) -> ()->() {
        
        let opcode = CPU.mmu[CPU.registers.PC]
        return CPU.basicTable[opcode]
        
    }
    
    static func readByteImmediate() -> UInt8 {
        let immed = CPU.mmu[CPU.registers.PC]
        CPU.registers.PC += 1
        return immed
    }
    
    static func readWordImmediate() -> UInt16 {
        let immed = CPU.mmu.fetchWord(at: CPU.registers.PC)
        CPU.registers.PC += 2
        return immed
    }


}

func I(operation: InstType, dest: Argument?, source: Argument?) -> ()->() {
    //var execution: ()->()
    switch operation {
    case .NOOP:
        return {}
    case .STOP:
        return { fatalError() }
    case .LDH:
        fallthrough
    case .LD8:
        return generateBinOp8({$1}, dest!, source!)
    case .LD16:
        return generateBinOp16({$1}, dest!, source!)
    case .INC8:
        let adder: (UInt8) -> UInt8 = { b in
            Registers.Flags.halfCarry = b & 0b1111 == 0b1111 // will only be a half carry if this value is 0b1111
            Registers.Flags.subtract = false
            let c = Int8(bitPattern: b) &+ 1
            Registers.Flags.zero = c == 0
            return UInt8(bitPattern: c)
        }
        return generateUnaryOp8(adder, dest!)
    case .INC16:
        let adder: (UInt16) -> UInt16 = { b in
            let c = Int16(bitPattern: b)
            return UInt16(bitPattern: c &+ 1)
        }
        return generateUnaryOp16(adder, dest!)
    case .DEC8:
        let decrementer: (UInt8) -> UInt8 = { b in
            Registers.Flags.halfCarry = b & 0b0000 == 0b0000
            Registers.Flags.subtract = true
            
            let c = Int8(bitPattern: b) &- 1
            Registers.Flags.zero = c == 0
            return UInt8(bitPattern: c)
        }
        return generateUnaryOp8(decrementer, dest!)
    case .DEC16:
        let decrementer: (UInt16) -> (UInt16) = { b in
            let c = Int16(bitPattern: b)
            return UInt16(bitPattern: c &- 1)
        }
        return generateUnaryOp16(decrementer, dest!)
    case .ADD8:
        let adder: (UInt8, UInt8) -> UInt8 = { a, b in
            let x = Int8(bitPattern: a)
            let y = Int8(bitPattern: b)
            let c = x.addingReportingOverflow(y)
            Registers.Flags.carry = c.overflow
            Registers.Flags.halfCarry = ((x & 0xF) + (y & 0xF)) & 0x10 > 0
            Registers.Flags.subtract = false
            Registers.Flags.zero = c.partialValue == 0
            return UInt8(bitPattern: c.partialValue)
        }
        return generateBinOp8(adder, dest!, source!)
    case .ADD16:
        let adder: (UInt16, UInt16) -> UInt16 = { a, b in
            let f = Int16(bitPattern: a)
            let s = Int16(bitPattern: b)
            let c = f.addingReportingOverflow(s)
            Registers.Flags.carry = c.overflow
            // the below operation might be really slow
            Registers.Flags.halfCarry = Int8(bitPattern: UInt8(a & 0x00FF)).addingReportingOverflow(Int8(bitPattern: UInt8(b & 0x00FF))).overflow
            Registers.Flags.subtract = false
            return UInt16(bitPattern: c.partialValue)
        }
        return generateBinOp16(adder, dest!, source!)
    case .PREFIX:
        return { fatalError() }
    default:
        return { fatalError("Unimplemented operation!") }
    }
    
}

func generateUnaryOp8(_ operation: @escaping (UInt8) -> (UInt8), _ dest: Argument) -> (()->()) {
    
    var clocks: UInt = 4
    
    switch dest {
    case .A:
        return {
            CPU.registers.A = operation(CPU.registers.A)
        }
    case .B:
        return {
            CPU.registers.B = operation(CPU.registers.B)
        }
    case .C:
        return {
            CPU.registers.C = operation(CPU.registers.C)
        }
    case .D:
        return {
            CPU.registers.D = operation(CPU.registers.D)
        }
    case .E:
        return {
            CPU.registers.E = operation(CPU.registers.E)
        }
    case .H:
        return {
            CPU.registers.H = operation(CPU.registers.H)
        }
    case .Mem(.HL):
        return {
            let addr = CPU.registers.HL
            CPU.mmu[addr] = operation(CPU.mmu[addr])
        }
    default:
        fatalError()
    }
    
    return {}
}

func generateUnaryOp16(_ operation: @escaping (UInt16) -> (UInt16), _ dest: Argument) -> (()->()) {
    
    switch dest {
    case .BC:
        return {
            CPU.registers.BC = operation(CPU.registers.BC)
        }
    case .DE:
        return {
            CPU.registers.DE = operation(CPU.registers.DE)
        }
    case .HL:
        return {
            CPU.registers.HL = operation(CPU.registers.HL)
        }
    case .SP:
        return {
            CPU.registers.SP = operation(CPU.registers.SP)
        }
        
    default:
        return {}
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
            CPU.clockCounter += clocks
            CPU.registers.A = operation(CPU.registers.A, reader())
        }
    case .B:
        return {
            CPU.clockCounter += clocks
            CPU.registers.B = operation(CPU.registers.B, reader())
        }
    case .C:
        return {
            CPU.clockCounter += clocks
            CPU.registers.C = operation(CPU.registers.C, reader())
        }
    case .D:
        return {
            CPU.clockCounter += clocks
            CPU.registers.D = operation(CPU.registers.D, reader())
        }
    case .E:
        return {
            CPU.clockCounter += clocks
            CPU.registers.A = operation(CPU.registers.E, reader())
        }
    case .H:
        return {
            CPU.clockCounter += clocks
            CPU.registers.H = operation(CPU.registers.H, reader())
        }
    case .L:
        return {
            CPU.clockCounter += clocks
            CPU.registers.L = operation(CPU.registers.L, reader())
        }
    case .Immed8:
        reader = CPU.readByteImmediate
        
    case .Mem(let target):
        clocks += 4
        switch target {
        case .C:
            return {
                CPU.clockCounter += clocks
                CPU.mmu[UInt16(CPU.registers.C) | 0xFF00] = operation(0, reader())
            }
        case .BC:
            return {
                // it's probably unnecessary to execute operation because destination indirection is only done using the LD operation
                // pass 0 because there's no arithmetic between the two operands
                CPU.clockCounter += clocks
                CPU.mmu[CPU.registers.BC] = operation(0, reader())
            }
        case .DE:
            return {
                CPU.clockCounter += clocks
                CPU.mmu[CPU.registers.DE] = operation(0, reader())
            }
        case .HLi:
            return {
                CPU.clockCounter += clocks
                CPU.mmu[CPU.registers.HL] = operation(0, reader())
                CPU.registers.HL += 1
            }
        case .HLd:
            return {
                CPU.clockCounter += clocks
                CPU.mmu[CPU.registers.HL] = operation(0, reader())
                CPU.registers.HL -= 1
            }
        default:
            return { fatalError() }
        }
    default:
        return { fatalError() }
    }
    
    return {}
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
        reader = CPU.readWordImmediate

    default:
        reader = { fatalError("Invalid") }
    }
    
    switch dest {
    
    case .BC:
        return {
            CPU.clockCounter += clocks
            CPU.registers.BC = operation(CPU.registers.BC, reader())
        }
    case .DE:
        return {
            CPU.clockCounter += clocks
            CPU.registers.DE = operation(CPU.registers.DE, reader())
        }
    case .Mem(let target):
        clocks += 4
        switch target {
        case .Immed16:
            return {
                // it seems this scenario only is used to store SP in memory
                CPU.clockCounter += clocks
                // this reader is definitely the stack pointer
                let word = reader()
                let lower = UInt8(word & 0x00FF)
                let upper = UInt8(word & 0xFF00)
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
    return I(operation: operation, dest: dest, source: source)
}

func I(_ unaryOp: InstType, _ dest: Argument) -> ()->() {
    return I(unaryOp, dest, nil)
}

func I(_ operation: InstType) -> ()->() {
    return I(operation, nil, nil)
}



