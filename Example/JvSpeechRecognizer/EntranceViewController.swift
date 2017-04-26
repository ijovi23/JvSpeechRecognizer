//
//  EntranceViewController.swift
//  JvSpeechRecognizer
//
//  Created by Jovi Du on 25/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class EntranceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func btnTryPressed() {
        
        if #available(iOS 10.0, *) {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ViewController") {
                present(vc, animated: true, completion: nil)
            }
        } else {
            if let uvc = storyboard?.instantiateViewController(withIdentifier: "UnavailableViewController") {
                present(uvc, animated: true, completion: nil)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
