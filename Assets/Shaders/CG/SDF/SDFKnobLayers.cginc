// SDFKnobLayers.cginc
// Shared helper functions and layer compositing for SDFKnob and SDFKnobRM shaders.
// Include AFTER SDFKnobUniforms.cginc and core .cginc files.
//
// Provides: getNubSDF, CalculateArcBevelNormal, shadowEdgeAlpha,
//           calculateExternalShadow, calculateKnobShadow, calculateEdgeIndent,
//           calculateBorder, getCircularMask, compositeOver, getRingMask,
//           CalculateRimFromSDF, CalculateRim, RenderBevelWithPatternAndGradient,
//           getScaleMarkSDF, renderScaleMarks, renderOuterRing, renderGlow.

#ifndef SDFKNOB_LAYERS_INCLUDED
#define SDFKNOB_LAYERS_INCLUDED

// Knob body shape dispatcher (gripNubsSDF, PolygonSDF, ..., getKnobSDF)
// Shared shadow model (UIShadowEdgeAlpha / UIShadowPenumbra / UI_SHADOW_CONTACT_BLUR)
// and the shared ring profile (UIRingMask). Included here rather than relied on from the
// parent shader so this file stays self-contained regardless of include order.
#include "../Core/UILighting.cginc"
#include "../Core/UIRing.cginc"
#include "SDFKnobShapes.cginc"

// ---- Knob-specific SDF helpers (inline) ----

// Get nub SDF based on shape type
// param1 = primary shape param (replaces legacy "rounding" for shape 2/7/8; shape-specific for others)
// param2, param3 = secondary shape params
float getNubSDF(float2 p, float shapeType, float width, float height, float param1, float param2, float param3)
{
    int shape = (int)shapeType;

    [branch]
    switch (shape) {
        case 0: // Circle
            return CircleSDF(p, min(width, height) * 0.5);
        case 1: // Rectangle
            return RectangleSDF(p, float2(width, height) * 0.5);
        case 2: // Rounded Rectangle — param1=cornerRadius
            return RoundedRectSDF(p, float2(width, height) * 0.5, param1);
        case 3: // Ellipse
            return EllipseSDF(p, float2(width, height) * 0.5);
        case 4: // Triangle (pointing up)
            {
                float2 a = float2(0, -height * 0.5);
                float2 b = float2(-width * 0.5, height * 0.5);
                float2 c = float2(width * 0.5, height * 0.5);
                return TriangleSDF(p, a, b, c);
            }
        // case 5: // Diamond
        //     {
        //         float2 a = float2(0, -height * 0.5);
        //         float2 b = float2(-width * 0.5, 0);
        //         float2 c = float2(0, height * 0.5);
        //         float2 d = float2(width * 0.5, 0);
        //         float tri1 = TriangleSDF(p, a, b, c);
        //         float tri2 = TriangleSDF(p, a, c, d);
        //         return min(tri1, tri2);
        //     }
        // case 6: // Play button (triangle pointing right)
        //     {
        //         float2 a = float2(-width * 0.3, -height * 0.4);
        //         float2 b = float2(-width * 0.3, height * 0.4);
        //         float2 c = float2(width * 0.4, 0);
        //         return TriangleSDF(p, a, b, c);
        //     }
        // case 7: // Line (vertical) — param1=cornerRadius
        //     return RoundedRectSDF(p, float2(width * 0.1, height * 0.5), param1);
        // case 8: // Line (horizontal) — param1=cornerRadius
        //     return RoundedRectSDF(p, float2(width * 0.5, height * 0.1), param1);
        // case 9: // Dot
        //     return CircleSDF(p, min(width, height) * 0.2);
        // case 10: // Arrow — pointing upward; param1=headWidthRatio [0.3..0.9], param2=tailWidthRatio [0.1..0.5]
        //     {
        //         float2 tailPt = float2(0,  height * 0.5);
        //         float2 headPt = float2(0, -height * 0.5);
        //         float tailW = width * lerp(0.08, 0.45, param2);
        //         float headW = width * lerp(0.30, 0.90, param1);
        //         return ArrowSDF(p, tailPt, headPt, tailW, headW);
        //     }
        // case 11: // Star — param1=innerRatio (0=sharp, 1=fat), param2=pointCount [3..9]
        //     {
        //         int pts = clamp((int)(param2 * 6.0 + 3.5), 3, 9);
        //         float r = min(width, height) * 0.5;
        //         float m = lerp(4.0, 1.6, param1); // Inigo's m param: higher = sharper tips
        //         return StarSDF(p, r, pts, m);
        //     }
        // case 12: // Cross/Plus — param1=armWidthRatio, param2=rounding
        //     {
        //         float armW = min(width, height) * lerp(0.1, 0.5, param1);
        //         float armL = max(width, height) * 0.5;
        //         float rnd  = param2 * armW * 0.5;
        //         return CrossSDF(p, float2(armL, armW), rnd);
        //     }
        // case 13: // Heart
        //     {
        //         float scale = min(width, height) * 0.65;
        //         return HeartSDF(p / max(0.001, scale)) * scale;
        //     }
        // case 14: // Hexagon
        //     return HexagonSDF(p, min(width, height) * 0.5);
        // case 15: // Pentagon
        //     return PentagonSDF(p, min(width, height) * 0.5);
        // case 16: // Rhombus — param1=widthStretch makes it wider vs taller
        //     {
        //         float rw = width  * lerp(0.4, 0.6, param1);
        //         float rh = height * lerp(0.6, 0.4, param1);
        //         return RhombusSDF(p, float2(rw, rh));
        //     }
        // case 17: // Ring/Annulus — param1=thickness (fraction of radius)
        //     {
        //         float outerR = min(width, height) * 0.5;
        //         float thick  = outerR * lerp(0.05, 0.5, param1);
        //         return abs(CircleSDF(p, outerR)) - thick;
        //     }
        // case 18: // Cut disk / half-circle — param1=cut height
        //     {
        //         float r = min(width, height) * 0.5;
        //         float h = r * lerp(-1.0, 1.0, param1);
        //         return CutDiskSDF(p, r, h);
        //     }
        // case 19: // Pie sector — param1=half-angle of sector
        //     {
        //         float r = min(width, height) * 0.5;
        //         float ang = lerp(0.05, PI * 0.99, param1);
        //         float2 sc = float2(sin(ang), cos(ang));
        //         return PieSDF(p, sc, r);
        //     }
        default:
            return CircleSDF(p, min(width, height) * 0.5);
    }
}

