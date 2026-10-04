// ============================================================================
// SDFPlayRing.cginc — the pad's PLAY-TIME RING and LOOP GLYPH (UI/SDFButtonRM section 6)
//
// Both are drawn on the FACE plane (frag2dFacePos), so they tilt, shift and foreshorten with
// the pad exactly as the face does — which is why they live in the pad's shader and not in a
// UGUI overlay.
//
//   RING   A line running around the face, `_PlayRingInset` inside the face edge and following
//          its shape. It is the sample's timeline: the marker starts at TOP CENTRE at 0 and
//          runs clockwise, back to top centre when the sample's end time arrives.
//            _PlayRingProgress  0..1  where the marker is
//            _PlayRingActive    0..1  glow on/off (driven; the ring is a dim track when 0)
//   LOOP   A circular-arrow glyph on the face, shown while a LOOP pad is running.
//            _LoopGlyphActive   0/1   shown on any LOOP-mode pad
//            _LoopGlyphLit      0..1  glows while the loop is running
//
// Progress is measured around the SQUARE's perimeter, not by angle, so the marker moves at a
// constant speed along the line instead of sprinting through the corners.
// ============================================================================
#ifndef SDF_PLAY_RING_INCLUDED
#define SDF_PLAY_RING_INCLUDED

float  _PlayRingEnabled;
float4 _PlayRingColor;
float  _PlayRingWidth;       // half-thickness, quad units
float  _PlayRingInset;       // distance inside the face edge to the line's centre
float  _PlayRingProgress;
float  _PlayRingActive;
float  _PlayRingGlow;        // emissive multiplier when active
float  _PlayRingTrail;       // fraction of the lap the lit tail stretches behind the marker
float  _PlayRingTrack;       // alpha of the unlit track

float  _LoopGlyphActive;     // 0 = hidden, 1 = shown (pad is in LOOP mode)
float  _LoopGlyphLit;        // 0..1 glow — 1 while the loop is actually running
float4 _LoopGlyphColor;
float  _LoopGlyphSize;       // 0..1 of the LARGEST radius that clears the ring (auto-sized per pad)
float  _LoopGlyphRotation;   // degrees, clockwise — 25 leans the arrowhead toward the right
float4 _PlayBackColor;       // dark outline + plate behind ring and glyph (rgb, alpha = strength)
float2 _LoopGlyphOffset;     // face-space offset of the glyph centre (x right, y up on screen)

// Position 0..1 around the perimeter of a square, 0 at top centre, clockwise.
// `p` is in screen-oriented space: +x right, -y up (the icon convention).
float PlayRingPerimeterT(float2 p)
{
    float ax = abs(p.x), ay = abs(p.y);
    float t;
    if (ay >= ax) {
        if (p.y < 0.0) t = 0.125 * (p.x / max(-p.y, 1e-5));          // top
        else           t = 0.5 + 0.125 * (-p.x / max(p.y, 1e-5));    // bottom
    } else {
        if (p.x > 0.0) t = 0.25 + 0.125 * (p.y / max(p.x, 1e-5));    // right
        else           t = 0.75 + 0.125 * (p.y / min(p.x, -1e-5));   // left
    }
    return frac(t + 1.0);
}

// Distance to a triangle (iq).
float PlayRingTriSDF(float2 p, float2 a, float2 b, float2 c)
{
    float2 e0 = b - a, e1 = c - b, e2 = a - c;
    float2 v0 = p - a, v1 = p - b, v2 = p - c;
    float2 q0 = v0 - e0 * saturate(dot(v0, e0) / dot(e0, e0));
    float2 q1 = v1 - e1 * saturate(dot(v1, e1) / dot(e1, e1));
    float2 q2 = v2 - e2 * saturate(dot(v2, e2) / dot(e2, e2));
    float s = sign(e0.x * e2.y - e0.y * e2.x);
    float2 d = min(min(float2(dot(q0, q0), s * (v0.x * e0.y - v0.y * e0.x)),
                       float2(dot(q1, q1), s * (v1.x * e1.y - v1.y * e1.x))),
                       float2(dot(q2, q2), s * (v2.x * e2.y - v2.y * e2.x)));
    return -sqrt(d.x) * sign(d.y);
}

// Circular-arrow glyph, unit radius. Screen-oriented p (+x right, -y up).
// A ring with a gap at the top-right and an arrowhead closing the clockwise end.
float PlayRingLoopGlyphSDF(float2 p)
{
    const float W = 0.13;                     // stroke half-width, in radii
    float r = length(p);
    float ang = atan2(p.x, -p.y);             // 0 at top, clockwise
    if (ang < 0.0) ang += 6.2831853;
    const float gapA = 0.95;                  // arc starts here...
    const float endA = 6.2831853 - 0.80;      // ...and ends here (arrow base)

    float dRing = abs(r - 1.0) - W;
    // Cap the arc at both ends: distance to the ring only where ang is inside the arc.
    float2 capS = float2(sin(gapA), -cos(gapA));
    float2 capE = float2(sin(endA), -cos(endA));
    float dCaps = min(length(p - capS), length(p - capE)) - W;
    float d = (ang >= gapA && ang <= endA) ? dRing : dCaps;

    // Arrowhead at the clockwise end, tip pointing along the tangent.
    float2 rad = capE;                        // radial direction at the end (unit)
    float2 tng = float2(cos(endA), sin(endA));
    float2 tip = capE + tng * 0.80;
    float2 b0  = capE + rad * 0.50;
    float2 b1  = capE - rad * 0.50;
    d = min(d, PlayRingTriSDF(p, b0, tip, b1));
    return d;
}

