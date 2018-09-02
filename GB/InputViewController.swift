//
//  InputViewController.swift
//  GB
//
//  Created by Nathan Gelman on 8/9/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import UIKit

class InputViewController: UIViewController {
    
    static var inputController = InputController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func pressed(_ sender: UIButton) {
        switch sender.titleLabel?.text {
        case "Up":
            InputViewController.inputController.up = true
        case "Down":
            InputViewController.inputController.down = true
        case "Left":
            InputViewController.inputController.left = true
        case "Right":
            InputViewController.inputController.right = true
        case "A":
            InputViewController.inputController.a = true
        case "B":
            InputViewController.inputController.b = true
        case "Select":
            InputViewController.inputController.select = true
        case "Start":
            InputViewController.inputController.start = true
        default:
            fatalError()
        }
        InputViewController.inputController.buttonPressed = true
    }
    
    @IBAction func depressed(_ sender: UIButton) {
        switch sender.titleLabel?.text {
        case "Up":
            InputViewController.inputController.up = false
        case "Down":
            InputViewController.inputController.down = false
        case "Left":
            InputViewController.inputController.left = false
        case "Right":
            InputViewController.inputController.right = false
        case "A":
            InputViewController.inputController.a = false
        case "B":
            InputViewController.inputController.b = false
        case "Select":
            InputViewController.inputController.select = false
        case "Start":
            InputViewController.inputController.start = false
        default:
            fatalError()
        }
    }
    
}