// Calculate arc bevel normal including rounded ends
float3 CalculateArcBevelNormal(float2 uv, float radius, float thickness, float startAngle, float angleRange,
                             float bevelDepth, float bevelDistance, float bevelSmoothness, float fillFaceSmoothness)
{
    float3 normal = float3(0, 0, 1);

    float2 center = float2(0.5, 0.5);
    float2 pos = (uv - center) * 2.0; // Convert to world space

    // Use our ArcSDF function to get the actual distance to the arc geometry
    float arcDist = ArcSDF(pos, radius, thickness, startAngle, angleRange, _LineRoundedEnabled);

    // Calculate bevel factor based on distance to the actual arc surface
    float scaledBevelDistance = bevelDistance * 0.1;
    float scaledSmoothness = bevelSmoothness * 0.05;
    float bevelFactor = smoothstep(scaledBevelDistance, scaledBevelDistance - scaledSmoothness, abs(arcDist));

    // Calculate gradient direction by sampling nearby points.
    // The raw gradient points OUTWARD (away from arc surface).
    // Negate to point INWARD, matching CalculateCircleBevelNormal convention
    // and the light-travel-direction convention used by ApplyUILighting.
    float epsilon = 0.001;
    float2 gradient = float2(
        ArcSDF(pos + float2(epsilon, 0), radius, thickness, startAngle, angleRange, _LineRoundedEnabled) - arcDist,
        ArcSDF(pos + float2(0, epsilon), radius, thickness, startAngle, angleRange, _LineRoundedEnabled) - arcDist
    ) / epsilon;

    if (length(gradient) > 0.001) {
        float2 normalDir = -normalize(gradient);

        // For negative bevel depths (recessed surfaces), invert the direction
        if (bevelDepth < 0.0) {
            normalDir = -normalDir;
        }

        float totalDepth = bevelFactor * abs(bevelDepth);
        normal.xy = normalDir * totalDepth;
        normal.z = 1.0 - abs(totalDepth) * 0.5;
    }

    return normalize(normal);
}

// Calculate external shadow for main components with bevel-aware casting
// Shared helper: converts an SDF distance into a shadow alpha using centered blur.
// The blur zone straddles the SDF boundary equally (halfBlur each side), so the
// perceptual midpoint of the shadow edge stays fixed when blur changes.
// dirBlend 0 = light-facing (sharp power curve), 1 = trailing (smooth softstep).
// DEPRECATED SHAPE, KEPT AS A WRAPPER. This used `shadowBlur` RAW as the full band width
// while SDFButtonLayers' buttonShadowEdgeAlpha multiplied the same authored 0..1 number by
// 0.05 — a 20x disagreement between two shaders that skins tune side by side, and most of
// why a knob's shadow read as a soft cloud where a button's read as a hard slab. Both now
// resolve to UIShadowEdgeAlpha with the same relative-to-occluder unit.
//
// blurFactor/dirBlend are ignored here for the same reason as in the button's wrapper: they
// were a per-widget stand-in for contact hardening, which now happens per pixel along the
// actual throw (see UIShadowPenumbra).
//
// ⚠ SKINS AUTHORED AGAINST THE OLD SCALE WILL LOOK SHARPER. That is the intended direction —
// a shadow should be sharp where it meets the object — but a knob skin that wanted a broad
// diffuse halo needs its blur raised to get one back.
float shadowEdgeAlpha(float sdfDist, float shadowBlur, float blurFactor, float dirBlend,
                      float occluderR = 1.0)
{
    return UIShadowEdgeAlpha(sdfDist, UI_SHADOW_CONTACT_BLUR(shadowBlur, occluderR), 0.0);
}

