// SDFSliderLayers.cginc
// Slider-specific rendering helpers for SDFSlider.shader and SDFSliderRM.shader.
// Include AFTER SDFSliderUniforms.cginc and core .cginc files.
//
// Includes:
//   SDFButtonLayers.cginc  — shared utilities (compositeOver, bevel, rim, etc.)
//   SDFPanelShapes.cginc   — getPanelBodySDF for background shape
//   SDFSliderHandleShapes.cginc — getHandleSDF for draggable thumb
//
// Defines:
//   calculateSliderExternalShadow — background-shape external cast shadow
//   calculateSliderEdgeIndent     — background-shape edge indent
//   calculateSliderBorder         — background-shape border
//   calculateHandleBodyShadow     — 3D hull-sweep shadow cast by the handle

#ifndef SDFSLIDER_LAYERS_INCLUDED
#define SDFSLIDER_LAYERS_INCLUDED

#include "SDFButtonLayers.cginc"       // compositeOver, bevel, rim, shadow helpers
#include "SDFPanelShapes.cginc"        // getPanelBodySDF  (_PanelBodyRoundness used for background)
#include "SDFSliderHandleShapes.cginc" // getHandleSDF     (_HandleRoundness)

// ============================================================================
//  Background external shadow — cast behind slider onto background
// ============================================================================
float calculateSliderExternalShadow(float2 uv, float3 lightDir,
                                     float blur, float dist, float blurFactor,
                                     float bodyHalfW, float bodyHalfH, int bodyShapeType,
                                     float bodyParam1, float bodyParam2, float bodyParam3,
                                     float2 aspectScale, float bodyShapeRotation)
{
    float2 ld2  = normalize(lightDir.xy);
    // See SDFButtonLayers.cginc's calculateButtonExternalShadow for why the offset is added
    // after aspect-scaling the base position rather than being multiplied by aspectScale too.
    float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist * 2.0;

    float2 sPosRot = (abs(bodyShapeRotation) > 0.001) ? rotate2D(sPos, bodyShapeRotation) : sPos;
    float  sD      = getPanelBodySDF(sPosRot, bodyHalfW, bodyHalfH,
                                     bodyShapeType, bodyParam1, bodyParam2, bodyParam3);

    float lightProj = dot(sPos, ld2);
    float maxDim    = max(bodyHalfW, bodyHalfH);
    float dirBlend  = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
    return buttonShadowEdgeAlpha(sD, blur, blurFactor, dirBlend);
}

// ============================================================================
//  Background edge indent
// ============================================================================
float calculateSliderEdgeIndent(float2 uv, float2 pos,
                                 float indentWidth, float indentSoftness,
                                 float bodyHalfW, float bodyHalfH, int bodyShapeType,
                                 float bodyParam1, float bodyParam2, float bodyParam3,
                                 float edgeInset)
{
    float bodyDist       = getPanelBodySDF(pos, bodyHalfW, bodyHalfH,
                                           bodyShapeType, bodyParam1, bodyParam2, bodyParam3);
    float distToGeometry = max(0.0, bodyDist + edgeInset);

    if (distToGeometry >= indentWidth) return 0.0;

    float baseGradient = 1.0 - (distToGeometry / indentWidth);
    float edgeAA       = fwidth(distToGeometry) * 0.75;

    if (indentSoftness > 0.001)
    {
        float softnessCurve = pow(indentSoftness / 2.0, 1.5);
        float edgePower     = lerp(0.8, 4.0, softnessCurve);
        baseGradient        = pow(max(0.0, baseGradient), edgePower);
    }
    else
    {
        baseGradient = 1.0 - smoothstep(indentWidth - edgeAA, indentWidth + edgeAA, distToGeometry);
    }
    baseGradient = sin(baseGradient * PI * 0.5);

    return baseGradient;
}

// ============================================================================
//  Background border
// ============================================================================
float4 calculateSliderBorder(float2 uv, float3 baseColor,
                              float borderWidth, float borderSoftness,
                              float bodyHalfW, float bodyHalfH, int bodyShapeType,
                              float bodyParam1, float bodyParam2, float bodyParam3,
                              float2 aspectScale, out float territory)
{
    float2 pos      = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale;
    float  bodyDist = getPanelBodySDF(pos, bodyHalfW, bodyHalfH,
                                      bodyShapeType, bodyParam1, bodyParam2, bodyParam3);
    float  borderAA = fwidth(bodyDist) * 0.75;

    float innerEdge  = smoothstep(-borderAA, borderAA, bodyDist);
    float outerEdge  = 1.0 - smoothstep(borderWidth, borderWidth + max(borderSoftness, borderAA), bodyDist);
    float borderMask = innerEdge * outerEdge;

    territory = borderMask;
    return float4(baseColor, borderMask);
}

