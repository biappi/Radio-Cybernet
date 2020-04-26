//
//  Configuration.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 26/04/2020.
//  Copyright © 2020 Antonio Malara. All rights reserved.
//

import Foundation

struct RadioConfiguration {
    var name:     String  = ""
    var hostname: String  = ""
    var port:     Int     = 80
    var mount:    String  = ""
    var password: String  = ""
    var bitrate:  Bitrate = .bitrate128
}

struct EventConfiguration {
    var name:   String = ""
    var record: Bool = true
}

func LoadConfiguration() -> (RadioConfiguration, EventConfiguration) {
    var (radioConf, eventConf) = (RadioConfiguration(), EventConfiguration())
    
    let d = UserDefaults.standard
    
    d.register(defaults: [
        "port": 8000,
        "record": false
    ])
    
    radioConf.name     = d.string (forKey: "radioName") ?? ""
    radioConf.hostname = d.string (forKey: "hostname")  ?? ""
    radioConf.port     = d.integer(forKey: "port")
    radioConf.mount    = d.string (forKey: "mount")     ?? ""
    radioConf.bitrate  = d.object (forKey: "bitrate")
                            .flatMap { ($0 as? NSNumber)?.intValue }
                            .flatMap(Bitrate.init)
                            ?? .bitrate128
    eventConf.name     = d.string (forKey: "eventName") ?? ""
    eventConf.record   = d.bool   (forKey: "record")
    
    let query: [String: Any] = [
        kSecClass            as String: kSecClassInternetPassword,
        kSecAttrServer       as String: "\(radioConf.hostname):\(radioConf.port)",
        kSecReturnAttributes as String: true,
        kSecMatchLimit       as String: kSecMatchLimitOne,
        kSecReturnData       as String: true,
    ]
    
    var item : CFTypeRef?
    if
        SecItemCopyMatching(query as CFDictionary, &item) == noErr,
        let existingItem = item as? [String : Any],
        let passwordData = existingItem[kSecValueData as String] as? Data,
        let password = String(data: passwordData, encoding: String.Encoding.utf8)
    {
        radioConf.password = password
    }
    
    return (radioConf, eventConf)
}

func SaveConfiguraion(radioConf: RadioConfiguration, eventConf: EventConfiguration) {
    let d = UserDefaults.standard
    
    d.set(radioConf.name,     forKey: "radioName")
    d.set(radioConf.hostname, forKey: "hostname")
    d.set(radioConf.port,     forKey: "port")
    d.set(radioConf.mount,    forKey: "mount")
    d.set(radioConf.bitrate.rawValue,
                              forKey: "bitrate")
    d.set(eventConf.name,     forKey: "eventName")
    d.set(eventConf.record,   forKey: "record")
    
    let query: [String: Any] = [
        kSecClass      as String: kSecClassInternetPassword,
        kSecAttrServer as String: "\(radioConf.hostname):\(radioConf.port)",
    ]
    
    let attributes: [String: Any] = [
        kSecValueData  as String: radioConf.password.data(using: .utf8)!,
    ]
    
    let s = SecItemAdd(query as CFDictionary, nil)
    
    if s == errSecDuplicateItem {
        let s = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if s != noErr {
            print("error updating pass \(s)")
        }
    }
    else {
        print("error saving pass \(s)")
    }
}
