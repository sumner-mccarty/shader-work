#ifndef UI_LIGHTING_CGINC
#define UI_LIGHTING_CGINC

#include "Constants.cginc"
#include "../SDF/SDFPrimitives.cginc"

// UILight structure for lighting calculations
struct UILight
{
    bool enabled;
    float3 direction;
    float intensity;
    float4 color;
    float specular;
    float specularPower;
};

// Helper function to create a UILight
UILight CreateUILight(float enabled, float3 direction, float intensity, float4 color, float specular, float specularPower)
{
    UILight light;
    light.enabled = enabled > 0.5;
    light.direction = normalize(direction);
    light.intensity = intensity;
    light.color = color;
    light.specular = specular;
    light.specularPower = specularPower;
    return light;
}

// ─────────────────────────────────────────────────────────────────────────────
// THE LIGHT RIG. Three scene lights, shared by every widget, and NO per-material
// lights at all.
//
// Skins used to carry a full copy of each light (_LightingLightNEnabled / Direction /
// Intensity / Color / Specular / SpecularPower) plus a _LightingLightNGlobalEnabled
// flag to pick between that copy and the rig. That is 21 uniforms and three runtime
// branches per shader, in the fragment program, for a choice no skin actually wants
// to make differently — and it is what pushed SDFKnobRM's fragment program past the
// HLSL compiler's time limit. All of it is gone. A light is the rig's light.
//
// Published by UiSceneDirector (runtime) and GlobalLightingPlugin (designer preview),
// both through UiLightRig:
//     _GlobalLightPosN   = (x, y, height)          x aspect-scaled, same space as _Position
//     _GlobalLightColorN = (r, g, b, intensity)
//     _GlobalLightFxN    = (enabled, specular, specularPower, unused)
//
// SHADOW LENGTHS ARE STILL PER-SKIN. _LightingShadowN* / _ButtonShadowN* / _KnobShadowN*
// / _HandleShadowN* all stay exactly as they were — only the LIGHT is shared. A skin
// tunes how long and soft its shadows are; the rig decides where they point.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// SIGN CONVENTION — read before touching this.
//
//   lightDir.xy = the direction the light TRAVELS, lamp → surface.
//   lightDir.z  = + toward the viewer, so a flat face (N = 0,0,1) stays lit.
//
// It is NOT a "to-light" vector, and the two halves genuinely disagree in sign. That
// looks wrong until you check the consumers, which were all written to it:
//   • CalculateShapeBevelNormal uses edgeDir = -sdfGradient, so a raised bevel's normal
//     points INWARD. Lit means dot(N, L) > 0, which needs L.xy pointing away from the lamp.
//   • The flat shadow offset samples at `p - ld2*dist`, drawing the shadow at +ld2 —
//     away from the lamp only if ld2 already points away from it.
// Returning `lightPos - objectPos` here instead (a to-light vector) lit the side AWAY
// from the lamp and threw the shadow onto the SAME side as the lamp — both halves of
// the long-standing bug, from this one sign.
//
// z is the lamp's HEIGHT above the UI plane and is what makes it grazing rather than
// head-on. Clamped, not defaulted: an unpublished rig gives a head-on light rather
// than a degenerate in-plane one.
// ─────────────────────────────────────────────────────────────────────────────
float3 UILightDirection(float3 lightPos, float2 objectPos)
{
    return normalize(float3(objectPos - lightPos.xy, max(lightPos.z, 0.02)));
}

// The 2D↔3D boundary. Raymarched paths rotate the light into a widget's tilted frame
// and use xy and z TOGETHER:
//     lKy = dot(L.xy, tiltDir) * sinT + L.z * cosT;   if (lKy > 0) { ...cast hull... }
// lKy asks "is the lamp above this face?" and can only answer that if xy and z describe
// the same physical direction. Feed it the travel vector and the halves cancel, lKy
// drops under the threshold, and the whole cast-shadow sweep is skipped — knobs and
// buttons lose their drop shadows while their flat shading still looks fine.
float3 UIToLightVector(float3 travelDir)
{
    return float3(-travelDir.xy, travelDir.z);
}

// Build light N. Branchless by construction — there is nothing to choose between.
UILight UIGlobalLight(float3 gPos, float4 gColor, float4 gFx, float2 objectPos)
{
    UILight light;
    light.enabled       = gFx.x > 0.5;
    light.direction     = UILightDirection(gPos, objectPos);
    light.intensity     = gColor.w;
    light.color         = float4(gColor.rgb, 1.0);
    light.specular      = gFx.y;
    light.specularPower = gFx.z;
    return light;
}

// Macros, not functions: the uniforms are declared per-shader (in each SDFxxxUniforms.cginc),
// so a shared function here couldn't see them — a macro expands where they're in scope.
//
// RESOLVE ONCE PER SHADER. Assign UI_LIGHT_N to a local at the top of the fragment and read
// `lightN.direction` everywhere else. These used to be expanded at every shadow call site —
// thirteen times in SDFKnobRM — each redoing the same normalize for an identical result.
#define UI_LIGHT_1 UIGlobalLight(_GlobalLightPos1, _GlobalLightColor1, _GlobalLightFx1, _Position.xy)
#define UI_LIGHT_2 UIGlobalLight(_GlobalLightPos2, _GlobalLightColor2, _GlobalLightFx2, _Position.xy)
#define UI_LIGHT_3 UIGlobalLight(_GlobalLightPos3, _GlobalLightColor3, _GlobalLightFx3, _Position.xy)

#define UI_LIGHT_DIR_1 UILightDirection(_GlobalLightPos1, _Position.xy)
#define UI_LIGHT_DIR_2 UILightDirection(_GlobalLightPos2, _Position.xy)
#define UI_LIGHT_DIR_3 UILightDirection(_GlobalLightPos3, _Position.xy)

