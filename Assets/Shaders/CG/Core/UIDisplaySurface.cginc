#ifndef UI_DISPLAY_SURFACE_INCLUDED
#define UI_DISPLAY_SURFACE_INCLUDED

#include "UILighting.cginc"

// ═════════════════════════════════════════════════════════════════════════════
// UIDisplaySurface — the sheet of glass or plastic in front of a screen.
// ═════════════════════════════════════════════════════════════════════════════
//
// WHAT THIS IS FOR. SDFScope / SDFWaveform / SDFRhythmTrack all draw an EMISSIVE
// picture: a curve, a waveform, a note highway. None of them modelled the thing
// you look at that picture THROUGH. SDFScope had a `_Sheen*` band — a gaussian
// stripe at an authored angle and an authored position — which is a painting of a
// reflection, not a reflection: it sat in the same place no matter where the lamps
// were, and stayed put while every knob and button beside it relit. The other two
// had nothing at all. That is the whole "some have no lighting, some have a fake
// unmoving one" split.
//
// Everything here derives from the SAME three lamps every other lit SDF widget
// reads (_GlobalLightPosN / _GlobalLightColorN / _GlobalLightFxN, published by
// UiSceneDirector — see the light-rig note in UILighting.cginc). Move a lamp and
// the glare slides across the glass, the bezel's inner shadow swings to the far
// side, and the rim lights on the lamp-facing edge. Nothing is authored in place.
//
// ── PER-FRAGMENT LIGHT POSITION, not per-widget ─────────────────────────────
// The RM widgets resolve their light ONCE from `_Position` (the widget's anchor)
// because a knob is small and one direction across it is honest. A display is not
// small — a waveform strip can be most of the window — and one direction across it
// gives a flat, uniform wash with no locatable highlight anywhere. So the caller
// passes each FRAGMENT's own position in rig space (see UI_DISPLAY_LIGHT_POS), and
// the lamp is treated as the point light it actually is. That is what makes the
// glare a spot you can point at rather than a gradient, and it costs one varying.
//
// ── WHY THE PICTURE STAYS READABLE ──────────────────────────────────────────
// A real reflection adds light; it does not hide anything. But a glare blob sitting
// on top of a 1px curve makes that curve unreadable, which is a worse display than
// one with no glass at all. `signalMask` fixes that the way the eye does: where the
// emitted picture is bright it out-competes the reflection, so the reflection is
// attenuated there. Bright signal wins, dark background takes the glare.
//
// ── SIGN CONVENTION ─────────────────────────────────────────────────────────
// UILightDirection returns the TRAVEL direction (lamp → surface) and the RM bevel
// paths consume it directly because their normals point INWARD (see UILighting's
// sign note — do not "fix" it). A display's front face is the opposite case: its
// normal points OUT at the viewer, so every dot product here uses UIToLightVector's
// to-lamp vector. Feeding the travel vector instead lights the edge away from the
// lamp and throws the inset shadow onto the wrong side — both halves at once, which
// is the tell if this ever looks inverted.
// ═════════════════════════════════════════════════════════════════════════════


// ─────────────────────────────────────────────────────────────────────────────
// Parameters. Every one is a MULTIPLIER on the per-mode base below, defaulting to
// 1.0 = "whatever this kind of display naturally is". That is deliberate: it means
// an already-authored finish (Resources/UiThemes/ScopeFinishes.json) gains correct
// lighting without a single edit, and a finish only names a number here when it
// wants to differ from its own material. 0 switches a term off outright.
// ─────────────────────────────────────────────────────────────────────────────
struct UIDisplaySurfaceDesc
{
    float  mode;          // 0 none · 1 glass · 2 plastic · 3 LED matrix · 4 LCD
    float  reflectivity;  // × specular + environment strength
    float  gloss;         // × highlight tightness (high = small hard glass spot)
    float  rough;         // × microfacet break-up (high = broad, broken, plastic)
    float  fresnel;       // × edge reflectivity
    float  curve;         // × optical dome of the cover (NOT the picture warp)
    float  env;           // × reflected-room brightness
    float  innerShadow;   // × bezel lip occlusion cast onto the face
    float  signalMask;    // 0..1 how hard bright signal suppresses reflection
    float3 envColor;      // colour of the room the glass reflects
    float  bezelPx;       // aperture inset — same value the bezel layer uses
    float  bezelRoundPx;
    float2 quadPx;        // widget size in pixels (_QuadSize.xy)
};

