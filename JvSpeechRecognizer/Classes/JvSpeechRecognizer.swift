//
//  JvSpeechRecognizer.swift
//  JvSpeechRecognizerDemo
//
//  Created by Jovi Du on 20/04/2017.
//  Copyright © 2017 Jovistudio. All rights reserved.
//

import Speech

@objc public enum JvSpeechRecognizerStartResult: Int {
    case success = 0
    case busy
    case noPermission
    case recognizerUnavailable
    case audioEngineNoInputNode
    case otherError
}

@objc public enum JvSpeechRecognizerStatus: Int {
    case idle
    case listening
    case recognizing
}

@objc public protocol JvSpeechRecognizerDelegate: NSObjectProtocol {
    
    @available(iOS 10.0, *)
    @objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizePartialResult partialResult: String)
    
    @available(iOS 10.0, *)
    @objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizeFinalResult finalResult: String, allResults: [String])
    
    @available(iOS 10.0, *)
    @objc optional func jvSpeechRecognizerWasCancelled(_ recognizer: JvSpeechRecognizer)
    
    @available(iOS 10.0, *)
    @objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didFinishWithError error: Error?)
}

@available(iOS 10.0, *)
open class JvSpeechRecognizer: NSObject {
    
    //Public Properties
    
    weak open var delegate: JvSpeechRecognizerDelegate?
    
    open private(set) var status: JvSpeechRecognizerStatus = .idle
    
    open var audioSessionControlEnabled = true
    
    open var reportPartialResults = true
    
    open var needsDebugLog = false
    
    public var microphonePermitted: Bool {
        get {
            return (avAudioSession.recordPermission() == .granted)
        }
    }
    
    public var speechRecognitionPermitted: Bool {
        get {
            return (SFSpeechRecognizer.authorizationStatus() == .authorized)
        }
    }
    
    //Private Properties
    
    private var sfRecognizer: SFSpeechRecognizer?
    private var sfRecognizerDelegate: JvSpeechRecognizer_nativeRecognizerDelegate
    private var sfRecognitionTask: SFSpeechRecognitionTask?
    private var sfAudioRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var avAudioEngine: AVAudioEngine?
    weak private var avAudioSession: AVAudioSession! {
        get {
            return AVAudioSession.sharedInstance()
        }
    }
    
    //Init
    