// ============================================================================
//  Handle body shadow — hull-sweep 3D cast shadow from the handle thumb
//
//  handlePos:   handle centre in equi-pixel space (same space as pos)
//  halfW/halfH: handle half-extents in equi-pixel space
//  faceInset:   amount handle face is inset from body (for bevel depth)
//  pseudoHeight:height of the 3D extrusion in equi-pixel units
// ============================================================================
float calculateHandleBodyShadow(float2 uv, float3 lightDir,
                                 float blur, float dist, float blurFactor, float castMul,
                                 float2 handlePos, float halfW, float halfH,
                                 int shapeType, float param1, float param2, float param3,
                                 float faceInset, float pseudoHeight,
                                 float2 aspectScale, float shapeRotation,
                                 float2 posOffset, float aaUnit = 0.0)
{
    float2 ld2  = normalize(lightDir.xy);
    // Sample position relative to handle centre; posOffset shifts for view tilt/shift.
    float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - handlePos - ld2 * dist + posOffset;
    bool   doRot = abs(shapeRotation) > 0.001;

    float2 sPosRot = doRot ? rotate2D(sPos, shapeRotation) : sPos;
    float  sD      = getHandleSDF(sPosRot, halfW, halfH, shapeType, param1, param2, param3);
    float  maxDim  = max(halfW, halfH);

    // Penumbra half-width AT THE CONTACT POINT — the skin's own softness, in the same
    // relative-to-occluder unit the button and knob now use, so the same authored number
    // means the same visual softness on all three.
    float penHalf  = UI_SHADOW_CONTACT_BLUR(blur, maxDim);
    float umbraMul = 1.0;

    if (castMul > 0.001 && pseudoHeight > 0.001)
    {
        float  ps        = pseudoHeight * castMul;
        float2 topOff    = -ld2 * ps;
        float  faceHalfW = max(0.001, halfW - faceInset);
        float  faceHalfH = max(0.001, halfH - faceInset);

        // CONTACT HARDENING. `t` is where along the throw this pixel sits: 0 at the foot of
        // the handle, 1 at the projected tip. The penumbra opens up with it and the umbra
        // dissolves with it, so the shadow is sharp and dark where the handle meets the
        // track and broad and faint where it is furthest from it. A single per-widget
        // softness — what this used to have — is the look of a flat card hovering above the
        // track, which is exactly the complaint these shadows drew.
        float  castLen = length(topOff);
        float  segLen2 = dot(topOff, topOff);
        float  t       = saturate(-dot(sPos, topOff) / max(0.0001, segLen2));
        float2 fall    = UIShadowPenumbra(castLen * t, maxDim, blurFactor);
        penHalf       += fall.x;
        umbraMul       = fall.y;

        // The hull, swept. The cast silhouette is the convex hull of the base footprint and
        // the projected face, and for two convex sets that hull is EXACTLY the union over
        // s in [0,1] of their linear interpolation. One closest-point-on-segment sample
        // min'd against the tip's own footprint (what was here) is only correct when the
        // swept shape does not change size; this one tapers by faceInset, so the two fields
        // crossed over early on one side of a corner and late on the other and bit a
        // visible notch out of the shadow. Dynamic loop: ONE getHandleSDF is compiled and a
        // handful of iterations run, against the three that used to be unrolled.
        int   hullN = UIShadowHullSamples(castLen, maxDim);
        float invN  = 1.0 / (float)max(hullN - 1, 1);
        UNITY_LOOP for (int hs = 1; hs < hullN; hs++)
        {
            float  s      = (float)hs * invN;
            float2 sPosS  = sPos + topOff * s;
            float2 sPosSR = doRot ? rotate2D(sPosS, shapeRotation) : sPosS;
            float  hullHW = lerp(halfW, faceHalfW, s);
            float  hullHH = lerp(halfH, faceHalfH, s);
            sD = min(sD, getHandleSDF(sPosSR, hullHW, hullHH, shapeType, param1, param2, param3));
        }
    }

    return UIShadowEdgeAlpha(sD, penHalf, aaUnit) * umbraMul;
}

#endif // SDFSLIDER_LAYERS_INCLUDED
