#ifndef SDF_OPERATIONS_INCLUDED
#define SDF_OPERATIONS_INCLUDED

#include "../Core/UIMath.cginc"

// ----------------------
// Boolean Operations
// ----------------------

float OpUnion(float d1, float d2)
{
    return min(d1, d2);
}

float OpSubtraction(float d1, float d2)
{
    return max(-d1, d2);
}

float OpIntersection(float d1, float d2)
{
    return max(d1, d2);
}

// ----------------------
// Smooth Boolean Operations
// ----------------------

float OpSmoothUnion(float d1, float d2, float k)
{
    float h = saturate(0.5 + 0.5 * (d2 - d1) / k);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float OpSmoothSubtraction(float d1, float d2, float k)
{
    float h = saturate(0.5 - 0.5 * (d2 + d1) / k);
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

float OpSmoothIntersection(float d1, float d2, float k)
{
    float h = saturate(0.5 - 0.5 * (d2 - d1) / k);
    return lerp(d2, d1, h) + k * h * (1.0 - h);
}

// ----------------------
// Domain Operations
// ----------------------

float2 OpTranslate(float2 p, float2 offset)
{
    return p - offset;
}

float2 OpRotate(float2 p, float angle)
{
    return Rotate2D(p, angle);
}

float2 OpScale(float2 p, float2 scale)
{
    return p / scale;
}

float2 OpRepeat(float2 p, float2 c)
{
    return fmod(p + 0.5 * c, c) - 0.5 * c;
}

float2 OpRepeatLimit(float2 p, float c, float2 l)
{
    float2 q = p - c * clamp(round(p / c), -l, l);
    return q;
}

float2 OpMirror(float2 p, float2 n)
{
    return p - 2.0 * min(0.0, dot(p, n)) * n;
}

// ----------------------
// Displacement Operations
// ----------------------

float OpDisplace(float sdf, float2 p, float amplitude, float frequency)
{
    float displacement = sin(frequency * p.x) * sin(frequency * p.y) * amplitude;
    return sdf + displacement;
}

float OpTwist(float sdf, float2 p, float amount)
{
    float c = cos(amount * p.y);
    float s = sin(amount * p.y);
    float2 q = float2(c * p.x - s * p.y, s * p.x + c * p.y);
    return sdf; // Apply to SDF with twisted coordinates
}

float OpBend(float sdf, float2 p, float amount)
{
    float c = cos(amount * p.x);
    float s = sin(amount * p.x);
    float2 q = float2(c * p.x - s * p.y, s * p.x + c * p.y);
    return sdf; // Apply to SDF with bent coordinates
}

// ----------------------
// Distance Modifications
// ----------------------

float OpOnion(float sdf, float thickness)
{
    return abs(sdf) - thickness;
}


// ----------------------
// UI-Specific SDF Operations
// ----------------------

// Distance to alpha conversion with antialiasing
float SDFToAlpha(float sdf, float edgeWidth)
{
    return 1.0 - smoothstep(-edgeWidth, edgeWidth, sdf);
}

// Distance to alpha with automatic antialiasing
float SDFToAlphaAA(float sdf)
{
    float delta = fwidth(sdf) * 0.5;
    return 1.0 - smoothstep(-delta, delta, sdf);
}

// Distance to outline mask
float SDFToOutline(float sdf, float outlineWidth, float edgeWidth)
{
    float outer = SDFToAlpha(sdf + outlineWidth, edgeWidth);
    float inner = SDFToAlpha(sdf, edgeWidth);
    return outer - inner;
}

// Distance to outline with automatic antialiasing
float SDFToOutlineAA(float sdf, float outlineWidth)
{
    float delta = fwidth(sdf) * 0.5;
    float outer = 1.0 - smoothstep(-delta, delta, sdf + outlineWidth);
    float inner = 1.0 - smoothstep(-delta, delta, sdf);
    return outer - inner;
}

// ----------------------
// Blend Operations
// ----------------------

float OpBlend(float d1, float d2, float t)
{
    return lerp(d1, d2, t);
}

float OpSoftMin(float a, float b, float k)
{
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float OpSoftMax(float a, float b, float k)
{
    return -OpSoftMin(-a, -b, k);
}

// ----------------------
// Advanced Operations
// ----------------------

float OpExtrusion(float sdf2D, float z, float h)
{
    float2 w = float2(sdf2D, abs(z) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
}

float OpRevolution(float2 p, float sdf1D)
{
    return sdf1D; // Apply 1D SDF to length(p.xz) - offset
}

float OpElongate(float sdf, float2 p, float2 h)
{
    float2 q = abs(p) - h;
    return sdf + length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

// ----------------------
// Morphing Operations
// ----------------------

float OpMorph(float sdf1, float sdf2, float t)
{
    return lerp(sdf1, sdf2, smoothstep(0.0, 1.0, t));
}

float OpSmoothMorph(float sdf1, float sdf2, float t, float smoothness)
{
    float blend = smoothstep(-smoothness, smoothness, t - 0.5) * 2.0 - 1.0;
    return lerp(sdf1, sdf2, (blend + 1.0) * 0.5);
}

// ----------------------
// Utility Functions
// ----------------------

float SDFToGlow(float sdf, float glowDistance, float glowIntensity)
{
    float glowMask = smoothstep(-0.005, 0.005, sdf);
    return glowMask * (1.0 - saturate(sdf / glowDistance)) * glowIntensity;
}

// Multiple SDF combination with weights
float OpWeightedUnion(float sdf1, float sdf2, float sdf3, float sdf4, float4 weights)
{
    float4 sdfs = float4(sdf1, sdf2, sdf3, sdf4);
    weights = normalize(weights);
    
    float result = 1000.0;
    for (int i = 0; i < 4; i++)
    {
        if (weights[i] > 0.001)
        {
            result = min(result, sdfs[i] * weights[i]);
        }
    }
    return result;
}

// Smooth minimum with exponential falloff
float OpExpSmoothMin(float a, float b, float k)
{
    float res = exp2(-k * a) + exp2(-k * b);
    return -log2(res) / k;
}

// Polynomial smooth minimum
float OpPowSmoothMin(float a, float b, float k)
{
    a = pow(a, k);
    b = pow(b, k);
    return pow((a * b) / (a + b), 1.0 / k);
}

// ----------------------
// Frustum Wall Geometry Helpers
// Derived from IQ capped-cone intersector normal formula:
// https://iquilezles.org/articles/intersectors/
// ----------------------

// Analytic Z component of the wall normal for a frustum with the given
// lateral inset (bevelDist) and vertical height (shiftAmount).
// Matches the surface normal of a capped cone — not a heuristic lerp.
float FrustumWallNz(float bevelDist, float shiftAmt)
{
    float len = sqrt(shiftAmt * shiftAmt + bevelDist * bevelDist);
    return (len > 0.0001) ? shiftAmt / len : 1.0;
}

// Lateral (XY) scale of the wall normal for the same geometry.
float FrustumWallLateral(float bevelDist, float shiftAmt)
{
    float len = sqrt(shiftAmt * shiftAmt + bevelDist * bevelDist);
    return (len > 0.0001) ? bevelDist / len : 0.0;
}

#endif