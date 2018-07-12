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
    }
    
    var cartridge_type: CartridgeType = .ROM_only
    
    func openRom(fileName: String) {
        guard let rom = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "gb")!)) else { assert(false) }
        
        bank0 = rom.subdata(in: Range<Data.Index>(0..<0x4000))
        
        // determine the cartridge type based on the value at this address
        switch rom[0x147] {
        case 0:
            cartridge_type = .ROM_only
            bank1 = rom.subdata(in: Range<Data.Index>(0x4000..<0x8000))
        default:
            // this can be expanded later to support other cartridge types but only one case is needed for tetris
            cartridge_type = .ROM_only
            bank1 = Data(repeating: 0, count: 0x4000)
        }
    }
    
    var bios_mode = true
    
    var bios: Data = try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "bios", ofType: "gb")!))
    var rom: Data?
    
    var bank0: Data = Data(repeating: 0, count: 0x4000)
    var bank1: Data = Data(repeating: 0, count: 0x4000)
    var vram: Data = Data(repeating: 0, count: 0x2000) // this should be removed, vram should be part of the GPU
    var wram: Data = Data(repeating: 0, count: 0x2000)
    var iram: Data = Data(repeating: 0, count: 0x80)
    var interruptEnable: Bool = false
    
    subscript(index: UInt16) -> UInt8 {
        get {
            switch(index & 0xF000) {
            case 0:
                if(bios_mode) {
                    guard (index < 0x100) else { assert(false) }
                    return bios[index]
                }
                fallthrough
            case 0x1...0x3:
                return bank0[index]
            case 0x4...0x7:
                // this only supports ROM ONLY
                // to support MBC1 for tetris we need switchable banks or something of that nature
                // also, can only determine how data should be stored at emulation time
                switch cartridge_type {
                case .ROM_only:
                    return bank1[index & 0x3FFF]
                default:
                    return 0
                }
                
            case 0x8...0x9:
                return vram[index & 0x1FFF]
            case 0xA...0xB:
                // TODO: implement external RAM
                return 0
            case 0xC...0xD:
                return wram[index & 0x1FFF]
            case 0xE...0xF:
                if (index < 0xFE00) {
                    return wram[index & 0x1FFF]
                } else {
                    switch(index) {
                    case 0xFE00..<0xFF00:
                        // TODO: this holds sprite information
                        fallthrough
                    case 0xFF00..<0xFF80:
                        // TODO: this must interface with memory mapped IO somehow
                        fallthrough
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
            
            switch(index & 0xF000) {
            case 0...3:
                bank0[index] = newValue
            case 4...7:
                // this only supports ROM ONLY
                // to support MBC1 for tetris we need switchable banks or something of that nature
                // also, can only determine how data should be stored at emulation time
                switch cartridge_type {
                case .ROM_only:
                    bank1[index & 0x3FFF] = newValue
                default:
                    break
                }
                
            case 8...9:
                vram[index & 0x1FFF] = newValue
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
                    case 0xFF00..<0xFF80:
                        // TODO: this must interface with memory mapped IO somehow
                        fallthrough
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


