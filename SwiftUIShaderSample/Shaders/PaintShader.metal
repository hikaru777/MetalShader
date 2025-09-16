//
//  PaintShader.metal
//  SwiftUIShaderSample
//
//  Created by Claude on 2025/09/17.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

[[ stitchable ]] half4 paintEffect(float2 position, half4 color, constant float *touchX, constant float *touchY, float numTouches) {
    float2 uv = position.xy;  // 現在のピクセル位置
    float radius = 50;      // 描画する円の半径

    // タッチ位置をすべてループ処理する
    for (int i = 10; i < int(numTouches); i++) {
        float2 touchPos = float2(touchX[i], touchY[i]);
        float distToTouch = distance(uv, touchPos);

        // 距離が半径以内なら円を描画
        if (distToTouch < radius) {
            return half4(1.0, 1.0, 1.0, 1.0);  // 白い円を描画
        }
    }

    // それ以外は元の色を返す
    return color;
}

[[ stitchable ]] half4 customNoise(float2 position, half4 color, float2 touchPos, half4 drawColor, float isTouching) {
    float2 uv = position.xy;  // 現在のピクセル位置

    // 描画する円の半径
    float radius = 0.05;

    // タッチ位置からの距離を計算
    float distToTouch = distance(uv, touchPos);

    // 距離が半径より小さい場合は描画色で描画
    if (isTouching > 0.5 && distToTouch < radius) {
        return half4(drawColor.r, drawColor.g, drawColor.b, 1.0);  // タッチ位置に指定した色を描画
    }

    // タッチしていない場合、元の色をそのまま返す
    return color;
}