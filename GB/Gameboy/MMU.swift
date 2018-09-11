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
    
    var WRAMbanks: Array<Data> = Array<Data>(repeating: Data(repeating:0, count: 0x1000), count: 8)
    //var activeWRAMbank = withUnsafeMutablePointer(to: &WRAMbanks[0], {$0})
    var WRAMbankIndex = 1
    
    var cartridge_type: CartridgeType = .ROM_only
    
    var bios_mode = false
    
    //var bios: Data = try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "bios", ofType: "gb")!))
    var rom: Data?
    
    var bank0: Data = Data(repeating: 0, count: 0x4000)
    var bank1: Data = Data(repeating: 0, count: 0x4000)
    
    var iram: Data = Data(repeating: 0, count: 0x80)
    
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
                return WRAMbanks[0][index & 0x0FFF]
            case 0xD:
                //return MMU.activeWRAMbank.pointee[index & 0x0FFF]
                return WRAMbanks[WRAMbankIndex][index & 0x0FFF]
            case 0xE:
                fatalError("\(index)")
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
                case 0xFEA0..<0xFF00:
                    fatalError("\(index)")
                case 0xFF00:
                    // input/output ports
                    // the 4 lsb of this return value should signal that nothing is pressed
                    
                    return InputViewController.inputController.register
                    //return MMU.FF00 == 0x30 ? 0xFE : 0xFF
                case 0xFF01:
                    // serial cable communications p 28
                    return 0
                case 0xFF02:
                    // serial cable communications p 28
                    // 0x7E was the value of this register in the emulator
                    return 0x7E
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
                case 0xFF4A:
                    return GPU.windowY
                case 0xFF4B:
                    return GPU.windowX
                case 0xFF4D:
                    // cpu speed switching p 34
                    //CPU.speedDivider =
                    return 0
                case 0xFF4F:
                    // vram bank switching getter
                    return UInt8(GPU.VRAMbankIndex)
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
                return 0
            }
            
            fatalError("\(index)")
        }
        
        set {
            
            /*if index == 0xd60c {
                print("\(newValue) \(MMU.WRAMbankIndex) \(CPU.registers.PC)")
            }*/
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
                /*if index == 0xC103 {
                    print("C103 \(CPU.registers.PC)")
                }*/
                WRAMbanks[0][index & 0x0FFF] = newValue
            case 0xD:
                //wram[index & 0x1FFF] = newValue
                WRAMbanks[WRAMbankIndex][index & 0x0FFF] = newValue
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
                            GPU.OAM[spriteNum].y = newValue
                        case 1:
                            GPU.OAM[spriteNum].x = newValue
                        case 2:
                            GPU.OAM[spriteNum].tileNum = newValue
                        case 3:
                            GPU.OAM[spriteNum].attributes = newValue
                        default:
                            fatalError("\(index)")
                        }

                    case 0xFF00:
                        InputViewController.inputController.register = newValue
                    case 0xFF01:
                        // serial transfer data
                        // page 28
                        print("\(Character(Unicode.Scalar(newValue))) \(newValue)")
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
                    case 0xFF10...0xFF3F:
                        GameBoy.apu.write_register(UInt32(CPU.cyclesSinceFrame), UInt32(index), UInt32(newValue))
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
                            GPU.OAM[spriteNum].y = y
                            GPU.OAM[spriteNum].x = x
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
                    case 0xFF4A:
                        GPU.windowY = newValue
                    case 0xFF4B:
                        GPU.windowX = newValue
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
                        let bank = newValue == 0 ? 1 : newValue & 0x07
                        //MMU.activeWRAMbank = withUnsafeMutablePointer(to: &MMU.WRAMbanks[bank], {$0})
                        WRAMbankIndex = Int(bank)
                    case 0xFF80..<0xFFFF:
                        /*if index == 0xFFAF {
                            print(CPU.registers.PC)
                        }*/
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




