#ifndef UI_EFFECTS_INCLUDED
#define UI_EFFECTS_INCLUDED

#include "Constants.cginc"
#include "UIMath.cginc"
#include "UIGradients.cginc"

// Effect types dictionary
#define EFFECT_NONE           0
#define EFFECT_FILL           1
#define EFFECT_OUTLINE        2
#define EFFECT_GLOW           3
#define EFFECT_SHADOW         4
#define EFFECT_INNER_SHADOW   5
#define EFFECT_BEVEL          6
#define EFFECT_EMBOSS         7
#define EFFECT_ICON           8
#define EFFECT_ICON_BORDER    9
#define EFFECT_ICON_GLOW      10

// Effect parameter structure
struct EffectParams
{
    int type;
    float4 colorA, colorB, colorC, colorD;
    float2 direction;
    float speed;
    float manualPosition;
    float globalBlend;
    float globalIntensity;
    float amount;
    float distance;
    float intensity;
    float width;
    float2 offset;
    GradientParams gradient;
};

// Create default effect parameters
EffectParams CreateEffectParams()
{
    EffectParams p;
    p.type = EFFECT_NONE;
    p.colorA = float4(1, 1, 1, 1);
    p.colorB = float4(0.8, 0.8, 0.8, 1);
    p.colorC = float4(0.6, 0.6, 0.6, 1);
    p.colorD = float4(0.4, 0.4, 0.4, 1);
    p.direction = float2(1, 0);
    p.speed = 1;
    p.manualPosition = 0;
    p.globalBlend = 0;
    p.globalIntensity = 1;
    p.amount = 1;
    p.distance = 0.1;
    p.intensity = 1;
    p.width = 0.02;
    p.offset = float2(0, 0);
    p.gradient = CreateGradientParams();
    return p;
}

