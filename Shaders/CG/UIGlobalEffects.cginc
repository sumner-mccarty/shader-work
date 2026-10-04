#ifndef UI_GLOBAL_EFFECTS_INCLUDED
#define UI_GLOBAL_EFFECTS_INCLUDED

#include "Core/UIMath.cginc"
#include "Core/UIGlobalUniforms.cginc"
#include "Core/UIGradients.cginc"

// Screen effect functions (simplified versions for gradient blending)
float4 ApplyGlobalScreenEffects(float4 color, float2 uv, float2 screenPos)
{
    float4 result = color;
    
    // Chromatic aberration
    if (_GlobalEffectMask & 1)
    {
        float2 center = float2(0.5, 0.5);
        float2 delta = uv - center;
        float distance = length(delta);
        float aberration = distance * _GlobalChromaticStrength;
        
        result.r = color.r;
        result.g = color.g * (1.0 - aberration * 0.5);
        result.b = color.b * (1.0 - aberration);
    }
    
    // Film grain
    if (_GlobalEffectMask & 2)
    {
        float2 grainUV = screenPos * _GlobalGrainSize;
        float grain = noise(grainUV + _GlobalGradientTime) * 2.0 - 1.0;
        grain *= _GlobalGrainIntensity * 0.1;
        result.rgb += grain;
    }
    
    // Vignette
    if (_GlobalEffectMask & 4)
    {
        float2 center = float2(0.5, 0.5);
        float2 delta = uv - center;
        float distance = length(delta);
        
        float vignette = smoothstep(_GlobalVignetteRadius + _GlobalVignetteSmooth,
                                   _GlobalVignetteRadius - _GlobalVignetteSmooth,
                                   distance);
        vignette = lerp(1.0, vignette, _GlobalVignetteIntensity);
        result.rgb *= vignette;
    }
    
    // Scanlines
    if (_GlobalEffectMask & 8)
    {
        float scanline = sin(uv.y * _GlobalScanlineCount * UNITY_PI) * 0.5 + 0.5;
        scanline = lerp(1.0, scanline, _GlobalScanlineIntensity);
        result.rgb *= scanline;
    }
    
    // Color grading
    if (_GlobalEffectMask & 32)
    {
        // Brightness
        result.rgb += _GlobalBrightness;
        
        // Contrast
        result.rgb = (result.rgb - 0.5) * _GlobalContrast + 0.5;
        
        // Saturation
        float gray = dot(result.rgb, float3(0.299, 0.587, 0.114));
        result.rgb = lerp(float3(gray, gray, gray), result.rgb, _GlobalSaturation);
        
        // Color balance
        result.rgb *= _GlobalColorBalance.rgb;
        
        result = saturate(result);
    }
    
    return result;
}

// Enhanced ApplyGlobalEffects function with full feature support
float4 ApplyGlobalEffects(float4 inputColor, float2 uv, float2 screenPos, float intensity)
{
    // Create global gradient using all the new parameters
    float globalGradientPos = GetGradientPosition(_GlobalGradientType, uv, _GlobalGradientDirection,
                                                  _GlobalGradientTime, 1.0, _GlobalGradientScale, _GlobalGradientOffset);
    
    // Create global gradient color (always 4 stops for global gradient)
    float4 globalGradient = InterpolateGradientColors(_GlobalGradientColorA, _GlobalGradientColorB,
                                                      _GlobalGradientColorC, _GlobalGradientColorD,
                                                      globalGradientPos, 4);
    
    // Apply global pulse effect
    float pulse = PulseWave(_GlobalGradientTime, _GlobalPulseFreq, _GlobalPulseIntensity);
    globalGradient.rgb += pulse * 0.1;
    
    // Apply global wave effect
    float2 normalizedScreenPos = screenPos / _GlobalScreenSize;
    float wave = sin(normalizedScreenPos.x * _GlobalWaveParams.x + _GlobalGradientTime * _GlobalWaveParams.z + _GlobalWaveParams.w) * _GlobalWaveParams.y;
    globalGradient.rgb += wave * 0.05;
    
    // Apply global screen effects
    globalGradient = ApplyGlobalScreenEffects(globalGradient, uv, normalizedScreenPos);
    
    // Apply global intensity
    globalGradient.rgb *= intensity;
    
    // Ensure we don't go out of range
    globalGradient = saturate(globalGradient);
    
    return globalGradient;
}

#endif // UI_GLOBAL_EFFECTS_INCLUDED