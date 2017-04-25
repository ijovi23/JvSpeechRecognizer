//
//  JvSpeechRecognizer.swift
//  JvSpeechRecognizerDemo
//
//  Created by Jovi Du on 20/04/2017.
//  Copyright © 2017 Jovistudio. All rights reserved.
//

import Speech

public enum JvSpeechRecognizerStartResult: Int {
    case success
    case busy
    case noPermission
    case recognizerUnavailable
    case audioEngineNoInputNode
    case otherError
}

public enum JvSpeechRecognizerStatus {
    case idle
    case listening
    case recognizing
}

@objc public protocol JvSpeechRecognizerDelegate : NSObjectProtocol {
    
    @objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizePartialResult partialResult: String)
    
    @objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizeFinalResult finalResult: String, allResults: [String])
    
    @objc optional func jvSpeechRecognizerWasCancelled(_ recognizer: JvSpeechRecognizer)
    
    @objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didFinishWithError error: Error?)
}

@available(iOS 10.0, *)
open class JvSpeechRecognizer: NSObject, SFSpeechRecognitionTaskDelegate {
    
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
    private var sfRecognitionTask: SFSpeechRecognitionTask?
    private var sfAudioRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let avAudioEngine = AVAudioEngine()
    weak private var avAudioSession: AVAudioSession! {
        get {
            return AVAudioSession.sharedInstance()
        }
    }
    
    //Init
    
    init?(localeId: String?) {
        if localeId != nil {
            sfRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId!))
        } else {
            sfRecognizer = SFSpeechRecognizer()
        }
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
                debugPrint("AudioSession setup failed: \(error.localizedDescription)")
                return .otherError
            }
        }
        
        guard let inputNode = avAudioEngine.inputNode else {
            debugPrint("Cannot perform input with current hardware/AVAudioSesssionCategory.")
            return .audioEngineNoInputNode
        }
        
        sfAudioRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let sfAudioRecognitionRequest = sfAudioRecognitionRequest else {
            debugPrint("Failed to create the instance of SFSpeechAudioBufferRecognitionRequest")
            return .otherError
        }
        
        sfAudioRecognitionRequest.shouldReportPartialResults = reportPartialResults
        sfRecognitionTask = sfRecognizer.recognitionTask(with: sfAudioRecognitionRequest, delegate: self)
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            sfAudioRecognitionRequest.append(buffer)
        }
        
        avAudioEngine.prepare()
        
        do {
            try avAudioEngine.start()
        } catch {
            debugPrint("AudioEngine failed to start: \(error.localizedDescription)")
            return .otherError
        }
        
        status = .listening
        return .success
    }
    
    private func _stopSpeaking() {
        if avAudioEngine.isRunning {
            avAudioEngine.stop()
        }
        
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
        if avAudioEngine.isRunning {
            avAudioEngine.stop()
        }
        
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
    
    private func debugPrint(_ content: String) {
        if needsDebugLog {
            print(content)
        }
    }
    
    /// SFSpeechRecognitionTaskDelegate
    
    public func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        debugPrint("speechRecognitionDidDetectSpeech")
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        debugPrint("speechRecognitionTaskDidHypothesizeTranscription")
        let result = transcription.formattedString
        
        OperationQueue.main.addOperation {
            self.delegate?.jvSpeechRecognizer?(self, didRecognizePartialResult: result)
        }
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        debugPrint("speechRecognitionTaskDidFinishRecognition")
        let bestResult = recognitionResult.bestTranscription.formattedString
        let results = recognitionResult.transcriptions.map({$0.formattedString})
        
        OperationQueue.main.addOperation {
            self.delegate?.jvSpeechRecognizer?(self, didRecognizeFinalResult: bestResult, allResults: results)
        }
    }
    
    public func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        debugPrint("speechRecognitionTaskFinishedReadingAudio")
        status = .recognizing
    }
    
    public func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        debugPrint("speechRecognitionTaskWasCancelled")
        status = .idle
        
        OperationQueue.main.addOperation {
            self.delegate?.jvSpeechRecognizerWasCancelled?(self)
        }
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if successfully {
            debugPrint("speechRecognitionTaskDidFinishSuccessfully")
        } else {
            debugPrint("speechRecognitionTaskDidFinishUnsuccessfully: \(task.error?.localizedDescription ?? "Unknown error")")
        }
        status = .idle
        
        OperationQueue.main.addOperation {
            self.delegate?.jvSpeechRecognizer?(self, didFinishWithError: task.error)
        }
    }
}
