#ifndef UI_GRADIENTS_INCLUDED
#define UI_GRADIENTS_INCLUDED

#include "Constants.cginc"
#include "./UIMath.cginc"
#include "UIGlobalUniforms.cginc"
#include "UIPatterns.cginc"

// Gradient types
// Values MUST stay in sync with GradientType enum in ShaderConstants.cs.
#define GRADIENT_LINEAR       0
#define GRADIENT_RADIAL       1
#define GRADIENT_ANGULAR      2
#define GRADIENT_DIAMOND      3
#define GRADIENT_TRIANGLE     4
// RM-only bevel topology types (only meaningful on SURFACE_WALL in SDFKnobRM.shader).
// Uses the 2D SDF surface normal at the hit point.
// normalDot = dot(surfaceNormal2D, radialOutward): +1=outer wall, 0=slit side, -1=slit back.
// tangentialMag = |dot(surfaceNormal2D, tangentDir)|: 1=pure tangential (slit sides).
#define GRADIENT_BEVEL_DEPTH  5  // Linear A(outer)→D(back) ramp: scale=range, offset=shift
#define GRADIENT_BEVEL_WALLS  6  // Zones: A=outer, B=side(out), C=side(in), D=groove back; scale=sharpness, offset=threshold

// Gradient parameter structure
struct GradientParams
{
    float4 colorA, colorB, colorC, colorD;
    float2 direction;
    float speed;
    float manualPosition;
    float globalBlend;
    float globalIntensity;
    float scale;
    float offset;
};

// Create default gradient parameters
GradientParams CreateGradientParams()
{
    GradientParams p;
    p.colorA = float4(1, 1, 1, 1);
    p.colorB = float4(0.8, 0.8, 0.8, 1);
    p.colorC = float4(0.6, 0.6, 0.6, 1);
    p.colorD = float4(0.4, 0.4, 0.4, 1);
    p.direction = float2(1, 0);
    p.speed = 1;
    p.manualPosition = 0;
    p.globalBlend = 0;
    p.globalIntensity = 1;
    p.scale = 1;
    p.offset = 0;
    return p;
}

// Pulse function
float PulseWave(float t, float frequency, float intensity)
{
    return sin(t * frequency * 6.28318) * intensity;
}

// Linear gradient
float LinearGradient(float2 uv, float2 direction, float time, float speed, float scale, float offset)
{
    return (dot(uv, normalize(direction)) * scale + time * speed * 0.1 + offset);
}

// Radial gradient — radiates from the UV centre (0.5, 0.5)
float RadialGradient(float2 uv, float time, float speed, float scale, float offset)
{
    float2 centered = (uv - 0.5) * 2.0; // [-1,1] with centre at origin
    return (length(centered) * scale + time * speed * 0.1 + offset);
}

// Angular gradient — sweeps around the UV centre (0.5, 0.5)
float AngularGradient(float2 uv, float time, float speed, float scale, float offset)
{
    float angle = atan2(uv.y - 0.5, uv.x - 0.5) / (2.0 * UNITY_PI) + 0.5;
    return (angle * scale + time * speed * 0.1 + offset);
}

// Diamond gradient — taxicab distance from the UV centre (0.5, 0.5)
float DiamondGradient(float2 uv, float time, float speed, float scale, float offset)
{
    return ((abs(uv.x - 0.5) + abs(uv.y - 0.5)) * 2.0 * scale + time * speed * 0.1 + offset);
}

// Triangle gradient (animated wave) - this one should naturally repeat
float TriangleGradient(float2 uv, float2 direction, float time, float speed, float scale, float offset)
{
    float t = dot(uv, normalize(direction)) * scale + time * speed * 0.1 + offset;
    return TriangleWave(t); // TriangleWave already handles repetition via frac()
}

// Get gradient position based on type
float GetGradientPosition(int gradientType, float2 uv, float2 direction, float time, float speed, float scale, float offset)
{
    [branch]
    switch (gradientType)
    {
        case GRADIENT_LINEAR:
            return LinearGradient(uv, direction, time, speed, scale, offset);
        case GRADIENT_RADIAL:
            return RadialGradient(uv, time, speed, scale, offset);
        case GRADIENT_ANGULAR:
            return AngularGradient(uv, time, speed, scale, offset);
        case GRADIENT_DIAMOND:
            return DiamondGradient(uv, time, speed, scale, offset);
        case GRADIENT_TRIANGLE:
            return TriangleGradient(uv, direction, time, speed, scale, offset);
        default: // GRADIENT_NONE or unknown
            return 0.5;
    }
}

