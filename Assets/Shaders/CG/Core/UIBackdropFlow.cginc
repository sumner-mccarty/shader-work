#ifndef UI_BACKDROP_FLOW_INCLUDED
#define UI_BACKDROP_FLOW_INCLUDED

// ============================================================================
// UIBackdropFlow.cginc — the shared kit for PROCEDURAL, ANIMATED backdrops (2026-10-08)
// ============================================================================
// Used ONLY by the Backdrop* shaders (BackdropCaustics / BackdropSplotch / BackdropRibbons). It is
// deliberately NOT included by any widget shader: nothing here is paid for by SDFKnob / SDFButton /
// SDFSlider / SDFPanel, so their FXC compile budgets and every shipped skin are untouched.
//
// WHY PROCEDURAL. A wallpaper texture is finite, tiles or clamps, and cannot move except as a flat
// scroll. A function of (position, time) has no seam, no resolution, and every look decision is a
// Properties entry a .states.json can tune.
//
// THE TIME CONTRACT — everything is exactly periodic.
//     cyc = _Time.y * _Speed + _Phase          (cycles; _Speed is cycles PER SECOND)
// Every motion in the Backdrop* shaders is either a point walking once round a circle per cycle
// (bdOrbit) or a phase advanced by a WHOLE number of turns per cycle, so the picture at cyc and
// cyc + 1 is identical. A host can therefore loop forever without a seam, a GIF of one period loops
// perfectly, and "speed" is simply how long a period lasts (_Speed 0.04 = a 25 s loop). _Phase scrubs
// to a fixed frame for a still render.
//
// HOW IT REACHES THE GLASS. The widget shaders' glass term samples `_UIBackdropTex` (see
// UIMaterials.cginc). A host renders one of these shaders into a mipmapped render texture every frame
// (Graphics.Blit(null, rt, material)) and binds it as `_UIBackdropTex` — the glass then refracts the
// LIVE picture and no widget shader changes. The visible wallpaper is the same render texture drawn
// behind the UI.
// ============================================================================

#define BD_TAU 6.28318530718

// Dave Hoskins' sine-free hashes: stable across GPUs/drivers (a sin()-hash bands on some mobiles).
float bdHash21(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

float2 bdHash22(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx + p3.yz) * p3.zy);
}

// Value noise, quintic fade (C2 continuous: no creases for a lens to bend), 0..1.
float bdNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = bdHash21(i);
    float b = bdHash21(i + float2(1.0, 0.0));
    float c = bdHash21(i + float2(0.0, 1.0));
    float d = bdHash21(i + float2(1.0, 1.0));
    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

// Fractal noise, 1..4 octaves (`oct` may be fractional: the last octave fades in), 0..1.
float bdFbm(float2 p, float oct)
{
    float v = 0.0;
    float a = 0.5;
    float norm = 0.0;
    float2 shift = float2(17.1, 9.2);
    [unroll]
    for (int i = 0; i < 4; i++)
    {
        float w = saturate(oct - (float)i);
        v += a * w * bdNoise(p);
        norm += a * w;
        p = p * 2.03 + shift;
        a *= 0.5;
    }
    return v / max(norm, 1e-4);
}

// A point that walks once round a circle of radius `r` per cycle (the periodic way to move through noise).
float2 bdOrbit(float cyc, float r, float seed)
{
    float a = BD_TAU * (cyc + seed);
    return r * float2(cos(a), sin(a));
}

// Backdrop-space position: centred, aspect-correct, 1 unit = the picture's height, times `scale`.
float2 bdPos(float2 uv, float aspect, float scale)
{
    float asp = aspect > 0.01 ? aspect : _ScreenParams.x / max(_ScreenParams.y, 1.0);
    return (uv - 0.5) * float2(asp, 1.0) * scale;
}

// Four-stop colour ramp, smooth between stops (t 0..1).
float3 bdRamp4(float t, float3 a, float3 b, float3 c, float3 d)
{
    t = saturate(t) * 3.0;
    float3 ab = lerp(a, b, smoothstep(0.0, 1.0, t));
    float3 bc = lerp(b, c, smoothstep(0.0, 1.0, t - 1.0));
    float3 cd = lerp(c, d, smoothstep(0.0, 1.0, t - 2.0));
    return t < 1.0 ? ab : (t < 2.0 ? bc : cd);
}

// The finishing every backdrop shares: brightness / contrast / saturation, a vignette, an optional
// film grain, and ±½ LSB of dither so dark gradients never band.
float3 bdFinish(float3 col, float2 uv, float brightness, float contrast, float saturation,
                float vignette, float grain, float cyc)
{
    col = (col - 0.5) * contrast + 0.5 + brightness;
    float l = dot(col, float3(0.2126, 0.7152, 0.0722));
    col = lerp(float3(l, l, l), col, saturation);
    float2 q = uv - 0.5;
    col *= 1.0 - vignette * saturate(dot(q, q) * 2.2);
    float2 px = uv * _ScreenParams.xy;
    col += (bdHash21(px) - 0.5) * (1.0 / 255.0);                                   // static dither
    col += (bdHash21(px + frac(cyc * 13.0) * 97.0) - 0.5) * grain;                 // animated grain
    return saturate(col);
}

#endif // UI_BACKDROP_FLOW_INCLUDED
