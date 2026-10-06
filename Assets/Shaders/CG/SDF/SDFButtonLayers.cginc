// SDFButtonLayers.cginc
// Shared helper functions and layer compositing for SDFButton and SDFButtonRM shaders.
// Include AFTER SDFButtonUniforms.cginc and core .cginc files.
//
// Provides: compositeOver, shadowEdgeAlpha, calculateButtonShadow,
//           calculateButtonEdgeIndent, calculateButtonBorder,
//           RenderBevelWithPatternAndGradient, CalculateRimFromSDF,
//           getIconSDF

#ifndef SDFBUTTON_LAYERS_INCLUDED
#define SDFBUTTON_LAYERS_INCLUDED

// Button body shape dispatcher
// Shared shadow model (UIShadowEdgeAlpha / UIShadowPenumbra / UI_SHADOW_CONTACT_BLUR)
// and the shared ring profile (UIRingMask). Included here rather than relied on from the
// parent shader so this file stays self-contained regardless of include order.
#include "../Core/UILighting.cginc"
#include "../Core/UIRing.cginc"
#include "SDFButtonShapes.cginc"

// ---- Antialiasing helper ----
float getSDFAlphaButton(float dist)
{
    float aa = fwidth(dist) * 0.75;
    return smoothstep(aa, -aa, dist);
}

// ---- Icon SDF (same shapes as knob nubs) ----
// Uses the nub shape set from SDFKnobLayers — circles, rectangles, arrows, stars, etc.
// Texture SDF uniforms for icon.
uniform float  _IconShapeTexLayer;
uniform float2 _IconShapeTexScale;