// The material each _SurfaceMode is made of. These are the numbers the multipliers
// multiply; they are what "glass" and "plastic" actually mean here.
//   x = reflect   y = gloss   z = rough   w = fresnel
float4 uiDispBaseA(float mode)
{
    if (mode < 1.5) return float4(1.00, 0.88, 0.10, 1.00); // glass: sharp, clean, glassy edge
    if (mode < 2.5) return float4(0.30, 0.26, 0.75, 0.40); // plastic: broad, broken, matte
    if (mode < 3.5) return float4(0.48, 0.60, 0.30, 0.55); // LED cover: semi-gloss
    return                 float4(0.42, 0.38, 0.45, 0.65); // LCD: polariser sheen
}

// Does this kind of screen draw DARK signal on a LIT field? Only the LCD does, and it
// changes what "protect the picture" means — see the signal guard in UIApplyDisplaySurface.
bool uiDispInverted(float mode) { return mode > 3.5; }
//   x = curve     y = env     z = innerShadow(px depth)   w = edgeRoll(px)
float4 uiDispBaseB(float mode)
{
    if (mode < 1.5) return float4(0.34, 0.85, 3.2, 2.6);
    if (mode < 2.5) return float4(0.20, 0.42, 2.4, 3.4);
    if (mode < 3.5) return float4(0.12, 0.34, 2.2, 2.0);
    return                 float4(0.14, 0.55, 2.8, 2.4);
}


// The rig, as published by UiSceneDirector. Declared here rather than in each of
// the three display shaders: this is the same documented "globals are the one
// exception to the pure-function rule" carve-out UIGlobalUniforms.cginc lives
// under. The RM widgets declare their own copies in their SDFxxxUniforms.cginc and
// none of them include this file, so there is nothing to collide with.
float3 _GlobalLightPos1;
float3 _GlobalLightPos2;
float3 _GlobalLightPos3;
float4 _GlobalLightColor1;
float4 _GlobalLightColor2;
float4 _GlobalLightColor3;
float4 _GlobalLightFx1;
float4 _GlobalLightFx2;
float4 _GlobalLightFx3;

// The shared cross-widget shadow buffer (UIShadowBufferManager.cs). Declared here for the
// same reason as the lights above, and sampled directly rather than via UIRenderer.cginc's
// helper: that header drags in UIComponents/UIPatterns/UIGradients/UIGlobalEffects, none of
// which a display shader needs, and these fragment programs are already the expensive ones.
#ifndef UI_GLOBAL_UNIFORMS_INCLUDED
uniform sampler2D _UIShadowBuffer;
// Is that texture live this frame? See UIGlobalUniforms.cginc — same flag, same meaning.
uniform float _UIShadowBufferBound;
#endif

// Receive shadows cast by the knobs and buttons sitting around this screen.
//
// A display is a big flat surface in the middle of a rack of things that cast — without this
// it is the one object a neighbour's shadow falls straight through, which reads as the screen
// floating in front of the panel rather than being set into it. White = unshadowed.
//
// ⚠ GATED on _UIShadowBufferBound, like UIRenderer's receiver (2026-09-17). An unlit look (Tron,
// Flat) casts nothing, so UIShadowBufferManager idles its camera and reports the buffer UNBOUND —
// and the RT's contents are then whatever was last in it. Every widget receiver already read that
// flag; these three displays sampled the texture raw, so the scopes, waveforms and the whole
// highway went BLACK under Tron the moment that RT was recreated or lost while idle (user report:
// "load a kit in the creator and the displays and gametracks go black; realistic is fine").
float3 UIDisplayReceiveShadow(float2 screenUv)
{
    if (_UIShadowBufferBound < 0.5) return float3(1, 1, 1);
    return tex2D(_UIShadowBuffer, screenUv).rgb;
}


// ─────────────────────────────────────────────────────────────────────────────
// The glass opening — a rounded rect in PIXELS, inset by the bezel. Identical
// construction to SDFScope's own bezel layer so the lit edge and the drawn frame
// can never disagree about where the glass ends.
// ─────────────────────────────────────────────────────────────────────────────
float uiDispAperture(float2 uv, float2 quadPx, float insetPx, float radiusPx)
{
    float2 halfPx = quadPx * 0.5;
    float  r = min(radiusPx, min(halfPx.x, halfPx.y));
    float2 p = abs(uv * quadPx - halfPx) - (halfPx - insetPx - r);
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0) - r;
}

