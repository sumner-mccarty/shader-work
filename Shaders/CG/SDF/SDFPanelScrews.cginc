// ============================================================================
// SDFPanelScrews.cginc — the corner hardware a faceplate is bolted down with
// ============================================================================
// Pure functions, no uniforms. SDFPanel.shader owns the properties and passes
// everything in, matching the rest of the CG/SDF library.
//
// SPACE AND UNITS — the reason this file exists.
//
// The screws used to be placed at a fixed count of REAL SCREEN PIXELS in from
// the raw quad corner, derived from ddx/ddy. That is not where the corner is:
// the visible panel is inset from the quad by `_PanelPadding` and its corner is
// rounded/chamfered by the body shape, so the bolts drifted off the corner they
// were supposed to be holding down the moment either changed, and they did not
// scale with the panel the way every other feature does.
//
// They now live in the panel's own `pos` space — the isotropic, aspect-corrected
// space SDFPanel builds once at the top of its fragment program — and are
// measured inward from the PANEL BODY's half-extents. `_PanelScrewInset` and
// `_PanelScrewRadius` are therefore in exactly the same units as
// `_PanelPadding`: padding pushes the body in from the quad by a constant, the
// inset pushes the screw in from THAT by a constant, and both track the panel
// at any size. (This is also why the properties lost their `Px` suffix — the
// old names promised pixels, which is no longer what they are.)
//
// Because `pos` is isotropic (equal units per pixel on both axes for any aspect
// ratio) a screw is round on a wide rack faceplate and on a tall side rail
// alike, with no aspect correction at the call site.
// ============================================================================

#ifndef SDF_PANEL_SCREWS_INCLUDED
#define SDF_PANEL_SCREWS_INCLUDED

// ── the drive recess cut into the head ──────────────────────────────────────
//
// `q` is head-normalised (|q| = 1 at the head's edge) and already rotated by
// _PanelScrewRotation. Returns a signed distance, < 0 inside the cut. Shapes
// with no recess (a plain dome rivet, a bare hex bolt head) return a large
// positive so the caller's smoothstep resolves to "nothing cut" without a
// branch.
//
// Matches ScrewShapeType in ShaderConstants.cs — keep the two in step.
inline float pnScrewRecessSDF(float2 q, int shape)
{
    if (shape == 0)                                   // SLOTTED — one straight drive slot
        return RectangleSDF(q, float2(0.78, 0.115));
    if (shape == 1)                                   // PHILLIPS — equal cross
        return CrossSDF(q, float2(0.70, 0.115), 0.02);
    if (shape == 2)                                   // HEX SOCKET (Allen)
        return HexagonSDF(q, 0.46);
    if (shape == 3)                                   // TORX — six-lobe star
        return StarSDF(q, 0.50, 6, 3.2);
    if (shape == 6)                                   // POZIDRIV — cross + 45° ticks
        return min(CrossSDF(q, float2(0.70, 0.105), 0.02),
                   CrossSDF(rotate2D(q, PI * 0.25), float2(0.40, 0.055), 0.01));
    if (shape == 7)                                   // ROBERTSON — square socket
        return RectangleSDF(q, float2(0.40, 0.40));
    return 1.0;                                       // 4 DOME · 5 HEX HEAD — no recess
}

// ── the head outline ────────────────────────────────────────────────────────
inline float pnScrewHeadSDF(float2 q, int shape)
{
    if (shape == 5) return HexagonSDF(q, 1.0);        // HEX HEAD — a bolt, not a screw
    return length(q) - 1.0;
}

// ── where a screw goes ──────────────────────────────────────────────────────
//
// Walk in from the plate's rectangular corner along the 45° diagonal until the
// BODY's own signed distance field reads -inset. The screw then sits a true
// constant distance inside the plate's edge whatever the corner is doing — a
// squircle's round, an octagon's chamfer, a hexagon's slope — instead of at a
// fixed x/y offset that floats the bolt off into empty space the moment the
// corner stops being square. This is the same relationship `_PanelPadding` has
// with the quad, one level in.
//
// Sphere tracing converges here because the step is taken straight down the
// distance gradient; the sharp-rect worst case shrinks the error by ~0.29 per
// iteration, so five steps land inside a quarter percent. It is all uniform
// math (half-extents and shape params are constants across the quad), so the
// compiler hoists the whole thing out of the fragment.
inline float2 pnScrewCentre(float2 sgn, float halfW, float halfH, int shape,
                            float p1, float p2, float p3, float inset)
{
    float2 dir = -sgn * 0.70710678;
    float2 p   = sgn * float2(halfW, halfH);
    [unroll] for (int k = 0; k < 5; k++)
        p += dir * (getPanelBodySDF(p, halfW, halfH, shape, p1, p2, p3, -2, float2(0, 0)) + inset);
    return p;
}

