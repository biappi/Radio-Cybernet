//
//  Engine.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 06/11/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import Foundation
import AVFoundation

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

class Engine {
    
    static let audioBufferSizeSec     = 1
    static let audioBufferSizeSamples = 44100 * audioBufferSizeSec
    static let mp3BufferSizeSample    = Int(1.25 * Double(audioBufferSizeSamples) + 7200)
    
    let engine = AVAudioEngine()
    let lame   = LAME()
    let shout  = Shout()
    
    var file  : FileHandle?

    var floatData1 = [Float](repeating: 0, count: audioBufferSizeSamples)
    var mp3Buffer  = [UInt8](repeating: 0, count: mp3BufferSizeSample)

    func engine_test() {
        let  session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.record)
        try! session.setActive(true)
        
        print(engine.inputNode)
        
        for i in 0 ..< engine.inputNode.numberOfInputs {
            print(i)
            print(engine.inputNode.name(forInputBus: i) ?? "noname")
            print(engine.inputNode.inputFormat(forBus: i))
        }

        for i in 0 ..< engine.inputNode.numberOfOutputs {
            print(i)
            print(engine.inputNode.name(forOutputBus: i) ?? "noname")
            print(engine.inputNode.outputFormat(forBus: i))
        }
                
        let url = FileManager
            .default
            .urls(for: .documentDirectory, in: .allDomainsMask)
            .first!
            .appendingPathComponent("DIOCANE")
        
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        file = try? FileHandle(forWritingTo: url)
        
        print(url.path)
        
        engine.inputNode.installTap(onBus: 0, bufferSize: 0, format: nil, block: tap)

        shout_open(shout.shout)
            
        try! engine.start()
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
        
        let res = mp3buf.withUnsafeBytes { bytes -> Int32 in
            let x = bytes.bindMemory(to: UInt8.self)
            return shout_send(shout.shout, x.baseAddress, x.count)
        }
        
        if res != SHOUTERR_SUCCESS {
            print(shout_get_error(shout.shout) ?? "nil")
        }
        
        let scaledValue = meterValue(data: floatData1)
        
        DispatchQueue.main.async {
            porcoddio.send(CGFloat(scaledValue))
        }
    }
}
