//
//  ViewController.swift
//  InstabugInternshipTask
//
//  Created by Yosef Hamza on 19/04/2021.
//

import UIKit
import InstabugLogger

class ViewController: UIViewController {
    @IBOutlet weak var mainThreadLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        InstabugLogger.shared.log(.debug, message: "TEST1")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse, .transitionCurlUp]) {
            self.mainThreadLabel.transform = CGAffineTransform(rotationAngle: CGFloat( Double.pi))
        }
        
//        DispatchQueue(label: "loading").async {
//
//        }
        for i in 0...8000 {
                        InstabugLogger.shared.log(.debug, message: "Test\(i)")
//                        InstabugLogger.shared.fetchAllLogs {
//                            print($0)
//                        }
        }
    }


}