// ─────────────────────────────────────────────────────────────────────────────
// DISTANCE FALLOFF FOR A CAST SHADOW — the penumbra model.
//
// Replaces "clamp the throw and carry on at full strength", which is wrong twice over:
// it freezes the shadow at full darkness however far it is thrown, and then ends it in a
// dead straight line at the cap, which is the one thing a shadow never does. Growing the
// backing quad instead only moves that straight line further out, and costs fill rate
// quadratically (2x expansion is 4x the pixels).
//
// What actually happens: a lamp has an angular size, so an occluder at cast distance d
// throws a penumbra of half-width w = d*tan(alpha) — growing LINEARLY with distance —
// while its umbra survives only while the occluder is bigger than that penumbra. Past
// d = R/tan(alpha) there is no umbra left at all and peak darkness falls off as 1/d^2.
// So a distant shadow is not a hard shape further away; it is a broad faint one, and it
// fades out on its own long before any quad edge matters.
//
// x = blur multiplier (penumbra growth), y = alpha multiplier (umbra dissolving).
// blurFactor scales the effective lamp size, so a skin that already asks for softer
// shadows also gets them fading sooner — one knob, both halves of the same physics.
float2 UIShadowDistanceFalloff(float castLen, float occluderHalfSize, float blurFactor)
{
    float R        = max(occluderHalfSize, 0.0001);
    float penumbra = max(castLen, 0.0) * 0.30 * (0.5 + saturate(blurFactor));

    // x is the penumbra measured in occluder half-sizes: the umbra survives while x < 1 and
    // is gone past it. The cubic holds alpha near 1 through that whole range and only then
    // rolls off, which is the point — a long shadow should still be a shadow. A gentler
    // curve like R/(R+w) starts fading immediately and made even mid-length casts wash out.
    float x = penumbra / R;
    return float2(1.0 + penumbra / (0.25 * R), 1.0 / (1.0 + x * x * x));
}

// ─────────────────────────────────────────────────────────────────────────────
// THE SHARED SHADOW MODEL — one set of rules for every widget that casts.
//
// Everything below is deliberately shader-agnostic: the knob, button and slider all
// call these, so "a knob's shadow and a button's shadow are cast the same way" is a
// property of the code rather than of two skins happening to be tuned alike. Before
// this existed the two shaders had SEPARATE edge functions whose authored `blur`
// differed by 20x in meaning (SDFKnobLayers' shadowEdgeAlpha used blur raw as the full
// band width; SDFButtonLayers' buttonShadowEdgeAlpha multiplied it by 0.05), which is
// most of why a knob's shadow read as a soft cloud and a button's as a hard slab.
// ─────────────────────────────────────────────────────────────────────────────

// PENUMBRA, as an absolute half-width rather than a multiplier.
//
// A lamp has angular size, so an occluder edge at cast distance d throws a penumbra of
// half-width w = d*tan(alpha) — and that is a LENGTH, not a scale factor on whatever
// softness the skin happened to author. Returning a multiplier (UIShadowDistanceFalloff,
// above) forces the two to be entangled: a skin that wants a crisp contact edge has to
// author a tiny blur, which then stays tiny at the far end of a long throw as well,
// because the multiplier only reaches ~1.4x for a realistic cast.
//
// Split instead: the skin's `blur` is the base softness AT THE CONTACT POINT, and this
// is added to it as the throw opens up. That is what makes a shadow read as contact —
// razor sharp where the solid meets the surface, broad and faint where it is furthest
// from it — and it is the single biggest reason the old shadows felt like the widget was
// hovering a foot above the panel.
//
// CALL IT PER PIXEL, with castLen scaled by how far along the throw THIS pixel sits (the
// hull sweep's own segment parameter). Calling it once per widget with the full throw —
// what the old code did — gives one uniform softness across the entire shadow, which is
// exactly the look of a flat card floating above the surface.
//
// x = penumbra half-width, in the same units as the SDF distance it will be compared to.
// y = umbra alpha: the shadow's core survives while the penumbra is smaller than the
//     occluder and dissolves once it is not.
float2 UIShadowPenumbra(float castLen, float occluderHalfSize, float blurFactor)
{
    float R        = max(occluderHalfSize, 0.0001);
    // blurFactor IS the lamp's angular size, so 0 is a POINT light: no penumbra at any
    // distance, a hard shadow all the way to the tip.
    //
    // This used to read `0.30 * (0.5 + saturate(blurFactor))`, and that 0.5 was a floor that
    // made a hard shadow unauthorable. It was harmless while this returned a MULTIPLIER on the
    // skin's own blur — blur 0 x anything is still 0 — but the term is ADDITIVE now, so the
    // floor became "every shadow is soft past the contact point, whatever you set". Zeroing a
    // softness control has to mean it.
    //
    // 0.60 rather than 0.30 so the midpoint is unchanged: at blurFactor 0.5 this is exactly
    // what the old expression returned, which is where every shipped skin sits.
    float penumbra = max(castLen, 0.0) * 0.60 * saturate(blurFactor);
    float x        = penumbra / R;
    return float2(penumbra, 1.0 / (1.0 + x * x * x));
}

// The skin's authored blur (0..1), as a penumbra half-width at the contact point.
// Relative to the occluder's own half-size, so the same authored number means the same
// visual softness on a 20px lamp and a 200px pad — and, more to the point, on a knob and
// on a button.
#define UI_SHADOW_CONTACT_BLUR(blur, R) ((blur) * 0.08 * (R))

// THE SHADOW EDGE. Symmetric about the silhouette: halfWidth is the distance from the
// alpha=0.5 contour to full light, so raising it softens the shadow without growing it.
// aaUnit is one screen pixel in the same units — the floor that stops a sharp contact
// edge from stair-stepping.
float UIShadowEdgeAlpha(float sdfDist, float halfWidth, float aaUnit)
{
    float w = max(halfWidth, aaUnit);
    return smoothstep(w, -w, sdfDist);
}