// Outward normal of that opening, ANALYTIC and in uv space (y up).
//
// The obvious implementation is float2(ddx(d), ddy(d)) — and it is wrong here in a way
// that is almost invisible until you look for it. ddy is a SCREEN derivative, and screen
// y runs DOWNWARD while uv.y and the light rig's space both run upward. So a gradient
// taken that way has its y silently negated relative to the dome term it gets added to
// and relative to the lamp positions it gets dotted against: the top edge of the glass
// rolls the wrong way, lights as if it were the bottom edge, and the reflected room
// goes dark exactly where it should be brightest. (Measured on the offline port: the
// top rim's environment term came out at 2e-6 instead of its peak.)
//
// The aperture is an analytic rounded rect, so there is no reason to ask the hardware.
// This is exact, cheaper, has no y-convention to get wrong, and is safe to call from
// inside a branch — which a derivative is not.
float2 uiDispApertureGrad(float2 uv, float2 quadPx, float insetPx, float radiusPx)
{
    float2 halfPx = quadPx * 0.5;
    float  r = min(radiusPx, min(halfPx.x, halfPx.y));
    float2 q = uv * quadPx - halfPx;
    float2 p = abs(q) - (halfPx - insetPx - r);

    // Corner region: both axes are outside the inner box, so the nearest feature is the
    // corner arc and the gradient is radial. Edge region: whichever axis is further out.
    float2 g = (p.x > 0.0 && p.y > 0.0)
             ? normalize(max(p, float2(1e-5, 1e-5)))
             : ((p.x > p.y) ? float2(1.0, 0.0) : float2(0.0, 1.0));

    return g * float2(q.x >= 0.0 ? 1.0 : -1.0, q.y >= 0.0 ? 1.0 : -1.0);
}


// ─────────────────────────────────────────────────────────────────────────────
// Surface normal of the cover sheet. Three things bend it, and the third is what
// sells the material more than any other single term:
//
//   1. DOME — the cover bulges toward the viewer, so its normal tilts outward as
//      you move off centre. Without this the normal is (0,0,1) everywhere, every
//      dot product is constant across the face, and a point lamp produces a flat
//      wash. The dome is what turns the lamp into a locatable glare SPOT.
//   2. EDGE ROLL — real cover glass has a rounded lip where it meets the bezel.
//      That lip is a near-vertical band of normals, so it catches a hard bright
//      line on the lamp side and goes black on the far side. It reads as thickness.
//   3. MICROFACET — a perfect analytic surface gives a perfect analytic blob, which
//      is exactly what makes CG glass look like CG. Breaking the normal up by a
//      hair, scaled by roughness, is the difference between "moulded plastic" and
//      "a shiny grey rectangle".
// ─────────────────────────────────────────────────────────────────────────────
float3 uiDispNormal(float2 uv, float2 quadPx, float apertureD, float2 apertureGrad,
                    float curve, float edgeRollPx, float rough)
{
    float2 c = uv * 2.0 - 1.0;
    float2 n = c * curve;

    // Rounded glass lip. `inside` is how far in from the opening we are; the roll
    // ramps in over the last edgeRollPx and pushes the normal along the outward
    // gradient, squared so the band stays tight against the frame.
    if (edgeRollPx > 0.01)
    {
        float inside = -apertureD;
        float roll   = 1.0 - saturate(inside / edgeRollPx);
        n += apertureGrad * roll * roll * 1.55;
    }

    if (rough > 0.001)
    {
        // Cell size shrinks as roughness rises: rougher plastic has finer, denser
        // structure. Pixel-space so the grain doesn't stretch with the quad.
        // Three octaves at deliberately irrational-ish frequency ratios. Two octaves on a
        // regular lattice read as woven cloth, not as a moulded surface — the repeat is
        // plainly visible on a wide panel. The amplitude is small on purpose: this is meant
        // to break the EDGE of a highlight into something organic, not to be seen itself.
        float2 np = uv * quadPx / max(5.0, 18.0 - rough * 11.0);
        float  a  = sin(np.x * 1.7 + np.y * 0.9) * sin(np.y * 1.3 - np.x * 0.6)
                  + sin(np.x * 2.7 - np.y * 4.1) * 0.5;
        float  b  = sin(np.x * 3.1 - np.y * 2.3) * sin(np.x * 0.8 + np.y * 2.7)
                  + sin(np.y * 3.7 + np.x * 1.1) * 0.5;
        n += float2(a, b) * rough * 0.040;
    }

    return normalize(float3(n, 1.0));
}


// ─────────────────────────────────────────────────────────────────────────────
// Fresnel. V is (0,0,1) for a UI quad, so dot(N,V) is just N.z and the whole
// Schlick term collapses to a function of how far the normal has tilted away from
// facing us — which is exactly the dome rim and the edge roll. This is why glass
// glows at its edges and a flat matte panel doesn't.
// ─────────────────────────────────────────────────────────────────────────────
float uiDispFresnel(float3 N, float strength)
{
    float f = pow(1.0 - saturate(N.z), 5.0);
    return saturate(0.02 + f * strength * 3.0);
}


