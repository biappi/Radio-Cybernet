//
//  SwiftUIView.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 14/10/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import SwiftUI
import Combine

extension RadioConfiguration {
    
    var portString : String {
        get {
            String(port)
        }
        
        set {
            NumberFormatter().number(from: newValue).map {
                self.port = Int(truncating: $0)
            }
        }
    }
    
}

extension EngineState {
    
    var string: String {
        switch self {
        case .offline(let status):
            return "Offline" + (status.map { " - \($0)" } ?? "")
        case .connecting:     return "Connecting"
        case .connected:      return "Connected"
        case .disconnecting:  return "Disconnecting"
        }
    }
    
    var didConnect: Bool {
        switch self {
        case .connected: return true
        default:         return false
        }
    }
    
}

struct SwiftUIView: View {
    
    @EnvironmentObject var engine: RealEngine

    @State private var level      = CGFloat(0)
    
    @State private var radioConf  = RadioConfiguration()
    @State private var eventConf  = EventConfiguration()
    
    func loadConfiguration() {
        let d = UserDefaults.standard
        
        d.register(defaults: [
            "port": 8000,
            "record": false
        ])
        
        radioConf.name     = d.string (forKey: "radioName") ?? ""
        radioConf.hostname = d.string (forKey: "hostname")  ?? ""
        radioConf.port     = d.integer(forKey: "port")
        radioConf.mount    = d.string (forKey: "mount")     ?? ""
        radioConf.password = d.string (forKey: "password")  ?? ""
        
        eventConf.name     = d.string (forKey: "eventName") ?? ""
        eventConf.record   = d.bool   (forKey: "record")
    }
    
    func saveConfiguraion() {
        let d = UserDefaults.standard

        d.set(radioConf.name,     forKey: "radioName")
        d.set(radioConf.hostname, forKey: "hostname")
        d.set(radioConf.port,     forKey: "port")
        d.set(radioConf.mount,    forKey: "mount")
        d.set(radioConf.password, forKey: "password")
        
        d.set(eventConf.name,     forKey: "eventName")
        d.set(eventConf.record,   forKey: "record")
    }
    
    var body: some View {

        VStack {
            HStack {
                Form {
                    Section(header: Text("Radio Settings")) {

                        HStack {
                            Text("Name")
                                .padding(.bottom, 2)
                            
                            Spacer()
                            TextField("Example Radio", text: $radioConf.name)
                        }

                        HStack {
                            Text("Hostname")
                                .padding(.bottom, 2)
                            
                            Spacer()
                            TextField("radio.example.com", text: $radioConf.hostname)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                            
                            Text(":")
                                .padding(.bottom, 2)
                            
                            TextField("8080", text: $radioConf.portString
                            )
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 50)
                            
                        }

                        HStack {
                            Text("Mountpoint")
                                .padding(.bottom, 2)
                            
                            Spacer()
                            TextField("/radio.mp3", text: $radioConf.mount)
                                .autocapitalization(.none)
                        }

                        HStack {
                            Text("Password")
                                .padding(.bottom, 2)

                            Spacer()
                            SecureField("password", text: $radioConf.password)
                        }

                    }
                    
                    Section(header: Text("Event")) {
                        TextField("Event name", text: $eventConf.name)
                        Toggle("Save recording", isOn: $eventConf.record)
                    }
                    
                    Section {
                        if !engine.state.canDisconnect {
                            Button(action: goLive) {
                                Text("Go Live")
                            }
                            .disabled(!engine.state.canGoLive)
                        }
                        else {
                            Button(action: engine.disconnect) {
                                Text("Disconnect")
                            }
                        }
                    }
                }
            }
            
            VStack {
                HStack {
                    Text(engine.state.string)
                }
                .padding(.bottom)
                
                Meter(level: engine.meterLevel)
            }
                .padding([.horizontal, .vertical])
                
        }
        .onAppear(perform: loadConfiguration)
        .onReceive(engine.$state) {
            if $0.didConnect {
                self.saveConfiguraion()
            }
        }
    }
    
    func goLive() {
        engine.goLive(radio: radioConf, event: eventConf)
    }
    
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}

struct Meter: View {
    var level : CGFloat
    
    var body: some View {
        GeometryReader { metrics in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.blue)
                
                Rectangle()
                    .frame(width: metrics.size.width * self.level)
                    .foregroundColor(.yellow)
            }
        }
        .frame(height: CGFloat(40))
    }
}