// WHO DRAWS WHICH HALF OF A WIDGET'S OWN SHADOW.
//
// A caster cannot both write its shadow into the shared buffer AND read that buffer, or it
// multiplies its own shadow back over its own face. But it has to read the buffer, or it
// never receives anything from its neighbours — which is what made a pad's shadow stop dead
// at the edge of the pad beside it.
//
// So the shadow is split at the caster's OWN QUAD, and the two halves are exact complements:
//
//   outside the quad  -> the shadow pass writes it, every other surface reads it from the
//                        buffer. This is the half that lands on the faceplate and on
//                        neighbouring widgets.
//   inside the quad   -> the WIDGET draws it itself, in its own fragment program, before its
//                        body composites. This is the half that has to fall on the widget's
//                        own siblings — a knob's Line and Fill and Value arc, a button's
//                        border — which no buffer sample could ever deliver without also
//                        darkening the body it came from.
//
// Both sides call this with the same widget-space uv and take `x` / `1 - x`, so they sum to
// exactly 1 everywhere and the seam cannot show. The band is wider than the buffer's own
// filtering for the same reason.
#define UI_SHADOW_SEAM_BAND 0.04
float UIShadowQuadSplit(float2 uvWidget)
{
    float qe = max(abs(uvWidget.x - 0.5), abs(uvWidget.y - 0.5)) * 2.0;   // 1 at the quad edge
    return smoothstep(1.0 - UI_SHADOW_SEAM_BAND, 1.0 + UI_SHADOW_SEAM_BAND, qe);
}

// Re-weight a premultiplied shadow layer so the two halves MULTIPLY back to the original.
//
// Scaling the layer linearly (`layer * w`) is the obvious thing and it is wrong. The two
// halves are applied in sequence — one through the buffer, one by the widget — so their
// transmittances multiply: (1 - w*a)(1 - (1-w)*a) = 1 - a + w(1-w)a². That leaves the seam
// SHORT of the full shadow by w(1-w)a², a faint bright line along the widget's quad boundary,
// worst at half coverage (5% of the shadow's own depth). Splitting the transmittance instead
// is exact: pow(1-a, w) * pow(1-a, 1-w) == 1-a, for every w and every a.
float4 UIShadowSplitLayer(float4 layer, float w)
{
    float a = 1.0 - pow(max(1.0 - layer.a, 0.0), w);
    return float4(layer.rgb / max(layer.a, 1e-4) * a, a);
}

// Apply the in-quad half. Two things at once, and both are needed:
//   * darken what the widget has ALREADY drawn — that is what puts the body's shadow onto its
//     own rings, arcs and border;
//   * lay the shadow down as real coverage where the widget has drawn nothing, so it still
//     reaches the panel behind the widget's own quad. The buffer is punched out there.
// dst is premultiplied-alpha, which is what makes both halves a single expression.
void UIApplySelfShadow(inout float4 dst, float3 shadowColor, float amount)
{
    float a = saturate(amount);
    dst.rgb = lerp(dst.rgb, dst.rgb * shadowColor, a);
    float add = a * (1.0 - dst.a);
    dst.rgb += shadowColor * add;
    dst.a   += add;
}

// HOW MANY STEPS THE HULL SWEEP NEEDS.
//
// The cast silhouette is the convex hull of the base footprint and the projected face,
// and for two convex sets that hull is exactly the union over s in [0,1] of their linear
// interpolation — so sampling s uniformly and taking the min IS the hull, to within the
// step size. The sampling error scales with the throw, so a short throw needs very few
// steps and only an extreme one needs many; feeding this to a DYNAMIC loop keeps the
// compiled program at one shape evaluation regardless.
//
// Measured against a 129-sample reference on a squircle pad: at the shipped cast lengths
// (~0.3 occluder half-sizes) 6 steps is accurate to 0.009 quad units, where the previous
// closest-point-plus-smooth-min construction was off by 0.146 — an error big enough to
// bite a visible notch out of the shadow's side, which is exactly what it did.
int UIShadowHullSamples(float castLen, float occluderHalfSize)
{
    float R = max(occluderHalfSize, 0.0001);
    return (int)clamp(4.0 + castLen / R * 8.0, 4.0, 16.0);
}

// =============================================================================
// ARCHITECTURE NOTE: Pure Function Library
// =============================================================================
// This file contains ONLY functions, structs, and constants.
// No shader properties are declared here.
//
// Shaders using these functions must declare required properties in their own
// CGPROGRAM section (e.g., float _LightingAmbient;)
//
// EXCEPTION: Global uniforms are centralized in UIGlobalUniforms.cginc
// =============================================================================

// =============================================================================
// LEGACY LIGHTING FUNCTIONS (COMMENTED OUT)
// =============================================================================
// These functions relied on global shader properties that are no longer declared
// in this include file (following the pure function library architecture).
// Legacy shaders (Knob.shader, SDFButton.shader, NeomorphicSDF.shader) that use
// these functions have been commented out and should be migrated to the new pattern.
// =============================================================================

/*
// 3D Lighting Functions
float3 calculateLighting(float3 normal, float3 baseColor, float3 lightDirection, float lightIntensity, 
                        float4 lightColor, float ambientIntensity, float specularPower, float specularIntensity)
{
    float3 L = normalize(lightDirection);
    float3 V = float3(0.0, 0.0, 1.0); // View vector
    
    // Lambert diffuse
    float NdL = dot(normal, L);
    float lambert = saturate(NdL);
    
    // Blinn-Phong specular
    float3 H = normalize(L + V);
    float specular = pow(saturate(dot(H, normal)), specularPower);
    
    // Combine lighting
    float3 diffuse = lambert * lightIntensity;
    float3 specularColor = specular * specularIntensity;
    float3 ambient = ambientIntensity;
    
    float3 litColor = baseColor * (diffuse + ambient);
    litColor += lightColor.rgb * specularColor;
    
    return saturate(litColor);
}

// Simplified lighting function using global properties (DEPRECATED - requires global _LightDirection, etc.)
float3 calculateLighting(float3 normal, float3 baseColor)
{
    return calculateLighting(normal, baseColor, _LightDirection, _LightIntensity, 
                           _LightColor, _LightingAmbient, _SpecularPower, _SpecularIntensity);
}
*/