float getIconSDF(float2 p, float shapeType, float width, float height, float param1, float param2, float param3)
{
    int shape = (int)shapeType;

    [forcecase]
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
        case 5: // Diamond
        {
            float2 a = float2(0, -height * 0.5);
            float2 b = float2(-width * 0.5, 0);
            float2 c = float2(0, height * 0.5);
            float2 d = float2(width * 0.5, 0);
            float tri1 = TriangleSDF(p, a, b, c);
            float tri2 = TriangleSDF(p, a, c, d);
            return min(tri1, tri2);
        }
        case 6: // Play button (triangle pointing right)
        {
            float2 a = float2(-width * 0.3, -height * 0.4);
            float2 b = float2(-width * 0.3, height * 0.4);
            float2 c = float2(width * 0.4, 0);
            return TriangleSDF(p, a, b, c);
        }
        case 7: // Line (vertical) — param1=cornerRadius
            return RoundedRectSDF(p, float2(width * 0.1, height * 0.5), param1);
        case 8: // Line (horizontal) — param1=cornerRadius
            return RoundedRectSDF(p, float2(width * 0.5, height * 0.1), param1);
        case 9: // Dot
            return CircleSDF(p, min(width, height) * 0.2);
        case 10: // Arrow — pointing upward; param1=headWidth, param2=tailWidth
        {
            float2 tailPt = float2(0, height * 0.5);
            float2 headPt = float2(0, -height * 0.5);
            float tailW = width * lerp(0.08, 0.45, param2);
            float headW = width * lerp(0.30, 0.90, param1);
            return ArrowSDF(p, tailPt, headPt, tailW, headW);
        }
        case 11: // Star — param1=innerRatio, param2=pointCount
        {
            int pts = clamp((int)(param2 * 6.0 + 3.5), 3, 9);
            float r = min(width, height) * 0.5;
            float m = lerp(4.0, 1.6, param1);
            return StarSDF(p, r, pts, m);
        }
        case 12: // Cross/Plus — param1=armWidthRatio, param2=rounding
        {
            float armW = min(width, height) * lerp(0.1, 0.5, param1);
            float armL = max(width, height) * 0.5;
            float rnd = param2 * armW * 0.5;
            return CrossSDF(p, float2(armL, armW), rnd);
        }
        case 13: // Heart
        {
            float scale = min(width, height) * 0.65;
            return HeartSDF(p / max(0.001, scale)) * scale;
        }
        case 14: // Hexagon
            return HexagonSDF(p, min(width, height) * 0.5);
        case 15: // Pentagon
            return PentagonSDF(p, min(width, height) * 0.5);
        case 16: // Eye — almond outline ring + pupil dot (solo)
        {
            float dim = min(width, height);
            float w2 = width * 0.5;
            float h2 = dim * 0.30; // almond half-height
            // Vesica: intersection of two circles, centers offset vertically.
            float c = (w2 * w2 - h2 * h2) / max(1e-4, 2.0 * h2) * 0.5;
            float r = c + h2;
            float dTop = length(p - float2(0, -c)) - r;
            float dBot = length(p + float2(0, -c)) - r;
            float vesica = max(dTop, dBot);
            float outline = abs(vesica) - dim * 0.055;
            float pupil = CircleSDF(p, dim * 0.16);
            return min(outline, pupil);
        }
        case 17: // SpeakerOff — speaker body (driver rect + cone) + X (mute)
        {
            float dim = min(width, height);
            // Driver rect (left)
            float body = RectangleSDF(p - float2(-dim * 0.33, 0), float2(dim * 0.09, dim * 0.13));
            // Cone: trapezoid widening rightward, as two triangles
            float2 ta = float2(-dim * 0.26, -dim * 0.13);
            float2 tb = float2(-dim * 0.26,  dim * 0.13);
            float2 tc = float2( dim * 0.02,  dim * 0.36);
            float2 td = float2( dim * 0.02, -dim * 0.36);
            float cone = min(TriangleSDF(p, ta, tb, tc), TriangleSDF(p, ta, tc, td));
            float speaker = min(body, cone);
            // X: two 45-degree bars right of the cone
            float2 pc = p - float2(dim * 0.28, 0);
            float2 q1 = float2((pc.x + pc.y) * 0.7071, (pc.y - pc.x) * 0.7071);
            float2 q2 = float2((pc.x - pc.y) * 0.7071, (pc.y + pc.x) * 0.7071);
            float bar1 = RoundedRectSDF(q1, float2(dim * 0.17, dim * 0.045), dim * 0.03);
            float bar2 = RoundedRectSDF(q2, float2(dim * 0.17, dim * 0.045), dim * 0.03);
            return min(speaker, min(bar1, bar2));
        }
        case 18: // Speaker — speaker body + two sound-wave arcs
        {
            float dim = min(width, height);
            float body = RectangleSDF(p - float2(-dim * 0.33, 0), float2(dim * 0.09, dim * 0.13));
            float2 ta = float2(-dim * 0.26, -dim * 0.13);
            float2 tb = float2(-dim * 0.26,  dim * 0.13);
            float2 tc = float2( dim * 0.02,  dim * 0.36);
            float2 td = float2( dim * 0.02, -dim * 0.36);
            float cone = min(TriangleSDF(p, ta, tb, tc), TriangleSDF(p, ta, tc, td));
            float speaker = min(body, cone);
            // Arcs: rings clipped to the right half-plane of their center
            float2 pc = p - float2(dim * 0.06, 0);
            float ring1 = max(abs(length(pc) - dim * 0.20) - dim * 0.045, -pc.x);
            float ring2 = max(abs(length(pc) - dim * 0.34) - dim * 0.045, -pc.x);
            return min(speaker, min(ring1, ring2));
        }
        case 19: // Close — X of two 45-degree bars
        {
            // Bolder than it was (0.38 long / 0.07 thick): a close X is the one mark on the screen
            // that must read at a glance, and at the old weight it was a faint pencil tick on a
            // grey lozenge (2026-09-18, user feedback). Only close skins use this shape.
            float dim = min(width, height);
            float2 q1 = float2((p.x + p.y) * 0.7071, (p.y - p.x) * 0.7071);
            float2 q2 = float2((p.x - p.y) * 0.7071, (p.y + p.x) * 0.7071);
            float bar1 = RoundedRectSDF(q1, float2(dim * 0.44, dim * 0.105), dim * 0.09);
            float bar2 = RoundedRectSDF(q2, float2(dim * 0.44, dim * 0.105), dim * 0.09);
            return min(bar1, bar2);
        }
        case 20: // Chevron — ">" of two angled bars; param1 flips direction (0=right, 1=down)
        {
            float dim = min(width, height);
            float2 pp = (param1 > 0.5) ? float2(p.y, p.x) : p;
            float2 c1 = pp - float2(0, -dim * 0.16);
            float2 c2 = pp - float2(0,  dim * 0.16);
            float2 q1 = float2((c1.x + c1.y) * 0.7071, (c1.y - c1.x) * 0.7071);
            float2 q2 = float2((c2.x - c2.y) * 0.7071, (c2.y + c2.x) * 0.7071);
            float bar1 = RoundedRectSDF(q1, float2(dim * 0.24, dim * 0.07), dim * 0.05);
            float bar2 = RoundedRectSDF(q2, float2(dim * 0.24, dim * 0.07), dim * 0.05);
            return min(bar1, bar2);
        }
        case 29: // Power — IEC 5010 mark: a ring broken at 12 o'clock with an upright bar
        {
            // Same proportions as PanelIcons' "power" glyph (the transport's key wears that one),
            // scaled so the ring's outer edge lands just inside the icon box: these lamps are
            // ~20 units across on screen and a mark drawn at the usual 0.4-of-the-box icon size
            // was a grey smudge. -y is UP here, as everywhere in this switch (see case 4).
            float dim = min(width, height);
            float2 pc = p - float2(0, dim * 0.072);   // ring sits a touch low, so the bar can overhang
            float ring = abs(length(pc) - dim * 0.41) - dim * 0.072;
            // The break the bar passes through — cut wider than the bar so the ring's two ends
            // stay visibly separate from it at small sizes.
            float gap  = RectangleSDF(p - float2(0, -dim * 0.372), float2(dim * 0.12, dim * 0.252));
            ring = max(ring, -gap);
            float bar  = RoundedRectSDF(p - float2(0, -dim * 0.30), float2(dim * 0.084, dim * 0.252), dim * 0.024);
            return min(ring, bar);
        }
        case 100: // Texture SDF — shape sampled from a Texture2DArray layer
        {
            // THE path for a mark this switch cannot express — a drawing rather than a
            // primitive. PanelGlyph puts the app's own icons through here (PanelGlyphAtlas
            // bakes them into the array), which is why the two fixes below finally matter:
            // nothing had ever actually rendered this case.
            float iconDim = min(width, height);
            // ICON SPACE IS +x RIGHT, -y UP (see case 4, whose "pointing up" apex is at -y), and
            // v is up in a texture — so the y sample is flipped and x is not. It is each calling
            // shader's job to hand this function a p in that space: SDFButton flips y out of
            // screen space, SDFButtonRM flips x out of its face projection, whose lateral axis
            // points left. Getting that wrong is invisible on a rounded rect and unmissable on an
            // arrow, which is exactly how it was found.
            float2 texUV = (float2(p.x, -p.y) / (float2(width, height) * 0.5)) * _IconShapeTexScale * 0.5 + 0.5;
            // sampleTextureSDF returns distance/spread; recovering the distance needs the
            // spread back. Same correction SDFKnobShapes has always applied to its own copy of
            // this lookup — without it the zero crossing is still in the right place (so a
            // plain mask looks fine) but every distance around it is 1/spread too big, which is
            // what the icon bevel and rim read.
            float spreadCorr = max(_SDFShapeTexSpread, 0.001);
            float texDist = sampleTextureSDF(saturate(texUV), (int)_IconShapeTexLayer)
                            * spreadCorr * iconDim * 0.5;

            // The field only exists INSIDE its slice, and saying where it stops is not optional:
            // the array is clamp-addressed, so a uv past the edge repeats the border texel across
            // the rest of the button, and a mark drawn to the full extent of its slice has border
            // texels that are INSIDE it. (Seen for real: the takes and grid keys grew crosshairs
            // spilling out past their plates, while the duck, which has margins, looked fine.)
            //
            // Intersected with the box rather than cut off at it. An early `return` out here is
            // the obvious fix and it leaves a visible 1px frame: the distance jumps at the
            // boundary, `fwidth` in the caller's antialiasing explodes on that line, and the mask
            // resolves to a half-covered ring. max() against a SIGNED box keeps the field
            // continuous, so the derivative stays sane and the seam disappears.
            float2 q = (abs(texUV - 0.5) - 0.5) * iconDim;
            float box = min(max(q.x, q.y), 0.0) + length(max(q, 0.0));
            return max(texDist, box);
        }
        default:
            return CircleSDF(p, min(width, height) * 0.5);
    }
}

