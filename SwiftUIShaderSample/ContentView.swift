//
//  ContentView.swift
//  SwiftUIShaderSample
//
//  Created by 本田輝 on 2024/05/15.
//

import CoreMotion
import SwiftUI
import Kingfisher



struct ChangeColorModifier: ViewModifier {
    @ObservedObject var manager: MotionManager
    
    func body(content: Content) -> some View {
        content
            .colorEffect(ShaderLibrary.slopeSeppenImage(.float(Float(manager.pitch)),.float(Float(manager.roll))))
    }
}

extension View {
    func colorChangeEffect(manager: MotionManager) -> some View {
        modifier(ChangeColorModifier(manager: manager))
    }
}

@available(iOS 18.0, *)
struct ContentView: View {
    @ObservedObject var manager: MotionManager
    @State private var showOrbs = false
    @State private var orbScales: [CGFloat] = [0, 0, 0, 0]
    @State private var orbOpacities: [Double] = [0, 0, 0, 0]
    @State private var orbInOrbit: [Bool] = [false, false, false, false]
    @State private var orbDisappearing: [Bool] = [false, false, false, false]
    @State private var pressLocation: CGPoint = .zero
    @State private var disappearLocation: CGPoint = .zero
    @State private var startTime: Date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { context in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    if showOrbs {
                        ForEach(0..<4, id: \.self) { index in
                            OrbView()
                                .scaleEffect(orbScales[index])
                                .opacity(orbOpacities[index])
                                .position(calculateOrbPosition(index: index, geometry: geometry, context: context))
                                .animation(.spring(response: 1.2, dampingFraction: 0.6), value: orbInOrbit[index])
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: orbDisappearing[index])
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .onEnded { value in
                            switch value {
                            case .second(true, let drag):
                                let location = drag?.location ?? CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
                                if !showOrbs {
                                    handleTap(location)
                                }
                            default:
                                break
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if showOrbs {
                                handleTap(value.location)
                            }
                        }
                )
            }
        }
    }
    
    private func calculateOrbPosition(index: Int, geometry: GeometryProxy, context: TimelineViewDefaultContext) -> CGPoint {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        if orbInOrbit[index] && !orbDisappearing[index] {
            // 円軌道上を回転
            let angle = Double(index) * .pi/2 + context.date.timeIntervalSince(startTime)
            return CGPoint(
                x: centerX + 120 * cos(angle),
                y: centerY + 120 * sin(angle)
            )
        } else if orbDisappearing[index] {
            // 消える時の位置（2回目のタップ位置）
            return disappearLocation
        } else {
            // 初期位置（最初のタップ位置）
            return pressLocation
        }
    }
    
    private func handleTap(_ location: CGPoint) {
        if !showOrbs {
            showOrbs = true
            startTime = Date()
            pressLocation = location
            
            // オーブを順番に出現させる
            for index in 0..<4 {
                orbInOrbit[index] = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                    // オーブを出現させる（タップ位置）
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        orbScales[index] = 1.0
                        orbOpacities[index] = 1.0
                    }
                    
                    // 少し遅れて円軌道に移動
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                            orbInOrbit[index] = true
                        }
                    }
                }
            }
        } else {
            // 消すためのタップ位置を記録
            disappearLocation = location
            
            for index in (0..<4).reversed() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(3 - index) * 0.1) {
                    // まず円軌道から新しいタップ位置に戻る
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        orbDisappearing[index] = true
                    }
                    
                    // 少し遅れて消える
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeIn(duration: 0.3)) {
                            orbScales[index] = 0
                            orbOpacities[index] = 0
                        }
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showOrbs = false
                // 状態をリセット
                for index in 0..<4 {
                    orbInOrbit[index] = false
                    orbDisappearing[index] = false
                }
            }
        }
    }
}

// オーブのコンポーネント
struct OrbView: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.cyan, .blue, .purple]),
                    center: .center,
                    startRadius: 3,
                    endRadius: 27
                )
            )
            .frame(width: 54, height: 54)
            .shadow(color: .cyan.opacity(0.8), radius: 20)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
            )
    }
}

// センサー情報表示のコンポーネント
struct SensorInfoView: View {
    @ObservedObject var motionManager: MotionManager
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Rotation Rate")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("X: \(motionManager.rotationRateX, specifier: "%.2f")")
                    Text("Y: \(motionManager.rotationRateY, specifier: "%.2f")")
                    Text("Z: \(motionManager.rotationRateZ, specifier: "%.2f")")
                }
                .foregroundColor(.white.opacity(0.8))
                .font(.system(.body, design: .monospaced))
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            Text("Angles")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Pitch: \(motionManager.pitch, specifier: "%.2f")")
                    Text("Roll: \(motionManager.roll, specifier: "%.2f")")
                    Text("Yaw: \(motionManager.yaw, specifier: "%.2f")")
                }
                .foregroundColor(.white.opacity(0.8))
                .font(.system(.body, design: .monospaced))
            }
        }
    }
}
