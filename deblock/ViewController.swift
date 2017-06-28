//
//  ViewController.swift
//  deblock
//
//  Created by alexma on 26/06/2017.
//  Copyright © 2017 alexma. All rights reserved.
//

import UIKit
import CoreML



@available(iOS 11.0, *)
class ViewController: UIViewController {


    
    @IBOutlet weak var myview: GGView!
    
    
//    let model = pred()
//
//    let input_data = try? MLMultiArray(shape:[16], dataType:MLMultiArrayDataType.double)
//
//    let k_data = try? MLMultiArray(shape:[10], dataType:MLMultiArrayDataType.double)
    
    
   //    else {
//    fatalError("Unexpected runtime error. MLMultiArray")
//    }
//
//    guard let Output = try? model.prediction(input1:matrix) else {
//    fatalError("Unexpected runtime error.")
//    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        for i in 0..<16 {
//            input_data![i] = 1
//        }
//        for i in 0..<10 {
//            k_data![i] = 1
//        }
//        let i = predInput(input1: input_data!, lstm_1_c_in: k_data!)
//       // let i = predInput(input1: input_data!)
//        let output = try? model.prediction(input: i)
//        let result = String(describing: output?.output1[0])
//        let result1 = String(describing: output?.lstm_1_h_out[0])
//        print(input_data!)
//        print(result)
//        print(result1)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

}

