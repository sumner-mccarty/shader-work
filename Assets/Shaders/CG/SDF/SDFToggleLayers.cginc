// SDFToggleLayers.cginc
// Toggle-specific rendering helpers shared by all per-type SDFToggle shaders.
// Include AFTER SDFToggleSharedUniforms.cginc, the per-type shapes cginc, and core cginc files.
//
// Includes:
//   SDFButtonLayers.cginc  — shared utilities (compositeOver, bevel, rim, shadow helpers)
//   SDFToggleShapes.cginc  — skipped when SDF_TOGGLE_SHAPES_INCLUDED is defined (set by
//                            per-type shapes cgincs like SDFPillShapes.cginc)
//
// Defines:
//   calculateToggleExternalShadow  — cast shadow of Bg shape behind widget
//   calculateToggleBodyShadow      — hull-sweep cast shadow of the Toggle body
//   calculateToggleEdgeIndent      — edge indent around Bg shape
//   calculateToggleBorder          — border at canvas edge
//   calculateLedBloom              — analytic exp() glow halo around Toggle body

#ifndef SDFTOGGLE_LAYERS_INCLUDED
#define SDFTOGGLE_LAYERS_INCLUDED

#include "SDFButtonLayers.cginc"   // compositeOver, bevel/rim structs+functions, shadow alpha helper
// Per-type shapes files (SDFPillShapes.cginc, etc.) set SDF_TOGGLE_SHAPES_INCLUDED before
// including SDFToggleLayers.cginc — skip the monolithic shapes file for new per-type shaders.
#ifndef SDF_TOGGLE_SHAPES_INCLUDED
#include "SDFToggleShapes.cginc"   // getToggleBodySDF, getToggleTrackSDF, per-type SDFs
#endif

// ============================================================================
// External shadow — cast by the Bg (background panel) shape
// ============================================================================
// Uses a rounded-rect approximation of the Bg shape rather than the ToggleType SDF,
// since the Bg is always a simple rect/rounded-rect regardless of toggle type.
float calculateToggleExternalShadow(float2 uv, float3 lightDir,
                                     float blur, float dist, float blurFactor,
                                     float bgHalfW, float bgHalfH,
                                     float bgRounding, float2 aspectScale)
{
    float2 ld2  = normalize(lightDir.xy);
    // See SDFButtonLayers.cginc's calculateButtonExternalShadow for why the offset is added
    // after aspect-scaling the base position rather than being multiplied by aspectScale too.
    float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist * 2.0;

    float minDim = min(bgHalfW, bgHalfH);
    float r      = minDim * (1.0 - saturate(bgRounding));
    float sD     = RoundedRectSDF(sPos, float2(bgHalfW, bgHalfH), r);

    float lightProj = dot(sPos, ld2);
    float maxDim    = max(bgHalfW, bgHalfH);
    float dirBlend  = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
    return buttonShadowEdgeAlpha(sD, blur, blurFactor, dirBlend);
}

// ============================================================================
// Toggle body cast shadow — hull-sweep of Toggle body projected along light
// ============================================================================
float calculateToggleBodyShadow(float2 uv, float3 lightDir,
                                 float blur, float dist, float blurFactor, float castMul,
                                 float bodyHalfW, float bodyHalfH,
                                 float faceInset, float pseudoHeight,
                                 float2 aspectScale)
{
    float2 ld2  = normalize(lightDir.xy);
    float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist * 2.0;

    // Base Toggle body SDF at shadow sample position
    float sD = getToggleBodySDF(sPos, bodyHalfW, bodyHalfH);

    // Hull sweep: project from base footprint to elevated face
    if (castMul > 0.001 && pseudoHeight > 0.001) {
        float ps      = pseudoHeight * castMul;
        float2 topOff = -ld2 * ps;

        float faceHalfW = max(0.001, bodyHalfW - faceInset);
        float faceHalfH = max(0.001, bodyHalfH - faceInset);

        float segLen2 = dot(topOff, topOff);
        float t       = saturate(-dot(sPos, topOff) / max(0.0001, segLen2));
        float2 sPosH  = sPos + topOff * t;
        float hullHW  = lerp(bodyHalfW, faceHalfW, t);
        float hullHH  = lerp(bodyHalfH, faceHalfH, t);
        float sDH     = getToggleBodySDF(sPosH, hullHW, hullHH);

        float2 sPosT  = sPos + topOff;
        float sDT     = getToggleBodySDF(sPosT, faceHalfW, faceHalfH);

        sD = min(sD, min(sDH, sDT));
    }

    float lightProj = dot(sPos, ld2);
    float maxDim    = max(bodyHalfW, bodyHalfH);
    float dirBlend  = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
    return buttonShadowEdgeAlpha(sD, blur, blurFactor, dirBlend);
}