float calculateExternalShadow(float2 uv, float3 lightDirection, float shadowBlur, float shadowDistance, float blurFactor)
{
    float2 center = float2(0.5, 0.5);
    float2 lightDir2D = normalize(lightDirection.xy);
    float2 shadowOffset = lightDir2D * shadowDistance;
    float2 shadowPos = (uv - center - shadowOffset) * 2.0;

    // dirBlend: 0 = light-facing side (sharp), 1 = trailing side (soft).
    // Scaled by lineRadius so it covers the geometry range without clamping too early.
    float lightProj = dot(shadowPos, lightDir2D);
    float dirBlend = saturate(0.5 + lightProj / max(0.0001, _LineRadius * 2.0));

    float shadowAlpha = 0.0;

    // Fill shadow
    if (_FillEnabled > 0.5 && _FillRenderAlpha > 0.001) {
        float fillShadowDist = length(shadowPos) - _LineRadius;
        shadowAlpha = max(shadowAlpha, shadowEdgeAlpha(fillShadowDist, shadowBlur, blurFactor, dirBlend));
    }

    // Line shadow — removed: no independent enable toggle, always cast when _LineEnabled was on.

    // Value component shadows
    float valueThickness = _LineWidth * _LineSublineThickness;
    float lineCenterRadius = _LineRadius + _LineWidth * 0.5;
    float currentAngleRange = _AngleRange * _Value;

    // Value filled shadow
    if (_LineEnabled > 0.5 && _LineSublineFilledEnabled > 0.5 && _LineSublineFilledRenderAlpha > 0.001 && currentAngleRange > 0.0) {
        float valueShadowDist = ArcSDF(shadowPos, lineCenterRadius, valueThickness, _AngleStart, currentAngleRange, _LineRoundedEnabled);
        shadowAlpha = max(shadowAlpha, shadowEdgeAlpha(valueShadowDist, shadowBlur, blurFactor, dirBlend));
    }

    // Value unfilled shadow
    if (_LineEnabled > 0.5 && _LineSublineUnfilledEnabled > 0.5 && _LineSublineUnfilledRenderAlpha > 0.001) {
        float unfilledStart = _AngleStart + currentAngleRange;
        float unfilledRange = _AngleRange - currentAngleRange;
        if (unfilledRange > 0.0) {
            float valueShadowDist = ArcSDF(shadowPos, lineCenterRadius, valueThickness, unfilledStart, unfilledRange, _LineRoundedEnabled);
            shadowAlpha = max(shadowAlpha, shadowEdgeAlpha(valueShadowDist, shadowBlur, blurFactor, dirBlend));
        }
    }

    return shadowAlpha;
}

// Calculate knob shadow with bevel-aware casting
float calculateKnobShadow(float2 uv, float3 lightDirection, float shadowBlur, float knobRadius, float shadowDistance, float blurFactor)
{
    float2 center = float2(0.5, 0.5);
    float2 lightDir2D = normalize(lightDirection.xy);
    float2 shadowOffset = lightDir2D * shadowDistance;
    float2 shadowPos = (uv - center - shadowOffset) * 2.0;

    // Calculate knob rotation for shadow position (includes knob rotation offset)
    float knobAngle = (_AngleStart + _AngleRange * _Value + _KnobRotation) * (PI / 180.0);

    // Shadow is cast by the base silhouette
    float2 shadowPosRot = rotate2D(shadowPos, knobAngle);

    // Main knob shadow (negate shape rotation to match RM's XZ coordinate convention)
    float knobShadowDist = getKnobSDF(rotate2D(shadowPosRot, -_KnobShapeRotation * (PI / 180.0)), knobRadius, _KnobShapeType, _KnobShapeScale, _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3, _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6);

    // dirBlend: 0 = light-facing (sharp), 1 = trailing (soft).
    // Raw projection (no normalize) — increases monotonically, no wrap-around at tails.
    float lightProj = dot(shadowPos, lightDir2D);
    float dirBlend = saturate(0.5 + lightProj / max(0.0001, knobRadius * 2.0));

    float knobShadowAlpha = shadowEdgeAlpha(knobShadowDist, shadowBlur, blurFactor, dirBlend);

    return knobShadowAlpha;
}

