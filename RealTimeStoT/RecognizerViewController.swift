//
//  RecognizerViewController.swift
//  RealTimeStoT
//
//  Created by Jonah Zukosky on 1/26/19.
//  Copyright © 2019 Zukosky, Jonah. All rights reserved.
//

import UIKit
import Speech

class RecognizerViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var recordingButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorizeSR()
        
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        if isRecording {
            isRecording = !isRecording
            recordingButton.setTitle("Start Recording", for: .normal)
            recordingButton.backgroundColor = UIColor.green
            stopRecording()
        } else {
            isRecording = !isRecording
            textView.text = ""
            recordingButton.setTitle("Stop Recording", for: .normal)
            recordingButton.backgroundColor = UIColor.red
            try! startRecording()
        }
    }
    
    func startRecording() throws {
        if let recognitionTask = speechRecognitionTask {
            recognitionTask.cancel()
            self.speechRecognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .spokenAudio, options: .defaultToSpeaker)
        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = speechRecognitionRequest else {
            fatalError("SFSpeechAudioBufferRecognitionRequest object creation failed")
        }
        
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        speechRecognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var finished = false
            
            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
                finished = result.isFinal
            }
            
            if error != nil || finished {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.speechRecognitionRequest = nil
                self.speechRecognitionTask = nil
                
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.speechRecognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            speechRecognitionRequest?.endAudio()
        }
    }
    
    func authorizeSR() {
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            OperationQueue.main.addOperation {
                switch status {
                case .authorized:
                    self.recordingButton.isEnabled = true
                    self.recordingButton.backgroundColor = UIColor.green
                case .denied:
                    self.recordingButton.isEnabled = false
                    self.recordingButton.setTitle("Speech Recognition Denied", for: .disabled)
                    self.recordingButton.backgroundColor = UIColor.gray
                case .restricted:
                    self.recordingButton.isEnabled = false
                    self.recordingButton.setTitle("Speech Recognition Restricted", for: .disabled)
                    self.recordingButton.backgroundColor = UIColor.gray
                case .notDetermined:
                    self.recordingButton.isEnabled = false
                    self.recordingButton.setTitle("Speech Recognition Denied", for: .disabled)
                    self.recordingButton.backgroundColor = UIColor.gray
                }
            }
            
        }
    }

}
