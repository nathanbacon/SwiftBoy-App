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
    
    static var isReady = false
    
    static var textureData = Data(repeating: 0x00, count: 160*144*4)
    static var backgroundTransparent = Array<Bool>(repeating: false, count: 160*144)
    static var claimedBySprite = Array<Bool>(repeating: false, count: 160*144)
    
    static var tileDump = Data(repeating: 0x00, count: 16 * 8 * 16 * 8 * 4)
   
    //static var screenData = Array<(red: UInt8, green: UInt8, blue: UInt8)>(repeating: (0,0,0), count: 160*144)
    
    static var VRAMbanks = Array<Data>(repeating: Data(repeating:0, count: 0x2000), count: 2)
    static var VRAMbankIndex = 0
    static var activeVRAMbank = withUnsafeMutablePointer(to: &VRAMbanks[0], {$0})
    
    static var OAM = Array<Sprite>(repeating: GPU.Sprite(), count: 40)
    
    subscript(index: UInt16) -> UInt8 {
        get {
            return GPU.VRAMbanks[GPU.VRAMbankIndex][index]
        }
        set {
            GPU.VRAMbanks[GPU.VRAMbankIndex][index] = newValue
        }
    }
    
    struct Sprite {
        enum SpritePriority: Int {
            case AboveBackground = 0
            case BehindBackground = 1
        }
        
        var x: UInt8
        var y: UInt8
        var tileNum: UInt8
        
        var priority: SpritePriority
        var yFlip: Bool
        var xFlip: Bool
        var DMGPallete: Bool
        var VRAMBank: UInt8
        var palleteNum: UInt8
        
        init() {
            x = UInt8(bitPattern: -8)
            y = UInt8(bitPattern: -16)
            tileNum = 0
            priority = .AboveBackground
            yFlip = false
            xFlip = false
            DMGPallete = false
            VRAMBank = 0
            palleteNum = 0
        }
        
        var attributes: UInt8 {
            get {
                return UInt8(priority == .BehindBackground ? 0x80 : 0) |
                    (yFlip ? 0x40 : 0) |
                    (xFlip ? 0x20 : 0) |
                    (DMGPallete ? 0x10 : 0) |
                    (VRAMBank << 3) |
                    (palleteNum & 0x03)
            }
            set {
                priority = (newValue & 0x80) > 0 ? .BehindBackground : .AboveBackground
                yFlip = newValue & 0x40 > 0
                xFlip = newValue & 0x20 > 0
                DMGPallete = 0x10 & 0x10 > 0
                VRAMBank = (newValue & 0x08) > 0 ? 0x1 : 0
                palleteNum = newValue & 0x03
            }
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
                //mode = LCDMode(rawValue: newValue & 0x03) ?? mode
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
        
        if currentLine == 144 {
            STAT.mode = .VBlank
            //GPU.isReady = true
        } else if currentLine > 144 {
            STAT.mode = .VBlank
        } else {
            let mode2bound = 80
            let mode3bound = mode2bound + 172
            
            if scanLineCycles < mode2bound {
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
            scanLineCycles = 0
            if currentLine == 144 {
                CPU.Interrupt.requestInterrupt(for: CPU.Interrupt.VBlank)
                
                isReady = true
            } else if currentLine > 153 {
                //textureData = Data(repeating: 0, count: 160*144*4)
                currentLine = 0
            } else if currentLine < 144 {
                drawScanLine()
            }
            
            currentLine += 1
        }
    }
    
    private static func drawScanLine() {
        if LCDC.BGDisplay {
            renderTiles()
        }
        
        if LCDC.spriteDisplay {
            renderSprites()
        }
    }
    
    private static func getColor(from shade: UInt8) -> (red: UInt8, green: UInt8, blue: UInt8) {
        // this function will eventually read palette data in the GPU
        return (red: 32, green: 32, blue: 32)
    }
    
    private static func renderSprites() {
        
        claimedBySprite = Array<Bool>(repeating: false, count: 160*144)

        for spriteInd in 0..<40 {
            let sprite = OAM[spriteInd]
            let y = sprite.y.subtractingReportingOverflow(16)
            let yPos = sprite.y &- 16
            let ySize: UInt8 = LCDC.spriteSize ? 16 : 8
            let xPos = sprite.x &- 8
            
            // TODO: simply check if the yPos or yPos + ySize and xPos or xPos + xSize is in the bounds of the screen?
            guard yPos <= currentLine, currentLine < yPos &+ ySize, xPos &+ 8 >= 0 else { continue } // determine if the sprite is being rendered on the current scanline
            
            
            let tileLocation = sprite.tileNum
            // unsafe subtraction might always lead to the correct result
            let lineInSprite = currentLine - yPos

            let charBank = sprite.VRAMBank & 0x01

            let lineAddr = sprite.yFlip ? (UInt16(tileLocation + 1) * UInt16(ySize) * 2 - 2) - (UInt16(lineInSprite) * 2) : (UInt16(tileLocation) * UInt16(ySize) * 2) + (UInt16(lineInSprite) * 2)
            
            guard lineAddr < VRAMbanks[charBank].count - 1 else { continue }
            
            let lData = VRAMbanks[charBank][lineAddr+1]
            let hData = VRAMbanks[charBank][lineAddr]
            
            for xPixel: UInt8 in 0..<8 {
                guard xPixel &+ xPos >= 0, xPixel &+ xPos < 160 else { continue }
                let colorSelector = sprite.xFlip ? UInt8(0x01 << xPixel) : UInt8(0x80 >> xPixel)
                
                let l: UInt8 = lData & (colorSelector) > 0 ? 0b01 : 0
                let h: UInt8 = hData & (colorSelector) > 0 ? 0b10 : 0
                
                let shade = h | l
                
                let offset = Int(currentLine) * 160 + Int(xPos &+ xPixel)
                guard shade != 0 && !claimedBySprite[offset] && (sprite.priority == .AboveBackground || backgroundTransparent[offset]) else { continue }
                claimedBySprite[offset] = true
                let memoryOffset = offset * 4
                
                switch shade {
                case 0x00:
                    textureData[memoryOffset] = 0xFF
                    textureData[memoryOffset+1] = 0xFF
                    textureData[memoryOffset+2] = 0xFF
                    textureData[memoryOffset+3] = 0xFF
                case 0x01:
                    textureData[memoryOffset] = 0xAF
                    textureData[memoryOffset+1] = 0xAF
                    textureData[memoryOffset+2] = 0xAF
                    textureData[memoryOffset+3] = 0xAF
                case 0x02:
                    textureData[memoryOffset] = 0x5F
                    textureData[memoryOffset+1] = 0x5F
                    textureData[memoryOffset+2] = 0x5F
                    textureData[memoryOffset+3] = 0x5F
                case 0x03:
                    textureData[memoryOffset] = 0x00
                    textureData[memoryOffset+1] = 0x00
                    textureData[memoryOffset+2] = 0x00
                    textureData[memoryOffset+3] = 0xFF
                default:
                    fatalError()
                }
            }
            
            
        }
    }
    
    /*private static func dumpBG() {
        let startAddr = 0x0800
        
        for tileStart in stride(from: startAddr, to: 0x2000, by: 8 * 2) {
            
        }
    }*/
    
    
    
    private static func renderTiles() {
        var tileData: UInt16 = 0
        var backgroundMemory: UInt16 = 0
        var unsig = true
        let usingWindow = LCDC.windowDisplayToggle && windowY <= currentLine
        
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
        
        let yPos: UInt16 = UInt16(!usingWindow ? scrollY &+ currentLine : currentLine &- windowY)
        let tileRow = UInt16(yPos/8)*32
        let lineInTile = UInt16(yPos % 8) * 2

        
        for pixel: UInt8 in 0..<160 {
            //let xPos = UInt16(usingWindow && pixel >= (windowX) ? pixel &- windowX : pixel &+ scrollX)
            let xPos = UInt16((usingWindow && pixel >= (windowX &- 7)) ? pixel &- (windowX &- 7) : scrollX &+ pixel)
            
            let tileCol = UInt16(xPos / 8)
            let tileNum = UInt8(VRAMbanks[VRAMbankIndex][(backgroundMemory + tileRow + tileCol)])

            let tileLocation = tileData + (unsig ? UInt16(tileNum) * 16 : UInt16((tileNum &+ 128)) * 16)

            let lData = VRAMbanks[VRAMbankIndex][tileLocation + lineInTile]
            let hData = VRAMbanks[VRAMbankIndex][tileLocation + lineInTile + 1]
            
            // will be high on the bit of data needed to select the color of the tile
            let colorSelector: UInt8 = 0x80 >> (UInt8(xPos) % 8)
            let shade = UInt8((colorSelector & hData) > 0 ? 0b10 : 0b00) | ((colorSelector & lData) > 0 ? 0b01 : 0b00)

            //let color = getColor(from: shade)

            let offset = Int(currentLine) * 160*4 + Int(pixel) * 4
            switch shade {
            case 0x00:
                textureData[offset] = 0xFF
                textureData[offset+1] = 0xFF
                textureData[offset+2] = 0xFF
                textureData[offset+3] = 0xFF
                backgroundTransparent[Int(currentLine) * 160 + Int(pixel)] = true
            case 0x01:
                textureData[offset] = 0xAF
                textureData[offset+1] = 0xAF
                textureData[offset+2] = 0xAF
                textureData[offset+3] = 0xAF
                backgroundTransparent[Int(currentLine) * 160 + Int(pixel)] = false
            case 0x02:
                textureData[offset] = 0x5F
                textureData[offset+1] = 0x5F
                textureData[offset+2] = 0x5F
                textureData[offset+3] = 0x5F
                backgroundTransparent[Int(currentLine) * 160 + Int(pixel)] = false
            case 0x03:
                textureData[offset] = 0x00
                textureData[offset+1] = 0x00
                textureData[offset+2] = 0x00
                textureData[offset+3] = 0xFF
                backgroundTransparent[Int(currentLine) * 160 + Int(pixel)] = false
            default:
                fatalError()
            }
            
            //textureData[offset] = shade
        }
        
    
    }
}