// Calculate edge indent effect - follow actual rendered geometry
float calculateEdgeIndent(float2 uv, float indentWidth, float indentSoftness,
                          float edgeInset = 0.0, float falloff = 1.0)
{
    float2 center = float2(0.5, 0.5);
    float2 pos = (uv - center) * 2.0;

    float distFromCenter = length(pos);

    // Calculate the distance to the outer boundary of all visible geometry
    float distToGeometry = 10000.0; // Start with very large distance

    // Fill boundary (simple circle)
    if (_FillEnabled > 0.5 && _FillRenderAlpha > 0.001) {
        float fillDist = abs(distFromCenter - _LineRadius);
        distToGeometry = min(distToGeometry, fillDist);
    }

    // Line boundary - calculate distance to the rendered line geometry
    if (_LineEnabled > 0.5 && _LineRenderAlpha > 0.001) {
        float currentAngleRange = _AngleRange * _Value;

        // Check segments individually and get minimum distance to any visible segment
        float minSegmentDist = 10000.0;

        // Segment 1: Where value filled would be
        if (currentAngleRange > 0.0) {
            float filledSegmentSDF = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, _AngleStart, currentAngleRange, _LineRoundedEnabled);
            // Use max(0, distance) to only get positive distances (outside the shape)
            float filledSegmentDist = max(0.0, filledSegmentSDF);
            minSegmentDist = min(minSegmentDist, filledSegmentDist);
        }

        // Segment 2: Where value unfilled would be
        float unfilledStart = _AngleStart + currentAngleRange;
        float unfilledRange = _AngleRange - currentAngleRange;
        if (unfilledRange > 0.0) {
            float unfilledSegmentSDF = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, unfilledStart, unfilledRange, _LineRoundedEnabled);
            // Use max(0, distance) to only get positive distances (outside the shape)
            float unfilledSegmentDist = max(0.0, unfilledSegmentSDF);
            minSegmentDist = min(minSegmentDist, unfilledSegmentDist);
        }

        distToGeometry = min(distToGeometry, minSegmentDist);
    }

    // Value component boundaries
    float valueThickness = _LineWidth * _LineSublineThickness;
    float lineCenterRadius = _LineRadius + _LineWidth * 0.5;
    float currentAngleRange = _AngleRange * _Value;

    // Value filled boundary
    if (_LineEnabled > 0.5 && _LineSublineFilledEnabled > 0.5 && _LineSublineFilledRenderAlpha > 0.001 && currentAngleRange > 0.001) {
        float filledValueSDF = ArcSDF(pos, lineCenterRadius, valueThickness, _AngleStart, currentAngleRange, _LineRoundedEnabled);
        // Use max(0, distance) to only get positive distances (outside the shape)
        float filledValueDist = max(0.0, filledValueSDF);
        distToGeometry = min(distToGeometry, filledValueDist);
    }

    // Value unfilled boundary
    if (_LineEnabled > 0.5 && _LineSublineUnfilledEnabled > 0.5 && _LineSublineUnfilledRenderAlpha > 0.001) {
        float unfilledStart = _AngleStart + currentAngleRange;
        float unfilledRange = _AngleRange - currentAngleRange;
        if (unfilledRange > 0.001) {
            float unfilledValueSDF = ArcSDF(pos, lineCenterRadius, valueThickness, unfilledStart, unfilledRange, _LineRoundedEnabled);
            // Use max(0, distance) to only get positive distances (outside the shape)
            float unfilledValueDist = max(0.0, unfilledValueSDF);
            distToGeometry = min(distToGeometry, unfilledValueDist);
        }
    }

    // No indent if no components are visible
    if (distToGeometry >= 9999.0) {
        return 0.0;
    }

    // The band itself is the SHARED profile — see UIRingMask. What is knob-specific is the
    // distance field above (the outer boundary of everything the knob draws, not just its
    // body), not how the band falls off, and that split is the whole point of the unification.
    float edgeAA = fwidth(distToGeometry) * 0.75;
    return UIRingMask(distToGeometry, edgeInset, indentWidth, indentSoftness, falloff, edgeAA, 0.0);
}

// Calculate cut-in border effect
float4 calculateBorder(float2 uv, float3 baseColor, float borderWidth, float borderSoftness,
                       out float territory, float borderInset = 0.0, float falloff = 0.0)
{
    float2 center = float2(0.5, 0.5);
    float2 pos = (uv - center) * 2.0;

    // Calculate all component boundaries
    float valueThickness = _LineWidth * _LineSublineThickness;
    float extendedLineWidth = max(_LineWidth, valueThickness + 0.02);

    // Get maximum outer radius of all visible components
    float maxOuterRadius = 0.0;

    // Check fill boundary (outer edge)
    if (_FillEnabled > 0.5 && _FillRenderAlpha > 0.001) {
        maxOuterRadius = max(maxOuterRadius, _LineRadius);
    }

    // Check line arc boundary (outer edge)
    if (_LineEnabled > 0.5 && _LineRenderAlpha > 0.001) {
        float lineOuterRadius = _LineRadius + extendedLineWidth;
        maxOuterRadius = max(maxOuterRadius, lineOuterRadius);
    }

    // Check value arc boundaries (outer edge)
    float lineCenterRadius = _LineRadius + _LineWidth * 0.5;
    float valueOuterRadius = lineCenterRadius + valueThickness * 0.5;

    float currentAngleRange = _AngleRange * _Value;

    // Value filled boundary (outer edge)
    if (_LineEnabled > 0.5 && _LineSublineFilledEnabled > 0.5 && _LineSublineFilledRenderAlpha > 0.001 && currentAngleRange > 0.0) {
        maxOuterRadius = max(maxOuterRadius, valueOuterRadius);
    }

    // Value unfilled boundary (outer edge)
    if (_LineEnabled > 0.5 && _LineSublineUnfilledEnabled > 0.5 && _LineSublineUnfilledRenderAlpha > 0.001) {
        float unfilledRange = _AngleRange - currentAngleRange;
        if (unfilledRange > 0.0) {
            maxOuterRadius = max(maxOuterRadius, valueOuterRadius);
        }
    }

    // Calculate distance from current point to the maximum outer edge
    float distFromCenter = length(pos);
    float borderDist = distFromCenter - maxOuterRadius;

    // Calculate antialiasing width
    float borderAA = fwidth(borderDist) * 0.75;

    // Same ring profile the Edge uses — see UIRingMask. falloff 0 is this function's original
    // shape: flat across the band, soft only where it terminates, never inside the control.
    float borderMask = UIRingMask(borderDist, borderInset, borderWidth, borderSoftness, falloff, borderAA);

    // Territory: the full extent where the border has ANY visual presence.
    // Used by the caller to clear underlying content (shadows, etc.) so the
    // soft edge fades cleanly to the background instead of to dark shadows.
    territory = borderMask; // Same as appearance mask - border owns exactly what it draws

    float3 borderColor = baseColor;
    float borderAlpha = borderMask; // Return geometric mask only; _BorderColor.a applied at call site

    return float4(borderColor, borderAlpha);
}

// Get antialiased mask for circular area
float getCircularMask(float2 uv, float radius)
{
    float2 center = float2(0.5, 0.5);
    float dist = length(uv - center) - radius;
    return getSDFAlpha(dist);
}

