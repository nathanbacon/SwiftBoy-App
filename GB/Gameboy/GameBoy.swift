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
    
    
    static func openROM(with fileName: String) {
        mmu.openRom(fileName: fileName)
    }
}
