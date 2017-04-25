# JvSpeechRecognizer
An encapsulation of SFSpeechRecognizer. Just did some potty work └□·□┘

![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg?style=flat)

## Requirements

- iOS 10.0+
- Xcode 8.3+
- Swift 3.1+

## Installation
### Manually
Add all files in the directory **JvSpeechRecognizer** to your project.

## Usage

### Create & Init

`let recognizer = JvSpeechRecognizer(localeId: "en-US")`

### Methods
```
open func requestPermission(_ response: @escaping (Bool) -> Void)

open func startSpeaking() -> JvSpeechRecognizerStartResult

open func startSpeaking(delegate del: JvSpeechRecognizerDelegate) -> JvSpeechRecognizerStartResult

open func stopSpeaking()

open func cancel()
```

### Delegate Methods
```
@objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizePartialResult partialResult: String)
    
@objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizeFinalResult finalResult: String, allResults: [String])
    
@objc optional func jvSpeechRecognizerWasCancelled(_ recognizer: JvSpeechRecognizer)
    
@objc optional func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didFinishWithError error: Error?)
```

### See more details in the Demo project

![](https://github.com/ijovi23/JvSpeechRecognizer/raw/master/Resources/demoScreenshot01.PNG)