// Premultiplied alpha compositing ("over" operation)
// Uses displayable source color + blend alpha for coverage.
// After this, dst.rgb is premultiplied and dst.a is correct coverage.
void compositeOver(inout float4 dst, float3 srcColor, float blendAlpha) {
    float oneMinusAlpha = 1.0 - blendAlpha;
    dst.rgb = dst.rgb * oneMinusAlpha + srcColor * blendAlpha;
    dst.a = dst.a + blendAlpha * (1.0 - dst.a);
}

// Get antialiased mask for ring area
float getRingMask(float2 uv, float innerRadius, float outerRadius)
{
    float2 center = float2(0.5, 0.5);
    float dist = length(uv - center);
    float ringDist = max(innerRadius - dist, dist - outerRadius);
    return getSDFAlpha(ringDist);
}

// Rim bevel calculation for edge effects - works with any SDF shape
struct RimResult {
    float3 litColor;
    float3 normal;
    float rimBevelMask;
};

RimResult CalculateRimFromSDF(
    float2 uv, float3 inputColor, float3 normal, float shapeSDF,
    float rimBevelEnabled, float rimBevelDepth, float rimBevelWidth, float rimBevelSmoothness,
    UILight light1, UILight light2, UILight light3)
{
    RimResult result;
    result.litColor = inputColor;
    result.normal = normal;
    result.rimBevelMask = 0.0;

    if (rimBevelEnabled < 0.5) {
        return result;
    }

    // Use the SDF distance to determine rim bevel effect
    // Rim bevel is active when we're close to the edge (small positive or negative SDF values)
    float rimBevelFactor = smoothstep(rimBevelWidth, rimBevelWidth - rimBevelSmoothness, abs(shapeSDF));
    result.rimBevelMask = rimBevelFactor;

    if (rimBevelFactor > 0.001) {
        // Use screen-space derivatives of the SDF to get the edge direction.
        // Negate to point INWARD — same convention as CalculateShapeBevelNormal.
        // This makes the rim lit on the same side as the bevel.
        float2 sdfGradient = float2(ddx(shapeSDF), ddy(shapeSDF));
        float gradLen = length(sdfGradient);
        float2 edgeNormal2D = (gradLen > 0.0001) ? -sdfGradient / gradLen
                                                 : normalize(float2(0.5, 0.5) - uv);

        // Rim bevel normal: positive depth = raised rim, negative = recessed.
        float3 rimBevelNormal = normalize(float3(edgeNormal2D * rimBevelDepth, 1.0));

        // Only modify the normal — the caller's single ApplyUILighting handles all lighting.
        // This avoids double-lighting that previously inverted the rim appearance.
        result.normal = normalize(lerp(normal, rimBevelNormal, rimBevelFactor));
    }

    return result;
}

// Legacy circular rim bevel function - kept for backward compatibility
RimResult CalculateRim(
    float2 uv, float3 inputColor, float3 normal, float componentRadius,
    float rimBevelEnabled, float rimBevelDepth, float rimBevelWidth, float rimBevelSmoothness,
    UILight light1, UILight light2, UILight light3)
{
    RimResult result;
    result.litColor = inputColor;
    result.normal = normal;
    result.rimBevelMask = 0.0;

    if (rimBevelEnabled < 0.5) {
        return result;
    }

    // Calculate distance from edge for rim bevel
    float2 center = float2(0.5, 0.5);
    float2 toCenter = center - uv;
    float distFromCenter = length(toCenter);

    // Convert radius to UV space
    float radiusInUVSpace = componentRadius * 0.5;

    // Scale rim bevel parameters to UV space
    float scaledRimWidth = rimBevelWidth * 0.5;
    float scaledRimSmoothness = rimBevelSmoothness * 0.5;

    // Calculate distance from the outer edge (rim bevel is at the very edge)
    float distFromEdge = abs(radiusInUVSpace - distFromCenter);

    // Rim bevel factor - active only at the very edge
    float rimBevelFactor = smoothstep(scaledRimWidth, scaledRimWidth - scaledRimSmoothness, distFromEdge);
    result.rimBevelMask = rimBevelFactor;

    if (rimBevelFactor > 0.001) {
        // Calculate rim bevel normal — point INWARD (toward center), same convention
        // as CalculateCircleBevelNormal, so rim is lit on the same side as the bevel.
        float2 toEdge = normalize(toCenter);
        float3 rimBevelNormal = normalize(float3(toEdge * rimBevelDepth, 1.0));

        // Only modify the normal — the caller's single ApplyUILighting handles all lighting.
        result.normal = normalize(lerp(normal, rimBevelNormal, rimBevelFactor));
    }

    return result;
}

// Enhanced bevel rendering with pattern and gradient support
struct BevelRenderResult {
    float3 litColor;
    float3 normal;
    float bevelMask;
};

