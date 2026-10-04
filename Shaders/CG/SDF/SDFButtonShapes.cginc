// SDFButtonShapes.cginc
// Button-specific shape SDFs shared between SDFButton.shader and SDFButtonRM.shader.
// Must be included AFTER SDFPrimitives.cginc (uses RoundedRectSDF, CircleSDF, etc.)
// and after Constants.cginc (uses PI).
//
// Defines: getButtonSDF
//
// Button shapes are designed for rectangular UI elements that may have non-square
// aspect ratios. Each shape takes width/height half-extents plus shape-specific parameters.
//
// _ButtonRoundness uniform consumed by getButtonSDF. Declaring here makes the .cginc
// self-contained regardless of include order in the parent shader.

#ifndef SDF_BUTTON_SHAPES_INCLUDED
#define SDF_BUTTON_SHAPES_INCLUDED

// Roundness uniform consumed by getButtonSDF.
uniform float _ButtonRoundness;

// Texture SDF support -- declared here for include-order independence.
#include "SDFTextures.cginc"
uniform float  _ButtonShapeTexLayer;
uniform float2 _ButtonShapeTexScale;

// ButtonShapeType enum:
// 0  = Squircle   - Circle/pill/roundedrect/square; param1=squareness (0=circle/pill -> 1=sharp rect);
//                   stretches with aspect ratio
// 1  = Polygircle - Circular polygon; param1=0->circle, param1>0->n-gon (3-12 sides);
//                   uniform -- never stretches (always inscribed in min-dimension circle);
//                   param2=corner rounding
// 2  = Tab        - Rounded top, flat bottom; param1=top corner radius (0=sharp, 1=half-circle top)
// 3  = Hexagon    - Flat-top hexagon; stretches with half-extents (like Octagon); param1=corner rounding
// 4  = Octagon    - Rectangle with chamfered 45 corners; stretches with half-extents; param1=corner cut amount

// ---- Helper SDFs ----

// Tab shape: rounded top, flat bottom
float TabShapeSDF(float2 p, float2 halfSize, float topRadius)
{
    float r = min(halfSize.x, halfSize.y) * saturate(topRadius);
    // Bottom half: sharp rectangle
    if (p.y < 0.0) {
        return max(abs(p.x) - halfSize.x, abs(p.y) - halfSize.y);
    }
    // Top half: rounded rectangle
    float2 q = abs(p) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Flat-top hexagon that stretches to fill halfSize.
// Vertices at (+-halfSize.x, 0); flat edges at y = +-halfSize.y.
// Corner junctions at (+-halfSize.x/2, +-halfSize.y).
// Outward normal of upper-right diagonal = (halfSize.y, halfSize.x*0.5).
float HexagonStretchSDF(float2 p, float2 halfSize, float rounding)
{
    float2 ap = abs(p);
    float hx = halfSize.x, hy = halfSize.y;
    // Flat top/bottom
    float dFlat = ap.y - hy;
    // Diagonal: connects (hx, 0) to (hx*0.5, hy). Outward normal = (hy, hx*0.5).
    float diagLen = length(float2(hy, hx * 0.5));
    float dDiag = (dot(ap, float2(hy, hx * 0.5)) - hx * hy) / max(1e-4, diagLen);
    return max(dFlat, dDiag) - rounding;
}

// Octagon: rectangle with corners cut at 45 degrees, scales with halfSize
float OctagonSDF(float2 p, float2 halfSize, float cornerCut)
{
    float2 ap = abs(p);
    float s = min(halfSize.x, halfSize.y);
    float cut = lerp(0.0, s * 0.5, saturate(cornerCut));
    float rectDist   = max(ap.x - halfSize.x, ap.y - halfSize.y);
    float cornerDist = (ap.x + ap.y - (halfSize.x + halfSize.y - cut)) * 0.7071;
    return max(rectDist, cornerDist);
}

// Main button shape dispatcher
// p: position in equi-pixel space (centered, aspect-corrected by caller)
// halfWidth, halfHeight: half-extents of the button in equi-pixel space
// shapeType: 0-4, or 100 for texture
// param1-param3: shape-specific parameters (all in [0,1] range)
float getButtonSDF(float2 p, float halfWidth, float halfHeight,
                   int shapeType, float param1, float param2, float param3,
                   float texLayer = -2, float2 texScale = float2(0, 0))
{
    float2 halfSize = float2(halfWidth, halfHeight);
    float minDim = min(halfWidth, halfHeight);
    float d;

    [forcecase]
    switch (shapeType) {
        case 0: // Squircle -- param1=squareness (0=circle/pill, 1=sharp rect); stretches with aspect ratio
        {
            float r = minDim * (1.0 - saturate(param1));
            d = RoundedRectSDF(p, halfSize, r);
            break;
        }
        case 1: // Polygircle -- param1=0->circle, param1>0->3-12 sided polygon; uses minDim (never stretches)
        {
            if (param1 < 0.001) {
                d = CircleSDF(p, minDim);
            } else {
                // Map param1 [0.001, 1] to sides [3, 12]
                int sides = clamp((int)(3.0 + param1 * 9.0 + 0.5), 3, 12);
                float rounding = param2 * minDim * 0.15;
                float an = PI / float(sides);
                float bn = fmod(atan2(p.x, p.y) + 2.0 * PI, 2.0 * an) - an;
                float2 q = length(p) * float2(cos(bn), abs(sin(bn)));
                float2 acs = float2(cos(an), sin(an)) * minDim;
                float2 delta = q - acs;
                delta.y += clamp(-delta.y, 0.0, acs.y);
                d = length(delta) * sign(delta.x) - rounding;
            }
            break;
        }
        case 2: // Tab -- param1=top corner radius (0=sharp, 1=half-circle top); rounded top, flat bottom
        {
            d = TabShapeSDF(p, halfSize, param1);
            break;
        }
        case 3: // Hexagon -- flat-top, stretches with halfSize; param1=corner rounding
        {
            float rounding = param1 * minDim * 0.1;
            d = HexagonStretchSDF(p, halfSize, rounding);
            break;
        }
        case 4: // Octagon -- stretches with halfSize; param1=corner cut amount
        {
            d = OctagonSDF(p, halfSize, param1);
            break;
        }
        case 100: // Texture SDF -- shape sampled from Texture2DArray layer
        {
            int   tl = (int)((texLayer > -1.5) ? texLayer : _ButtonShapeTexLayer);
            float2 ts = (texScale.x + texScale.y > 0.001) ? texScale : _ButtonShapeTexScale;
            float2 texUV = (p / halfSize) * ts * 0.5 + 0.5;
            d = sampleTextureSDF(texUV, tl) * minDim;
            break;
        }
        default:
        {
            // Default: Squircle behaviour
            float r = minDim * (1.0 - saturate(param1));
            d = RoundedRectSDF(p, halfSize, r);
            break;
        }
    }

    // Apply universal roundness (post-SDF rounding)
    d -= _ButtonRoundness * minDim * 0.15;

    return d;
}

#endif // SDF_BUTTON_SHAPES_INCLUDED