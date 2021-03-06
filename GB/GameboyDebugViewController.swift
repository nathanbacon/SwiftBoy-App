//
//  GameboyDebugViewController.swift
//  GB
//
//  Created by Nathan Gelman on 7/15/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import UIKit

class GameboyDebugViewController: UITableViewController {
    
    var gameboy = GameBoy()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        gameboy.runLoop()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "PC: \(String(CPU.registers.PC, radix: 16))"
        case 1:
            cell.textLabel?.text = "A \(String(format: "%02X",CPU.registers.A))"
        case 2:
            cell.textLabel?.text = "B \(String(format: "%02X",CPU.registers.B))"
        case 3:
            cell.textLabel?.text = "C \(String(format: "%02X",CPU.registers.C))"
        case 4:
            cell.textLabel?.text = "SP \(String(CPU.registers.SP, radix: 16))"
        default:
            cell.textLabel?.text = "meow"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        gameboy.execInstruc()
        self.tableView.reloadData()
    }

}