BevelRenderResult RenderBevelWithPatternAndGradient(
    float2 uv, float3 cleanBaseColor, float3 mainPatternedColor, float3 normal, float componentRadius,
    float shapeDist,
    float bevelDepth, float bevelDistance, float bevelSmoothness,
    float bevelPatternEnabled, float bevelPatternType, float bevelPatternScale, float bevelPatternIntensity,
    float bevelPatternContrast, float bevelPatternSpecularEffect, float bevelPatternRoughnessEffect,
    float bevelGradientEnabled, int bevelGradientType, float4 bevelGradientColorA, float4 bevelGradientColorB,
    float4 bevelGradientColorC, float4 bevelGradientColorD, float2 bevelGradientDirection,
    float bevelGradientSpeed, float bevelGradientScale, float bevelGradientOffset,
    float bevelPatternParam1, float bevelPatternParam2, float bevelPatternParam3,
    int bevelGradientColorUsed,
    float bevelPatternColorEnabled, int bevelPatternColorMode,
    int bevelPatternColorType, int bevelPatternColorUsed,
    float4 bevelPatternColorA, float4 bevelPatternColorB,
    float4 bevelPatternColorC, float4 bevelPatternColorD,
    float value, float angleRange, float time, UILight light1, UILight light2, UILight light3)
{
    BevelRenderResult result;
    result.litColor = mainPatternedColor;
    result.normal = normal;
    result.bevelMask = 0.0;

    // SDF-based bevel factor — shapeDist is negative inside, 0 at edge (world space).
    // This makes the bevel pattern zone exactly match the shape outline, including non-circular shapes.
    float distFromEdge = max(0.0, -shapeDist);
    float scaledBevelDistance = bevelDistance;
    float scaledBevelSmoothness = bevelSmoothness;
    float bevelFactor = smoothstep(scaledBevelDistance, max(0.0001, scaledBevelDistance - scaledBevelSmoothness), distFromEdge);
    result.bevelMask = bevelFactor;

    // If bevel pattern or gradient is enabled, we replace the main pattern in bevel areas
    bool hasBevelEffects = (bevelPatternEnabled > 0.5) || (bevelGradientEnabled > 0.5);

    if (hasBevelEffects && bevelFactor > 0.001) {
        // Start with clean base color for bevel areas
        float3 bevelColor = cleanBaseColor;

        // Apply bevel gradient if enabled
        if (bevelGradientEnabled > 0.5) {
            float4 gradientColor = CalculateGradient(uv, bevelGradientColorA, bevelGradientColorB,
                                                   bevelGradientColorC, bevelGradientColorD,
                                                   bevelGradientDirection, bevelGradientType,
                                                   bevelGradientSpeed, bevelGradientScale,
                                                   bevelGradientOffset, time, bevelGradientColorUsed);
            bevelColor = gradientColor.rgb;
        }

        // Apply bevel pattern if enabled
        if (bevelPatternEnabled > 0.5) {
            // Create bevel pattern component with rotation
        UIComponent bevelPatternComponent = CreateUIComponent(
            float4(1, 1, 1, 1), 1.0, // White base for pattern multiplication
            0.0, 0.0, 0.0, 0.0, // No bevel on pattern itself
            float4(1, 1, 1, 1), float4(1, 1, 1, 1), float4(1, 1, 1, 1), float4(1, 1, 1, 1), // No gradient
            float2(1, 0), 1.0, 1.0, 0.0, 0.0, 1.0, 0, // No gradient
            bevelPatternType, bevelPatternScale, bevelPatternIntensity, bevelPatternContrast,
            bevelPatternSpecularEffect, bevelPatternRoughnessEffect, 1.0, // Rotate with value
            0.0, 0.0, 1.0, 0.0, // No modulation, default frequency, no offset for bevel patterns
            bevelPatternParam1, bevelPatternParam2, bevelPatternParam3,
            0.0, 1.0,  // no gradient, but enable pattern
            bevelPatternColorEnabled, bevelPatternColorMode,
            bevelPatternColorType, bevelPatternColorUsed,
            bevelPatternColorA, bevelPatternColorB,
            bevelPatternColorC, bevelPatternColorD
        );                        float specularMod;
            float2 normalOffset;
            bevelColor = ApplyMaterialPattern(bevelColor, uv, bevelPatternComponent, value, angleRange,
                                             specularMod, normalOffset);

            // Apply pattern normal modifications to bevel areas only
            result.normal = normalize(result.normal + float3(normalOffset * bevelFactor, 0));
        }

        // Blend from main patterned color to bevel color based on bevel factor
        result.litColor = lerp(mainPatternedColor, bevelColor, bevelFactor);
    }

    return result;
}

// Helper function to get scale mark SDF
float getScaleMarkSDF(float2 p, int markIndex, float totalMarks, float markType,
                      float startAngle, float angleRange, float radius,
                      float markLength, float thickness, float rounding)
{
    // Calculate angle for this specific mark (in UI degrees)
    float t = float(markIndex) / (totalMarks - 1.0);
    float markAngleUI = startAngle + angleRange * t;

    // Normalize to [0, 360) range
    float normalizedAngle = fmod(markAngleUI + 360.0, 360.0);

    // Convert UI angle to atan2 coordinates
    float atan2Angle;
    if (normalizedAngle <= 180.0) {
        atan2Angle = 180.0 - normalizedAngle;
    } else {
        atan2Angle = 540.0 - normalizedAngle;
    }
    if (atan2Angle >= 360.0) atan2Angle -= 360.0;

    // Convert to radians and calculate direction
    float mathAngle = atan2Angle * (PI / 180.0);
    float2 direction = float2(cos(mathAngle), sin(mathAngle));

    // Calculate mark position
    float2 markPos = direction * radius;

    // Position relative to mark
    float2 localPos = p - markPos;

    // Rotate local position to align with radial direction
    float2 rotatedPos = rotate2D(localPos, -mathAngle);

    // Different mark types
    if (markType < 0.5) {
        // Type 0: Lines (radial ticks)
        float2 markSize = float2(thickness, markLength);
        float d = RectangleSDF(rotatedPos, markSize * 0.5);

        // Apply rounding if enabled
        if (rounding > 0.001) {
            d -= rounding * thickness * 0.5;
        }
        return d;
    }
    else if (markType < 1.5) {
        // Type 1: Dots (circles)
        float dotRadius = max(thickness, markLength * 0.3);
        return length(rotatedPos) - dotRadius;
    }
    else if (markType < 2.5) {
        // Type 2: Arc segments - handled differently (return negative for now)
        return -1.0;
    }
    else {
        // Type 3: Mixed - use dots for minor, lines for major (decided by caller)
        float2 markSize = float2(thickness, markLength);
        return RectangleSDF(rotatedPos, markSize * 0.5);
    }
}

