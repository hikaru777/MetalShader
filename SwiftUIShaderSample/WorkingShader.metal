//
//  WorkingShader.metal
//  SwiftUIShaderSample
//
//  Created by Claude on 2025/09/17.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 simpleAurora(float2 position, half4 color, float time) {
    // 正規化座標
    float2 p = position / 400.0 - 1.0;
    p.x *= 0.75; // アスペクト比調整
    
    // シンプルな波動
    float wave1 = sin(p.x * 2.0 + time * 2.0) * 0.3;
    float wave2 = sin(p.x * 3.0 - time * 1.5) * 0.2;
    
    // オーロラ帯
    float y = p.y + wave1 + wave2;
    float band = exp(-6.0 * abs(y - 0.2));
    
    // 色の変化
    float colorShift = sin(time * 1.5) * 0.5 + 0.5;
    float3 green = float3(0.2, 1.0, 0.4);
    float3 blue = float3(0.3, 0.7, 1.0);
    float3 auroraColor = mix(green, blue, colorShift);
    
    // 明滅
    float pulse = sin(time * 3.0) * 0.3 + 0.7;
    
    // 最終色
    float3 result = auroraColor * band * pulse;
    
    return half4(half3(result), 1.0);
}