// ---- Premultiplied alpha compositing ----
void buttonCompositeOver(inout float4 dst, float3 srcColor, float blendAlpha)
{
    float oneMinusAlpha = 1.0 - blendAlpha;
    dst.rgb = dst.rgb * oneMinusAlpha + srcColor * blendAlpha;
    dst.a = dst.a + blendAlpha * (1.0 - dst.a);
}

// ---- Shadow helpers ----
// aaWidth: one screen pixel, expressed in the same units as sdfDist — the floor that keeps
// a contact-sharp shadow from stair-stepping and crawling as the light moves. Pass 0 to opt
// out (the 2D SDFButton callers below do).
// DEPRECATED SHAPE, KEPT AS A WRAPPER. Everything now resolves to UIShadowEdgeAlpha
// (UILighting.cginc), which is symmetric about the silhouette and shared with the knob and
// slider. `blurFactor` and `dirBlend` are ignored: they were this function's attempt at
// contact hardening — widen the blur with distance along the light — and it could only ever
// be a per-widget guess, because it ramped across the whole quad rather than along the
// actual throw. Real contact hardening now lives in the cast functions, which know where
// along the sweep each pixel sits (see UIShadowPenumbra). occluderR defaults to 1 (the
// quad's own half-size), which is within ~20% of a typical widget's half-extent, so the
// sites that don't pass it are unchanged in practice.
float buttonShadowEdgeAlpha(float sdfDist, float blur, float blurFactor, float dirBlend,
                            float aaWidth = 0.0, float occluderR = 1.0)
{
    return UIShadowEdgeAlpha(sdfDist, UI_SHADOW_CONTACT_BLUR(blur, occluderR), aaWidth);
}


