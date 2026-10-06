// SDFPanelShapes.cginc
// Panel-specific shape SDFs shared between SDFPanel.shader and SDFPanelRM.shader.
// Must be included AFTER SDFPrimitives.cginc and Constants.cginc.
//
// Defines: getPanelBodySDF
//
// PanelBodyShapeType (ShaderConstants.cs):
//   0 = Squircle   — RoundedRect; param1=squareness (0=pill → 1=sharp rect)
//   1 = Polygircle — n-sided polygon; param1=0→circle, >0→3-12 sides; param2=rounding
//   2 = Tab        — rounded top, flat/rect bottom; param1=top corner radius (0-1)
//   3 = Hexagon    — flat-top hexagon stretched by half-extents; param1=rounding
//   4 = Octagon    — 45° chamfered corners; param1=corner cut fraction (0-1)
// 100 = Texture    — SDF sampled from Texture2DArray
//
// Helper functions carry the "Panel" prefix so that SDFButtonShapes.cginc (which defines
// TabShapeSDF, HexagonStretchSDF, OctagonSDF) can be included in the same translation unit
// (e.g. via SDFPanelLayers.cginc → SDFButtonLayers.cginc) without redefinition errors.

#ifndef SDF_PANEL_SHAPES_INCLUDED
#define SDF_PANEL_SHAPES_INCLUDED

uniform float  _PanelBodyRoundness;

// Absolute-pixel corner radius (0 = off, use param1 proportional squareness).
// _WidgetPixelSize is the RectTransform's real pixel size, pushed per-instance by
// MaterialStateController.SyncPixelSize — the shorter side always spans exactly
// 2.0 equi-pixel units, so equi-units-per-real-pixel = 2 / min(pixelSize).
uniform float  _PanelCornerRadiusPx;
uniform float2 _WidgetPixelSize;

#include "SDFTextures.cginc"
uniform float  _PanelBodyShapeTexLayer;
uniform float2 _PanelBodyShapeTexScale;

// ============================================================
//  Helper SDFs  (Panel-prefixed)
// ============================================================

