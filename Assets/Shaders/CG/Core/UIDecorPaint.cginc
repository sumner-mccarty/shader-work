#ifndef UI_DECOR_PAINT_INCLUDED
#define UI_DECOR_PAINT_INCLUDED

// ============================================================================
// UIDecorPaint.cginc — the output contract of the decor ITEM shaders (UI/Decor/*), Docs/Decor.md §2.2.
// ============================================================================
// Every decor item (stroke, splat, sticker, wrap) draws into the SAME four render targets of its panel:
//   SV_Target0  albedo  premultiplied paint colour, a = coverage                    Blend One OneMinusSrcAlpha
//   SV_Target1  mat     premult (gloss, metal, holo), a = coverage                   Blend One OneMinusSrcAlpha
//   SV_Target2  fx      premult (glitter, emissive, unused), a = coverage            Blend One OneMinusSrcAlpha
//   SV_Target3  height  paint / vinyl thickness (R)                                 Blend One One (stacks)
// UI/Decor/Resolve turns them into what the plate samples (UIDecor.cginc). The finish of an item is uniform
// (_DecorMat = gloss, metal, holo, glitter; _DecorMat2.x = emissive, .y = thickness) and set from C# per
// item (DecorRenderer.MaterialFor); a shader only decides WHERE paint is, its tone and its relief.
//
// Erasing is the same geometry drawn with Blend Zero OneMinusSrcAlpha on all four targets (DecorErase).
// NOT included by any widget shader: no widget compile budget is touched.
// ============================================================================

#include "UnityCG.cginc"
#include "UIBackdropFlow.cginc"

float4 _Color;       // paint colour; a = item opacity
float4 _DecorMat;    // gloss, metal, holo, glitter
float4 _DecorMat2;   // emissive, thickness, unused, unused

struct DecorOut
{
    float4 albedo : SV_Target0;
    float4 mat    : SV_Target1;
    float4 fx     : SV_Target2;
    float4 height : SV_Target3;
};

// rgb = paint colour (NOT premultiplied), a = coverage (already including item opacity),
// relief = this pixel's thickness relative to the item's own (0..~1.5), glow = emissive multiplier.
DecorOut DecorEmit(float3 rgb, float a, float relief, float glow)
{
    DecorOut o;
    a = saturate(a);
    o.albedo = float4(saturate(rgb) * a, a);
    o.mat    = float4(_DecorMat.x * a, _DecorMat.y * a, _DecorMat.z * a, a);
    o.fx     = float4(_DecorMat.w * a, saturate(_DecorMat2.x * glow) * a, 0.0, a);
    o.height = float4(saturate(_DecorMat2.y * relief * a), 0.0, 0.0, a);
    return o;
}

// DecorEmit with the finish scaled for this pixel (the paper backing of a holo sticker's peeled corner is
// paper, not foil): matMul multiplies gloss/metal/holo/glitter.
DecorOut DecorEmitM(float3 rgb, float a, float relief, float glow, float matMul)
{
    DecorOut o = DecorEmit(rgb, a, relief, glow);
    a = saturate(a);
    o.mat = float4(_DecorMat.xyz * a * matMul, a);
    o.fx.x = _DecorMat.w * a * matMul;
    return o;
}

// A pixel that only TINTS what is under it (glow spill, overspray haze) without being a surface of its own:
// it carries colour + emission but no gloss/metal/relief of its own.
DecorOut DecorEmitGlow(float3 rgb, float a, float emissive)
{
    DecorOut o;
    a = saturate(a);
    o.albedo = float4(saturate(rgb) * a, a);
    o.mat    = float4(0.0, 0.0, 0.0, 0.0);
    o.fx     = float4(0.0, saturate(emissive) * a, 0.0, a);
    o.height = float4(0.0, 0.0, 0.0, 0.0);
    return o;
}

DecorOut DecorErase(float a)
{
    DecorOut o;
    a = saturate(a);
    o.albedo = float4(0, 0, 0, a);
    o.mat    = float4(0, 0, 0, a);
    o.fx     = float4(0, 0, 0, a);
    o.height = float4(0, 0, 0, a);
    return o;
}

// Shared shading helpers --------------------------------------------------------------------------------------

float dpLum(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

// Polynomial smooth minimum: a wet neck between two shapes.
float dpSmin(float a, float b, float k)
{
    float h = saturate(0.5 + 0.5 * (b - a) / max(k, 1e-4));
    return lerp(b, a, h) - k * h * (1.0 - h);
}

// Tapered capsule a->b, radius ra at a, rb at b.
float dpTaper(float2 p, float2 a, float2 b, float ra, float rb)
{
    float2 pa = p - a;
    float2 ba = b - a;
    float h = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-6));
    return length(pa - ba * h) - lerp(ra, rb, h);
}

// ShaderLab blend block every item pass repeats (ShaderLab cannot take it from an include):
//     Blend 0 One OneMinusSrcAlpha  Blend 1 One OneMinusSrcAlpha  Blend 2 One OneMinusSrcAlpha  Blend 3 One One

#endif // UI_DECOR_PAINT_INCLUDED