// ─────────────────────────────────────────────────────────────────────────────
// One lamp, seen REFLECTED in the cover. This is a mirror, not a shading lobe, and
// the difference matters enormously on something as flat as a screen.
//
// The obvious implementation — Blinn-Phong, pow(dot(N,H), exponent) — is wrong here
// and fails in a specific, measurable way. Its lobe has a fixed ANGULAR width, so as
// a lamp rises toward overhead the half-vector lines up with the panel's normal over
// the whole face at once and the "highlight" stops being a highlight: measured on the
// offline port of this file, a plastic cover went from 12% of its face covered at lamp
// height 0.12 to 90% at height 1.6. That is the milky wash that buries the picture,
// and no amount of exponent tuning removes it, because the exponent is not what sets
// a real highlight's size.
//
// What a screen actually shows is the reflected IMAGE of the lamp. So: reflect the
// view ray about the surface normal, march it out to the lamp's own height, and ask
// how far it lands from the lamp. On a perfectly flat cover that reduces to "the lamp
// appears exactly where the lamp is" — self-limiting and correct, a small bulb stays a
// small glare no matter how high it goes. The dome then smears and slides that image
// outward exactly the way curved glass does, so the same code gives a tight dot on a
// flat LCD and a long swept streak on a CRT.
//
// A lamp too far off to one side is reflected off the edge of the cover's field of
// view and produces nothing at all here — also correct, and why uiDispEnvironment
// carries a base reflection: a screen across the room from every lamp still reflects
// the ROOM, it just doesn't show a bulb.
// ─────────────────────────────────────────────────────────────────────────────
float3 uiDispLampSpec(float3 N, float3 gPos, float4 gColor, float4 gFx,
                      float2 lightSpacePos, float gloss, float rough)
{
    if (gFx.x < 0.5) return float3(0, 0, 0);

    // reflect(-V, N) with V = (0,0,1). Flat cover → R = (0,0,1), straight back at us.
    float3 R = 2.0 * N.z * N - float3(0, 0, 1);
    if (R.z < 0.02) return float3(0, 0, 0);   // never reaches the lamp's plane

    float  lz   = max(gPos.z, 0.02);
    float2 hit  = lightSpacePos + R.xy * (lz / R.z);
    float  miss = length(hit - gPos.xy);

    // The lamp's apparent radius, in rig units (fractions of screen height). Tight for
    // polished glass, broad and soft for moulded plastic, widened further by surface
    // roughness. gFx.z is the rig's specularPower (default 32 → factor 1), so a designer
    // tightening the rig's highlights tightens the screens along with everything else —
    // they are lit by the same room, not by a separate model.
    float radius = lerp(0.30, 0.070, saturate(gloss)) * (1.0 + rough * 0.9)
                 * (32.0 / max(gFx.z, 1.0));
    float t = miss / max(radius, 0.01);
    float s = exp(-t * t * 2.0);

    // Half-Lambert guard so a lamp behind the surface can't light it. Soft, because a
    // hard cut terminates the glare in a visible arc.
    float3 toL  = UIToLightVector(UILightDirection(gPos, lightSpacePos));
    float  wrap = saturate(dot(N, toL) * 0.6 + 0.4);

    // gFx.y is the rig's specular (default 0.25 → factor 1), gColor.w its intensity.
    return gColor.rgb * (s * wrap * gFx.y * 4.0 * gColor.w);
}


// ─────────────────────────────────────────────────────────────────────────────
// The room, reflected — the broad, always-present half of what glass shows, as
// opposed to the locatable bulb above.
//
// `keyDirXY` points from the surface toward the brightest lamp, so the room's bright
// side is wherever the rig's key light is. That is what keeps a display that no lamp
// reflects directly into from going dead: it still has a gradient, and that gradient
// still swings when the lights move. A fixed "sky is up" would have been one more
// piece of painted lighting, which is the whole thing being fixed here.
//
// (0.25 + fres) rather than plain fres: real glass reflects ~4% face-on and ~100% at
// grazing, but a screen with literally nothing in the middle reads as a matte hole,
// so the rim still dominates while the centre keeps a floor.
// ─────────────────────────────────────────────────────────────────────────────
float3 uiDispEnvironment(float3 N, float3 envColor, float amount, float fres,
                         float2 keyDirXY)
{
    if (amount < 0.001) return float3(0, 0, 0);
    float2 r       = N.xy * 2.0;                    // reflected direction, V = (0,0,1)
    float  toward  = dot(r, keyDirXY);
    // Both terms are deliberately small. On a FLAT cover `toward` is near-constant over
    // the whole face, so anything generous here stops being a horizon band and becomes a
    // uniform veil that lifts the black background — measured at +72% on a glass.amber
    // well before these were cut, which is the difference between a dark screen with a
    // reflection on it and a grey screen.
    float  sky     = pow(saturate(0.5 + toward * 0.9), 2.2);
    float  horizon = exp(-toward * toward * 12.0) * 0.15;
    return envColor * (sky * 0.5 + horizon) * amount * (0.05 + fres);
}


