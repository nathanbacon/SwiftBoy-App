//
//  MMU.swift
//  GB
//
//  Created by Nathan Gelman on 5/21/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

class MMU {
    
    static var mmu: MMU = MMU()
    
    enum CartridgeType {
        case ROM_only
        case MBC1
        case MBC3
    }
    
    var cartridge: Cartridge? {
        didSet {
            if cartridge != nil {
                bank0 = cartridge!.ROMbanks[0]
                externRAM = cartridge!.getRAMBank(at: 0)
            }
        }
    }
    
    static var WRAMbanks: Array<Data> = Array<Data>(repeating: Data(repeating:0, count: 0x1000), count: 8)
    static var activeWRAMbank = withUnsafeMutablePointer(to: &WRAMbanks[0], {$0})
    
    static var VRAMbanks = Array<Data>(repeating: Data(repeating:0, count: 0x2000), count: 2)
    static var activeVRAMbank = withUnsafeMutablePointer(to: &VRAMbanks[0], {$0})
    
    var cartridge_type: CartridgeType = .ROM_only
    
    var bios_mode = false
    
    var bios: Data = try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "bios", ofType: "gb")!))
    var rom: Data?
    
    var bank0: Data = Data(repeating: 0, count: 0x4000)
    var bank1: Data = Data(repeating: 0, count: 0x4000)
    var vram: Data = Data(repeating: 0, count: 0x2000) // this should be removed, vram should be part of the GPU
    var wram: Data = Data(repeating: 0, count: 0x2000)
    var externRAM: UnsafeMutablePointer<Data>?
    var iram: Data = Data(repeating: 0, count: 0x80)
    var interruptEnable: Bool = false
    
    subscript(index: UInt16) -> UInt8 {
        get {
            switch(index >> 12) {
            case 0:
                if(bios_mode) {
                    guard (index < 0x100) else { assert(false) }
                    return bios[index]
                }
                fallthrough
            case 0x1...0x3:
                return bank0[index]
            case 0x4...0x7:
                return bank1[index]
                
            case 0x8...0x9:
                return MMU.activeVRAMbank.pointee[index & 0x1FFF]
            case 0xA...0xB:
                // TODO: implement external RAM
                return externRAM!.pointee[Int(index)]
            case 0xC:
                return MMU.WRAMbanks[0][index & 0x0FFF]
            case 0xD:
                return MMU.activeWRAMbank.pointee[index & 0x0FFF]
                
            case 0xE...0xF:
                if (index < 0xFE00) {
                    return wram[index & 0x1FFF]
                } else {
                    switch(index) {
                    case 0xFE00..<0xFF00:
                        // TODO: this holds sprite information
                        break
                    case 0xFF00:
                        // input/output ports
                        break
                    case 0xFF01:
                        // serial cable communications p 28
                        break
                    case 0xFF02:
                        break
                    case 0xFF05...0xFF07:
                        // timer registers p 25
                        break
                
                    case 0xFF0F:
                        // interrupt flags p 26
                        break
                    case 0xFF40:
                        // LCDC register
                        break
                    case 0xFF4D:
                        // cpu speed switching
                        break
                    case 0xFF56:
                        // IR communication
                        break
                    case 0xFF80..<0xFFFF:
                        return iram[index & 0x007F]
                    case 0xFFFF:
                        return interruptEnable ? 1 : 0
                    default:
                        return 0
                    }
                }
            default:
                // this should never execute
                return 1
            }
        }
        
        set {
            
            switch(index >> 12) {
            case 0..<2:
                // this is a rom bank so we should never write to it
                bank0[index] = newValue
            case 2...3:
                bank1 = cartridge!.getROMBank(at: newValue)
            case 4...5:
                externRAM = cartridge!.getRAMBank(at: newValue & 0x000F)
            case 6...7:
                // bottom of p 216 in gbc manual
                break
            case 8...9:
                MMU.activeVRAMbank.pointee[index & 0x1FFF] = newValue
            case 10...11:
                // TODO: implement external RAM
                print("unimplemented")
            case 12...13:
                wram[index & 0x1FFF] = newValue
            case 14...15:
                if (index < 0xFE00) {
                    wram[index & 0x1FFF] = newValue
                } else {
                    switch(index) {
                    case 0xFE00..<0xFF00:
                        // TODO: this holds sprite information
                        fallthrough
                    case 0xFF70:
                        let bank = newValue == 0 ? 1 : newValue
                        MMU.activeWRAMbank = withUnsafeMutablePointer(to: &MMU.WRAMbanks[bank], {$0})
                    case 0xFF4D:
                        // cpu speed switching
                        break
                    case 0xFF4F:
                        // vram bank switching
                        MMU.activeVRAMbank = withUnsafeMutablePointer(to: &MMU.VRAMbanks[newValue], {$0})
                        break
                    case 0xFF80..<0xFFFF:
                        iram[index & 0x007F] = newValue
                    case 0xFFFF:
                        interruptEnable = (newValue == 1)
                    default:
                        // this should never execute
                        break
                    }
                }
            default:
                // this should never execute
                break
            }

        }
    }
    
    func fetchWord(at index: UInt16) -> UInt16 {
        switch(index & 0xF000) {
        case 0:
            if(bios_mode) {
                guard (index < 0x100) else { assert(false) }
                return bios.withUnsafeBytes { return $0[Int(index)] }
            } else if(index == 0x100) {
                bios_mode = false
            }
            fallthrough
        case 0x1...0x3:
            return bank0.withUnsafeBytes { return $0[Int(index)] }
        case 0x4...0x7:
            // this only supports ROM ONLY
            // to support MBC1 for tetris we need switchable banks or something of that nature
            // also, can only determine how data should be stored at emulation time
            switch cartridge_type {
            case .ROM_only:
                return bank1.withUnsafeBytes { return $0[Int(index & 0x3FFF)] }
            default:
                return 0
            }
            
        case 0x8...0x9:
            return vram.withUnsafeBytes { return $0[Int(index & 0x1FFF)] }
        case 0xA...0xB:
            // TODO: implement external RAM
            return 0
        case 0xC...0xD:
            return wram.withUnsafeBytes { return $0[Int(index & 0x1FFF)] }
        case 0xE...0xF:
            if (index < 0xFE00) {
                return wram.withUnsafeBytes { return $0[Int(index & 0x1FFF)] }
            } else {
                switch(index) {
                case 0xFE00..<0xFF00:
                    // TODO: this holds sprite information
                    fallthrough
                case 0xFF00..<0xFF80:
                    // TODO: this must interface with memory mapped IO somehow
                    fallthrough
                case 0xFF80..<0xFFFF:
                    return iram.withUnsafeBytes { return $0[Int(index & 0x007F)] }
                case 0xFFFF:
                    return interruptEnable ? 1 : 0
                default:
                    // this should never execute
                    return 0
                }
            }
        default:
            // this should never execute
            return 1
        }
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