// Convert a distance measured in the BUTTON's tilt frame into a SCREEN distance.
//
// The tilt frame stretches its second axis by 1/cosT, so it is anisotropic and a single
// `sD * cosT` cannot undo it: that scale is correct for the foreshortened (tiltDir) axis
// and wrong by 1/cosT across it. At _ViewTilt 7 that understates across-axis distance 2.2x
// and at tilt 10 by 6.7x, spreading the blur band sideways until the taper is swamped.
//
// The right conversion is the screen length of a unit step along the SDF's own outward
// direction. normalize(bxz) is that direction exactly for a circle and closely for the
// rounded shapes used here. Identity at cosT = 1, so untilted widgets are unchanged.
float buttonTiltToScreenDist(float sdfDist, float2 bxz, float cosTsafe)
{
    float2 nb = normalize(bxz + float2(1e-6, 1e-6));
    return sdfDist * length(float2(nb.x, nb.y * cosTsafe));
}

// Calculate external shadow (circular projection behind button)
float calculateButtonExternalShadow(float2 uv, float3 lightDir, float blur, float dist, float blurFactor,
                                     float bodyHalfW, float bodyHalfH, int bodyShapeType,
                                     float bodyParam1, float bodyParam2, float bodyParam3,
                                     float2 aspectScale, float bodyShapeRotation)
{
    float2 ld2 = normalize(lightDir.xy);
    // Position and offset are computed separately: the base position is scaled into
    // aspect-space (matching bodyHalfW/H's own units), then the light-direction offset is
    // added directly in that same space. Multiplying the offset by aspectScale too (as before)
    // stretched it disproportionately along whichever axis had the larger aspectScale, so the
    // shadow drifted further off-axis the wider/taller the control got. At aspectScale=(1,1)
    // this is numerically identical to the old form, so square controls are unaffected.
    float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist * 2.0;

    // Rotate sample position into shape-local space to match body rotation
    float2 sPosRot = (abs(bodyShapeRotation) > 0.001) ? rotate2D(sPos, bodyShapeRotation) : sPos;

    // Evaluate button shape SDF at shadow position (half-extents already aspect-corrected by caller)
    float sD = getButtonSDF(sPosRot, bodyHalfW, bodyHalfH, bodyShapeType, bodyParam1, bodyParam2, bodyParam3);

    // No cast here (this is the flat drop shadow behind the widget), so there is no
    // distance term to add — just the skin's own contact softness, through the same
    // shared edge every other shadow in the project now uses.
    return UIShadowEdgeAlpha(sD, UI_SHADOW_CONTACT_BLUR(blur, max(bodyHalfW, bodyHalfH)), 0.0);
}

