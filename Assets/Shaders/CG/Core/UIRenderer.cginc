#ifndef UI_RENDERER_INCLUDED
#define UI_RENDERER_INCLUDED

#include "UIComponents.cginc"
#include "UIPatterns.cginc"
#include "UILighting.cginc"
#include "UIGradients.cginc"
#include "../UIGlobalEffects.cginc"

// Standard rendering pipeline for UI components with gradients and global effects

// Helper function to calculate gradient colors for UI components
float4 CalculateGradient(float2 uv, float4 colorA, float4 colorB, float4 colorC, float4 colorD,
                        float2 direction, int gradientType, float speed, float scale, float offset, float time,
                        int numColors)
{
    float gradientPos = GetGradientPosition(gradientType, uv, direction, time * speed, 1.0, scale, offset);
    return InterpolateGradientColors(colorA, colorB, colorC, colorD, gradientPos, numColors);
}

// Samples the shared cross-widget shadow buffer (_UIShadowBuffer, declared in
// UIGlobalUniforms.cginc) at a fragment's own screen-space UV — returns the multiply-darken
// factor to receive shadows cast by ANY other widget, regardless of draw order.
float3 sampleUIShadowBuffer(float2 screenUV)
{
    if (_UIShadowBufferBound < 0.5) return float3(1, 1, 1);   // nothing bound = no shadow
    return tex2D(_UIShadowBuffer, screenUV).rgb;
}

// Helper function to calculate global gradient colors
float4 CalculateGlobalGradient(float2 screenPos, float time)
{
    float2 uv = screenPos / _ScreenParams.xy;
    float globalGradientPos = GetGradientPosition(_GlobalGradientType, uv, _GlobalGradientDirection,
                                                  _GlobalGradientTime, 1.0, _GlobalGradientScale, _GlobalGradientOffset);
    return InterpolateGradientColors(_GlobalGradientColorA, _GlobalGradientColorB,
                                     _GlobalGradientColorC, _GlobalGradientColorD, globalGradientPos, 4);
}

// Standard rendering pipeline for UI components with gradients and global effects
float4 RenderUIComponent(float2 uv, float componentMask, UIComponent component, 
                        float4 screenPos, float time, float currentValue, float angleRange,
                        float ambientIntensity, UILight light1, UILight light2, UILight light3)
{
    if (componentMask <= 0.0) return float4(0, 0, 0, 0);
    
    // Start with base color
    float3 baseColor = component.color.rgb;
    
    // Apply gradient if enabled (now uses explicit gradientEnabled flag instead of checking gradientType == GRADIENT_NONE)
    if (component.gradientEnabled > 0.5) {
        float4 gradientColor = CalculateGradient(uv, component.gradientColorA, component.gradientColorB, 
                                               component.gradientColorC, component.gradientColorD,
                                               component.gradientDirection, component.gradientType,
                                               component.gradientSpeed, component.gradientScale, 
                                               component.gradientOffset, time, component.gradientNumColors);
        baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
    }
    
    // Apply global effects if enabled
    if (component.globalBlend > 0.0) {
        float4 globalColor = CalculateGlobalGradient(screenPos.xy, time);
        baseColor = lerp(baseColor, globalColor.rgb, component.globalBlend * component.globalIntensity);
    }
    
    // Apply material pattern and get lighting modifiers (patternEnabled check is now inside ApplyMaterialPattern)
    float specularMod;
    float2 normalOffset;
    float3 patternedColor = ApplyMaterialPattern(baseColor, uv, component, currentValue, angleRange, 
                                               specularMod, normalOffset);
    
    // Calculate bevel normal (this would be passed in for different geometries)
    float3 normal = CalculateCircleBevelNormal(uv, 0.5, component.bevelDepth, 
                                             component.bevelDistance, component.bevelSmoothness, component.fillFaceSmoothness);
    
    // Apply lighting
    float3 litColor = ApplyUILighting(normal, patternedColor, ambientIntensity, specularMod, normalOffset, 
                                    light1, light2, light3);
    
    return float4(litColor, component.color.a * component.alpha);
}

