//
//  ViewController.swift
//  dictation
//
//  Created by Hana on 10/12/16.
//  Copyright © 2016 sarcrates. All rights reserved.
//

import UIKit
import Speech

public class ViewController: UIViewController, SFSpeechRecognizerDelegate{
    @IBOutlet weak var textview: UITextView!
    @IBOutlet weak var dictatebutton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        dictatebutton.isEnabled = false
        
        
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.dictatebutton.isEnabled = true
                    
                case .denied:
                    self.dictatebutton.isEnabled = false
                    self.dictatebutton.setTitle("User denied access to speech recognition.", for: .disabled)
                    
                case .restricted:
                    self.dictatebutton.isEnabled = false
                    self.dictatebutton.setTitle("Speech recognition restricted on device.", for: .disabled)
                    
                case .notDetermined:
                    self.dictatebutton.isEnabled = false
                    self.dictatebutton.setTitle("Speech recognition not yet authorized.", for: .disabled)
                }
            }
            
            
        }
        
    }

    
    private func StartRecording() throws {
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SfSpeechAudioBufferRecognitionRequest object")}
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in var isFinal = false
            
            var formattedString: String
            let search: String = "test"
            var words: [String] = []
            var found: String = ""
            if let result = result {
                
                self.textview.text = result.bestTranscription.formattedString
                formattedString = result.bestTranscription.formattedString
                words = formattedString.components(separatedBy: " ")
                print(words)
                print(formattedString)
                if(formattedString.contains(search)){
                    for word in words{
                        if(word == search){
                            found = word
                        }
                    }
                    print(found)
                    self.textview.textColor = UIColor.red
                    print("true")
                }else{
                    print("false")
                }
                /*  let fileName = "test"
                 let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                 
                 let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
                 print("FilePath: \(fileURL.path)")
                 
                 let writeString = NSString(string: formattedString)
                 do {
                 try writeString.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
                 } catch let error as NSError {
                 print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
                 }*/
                
                isFinal = result.isFinal
            }
            
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.dictatebutton.isEnabled = true
                self.dictatebutton.setTitle("Start Speaking", for: [])
            }
            
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        textview.text = "I'm listening."
        
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            dictatebutton.isEnabled = true
            dictatebutton.setTitle("Start Recording", for: [])
        } else {
            dictatebutton.isEnabled = false
            dictatebutton.setTitle("Recognition not available.", for: .disabled)
        }
        
    }
    
    @IBAction func dictateaction() {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            dictatebutton.isEnabled = false
            dictatebutton.setTitle("Ending...", for: .disabled)
        } else {
            try! StartRecording()
            dictatebutton.setTitle("Stop Recording", for: [])
        }
        
        
    }
    
}
