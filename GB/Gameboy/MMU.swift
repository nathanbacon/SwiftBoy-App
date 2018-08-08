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
                cartridge!.getRAMBank(at: 0)
            }
        }
    }
    
    static var WRAMbanks: Array<Data> = Array<Data>(repeating: Data(repeating:0, count: 0x1000), count: 8)
    static var activeWRAMbank = withUnsafeMutablePointer(to: &WRAMbanks[0], {$0})
    static var WRAMbankIndex = 1
    
    //static var VRAMbanks = Array<Data>(repeating: Data(repeating:0, count: 0x2000), count: 2)
    //static var activeVRAMbank = withUnsafeMutablePointer(to: &VRAMbanks[0], {$0})
    
    var cartridge_type: CartridgeType = .ROM_only
    
    var bios_mode = false
    
    //var bios: Data = try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "bios", ofType: "gb")!))
    var rom: Data?
    
    var bank0: Data = Data(repeating: 0, count: 0x4000)
    var bank1: Data = Data(repeating: 0, count: 0x4000)
    
    //var externRAM: UnsafeMutablePointer<Data>?
    var iram: Data = Data(repeating: 0, count: 0x80)

    // MARK: FLAGS/REGISTERS
    
    static var DMAinProgress: Bool = false
    
    static var HDMA5: UInt8 {
        set {
            //let addr = HDMA5 & 0x7F
        }
        
        get {
            return DMAinProgress ? 0x00 : 0x80
        }
    }
    

    static var FF00: UInt8 = 0
    
    subscript(index: UInt16) -> UInt8 {
        get {
            switch(index >> 12) {
            case 0x0:
                /*if(bios_mode) {
                    guard (index < 0x100) else { fatalError() }
                    return bios[index]
                }*/
                fallthrough
            case 0x1:
                fallthrough
            case 0x2:
                fallthrough
            case 0x3:
                return bank0[index]
            case 0x4:
                fallthrough
            case 0x5:
                fallthrough
            case 0x6:
                fallthrough
            case 0x7:
                return bank1[index & 0x3FFF]
                
            case 0x8:
                fallthrough
            case 0x9:
                return GPU.gpu[index & 0x1FFF]
            case 0xA:
                fallthrough
            case 0xB:
                // This method doesn't seem to work, just 
                return cartridge!.readRam(at: index & 0x1FFF)
            case 0xC:
                return MMU.WRAMbanks[0][index & 0x0FFF]
            case 0xD:
                //return MMU.activeWRAMbank.pointee[index & 0x0FFF]
                return MMU.WRAMbanks[MMU.WRAMbankIndex][index & 0x0FFF]
            case 0xE:
                fatalError()
            case 0xF:
                
                switch(index) {
                case 0xFE00..<0xFEA0:
                    // TODO: this holds sprite information
                    let spriteNum = index / 4
                    switch index % 4 {
                    case 0:
                        return GPU.OAM[spriteNum].y + 16
                    case 1:
                        return GPU.OAM[spriteNum].x + 8
                    case 2:
                        return GPU.OAM[spriteNum].tileNum
                    case 3:
                        return GPU.OAM[spriteNum].attributes
                    default:
                        fatalError()
                    }

                case 0xFF00:
                    // input/output ports
                    // the 4 lsb of this return value should signal that nothing is pressed
                    return 0xFF
                    //return MMU.FF00 == 0x30 ? 0xFE : 0xFF
                case 0xFF01:
                    // serial cable communications p 28
                    break
                case 0xFF02:
                    // serial cable communications p 28
                    break
                case 0xFF04:
                    // divider p 24
                    return Timer.divider
                case 0xFF05:
                    // timer registers p 25
                    return Timer.counter
                case 0xFF06:
                    return Timer.modulo
                case 0xFF07:
                    return Timer.controllerRegister
                case 0xFF0F:
                    // interrupt flags p 26
                    return CPU.Interrupt.IF
                case 0xFF40:
                    // LCDC register
                    // page 54
                    return GPU.LCDC.value
                case 0xFF41:
                    // LCDC status flag
                    // page 55
                    return GPU.STAT.value
                case 0xFF42:
                    // scroll Y
                    return GPU.scrollY

                case 0xFF43:
                    // scroll X
                    return GPU.scrollX

                case 0xFF44:
                    // LCDC y-coordinate, read only
                    return GPU.currentLineRegister
                
                case 0xFF45:
                    return GPU.LYC
                case 0xFF4D:
                    // cpu speed switching p 34
                    break
                case 0xFF4F:
                    // vram bank switching getter
                    break
                case 0xFF55:
                    // Transfer start and number of bytes to transfer
                    break
                case 0xFF56:
                    // IR communication
                    break
                case 0xFF68:
                    // specifices a bg write
                    break
                case 0xFF69:
                    // bg write data
                    break
                case 0xFF6A:
                    // specifies the obj write data
                    break
                case 0xFF6B:
                    // obj write data
                    break
                case 0xFF70:
                    // working ram bank switching page 34
                    break
                case 0xFF80..<0xFFFF:
                    return iram[index & 0x007F]
                case 0xFFFF:
                    return CPU.Interrupt.IE
                default:
                    return 0
                }
                
            default:
                // this should never execute
                return 1
            }
            
            fatalError()
        }
        
        set {
            
            switch(index >> 12) {
            case 0:
                fallthrough
            case 1:
                // this is a rom bank so we should never write to it
                bank0[index] = newValue
            case 2:
                fallthrough
            case 3:
                bank1 = cartridge!.getROMBank(at: newValue & 0x3F)
            case 4:
                fallthrough
            case 5:
                cartridge!.getRAMBank(at: newValue & 0x0003)
            case 6:
                fallthrough
            case 7:
                // bottom of p 216 in gbc manual
                break
            case 8:
                fallthrough
            case 9:
                GPU.gpu[index & 0x1FFF] = newValue
                break
            case 0xA:
                fallthrough
            case 0xB:
                cartridge!.writeRam(at: index & 0x1FFF, newValue: newValue)
            case 0xC:
                MMU.WRAMbanks[0][index & 0x0FFF] = newValue
            case 0xD:
                //wram[index & 0x1FFF] = newValue
                MMU.WRAMbanks[MMU.WRAMbankIndex][index & 0x0FFF] = newValue
                break
            case 0xE:
                fallthrough
            case 0xF:
                if (index < 0xFE00) {
                    //wram[index & 0x1FFF] = newValue
                    break
                } else {
                    switch(index) {
                    case 0xFE00..<0xFF00:
                        // TODO: this holds sprite information
                        let spriteNum = index / 4
                        switch index % 4 {
                        case 0:
                            GPU.OAM[spriteNum].y = newValue - 16
                        case 1:
                            GPU.OAM[spriteNum].x = newValue - 8
                        case 2:
                            GPU.OAM[spriteNum].tileNum = newValue
                        case 3:
                            GPU.OAM[spriteNum].attributes = newValue
                        default:
                            fatalError()
                        }

                    case 0xFF00:
                        MMU.FF00 = newValue
                    case 0xFF01:
                        // serial transfer data
                        // page 28
                        break
                    case 0xFF02:
                        // serial transfer control register
                        // p28
                        break
                    case 0xFF04:
                        // divider p 24
                        Timer.divider = 0
                    case 0xFF05:
                        // timer registers p 25
                        Timer.counter = newValue
                        break
                    case 0xFF06:
                        Timer.modulo = newValue
                    case 0xFF07:
                        Timer.controllerRegister = newValue
                    case 0xFF0F:
                        // interrupt request
                        CPU.Interrupt.IF = newValue
                    case 0xFF40:
                        // LCDC register
                        // page 54
                        GPU.LCDC.value = newValue
                        break
                    case 0xFF41:
                        // LCDC status flag
                        // page 55
                        GPU.STAT.value = newValue
                    case 0xFF42:
                        // scroll Y
                        GPU.scrollY = newValue

                    case 0xFF43:
                        // scroll X
                        GPU.scrollX = newValue
                    case 0xFF44:
                        //GPU.currentLineRegister = newValue
                        break
                    case 0xFF45:
                        GPU.LYC = newValue
                    case 0xFF46:
                        // DMA transfer and starting address page 62
                        let startAddr = UInt16(newValue) << 8
                        for (spriteNum, addr) in stride(from: startAddr, to: startAddr + 40 * 4, by: 4).enumerated() {
                            let y = self[addr]
                            let x = self[addr + 1]
                            let tileNum = self[addr+2]
                            let attrib = self[addr+3]
                            GPU.OAM[spriteNum].y = y &- 16
                            GPU.OAM[spriteNum].x = x &- 8
                            GPU.OAM[spriteNum].tileNum = tileNum
                            GPU.OAM[spriteNum].attributes = attrib
                        }
                    case 0xFF47:
                        //pallete selector p 57 of dmg manual
                        fallthrough
                    case 0xFF48:
                        fallthrough
                    case 0xFF49:
                        break
                    case 0xFF55:
                        // Transfer start and number of bytes to transfer
                        
                        break
                    case 0xFF4D:
                        // cpu speed switching
                        break
                    case 0xFF4F:
                        // vram bank switching
                        // todo let the GPU do bank switching, these should be private
                        //GPU.activeVRAMbank = withUnsafeMutablePointer(to: &GPU.VRAMbanks[newValue], {$0})
                        GPU.VRAMbankIndex = Int(newValue)
                        break
                    case 0xFF68:
                        // specifices a bg write
                        break
                    case 0xFF69:
                        // bg write data
                        break
                    case 0xFF6A:
                        // specifies the obj write data
                        break
                    case 0xFF6B:
                        // obj write data
                        break
                    case 0xFF70:
                        let bank = newValue == 0 ? 1 : newValue
                        //MMU.activeWRAMbank = withUnsafeMutablePointer(to: &MMU.WRAMbanks[bank], {$0})
                        MMU.WRAMbankIndex = Int(bank)
                    case 0xFF80..<0xFFFF:
                        iram[index & 0x007F] = newValue
                    case 0xFFFF:
                        CPU.Interrupt.IE = newValue
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