// ============================================================================
// Edge indent — recessed indent around the Bg boundary
// ============================================================================
float calculateToggleEdgeIndent(float2 uv, float2 pos,
                                 float indentWidth, float indentSoftness,
                                 float bgHalfW, float bgHalfH,
                                 float bgRounding, float edgeInset)
{
    float minDim = min(bgHalfW, bgHalfH);
    float r      = minDim * (1.0 - saturate(bgRounding));
    float bgDist = RoundedRectSDF(pos, float2(bgHalfW, bgHalfH), r);
    float distToGeometry = max(0.0, bgDist + edgeInset);

    if (distToGeometry >= indentWidth) return 0.0;

    float baseGradient = 1.0 - (distToGeometry / indentWidth);
    float edgeAA = fwidth(distToGeometry) * 0.75;

    if (indentSoftness > 0.001) {
        float softnessCurve = pow(indentSoftness / 2.0, 1.5);
        float edgePower = lerp(0.8, 4.0, softnessCurve);
        baseGradient = pow(max(0.0, baseGradient), edgePower);
    } else {
        baseGradient = 1.0 - smoothstep(indentWidth - edgeAA, indentWidth + edgeAA, distToGeometry);
    }
    baseGradient = sin(baseGradient * PI * 0.5);
    return baseGradient;
}

// ============================================================================
// Border — thin cut-in at canvas edge (matches Bg shape boundary)
// ============================================================================
float4 calculateToggleBorder(float2 uv, float3 baseColor,
                              float borderWidth, float borderSoftness,
                              float bgHalfW, float bgHalfH, float bgRounding,
                              float2 aspectScale, out float territory)
{
    float2 pos   = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale;
    float minDim = min(bgHalfW, bgHalfH);
    float r      = minDim * (1.0 - saturate(bgRounding));
    float bgDist = RoundedRectSDF(pos, float2(bgHalfW, bgHalfH), r);
    float borderAA = fwidth(bgDist) * 0.75;

    float innerEdge = smoothstep(-borderAA, borderAA, bgDist);
    float outerEdge = 1.0 - smoothstep(borderWidth, borderWidth + max(borderSoftness, borderAA), bgDist);
    float borderMask = innerEdge * outerEdge;

    territory = borderMask;
    return float4(baseColor, borderMask);
}

// ============================================================================
// LED Bloom — analytic exp() glow halo around the Toggle body SDF
// ============================================================================
// toggleBodyDist: pre-evaluated SDF of the toggle body (positive = outside)
// glowRadius:     equi-pixel radius for bloom to fall off over
// sharpness:      exp() fall-off rate; higher = tighter glow  (default ~8)
// intensity:      overall brightness multiplier
//
// Returns bloom brightness in [0, intensity].  Caller multiplies by LedColor.
// ============================================================================
float calculateLedBloom(float toggleBodyDist, float glowRadius, float sharpness, float intensity)
{
    // Only applies outside the toggle body (positive SDF region)
    float d = max(0.0, toggleBodyDist);
    // Exponential fall-off normalized to glowRadius
    float norm = d / max(0.001, glowRadius);
    float bloom = exp(-norm * max(0.1, sharpness)) * intensity;
    return bloom;
}


#endif // SDFTOGGLE_LAYERS_INCLUDED
