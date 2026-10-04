// SDFPanelLayers.cginc
// Panel-specific rendering helpers for SDFPanel.shader and SDFPanelRM.shader.
// Include AFTER SDFPanelUniforms.cginc and core .cginc files.
//
// Includes SDFButtonLayers.cginc to inherit shared utilities:
//   buttonCompositeOver, buttonShadowEdgeAlpha,
//   RenderButtonBevelWithPatternAndGradient, CalculateButtonRimFromSDF,
//   getIconSDF (available, not used by Panel but harmless)
//
// Defines Panel-specific shadow / edge / border functions that call
// getPanelBodySDF (from SDFPanelShapes.cginc) instead of getButtonSDF.
// These are near-identical to the Button equivalents but use the Panel
// uniform namespace (_PanelBodyRoundness etc.) via getPanelBodySDF.

#ifndef SDFPANEL_LAYERS_INCLUDED
#define SDFPANEL_LAYERS_INCLUDED

// Pull in SDFButtonLayers (includes SDFButtonShapes → getButtonSDF, _ButtonRoundness)
// as well as all shared utilities (compositeOver, bevel, rim, etc.)
#include "SDFButtonLayers.cginc"

// Pull in Panel body shapes (defines getPanelBodySDF, _PanelBodyRoundness)
// Helper names are Panel-prefixed so there is no symbol collision.
#include "SDFPanelShapes.cginc"

// ============================================================================
//  External shadow — cast behind the panel onto the background
// ============================================================================
float calculatePanelExternalShadow(float2 uv, float3 lightDir,
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
//  Body shadow — hull sweep for 3D-depth cast shadow
// ============================================================================
float calculatePanelBodyShadow(float2 uv, float3 lightDir,
                                float blur, float dist, float blurFactor, float castMul,
                                float bodyHalfW, float bodyHalfH, int bodyShapeType,
                                float bodyParam1, float bodyParam2, float bodyParam3,
                                float faceInset, float pseudoHeight,
                                float2 aspectScale, float bodyShapeRotation,
                                float faceHoleEnabled)
{
    float2 ld2  = normalize(lightDir.xy);
    float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist * 2.0;
    bool   doRot = abs(bodyShapeRotation) > 0.001;

    float2 sPosRot = doRot ? rotate2D(sPos, bodyShapeRotation) : sPos;
    float  sD      = getPanelBodySDF(sPosRot, bodyHalfW, bodyHalfH,
                                     bodyShapeType, bodyParam1, bodyParam2, bodyParam3);

    if (castMul > 0.001 && pseudoHeight > 0.001)
    {
        float  ps        = pseudoHeight * castMul;
        float2 topOff    = -ld2 * ps;
        float  faceHalfW = max(0.001, bodyHalfW - faceInset);
        float  faceHalfH = max(0.001, bodyHalfH - faceInset);

        float  segLen2 = dot(topOff, topOff);
        float  t       = saturate(-dot(sPos, topOff) / max(0.0001, segLen2));
        float2 sPosH   = sPos + topOff * t;
        float  hullHW  = lerp(bodyHalfW, faceHalfW, t);
        float  hullHH  = lerp(bodyHalfH, faceHalfH, t);
        float2 sPosHR  = doRot ? rotate2D(sPosH, bodyShapeRotation) : sPosH;
        float  sDH     = getPanelBodySDF(sPosHR, hullHW, hullHH,
                                         bodyShapeType, bodyParam1, bodyParam2, bodyParam3);

        float2 sPosT   = sPos + topOff;
        float2 sPosTR  = doRot ? rotate2D(sPosT, bodyShapeRotation) : sPosT;
        float  sDT     = getPanelBodySDF(sPosTR, faceHalfW, faceHalfH,
                                         bodyShapeType, bodyParam1, bodyParam2, bodyParam3);

        sD = min(sD, min(sDH, sDT));
    }

    if (faceHoleEnabled > 0.5 && faceInset > 0.0001)
    {
        sD = max(sD, -sD - faceInset);
    }

    float lightProj = dot(sPos, ld2);
    float maxDim    = max(bodyHalfW, bodyHalfH);
    float dirBlend  = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
    return buttonShadowEdgeAlpha(sD, blur, blurFactor, dirBlend);
}

// ============================================================================
//  Edge indent — recessed band around the panel shape
// ============================================================================
float calculatePanelEdgeIndent(float2 uv, float2 pos,
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
//  Border — cut-in frame at the canvas quad edge using panel shape
// ============================================================================
float4 calculatePanelBorder(float2 uv, float3 baseColor,
                             float borderWidth, float borderSoftness,
                             float bodyHalfW, float bodyHalfH, int bodyShapeType,
                             float bodyParam1, float bodyParam2, float bodyParam3,
                             float2 aspectScale, out float territory)
{
    float2 pos     = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale;
    float  bodyDist = getPanelBodySDF(pos, bodyHalfW, bodyHalfH,
                                      bodyShapeType, bodyParam1, bodyParam2, bodyParam3);
    float  borderAA = fwidth(bodyDist) * 0.75;

    float innerEdge  = smoothstep(-borderAA, borderAA, bodyDist);
    float outerEdge  = 1.0 - smoothstep(borderWidth, borderWidth + max(borderSoftness, borderAA), bodyDist);
    float borderMask = innerEdge * outerEdge;

    territory = borderMask;
    return float4(baseColor, borderMask);
}

#endif // SDFPANEL_LAYERS_INCLUDED