/*
// ============================================================================
// LEGACY FUNCTIONS - COMMENTED OUT
// These functions relied on global properties (_BevelSmoothness) that have
// been removed from this pure function library. Only used by deprecated shaders.
// ============================================================================

// Enhanced 3D normal calculation based on working shader approach
float3 calculateButtonNormal(float2 uv, float2 size, float cornerRadius, float2 aspectRatio, int buttonShape, float bevelDepth)
{
    float3 N;
    float2 compensatedUV = uv;
    compensatedUV.x /= (aspectRatio.x > 0.0001) ? aspectRatio.x : 1.0;
    compensatedUV.y /= (aspectRatio.y > 0.0001) ? aspectRatio.y : 1.0;

    float2 compensatedSize = size;
    compensatedSize.x /= (aspectRatio.x > 0.0001) ? aspectRatio.x : 1.0;
    compensatedSize.y /= (aspectRatio.y > 0.0001) ? aspectRatio.y : 1.0;

    float2 dist;
    float edge;
    float k;
    float2 cf1, cf2;

    if (buttonShape == 0) { // Rounded Rectangle - create smooth base normal
        // Use a simple radial approach for base lighting to avoid + pattern
        float2 distFromCenter = compensatedUV / compensatedSize;
        float distLength = length(distFromCenter);

        if (distLength > 0.001) {
            N.xy = normalize(distFromCenter) * 0.3;
        } else {
            N.xy = float2(0.0, 0.0);
        }
        N.z = 0.7;
    } else if (buttonShape == 1) { // Ellipse - based on working shader SHAPE_CIRCLE
        dist = compensatedUV / compensatedSize;
        edge = min(compensatedSize.x, compensatedSize.y) * 0.5;
        k = min(abs(dist.x), abs(dist.y));

        float smoothVal = smoothstep(1.0 - edge, 1.0, length(dist));
        cf1 = float2(smoothVal, smoothVal);

        float smoothValNeg = -smoothstep(-1.0 + edge, -1.0, length(dist));
        cf2 = float2(smoothValNeg, smoothValNeg);

        N.xy = lerp(lerp(cf1, cf2, 0.5), dist, cf1);
        N.z = pow(sqrt(cos(k * 0.5 * PI)), 0.1) * 0.2;
    } else { // Circle - based on working shader SHAPE_SPHERE
        N.xy = compensatedUV / compensatedSize;
        N.z = cos((length(compensatedUV) / max(compensatedSize.x, compensatedSize.y)) * PI * 0.5);
    }

    // Apply bevel depth effect to the normal for visual 3D effect
    // This creates the transition from hard edges to soft pillow effect
    if (bevelDepth > 0.001) {
        // Calculate distance from center in normalized space
        float2 distFromCenter = compensatedUV / compensatedSize;

        // Calculate the actual SDF distance to the shape boundary using proper SDF functions
        float shapeSDF;
        if (buttonShape == 0) { // Rounded Rectangle
            shapeSDF = RoundedRectSDF(compensatedUV, compensatedSize, cornerRadius);
        } else if (buttonShape == 1) { // Ellipse
            shapeSDF = EllipseSDF(compensatedUV, compensatedSize);
        } else { // Circle - use average size to match ellipse behavior in square quads
            float avgSize = (compensatedSize.x + compensatedSize.y) * 0.5;
            shapeSDF = CircleSDF(compensatedUV, avgSize);
        }

        // Convert SDF to distance from edge (0 = at edge, 1 = at center)
        float maxDist = min(compensatedSize.x, compensatedSize.y);
        float normalizedDist = saturate((-shapeSDF + maxDist) / maxDist);

        // Calculate bevel distance based on actual shape
        // normalizedDist: 0 = at edge, 1 = at center
        float bevelDistance = normalizedDist;

        // For pillow effect at high bevel depth, blend with radial distance
        if (bevelDepth > 0.5) {
            float radialDist = length(distFromCenter);
            float normalizedRadial = saturate(radialDist);
            float blendFactor = (bevelDepth - 0.5) * 2.0; // 0.5 to 1.0 maps to 0.0 to 1.0
            bevelDistance = lerp(normalizedDist, normalizedRadial, blendFactor);
        }

        // Create bevel factor using proper curve
        // bevelDistance: 0 = at edge, 1 = at center
        // We want: edge = full bevel, center = no bevel
        float bevelFactor = 1.0 - bevelDistance; // Now: 1 = at edge, 0 = at center

        // _BevelSmoothness controls the sharpness of the bevel corner/transition
        // 0.0 = very sharp corner (hard transition), 1.0 = smooth corner (gradual transition)
        float power = lerp(20.0, 0.5, _BevelSmoothness); // Much sharper at 0, smooth at 1
        bevelFactor = pow(bevelFactor, power);

        // Modify the normal to create the bevel lighting effect
        // bevelDepth controls the intensity/height of the bevel
        // bevelFactor controls where the bevel appears (based on smoothness)
        float bevelInfluence = bevelDepth * bevelFactor;

        // Apply bevel influence using proper SDF gradients for shape accuracy
        if (bevelInfluence > 0.001) {
            // Calculate proper SDF gradient for bevel direction
            float2 eps = float2(0.001, 0.0);
            float2 bevelNormal = float2(0.0, 0.0);

            if (buttonShape == 0) { // Rounded Rectangle
                float sdfX1 = RoundedRectSDF(compensatedUV + eps.xy, compensatedSize, cornerRadius);
                float sdfX2 = RoundedRectSDF(compensatedUV - eps.xy, compensatedSize, cornerRadius);
                float sdfY1 = RoundedRectSDF(compensatedUV + eps.yx, compensatedSize, cornerRadius);
                float sdfY2 = RoundedRectSDF(compensatedUV - eps.yx, compensatedSize, cornerRadius);
                bevelNormal = float2(sdfX1 - sdfX2, sdfY1 - sdfY2) / (2.0 * eps.x);
            } else if (buttonShape == 1) { // Ellipse
                float sdfX1 = EllipseSDF(compensatedUV + eps.xy, compensatedSize);
                float sdfX2 = EllipseSDF(compensatedUV - eps.xy, compensatedSize);
                float sdfY1 = EllipseSDF(compensatedUV + eps.yx, compensatedSize);
                float sdfY2 = EllipseSDF(compensatedUV - eps.yx, compensatedSize);
                bevelNormal = float2(sdfX1 - sdfX2, sdfY1 - sdfY2) / (2.0 * eps.x);
            } else { // Circle
                float avgSize = (compensatedSize.x + compensatedSize.y) * 0.5;
                float sdfX1 = CircleSDF(compensatedUV + eps.xy, avgSize);
                float sdfX2 = CircleSDF(compensatedUV - eps.xy, avgSize);
                float sdfY1 = CircleSDF(compensatedUV + eps.yx, avgSize);
                float sdfY2 = CircleSDF(compensatedUV - eps.yx, avgSize);
                bevelNormal = float2(sdfX1 - sdfX2, sdfY1 - sdfY2) / (2.0 * eps.x);
            }

            // Apply bevel normal with proper intensity
            if (length(bevelNormal) > 0.001) {
                N.xy += normalize(bevelNormal) * bevelInfluence * 0.6;
            }
            N.z += bevelInfluence * 1.5;
        }
        N.z += bevelInfluence * 2.0;
    }

    return normalize(N);
}

// Create beveled SDF with proper bevel effect that transitions from hard edges to soft pillows
float getBeveledSDF(float2 uv, float2 size, float cornerRadius, float2 aspectRatio, int buttonShape, float bevelDepth)
{
    // Use the same coordinate system as the original button shader
    float2 compensatedUV = uv;
    compensatedUV.x /= (aspectRatio.x > 0.0001) ? aspectRatio.x : 1.0;
    compensatedUV.y /= (aspectRatio.y > 0.0001) ? aspectRatio.y : 1.0;

    float2 compensatedSize = size;
    compensatedSize.x /= (aspectRatio.x > 0.0001) ? aspectRatio.x : 1.0;
    compensatedSize.y /= (aspectRatio.y > 0.0001) ? aspectRatio.y : 1.0;

    // Calculate base SDF
    float baseSDF;
    if (buttonShape == 1) {
        baseSDF = EllipseSDF(compensatedUV, compensatedSize);
    } else if (buttonShape == 2) {
        baseSDF = CircleSDF(compensatedUV, compensatedSize.x);
    } else {
        baseSDF = RoundedRectSDF(compensatedUV, compensatedSize, cornerRadius);
    }

    // Apply bevel effect - this creates the pillow/bubble effect
    if (bevelDepth > 0.001) {
        float2 distFromCenter = compensatedUV / compensatedSize;

        // For rectangular shapes, use max distance for box-like bevels at low values
        // For high values, transition to radial distance for pillow-like effect
        float boxDist = max(abs(distFromCenter.x), abs(distFromCenter.y));
        float radialDist = length(distFromCenter);

        // Blend between box and radial distance based on bevel depth
        // Low bevel depth = more box-like (hard edges)
        // High bevel depth = more radial (soft pillow)
        float blendFactor = saturate(bevelDepth * 2.0); // 0.5 bevel depth = full transition
        float dist = lerp(boxDist, radialDist, blendFactor);

        // Create smooth bevel curve
        // Use _BevelSmoothness to control the transition sharpness
        float bevelStart = saturate(1.0 - _BevelSmoothness * 2.0); // Higher smoothness = earlier start
        float bevelFactor = smoothstep(bevelStart, 1.0, dist);

        // Apply power curve for more natural falloff
        float power = lerp(4.0, 1.0, bevelDepth); // Sharp at low depth, smooth at high depth
        bevelFactor = pow(bevelFactor, power);

        float bevelOffset = bevelDepth * 0.1 * bevelFactor; // Scale down for more subtle effect
        baseSDF -= bevelOffset;
    }

    return baseSDF;
}
*/

