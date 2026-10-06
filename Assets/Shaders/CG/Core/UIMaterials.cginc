#ifndef UI_MATERIALS_INCLUDED
#define UI_MATERIALS_INCLUDED

// ============================================================================
// UIMaterials.cginc — Materials v2 (2026-10-06): matcap reflections + backdrop glass.
// ============================================================================
// Two surface treatments applied AFTER a section's lighting, on the parts where material
// matters most (knob body, button body, slider handle, panel face):
//
//   MATCAP  — a lit-sphere image sampled with the shading normal. Gives metal, clear coat, pearl
//             and glass reflections the 3-lamp Blinn-Phong cannot. Images live in the global
//             Texture2DArray _UIMatcapArray (Resources/UiMaterials/Matcaps.png, catalog.json lists
//             the layers). Mode 0 METAL replaces the lit colour with the reflection tinted by the
//             part's colour (gold = chrome × gold); 1 COAT adds the reflection on top (lacquer,
//             gloss plastic, glass rim); 2 TINT multiplies (pearl, ceramic sheens).
//
//   GLASS   — the part shows the BACKDROP behind it (global _UIBackdropTex: the look's wallpaper,
//             drawn behind the whole UI), refracted by the normal, blurred by mip level, tinted,
//             with a fresnel rim. The part should be authored opaque (alpha 1): the glass IS its
//             transparency, so nothing double-blends with the real background.
//
// Both are off unless the section's _XxxMatcapEnabled / _XxxGlassEnabled guard is set, and both
// do nothing until the app binds their textures (_UIMaterialLibBound / _UIBackdropBound) — so every
// existing skin renders exactly as before.
//
// Usage in a widget shader (P = the section prefix, e.g. Knob, Button, Handle, Panel):
//     #include "CG/Core/UIMaterials.cginc"     (after UILighting.cginc)
//     UI_MATERIAL_V2_UNIFORMS(P)               (global scope)
//     UI_SET_SCREEN_UV(IN.screenPos)           (first line of frag)
//     UI_MATERIAL_V2(litColor, baseColor, normal, P, NY)   (right after the section's ApplyUILighting;
//                                                         NY = -1 raymarched shaders, +1 SDFPanel)
// ============================================================================

#include "UIGlobalUniforms.cginc"

static float2 g_uiScreenUV = float2(0.5, 0.5);

#define UI_SET_SCREEN_UV(sp) g_uiScreenUV = (sp).xy / max((sp).w, 1e-5);

// `n` here is in SCREEN-UP space (+x right, +y up the screen, +z toward the viewer); a matcap's top
// row is "up". The shaders do NOT agree on their normals' y: the raymarched ones (analytical normals)
// point +y DOWN the screen, the derivative-built ones (SDFPanel) point it UP in the app's orientation
// (measured 2026-10-06 with a chrome matcap in both render orientations). So every call site passes
// its own sign — UI_MATERIAL_V2(..., NY): RM shaders -1, SDFPanel +1.
float3 UISampleMatcap(float3 n, float layer)
{
    float2 muv = n.xy * 0.485 + 0.5;
    return UNITY_SAMPLE_TEX2DARRAY_LOD(_UIMatcapArray, float3(muv, floor(layer + 0.5)), 0).rgb;
}

float3 UIApplyMatcap(float3 litColor, float3 baseColor, float3 normal,
                     float enabled, float layer, float strength, float mode)
{
    if (enabled < 0.5 || _UIMaterialLibBound < 0.5) return litColor;
    float3 n = normalize(normal);
    float3 m = UISampleMatcap(n, layer);
    float3 r;
    if (mode < 0.5)       r = m * baseColor * 1.35;             // METAL: tinted reflection
    else if (mode < 1.5)  r = litColor + m;                     // COAT: specular on top
    else                  r = litColor * m * 1.6;               // TINT: sheen multiply
    return saturate(lerp(litColor, r, saturate(strength)));
}

float3 UIApplyGlass(float3 color, float3 normal, float enabled, float strength, float refract,
                    float blur, float4 tint, float rim)
{
    if (enabled < 0.5 || _UIBackdropBound < 0.5) return color;
    float3 n = normalize(normal);
    // Refraction bends the view toward the part's edge, like a lens; the backdrop is sampled
    // where that bent ray lands. Blur is a mip level of the (mipmapped) backdrop.
    float2 uv = g_uiScreenUV * _UIBackdropUV.xy + _UIBackdropUV.zw - n.xy * refract;
    float3 bg = tex2Dlod(_UIBackdropTex, float4(uv, 0, blur)).rgb;
    float3 glass = bg * tint.rgb + tint.rgb * tint.a * 0.08;
    float fres = pow(saturate(1.0 - n.z), 2.5) * rim;
    float3 o = lerp(color, glass, saturate(strength));
    return saturate(o + fres);
}

#define UI_MATERIAL_V2_UNIFORMS(P) \
    float _##P##MatcapEnabled; float _##P##MatcapLayer; float _##P##MatcapStrength; float _##P##MatcapMode; \
    float _##P##GlassEnabled; float _##P##GlassStrength; float _##P##GlassRefract; float _##P##GlassBlur; \
    float4 _##P##GlassTint; float _##P##GlassRim;

// Glass first (it replaces the body with the refracted backdrop), then the matcap — so a COAT
// matcap lays its highlights on top of the glass, which is what makes glass read as glass.
#define UI_MATERIAL_V2(col, base, n, P, NY) \
    col = UIApplyGlass(col, float3((n).x, (n).y * (NY), (n).z), _##P##GlassEnabled, _##P##GlassStrength, _##P##GlassRefract, \
                       _##P##GlassBlur, _##P##GlassTint, _##P##GlassRim); \
    col = UIApplyMatcap(col, base, float3((n).x, (n).y * (NY), (n).z), _##P##MatcapEnabled, _##P##MatcapLayer, _##P##MatcapStrength, \
                        _##P##MatcapMode);

#endif // UI_MATERIALS_INCLUDED
