//
//  ViewController.swift
//  JvSpeechRecognizerDemo
//
//  Created by Jovi Du on 19/04/2017.
//  Copyright © 2017 Jovistudio. All rights reserved.
//

import UIKit
import JvSpeechRecognizer

@available(iOS 10.0, *)
class ViewController: UIViewController, JvSpeechRecognizerDelegate {

    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var btnStartSpeaking: UIButton!
    @IBOutlet weak var btnStopSpeaking: UIButton!
    @IBOutlet weak var btnCancelRecognition: UIButton!
    
    let recognizer = JvSpeechRecognizer(localeId: "en-US")
    var unconfirmedResult: String?
    var confirmedResult: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnStartSpeaking.isEnabled = true
        btnStopSpeaking.isEnabled = false
        btnCancelRecognition.isEnabled = false
        
        recognizer?.delegate = self
        recognizer?.needsDebugLog = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OperationQueue().addOperation {
            self.recognizer?.requestPermission({ (permitted) in
                print("request permission result: \(permitted)")
            })
        }
    }
    
    func updateResultTextView() {
        resultTextView.text = "\(unconfirmedResult ?? "") \(confirmedResult ?? "")"
    }

    @IBAction func btnStartSpeakingPressed() {
        guard let recognizer = recognizer else {
            print("Unable to create recognizer")
            return;
        }
        
        let startResult = recognizer.startSpeaking()
        switch startResult {
        case .success:
            btnStartSpeaking.isEnabled = false
            btnStopSpeaking.isEnabled = true
            btnCancelRecognition.isEnabled = true
        default:
            print(startResult)
        }
    }
    
    @IBAction func btnStopSpeakingPressed() {
        recognizer?.stopSpeaking()
    }
    
    @IBAction func btnCancelRecognitionPressed() {
        recognizer?.cancel()
        
    }
    
    @IBAction func btnBackPressed() {
        dismiss(animated: true, completion: nil)
    }

    func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizePartialResult partialResult: String) {
        unconfirmedResult = partialResult
        updateResultTextView()
    }
    
    func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizeFinalResult finalResult: String, allResults: [String]) {
        confirmedResult = finalResult
        unconfirmedResult = nil
        updateResultTextView()
    }
    
    func jvSpeechRecognizerWasCancelled(_ recognizer: JvSpeechRecognizer) {
        btnStartSpeaking.isEnabled = true
        btnStopSpeaking.isEnabled = false
        btnCancelRecognition.isEnabled = false
    }
    
    func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didFinishWithError error: Error?) {
        btnStartSpeaking.isEnabled = true
        btnStopSpeaking.isEnabled = false
        btnCancelRecognition.isEnabled = false
    }
}

