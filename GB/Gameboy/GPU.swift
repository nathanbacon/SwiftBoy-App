//
//  GPU.swift
//  GB
//
//  Created by Nathan Gelman on 7/19/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation
import GLKit

struct GPU {
    
    static var gpu = GPU()
    
    static var screenData = Array<(red: UInt8, green: UInt8, blue: UInt8)>(repeating: (0,0,0), count: 160*144)
    
    static var VRAMbanks = Array<Data>(repeating: Data(repeating:0, count: 0x2000), count: 2)
    static var activeVRAMbank = withUnsafeMutablePointer(to: &VRAMbanks[0], {$0})
    static var vram: Data {
        return activeVRAMbank.pointee
    }
    
    static var OAM = Data(repeating: 0, count: 0xA0)
    
    subscript(index: UInt16) -> UInt8 {
        get {
            return GPU.activeVRAMbank.pointee[index]
        }
        set {
            GPU.activeVRAMbank.pointee[index] = newValue
        }
    }
    
    struct Pallete {
        private struct Color {
            var red: UInt8 = 0
            var green: UInt8 = 0
            var blue: UInt8 = 0
        }
        
        private var color0 = Color()
        private var color1 = Color()
        private var color2 = Color()
        private var color3 = Color()
        
        func setLow(data: UInt8) {
            
        }
        func setHigh(data: UInt8) {
            
        }
    }
    
    enum LCDMode: UInt8 {
        case HBlank = 0
        case VBlank = 1
        case searchSprite = 2
        case dataTransfer = 3
    }
    
    struct LCDC {
        static var LCDenabled = false { // bit 7
            didSet {
                if !LCDenabled {
                    STAT.mode = .VBlank
                }
            }
        }
        static private(set) var windowTileMapSelect = false // bit 6 Window Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
        static private(set) var windowDisplayToggle = false // bit 5 Window Display Enable (0=Off, 1=On)
        static private(set) var BGWindowTileSelect = false // bit 4 BG & Window Tile Data Select (0=8800-97FF, 1=8000-8FFF)
        static private(set) var BGTileMapSelect = false // bit 3 BG Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
        static private(set) var spriteSize = false // bit 2  OBJ (Sprite) Size (0=8x8, 1=8x16)
        static private(set) var spriteDisplay = false // bit 1 OBJ (Sprite) Display Enable (0=Off, 1=On)
        static private(set) var BGDisplay = false // bit 0 BG Display (for CGB see below) (0=Off, 1=On)
        static var value: UInt8 {
            get {
                return UInt8(LCDenabled ? 0x80 : 0) +
                    (windowTileMapSelect ? 0x40 : 0) +
                    (windowDisplayToggle ? 0x20 : 0) +
                    (BGWindowTileSelect ? 0x10 : 0) +
                    (BGTileMapSelect ? 0x08 : 0) +
                    (spriteSize ? 0x04 : 0) +
                    (spriteDisplay ? 0x02 : 0) +
                    (BGDisplay ? 0x01 : 0)
            }
            set {
                LCDenabled = 0x80 & newValue > 0
                windowTileMapSelect = 0x40 & newValue > 0
                windowDisplayToggle = 0x20 & newValue > 0
                BGWindowTileSelect = 0x10 & newValue > 0
                BGTileMapSelect = 0x08 & newValue > 0
                spriteSize = 0x04 & newValue > 0
                spriteDisplay = 0x02 & newValue > 0
                BGDisplay = 0x01 & newValue > 0
            }
        }
    }
    
