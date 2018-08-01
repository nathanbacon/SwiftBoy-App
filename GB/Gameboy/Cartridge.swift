//
//  Cartridge.swift
//  GB
//
//  Created by Nathan Gelman on 7/14/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation

struct Cartridge {
    
    let ROMbanks: Array<Data>
    var RAMbanks: Array<Data> = Array<Data>(repeating: Data(repeating: 0, count: 0x2000), count: 4)
    var activeROMBankNo: Int = 1
    var activeRAMBankNo: Int = 1
    
    init(filename: String) {

        guard let rom = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: filename, ofType: "gb")!)) else { fatalError() }
        
        var memOffset: Int = 0
        var banksTemp: Array<Data> = []
        
        while memOffset < rom.count {
            banksTemp.append(rom.subdata(in: memOffset..<(memOffset + 0x4000)))
            memOffset += 0x4000
        }
        
        ROMbanks = banksTemp

    }
    
    mutating func getROMBank(at index: UInt8) -> Data {
        activeROMBankNo = Int(index)
        return ROMbanks[Int(index)]
    }
    
    mutating func getRAMBank(at index: UInt8) -> UnsafeMutablePointer<Data> {
        activeRAMBankNo = Int(index)
        return withUnsafeMutablePointer(to: &RAMbanks[Int(index)], {$0})
    }
}
