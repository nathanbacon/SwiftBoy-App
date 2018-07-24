//
//  GameBoy.swift
//  GB
//
//  Created by Nathan Gelman on 5/23/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

struct GameBoy {
    static var cpu: CPU = CPU.cpu
    
    static var mmu: MMU = MMU.mmu
    
    var cart: Cartridge
    
    init() {
        cart = Cartridge(filename: "pokemon_blue")
        GameBoy.mmu.cartridge = cart
    }
    
    func runLoop() {
        while GPU.currentLineRegister < 145 {
            let cycles = CPU.execNextInstruction()
            GPU.updateGraphics(cycles: cycles)
        }
    }
    
    func execInstruc() {
        let cycles = CPU.execNextInstruction()
        GPU.updateGraphics(cycles: cycles)
    }
    

}
