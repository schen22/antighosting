//
//  ContentView.swift
//  antiGhosting
//
//  Created by Sarah Chen on 1/26/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
  @State private var prompt: String = "Press the button to get a fun prompt!"
  @State private var apiResponse: String = ""
  @State private var timeLeft: Int = 0
  @State private var timer: Timer? = nil
  @State private var isRecording: Bool = false
  @State private var audioRecorder: AVAudioRecorder? = nil
  
  var body: some View {
    VStack(spacing: 30) {
      Text(prompt)
        .font(.headline)
        .multilineTextAlignment(.center)
        .padding()
      
      if !apiResponse.isEmpty {
        Text("API Response: \(apiResponse)")
          .font(.subheadline)
          .foregroundColor(.gray)
          .padding()
      }
      
      if timeLeft > 0 {
        Text("Time left: \(timeLeft)s")
          .font(.title)
          .foregroundColor(.red)
      }
      
      Button(action: {
        fetchPrompt()
      }) {
        Text("Get a Prompt")
          .font(.title2)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      
      Button(action: {
        if isRecording {
          stopRecording()
        } else {
          startRecording()
        }
      }) {
        Text(isRecording ? "Stop Recording" : "Start Recording")
          .font(.title2)
          .padding()
          .background(isRecording ? Color.red : Color.green)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
    }
    .padding()
    .onDisappear {
      timer?.invalidate()
    }
  }
  
  private func fetchPrompt() {
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
      prompt = "Error: Invalid URL"
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer API-KEY", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
      "model": "gpt-3.5-turbo",
      "messages": [
        ["role": "system", "content": "You are a helpful assistant."],
        ["role": "user", "content": "Generate a fun prompt that can be answered in 30 seconds and sent to close friends."],
        ["role": "developer", "content": "Provide fun prompts for quick and engaging responses."]
      ],
      "max_tokens": 50
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        DispatchQueue.main.async {
          prompt = "Error: \(error.localizedDescription)"
        }
        return
      }
      
      guard let data = data else {
        DispatchQueue.main.async {
          prompt = "Error: No data received"
        }
        return
      }
      
      do {
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
          DispatchQueue.main.async {
            prompt = content
          }
          // unwrap error message
          //          } else if let errorObject = json["error"] as? [String:Any],
          //                    let errorMessage = errorObject["message"] as? String {
          //            DispatchQueue.main.async {
          //              prompt = "Error: \(errorMessage)"
          //            }
          //          }
        } else {
          // print error message
          print(String(data: data, encoding: .utf8)!)
          DispatchQueue.main.async {
            prompt = "Error: Unable to parse response"
          }
        }
      } catch {
        DispatchQueue.main.async {
          prompt = "Error: \(error.localizedDescription)"
        }
      }
    }
    
    task.resume()
  }
  
  private func startTimer() {
    timer?.invalidate()
    timeLeft = 30
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if timeLeft > 0 {
        timeLeft -= 1
      } else {
        timer?.invalidate()
        if isRecording {
          stopRecording()
        }
      }
    }
  }
  
  private func startRecording() {
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
      try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
      try audioSession.setActive(true)
      
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioFilename = documentsPath.appendingPathComponent("response.m4a")
      
      let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
      
      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder?.record()
      
      isRecording = true
      startTimer()
    } catch {
      prompt = "Error: Unable to start recording"
    }
  }
  
  private func stopRecording() {
    audioRecorder?.stop()
    audioRecorder = nil
    isRecording = false
  }
}

//
//#Preview {
//  ContentView()
//}