// ─────────────────────────────────────────────────────────────────────────────
// The bezel lip's shadow, cast onto the glass below it.
//
// Physically: the frame stands proud of the face by `depthPx`, so a lamp that is
// not straight overhead throws the lip's edge inward. Sampling the aperture at a
// point pushed TOWARD the lamp answers "would the lip be between me and it?" —
// where that sample lands outside the opening, yes, and this pixel is occluded.
// The shadow therefore hugs the edge NEAREST the lamp and reaches away from it,
// which is the inset-screen look, and it swings around the frame as the lamp moves.
//
// toL.z is the lamp's height; dividing by it is the tan() that makes a low grazing
// lamp throw a long shadow. Clamped so an overhead lamp doesn't divide by zero.
// ─────────────────────────────────────────────────────────────────────────────
float uiDispInnerShadow(float2 uv, float2 quadPx, float insetPx, float radiusPx,
                        float3 gPos, float4 gFx, float2 lightSpacePos,
                        float depthPx, float intensity)
{
    if (gFx.x < 0.5 || depthPx < 0.01 || intensity < 0.001) return 0.0;

    float3 toL = UIToLightVector(UILightDirection(gPos, lightSpacePos));
    float2 off = (toL.xy / max(toL.z, 0.12)) * depthPx;

    // Cap the throw. A grazing lamp sends depth*tan(angle) toward infinity, and a lip
    // 3px proud has no business shading 24px into the glass (measured at lamp height
    // 0.12) — past a few times its own depth it stops reading as a lip and starts
    // reading as a gradient someone painted on the picture.
    float reach = length(off);
    float cap   = depthPx * 2.5;
    if (reach > cap) off *= cap / max(reach, 1e-4);

    float2 uvOff = uv + off / max(quadPx, float2(1.0, 1.0));
    float  d     = uiDispAperture(uvOff, quadPx, insetPx, radiusPx);

    // Soften over ~1.5px so the terminator is a shadow edge, not a jaggy.
    return smoothstep(-1.5, 1.5, d) * intensity;
}


