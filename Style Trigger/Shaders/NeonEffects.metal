//
//  NeonEffects.metal
//  Style Trigger
//
//  Created by Tufan Cakir on 17.10.26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Compatible with ShaderLibrary.neonPulse(.float(intensity))
// Position is expressed in the view's local coordinate space.
[[ stitchable ]] half4 neonPulse(
    float2 position,
    half4 color,
    float intensity
) {
    // Keep the original alpha untouched to avoid unwanted halos at edges.
    float strength = clamp(intensity, 0.0f, 2.0f);
    if (strength <= 0.0001f || color.a <= 0.0001h) {
        return color;
    }

    // Gentle horizontal scanlines, rather than strong brightness flicker.
    float scan = 0.975f + 0.025f * sin(position.y * 0.16f);

    // Two spatial frequencies give a soft neon shimmer without requiring time.
    float shimmer = 0.5f + 0.5f * sin(position.y * 0.045f + position.x * 0.012f);
    float gain = 1.0f + strength * (0.055f + 0.035f * shimmer);

    float3 rgb = float3(color.rgb);
    rgb *= mix(1.0f, scan, min(strength, 1.0f));
    rgb = min(rgb * gain, float3(1.0f));

    return half4(half3(rgb), color.a);
}
