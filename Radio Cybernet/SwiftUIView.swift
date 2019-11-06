//
//  SwiftUIView.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 14/10/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import SwiftUI
import Combine

var porcoddio = PassthroughSubject<CGFloat, Never>()

struct SwiftUIView: View {
    
    @State private var level      = CGFloat(0)

    @State private var name       = ""
    @State private var hostname   = ""
    @State private var port       = ""
    @State private var mountpoint = ""
    @State private var password   = ""
    
    @State private var eventName  = ""
    @State private var saveFile   = true

    var body: some View {
        VStack {
            HStack {
                Form {
                    Section(header: Text("Radio Settings")) {

                        HStack {
                            Text("Name")
                                .padding(.bottom, 2)
                            Spacer()
                            TextField("Example Radio", text: $mountpoint)
                        }

                        HStack {
                            Text("Hostname")
                                .padding(.bottom, 2)
                            
                            Spacer()
                            TextField("radio.example.com", text: $hostname)
                            Text(":")
                                .padding(.bottom, 2)
                            TextField("8080", text: $port)
                                .frame(maxWidth: 50)
                            
                        }

                        HStack {
                            Text("Mountpoint")
                                .padding(.bottom, 2)
                            Spacer()
                            TextField("/radio.mp3", text: $mountpoint)

                        }

                        HStack {
                            Text("Password")
                                .padding(.bottom, 2)

                            Spacer()
                            SecureField("password", text: $hostname)
                        }

                    }
                    
                    Section(header: Text("Event")) {
                        TextField("Event name", text: $eventName)
                        Toggle("Save recording", isOn: $saveFile)

                    }
                    
                    Section {
                        Button(action: { },
                               label: { Text("Go Live") } )
                    }
                }
            }
            
            Meter(level: $level)
                .padding([.horizontal, .vertical])
                .onReceive(porcoddio) { self.level = $0 }
        }
    }
    
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}

struct Meter: View {
    @Binding var level : CGFloat
    
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
