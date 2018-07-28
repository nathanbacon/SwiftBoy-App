//
//  GameboyDebugger.swift
//  GB
//
//  Created by Nathan Gelman on 7/25/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import UIKit

class GameboyDebugger: UIViewController {
    
    @IBOutlet weak var aText: UITextField!
    @IBOutlet weak var bText: UITextField!
    @IBOutlet weak var cText: UITextField!
    @IBOutlet weak var dText: UITextField!
    @IBOutlet weak var eText: UITextField!
    @IBOutlet weak var fText: UITextField!
    @IBOutlet weak var hText: UITextField!
    @IBOutlet weak var lText: UITextField!
    @IBOutlet weak var pcText: UITextField!
    @IBOutlet weak var spText: UITextField!
    @IBOutlet weak var zeroText: UITextField!
    @IBOutlet weak var subText: UITextField!
    @IBOutlet weak var hcarryText: UITextField!
    @IBOutlet weak var carryText: UITextField!
    @IBOutlet weak var continueText: UITextField!
    @IBOutlet weak var prevInstrucText: UILabel!
    
    @IBAction func nextInstruction() {
        gb.execInstruc()
        updateUI()
    }
    
    @IBAction func continueExecution() {
        if let text = continueText.text, !text.isEmpty {
            if let addr = UInt16(text, radix: 16) {
                gb.continueExecution(to: addr)
                //gb.runLoop()
                updateUI()
            }
        }
    }
    
    
    func updateUI() {
        aText.text = String(CPU.registers.A, radix: 16)
        bText.text = String(CPU.registers.B, radix: 16)
        cText.text = String(CPU.registers.C, radix: 16)
        dText.text = String(CPU.registers.D, radix: 16)
        eText.text = String(CPU.registers.E, radix: 16)
        fText.text = String(CPU.registers.F, radix: 16)
        hText.text = String(CPU.registers.H, radix: 16)
        lText.text = String(CPU.registers.L, radix: 16)
        pcText.text = String(CPU.registers.PC, radix: 16)
        spText.text = String(CPU.registers.SP, radix: 16)
        zeroText.text = CPU.registers.flags.zero ? "set" : "reset"
        subText.text = CPU.registers.flags.subtract ? "set" : "reset"
        hcarryText.text = CPU.registers.flags.halfCarry ? "set" : "reset"
        carryText.text = CPU.registers.flags.carry ? "set" : "reset"
        prevInstrucText.text = CPU.prevInstruction
 
    }
    
    var gb = GameBoy()

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }


}