// Interpolate between 2, 3, or 4 gradient color stops.
// Uses a ping-pong (triangle wave) on t so tiling is always seamless:
// the gradient bounces c0→…→cN-1→…→c0 with no hard seam at the repeat boundary.
float4 InterpolateGradientColors(float4 c0, float4 c1, float4 c2, float4 c3, float t, int numColors)
{
    // Triangle wave: maps any t to [0,1] bouncing 0→1→0→1…
    t = 1.0 - abs(frac(t * 0.5) * 2.0 - 1.0);
    if (numColors <= 2)
    {
        return lerp(c0, c1, smoothstep(0.0, 1.0, t));
    }
    else if (numColors == 3)
    {
        float h = 0.5;
        if (t < h) return lerp(c0, c1, smoothstep(0.0, 1.0, t / h));
        else       return lerp(c1, c2, smoothstep(0.0, 1.0, (t - h) / h));
    }
    else // 4 stops
    {
        float s = 1.0 / 3.0;
        if      (t < s)       return lerp(c0, c1, smoothstep(0.0, 1.0, t / s));
        else if (t < 2.0 * s) return lerp(c1, c2, smoothstep(0.0, 1.0, (t - s) / s));
        else                  return lerp(c2, c3, smoothstep(0.0, 1.0, (t - 2.0 * s) / s));
    }
}

// Main gradient color function
float4 GetGradientColor(GradientParams params, int gradientType, int numColors, float2 uv, float4 screenPos, float time)
{
    // Gradient enabled flag replaces checking for GRADIENT_NONE
    if (gradientType < 0 || numColors < 2) return params.colorA;
    
    float gradientPos = GetGradientPosition(gradientType, uv, params.direction, time, params.speed, params.scale, params.offset);
    
    if (params.speed == 0 && params.manualPosition > 0)
        gradientPos = params.manualPosition * params.scale + params.offset;
    
    return InterpolateGradientColors(params.colorA, params.colorB, params.colorC, params.colorD, gradientPos, numColors);
}

// Convenience overload — gradientType and numColors must be supplied.
float4 GetGradientColor(float4 colorA, float4 colorB, float4 colorC, float4 colorD,
                       float2 direction, float speed, float manualPosition, float scale, float offset,
                       float2 uv, float4 screenPos, float globalBlend, float globalIntensity, float time,
                       int gradientType, int numColors)
{
    GradientParams params;
    params.colorA = colorA;
    params.colorB = colorB;
    params.colorC = colorC;
    params.colorD = colorD;
    params.direction = direction;
    params.speed = speed;
    params.manualPosition = manualPosition;
    params.globalBlend = globalBlend;
    params.globalIntensity = globalIntensity;
    params.scale = scale;
    params.offset = offset;
    
    return GetGradientColor(params, gradientType, numColors, uv, screenPos, time);
}

// Blend modes
#define BLEND_LERP          0
#define BLEND_MULTIPLY      1
#define BLEND_ADD           2
#define BLEND_OVERLAY       3
#define BLEND_SCREEN        4

// Blend gradients with different modes
float4 BlendGradients(float4 gradientA, float4 gradientB, float blend, int blendMode)
{
    [branch]
    switch (blendMode)
    {
        case BLEND_LERP:
            return lerp(gradientA, gradientB, blend);
        case BLEND_MULTIPLY:
            return gradientA * lerp(float4(1, 1, 1, 1), gradientB, blend);
        case BLEND_ADD:
            return gradientA + gradientB * blend;
        case BLEND_OVERLAY:
            {
                float3 overlay = gradientA.rgb < 0.5 ?
                    2.0 * gradientA.rgb * gradientB.rgb :
                    1.0 - 2.0 * (1.0 - gradientA.rgb) * (1.0 - gradientB.rgb);
                return float4(lerp(gradientA.rgb, overlay, blend), gradientA.a);
            }
        case BLEND_SCREEN:
            return 1.0 - (1.0 - gradientA) * (1.0 - gradientB * blend);
        default:
            return lerp(gradientA, gradientB, blend);
    }
}

#endif