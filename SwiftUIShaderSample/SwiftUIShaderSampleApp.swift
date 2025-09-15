//
//  SwiftUIShaderSampleApp.swift
//  SwiftUIShaderSample
//
//  Created by 本田輝 on 2024/05/15.
//

import SwiftUI

@main
struct SwiftUIShaderSampleApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 18.0, *) {
                ContentView(manager: .init())
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
