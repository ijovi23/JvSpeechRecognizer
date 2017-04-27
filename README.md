# JvSpeechRecognizer
An encapsulation of SFSpeechRecognizer. Just did some potty work └□·□┘

[![CI Status](http://img.shields.io/travis/ijovi23/JvSpeechRecognizer.svg?style=flat)](https://travis-ci.org/ijovi23/JvSpeechRecognizer)
[![Version](https://img.shields.io/badge/pod-v1.0.2-brightgreen.svg?style=flat)](http://cocoapods.org/pods/JvSpeechRecognizer)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](http://cocoapods.org/pods/JvSpeechRecognizer)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg?style=flat)](http://cocoapods.org/pods/JvSpeechRecognizer)

<!--## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.-->

## Requirements

- iOS 10.0+ [use]
- iOS 9.0+ [build]
- Xcode 8.3+
- Swift 3.1+

## Installation

### Cocoapods

JvSpeechRecognizer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "JvSpeechRecognizer"
```

### Manually
Add all files in the directory **JvSpeechRecognizer** to your project.

## Usage

### Privacy

Add the following keys to `Info.plist`

`NSMicrophoneUsageDescription`
`NSSpeechRecognitionUsageDescription`

### Create & Init
```swift
let recognizer = JvSpeechRecognizer(localeId: "en-US")
```

### Methods
```swift
open func requestPermission(_ response: @escaping (Bool) -> Void)

open func startSpeaking() -> JvSpeechRecognizerStartResult

open func startSpeaking(delegate del: JvSpeechRecognizerDelegate) -> JvSpeechRecognizerStartResult

open func stopSpeaking()

open func cancel()
```

### Delegate Methods
```swift
func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizePartialResult partialResult: String)
    
func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didRecognizeFinalResult finalResult: String, allResults: [String])
    
func jvSpeechRecognizerWasCancelled(_ recognizer: JvSpeechRecognizer)
    
func jvSpeechRecognizer(_ recognizer: JvSpeechRecognizer, didFinishWithError error: Error?)
```

### See more details in the demo

![](https://github.com/ijovi23/JvSpeechRecognizer/raw/master/Resources/demoScreenshot01.PNG)

## Author

ijovi23, ijovi23@gmail.com

## License

JvSpeechRecognizer is available under the MIT license. See the LICENSE file for more info.
