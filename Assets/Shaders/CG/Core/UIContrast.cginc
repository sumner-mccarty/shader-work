#ifndef UI_CONTRAST_INCLUDED
#define UI_CONTRAST_INCLUDED

// ============================================================================
// UIContrast — keep an ink (an icon, a mark) legible against whatever it is drawn on.
//
// Pure functions, no uniforms. Colours are the shader's working values; the project runs in
// GAMMA colour space, so they are sRGB-encoded and are linearised (pow 2.2) for the WCAG
// relative-luminance maths, then re-encoded.
//
// Why this exists (2026-10-08): a mark's colour is chosen by a palette or a layout that does not
// know which key it will sit on, and every look re-finishes the keys. The same pale-grey glyph
// read fine on graphite and vanished on Walnut's ivory keys, Ice Cold's white ones and
// Marble & Rose's pink ones; lighting then dimmed light marks to mid-grey on dark keys. The
// button shader is the one place that knows the LIT face colour under the mark, so the
// guarantee lives here instead of in 26 palettes.
// ============================================================================

inline float uiRelLum(float3 gammaRgb)
{
    float3 l = pow(saturate(gammaRgb), 2.2);
    return dot(l, float3(0.2126, 0.7152, 0.0722));
}

inline float uiContrastRatio(float la, float lb)
{
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

// Return `ink` unchanged if it already reaches `ratio` against `bg`; otherwise push it — keeping
// its hue — darker (on a light face) or lighter (on a dark face) until it does, as far as black /
// white allow. The dark/light choice blends over a narrow band around the luminance where black
// and white give equal contrast (~0.18), so a face with a gradient never flips the mark abruptly.
inline float3 uiEnsureContrast(float3 ink, float3 bg, float ratio)
{
    if (ratio <= 1.0) return ink;
    float lb = uiRelLum(bg);
    float li = uiRelLum(ink);
    if (uiContrastRatio(li, lb) >= ratio) return ink;

    float3 inkLin = pow(saturate(ink), 2.2);

    // darker: scale linear rgb so luminance hits (lb + .05) / ratio - .05
    float ld = max((lb + 0.05) / ratio - 0.05, 0.0);
    float kd = (li > 1e-4) ? saturate(ld / li) : 0.0;
    float3 darkLin = inkLin * kd;

    // lighter: lerp linear rgb toward white so luminance hits ratio * (lb + .05) - .05
    float ll = min(ratio * (lb + 0.05) - 0.05, 1.0);
    float tl = saturate((ll - li) / max(1.0 - li, 1e-4));
    float3 lightLin = lerp(inkLin, float3(1.0, 1.0, 1.0), tl);

    float goDark = smoothstep(0.13, 0.24, lb);
    float3 outLin = lerp(lightLin, darkLin, goDark);
    return pow(outLin, 1.0 / 2.2);
}

#endif // UI_CONTRAST_INCLUDED
