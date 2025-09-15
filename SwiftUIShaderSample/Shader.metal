//
//  Shader.metal
//  SwiftUIShaderSample
//
//  Created by 本田輝 on 2024/05/15.
//

//下に行くほど新しい試作品

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 sampleGradient(float2 position,
                                      half4 color,
                                      float time) {
    // 元の色(color)を時間経過(time)で変化させた色を返している
    //    float gray = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
    float gray3 = (color.r + color.g + color.b) / 3;
    return half4(gray3, gray3, gray3, 1.0);
    
}

[[ stitchable ]] half4 gradient2d(float2 position, half4 color, float sliderInt) {
    // 元の色(color)を時間経過(time)で変化させた色を返している
    float gray = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
    
    //    float gray3 = (color.r + color.g + color.b) / 3;
    
    if (sliderInt < gray) {
        gray = 0;
    } else {
        gray= 1;
    }
    
    return half4(gray, gray, gray, 1.0);
}


[[ stitchable ]] half4 noise(float2 position, half4 currentColor, float time) {
    float value = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
    return half4(value, value, value, 1) * currentColor.a;
}

[[ stitchable ]] float2 wave(float2 position, float time) {
    return position + float2 (sin(time + position.y / 20), sin(time + position.x / 20)) * 5;
}

[[ stitchable ]] /*half4*/float2 slopeImage(float2 position, half4 color, float pitch, float roll) {
    
    // rollの値に基づいて直線の傾きを変える
    position.x = position.x * cos(roll) - position.y * sin(roll);
    position.y = position.x * sin(roll) + position.y * cos(roll);
    
    return position;
    //    if (pitch > 0) {
    //        float thisY = pitch * 50;
    //        float dist = distance(position, float2(pitch, 0.5));
    //        return half4(color.r + pitch, color.g + pitch + (50.0 / dist), color.b + pitch, 1.0);
    //    } else if ( roll > 0) {
    //        return half4(color.r - roll, color.g - roll, color.b - roll, 1.0);
    //    }
    
    //    if (sliderInt < gray) {
    //    } else {
    //    }
    
    //    return half4(gray, gray, gray, 1.0);
}

[[ stitchable ]] half4 slopeSeppenImage(float2 position, half4 color, float pitch, float roll) {
    
    float rightRoll = roll + 0.5;
    float leftRoll = roll - 0.5;
    // 傾き1の直線 y = x の位置を roll によって変える
    float scaledRoll1 = -rightRoll * 2000.0; // roll の値をスケールアップ
    float y_line1 = position.x + scaledRoll1;
    
    // もう一本の直線 y = x の位置を secondRoll によって変える
    float scaledRoll2 = -leftRoll * 2000.0; // secondRoll の値をスケールアップ
    float y_line2 = position.x + scaledRoll2;
    
//    float scaledRoll3 = rightRoll * 2000.0; // roll の値をスケールアップ
//    float y_line3 = -position.x + scaledRoll1;
//    
//    float scaledRoll4 = leftRoll * 2000.0; // secondRoll の値をスケールアップ
//    float y_line4 = -position.x + scaledRoll2;
    
    // 距離に基づいてオーバーレイの強度を計算
    float distance1 = abs(position.y - y_line1) / sqrt(1000.0);
    float intensity1 = exp(-distance1 * 0.5);
    
    float distance2 = abs(position.y - y_line2) / sqrt(1000.0);
    float intensity2 = exp(-distance2 * 0.5);
    
    float minDistance = min(distance1, distance2);

    // 距離に基づいてオーバーレイの強度を計算
    float intensity = exp(-minDistance * 0.2); // 強度を調整
    // オーバーレイの色を計算
    half4 overlayColor = half4(/*color.r + 0.8, color.g + 0.8, color.b + 0.8, */1,1,1,1);
    
    // 元の色とオーバーレイを合成
    half4 finalColor = mix(color, overlayColor, intensity * 0.6);
    
    return finalColor;
}

[[ stitchable ]] half4 slopekirakiraImage(float2 position, half4 color, float pitch, float roll) {
    
    // rollの値に基づいて直線の傾きを変える
    position.x = position.x * cos(roll) - position.y * sin(roll);
    position.y = position.x * sin(roll) + position.y * cos(roll);
    
    float tanRoll = tan(roll);
    float distance1 = abs(position.y - position.x * tanRoll) / sqrt(1.0 + tanRoll * tanRoll);
    
    // 左下からの直線の式 y = -x * tan(roll)
    float distance2 = abs(position.y + position.x * tan(roll * 1.5)) / sqrt(1.0 + tan(roll * 1.5) * tan(roll * 5));
    
    // 距離に基づいてオーバーレイの強度を計算
    float intensity1 = exp(-distance1 * 0.5); // 右上からの距離
    float intensity2 = exp(-distance2 * 0.5); // 左下からの距離
    
    // 左下からの直線を優先
    float intensity = (intensity2 > 0.1) ? intensity2 : intensity1;
    
    // 元の色とオーバーレイを合成
    half4 overlayColor = half4(intensity, intensity, intensity, 1.0);
    half4 finalColor = mix(color, overlayColor, intensity);
    
    return finalColor;
    
}

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
