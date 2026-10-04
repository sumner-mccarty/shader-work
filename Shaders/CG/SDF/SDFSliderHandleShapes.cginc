// SDFSliderHandleShapes.cginc
// Slider handle (draggable thumb) shape SDFs for SDFSlider.shader and SDFSliderRM.shader.
// Must be included AFTER SDFPrimitives.cginc and Constants.cginc.
//
// Defines: getHandleSDF
//
// SliderHandleShapeType (ShaderConstants.cs):
//   0 = Capsule      — Pill / rounded-rect; param1=corner roundness (0=full pill, 1=sharp rect)
//   1 = Circle       — Circular puck; uses min(halfW, halfH) as radius
//   2 = FlatRect     — Rectangle; param1=corner roundness fraction
//   3 = OvalPointer  — Tall oval + small triangular pointer indicator at bottom
//                      param1=pointer height (0-1), param2=pointer width (0-1)
//   4 = WingFader    — Wide rect with two symmetric grip grooves on long edges
//                      param1=groove depth (0-1), param2=groove x-position (0-1), param3=corner roundness
//   5 = ArrowHandle  — Pill body + triangular pointer at top
//                      param1=arrow height (0-1), param2=arrow width (0-1), param3=corner roundness
//   6 = FaderCap     — Rounded-rect with central horizontal groove (ported from KnobShapes)
//                      param1=width squeeze (0=narrow, 1=full width), param2=groove depth (0-1), param3=corner rounding
//   7 = FaderCapWide — Wide rounded-rect with two screw holes (ported from KnobShapes)
//                      param1=height fraction (0=flat, 1=taller), param2=screw hole radius (0-1), param3=corner rounding
//   8 = DShaft       — Oval with a flat horizontal cut on one side
//                      param1=cut depth (0=no cut, 1=deep cut), param2=oval rounding
//   9 = Squircle     — param1=squareness (0=circle, 1=sharp rect)
// 100 = Texture      — SDF sampled from Texture2DArray

#ifndef SDF_SLIDER_HANDLE_SHAPES_INCLUDED
#define SDF_SLIDER_HANDLE_SHAPES_INCLUDED

uniform float  _HandleRoundness;

#include "SDFTextures.cginc"
uniform float  _HandleShapeTexLayer;
uniform float2 _HandleShapeTexScale;

// ============================================================
//  Helper SDFs
// ============================================================

// OvalPointer: rounded rect body with a small downward triangular pointer nub.
float HandleOvalPointerSDF(float2 p, float halfW, float halfH, float param1, float param2)
{
    float ptrH   = halfH * lerp(0.0, 0.38, param1);
    float ptrW   = halfW * lerp(0.2, 0.85, param2);
    float bodyHH = halfH - ptrH * 0.45;
    float bodyDist = RoundedRectSDF(p + float2(0.0, -ptrH * 0.45), float2(halfW, bodyHH), halfW * 0.75);
    if (ptrH > 0.001 && ptrW > 0.001)
    {
        float2 pa = float2( 0.0,   halfH);
        float2 pb = float2(-ptrW,  halfH - ptrH);
        float2 pc = float2( ptrW,  halfH - ptrH);
        float  ptrDist = TriangleSDF(p, pa, pb, pc);
        bodyDist = min(bodyDist, ptrDist);
    }
    return bodyDist;
}

// WingFader: wide rect handle with two symmetric recessed grip grooves.
float HandleWingFaderSDF(float2 p, float halfW, float halfH,
                         float param1, float param2, float param3)
{
    float cornerR    = param3 * halfH * 0.4;
    float bodyDist   = RoundedRectSDF(p, float2(halfW, halfH), cornerR);
    float grooveDepth = lerp(0.0, halfH * 0.7, param1);
    float grooveHW   = halfW * lerp(0.1, 0.45, param2);
    float grooveHH   = halfH * 0.13;
    if (grooveDepth > 0.001)
    {
        // top groove
        float g1 = max(abs(p.x) - grooveHW, abs(p.y + halfH) - grooveHH);
        // bottom groove
        float g2 = max(abs(p.x) - grooveHW, abs(p.y - halfH) - grooveHH);
        bodyDist = max(bodyDist, -min(g1, g2));
    }
    return bodyDist;
}

// ArrowHandle: pill body with a triangular pointer at the top.
float HandleArrowSDF(float2 p, float halfW, float halfH,
                     float param1, float param2, float param3)
{
    float arrowH  = halfH * lerp(0.0, 0.45, param1);
    float arrowW  = halfW * lerp(0.25, 1.0, param2);
    float cornerR = param3 * halfW * 0.6;
    // Body shifted down so top of body meets arrow base
    float bodyOffY = arrowH * 0.45;
    float bodyHH   = halfH - bodyOffY;
    float bodyDist = RoundedRectSDF(p + float2(0.0, bodyOffY), float2(halfW, bodyHH), cornerR);
    if (arrowH > 0.001 && arrowW > 0.001)
    {
        float baseY = -(halfH - arrowH - bodyOffY);
        float2 pa   = float2( 0.0,  -halfH + bodyOffY);
        float2 pb   = float2(-arrowW, baseY);
        float2 pc   = float2( arrowW, baseY);
        float arrowDist = TriangleSDF(p, pa, pb, pc);
        bodyDist = min(bodyDist, arrowDist);
    }
    return bodyDist;
}