// Tab: rounded on the top half, rectangular on the bottom half.
// topRadius: fraction of min(halfSize) used as corner radius [0,1].
float PanelTabShapeSDF(float2 p, float2 halfSize, float topRadius)
{
    float r = min(halfSize.x, halfSize.y) * saturate(topRadius);
    if (p.y < 0.0)
    {
        return max(abs(p.x) - halfSize.x, abs(p.y) - halfSize.y);
    }
    float2 q = abs(p) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Hexagon: flat-top, stretches proportionally with halfSize.
// rounding: absolute pixel offset to expand/contract edges.
float PanelHexagonStretchSDF(float2 p, float2 halfSize, float rounding)
{
    float2 ap = abs(p);
    float hx = halfSize.x, hy = halfSize.y;
    float dFlat  = ap.y - hy;
    float diagLen = length(float2(hy, hx * 0.5));
    float dDiag  = (dot(ap, float2(hy, hx * 0.5)) - hx * hy) / max(1e-4, diagLen);
    return max(dFlat, dDiag) - rounding;
}

// Octagon: rectangle with 45° chamfered corners.
// cornerCut: fraction [0,1] of min(halfSize)*0.5 removed at each corner.
float PanelOctagonSDF(float2 p, float2 halfSize, float cornerCut)
{
    float2 ap  = abs(p);
    float  s   = min(halfSize.x, halfSize.y);
    float  cut = lerp(0.0, s * 0.5, saturate(cornerCut));
    float rectDist   = max(ap.x - halfSize.x, ap.y - halfSize.y);
    float cornerDist = (ap.x + ap.y - (halfSize.x + halfSize.y - cut)) * 0.7071;
    return max(rectDist, cornerDist);
}

// ============================================================
//  Main panel body shape dispatcher
// ============================================================
// p:           position in equi-pixel space, centered, aspect-corrected by caller
// halfWidth/H: half-extents in equi-pixel space
// shapeType:   see PanelBodyShapeType enum
// param1-3:    shape-specific tuning parameters [0,1]
// texLayer/texScale: override texture layer/scale (pass -2/float2(0,0) to use uniforms)
float getPanelBodySDF(float2 p, float halfWidth, float halfHeight,
                      int shapeType, float param1, float param2, float param3,
                      float texLayer = -2, float2 texScale = float2(0, 0))
{
    float2 halfSize = float2(halfWidth, halfHeight);
    float  minDim   = min(halfWidth, halfHeight);
    float  d;

    [forcecase]
    switch (shapeType)
    {
        case 0: // Squircle
        {
            float r = minDim * (1.0 - saturate(param1));
            // Fixed-pixel corner radius: same on-screen radius on every panel size,
            // clamped to the pill limit for small panels.
            if (_PanelCornerRadiusPx > 0.5 && min(_WidgetPixelSize.x, _WidgetPixelSize.y) > 1.0)
            {
                float minPix = min(_WidgetPixelSize.x, _WidgetPixelSize.y);
                r = clamp(_PanelCornerRadiusPx * 2.0 / minPix, 0.0, minDim);
            }
            d = RoundedRectSDF(p, halfSize, r);
            break;
        }
        case 1: // Polygircle
        {
            if (param1 < 0.001)
            {
                d = CircleSDF(p, minDim);
            }
            else
            {
                int    sides   = clamp((int)(3.0 + param1 * 9.0 + 0.5), 3, 12);
                float  rounding = param2 * minDim * 0.15;
                float  an      = PI / float(sides);
                float  bn      = fmod(atan2(p.x, p.y) + 2.0 * PI, 2.0 * an) - an;
                float2 q       = length(p) * float2(cos(bn), abs(sin(bn)));
                float2 acs     = float2(cos(an), sin(an)) * minDim;
                float2 delta   = q - acs;
                delta.y += clamp(-delta.y, 0.0, acs.y);
                d = length(delta) * sign(delta.x) - rounding;
            }
            break;
        }
        case 2: // Tab — rounded top, flat bottom
        {
            d = PanelTabShapeSDF(p, halfSize, param1);
            break;
        }
        case 3: // Hexagon — flat-top, stretches with half-extents
        {
            float rounding = param1 * minDim * 0.1;
            d = PanelHexagonStretchSDF(p, halfSize, rounding);
            break;
        }
        case 4: // Octagon — chamfered corners
        {
            // _PanelCornerRadiusPx pins the CUT in canvas units, as it pins the squircle radius:
            // a proportional cut is a nick on a strip and a huge bevel on a rack (Tron, 2026-09-14).
            float cutAmt = param1;
            if (_PanelCornerRadiusPx > 0.5 && min(_WidgetPixelSize.x, _WidgetPixelSize.y) > 1.0)
            {
                float minPix = min(_WidgetPixelSize.x, _WidgetPixelSize.y);
                cutAmt = saturate((_PanelCornerRadiusPx * 2.0 / minPix) / max(1e-4, minDim * 0.5));
            }
            d = PanelOctagonSDF(p, halfSize, cutAmt);
            break;
        }
        case 100: // Texture SDF
        {
            int    tl    = (int)((texLayer > -1.5) ? texLayer : _PanelBodyShapeTexLayer);
            float2 ts    = (texScale.x + texScale.y > 0.001) ? texScale : _PanelBodyShapeTexScale;
            float2 texUV = (p / max(float2(0.001, 0.001), halfSize)) * ts * 0.5 + 0.5;
            d = sampleTextureSDF(texUV, tl) * minDim;
            break;
        }
        default:
        {
            float r = minDim * (1.0 - saturate(param1));
            d = RoundedRectSDF(p, halfSize, r);
            break;
        }
    }

    d -= _PanelBodyRoundness * minDim * 0.15;
    return d;
}

#endif // SDF_PANEL_SHAPES_INCLUDED
