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

extension Engine.State {
    var string: String {
        switch self {
        case .offline(let status):
            return "Offline" + (status.map { " - \($0)" } ?? "")
        case .connecting:     return "Connecting"
        case .connected:      return "Connected"
        case .disconnecting:  return "Disconnecting"
        }
    }
}

struct SwiftUIView: View {
    
    @EnvironmentObject var engine: Engine

    @State private var level      = CGFloat(0)
    
    @State private var radioConf  = RadioConfiguration()
    @State private var eventConf  = EventConfiguration()
    
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
                            
                            Text(":")
                                .padding(.bottom, 2)
                            
                            TextField("8080", text: $radioConf.portString
                            )
                                .frame(maxWidth: 50)
                            
                        }

                        HStack {
                            Text("Mountpoint")
                                .padding(.bottom, 2)
                            
                            Spacer()
                            TextField("/radio.mp3", text: $radioConf.mount)
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
