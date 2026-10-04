#ifndef UI_MATH_INCLUDED
#define UI_MATH_INCLUDED

#include "Constants.cginc"

// ----------------------
// Noise Functions
// ----------------------

// Simple hash function for noise
float hash(float2 p) {
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

// Smooth noise function
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return lerp(lerp(hash(i + float2(0.0, 0.0)), hash(i + float2(1.0, 0.0)), u.x),
               lerp(hash(i + float2(0.0, 1.0)), hash(i + float2(1.0, 1.0)), u.x), u.y);
}

// ----------------------
// Basic Math Utilities
// ----------------------

float saturate(float x)
{
    return clamp(x, 0.0, 1.0);
}

float2 saturate(float2 x)
{
    return clamp(x, 0.0, 1.0);
}

float3 saturate(float3 x)
{
    return clamp(x, 0.0, 1.0);
}

float4 saturate(float4 x)
{
    return clamp(x, 0.0, 1.0);
}

// Enhanced utility functions
inline float selectValue(bool boolean, float a0, float a1) {
    return boolean * a0 + (1.0 - boolean) * a1;
}

inline float2 selectValue(bool boolean, float2 a0, float2 a1) {
    return boolean * a0 + (1.0 - boolean) * a1;
}

inline float3 selectValue(bool boolean, float3 a0, float3 a1) {
    return boolean * a0 + (1.0 - boolean) * a1;
}

inline float4 selectValue(bool boolean, float4 a0, float4 a1) {
    return boolean * a0 + (1.0 - boolean) * a1;
}

inline float saturaterange(float a, float b, float x) {
    return saturate((x - a) / (b - a));
}

inline float4 saturaterange(float4 a, float4 b, float4 x) {
    return saturate((x - a) / (b - a));
}

inline float dot2D(float2 v) {
    return dot(v, v);
}

inline float cross2D(float2 a, float2 b) {
    return a.x * b.y - a.y * b.x;
}

inline float2 rotate2D(float2 pos, float theta) {
    return float2(pos.x * cos(theta) - pos.y * sin(theta), pos.x * sin(theta) + pos.y * cos(theta));
}

