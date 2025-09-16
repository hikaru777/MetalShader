//
//  AuroraShader.metal
//  SwiftUIShaderSample
//
//  Created by Claude on 2025/09/17.
//  GLSLfan Aurora Shader converted to Metal
//

#include <metal_stdlib>
using namespace metal;

// ======== Tunable knobs (動きを強調) ========
constant float WAVE_AMP   = 0.8;    // 横方向うねりの振幅（大幅増加）
constant float WAVE_FREQ  = 1.8;    // うねりの周波数（低く）
constant float WAVE_SPEED = 3.5;    // うねりの流速（大幅高速化）
constant float SHEAR_AMP  = 0.6;    // 帯のせん断(斜め揺れ)強さ（大幅増加）
constant float CURL_STR   = 1.2;    // カールノイズによる流れの強さ（倍増）
constant float STRIPE_GAIN= 0.85;   // 縦スジの主張（少し下げて動きを強調）
constant float PULSE_SP   = 5.0;    // 明滅スピード（倍増）

// ======== ユーティリティ関数群 ========
float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i + float2(0, 0));
    float b = hash(i + float2(1, 0));
    float c = hash(i + float2(0, 1));
    float d = hash(i + float2(1, 1));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(float2 p) {
    float s = 0.0;
    float a = 0.5;
    float2x2 m = float2x2(1.35, 1.12, -1.12, 1.35);
    
    for (int i = 0; i < 6; i++) {
        s += a * noise(p);
        p = m * p + 0.015;
        a *= 0.5;
    }
    return s;
}

float2 grad(float2 p) {
    float e = 0.001;
    return float2(
        noise(p + float2(e, 0)) - noise(p - float2(e, 0)),
        noise(p + float2(0, e)) - noise(p - float2(0, e))
    ) / (2.0 * e);
}

float2 curl(float2 p) {
    float2 g = grad(p);
    return float2(-g.y, g.x);
}

float3 auroraColor(float h) {
    float3 c1 = float3(0.05, 0.85, 0.35);  // 緑
    float3 c2 = float3(0.10, 0.75, 0.95);  // シアン
    float3 c3 = float3(0.85, 0.35, 0.95);  // マゼンタ
    
    return mix(
        mix(c1, c2, smoothstep(0.15, 0.55, h)),
        c3, 
        smoothstep(0.55, 1.00, h)
    );
}

float glow(float d, float r, float k) {
    return pow(clamp(1.0 - d / r, 0.0, 1.0), k);
}

// ======== メインオーロラシェーダー ========
[[ stitchable ]] half4 realisticAurora(float2 position, half4 color, float time) {
    // SwiftUIの座標系に対応（positionは実ピクセル座標）
    // スケールファクターで正規化
    float2 p = position / 400.0; // スケール調整
    p = (p - 1.0) * 0.8; // 中心化とズーム
    
    // アスペクト比の調整（概算）
    p.x *= 0.75;
    
    // 天頂のカーブ(弱め)
    p.y += 0.10 * (p.x * p.x);
    
    // 夜空ベース
    float3 col = float3(0.012, 0.018, 0.035);
    col += 0.03 * (1.0 - smoothstep(-0.8, 0.6, p.y));
    
    // ---- 波打ち(なみなみ)作成：横方向メアンダ + 斜めシア ----
    // 横方向のうねり（時間で流れるSin）- より大きな動き
    float wave = sin(p.x * WAVE_FREQ + time * WAVE_SPEED) + 
                 0.5 * sin(p.x * (WAVE_FREQ * 1.7) - time * (WAVE_SPEED * 0.6)) +
                 0.3 * sin(p.x * (WAVE_FREQ * 0.8) + time * (WAVE_SPEED * 1.5)); // 追加波
    wave *= WAVE_AMP;
    
    // 斜めシア（帯全体の傾き変化）- より速く動く
    float shear = (p.x) * SHEAR_AMP * sin(time * 1.0 + p.x * 1.2);
    
    // オーロラ帯の座標（なみなみ適用）
    float2 base = float2(p.x * 1.35, (p.y + wave + shear) * 1.8);
    
    // カールノイズで流れ付与（帯の流動感）- より速い流れ
    float2 flow = float2(0.22, 0.0) + CURL_STR * curl(base * 0.55 + float2(0.0, time * 0.15));
    float2 q = base + flow * (0.55 + 0.45 * sin(time * 0.8));
    
    // 帯の中心ガウス（中心少し上）
    float band = exp(-7.5 * abs(q.y - 0.18));
    
    // 縦スジ + うねり（強めに出す）- より速い動き
    float wav = fbm(q * 1.05 + float2(0.0, time * 0.3));
    float stripe = fbm(float2(q.x * 2.4, q.y * 3.4 - time * 2.0));
    stripe = mix(stripe, stripe * stripe, 0.35);     // コントラストを少し上げる
    stripe *= STRIPE_GAIN;
    
    // 明滅
    float pulse = 0.52 + 0.48 * sin(time * PULSE_SP + fbm(q * 2.1) * 3.14159);
    
    // 濃度（なみなみ + スジ + 帯）
    float dens = band * smoothstep(0.12, 0.95, stripe * 0.9 + wav * 0.6);
    dens *= (0.6 + 0.4 * pulse);
    dens = clamp(dens, 0.0, 1.0);
    
    // 高度→色相遷移
    float h = clamp((q.y + 0.9) * 0.55 + 0.22 * wav, 0.0, 1.0);
    float3 aCol = auroraColor(h);
    
    // コア
    float3 aur = aCol * (0.66 * dens);
    
    // 外郭グロー（なみなみでエッジも揺れる）
    float dEdge = max(0.0, 0.36 - abs(q.y - 0.18));
    float halo = glow(dEdge, 0.36, 1.8) * (0.35 + 0.65 * pulse);
    aur += aCol * halo * 0.65;
    
    // 奥行き用の薄い第2層（位相ずらしで干渉=波感UP）- より速い動き
    float2 b2 = base * 0.86 + float2(0.0, 0.08);
    b2.x += 0.12 * sin(b2.y * 3.2 - time * 1.2);         // 2層目だけ別位相の横波（2倍の振幅・3倍速）
    float d2 = exp(-6.0 * abs(b2.y - 0.16)) * (0.55 + 0.45 * fbm(b2 * 2.4 - float2(0.0, time * 1.5)));
    float3 aur2 = auroraColor(clamp((b2.y + 0.9) * 0.55, 0.0, 1.0)) * d2 * 0.34;
    
    // 加算
    col += aur2 + aur;
    
    // 星（控えめ）
    float2 sp = p * 2.6;
    float stars = step(0.9977, hash(floor(sp * 200.0))) * (0.2 + 0.8 * hash(sp + float2(time)));
    col += float3(stars) * smoothstep(0.0, 0.4, p.y);
    
    // トーンマップ
    col = clamp(col, 0.0, 10.0);
    col = 1.0 - exp(-col * 1.6);
    col = pow(clamp(col, 0.0, 1.0), float3(0.92));
    
    return half4(half3(col), 1.0);
}

// 従来のオーロラシェーダー（後方互換）
[[ stitchable ]] half4 aurora(float2 position, half4 color, float time, float pitch, float roll) {
    return realisticAurora(position, color, time);
}

[[ stitchable ]] half4 auroraAdvanced(float2 position, half4 color, float time, float pitch, float roll) {
    return realisticAurora(position, color, time);
}