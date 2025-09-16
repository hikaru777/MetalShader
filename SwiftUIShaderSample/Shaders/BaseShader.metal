//
//  BaseShader.metal
//  SwiftUIShaderSample
//
//  Created by Claude on 2025/09/17.
//

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