// Smoothstep variations
float smootherstep(float edge0, float edge1, float x)
{
    x = saturate((x - edge0) / (edge1 - edge0));
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

float EaseIn(float t)
{
    return t * t;
}

float EaseOut(float t)
{
    return 1.0 - (1.0 - t) * (1.0 - t);
}

float EaseInOut(float t)
{
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

// ----------------------
// 2D Transformations
// ----------------------

float2 Rotate2D(float2 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float2(p.x * c - p.y * s, p.x * s + p.y * c);
}

float2 Rotate(float2 p, float angle)
{
    return Rotate2D(p, angle);
}

float2x2 Rotation2D(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float2x2(c, -s, s, c);
}

// ----------------------
// Wave Functions
// ----------------------

float TriangleWave(float t)
{
    t = frac(t);
    return t < 0.5 ? t * 2.0 : 2.0 - t * 2.0;
}

float SineWave(float t)
{
    return 0.5 + 0.5 * sin(t * TAU);
}

float SawtoothWave(float t)
{
    return frac(t);
}

float SquareWave(float t)
{
    return frac(t) < 0.5 ? 0.0 : 1.0;
}

float SmoothTriangleWave(float t)
{
    t = frac(t);
    return t < 0.5 ? smoothstep(0.0, 0.5, t) : smoothstep(1.0, 0.5, t);
}

float PulseWave(float t, float duty)
{
    return frac(t) < duty ? 1.0 : 0.0;
}

float SquareWave(float t, float duty)
{
    return step(duty, frac(t));
}

// ----------------------
// Color Space Conversions
// ----------------------

float3 RGBtoHSV(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVtoRGB(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

// ----------------------
// Noise Functions
// ----------------------

float RandomNoise(float2 st)
{
    return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
}

float2 RandomNoise2(float2 st)
{
    st = float2(dot(st, float2(127.1, 311.7)), dot(st, float2(269.5, 183.3)));
    return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
}

float Remap(float value, float inMin, float inMax, float outMin, float outMax)
{
    return outMin + (outMax - outMin) * saturate((value - inMin) / (inMax - inMin));
}

float ValueNoise(float2 st)
{
    float2 i = floor(st);
    float2 f = frac(st);
    
    float a = RandomNoise(i);
    float b = RandomNoise(i + float2(1.0, 0.0));
    float c = RandomNoise(i + float2(0.0, 1.0));
    float d = RandomNoise(i + float2(1.0, 1.0));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float FBMNoise(float2 p, int octaves, float persistence, float lacunarity)
{
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++)
    {
        value += ValueNoise(p * frequency) * amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    
    return value;
}

// Gradient noise (Perlin-like)
float2 GradientNoise2D(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return lerp(lerp(RandomNoise(i + float2(0.0, 0.0)),
                     RandomNoise(i + float2(1.0, 0.0)), u.x),
                lerp(RandomNoise(i + float2(0.0, 1.0)),
                     RandomNoise(i + float2(1.0, 1.0)), u.x), u.y) * 2.0 - 1.0;
}

// ----------------------
// Voronoi / Cellular Noise
// ----------------------

// Hash for Voronoi cell points (returns 2D random offset in [0,1])
float2 VoronoiHash(float2 cell)
{
    float2 st = float2(dot(cell, float2(127.1, 311.7)), dot(cell, float2(269.5, 183.3)));
    return frac(sin(st) * 43758.5453123);
}

// Voronoi distance (F1 = nearest cell distance)
// Returns float2(F1, F2) where F1 < F2
float2 VoronoiNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    
    float f1 = 8.0;
    float f2 = 8.0;
    
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            float2 neighbor = float2(x, y);
            float2 cellPoint = VoronoiHash(i + neighbor);
            float2 diff = neighbor + cellPoint - f;
            float dist = dot(diff, diff);
            
            if (dist < f1)
            {
                f2 = f1;
                f1 = dist;
            }
            else if (dist < f2)
            {
                f2 = dist;
            }
        }
    }
    
    return float2(sqrt(f1), sqrt(f2));
}

// Voronoi edge distance (distance to nearest cell boundary)
float VoronoiEdge(float2 p)
{
    float2 v = VoronoiNoise(p);
    return v.y - v.x;
}

// Domain warping helper - distorts UV using noise for organic effects
float2 DomainWarp(float2 p, float amount, float scale)
{
    float2 offset = float2(
        noise(p * scale + float2(0.0, 0.0)),
        noise(p * scale + float2(5.2, 1.3))
    );
    return p + (offset - 0.5) * amount;
}

// ----------------------
// Time Utilities
// ----------------------

float GetManualTime(float speed, float manualPosition, float offset)
{
    return speed > 0.0 ? _Time.y * speed + offset : manualPosition + offset;
}

float GetAnimatedTime(float speed, float offset)
{
    return _Time.y * speed + offset;
}

// ----------------------
// UV Utilities
// ----------------------

float2 CenterUV(float2 uv)
{
    return uv - 0.5;
}

float2 NormalizeUV(float2 uv, float2 resolution)
{
    return uv / resolution;
}

float2 AspectCorrect(float2 uv, float aspect)
{
    return float2(uv.x * aspect, uv.y);
}

// ----------------------
// Distance Field Utilities
// ----------------------

float SmoothUnion(float d1, float d2, float k)
{
    float h = saturate(0.5 + 0.5 * (d2 - d1) / k);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float SmoothSubtraction(float d1, float d2, float k)
{
    float h = saturate(0.5 - 0.5 * (d2 + d1) / k);
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

float SmoothIntersection(float d1, float d2, float k)
{
    float h = saturate(0.5 - 0.5 * (d2 - d1) / k);
    return lerp(d2, d1, h) + k * h * (1.0 - h);
}

// ----------------------
// Angular Range Utilities
// ----------------------
// These use UI angle convention: 0=top, clockwise positive.
// All parameters are passed in — no shader globals referenced.

// Check if a point is inside an arc region (ring + angular range)
// p: position in [-1,1] centered space
// radius: center radius of the arc
// thickness: width of the arc ring
// startAngle: start angle in degrees (UI convention)
// angleRange: sweep in degrees
bool isInsideArc(float2 p, float radius, float thickness, float startAngle, float angleRange)
{
    float rawAngle = degrees(atan2(p.y, p.x));
    if (rawAngle < 0.0) rawAngle += 360.0;
    
    float normalizedStartAngle = fmod(startAngle + 360.0, 360.0);
    
    float userCurrentAngle;
    if (rawAngle >= 0.0 && rawAngle <= 180.0) {
        userCurrentAngle = 180.0 - rawAngle;
    } else {
        userCurrentAngle = 540.0 - rawAngle;
    }
    if (userCurrentAngle >= 360.0) userCurrentAngle -= 360.0;
    if (userCurrentAngle < 0.0) userCurrentAngle += 360.0;
    
    float angleDiff = userCurrentAngle - normalizedStartAngle;
    if (angleDiff < 0.0) angleDiff += 360.0;
    
    if (angleDiff > angleRange) return false;
    
    float distFromCenter = length(p);
    float innerRadius = radius - thickness * 0.5;
    float outerRadius = radius + thickness * 0.5;
    return (distFromCenter >= innerRadius && distFromCenter <= outerRadius);
}

// Check if a point's angle falls within an angular range (distance-independent)
// p: position in [-1,1] centered space
// startAngle: start angle in degrees (UI convention)
// angleRange: sweep in degrees
bool isInAngularRange(float2 p, float startAngle, float angleRange)
{
    if (angleRange >= 360.0) return true;
    
    float rawAngle = degrees(atan2(p.y, p.x));
    if (rawAngle < 0.0) rawAngle += 360.0;
    
    float normalizedStartAngle = fmod(startAngle + 360.0, 360.0);
    
    float userCurrentAngle;
    if (rawAngle >= 0.0 && rawAngle <= 180.0) {
        userCurrentAngle = 180.0 - rawAngle;
    } else {
        userCurrentAngle = 540.0 - rawAngle;
    }
    if (userCurrentAngle >= 360.0) userCurrentAngle -= 360.0;
    if (userCurrentAngle < 0.0) userCurrentAngle += 360.0;
    
    float angleDiff = userCurrentAngle - normalizedStartAngle;
    if (angleDiff < 0.0) angleDiff += 360.0;
    
    return (angleDiff <= angleRange);
}

#endif