//
//  ContentView.swift
//  SwiftUIShaderSample
//
//  Created by 本田輝 on 2024/05/15.
//

import CoreMotion
import SwiftUI
import Kingfisher

@available(iOS 18.0, *)
struct ContentView: View {
    @ObservedObject var manager: MotionManager
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = Float(context.date.timeIntervalSince1970)
            
            ZStack {
                Color.black.ignoresSafeArea()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .colorEffect(ShaderLibrary.realisticAurora(.float(time)))
        }
    }
}