// Calculate body shadow with hull sweep (for 3D appearance)
float calculateButtonBodyShadow(float2 uv, float3 lightDir,
                                 float blur, float dist, float blurFactor, float castMul,
                                 float bodyHalfW, float bodyHalfH, int bodyShapeType,
                                 float bodyParam1, float bodyParam2, float bodyParam3,
                                 float faceInset, float pseudoHeight,
                                 float2 aspectScale, float bodyShapeRotation,
                                 float faceHoleEnabled, float aaUnit = 0.0)
{
    float2 ld2 = normalize(lightDir.xy);
    // See calculateButtonExternalShadow above: offset is added after aspect-scaling the base
    // position, not multiplied by aspectScale itself, so it no longer stretches off-axis.
    float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist * 2.0;
    bool doRot = abs(bodyShapeRotation) > 0.001;

    // Base shape SDF at shadow position — rotate into shape-local space
    float2 sPosRot = doRot ? rotate2D(sPos, bodyShapeRotation) : sPos;
    float sD = getButtonSDF(sPosRot, bodyHalfW, bodyHalfH, bodyShapeType, bodyParam1, bodyParam2, bodyParam3);
    float maxDim = max(bodyHalfW, bodyHalfH);

    // Penumbra half-width AT THE CONTACT POINT — the skin's own softness, in the same
    // relative-to-occluder unit the RM shaders use, so one authored number means the same
    // visual softness everywhere. See UILighting.cginc's shared shadow model.
    float penHalf  = UI_SHADOW_CONTACT_BLUR(blur, maxDim);
    float umbraMul = 1.0;

    // Cast: hull sweep from base to face tip projected along light
    if (castMul > 0.001 && pseudoHeight > 0.001) {
        float ps = pseudoHeight * castMul;
        float2 topOff = -ld2 * ps;

        // Face size (smaller top of beveled shape).
        // Nine-slice: subtract faceInset uniformly from both axes so the shadow
        // tapers by the same screen-pixel amount on all sides.
        float faceHalfW = max(0.001, bodyHalfW - faceInset);
        float faceHalfH = max(0.001, bodyHalfH - faceInset);

        // CONTACT HARDENING: t is where along the throw this pixel sits, 0 at the foot of
        // the body and 1 at the projected tip, so the penumbra opens up and the umbra
        // dissolves with distance from the contact line instead of one flat softness being
        // applied across the whole shadow (which is the look of a card hovering above it).
        float castLen = length(topOff);
        float segLen2 = dot(topOff, topOff);
        float t = saturate(-dot(sPos, topOff) / max(0.0001, segLen2));
        float2 fall = UIShadowPenumbra(castLen * t, maxDim, blurFactor);
        penHalf    += fall.x;
        umbraMul    = fall.y;

        // The hull, swept: for two convex sets the convex hull is EXACTLY the union over
        // s in [0,1] of their linear interpolation, so a uniform sweep with a running min
        // IS the hull. One closest-point sample min'd against the tip's own footprint
        // (what was here) is only correct when the swept shape does not change size; this
        // one tapers by faceInset, and the two fields notched each other around the corners.
        int   hullN = UIShadowHullSamples(castLen, maxDim);
        float invN  = 1.0 / (float)max(hullN - 1, 1);
        UNITY_LOOP for (int hs = 1; hs < hullN; hs++) {
            float  s        = (float)hs * invN;
            float2 sPosS    = sPos + topOff * s;
            float2 sPosSRot = doRot ? rotate2D(sPosS, bodyShapeRotation) : sPosS;
            float  hullHalfW = lerp(bodyHalfW, faceHalfW, s);
            float  hullHalfH = lerp(bodyHalfH, faceHalfH, s);
            sD = min(sD, getButtonSDF(sPosSRot, hullHalfW, hullHalfH,
                                      bodyShapeType, bodyParam1, bodyParam2, bodyParam3));
        }
    }

    // When face is hidden (ring/outline mode) punch out the interior of the shadow
    // so only the ring silhouette casts a shadow. Ring SDF = max(outer, -inner).
    if (faceHoleEnabled > 0.5 && faceInset > 0.0001) {
        sD = max(sD, -sD - faceInset);
    }

    return UIShadowEdgeAlpha(sD, penHalf, aaUnit) * umbraMul;
}