// ═════════════════════════════════════════════════════════════════════════════
// The whole surface, applied to an already-composited emissive picture.
//
// ORDER IS PHYSICAL, and it is the order the light actually meets the pixel:
//   1. the lip's shadow lands ON the picture (it is between the lamp and the face)
//   2. the cover's own body tint multiplies through
//   3. reflections ADD on top — they are light arriving at the eye, not paint
// Reversing 1 and 3 would let the inner shadow darken the reflection, which would
// mean the frame casting a shadow onto its own glare. It doesn't.
// ═════════════════════════════════════════════════════════════════════════════
void UIApplyDisplaySurface(inout float4 acc, float2 uv, float2 lightSpacePos,
                           UIDisplaySurfaceDesc s,
                           float3 gPos1, float4 gCol1, float4 gFx1,
                           float3 gPos2, float4 gCol2, float4 gFx2,
                           float3 gPos3, float4 gCol3, float4 gFx3)
{
    if (s.mode < 0.5) return;

    float4 baseA = uiDispBaseA(s.mode);
    float4 baseB = uiDispBaseB(s.mode);

    float reflectAmt = baseA.x * s.reflectivity;
    float glossAmt   = saturate(baseA.y * s.gloss);
    float roughAmt   = saturate(baseA.z * s.rough);
    float fresAmt    = baseA.w * s.fresnel;
    float curveAmt   = baseB.x * s.curve;
    float envAmt     = baseB.y * s.env;
    float shadowPx   = baseB.z;
    float edgeRollPx = baseB.w;

    float2 quadPx = max(s.quadPx, float2(1.0, 1.0));
    float  apert  = uiDispAperture(uv, quadPx, s.bezelPx, s.bezelRoundPx);
    float2 apGrad = uiDispApertureGrad(uv, quadPx, s.bezelPx, s.bezelRoundPx);

    // ---- the key lamp ------------------------------------------------------
    // The brightest ENABLED lamp, used for the two things that must read as coming
    // from one place: the bezel's inset shadow and which way the reflected room is
    // bright. Three overlapping inset shadows read as grime rather than as depth.
    float w1 = (gFx1.x > 0.5) ? gCol1.w : 0.0;
    float w2 = (gFx2.x > 0.5) ? gCol2.w : 0.0;
    float w3 = (gFx3.x > 0.5) ? gCol3.w : 0.0;
    float3 kPos = gPos1; float4 kFx = gFx1; float4 kCol = gCol1;
    if (w2 > w1 && w2 >= w3) { kPos = gPos2; kFx = gFx2; kCol = gCol2; }
    else if (w3 > w1 && w3 > w2) { kPos = gPos3; kFx = gFx3; kCol = gCol3; }

    float3 keyToL   = UIToLightVector(UILightDirection(kPos, lightSpacePos));
    float2 keyDirXY = normalize(keyToL.xy + float2(1e-5, 1e-5));

    // ---- 1. bezel lip shadow, onto the picture -----------------------------
    if (s.innerShadow > 0.001)
    {
        float occ = uiDispInnerShadow(uv, quadPx, s.bezelPx, s.bezelRoundPx,
                                      kPos, kFx, lightSpacePos,
                                      shadowPx, s.innerShadow);
        // Confined to the glass: the frame draws itself, and darkening outside the
        // opening would just smear the shadow across the bezel's own face.
        float inGlass = 1.0 - smoothstep(-1.0, 1.0, apert);
        acc.rgb *= 1.0 - saturate(occ * 0.55) * inGlass;
    }

    // ---- 2. reflections ----------------------------------------------------
    float3 N    = uiDispNormal(uv, quadPx, apert, apGrad, curveAmt, edgeRollPx, roughAmt);
    float  fres = uiDispFresnel(N, fresAmt);

    float3 spec = uiDispLampSpec(N, gPos1, gCol1, gFx1, lightSpacePos, glossAmt, roughAmt)
                + uiDispLampSpec(N, gPos2, gCol2, gFx2, lightSpacePos, glossAmt, roughAmt)
                + uiDispLampSpec(N, gPos3, gCol3, gFx3, lightSpacePos, glossAmt, roughAmt);

    // Fresnel lifts the reflected bulb at the rim without ever killing it face-on,
    // which is why this is a lerp against 1 rather than a plain multiply.
    spec *= lerp(1.0, 1.0 + fres * 2.0, 0.6);

    // The reflected room is tinted by the key lamp, so switching the rig's lights off
    // dims the ambient reflection too instead of leaving a screen glowing on its own.
    float3 roomCol = s.envColor * lerp(float3(1, 1, 1), kCol.rgb, 0.6)
                   * saturate(max(max(w1, w2), w3));
    spec += uiDispEnvironment(N, roomCol, envAmt, fres, keyDirXY);
    spec *= reflectAmt;

    // Readability guard — see the header. On an EMISSIVE screen the bright pixels are the
    // signal, so reflection is pulled back over them and left to fall on the dark
    // background, which is what the eye does anyway.
    //
    // An LCD is the exact opposite: its signal is DARK on a lit field, so that same rule
    // sends the reflection straight onto the segments it is supposed to protect and
    // erases them — the transfer curve on the CL-76 all but vanished. There is nothing to
    // selectively protect on an absorptive display, so it takes the reflection uniformly
    // and relies on its lower base reflectivity instead. A uniform add preserves the
    // absolute contrast between segment and field; a selective one destroys it.
    if (!uiDispInverted(s.mode))
    {
        float lum = dot(acc.rgb, float3(0.299, 0.587, 0.114));
        spec *= 1.0 - saturate(lum * 1.4) * saturate(s.signalMask);
    }

    // Reflections stop at the glass edge; past it is frame, not screen.
    spec *= 1.0 - smoothstep(-1.0, 1.0, apert);

    // Premultiplied add: a reflection makes an otherwise transparent well opaque
    // exactly as much as it brightens it, or the highlight ghosts over whatever
    // is behind the panel.
    acc.rgb += spec;
    acc.a    = saturate(acc.a + dot(spec, float3(0.299, 0.587, 0.114)));
}


// ─────────────────────────────────────────────────────────────────────────────
// This fragment's position in the rig's space: normalized screen, y up, x scaled
// by the screen aspect — the space UiLightRig.PosVector publishes lamps in and the
// space UiSceneDirector publishes every widget's _Position in. `sp` is the
// ComputeScreenPos varying AFTER the perspective divide.
//
// Deriving it here rather than taking a pushed _Position is what makes the light
// per-fragment (see the header), and it also means these three shaders need no C#
// change to join the rig — they are not MaterialStateControllers, so nothing was
// ever pushing them a _Position in the first place.
// ─────────────────────────────────────────────────────────────────────────────
#define UI_DISPLAY_LIGHT_POS(sp) \
    float2((sp).x * (_ScreenParams.x / max(_ScreenParams.y, 1.0)), (sp).y)