// Helper function to render scale marks
float4 renderScaleMarks(float2 pos, float4 currentColor, inout float3 emissiveAccum)
{
    if (_OuterMarksEnabled < 0.5 || _OuterMarksCount < 2) {
        return currentColor;
    }

    float4 result = currentColor;

    // Arc mode (type 2) - render as segmented arc
    if (_OuterMarksType > 1.5 && _OuterMarksType < 2.5) {
        // Calculate arc parameters
        float arcRadius = _OuterMarksRadius * (_LineRadius + _LineWidth);
        float arcThickness = _OuterMarksArcThickness;
        float gapSize = _OuterMarksArcGapSize;

        // Calculate total angle per segment including gap
        float anglePerMark = _OuterMarksAngleRange / (_OuterMarksCount - 1.0);

        // Render each arc segment
        for (int i = 0; i < int(_OuterMarksCount); i++) {
            if (i >= int(_OuterMarksCount) - 1) break; // Don't render last segment gap

            // Calculate segment angle range (subtract gap)
            float segmentStart = _OuterMarksAngleStart + anglePerMark * float(i);
            float segmentRange = anglePerMark - (gapSize * 180.0 / PI); // Convert gap to degrees

            if (segmentRange > 0.001) {
                // Calculate SDF for this arc segment
                float segmentDist = ArcSDF(pos, arcRadius, arcThickness, segmentStart, segmentRange, _LineRoundedEnabled);
                float segmentAA = fwidth(segmentDist) * 0.75;
                float segmentMask = smoothstep(segmentAA, -segmentAA, segmentDist);

                if (segmentMask > 0.001) {
                    // Determine mark position as value (0-1) based on angle
                    float markValue = float(i) / (_OuterMarksCount - 1.0);

                    // Choose color: filled when value >= mark position, but special case for value=0 and first mark
                    bool shouldBeFilled = (_Value >= markValue) && !(_Value == 0.0 && markValue == 0.0);
                    float4 markColor = shouldBeFilled ? _OuterMarksColorFilled : _OuterMarksColorUnfilled;
                    float markAlpha = segmentMask * _OuterMarksRenderAlpha;
                    compositeOver(result, markColor.rgb, markAlpha);
                    emissiveAccum += markColor.rgb * segmentMask * _OuterMarksRenderEmissive;
                }
            }
        }
    }
    else {
        // Line or dot mode - render individual marks
        float baseRadius = _OuterMarksRadius * (_LineRadius + _LineWidth);

        for (int i = 0; i < int(_OuterMarksCount); i++) {
            if (i >= int(_OuterMarksCount)) break;

            // Determine mark position as value (0-1) based on angle
            float markValue = float(i) / (_OuterMarksCount - 1.0);

            // Determine if this is a major tick
            bool isMajorTick = (_OuterMarksMajorEnabled > 0.5) &&
                              (_OuterMarksMajorInterval >= 1.0) &&
                              (i % int(_OuterMarksMajorInterval) == 0);

            // Calculate mark parameters
            float markLength = _OuterMarksLength;
            float markThickness = _OuterMarksThickness;
            float4 markColor;
            float currentMarkType = _OuterMarksType;

            if (isMajorTick) {
                markLength *= _OuterMarksMajorLengthMultiplier;
                markThickness *= _OuterMarksMajorThicknessMultiplier;
                // Choose major tick color: filled when value >= mark position, but special case for value=0 and first mark
                bool shouldBeFilled = (_Value >= markValue) && !(_Value == 0.0 && markValue == 0.0);
                markColor = shouldBeFilled ? _OuterMarksMajorColorFilled : _OuterMarksMajorColorUnfilled;
            } else {
                // Choose scale mark color: filled when value >= mark position, but special case for value=0 and first mark
                bool shouldBeFilled = (_Value >= markValue) && !(_Value == 0.0 && markValue == 0.0);
                markColor = shouldBeFilled ? _OuterMarksColorFilled : _OuterMarksColorUnfilled;
            }

            // For mixed type, use lines for major, dots for minor
            if (_OuterMarksType > 2.5) {
                currentMarkType = isMajorTick ? 0.0 : 1.0;
            }

            // Calculate SDF for this mark
            float markDist = getScaleMarkSDF(pos, i, _OuterMarksCount, currentMarkType,
                                            _OuterMarksAngleStart, _OuterMarksAngleRange,
                                            baseRadius, markLength, markThickness, _OuterMarksRounding);

            if (markDist > -0.5) { // Skip if invalid (arc type)
                float markAA = fwidth(markDist) * 0.75;
                float markMask = smoothstep(markAA, -markAA, markDist);

                if (markMask > 0.001) {
                    float markAlpha = markMask * _OuterMarksRenderAlpha;
                    compositeOver(result, markColor.rgb, markAlpha);
                    emissiveAccum += markColor.rgb * markMask * _OuterMarksRenderEmissive;
                }
            }
        }
    }

    return result;
}