void PRCompose(inout float4 dst, float3 c, float a)
{
    dst.rgb = dst.rgb * (1.0 - a) + c * a;
    dst.a   = dst.a + a * (1.0 - dst.a);
}

// The whole layer. Shared by UI/SDFButtonRM (face-plane coords) and UI/SDFButton (flat).
//   dBody      the button's own outline SDF at this pixel (getButtonSDF, negative inside)
//   rp         face position in ICON space: +x right, -y up
//   halfWH     body half extents;  faceInset = rim + bevel width (where the flat face begins)
// Call from UNIFORM control flow (fwidth inside).
void PlayRingApply(float dBody, float2 rp, float2 halfWH, float faceInset,
                   inout float4 finalColor, inout float3 emissiveAccum)
{
    if (_PlayRingEnabled > 0.5) {
        float dFace = dBody + faceInset + _PlayRingInset;
        float aaR   = fwidth(dFace) * 0.75 + 1e-5;
        float ringLine = 1.0 - smoothstep(_PlayRingWidth - aaR, _PlayRingWidth + aaR, abs(dFace));
        float haloR = exp(-abs(dFace) / max(0.001, _PlayRingWidth * 2.2)) * 0.5;

        float t      = PlayRingPerimeterT(rp / halfWH);
        float behind = frac(_PlayRingProgress - t + 1.0);
        float swept  = step(t, _PlayRingProgress);
        float trail  = saturate(1.0 - behind / max(0.01, _PlayRingTrail));
        float dMk    = min(behind, 1.0 - behind);
        float head   = max(exp(-behind * 60.0) * step(behind, 0.5), exp(-dMk * 110.0));
        float lit    = saturate(swept * 0.45 + trail * 0.55 + head);
        float act    = _PlayRingActive;

        float a = ringLine * lerp(_PlayRingTrack, saturate(_PlayRingTrack + lit), act);
        a = max(a, ringLine * head * lerp(0.7, 1.0, act));
        // Dark keyline (twice the line's width) + soft shadow so the line pops off any face.
        float ob    = _PlayRingWidth * 2.1;
        float under = (1.0 - smoothstep(ob - aaR, ob + aaR, abs(dFace)))
                      + 0.5 * exp(-abs(dFace) / max(0.001, _PlayRingWidth * 3.5));
        PRCompose(finalColor, _PlayBackColor.rgb, saturate(under) * _PlayBackColor.a);
        float3 rc = _PlayRingColor.rgb;
        PRCompose(finalColor, rc, a * _PlayRingColor.a);
        emissiveAccum += rc * _PlayRingGlow * act *
                         (a * (0.55 + 0.45 * lit) + haloR * (0.35 * lit + head) * 0.6);
    }

    if (_LoopGlyphActive > 0.5) {
        // As big as clears the ring: free half-height inside the ring's keyline over the glyph's
        // own outer extent, so a wide pad and a square one each get the largest icon that cannot
        // touch the line.
        float freeR = min(halfWH.x, halfWH.y) - faceInset - _PlayRingInset - _PlayRingWidth * 2.6;
        float gR    = max(0.02, freeR / 1.32) * _LoopGlyphSize;
        float2 q0   = (rp - float2(_LoopGlyphOffset.x, -_LoopGlyphOffset.y)) / gR;
        float rot   = _LoopGlyphRotation * (3.14159265 / 180.0);
        float cr = cos(rot), sr = sin(rot);
        float2 q    = float2(cr * q0.x + sr * q0.y, -sr * q0.x + cr * q0.y);
        float dg    = PlayRingLoopGlyphSDF(q) * gR;
        float aaG   = fwidth(dg) * 0.75 + 1e-5;
        float gm    = 1.0 - smoothstep(-aaG, aaG, dg);
        float ol    = gR * 0.14;                       // dark stroke hugging the arrow
        float outl  = 1.0 - smoothstep(ol - aaG, ol + aaG, dg);
        PRCompose(finalColor, _PlayBackColor.rgb, outl * _PlayBackColor.a);
        float3 gc = _LoopGlyphColor.rgb;
        float ga  = gm * lerp(0.6, 1.0, _LoopGlyphLit);
        PRCompose(finalColor, gc, ga * _LoopGlyphColor.a);
        float halo = exp(-max(dg, 0.0) / max(0.004, gR * 0.3));
        emissiveAccum += gc * (ga * _LoopGlyphLit * _PlayRingGlow + halo * _LoopGlyphLit * 0.25);
    }
}

#endif // SDF_PLAY_RING_INCLUDED