// FaderCap: rounded-rect with an optional central horizontal groove.
// Adapted from KnobShapes/FaderCapSDF.cginc to take explicit width/height.
float HandleFaderCapSDF(float2 p, float halfW, float halfH,
                        float param1, float param2, float param3)
{
    float2 halfExt = float2(halfW * lerp(0.6, 1.0, param1), halfH);
    float  cornerR = param3 * halfH * 0.25;
    float  boxDist = RoundedRectSDF(p, halfExt, cornerR);
    float  grooveHH = halfH * 0.09;
    float  grooveHW = param2 * halfW * 0.45;
    if (grooveHW > 0.001)
    {
        float grooveDist = max(abs(p.y) - grooveHH, abs(p.x) - grooveHW);
        boxDist = max(boxDist, -grooveDist);
    }
    return boxDist;
}

// FaderCapWide: wide rounded-rect with two symmetrical screw/rivet holes.
// Adapted from KnobShapes/FaderCapWideSDF.cginc to take explicit width/height.
float HandleFaderCapWideSDF(float2 p, float halfW, float halfH,
                             float param1, float param2, float param3)
{
    float2 halfExt = float2(halfW, halfH * lerp(0.3, 0.7, param1));
    float  cornerR = param3 * halfH * 0.2;
    float  boxDist = RoundedRectSDF(p, halfExt, cornerR);
    float  screwR  = param2 * halfH * 0.3;
    if (screwR > 0.001)
    {
        float screwOff = halfW * 0.6;
        float sL = CircleSDF(p + float2( screwOff, 0.0), screwR);
        float sR = CircleSDF(p - float2( screwOff, 0.0), screwR);
        boxDist = max(boxDist, -min(sL, sR));
    }
    return boxDist;
}

// DShaft: rounded-oval with a flat horizontal cut on the bottom.
float HandleDShaftSDF(float2 p, float halfW, float halfH, float param1, float param2)
{
    float rounding  = param2 * min(halfW, halfH) * 0.15;
    float ovalDist  = RoundedRectSDF(p, float2(halfW, halfH), halfW * 0.88) - rounding;
    float cutY      = halfH * lerp(0.0, 0.85, param1);
    float cutDist   = p.y - (halfH - cutY);
    return max(ovalDist, cutDist);
}

// ============================================================
//  Main handle shape dispatcher
// ============================================================
// p:           position in handle-local equi-pixel space (centered on handle position)
// halfW/halfH: handle half-extents in equi-pixel space
// shapeType:   see SliderHandleShapeType enum
// param1-3:    shape-specific tuning parameters
float getHandleSDF(float2 p, float halfW, float halfH,
                   int shapeType, float param1, float param2, float param3,
                   float texLayer = -2, float2 texScale = float2(0, 0))
{
    float minDim = min(halfW, halfH);
    float d;

    [forcecase]
    switch (shapeType)
    {
        case 0: // Capsule — pill / rounded-rect
        {
            float r = minDim * (1.0 - saturate(param1));
            d = RoundedRectSDF(p, float2(halfW, halfH), r);
            break;
        }
        case 1: // Circle / Puck
        {
            d = CircleSDF(p, minDim);
            break;
        }
        case 2: // FlatRect
        {
            float r = minDim * saturate(param1) * 0.5;
            d = RoundedRectSDF(p, float2(halfW, halfH), r);
            break;
        }
        case 3: // OvalPointer
        {
            d = HandleOvalPointerSDF(p, halfW, halfH, param1, param2);
            break;
        }
        case 4: // WingFader
        {
            d = HandleWingFaderSDF(p, halfW, halfH, param1, param2, param3);
            break;
        }
        case 5: // ArrowHandle
        {
            d = HandleArrowSDF(p, halfW, halfH, param1, param2, param3);
            break;
        }
        case 6: // FaderCap
        {
            d = HandleFaderCapSDF(p, halfW, halfH, param1, param2, param3);
            break;
        }
        case 7: // FaderCapWide
        {
            d = HandleFaderCapWideSDF(p, halfW, halfH, param1, param2, param3);
            break;
        }
        case 8: // DShaft
        {
            d = HandleDShaftSDF(p, halfW, halfH, param1, param2);
            break;
        }
        case 9: // Squircle
        {
            float r = minDim * (1.0 - saturate(param1));
            d = RoundedRectSDF(p, float2(halfW, halfH), r);
            break;
        }
        case 100: // Texture SDF
        {
            int    tl    = (int)((texLayer > -1.5) ? texLayer : _HandleShapeTexLayer);
            float2 ts    = (texScale.x + texScale.y > 0.001) ? texScale : _HandleShapeTexScale;
            float2 texUV = float2(p.x / max(0.001, halfW), p.y / max(0.001, halfH)) * ts * 0.5 + 0.5;
            d = sampleTextureSDF(texUV, tl) * minDim;
            break;
        }
        default:
        {
            float r = minDim * (1.0 - saturate(param1));
            d = RoundedRectSDF(p, float2(halfW, halfH), r);
            break;
        }
    }

    d -= _HandleRoundness * minDim * 0.15;
    return d;
}

#endif // SDF_SLIDER_HANDLE_SHAPES_INCLUDED