/*
// Enhanced 3D normal calculation for fill area specifically
float3 calculateFillNormal(float2 uv, float2 fillSize, float2 buttonSize, float cornerRadius, float2 aspectRatio, int buttonShape, float bevelDepth)
{
    return calculateButtonNormal(uv, fillSize, cornerRadius, aspectRatio, buttonShape, bevelDepth);
}
*/

// Enhanced 3D normal calculation for knobs
float3 calculateKnobNormal(float2 uv, float dist, float innerRadius, float outerRadius, float bevelDepth)
{
    float3 N;
    float2 distVec = (uv - 0.5) / 0.5;
    
    N.xy = normalize(distVec) * 0.2;
    
    float ringCenter = (innerRadius + outerRadius) * 0.5;
    float ringWidth = outerRadius - innerRadius;
    float distFromRingCenter = abs(dist - ringCenter) / ringWidth;
    
    float bevelFactor = smoothstep(0.0, 0.3, distFromRingCenter);
    N.z = 0.3 + bevelDepth * bevelFactor * 2.0;
    
    float distFromCenter = length(distVec);
    float centerBevel = bevelDepth * 1.5 * smoothstep(0.2, 1.0, distFromCenter);
    N.z += centerBevel;
    
    return normalize(N);
}

// Enhanced 3D normal calculation for knob nub
float3 calculateNubNormal(float2 uv, float2 size, float bevelDepth)
{
    float3 N;
    float2 dist = uv / (size * 0.5);
    float edge = min(size.x, size.y) * 0.2;
    float k = min(dist.x, dist.y);
    
    float2 cf1 = float2(smoothstep(1.0 - edge, 1.0, dist.x), smoothstep(1.0 - edge, 1.0, dist.y));
    float2 cf2 = float2(-smoothstep(-1.0 + edge, -1.0, dist.x), -smoothstep(-1.0 + edge, -1.0, dist.y));
    N.xy = lerp(cf1, cf2, 0.5);
    N.z = pow(sqrt(cos(k * 0.5 * PI)), 0.1) * 0.3 + bevelDepth * 1.0;
    
    float distFromCenter = length(dist);
    float centerBevel = bevelDepth * 1.5 * smoothstep(0.3, 1.0, distFromCenter);
    N.z += centerBevel;
    
    return normalize(N);
}

