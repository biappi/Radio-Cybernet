//
//  Shout.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 06/11/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import Foundation

class Shout {
    fileprivate let shout : OpaquePointer?
    
    struct ShoutError : Error {
        var errno:       Int
        var description: String
    }
    
    init() {
        shout_init()
        shout = shout_new()
    }
    
    func connectTo(_ configuration: RadioConfiguration, description: String) -> String? {
        shout_set_format(shout, UInt32(SHOUT_FORMAT_MP3))
        shout_set_protocol(shout, UInt32(SHOUT_PROTOCOL_HTTP))
        
        shout_set_port(shout, UInt16(configuration.port))
        
        _ = configuration.hostname.withCString {
            shout_set_host(shout, $0)
        }

        if !configuration.user.isEmpty {
            _ = configuration.user.withCString {
                shout_set_user(shout, $0)
            }
        }

        _ = configuration.password.withCString {
            shout_set_password(shout, $0)
        }
        
        _ = configuration.mount.withCString {
            shout_set_mount(shout, $0)
        }
        
        _ = configuration.name.withCString {
            shout_set_name(shout, $0)
        }

        _ = description.withCString {
            shout_set_description(shout, $0)
        }

        let ret = shout_open(shout)
        
        if ret != SHOUTERR_SUCCESS {
            let error = String(cString: shout_get_error(shout))
            return error
        }
        else {
            return nil
        }
    }
    
    deinit {
        shout_free(shout)
    }
    
    func disconnect() {
        shout_close(shout)
    }
    
    func send(_ mp3buf: ArraySlice<UInt8>) -> String? {
        let ret = mp3buf.withUnsafeBytes { bytes -> Int32 in
            let x = bytes.bindMemory(to: UInt8.self)
            return shout_send(shout, x.baseAddress, x.count)
        }
        
        if ret != SHOUTERR_SUCCESS {
            let error = String(cString: shout_get_error(shout))
            return error
        }
        else {
            return nil
        }
    }
    
}
