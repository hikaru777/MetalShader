//
//  MotionManager.swift
//  SwiftUIShaderSample
//
//  Created by 本田輝 on 2024/05/29.
//

import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    
    @Published var rotationRateX: Double = 0.0
    @Published var rotationRateY: Double = 0.0
    @Published var rotationRateZ: Double = 0.0
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var yaw: Double = 0.0
    
    init() {
        startMotionUpdates()
    }
    
    func startMotionUpdates() {
            if motionManager.isDeviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = 0.01
                motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                    guard let self = self, let data = data else { return }
                    
                    // 角速度の更新
                    self.rotationRateX = data.rotationRate.x
                    self.rotationRateY = data.rotationRate.y
                    self.rotationRateZ = data.rotationRate.z
                    
                    // 角度の更新
                    self.pitch = data.attitude.pitch
                    self.roll = data.attitude.roll
                    self.yaw = data.attitude.yaw
                }
            }
        }
    
    func stopGyroscope() {
        motionManager.stopGyroUpdates()
    }
}