// Helper function to render outer rings
float4 renderOuterRing(float2 pos, float4 currentColor, float ringEnabled, float ringRadius,
                       float ringThickness, float4 ringColor, float ringStartAngle,
                       float ringAngleRange, float ringStyle, float ringRenderAlpha, float ringEmissive, inout float3 emissiveAccum)
{
    if (ringEnabled < 0.5) {
        return currentColor;
    }

    float4 result = currentColor;

    // Calculate ring SDF
    if (ringStyle < 0.5) {
        // Solid ring
        float ringDist = ArcSDF(pos, ringRadius, ringThickness, ringStartAngle, ringAngleRange, _LineRoundedEnabled);
        float ringAA = fwidth(ringDist) * 0.75;
        float ringMask = smoothstep(ringAA, -ringAA, ringDist);

        if (ringMask > 0.001) {
            compositeOver(result, ringColor.rgb, ringMask * ringRenderAlpha);
            emissiveAccum += ringColor.rgb * ringMask * ringEmissive;
        }
    }
    else if (ringStyle < 1.5) {
        // Dashed ring - create dashes around the ring
        int dashCount = 24;
        float dashAngle = ringAngleRange / float(dashCount);
        float gapRatio = 0.4; // 40% gap

        for (int i = 0; i < dashCount; i++) {
            float dashStart = ringStartAngle + dashAngle * float(i);
            float dashRange = dashAngle * (1.0 - gapRatio);

            float dashDist = ArcSDF(pos, ringRadius, ringThickness, dashStart, dashRange, _LineRoundedEnabled);
            float dashAA = fwidth(dashDist) * 0.75;
            float dashMask = smoothstep(dashAA, -dashAA, dashDist);

            if (dashMask > 0.001) {
                compositeOver(result, ringColor.rgb, dashMask * ringRenderAlpha);
                emissiveAccum += ringColor.rgb * dashMask * ringEmissive;
            }
        }
    }
    else {
        // Dotted ring - create dots around the ring
        int dotCount = 36;
        float dotRadius = ringThickness * 0.4;

        // For full circle (360°), exclude final dot to avoid overlap at start/end
        // For partial arcs, include final dot to complete the range
        int maxIndex = (ringAngleRange >= 360.0) ? (dotCount - 1) : dotCount;

        for (int i = 0; i <= maxIndex; i++) {
            float t = float(i) / float(dotCount);
            float dotAngle = ringStartAngle + ringAngleRange * t;

            // Check if this dot is within the ring's angle range
            if (t <= 1.0) {
                // Convert angle to position
                float normalizedAngle = fmod(dotAngle + 360.0, 360.0);
                float atan2Angle;
                if (normalizedAngle <= 180.0) {
                    atan2Angle = 180.0 - normalizedAngle;
                } else {
                    atan2Angle = 540.0 - normalizedAngle;
                }
                if (atan2Angle >= 360.0) atan2Angle -= 360.0;

                float mathAngle = atan2Angle * (PI / 180.0);
                float2 dotPos = float2(cos(mathAngle), sin(mathAngle)) * ringRadius;

                float dotDist = length(pos - dotPos) - dotRadius;
                float dotAA = fwidth(dotDist) * 0.75;
                float dotMask = smoothstep(dotAA, -dotAA, dotDist);

                if (dotMask > 0.001) {
                    compositeOver(result, ringColor.rgb, dotMask * ringRenderAlpha);
                    emissiveAccum += ringColor.rgb * dotMask * ringEmissive;
                }
            }
        }
    }

    return result;
}

// Helper function to render glow effect
float4 renderGlow(float2 pos, float4 currentColor, float glowEnabled,
                 float glowDist, float4 glowColor, float glowWidth, float glowSoftness, float glowIntensity,
                 float glowRenderAlpha, float glowEmissive, inout float3 emissiveAccum)
{
    if (glowEnabled < 0.5) {
        return currentColor;
    }

    // Create outer glow that extends from the shape edge outward
    // glowDist < 0 = inside shape, glowDist = 0 = at edge, glowDist > 0 = outside shape
    float glowFactor = 0.0;

    // Only render glow outside the shape (glowDist >= 0)
    if (glowDist >= 0.0) {
        // Glow extends from edge (0) to glowWidth with full intensity,
        // then fades from glowWidth to glowWidth+glowSoftness
        if (glowDist < glowWidth) {
            // Within the glow width - full intensity
            glowFactor = 1.0;
        } else {
            // Beyond glow width - fade over softness distance
            float fadeStart = glowWidth;
            float fadeEnd = glowWidth + glowSoftness;
            glowFactor = 1.0 - smoothstep(fadeStart, fadeEnd, glowDist);
        }
    }

    if (glowFactor > 0.001) {
        float glowMask = glowFactor * glowIntensity;
        emissiveAccum += glowColor.rgb * glowMask * glowEmissive;
        compositeOver(currentColor, glowColor.rgb, glowMask * glowRenderAlpha);
        return currentColor;
    }

    return currentColor;
}

#endif // SDFKNOB_LAYERS_INCLUDED