    struct STAT {
        static var IntCoincidence = false // bit 6
        static var IntSearchSprite = false // 5
        static var IntVBlank = false // 4
        static var IntHBlank = false // 3
        static var coincidenceFlag: Bool { // 2
            get {
                return GPU.currentLineRegister == GPU.LYC
            }
        }
        static var mode: LCDMode = .HBlank { // 1-0
            didSet {
                if oldValue != mode {
                    switch mode {
                    case .HBlank:
                        // request interrupt
                        if IntHBlank {
                            CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.LCD)
                        }
                        break
                    case .VBlank:
                        if IntVBlank {
                            CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.LCD)

                        }
                        break
                    case .searchSprite:
                        if IntSearchSprite {
                            CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.LCD)
                        }
                        break
                    case .dataTransfer:
                        break
                    }
                }
            }
        }
        static var value: UInt8 {
            get {
                return mode.rawValue +
                (coincidenceFlag ? 0x04 : 0) +
                (IntHBlank ? 0x08 : 0) +
                (IntVBlank ? 0x10 : 0) +
                (IntSearchSprite ? 0x20 : 0) +
                (IntCoincidence ? 0x40 : 0)
            }
            set {
                //mode = LCDMode(rawValue: newValue & 0x03) ?? .HBlank
                IntHBlank = newValue & 0x08 > 0
                IntVBlank = newValue & 0x10 > 0
                IntSearchSprite = newValue & 0x20 > 0
                IntCoincidence = newValue & 0x40 > 0
                
            }
        }
    }
    
    static var LYC: UInt8 = 0 // 0xFF45
    static var scrollX: UInt8 = 0
    static var scrollY: UInt8 = 0
    static var windowX: UInt8 = 0
    static var windowY: UInt8 = 0
    
    static private var scanLineCycles: UInt = 0
    static private var currentLine: UInt8 = 0
    static var currentLineRegister: UInt8 { // 0xFF44
        // the reason this register exists is because whenever the game sets the scanline, it should be set to 0
        get {
            return currentLine
        }
        set {
            currentLine = 0
        }
    }
    
    static private func setLCDStatus() {
        
        if currentLine >= 144 {
            STAT.mode = .VBlank
        } else {
            let mode2bound = 80
            let mode3bound = mode2bound + 172
            
            if scanLineCycles < mode3bound {
                STAT.mode = .searchSprite
            } else if scanLineCycles < mode3bound {
                STAT.mode = .dataTransfer
            } else {
                STAT.mode = .HBlank
            }
        }
        
        if STAT.IntCoincidence && STAT.coincidenceFlag {
            CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.LCD)
        }
    }
    
    static func updateGraphics(cycles: UInt) {
        setLCDStatus()
        
        if LCDC.LCDenabled {
            scanLineCycles += cycles
        } else {
            return
        }
        
        if scanLineCycles >= 456 {
            currentLine += 1
            
            scanLineCycles = 0
            if currentLine == 144 {
                CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.VBlank)
            } else if currentLine > 153 {
                currentLine = 0
            } else if currentLine < 144 {
                drawScanLine()
            }
        }
    }
    
    private static func drawScanLine() {
        if LCDC.BGDisplay {
            renderTiles()
        }
        
        if LCDC.spriteDisplay {
            // render sprites
        }
    }
    
    private static func getColor(from shade: UInt8) -> (red: UInt8, green: UInt8, blue: UInt8) {
        // this function will eventually read palette data in the GPU
        return (red: 32, green: 32, blue: 32)
    }
    
    private static func renderTiles() {
        var tileData: UInt16 = 0
        var backgroundMemory: UInt16 = 0
        var unsig = true
        let usingWindow = LCDC.windowDisplayToggle && windowY <= scrollY
        
        if LCDC.BGWindowTileSelect {
            tileData = 0x0000
            
        } else {
            tileData = 0x0800
            unsig = false
        }
        
        if usingWindow {
            backgroundMemory = LCDC.windowTileMapSelect ? 0x1C00 : 0x1800
        } else {
            backgroundMemory = LCDC.BGTileMapSelect ? 0x1C00 : 0x1800
        }
        
        let yPos: UInt16 = UInt16(usingWindow ? scrollY + currentLine : currentLine - windowY)
        let tileRow = UInt16(yPos/8)*32
        let lineInTile = (yPos % 8) * 2
        /*for tileRow in stride(from: 0, to: 160, by: 8) {
          // this can be used as an optimization later on
        }*/
        
        for pixel: UInt8 in 0..<160 {
            let xPos = UInt16(usingWindow && pixel >= windowX ? pixel - windowX : pixel + scrollX)
            
            let tileCol = xPos / 8
            let tileNum = UInt16(activeVRAMbank.pointee[(backgroundMemory + tileRow + tileCol)])
            
            let tileLocation = tileData + UInt16(unsig ? (tileNum * 16) : ((tileNum + 128) * 16) )
            
            let lData = vram[tileLocation + lineInTile]
            let hData = vram[tileLocation + lineInTile + 1]
           
            // will be high on the bit of data needed to select the color of the tile
            let colorSelector: UInt8 = 0x80 >> (pixel % 8)
            let shade = UInt8((colorSelector & hData) > 0 ? 0b10 : 0b00 | (colorSelector & lData) > 0 ? 0b01 : 0b00)

            let color = getColor(from: shade)
            
            screenData[UInt16(currentLine) + UInt16(pixel)] = color
        }
        
    }
}
