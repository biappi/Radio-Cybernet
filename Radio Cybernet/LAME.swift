//
//  LAME.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 06/11/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import Foundation

class LAME {
    let lame : OpaquePointer?
    
    init() {
        lame = lame_init()
        lame_set_num_channels(lame, 2)
        lame_set_mode(lame, JOINT_STEREO)
        lame_set_in_samplerate(lame, 44100)
        lame_set_out_samplerate(lame, 44100)
        lame_set_VBR(lame, vbr_mtrh)
        lame_set_VBR_q(lame, 2)
        lame_init_params(lame)
    }    
}