// ---- Edge and Border for the button: ONE ring, two falloffs ----
// Both measure from the SAME field — the body SDF in whatever frame the caller hands over
// (frag2dBodyPos on the RM path, so the ring follows the tilted/FOV-projected footprint the
// body is actually drawn at). They differ only in `falloff`; see UIRingMask.
float calculateButtonEdgeIndent(float2 uv, float2 pos, float indentWidth, float indentSoftness,
                                 float bodyHalfW, float bodyHalfH, int bodyShapeType,
                                 float bodyParam1, float bodyParam2, float bodyParam3,
                                 float edgeInset, float falloff = 1.0)
{
    float bodyDist = getButtonSDF(pos, bodyHalfW, bodyHalfH, bodyShapeType, bodyParam1, bodyParam2, bodyParam3);
    float aa = fwidth(bodyDist) * 0.75;
    return UIRingMask(bodyDist, edgeInset, indentWidth, indentSoftness, falloff, aa);
}

// ---- Border for button ----
float4 calculateButtonBorder(float2 uv, float3 baseColor, float borderWidth, float borderSoftness,
                              float bodyHalfW, float bodyHalfH, int bodyShapeType,
                              float bodyParam1, float bodyParam2, float bodyParam3,
                              float2 aspectScale, out float territory,
                              float borderInset = 0.0, float falloff = 0.0)
{
    float2 pos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale;

    // Same ring profile the Edge uses — see UIRingMask. falloff 0 is this function's original
    // shape (flat across the band, soft only where it terminates).
    float bodyDist   = getButtonSDF(pos, bodyHalfW, bodyHalfH, bodyShapeType, bodyParam1, bodyParam2, bodyParam3);
    float borderAA   = fwidth(bodyDist) * 0.75;
    float borderMask = UIRingMask(bodyDist, borderInset, borderWidth, borderSoftness, falloff, borderAA);

    territory = borderMask;
    return float4(baseColor, borderMask);
}

// ---- Bevel rendering with pattern and gradient (reusable from knob) ----
struct ButtonBevelRenderResult {
    float3 litColor;
    float3 normal;
    float bevelMask;
};