// Specialized renderer for circular components
float4 RenderCircularComponent(float2 uv, float radius, UIComponent component, 
                             float4 screenPos, float time, float currentValue, float angleRange,
                             float ambientIntensity, UILight light1, UILight light2, UILight light3)
{
    float2 center = float2(0.5, 0.5);
    float distFromCenter = length(uv - center);
    float mask = step(distFromCenter, radius);
    
    if (mask <= 0.0) return float4(0, 0, 0, 0);
    
    // Start with base color
    float3 baseColor = component.color.rgb;
    
    // Apply gradient if enabled
    if (component.gradientType > 0) {
        float4 gradientColor = CalculateGradient(uv, component.gradientColorA, component.gradientColorB, 
                                               component.gradientColorC, component.gradientColorD,
                                               component.gradientDirection, component.gradientType,
                                               component.gradientSpeed, component.gradientScale, 
                                               component.gradientOffset, time, component.gradientNumColors);
        baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
    }
    
    // Apply global effects if enabled
    if (component.globalBlend > 0.0) {
        float4 globalColor = CalculateGlobalGradient(screenPos.xy, time);
        baseColor = lerp(baseColor, globalColor.rgb, component.globalBlend * component.globalIntensity);
    }
    
    // Apply material pattern and get lighting modifiers
    float specularMod;
    float2 normalOffset;
    float3 patternedColor = ApplyMaterialPattern(baseColor, uv, component, currentValue, angleRange, 
                                               specularMod, normalOffset);
    
    // Calculate bevel normal using the ACTUAL radius, not hardcoded 0.5
    float3 normal = CalculateCircleBevelNormal(uv, radius, component.bevelDepth, 
                                             component.bevelDistance, component.bevelSmoothness, component.fillFaceSmoothness);
    
    // Apply lighting
    float3 litColor = ApplyUILighting(normal, patternedColor, ambientIntensity, specularMod, normalOffset, 
                                    light1, light2, light3);
    
    // Apply anti-aliasing to the circle edge
    float edgeSoftness = fwidth(distFromCenter);
    float alpha = smoothstep(radius + edgeSoftness, radius - edgeSoftness, distFromCenter);
    
    return float4(litColor, component.color.a * component.alpha * alpha);
}

// Specialized renderer for ring components
float4 RenderRingComponent(float2 uv, float innerRadius, float outerRadius, UIComponent component,
                         float4 screenPos, float time, float currentValue, float angleRange,
                         float ambientIntensity, UILight light1, UILight light2, UILight light3)
{
    float2 center = float2(0.5, 0.5);
    float distFromCenter = length(uv - center);
    float mask = step(innerRadius, distFromCenter) * step(distFromCenter, outerRadius);
    
    if (mask <= 0.0) return float4(0, 0, 0, 0);
    
    // Calculate ring bevel normal
    // Convert UV space radii to [-1,1] space for bevel calculation
    float worldInnerRadius = innerRadius * 2.0;
    float worldOuterRadius = outerRadius * 2.0;
    float3 normal = CalculateRingBevelNormal(uv, worldInnerRadius, worldOuterRadius, component.bevelDepth,
                                           component.bevelDistance, component.bevelSmoothness, component.fillFaceSmoothness);
    
    // Start with base color
    float3 baseColor = component.color.rgb;
    
    // Apply gradient if enabled
    if (component.gradientType > 0) {
        float4 gradientColor = CalculateGradient(uv, component.gradientColorA, component.gradientColorB, 
                                               component.gradientColorC, component.gradientColorD,
                                               component.gradientDirection, component.gradientType,
                                               component.gradientSpeed, component.gradientScale, 
                                               component.gradientOffset, time, component.gradientNumColors);
        baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
    }
    
    // Apply global effects if enabled
    if (component.globalBlend > 0.0) {
        float4 globalColor = CalculateGlobalGradient(screenPos.xy, time);
        baseColor = lerp(baseColor, globalColor.rgb, component.globalBlend * component.globalIntensity);
    }
    
    // Apply material pattern and get lighting modifiers
    float specularMod;
    float2 normalOffset;
    float3 patternedColor = ApplyMaterialPattern(baseColor, uv, component, currentValue, angleRange, 
                                               specularMod, normalOffset);
    
    // Apply lighting
    float3 litColor = ApplyUILighting(normal, patternedColor, ambientIntensity, specularMod, normalOffset, 
                                    light1, light2, light3);
    
    // Apply anti-aliasing to ring edges
    float edgeSoftness = fwidth(distFromCenter);
    float innerAlpha = smoothstep(innerRadius - edgeSoftness, innerRadius + edgeSoftness, distFromCenter);
    float outerAlpha = smoothstep(outerRadius + edgeSoftness, outerRadius - edgeSoftness, distFromCenter);
    float alpha = innerAlpha * outerAlpha;
    
    return float4(litColor, component.color.a * component.alpha * alpha);
}

#endif