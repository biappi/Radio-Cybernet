//
//  AppDelegate.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 02/09/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import UIKit
import AVFoundation

func lame_test() {
    let lame = lame_init()
    lame_set_num_channels(lame, 2)
    lame_set_mode(lame, JOINT_STEREO)
    lame_set_in_samplerate(lame, 44100)
    lame_set_out_samplerate(lame, 44100)
    lame_set_VBR(lame, vbr_mtrh)
    lame_set_VBR_q(lame, 2)
}

func shoutcast_connection_test(
    radioUrl: String,
    port: Int,
    mount: String,
    password: String
) -> OpaquePointer?
{
    shout_init()
    
    let shout = shout_new()
    
    shout_set_format(shout, UInt32(SHOUT_FORMAT_MP3))
    shout_set_protocol(shout, UInt32(SHOUT_PROTOCOL_HTTP))
    shout_set_port(shout, UInt16(port))
    
    _ = radioUrl.withCString {
        shout_set_host(shout, $0)
    }

    _ = password.withCString {
        shout_set_password(shout, $0)
    }
    
    _ = mount.withCString {
        shout_set_mount(shout, $0)
    }

    return shout
}

let engine = AVAudioEngine()

func rms(data: UnsafeMutablePointer<Float>, count: Int) -> Float {
    return
        (0 ..< count)
            .map { data.advanced(by: Int($0)).pointee }
            .reduce(0) { (a, i) in a + powf(i, 2) }
            / Float(count)
}

func scalePower(power: Float, minDb: Float = 120) -> Float {
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

func meterValue(data: UnsafeMutablePointer<Float>, count: Int) -> Float {
    let rmsValue   = rms(data: data, count: count)
    let powerValue = 20 * log10(rmsValue)
    return scalePower(power: powerValue)
}

func sampleFromAudioBuffer(_ pointer: UnsafeMutableRawPointer, bufferStride: Int, sampleIndex: Int) -> Float {
    return pointer
        .advanced(by: bufferStride * sampleIndex * MemoryLayout<Float>.stride)
        .bindMemory(to: Float.self, capacity: 1)
        .pointee
}

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
    
    let lame = lame_init()
    lame_set_num_channels(lame, 2)
    lame_set_mode(lame, JOINT_STEREO)
    lame_set_in_samplerate(lame, 44100)
    lame_set_out_samplerate(lame, 44100)
    lame_set_VBR(lame, vbr_mtrh)
    lame_set_VBR_q(lame, 2)
    lame_init_params(lame)
    
    let audioBufferSizeSec     = 1
    let audioBufferSizeSamples = 44100 * audioBufferSizeSec
    let mp3BufferSizeSample    = Int(1.25 * Double(audioBufferSizeSamples) + 7200)
    
    var floatData1 = [Float](repeating: 0, count: audioBufferSizeSamples)
    var mp3Buffer  = [UInt8](repeating: 0, count: mp3BufferSizeSample)
    
    let url = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!.appendingPathComponent("DIOCANE")
    FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
    
    let x = try! FileHandle(forWritingTo: url)
    
    print(url.path)
    
    let shout = shoutcast_connection_test(
        radioUrl: "ZZZ",
        port: 8000,
        mount: "/test.mp3",
        password: "XXX"
    )

    shout_open(shout)
    
    engine.inputNode.installTap(onBus: 0, bufferSize: 0, format: nil) { (buffer, time) in

        let length        = Int(buffer.frameLength)
        
        let floatPointer1 = UnsafeMutableRawPointer(buffer.floatChannelData!.pointee)

        for sample in 0 ..< length {
            floatData1[sample] = sampleFromAudioBuffer(floatPointer1, bufferStride: buffer.stride, sampleIndex: sample)
        }

        let encoded = lame_encode_buffer_ieee_float(
            lame,
            floatData1,
            floatData1,
            Int32(length),
            &mp3Buffer,
            Int32(mp3BufferSizeSample)
        )
        
        let mp3buf = mp3Buffer.prefix(upTo: Int(encoded))
        x.write(Data(mp3buf))
        
        let res = mp3buf.withUnsafeBytes { bytes -> Int32 in
            let x = bytes.bindMemory(to: UInt8.self)
            return shout_send(shout, x.baseAddress, x.count)
        }
        
        if res != SHOUTERR_SUCCESS {
            print(shout_get_error(shout) ?? "nil")
        }

        let rmsValue    = floatData1
            .reduce(0) { (a, i) in a + powf(i, 2) }
            / Float(floatData1.count)
        
        let powerValue  = 20 * log10(rmsValue)
        let scaledValue = scalePower(power: powerValue)
        
        DispatchQueue.main.async {
            porcoddio.send(CGFloat(scaledValue))
        }
    }
    
    try! engine.start()
}

var i = 0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool
    {
        lame_test()
        engine_test()
    /*
        shoutcast_connection_test(
            radioUrl: "XXX",
            port: 8000,
            mount: "/test.mp3",
            password: "XXX"
        )
    */
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

