//
//  ViewController.swift
//  ios_cube_loader
//
//  Created by Brian Jones on 2/27/16.
//  Copyright © 2016 Brian Jones. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let device = MTLCreateSystemDefaultDevice()
        let or = ObjRenderer(device: device!)
        //let data = reader.arrayData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

