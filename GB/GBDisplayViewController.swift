//
//  GBDisplayViewController.swift
//  GB
//
//  Created by Nathan Gelman on 7/31/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import UIKit
import MetalKit

class GBDisplayViewController: UIViewController {
    
    var metalView: MTKView {
        get {
            return view as! MTKView
        }
    }
    
    var gameboy: GameBoy = GameBoy()
    
    var renderer: GBRenderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        metalView.device = MTLCreateSystemDefaultDevice()
        renderer = GBRenderer(device: metalView.device!, gameboy: gameboy)
        metalView.delegate = renderer
    }

    

}