ButtonBevelRenderResult RenderButtonBevelWithPatternAndGradient(
    float2 uv, float2 uvIso, float3 cleanBaseColor, float3 mainPatternedColor, float3 normal,
    float shapeDist,
    float bevelDepth, float bevelDistance, float bevelSmoothness,
    float bevelActive,  // 1 = bevel enabled; gates bevel pattern/gradient
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
    float time, UILight light1, UILight light2, UILight light3)
{
    ButtonBevelRenderResult result;
    result.litColor = mainPatternedColor;
    result.normal = normal;
    result.bevelMask = 0.0;

    float distFromEdge = max(0.0, -shapeDist);
    float scaledBevelDistance = bevelDistance;
    float scaledBevelSmoothness = bevelSmoothness;
    float bevelFactor = smoothstep(scaledBevelDistance, max(0.0001, scaledBevelDistance - scaledBevelSmoothness), distFromEdge);
    result.bevelMask = bevelFactor;

    bool hasBevelEffects = (bevelActive > 0.5) && ((bevelPatternEnabled > 0.5) || (bevelGradientEnabled > 0.5));

    if (hasBevelEffects && bevelFactor > 0.001) {
        float3 bevelColor = cleanBaseColor;

        if (bevelGradientEnabled > 0.5) {
            float4 gradientColor = CalculateGradient(uv, bevelGradientColorA, bevelGradientColorB,
                                                   bevelGradientColorC, bevelGradientColorD,
                                                   bevelGradientDirection, bevelGradientType,
                                                   bevelGradientSpeed, bevelGradientScale,
                                                   bevelGradientOffset, time, bevelGradientColorUsed);
            bevelColor = gradientColor.rgb;
        }

        if (bevelPatternEnabled > 0.5) {
            UIComponent bevelPatternComponent = CreateUIComponent(
                float4(1, 1, 1, 1), 1.0,
                0.0, 0.0, 0.0, 0.0,
                float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                float2(1, 0), 1.0, 1.0, 0.0, 0.0, 1.0, 0,
                bevelPatternType, bevelPatternScale, bevelPatternIntensity, bevelPatternContrast,
                bevelPatternSpecularEffect, bevelPatternRoughnessEffect, 1.0,
                0.0, 0.0, 1.0, 0.0,
                bevelPatternParam1, bevelPatternParam2, bevelPatternParam3,
                0.0, 1.0,
                bevelPatternColorEnabled, bevelPatternColorMode,
                bevelPatternColorType, bevelPatternColorUsed,
                bevelPatternColorA, bevelPatternColorB,
                bevelPatternColorC, bevelPatternColorD
            );
            float specularMod;
            float2 normalOffset;
            bevelColor = ApplyMaterialPattern(bevelColor, uvIso, bevelPatternComponent, 0.0, 0.0,
                                             specularMod, normalOffset);
            result.normal = normalize(result.normal + float3(normalOffset * bevelFactor, 0));
        }

        result.litColor = lerp(mainPatternedColor, bevelColor, bevelFactor);
    }

    return result;
}

// ---- Rim bevel from SDF (same as knob version) ----
struct ButtonRimResult {
    float3 litColor;
    float3 normal;
    float rimBevelMask;
};

ButtonRimResult CalculateButtonRimFromSDF(
    float2 uv, float3 litColor, float3 normal, float shapeSDF,
    float rimEnabled, float rimBevelDepth, float rimBevelWidth, float rimBevelSmoothness,
    UILight light1, UILight light2, UILight light3, float2 aspectScale = float2(1,1))
{
    ButtonRimResult result;
    result.litColor = litColor;
    result.normal = normal;
    result.rimBevelMask = 0.0;

    if (rimEnabled < 0.5) return result;

    float distFromEdge = max(0.0, -shapeSDF);
    float scaledRimWidth = rimBevelWidth;
    float scaledRimSmoothness = rimBevelSmoothness;

    if (distFromEdge > scaledRimWidth) return result;

    float2 center = float2(0.5, 0.5);
    float2 toCenter = center - uv;

    float rimBevelFactor = smoothstep(scaledRimWidth, scaledRimWidth - scaledRimSmoothness, distFromEdge);
    result.rimBevelMask = rimBevelFactor;

    if (rimBevelFactor > 0.001) {
        // Use the SDF gradient for the rim tilt direction.
        // SDF is in equi-pixel space — raw ddx/ddy already give equal magnitudes on all
        // edges (no aspectScale division needed; dividing would skew corner rim normals).
        float2 sdfGrad = float2(ddx(shapeSDF), ddy(shapeSDF));
        float gradLen = length(sdfGrad);
        float2 inwardDir = (gradLen > 0.0001) ? (-sdfGrad / gradLen) : normalize(toCenter);
        float3 rimBevelNormal = normalize(float3(inwardDir * rimBevelDepth, 1.0));
        result.normal = normalize(lerp(normal, rimBevelNormal, rimBevelFactor));
    }

    return result;
}

#endif // SDFBUTTON_LAYERS_INCLUDED
