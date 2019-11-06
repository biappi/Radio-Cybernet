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
    @State private var level : CGFloat = 0
    
    var body: some View {
        VStack {
            Text("\(level)")
            Meter(level: $level)            
            Slider(value: $level)
        }
        .padding([.leading, .trailing])
        .onReceive(porcoddio) { self.level = $0 }
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
