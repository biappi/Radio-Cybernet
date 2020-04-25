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

extension Bitrate {
    var string: String {
        return "\(rawValue) kbps"
    }
}

struct SwiftUIView: View {
    
    @EnvironmentObject var engine: EngineInterface

    @State private var level      = CGFloat(0)
    
    @State private var radioConf  = RadioConfiguration()
    @State private var eventConf  = EventConfiguration()
    
    enum PrefsMaxWidth: Preference {}
    let prefsMaxWidth = GeometryPreferenceReader(
        key: AppendValue<PrefsMaxWidth>.self,
        value: { [$0.size.width] }
    )
    
    @State var prefsMaxWidthValue: CGFloat? = nil

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

    @State var settingsCollapsed = false
    @State var eventCollapsed = false
        
    var body: some View {

        VStack(spacing: 0) {
            NavigationView {
            HStack {
                Form {
                    Section(header: Header("Radio Settings", toggle: $settingsCollapsed)) {

                        if !settingsCollapsed {
                            HStack {
                                Text("Name")
                                    .padding(.bottom, 2)
                                    .read(prefsMaxWidth)
                                    .frame(width: prefsMaxWidthValue, alignment: .topLeading)
                                
                                Spacer()
                                TextField("Example Radio", text: $radioConf.name)
                            }
                            
                            HStack {
                                Text("Hostname")
                                    .padding(.bottom, 2)
                                    .read(prefsMaxWidth)
                                    .frame(width: prefsMaxWidthValue, alignment: .topLeading)
                                
                                Spacer()
                                TextField("radio.example.com", text: $radioConf.hostname)
                                    .autocapitalization(.none)
                                    .keyboardType(.URL)
                                
                                Text(":")
                                    .padding(.bottom, 2)
                                
                                TextField("8080", text: $radioConf.portString)
                                    .keyboardType(.numberPad)
                                    .frame(maxWidth: 50)
                                
                            }
                            
                            HStack {
                                Text("Mountpoint")
                                    .padding(.bottom, 2)
                                    .read(prefsMaxWidth)
                                    .frame(width: prefsMaxWidthValue, alignment: .topLeading)
                                
                                Spacer()
                                TextField("/radio.mp3", text: $radioConf.mount)
                                    .autocapitalization(.none)
                            }
                            
                            HStack {
                                Text("Password")
                                    .padding(.bottom, 2)
                                    .read(prefsMaxWidth)
                                    .frame(width: prefsMaxWidthValue, alignment: .topLeading)
                                
                                Spacer()
                                SecureField("password", text: $radioConf.password)
                            }
                            
                            
                            Picker(selection: $radioConf.bitrate, label: Text("Bitrate")) {
                                    ForEach(Bitrate.allCases, id: \.self) {
                                        Text($0.string)
                                    }
                                    .navigationBarTitle(Text("Encoding bitrate"))
                                }
                                
                        }

                    }
                        .disabled(engine.state.canDisconnect)
                        .navigationBarTitle(Text("Stream!"))
                    
                    Section(header: Header("Event", toggle: $eventCollapsed)) {
                        if !eventCollapsed {
                            TextField("Event name", text: $eventConf.name)
                            Toggle("Save recording", isOn: $eventConf.record)
                        }
                    }
                        .disabled(engine.state.canDisconnect)

                    
                    Section {
                        if !engine.state.canDisconnect {
                            Button(action: goLive) {
                                Text("Go Live")
                            }
                        }
                        else {
                            Button(action: engine.disconnect) {
                                Text("Disconnect")
                            }
                        }
                    }
                    .listRowBackground(engine.state.canDisconnect ? Color.red : nil)
                    .foregroundColor(engine.state.canDisconnect ? Color.white : nil)
                }
                .navigationBarTitle("Stream!")

            }
            .assignMaxPreference(for: prefsMaxWidth.key, to: $prefsMaxWidthValue)
            }
            
            InfoPaneView()
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

struct Header: View {
    
    @Binding var toggle: Bool
    
    let text: String
    
    init(_ text: String, toggle: Binding<Bool>) {
        self.text = text
        self._toggle = toggle
    }
    
    var body: some View {
        HStack {
            Text(toggle ? "▼" : "▲" )
            Text(text)
        }
        .onTapGesture {
            self.toggle.toggle()
        }
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
        .frame(height: CGFloat(20))
    }
}

struct InfoPaneView: View {
    
    @EnvironmentObject var engine: EngineInterface

    enum MeterMaxWidthPreference: Preference {}
    let meterMaxWidth = GeometryPreferenceReader(
        key: AppendValue<MeterMaxWidthPreference>.self,
        value: { [$0.size.width] }
    )
    
    @State var meterMaxWidthValue: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Network")
                    .multilineTextAlignment(.leading)
                    .read(meterMaxWidth)
                    .frame(width: meterMaxWidthValue, alignment: .topLeading)
                
                Text(engine.state.string)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
            }
            
            HStack {
                Text("Input")
                    .multilineTextAlignment(.leading)
                    .read(meterMaxWidth)
                    .frame(width: meterMaxWidthValue, alignment: .topLeading)
                
                
                Meter(level: engine.meterLevel)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding([.horizontal, .vertical])
        .background(Color.white)
        .clipped()
        .shadow(color: .gray, radius: 1, x: 0, y: -3)
        .assignMaxPreference(for: meterMaxWidth.key, to: $meterMaxWidthValue)
    }
    
}

// Preview Providers

struct SwiftUIView_Previews: PreviewProvider {
    
    static let interface = EngineInterface()
    
    static var previews: some View {
        
        Group {
            SwiftUIView()
                .environmentObject(interface)
                .previewDevice(PreviewDevice(rawValue: "iPhone SE"))
                .previewDisplayName("iPhone SE")
            
            SwiftUIView()
                .environmentObject(interface)
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max")
            
        }
    }
    
}