    public init?(localeId: String?) {
        if localeId != nil {
            sfRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId!))
        } else {
            sfRecognizer = SFSpeechRecognizer()
        }
        sfRecognizerDelegate = JvSpeechRecognizer_nativeRecognizerDelegate()
        
        super.init()
        
        sfRecognizerDelegate.ownerRecognizer = self
    }
    
    
    //Open Func
    
    open func requestPermission(_ response: @escaping (Bool) -> Void) {
        _requestPermission(response)
    }
    
    open func startSpeaking() -> JvSpeechRecognizerStartResult {
        return _startSpeaking()
    }
    
    open func startSpeaking(delegate del: JvSpeechRecognizerDelegate) -> JvSpeechRecognizerStartResult {
        delegate = del
        return _startSpeaking()
    }
    
    open func stopSpeaking() {
        _stopSpeaking()
    }
    
    open func cancel() {
        _cancel()
    }
    
    
    //Private Func
    
    private func _requestPermission(_ response: @escaping (Bool) -> Void) {
        // Request Microphone Permission
        avAudioSession.requestRecordPermission { (granted) in
            if granted {
                // Microphone Usage Permitted
                // Then Request Speech Recognition Permission
                SFSpeechRecognizer.requestAuthorization({ (authStatus) in
                    OperationQueue.main.addOperation {
                        response(authStatus == .authorized)
                    }
                })
            } else {
                // Microphone Usage Refused
                OperationQueue.main.addOperation {
                    response(false)
                }
            }
        }
    }
    
    private func _startSpeaking() -> JvSpeechRecognizerStartResult {
        
        guard microphonePermitted && speechRecognitionPermitted else {
            return .noPermission
        }
        
        guard let sfRecognizer = sfRecognizer else {
            return .recognizerUnavailable
        }
        
        guard sfRecognizer.isAvailable else {
            return .recognizerUnavailable
        }
        
        guard status == .idle else {
            return .busy
        }
        
        if audioSessionControlEnabled {
            do {
                try avAudioSession.setCategory(AVAudioSessionCategoryRecord)
                try avAudioSession.setMode(AVAudioSessionModeMeasurement)
                try avAudioSession.setActive(true, with: .notifyOthersOnDeactivation)
            } catch {
                printIfNeeded("AudioSession setup failed: \(error.localizedDescription)")
                return .otherError
            }
        }
        
        avAudioEngine = AVAudioEngine()
        guard let avAudioEngine = avAudioEngine else { return .otherError }
        
        guard let inputNode = avAudioEngine.inputNode else {
            printIfNeeded("Cannot perform input with current hardware/AVAudioSesssionCategory.")
            return .audioEngineNoInputNode
        }
        
        sfAudioRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let sfAudioRecognitionRequest = sfAudioRecognitionRequest else {
            printIfNeeded("Failed to create the instance of SFSpeechAudioBufferRecognitionRequest")
            return .otherError
        }
        
        sfAudioRecognitionRequest.shouldReportPartialResults = reportPartialResults
        sfRecognitionTask = sfRecognizer.recognitionTask(with: sfAudioRecognitionRequest, delegate: sfRecognizerDelegate)
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat) { (buffer, when) in
            sfAudioRecognitionRequest.append(buffer)
        }
        
        avAudioEngine.prepare()
        
        do {
            try avAudioEngine.start()
        } catch {
            printIfNeeded("AudioEngine failed to start: \(error.localizedDescription)")
            return .otherError
        }
        
        status = .listening
        return .success
    }
    
    private func _stopSpeaking() {
        
        avAudioEngine?.stop()
        
        sfAudioRecognitionRequest?.endAudio()
        
        if sfRecognitionTask != nil {
            switch sfRecognitionTask!.state {
            case .starting, .running:
                sfRecognitionTask?.finish()
            default: break
            }
        }
        
        status = .recognizing
    }
    
    private func _cancel() {
        
        avAudioEngine?.stop()
        
        sfAudioRecognitionRequest?.endAudio()
        
        if sfRecognitionTask != nil {
            switch sfRecognitionTask!.state {
            case .starting, .running, .finishing:
                sfRecognitionTask?.cancel()
            default: break
            }
        }
        
        status = .idle
    }
    
    fileprivate func printIfNeeded(_ content: String) {
        if needsDebugLog {
            print(content)
        }
    }
    
    fileprivate func setStatus(_ newStatus: JvSpeechRecognizerStatus) {
        status = newStatus
    }
    
}

@available(iOS 10.0, *)
private class JvSpeechRecognizer_nativeRecognizerDelegate: NSObject, SFSpeechRecognitionTaskDelegate {
    
    weak public var ownerRecognizer: JvSpeechRecognizer?
    
    public func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        ownerRecognizer?.printIfNeeded("speechRecognitionDidDetectSpeech")
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        ownerRecognizer?.printIfNeeded("speechRecognitionTaskDidHypothesizeTranscription")
        let result = transcription.formattedString
        
        OperationQueue.main.addOperation {
            self.ownerRecognizer?.delegate?.jvSpeechRecognizer?(self.ownerRecognizer!, didRecognizePartialResult: result)
        }
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        ownerRecognizer?.printIfNeeded("speechRecognitionTaskDidFinishRecognition")
        let bestResult = recognitionResult.bestTranscription.formattedString
        let results = recognitionResult.transcriptions.map({$0.formattedString})
        
        OperationQueue.main.addOperation {
            self.ownerRecognizer?.delegate?.jvSpeechRecognizer?(self.ownerRecognizer!, didRecognizeFinalResult: bestResult, allResults: results)
        }
    }
    
    public func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        ownerRecognizer?.printIfNeeded("speechRecognitionTaskFinishedReadingAudio")
        self.ownerRecognizer?.setStatus(.recognizing)
    }
    
    public func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        ownerRecognizer?.printIfNeeded("speechRecognitionTaskWasCancelled")
        self.ownerRecognizer?.setStatus(.idle)
        
        OperationQueue.main.addOperation {
            self.ownerRecognizer?.delegate?.jvSpeechRecognizerWasCancelled?(self.ownerRecognizer!)
        }
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if successfully {
            ownerRecognizer?.printIfNeeded("speechRecognitionTaskDidFinishSuccessfully")
        } else {
            ownerRecognizer?.printIfNeeded("speechRecognitionTaskDidFinishUnsuccessfully: \(task.error?.localizedDescription ?? "Unknown error")")
        }
        self.ownerRecognizer?.setStatus(.idle)
        
        OperationQueue.main.addOperation {
            self.ownerRecognizer?.delegate?.jvSpeechRecognizer?(self.ownerRecognizer!, didFinishWithError: task.error)
        }
    }
    
}