// ─────────────────────────────────────────────────────────────────────────────
// CUT-IN — the hole in the faceplate the whole display sits in (2026-09-18).
//
// The bezel above is a moulding AROUND the glass. This is the opening in the METAL around
// both: the same "edge" idea the widget shaders use (an SDF band with a falloff), turned
// inward. Two parts, both measured from the quad's own rounded boundary, in pixels:
//
//   EDGE  — a dark band that rolls off smoothly into the picture: the shadow of the lip,
//           the thing that makes a screen read as sitting IN the panel rather than on it.
//   BEVEL — the wall of the hole, a negative-depth chamfer lit by the key lamp. It faces
//           INTO the hole, so it is lit on the side AWAY from the lamp and shaded on the
//           side nearest it — the reverse of a raised button, which is exactly what sells
//           "cut in" rather than "stuck on". Only on displays at least bevelMinPx on their
//           short side: on a 22px meter it is a smudge, on a scope it is the whole effect.
//
// Both widths grow with the display (sizeK, 0.6×–1.8× around a 120px short side), so a big
// screen gets a deeper hole and a small one keeps its picture.
// ─────────────────────────────────────────────────────────────────────────────

// Signed distance INTO the quad from its rounded outer boundary, in px (+ inside).
float uiDispInsideDist(float2 uv, float2 quadPx, float radiusPx)
{
    float2 halfPx = quadPx * 0.5;
    float r = min(radiusPx, min(halfPx.x, halfPx.y));
    float2 q = abs(uv * quadPx - halfPx) - (halfPx - r);
    return -(length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r);
}

void UIApplyDisplayCutIn(inout float4 acc, float2 uv, float2 quadPx, float2 lightSpacePos,
                         float edgePx, float4 edgeColor, float edgeStrength, float roundPx,
                         float bevelPx, float bevelDepth, float bevelMinPx, float4 wallColor,
                         float3 gPos, float4 gColor, float4 gFx)
{
    if (edgePx <= 0.001 && bevelPx <= 0.001) return;

    float shortPx = min(quadPx.x, quadPx.y);
    float sizeK = clamp(shortPx / 120.0, 0.6, 1.8);
    float inside = uiDispInsideDist(uv, quadPx, roundPx);

    // Past the rounded corner is NOT the display any more — it is the faceplate the hole is cut
    // in. It used to be painted solid edge colour, which left four square dark corners outside
    // every rounded hole (2026-09-19); now it is cut away (coverage at the end) so the plate
    // behind shows through and the hole is really round.
    float rim = saturate(0.5 - inside);

    // ---- BEVEL: the WALL of the hole, outermost ------------------------------
    // Its own material (wallColor — the faceplate's metal, not the picture), so it reads on a
    // black screen as well as a pale one. It faces INTO the hole: lit on the side away from
    // the lamp, shaded on the side nearest it — the reverse of a raised button.
    float bPx = (bevelPx > 0.001 && shortPx >= bevelMinPx) ? bevelPx * sizeK : 0.0;
    if (bPx > 0.001)
    {
        float band = saturate(1.0 - inside / bPx) * (1.0 - rim);
        float wallA = smoothstep(0.0, 0.35, band) * wallColor.a;   // hard-ish inner edge of the wall
        float2 outward = uiDispApertureGrad(uv, quadPx, 0.0, roundPx);
        float3 toL = UIToLightVector(UILightDirection(gPos, lightSpacePos));
        float facing = dot(-outward, normalize(toL.xy + 1e-5));
        float3 keyRgb = (gFx.x > 0.5) ? gColor.rgb : float3(1, 1, 1);
        float3 wall = wallColor.rgb * (0.55 + 0.9 * saturate(facing) * bevelDepth)
                    * (1.0 - 0.65 * saturate(-facing) * bevelDepth);
        wall += keyRgb * saturate(facing) * band * bevelDepth * 0.18;
        acc.rgb = lerp(acc.rgb, wall, wallA);
    }

    // ---- EDGE: the lip's shadow, rolling off into the picture ---------------
    // Starts where the wall ends (or at the quad's edge when there is no wall).
    float ePx = edgePx * sizeK;
    if (ePx > 0.001)
    {
        float s = inside - bPx;                 // px past the foot of the wall
        float t = 1.0 - saturate(s / ePx);
        float roll = t * t * (3.0 - 2.0 * t);   // smooth at both ends…
        roll *= roll;                           // …and weighted to the lip
        float a = roll * edgeStrength;
        if (bPx > 0.001) a *= saturate(s + 1.0);  // the shadow falls on the picture, not the wall
        a = saturate(a) * edgeColor.a;
        acc.rgb = lerp(acc.rgb, edgeColor.rgb * acc.a, a);
    }

    // The hole's outline, anti-aliased over a pixel. acc is premultiplied, so scaling all four
    // channels fades the corner to the faceplate behind rather than to a painted colour.
    acc *= saturate(inside + 0.5);
}