// Fill effect
float4 ApplyFillEffect(float sdf, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float fill = (1.0 - smoothstep(-0.005, 0.005, sdf)) * params.amount;
    if (fill <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return color * fill;
}

// Outline effect
float4 ApplyOutlineEffect(float sdf, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float outline = smoothstep(-0.005, 0.005, sdf + params.width) * (1.0 - smoothstep(-0.005, 0.005, sdf));
    if (outline <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return color * outline * params.amount;
}

// Glow effect
float4 ApplyGlowEffect(float sdf, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float glowMask = smoothstep(-0.005, 0.005, sdf);
    float glow = glowMask * (1.0 - saturate(sdf / params.distance)) * params.intensity * params.amount;
    if (glow <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return float4(color.rgb * glow, glow);
}

// Shadow effect
float4 ApplyShadowEffect(float sdf, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float2 shadowUV = uv - params.offset;
    float shadowSDF = sdf; // Assume same SDF for simplicity, can be recalculated with offset
    float shadow = (1.0 - smoothstep(-0.005, 0.005, shadowSDF)) * params.amount;
    if (shadow <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, shadowUV,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return color * shadow;
}

// Icon effect
float4 ApplyIconEffect(float iconSDF, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float icon = (1.0 - smoothstep(-0.005, 0.005, iconSDF)) * params.amount;
    if (icon <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return color * icon;
}

// Icon border effect
float4 ApplyIconBorderEffect(float iconSDF, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float iconBorderDist = iconSDF + params.width;
    float iconBorder = (1.0 - smoothstep(-0.005, 0.005, iconBorderDist)) *
                       (1.0 - (1.0 - smoothstep(-0.005, 0.005, iconSDF))) * params.amount;
    if (iconBorder <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return color * iconBorder;
}

// Icon glow effect
float4 ApplyIconGlowEffect(float iconSDF, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float iconGlowMask = smoothstep(-0.005, 0.005, iconSDF);
    float iconGlow = iconGlowMask * (1.0 - saturate(iconSDF / params.distance)) * params.intensity * params.amount;
    if (iconGlow <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return float4(color.rgb * iconGlow, iconGlow);
}

// Bevel effect
float4 ApplyBevelEffect(float sdf, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float2 grad = float2(ddx(sdf), ddy(sdf));
    float bevelLight = saturate(dot(normalize(grad), normalize(params.direction))) * params.intensity;
    float mask = (1.0 - smoothstep(-0.005, 0.005, sdf)) * params.amount;
    if (mask <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    color.rgb *= (1.0 + bevelLight);
    return color * mask;
}

// Inner shadow effect
float4 ApplyInnerShadowEffect(float sdf, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float innerMask = (1.0 - smoothstep(-0.005, 0.005, sdf));
    float2 shadowUV = uv - params.offset;
    float shadowSDF = sdf; // Recalculate with offset if needed
    float innerShadow = smoothstep(-0.005, 0.005, shadowSDF + params.distance) * innerMask * params.amount;
    if (innerShadow <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, shadowUV,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    return color * innerShadow;
}

// Emboss effect
float4 ApplyEmbossEffect(float sdf, float2 uv, float4 screenPos, EffectParams params, float time)
{
    float2 grad = float2(ddx(sdf), ddy(sdf));
    float emboss = dot(normalize(grad), normalize(params.direction)) * params.intensity;
    float mask = abs(sdf) < params.width ? 1.0 : 0.0;
    mask *= params.amount;
    if (mask <= 0.01)
        return float4(0, 0, 0, 0);
    
    float4 color = GetGradientColor(params.colorA, params.colorB, params.colorC, params.colorD,
                                   params.direction, params.speed, params.manualPosition, uv,
                                   screenPos, params.globalBlend, params.globalIntensity, time);
    color.rgb = lerp(color.rgb, color.rgb + emboss, mask);
    return color * mask;
}

// Effect layer structure for combining multiple effects
struct EffectLayer
{
    EffectParams params;
    int blendMode;
    float opacity;
};

// Combine multiple effect layers
float4 CombineEffectLayers(EffectLayer layers[8], int layerCount, float sdf, float iconSDF, float2 uv, float4 screenPos, float time)
{
    float4 result = float4(0, 0, 0, 0);
    
    for (int i = 0; i < layerCount && i < 8; i++)
    {
        float4 layerColor = float4(0, 0, 0, 0);
        
        switch (layers[i].params.type)
        {
            case EFFECT_FILL:
                layerColor = ApplyFillEffect(sdf, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_OUTLINE:
                layerColor = ApplyOutlineEffect(sdf, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_GLOW:
                layerColor = ApplyGlowEffect(sdf, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_SHADOW:
                layerColor = ApplyShadowEffect(sdf, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_INNER_SHADOW:
                layerColor = ApplyInnerShadowEffect(sdf, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_BEVEL:
                layerColor = ApplyBevelEffect(sdf, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_EMBOSS:
                layerColor = ApplyEmbossEffect(sdf, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_ICON:
                layerColor = ApplyIconEffect(iconSDF, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_ICON_BORDER:
                layerColor = ApplyIconBorderEffect(iconSDF, uv, screenPos, layers[i].params, time);
                break;
            case EFFECT_ICON_GLOW:
                layerColor = ApplyIconGlowEffect(iconSDF, uv, screenPos, layers[i].params, time);
                break;
        }
        
        layerColor *= layers[i].opacity;
        result = BlendGradients(result, layerColor, layers[i].opacity, layers[i].blendMode);
    }
    
    return result;
}

// Simplified single effect application
float4 ApplyEffect(int effectType, float sdf, float iconSDF, float2 uv, float4 screenPos, EffectParams params, float time)
{
    switch (effectType)
    {
        case EFFECT_FILL:
            return ApplyFillEffect(sdf, uv, screenPos, params, time);
        case EFFECT_OUTLINE:
            return ApplyOutlineEffect(sdf, uv, screenPos, params, time);
        case EFFECT_GLOW:
            return ApplyGlowEffect(sdf, uv, screenPos, params, time);
        case EFFECT_SHADOW:
            return ApplyShadowEffect(sdf, uv, screenPos, params, time);
        case EFFECT_INNER_SHADOW:
            return ApplyInnerShadowEffect(sdf, uv, screenPos, params, time);
        case EFFECT_BEVEL:
            return ApplyBevelEffect(sdf, uv, screenPos, params, time);
        case EFFECT_EMBOSS:
            return ApplyEmbossEffect(sdf, uv, screenPos, params, time);
        case EFFECT_ICON:
            return ApplyIconEffect(iconSDF, uv, screenPos, params, time);
        case EFFECT_ICON_BORDER:
            return ApplyIconBorderEffect(iconSDF, uv, screenPos, params, time);
        case EFFECT_ICON_GLOW:
            return ApplyIconGlowEffect(iconSDF, uv, screenPos, params, time);
        default:
            return float4(0, 0, 0, 0);
    }
}

#endif