// Add visual bevel indicator
float3 applyVisualBevel(float3 color, float2 uv, float2 size, float2 aspectRatio, float bevelDepth)
{
    if (bevelDepth <= 0.001) return color;
    
    float2 compensatedUV = uv;
    compensatedUV.x /= (aspectRatio.x > 0.0001) ? aspectRatio.x : 1.0;
    compensatedUV.y /= (aspectRatio.y > 0.0001) ? aspectRatio.y : 1.0;
    
    float2 compensatedSize = size;
    compensatedSize.x /= (aspectRatio.x > 0.0001) ? aspectRatio.x : 1.0;
    compensatedSize.y /= (aspectRatio.y > 0.0001) ? aspectRatio.y : 1.0;
    
    float distFromCenter = length(compensatedUV / compensatedSize);
    float bevelDarkening = bevelDepth * 2.0 * smoothstep(0.7, 1.0, distFromCenter);
    return color * (1.0 - bevelDarkening * 0.3);
}

/*
// LEGACY: applyVisualBevel function (DEPRECATED - requires global _BevelDepth)
float3 applyVisualBevel(float3 color, float2 uv, float2 size, float2 aspectRatio)
{
    return applyVisualBevel(color, uv, size, aspectRatio, _BevelDepth);
}

// LEGACY: apply3DLighting function (DEPRECATED - requires global calculateLighting)
float3 apply3DLighting(float3 baseColor, float3 normal, float lightIntensity, float blendFactor = 0.8)
{
    if (lightIntensity <= 0.01) return baseColor;
    
    float3 litColor = calculateLighting(normal, baseColor);
    return lerp(baseColor, litColor, blendFactor);
}
*/

/*
// =============================================================================
// LEGACY WRAPPERS - COMMENTED OUT
// =============================================================================

// Simplified 3D lighting function using global properties
float3 apply3DLighting(float3 baseColor, float3 normal, float blendFactor = 0.8)
{
    return apply3DLighting(baseColor, normal, _LightIntensity, blendFactor);
}
*/

// =============================================================================
// Modern Lighting API - Pass all parameters explicitly
// =============================================================================

// Apply lighting using UILight structures
// ambientIntensity: Amount of ambient light (0-1, typically 0.2-0.5)
// UNLIT (2026-09-13). A widget shader that wants a per-material "skip lighting" switch declares
// `float _LightingUnlit;` and `#define UI_LIGHTING_UNLIT _LightingUnlit` BEFORE its first include
// (this file stays a pure-function library — it declares no property of its own). Anything that
// does not define the macro is always lit. Unlit returns the base colour exactly: no ambient
// scale, no lamps, no specular — so a flat look renders its authored hex under ANY rig, including
// Skin Studio previews drawn while a lit look is active, and pays nothing for the light maths.
#ifndef UI_LIGHTING_UNLIT
#define UI_LIGHTING_UNLIT 0.0
#endif

float3 ApplyUILighting(float3 normal, float3 baseColor, float ambientIntensity, float specularMod, float2 normalOffset, 
                      UILight light1, UILight light2, UILight light3)
{
    if (UI_LIGHTING_UNLIT > 0.5) return saturate(baseColor);

    float3 finalColor = baseColor;
    
    // Apply ambient lighting
    finalColor *= ambientIntensity;
    
    // Apply each light
    if (light1.enabled)
    {
        float3 lightDir = normalize(light1.direction);
        float ndotl = max(0.0, dot(normal, lightDir));
        
        // Diffuse contribution
        finalColor += baseColor * ndotl * light1.intensity * light1.color.rgb;
        
        // Specular contribution
        float3 viewDir = float3(0, 0, 1);
        float3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(0.0, dot(normal, halfDir)), light1.specularPower);
        finalColor += light1.color.rgb * spec * light1.specular * specularMod;
    }
    
    if (light2.enabled)
    {
        float3 lightDir = normalize(light2.direction);
        float ndotl = max(0.0, dot(normal, lightDir));
        
        // Diffuse contribution
        finalColor += baseColor * ndotl * light2.intensity * light2.color.rgb;
        
        // Specular contribution
        float3 viewDir = float3(0, 0, 1);
        float3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(0.0, dot(normal, halfDir)), light2.specularPower);
        finalColor += light2.color.rgb * spec * light2.specular * specularMod;
    }
    
    if (light3.enabled)
    {
        float3 lightDir = normalize(light3.direction);
        float ndotl = max(0.0, dot(normal, lightDir));
        
        // Diffuse contribution
        finalColor += baseColor * ndotl * light3.intensity * light3.color.rgb;
        
        // Specular contribution
        float3 viewDir = float3(0, 0, 1);
        float3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(0.0, dot(normal, halfDir)), light3.specularPower);
        finalColor += light3.color.rgb * spec * light3.specular * specularMod;
    }
    
    return saturate(finalColor);
}

