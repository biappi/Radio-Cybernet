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
    var s = Float.zero
    
    for d in data {
        s += pow(d, 2)
    }
    
    return s / Float(data.count)
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

enum EngineState {
    case offline(status: String?)
    case connecting
    case connected
    case disconnecting
    
    var canGoLive: Bool {
        switch self {
        case .offline(_):    return true
        case .connecting:    return false
        case .connected:     return false
        case .disconnecting: return false
        }
    }
    
    var canDisconnect: Bool {
        switch self {
            case .offline(_):    return false
            case .connecting:    return false
            case .connected:     return true
            case .disconnecting: return false
        }
    }
}

class EngineInterface : ObservableObject {
    @Published var meterLevel = CGFloat(0)
    @Published var state = EngineState.offline(status: nil)

    var engine: RealEngine? = nil
    
    func disconnect() {
        engine?.disconnect()
    }
    
    func goLive(
        radio: RadioConfiguration,
        event: EventConfiguration
    ) {
        engine?.goLive(radio: radio, event: event)
    }
}

class RealEngine {
    
    static let audioBufferSizeSec     = 1
    static let audioBufferSizeSamples = 44100 * audioBufferSizeSec
    static let mp3BufferSizeSample    = Int(1.25 * Double(audioBufferSizeSamples) + 7200)
    
    let engine = AVAudioEngine()
    
    var lame: LAME?
    var shout: Shout?
    
    var floatData1 = [Float](repeating: 0, count: audioBufferSizeSamples)
    var mp3Buffer  = [UInt8](repeating: 0, count: mp3BufferSizeSample)

    let interface: EngineInterface
    
    init(interface: EngineInterface) {
        self.interface = interface
        lame = nil
        shout = nil
        interface.engine = self
    }
    
    func recordedFileURL(name: String) -> URL {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        
        let namePart = name == "" ? "\(name) - " : ""
        let datePart = formatter.string(from: Date())
        let filename = "\(namePart)\(datePart).mp3"
        
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .allDomainsMask)
            .first!
            .appendingPathComponent(filename)
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

    // one way communication to audio queue
    
    var semaphore         = DispatchSemaphore(value: 1)
    
    var file:               FileHandle?
    var connectRequest:     (RadioConfiguration, EventConfiguration)?
    
    var disconnectRequest = false
    var sendPackets       = false
    
    // -
    
    func goLive(
        radio: RadioConfiguration,
        event: EventConfiguration
    ) {
        guard interface.state.canGoLive else {
            return
        }
        
        lame = LAME(bitrate: radio.bitrate)
        
        semaphore.wait()
        defer { semaphore.signal() }
        
        interface.state = .connecting
        connectRequest = (radio, event)
                
        disconnectRequest = false
        sendPackets = false
    }
    
    func disconnect() {
        guard interface.state.canDisconnect else {
            return
        }
        
        semaphore.wait()
        defer { semaphore.signal() }

        interface.state = .disconnecting
        disconnectRequest = true
    }
        
    // - //
    
    func tap(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        let length        = Int(buffer.frameLength)
        let floatPointer1 = UnsafeMutableRawPointer(buffer.floatChannelData!.pointee)
        
        for sample in 0 ..< length {
            floatData1[sample] = sampleFromAudioBuffer(floatPointer1, bufferStride: buffer.stride, sampleIndex: sample)
        }
                
        semaphore.wait()
        defer { semaphore.signal() }

        if let (radio, event) = connectRequest, !disconnectRequest {
            connectRequest = nil
            
            if event.record {
                let url = recordedFileURL(name: event.name)
                
                FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
                file = try? FileHandle(forWritingTo: url)
            }
            else {
                file = nil
            }

            let shout = Shout()
            self.shout = shout
            
            let error = shout.connectTo(
                radio,
                description: event.name
            )
            
            sendPackets = error == nil
            
            DispatchQueue.main.async {
                if let error = error {
                    self.interface.state = .offline(status: error)
                }
                else {
                    self.interface.state = .connected
                }
            }
        }
        else if disconnectRequest {
            disconnectRequest = false
            sendPackets = false
            shout?.disconnect()
            shout = nil
            
            DispatchQueue.main.async {
                self.lame = nil
                self.interface.state = .offline(status: nil)
            }
        }
        
        if sendPackets, let lame = self.lame {
            let encoded = lame_encode_buffer_ieee_float(
                lame.lame,
                floatData1,
                floatData1,
                Int32(length),
                &mp3Buffer,
                Int32(RealEngine.mp3BufferSizeSample)
            )
            
            let mp3buf = mp3Buffer.prefix(upTo: Int(encoded))

            file?.write(Data(mp3buf))
    
            if let shout = self.shout {
                if let error = shout.send(mp3buf) {
                    sendPackets = false
                    DispatchQueue.main.async {
                        self.interface.state = .offline(status: error)
                    }
                }
            }
            else {
                print("shout non there when it should have")
                //                    sendPackets = false
            }
            
        }
        
        let scaledValue = meterValue(data: floatData1)
        
        DispatchQueue.main.async {
            self.interface.meterLevel = CGFloat(scaledValue)
        }
    }
}
