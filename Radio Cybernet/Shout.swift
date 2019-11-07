//
//  Shout.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 06/11/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import Foundation

class Shout {
    let shout : OpaquePointer?
    
    init() {
        shout_init()
        shout = shout_new()
    }
    
    func connectTo(_ configuration: RadioConfiguration) {
        shout_set_format(shout, UInt32(SHOUT_FORMAT_MP3))
        shout_set_protocol(shout, UInt32(SHOUT_PROTOCOL_HTTP))
        
        shout_set_port(shout, UInt16(configuration.port))
        
        _ = configuration.hostname.withCString {
            shout_set_host(shout, $0)
        }
        
        _ = configuration.password.withCString {
            shout_set_password(shout, $0)
        }
        
        _ = configuration.mount.withCString {
            shout_set_mount(shout, $0)
        }
        
        shout_open(shout)
    }
    
}