// Calculate 3D normal for circular beveled surface
float3 CalculateCircleBevelNormal(float2 uv, float radius, float bevelDepth, float bevelDistance, float bevelSmoothness, float fillFaceSmoothness)
{
    float3 normal = float3(0, 0, 1);
    
    float2 center = float2(0.5, 0.5);
    float2 toCenter = center - uv;
    float distFromCenter = length(toCenter);
    
    // Convert radius from [-1,1] to [0,1] UV space for distance calculations
    float radiusInUVSpace = radius * 0.5;
    
    // Calculate distance from the edge inward (for bevel effect)
    float distFromEdge = abs(radiusInUVSpace - distFromCenter);
    
    // Scale bevelDistance and bevelSmoothness to match the UV coordinate system
    float scaledBevelDistance = bevelDistance * 0.5;
    float scaledBevelSmoothness = bevelSmoothness * 0.5;
    
    // 1. Bevel smoothness: affects outside the bevel (existing behavior)
    float bevelFactor = smoothstep(scaledBevelDistance, scaledBevelDistance - scaledBevelSmoothness, distFromEdge);
    
    // 2. Fill face smoothness: dome (positive) or bowl (negative) profile on the flat face
    float fillFactor = 0.0;
    if (distFromCenter <= radiusInUVSpace && fillFaceSmoothness != 0.0) {
        // centerDist: 0 at apex (center), 1 at edge — spherical sine profile
        float centerDist = distFromCenter / radiusInUVSpace;
        // sin gives dome (flat apex, steepest slope at rim — physically correct hemisphere)
        float domeProfile = sin(saturate(centerDist) * PI * 0.5);
        fillFactor = domeProfile * fillFaceSmoothness;
    }
    
    // Create normal perturbation for 3D effect
    if (distFromCenter > 0.001 && distFromCenter <= radiusInUVSpace) {
        float2 normalDir = normalize(toCenter);
        
        // For negative bevel depths (recessed surfaces), invert the normal direction
        // This makes the lighting behave correctly for pushed-in vs raised bevels
        if (bevelDepth < 0.0) {
            normalDir = -normalDir; // Invert direction for recessed bevel
        }
        
        // Combine bevel effect and fill face effect
        float totalDepth = bevelFactor * abs(bevelDepth) + fillFactor;
        normal.xy = normalDir * totalDepth;
        normal.z = 1.0 - abs(totalDepth) * 0.5;
    }
    
    return normalize(normal);
}

// Calculate bevel normal that follows any arbitrary shape SDF (shape-accurate, uses screen-space SDF gradient).
// Drop-in replacement for CalculateCircleBevelNormal when _KnobBevelShapeFollowEnabled > 0.
// shapeSDF        : the pre-computed SDF at the current fragment (negative = inside shape)
// profileType     : 0=Dome (smoothstep), 1=Linear (constant-slope angled shelf)
// profileSharpness: for Linear only — slope scale (0=flat, 1=full depth)
// bevelDepth, bevelDistance, bevelSmoothness, fillFaceSmoothness : same semantics as circle version
// fillCentreOffset : fragment position relative to the shape's centre, in the same isotropic units
//                    as shapeSDF. Only used for the face dome/bowl.
// fillInradius     : the shape's inradius (distance from centre to nearest edge), same units.
//                    Pass > 0 to opt in to the smooth full-face dome; <= 0 keeps the legacy
//                    bevelDistance-relative profile that rides the SDF gradient.
float3 CalculateShapeBevelNormal(float shapeSDF, float bevelDepth, float bevelDistance, float bevelSmoothness, float fillFaceSmoothness, int profileType, float profileSharpness, float2 aspectScale = float2(1,1), float2 fillCentreOffset = float2(0,0), float fillInradius = 0.0)
{
    float3 normal = float3(0, 0, 1);

    // Bevel band: active when we are inside the shape AND within bevelDistance of the edge.
    // abs(shapeSDF) is world-space distance; bevelDistance is also world-space — use directly (no *0.5).
    float scaledBevelDistance = bevelDistance;
    float scaledSmoothness    = bevelSmoothness;

    float bevelFactor;
    if (profileType == 1) {
        // Linear profile: constant-slope angled shelf, full depth at edge, 0 at bevelDistance inward.
        float t = saturate((scaledBevelDistance - abs(shapeSDF)) / max(0.0001, scaledBevelDistance));
        bevelFactor = t * profileSharpness;
    } else {
        // Dome profile (default): smooth S-curve roll-off via smoothstep.
        bevelFactor = smoothstep(scaledBevelDistance, max(0.0001, scaledBevelDistance - scaledSmoothness), abs(shapeSDF));
    }

    // Get the edge-perpendicular direction from the screen-space SDF gradient.
    // The SDF is in equi-pixel space (isotropic: 1 unit = screenHeight/2 pixels in both axes).
    // ddx/ddy of an equi-pixel SDF already give equal magnitudes on horizontal and vertical
    // edges (both equal 2/screenHeight per pixel), so NO aspectScale correction is needed.
    // Dividing by aspectScale was incorrect: it produced a 4× Y-bias at 4:1 aspect, making
    // corner bevel normals point mostly in the short-axis direction.
    float2 sdfGradient = float2(ddx(shapeSDF), ddy(shapeSDF));
    float gradLen = length(sdfGradient);
    float2 edgeDir = (gradLen > 0.0001) ? -sdfGradient / gradLen : float2(0.0, 1.0);

    // Flip gradient direction for recessed bevels.
    if (bevelDepth < 0.0) edgeDir = -edgeDir;

    // Fill face dome/bowl profile.
    float  fillFactor = 0.0;
    float2 fillDir    = edgeDir;
    if (shapeSDF < 0.0 && fillFaceSmoothness != 0.0) {
        if (fillInradius > 0.0001) {
            // Smooth full-face profile. t: 0 at the rim, 1 at the deepest interior point.
            float t = saturate(-shapeSDF / fillInradius);
            // Raised-cosine pillow: 1 at the rim, 0 at the apex, and — crucially — zero
            // derivative at BOTH ends. t is derived from the SDF, whose gradient is
            // discontinuous across the medial axis, so a profile with a non-zero slope at
            // t=1 would still crease the face there.
            fillFactor = (0.5 + 0.5 * cos(t * PI)) * fillFaceSmoothness;
            // Slope direction comes from the shape CENTRE, not the SDF gradient. The gradient of
            // a rect SDF is discontinuous across the medial axis, which creases the face into
            // hard mitre facets; a centre-radial direction is continuous everywhere.
            float offLen = length(fillCentreOffset);
            fillDir = (offLen > 0.0001) ? -fillCentreOffset / offLen : float2(0.0, 0.0);
        } else {
            // Legacy: SDF magnitude as a depth proxy, normalised by bevelDistance.
            float normalizedDepth = saturate(-shapeSDF / max(0.0001, scaledBevelDistance * 4.0));
            fillFactor = sin(normalizedDepth * PI * 0.5) * fillFaceSmoothness;
        }
    }

    // Sum the two slope contributions as vectors — they can have different directions.
    float2 slope = edgeDir * (bevelFactor * abs(bevelDepth)) + fillDir * fillFactor;
    float  slopeLen = length(slope);
    if (slopeLen > 0.0001) {
        normal.xy = slope;
        normal.z  = 1.0 - slopeLen * 0.5;
    }

    return normalize(normal);
}

