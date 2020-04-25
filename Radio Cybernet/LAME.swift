//
//  LAME.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 06/11/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import Foundation

enum Bitrate : Int, CaseIterable {
    case bitrate320 = 320
    case bitrate256 = 256
    case bitrate224 = 224
    case bitrate192 = 192
    case bitrate160 = 160
    case bitrate128 = 128
    case bitrate112 = 112
    case bitrate96  = 96
    case bitrate80  = 80
    case bitrate64  = 64
    case bitrate48  = 48
    case bitrate32  = 32
}

class LAME {
    let lame : OpaquePointer?
    
    init(bitrate: Bitrate) {
        lame = lame_init()
        
        if lame_set_num_channels(lame, 2) != 0 {
            print("set num channels no")
        }
        
        if lame_set_mode(lame, JOINT_STEREO) != 0 {
            print("set mode no")
        }
        
        if lame_set_in_samplerate(lame, 44100) != 0 {
            print("set in smplerate no")
        }
        
        if lame_set_out_samplerate(lame, 44100) != 0 {
            print("set out samplerate no")
        }
        
        if lame_set_VBR(lame, vbr_off) != 0 {
            print("set vbr no")
        }
        
        if lame_set_brate(lame, Int32(bitrate.rawValue)) != 0 {
            print("set brate no")
        }
        
        if lame_init_params(lame) != 0 {
            print("init params no")
        }
    }
    
    deinit {
        lame_close(lame)
    }
    
}
