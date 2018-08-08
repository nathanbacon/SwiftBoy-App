//
//  GameBoy.swift
//  GB
//
//  Created by Nathan Gelman on 5/23/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

class GameBoy {
    static var cpu: CPU = CPU.cpu
    
    static var mmu: MMU = MMU.mmu
    
    var cart: Cartridge
    
    init() {
        cart = Cartridge(filename: "pokemon_blue")
        GameBoy.mmu.cartridge = cart
    }
    
    func runLoop() {
        CPU.startTime = CFAbsoluteTimeGetCurrent()
        while true {
            let cycles = CPU.execNextInstruction()
            GPU.updateGraphics(cycles: cycles)
            Timer.updateTimer(elapsed: cycles)
            CPU.Interrupt.processInterrupts()
        }
    }
    
    func execInstruc() -> UInt {
        let cycles = CPU.execNextInstruction()
        GPU.updateGraphics(cycles: cycles)
        Timer.updateTimer(elapsed: cycles)
        CPU.Interrupt.processInterrupts()
        return cycles
    }
    
    func continueExecution(to pc: UInt16) {
        CPU.startTime = CFAbsoluteTimeGetCurrent()
        while CPU.registers.PC != pc {
            _ = execInstruc()
        }
    }
    
    var nextFrame: Data {
        get {
            //GPU.textureData = Data(repeating: 0x00, count: 160*144*4)
            
            while !GPU.isReady {
                let _ = execInstruc()
            }
            GPU.isReady = false
            return GPU.textureData
            /*var elapsedCycles: UInt = 0
            while elapsedCycles < 70224 {
                elapsedCycles += execInstruc()
            }
            return GPU.textureData*/
            
        }
        set {
            
        }
    }
    
    

}