// ── one screw ───────────────────────────────────────────────────────────────
//
// Returns the head coverage 0..1 and writes the shaded colour to `outColor`.
// `toLight` is the TO-LIGHT vector (UIToLightVector of the key lamp's travel
// direction — see UILighting.cginc's sign note), so the hardware relights with
// every other widget instead of carrying a painted-on highlight the way the old
// hard-coded "light from the top-left" block did.
float pnScrewShade(float2 rel, float aa, int shape, float rotRad,
                   float3 headColor, float3 slotColor,
                   float depth, float metallic, float3 toLight, float ambient,
                   out float3 outColor)
{
    float head = smoothstep(aa, -aa, pnScrewHeadSDF(rel, shape));
    outColor = headColor;
    if (head <= 0.0005) return 0.0;

    // Domed head: a hemisphere normal over the disc. 0.82 keeps it a shallow
    // pan head rather than a ball bearing. Diffuse is kept under unity so the
    // metal never flat-clips to white before the glint has even been added.
    float  r2 = saturate(dot(rel, rel));
    float3 n  = normalize(float3(rel * 0.82, sqrt(max(1.0 - r2 * 0.70, 1e-4))));
    float  ndl = saturate(dot(n, toLight));
    float3 col = headColor * (ambient * 0.50 + 0.60 * ndl);

    // Blinn glint, NOT pow(ndl): a UI widget is viewed straight on, so the
    // highlight belongs on the half-vector between the lamp and (0,0,1). Keying
    // it off ndl instead puts the hotspot wherever the surface faces the lamp
    // most directly, which on a dome is a big soft blob rather than a spark.
    float3 hv   = normalize(toLight + float3(0, 0, 1));
    float  spec = pow(saturate(dot(n, hv)), 34.0);
    col += headColor * spec * metallic * 0.55;

    // Rolled edge: the rim facing the lamp catches a crescent, the far rim rolls
    // into shade. This is what stops a screw reading as a flat printed dot.
    float rim     = smoothstep(0.66, 1.0, sqrt(r2));
    float rimFace = dot(normalize(rel + 1e-5), toLight.xy);
    col *= 1.0 - rim * saturate(-rimFace) * 0.50;
    col += headColor * rim * saturate(rimFace) * 0.30 * metallic;

    // Drive recess. Two evaluations, one shifted along the lamp direction: the
    // difference between the two masks IS the wall geometry, which gives a
    // correct engraved read (near lip shaded, far wall lit) for every shape
    // without this file having to know any shape's normals.
    float2 q  = rotate2D(rel, -rotRad);
    float2 lq = rotate2D(normalize(toLight.xy + 1e-5), -rotRad) * 0.075;
    float  inR  = smoothstep(aa, -aa, pnScrewRecessSDF(q, shape));
    float  inRS = smoothstep(aa, -aa, pnScrewRecessSDF(q - lq, shape));
    col  = lerp(col, slotColor * (ambient * 0.55 + 0.18), inR * depth);
    col += headColor * saturate(inRS - inR) * depth * 0.60;   // far wall, lit
    col *= 1.0 - saturate(inR - inRS) * depth * 0.45;         // near lip, shaded

    outColor = col;
    return head;
}

// ── the four corners ────────────────────────────────────────────────────────
//
// `bodyPos` / `bodyHalfW` / `bodyHalfH` are the panel body's own coordinates, so
// the screws inherit the body's rotation for free and sit a constant distance in
// from ITS corner rather than the quad's.
//
// `aaPos` is the pos-space width of one pixel, computed ONCE by the caller
// outside any branch — `pos` is linear in uv, so a single fwidth is exact for
// every corner and a derivative inside this loop would be undefined anyway.
// ── the counterbore ─────────────────────────────────────────────────────────
//
// What was missing to make a screw read as fitted rather than printed on: the
// PANEL is dished around the bolt. Without it the head is a disc pasted onto a
// flat surface, which is exactly how the old ones looked at any size — all the
// shading lived inside the head and stopped dead at its edge.
//
// The bowl's wall normal points inward, so the wall on the FAR side from the
// lamp is the one that catches light and the near side falls into shade — the
// opposite of the head's own rolled rim, which is what sells the depth. A flat
// darkening term rides underneath as contact occlusion.
//
// `rel` is head-normalised (|rel| = 1 at the head's edge); `bore` is the bowl's
// extra radius in head radii, so 0 turns the whole thing off.
inline void pnScrewBore(inout float3 panel, float2 rel, float bore,
                        float3 toLight, float aa)
{
    if (bore <= 0.001) return;
    float outer = 1.0 + bore;
    float rr    = length(rel);
    // 1 at the head's edge, 0 at the bowl's rim, and nothing at all beyond it.
    float t = saturate((outer - rr) / max(bore, 1e-4));
    t *= smoothstep(-aa, aa, outer - rr);
    if (t <= 0.001) return;

    float2 dir = normalize(rel + 1e-5);
    float  nd  = dot(-dir, toLight.xy);
    panel *= 1.0 - t * (0.30 + 0.34 * saturate(-nd));
    panel += panel * t * saturate(nd) * 0.28;
}

void panelDrawScrews(inout float4 finalColor, float2 bodyPos,
                     float bodyHalfW, float bodyHalfH, int bodyShape,
                     float sp1, float sp2, float sp3, float aaPos,
                     float inset, float radius, int shape, float rotRad,
                     float3 headColor, float3 slotColor,
                     float depth, float metallic, float bore,
                     float3 toLight, float ambient)
{
    float rad = max(radius, 0.002);
    float aa  = max(aaPos / rad, 1e-4);

    [unroll] for (int i = 0; i < 4; i++)
    {
        float2 sgn = float2((i & 1) ? 1.0 : -1.0, (i & 2) ? 1.0 : -1.0);
        float2 c   = pnScrewCentre(sgn, bodyHalfW, bodyHalfH, bodyShape, sp1, sp2, sp3, inset);
        float2 rel = (bodyPos - c) / rad;

        // The bowl is cut into the panel BEFORE the head is laid into it.
        pnScrewBore(finalColor.rgb, rel, bore, toLight, aa);

        float3 col;
        float  m = pnScrewShade(rel, aa, shape, rotRad,
                                headColor, slotColor, depth, metallic, toLight, ambient, col);
        if (m > 0.0005) buttonCompositeOver(finalColor, col, m);
    }
}

#endif // SDF_PANEL_SCREWS_INCLUDED