#define UI_APPLY_DISPLAY_CUT_IN(acc, uv, quadPx, lightSpacePos)                         \
    UIApplyDisplayCutIn(acc, uv, quadPx, lightSpacePos,                                   \
        _CutEdgePx, _CutEdgeColor, _CutEdgeStrength, _CutRoundPx,                         \
        _CutBevelPx, _CutBevelDepth, _CutBevelMinPx, _CutWallColor,                       \
        _GlobalLightPos1, _GlobalLightColor1, _GlobalLightFx1)

// Apply the surface with the rig's globals in scope. A macro for the same reason
// UI_LIGHT_1 is one: the uniforms are declared per-shader, so a shared function
// here could not see them.
#define UI_APPLY_DISPLAY_SURFACE(acc, uv, lightSpacePos, desc)          \
    UIApplyDisplaySurface(acc, uv, lightSpacePos, desc,                 \
        _GlobalLightPos1, _GlobalLightColor1, _GlobalLightFx1,          \
        _GlobalLightPos2, _GlobalLightColor2, _GlobalLightFx2,          \
        _GlobalLightPos3, _GlobalLightColor3, _GlobalLightFx3)

// The authored multiplier block — identical in all three display shaders, so it
// lives in one place and a new term is added once. A macro rather than three
// hand-copied lists because a shader that silently omitted one would compile fine
// and then read garbage for that term.
#define UI_DISPLAY_SURFACE_UNIFORMS \
    float _SurfaceReflect;          \
    float _SurfaceGloss;            \
    float _SurfaceRough;            \
    float _SurfaceFresnel;          \
    float _SurfaceCurveOptical;     \
    float _SurfaceEnv;              \
    float _SurfaceInnerShadow;      \
    float _SurfaceSignalMask;       \
    float4 _SurfaceEnvColor;        \
    float _CutEdgePx;               \
    float4 _CutEdgeColor;           \
    float _CutEdgeStrength;         \
    float _CutRoundPx;              \
    float _CutBevelPx;              \
    float _CutBevelDepth;           \
    float _CutBevelMinPx;           \
    float4 _CutWallColor;

// Fill a desc from those uniforms. `mode`, `bezelPx`, `bezelRoundPx` and `quadPx`
// are passed because the three shaders name them differently (or, for the two that
// had no surface at all, only just gained them).
#define UI_DISPLAY_SURFACE_DESC(dst, modeIn, bezelIn, bezelRoundIn, quadPxIn) \
    UIDisplaySurfaceDesc dst;                                                 \
    dst.mode        = modeIn;                                                 \
    dst.reflectivity = _SurfaceReflect;                                       \
    dst.gloss       = _SurfaceGloss;                                          \
    dst.rough       = _SurfaceRough;                                          \
    dst.fresnel     = _SurfaceFresnel;                                        \
    dst.curve       = _SurfaceCurveOptical;                                   \
    dst.env         = _SurfaceEnv;                                            \
    dst.innerShadow = _SurfaceInnerShadow;                                    \
    dst.signalMask  = _SurfaceSignalMask;                                     \
    dst.envColor    = _SurfaceEnvColor.rgb * _SurfaceEnvColor.a;              \
    dst.bezelPx     = bezelIn;                                                \
    dst.bezelRoundPx = bezelRoundIn;                                          \
    dst.quadPx      = quadPxIn;

// NOTE: the matching ShaderLab Properties entries are written out longhand in each
// display shader. They cannot be macro'd — the Properties block is parsed by
// ShaderLab before the CG preprocessor ever runs, so a macro there is just text.
// Keep this list in sync when adding a term:
//   _SurfaceReflect / _SurfaceGloss / _SurfaceRough / _SurfaceFresnel /
//   _SurfaceCurveOptical / _SurfaceEnv / _SurfaceInnerShadow /
//   _SurfaceSignalMask / _SurfaceEnvColor
//   _CutEdgePx / _CutEdgeColor / _CutEdgeStrength / _CutRoundPx /
//   _CutBevelPx / _CutBevelDepth / _CutBevelMinPx / _CutWallColor

#endif // UI_DISPLAY_SURFACE_INCLUDED
