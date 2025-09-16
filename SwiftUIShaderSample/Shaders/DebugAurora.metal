//
//  DebugAurora.metal
//  SwiftUIShaderSample
//
//  Created by Claude on 2025/09/17.
//  Debug version for visible motion testing
//

#include <metal_stdlib>
using namespace metal;

// デバッグ用：動きが分かりやすいシンプルバージョン
[[ stitchable ]] half4 debugAurora(float2 position, half4 color, float time) {
    float2 p = position / 400.0;
    p = (p - 1.0) * 0.8;
    p.x *= 0.75;
    
    // シンプルな波（見やすい）
    float wave = sin(p.x * 2.0 + time * 3.0) * 0.5;
    
    // オーロラ帯
    float band = exp(-8.0 * abs(p.y + wave - 0.2));
    
    // 時間による色変化（デバッグ用）
    float3 col1 = float3(0.2, 1.0, 0.4);  // 緑
    float3 col2 = float3(0.4, 0.6, 1.0);  // 青
    float3 auroraColor = mix(col1, col2, sin(time * 2.0) * 0.5 + 0.5);
    
    // 明確な明滅
    float pulse = sin(time * 4.0) * 0.3 + 0.7;
    
    float3 result = auroraColor * band * pulse;
    
    return half4(half3(result), 1.0);
}