// Wall normal for frustum sidewall in 3D ViewTilt mode.
// Uses the same screen-space SDF gradient approach as CalculateShapeBevelNormal.
// wallNzAnalytic : Z component from FrustumWallNz() — cone-angle correct, not a lerp.
float3 CalculateWallNormal(float frustumSDF, float2 fallbackDir, float wallNzAnalytic)
{
    float2 sdfGradient = float2(ddx(frustumSDF), ddy(frustumSDF));
    float gradLen = length(sdfGradient);
    float2 lateral = (gradLen > 0.0001) ? sdfGradient / gradLen : fallbackDir;

    // lateral scale is sin(coneAngle), z is cos(coneAngle) — normalized by construction
    // since FrustumWallNz returns cos and FrustumWallLateral returns sin of the same angle.
    return normalize(float3(lateral, wallNzAnalytic));
}

// Calculate bevel normal for ring/line geometry
float3 CalculateRingBevelNormal(float2 uv, float innerRadius, float outerRadius, float bevelDepth, float bevelDistance, float bevelSmoothness, float fillFaceSmoothness)
{
    float3 normal = float3(0, 0, 1);
    
    float2 center = float2(0.5, 0.5);
    float2 pos = (uv - center) * 2.0; // Convert to world space
    float distFromCenter = length(pos);
    
    // Calculate distance from both edges
    float distToInnerEdge = abs(distFromCenter - innerRadius);
    float distToOuterEdge = abs(distFromCenter - outerRadius);
    
    // Scale bevel distance appropriately
    float scaledBevelDistance = bevelDistance * 0.1;
    float scaledSmoothness = bevelSmoothness * 0.05;
    
    // 1. Bevel factor from both edges (existing behavior)
    float innerBevelFactor = smoothstep(scaledBevelDistance, scaledBevelDistance - scaledSmoothness, distToInnerEdge);
    float outerBevelFactor = smoothstep(scaledBevelDistance, scaledBevelDistance - scaledSmoothness, distToOuterEdge);
    float bevelFactor = max(innerBevelFactor, outerBevelFactor);
    
    // 2. Fill face smoothness: affects the ring area itself
    float fillFactor = 0.0;
    if (distFromCenter >= innerRadius && distFromCenter <= outerRadius) {
        float ringWidth = outerRadius - innerRadius;
        float ringPosition = (distFromCenter - innerRadius) / ringWidth; // Position within ring [0,1]
        
        if (fillFaceSmoothness > 0.0) {
            // Positive: outward bulge from ring center
            float ringCenter = 0.5; // Middle of the ring
            float distFromRingCenter = abs(ringPosition - ringCenter);
            fillFactor = (1.0 - distFromRingCenter * 2.0) * fillFaceSmoothness;
        } else if (fillFaceSmoothness < 0.0) {
            // Negative: inward divot toward ring center
            float ringCenter = 0.5;
            float distFromRingCenter = abs(ringPosition - ringCenter);
            fillFactor = -((1.0 - distFromRingCenter * 2.0) * abs(fillFaceSmoothness));
        }
    }
    
    // Create normal perturbation for 3D effect
    if (distFromCenter > 0.001 && distFromCenter >= innerRadius && distFromCenter <= outerRadius) {
        float2 radialDir = normalize(pos);
        
        // Bevel direction based on which edge is closer
        float bevelContribution = 0.0;
        if (bevelFactor > 0.01) {
            float bevelDirection = 0.0;
            if (distToInnerEdge < distToOuterEdge) {
                // Closer to inner edge - bevel inward for positive depth
                bevelDirection = 1.0;
            } else {
                // Closer to outer edge - bevel outward for positive depth
                bevelDirection = -1.0;
            }
            
            // For negative bevel depths (recessed surfaces), invert the direction
            if (bevelDepth < 0.0) {
                bevelDirection = -bevelDirection;
            }
            
            bevelContribution = bevelFactor * bevelDirection * abs(bevelDepth);
        }
        
        // Combine bevel effect and fill face effect
        float totalDepth = bevelContribution + fillFactor;
        normal.xy = radialDir * totalDepth;
        normal.z = 1.0 - abs(totalDepth) * 0.5;
    }
    
    return normalize(normal);
}

#endif // UI_LIGHTING_CGINC
