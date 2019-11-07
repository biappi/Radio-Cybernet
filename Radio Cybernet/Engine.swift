//
//  Engine.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 06/11/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

func rms(data: [Float]) -> Float {
    return data
        .reduce(0) { (a, i) in a + powf(i, 2) }
        / Float(data.count)
}

func scalePower(_ power: Float, minDb: Float = -120) -> Float {
    if !power.isFinite {
        return 0
    }
    else if power < minDb {
        return 0
    }
    else if power >= 10 {
        return 1
    }
    else {
        return abs(abs(minDb) - abs(power)) / abs(minDb)
    }
}

func meterValue(data: [Float]) -> Float {
    let rmsValue   = rms(data: data)
    let powerValue = 20 * log10(rmsValue)
    return scalePower(powerValue)
}

func sampleFromAudioBuffer(_ pointer: UnsafeMutableRawPointer, bufferStride: Int, sampleIndex: Int) -> Float {
    return pointer
        .advanced(by: bufferStride * sampleIndex * MemoryLayout<Float>.stride)
        .bindMemory(to: Float.self, capacity: 1)
        .pointee
}

struct RadioConfiguration {
    var name:     String = ""
    var hostname: String = ""
    var port:     Int    = 80
    var mount:    String = ""
    var password: String = ""
}

struct EventConfiguration {
    var name:   String = ""
    var record: Bool = true
}

class Engine : ObservableObject {
    
    static let audioBufferSizeSec     = 1
    static let audioBufferSizeSamples = 44100 * audioBufferSizeSec
    static let mp3BufferSizeSample    = Int(1.25 * Double(audioBufferSizeSamples) + 7200)
    
    static let shared = Engine()
    
    let engine = AVAudioEngine()
    let lame   = LAME()
    let shout  = Shout()
    
    var file  : FileHandle?

    var floatData1 = [Float](repeating: 0, count: audioBufferSizeSamples)
    var mp3Buffer  = [UInt8](repeating: 0, count: mp3BufferSizeSample)

    @Published private(set) var meterLevel = CGFloat(0)
    
    func recordedFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        
        let dateString = formatter.string(from: Date())
        
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .allDomainsMask)
            .first!
            .appendingPathComponent("diocane - \(dateString).mp3")
    }
    
    func engine_test() {
        let  session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.record)
        try! session.setActive(true)
        
        engine.inputNode.installTap(
            onBus: 0,
            bufferSize: 0,
            format: nil,
            block: tap
        )

        try! engine.start()
    }

    var connectRequest: RadioConfiguration?
    
    func goLive(
        radio: RadioConfiguration,
        event: EventConfiguration
    ) {
        connectRequest = radio
        
        if event.record {
            let url = recordedFileURL()
            
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            file = try? FileHandle(forWritingTo: url)
        }
        else {
            file = nil
        }
    }
    
    func tap(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        let length        = Int(buffer.frameLength)
        let floatPointer1 = UnsafeMutableRawPointer(buffer.floatChannelData!.pointee)
        
        for sample in 0 ..< length {
            floatData1[sample] = sampleFromAudioBuffer(floatPointer1, bufferStride: buffer.stride, sampleIndex: sample)
        }
        
        let encoded = lame_encode_buffer_ieee_float(
            lame.lame,
            floatData1,
            floatData1,
            Int32(length),
            &mp3Buffer,
            Int32(Engine.mp3BufferSizeSample)
        )
        
        let mp3buf = mp3Buffer.prefix(upTo: Int(encoded))
        file?.write(Data(mp3buf))
        
        if let radio = connectRequest {
            shout.connectTo(radio)
            connectRequest = nil
        }
        
        if shout_get_connected(shout.shout) == SHOUTERR_CONNECTED {
            let res = mp3buf.withUnsafeBytes { bytes -> Int32 in
                let x = bytes.bindMemory(to: UInt8.self)
                return shout_send(shout.shout, x.baseAddress, x.count)
            }
            
            if res != SHOUTERR_SUCCESS {
                print(shout_get_error(shout.shout) ?? "nil")
            }
        }
        
        
        let scaledValue = meterValue(data: floatData1)
        
        DispatchQueue.main.async {
            self.meterLevel = CGFloat(scaledValue)
        }
    }
}
