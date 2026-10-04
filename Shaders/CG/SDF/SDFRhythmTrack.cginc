// ============================================================================
// SDFRhythmTrack.cginc — pure functions for the Guitar-Hero note highway
// ============================================================================
// Library for SDFRhythmTrack.shader (tracker §1.7). No uniforms, no state —
// every function takes everything it needs as parameters, matching the
// CG/Core + CG/SDF architecture.
//
// COORDINATE SYSTEMS (established here, used by the shader):
//   uv          quad space, (0,0) bottom-left → (1,1) top-right
//   d01         normalized distance along the track surface, 0 = near edge
//               (bottom), 1 = far edge (top). NONLINEAR in v when tilted —
//               this is the perspective foreshortening.
//   t16         musical time in 16th notes. t16(v) = tNear + d01(v)*visible16.
//   trackX      lateral position across the track, -1 (left rail) .. +1
//               (right rail), perspective-corrected.
//   lane space  laneF = (trackX*0.5+0.5)*4 → 0..4; lane = floor(laneF);
//               laneLocal = frac(laneF)-0.5 → -0.5..+0.5 inside one lane.
//   note space  (xs, yt): xs = laneLocal * laneUnit16 (lateral, expressed in
//               16th-equivalent units so note gems keep their aspect ratio at
//               any zoom), yt = t16 relative to the note. All note SDFs live
//               here, so perspective foreshortening is automatic.
//
// PERSPECTIVE MODEL (classic ground-plane projection, closed form):
//   A camera looks down a plane; screen v of a point at plane depth z is
//   v = H*(1 - zNear/z) where H is the screen v of the horizon (H > 1 keeps
//   the horizon safely above the quad so the track never fully vanishes).
//   With zNear = 1:
//     zScale(v)  = H/(H-v)              lateral shrink factor (1 at bottom)
//     depth01(v) = v*(H-1)/(H-v)        0 at bottom edge, 1 at top edge
//     invDepth(p)= p*H/(H-1+p)          v for a given depth01 (hit-line pos)
//   H → ∞ degrades gracefully to the flat orthographic strip (tilt = 0).
// ============================================================================

#ifndef SDF_RHYTHM_TRACK_INCLUDED
#define SDF_RHYTHM_TRACK_INCLUDED

// ── perspective ─────────────────────────────────────────────────────────────

// Map tilt slider (0..1) to a horizon height. 14 ≈ visually flat, 1.045 ≈
// extreme racing-game tilt. Exponential-ish curve so the middle of the slider
// range is the sweet spot rather than the last 5%.
inline float rtHorizonFromTilt(float tilt)
{
    float t = saturate(tilt);
    return lerp(14.0, 1.045, t * t * (3.0 - 2.0 * t)); // smoothstep-shaped
}

inline float rtZScale(float v, float H)   { return H / max(H - v, 1e-4); }
inline float rtDepth01(float v, float H)  { return v * (H - 1.0) / max(H - v, 1e-4); }
inline float rtInvDepth01(float p, float H) { return p * H / max(H - 1.0 + p, 1e-4); }

// ── SDF / masks ─────────────────────────────────────────────────────────────

inline float rtRoundedBox(float2 p, float2 halfSize, float r)
{
    float2 q = abs(p) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Anti-aliased fill from an SDF: 1 inside, 0 outside, screen-width smooth edge.
inline float rtFill(float d)
{
    float aa = max(fwidth(d), 1e-5);
    return smoothstep(aa, -aa, d);
}

// Anti-aliased line mask from a distance and half-thickness (same units).
inline float rtLine(float d, float halfThick)
{
    float aa = max(fwidth(d), 1e-5);
    return smoothstep(halfThick + aa, halfThick - aa, abs(d));
}

// Soft exponential glow around an SDF (0 outside falloff, 1 at surface).
inline float rtGlow(float d, float falloff)
{
    return exp(-max(d, 0.0) / max(falloff, 1e-4));
}

// ── lane helpers ────────────────────────────────────────────────────────────

// Selection mask for one of 4 lanes: (1,0,0,0) for lane 0, etc.
inline float4 rtLaneMask4(float lane)
{
    return step(abs(float4(0.0, 1.0, 2.0, 3.0) - lane), 0.5);
}

// ── procedural hash / stars ─────────────────────────────────────────────────

inline float rtHash21(float2 p)
{
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

// One parallax starfield layer. p is a scaled 2D coordinate (cells ≈ 1 unit);
// scroll streams the field toward the viewer. Returns brightness 0..1.
inline float rtStarLayer(float2 p, float density, float time)
{
    float2 cell = floor(p);
    float2 f = frac(p);
    float h = rtHash21(cell);
    float present = step(h, density);
    float2 starPos = float2(rtHash21(cell + 7.13), rtHash21(cell + 3.71));
    float d = length(f - starPos);
    float twinkle = 0.55 + 0.45 * sin(time * (2.0 + h * 4.0) + h * 40.0);
    return present * exp(-d * d * 55.0) * twinkle;
}

// ── sky layers (the game-track THEME axis) ──────────────────────────────────
//
// The highway's palette was themable from the first version; the SPACE it flies
// through was one thing — a star field — and a colour swap can only take that so
// far. These are the alternatives, drawn into the same background section and
// gated by _SkyMode, so a theme picks a sky the way it picks colours.
//
// All of them are pure additive LIGHT over the gradient, cost nothing but ALU,
// and take their two colours from the theme rather than baking any in. Stars
// stay independent (_StarDensity), so every sky can have them or not.

// A better-decorrelated hash than <see cref="rtHash21"/>. rtHash21 is fine for the
// starfield, where each cell holds one point and neighbour correlation is invisible;
// used as a value-noise LATTICE it shows axis-aligned structure — soft rectangular
// blocks right through the clouds. This is the standard Hoskins hash and has none.
// rtHash21 is left exactly as it was so the star field doesn't shift under anyone.
inline float rtHash21b(float2 p)
{
    float3 p3 = frac(float3(p.x, p.y, p.x) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

// Smoothed value noise on a unit grid — the base both cloud layers are built on.
inline float rtValueNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = rtHash21b(i);
    float b = rtHash21b(i + float2(1.0, 0.0));
    float c = rtHash21b(i + float2(0.0, 1.0));
    float d = rtHash21b(i + float2(1.0, 1.0));
    return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
}

// Four octaves. Deliberately not more: this runs per fragment over a full panel,
// and past four the difference is invisible at the scales a sky is drawn at.
inline float rtFbm(float2 p)
{
    float v = 0.0;
    float amp = 0.5;
    [unroll]
    for (int i = 0; i < 4; i++)
    {
        v += amp * rtValueNoise(p);
        p *= 2.03;      // not exactly 2, or the octaves line up into visible grid seams
        amp *= 0.5;
    }
    return v;
}

// NEBULA — two-tone fbm cloud, densest toward the horizon and thinning out at the
// top of the frame so it frames the track rather than fogging the whole panel.
// Drifts with the music (scroll) plus a slow independent churn, so it reads as
// depth rather than as a texture pinned to the quad.
inline float3 rtSkyNebula(float2 uv, float aspect, float scroll, float time,
                          float3 colA, float3 colB, float amount, float scale)
{
    float2 p = float2(uv.x * aspect, uv.y) * max(scale, 0.05)
             + float2(time * 0.004, -scroll * 0.006 + time * 0.003);

    // Domain warp. Plain fbm gives even, blanket-like cloud; displacing the lookup
    // by a second, coarser fbm is what turns it into the torn wisps and dust lanes
    // that read as a nebula rather than as fog.
    float2 warp = float2(rtFbm(p * 0.5 + 11.3), rtFbm(p * 0.5 - 5.1)) - 0.5;
    p += warp * 1.6;

    float n = rtFbm(p);
    float m = rtFbm(p * 2.1 + 4.7);

    // Hard floor, then a power curve. Without the floor, fbm's midtones cover the
    // whole panel in a flat wash — the difference between "nebula" and "smeared
    // screen". Everything below the floor stays pure black sky with stars in it.
    float cloud = pow(saturate((n - 0.34) * 3.2), 1.6);

    float3 col = lerp(colA, colB, saturate((m - 0.35) * 2.0));
    float band = smoothstep(0.02, 0.35, uv.y) * (1.0 - 0.40 * smoothstep(0.70, 1.0, uv.y));
    return col * cloud * band * amount * 1.6;
}

// SYNTHWAVE SUN — a banded disc sitting on the horizon with a soft bloom around
// it. `horizonY` is where the track's own horizon lands, so the sun rises out of
// the same vanishing point the notes come from instead of floating near it.
//
// `sunU` is where it sits HORIZONTALLY in the shared sky space (see _SkyRect).
// It used to be hard-coded to 0.5 — the centre of the SCREEN — which is only the
// centre of the track when the track happens to be centred on the screen. It
// usually isn't: the front door puts a menu down the left third, so the highway
// panel sits off-centre and the sun rose out of its right-hand edge, half of it
// clipped away. The vanishing point the sun is supposed to share belongs to the
// TRACK, so the app passes the track's own centre and every other sky surface
// gets the same number — one sun, still shared, now behind the thing it is meant
// to be behind.
inline float3 rtSkySun(float2 uv, float aspect, float time,
                       float3 colA, float3 colB, float amount, float horizonY, float sunU)
{
    float2 p = float2((uv.x - sunU) * aspect, uv.y - horizonY);
    float r = length(p) / 0.20;

    float aa = max(fwidth(r), 1e-4);
    float disc = smoothstep(1.0 + aa, 1.0 - aa, r);

    // The slots. They widen downward, which is the whole retro-sun signature —
    // a disc with evenly spaced bands is just a striped circle.
    float h = (uv.y - horizonY) / 0.20;                 // -1 (bottom) .. 1 (top)
    float slots = step(0.0, sin(h * 30.0 + time * 0.6));
    float cut = saturate(slots + smoothstep(-0.1, 0.85, h));

    float3 sunCol = lerp(colB, colA, saturate(h * 0.5 + 0.5));
    float bloom = exp(-max(r - 1.0, 0.0) * 3.2) * 0.5;

    return (sunCol * disc * cut + colA * bloom) * amount;
}

// AURORA — three drifting ribbons with vertical streaking. Cheap, and the one sky
// that MOVES enough to be felt without pulling the eye off the notes, because all
// of the motion is slow and lateral while the notes travel vertically.
inline float3 rtSkyAurora(float2 uv, float aspect, float time,
                          float3 colA, float3 colB, float amount)
{
    float x = uv.x * aspect;
    float3 col = float3(0.0, 0.0, 0.0);

    [unroll]
    for (int i = 0; i < 3; i++)
    {
        float fi = (float)i;
        float phase  = time * (0.13 + fi * 0.045) + fi * 2.1;
        float centre = 0.52 + fi * 0.09 + 0.11 * sin(x * (1.6 + fi * 0.55) + phase);
        float width  = 0.085 + 0.045 * sin(x * 2.3 - phase);
        float dy     = (uv.y - centre) / max(width, 1e-3);
        float ribbon = exp(-dy * dy);
        ribbon *= 0.6 + 0.4 * rtValueNoise(float2(x * 6.0 + fi * 13.0, time * 0.3 + fi));
        col += lerp(colA, colB, fi * 0.5) * ribbon;
    }
    // Faded out at the very bottom: an aurora reaching down past the receptors
    // would be competing with the one part of the screen you are actually reading.
    return col * amount * 0.5 * smoothstep(0.05, 0.4, uv.y);
}

// BEAMS — a lighting rig above the frame, four shafts sweeping through haze.
// The one sky that is a ROOM rather than a distance: beams are only visible
// because there is something in the air, so the haze term is not decoration,
// it is what makes the shafts read at all.
inline float3 rtSkyBeams(float2 uv, float aspect, float time,
                         float3 colA, float3 colB, float amount)
{
    float2 p = float2(uv.x * aspect, uv.y);
    float2 o = float2(0.5 * aspect, 1.35);        // the rig, just off the top of the frame
    float2 d = p - o;
    float ang = atan2(d.x, -d.y);                 // 0 = straight down
    float dist = length(d);

    // How wide the frame IS, in angle, from where the rig is standing. Everything below is
    // expressed as a fraction of this rather than in absolute radians — otherwise one sweep
    // amplitude is right at exactly one aspect ratio: a portrait phone subtends about a
    // quarter of the angle a 16:9 laptop does, so a fixed sweep either barely moves on the
    // wide screen or spends most of its time off the edge of the narrow one.
    float halfAng = atan2(0.5 * aspect, 1.35);

    float3 col = float3(0.0, 0.0, 0.0);
    [unroll]
    for (int i = 0; i < 4; i++)
    {
        float fi = (float)i;
        // Each head sweeps at its own rate, so they cross rather than march in step —
        // four beams on one timer is a windscreen wiper, not a light show.
        float sweep = sin(time * (0.21 + fi * 0.055) + fi * 1.7) * halfAng * 1.15;
        float w = (0.10 + 0.05 * sin(time * 0.5 + fi * 2.3)) * halfAng;
        float t = (ang - sweep) / max(w, 1e-3);
        float beam = exp(-t * t);
        beam *= exp(-max(dist - 0.35, 0.0) * 1.15);   // dies out before it reaches the floor
        col += lerp(colA, colB, frac(fi * 0.37)) * beam;
    }

    col += lerp(colA, colB, 0.5) * smoothstep(1.15, 0.15, uv.y) * 0.16;
    return col * amount * 0.55;
}

// STRANDS — lit cable runs in the dark. Five sinuous lines, each a hard core in a
// soft halo, drifting at their own rate. The studio-at-2am sky: the only one made
// of objects, and the objects are the ones the whole app is about.
inline float3 rtSkyStrands(float2 uv, float aspect, float time,
                           float3 colA, float3 colB, float amount)
{
    float x = uv.x * aspect;
    float3 col = float3(0.0, 0.0, 0.0);

    [unroll]
    for (int i = 0; i < 5; i++)
    {
        float fi = (float)i;
        float sp = 0.06 + fi * 0.017;
        // Two summed sines, not one: a single sine is a wave, two is a cable lying
        // where it fell.
        float yc = 0.14 + fi * 0.175
                 + 0.075 * sin(x * (1.25 + fi * 0.33) + time * sp * 6.0 + fi * 2.1)
                 + 0.035 * sin(x * (2.70 - fi * 0.21) - time * sp * 4.0);

        float dy = abs(uv.y - yc);
        float core = exp(-(dy / 0.0034) * (dy / 0.0034));
        float halo = exp(-dy / 0.055) * 0.20;
        col += lerp(colA, colB, fi * 0.25) * (core + halo);
    }
    return col * amount * 0.55;
}

// SILK — smooth banded colour, domain-warped. No hard floor anywhere, which is the
// whole point: nebula is made of edges and gaps, this is made of GRADIENT. The
// quiet option, and the one that carries warm and pastel palettes without looking
// like a sci-fi asset wearing pink.
inline float3 rtSkySilk(float2 uv, float aspect, float time,
                        float3 colA, float3 colB, float amount, float scale)
{
    float2 p = float2(uv.x * aspect, uv.y) * max(scale, 0.05) * 0.55;
    float2 warp = float2(rtFbm(p * 0.7 + 3.1), rtFbm(p * 0.7 - 1.9)) - 0.5;
    p += warp * 2.4 + float2(time * 0.010, time * 0.005);

    float n = rtFbm(p);
    float band = 0.5 + 0.5 * sin(n * 9.0 + uv.y * 2.4);
    band = band * band * (3.0 - 2.0 * band);       // ease the band edges, twice-over soft

    // Heaviest low in the frame and thinning upward, so the top stays calm and the
    // notes coming out of it are never fighting a bright band.
    float falloff = 0.35 + 0.65 * (1.0 - smoothstep(0.15, 1.0, uv.y));
    return lerp(colA, colB, band) * falloff * amount * 0.5;
}

// One line of a unit-spaced grid, anti-aliased by its own screen derivative. Without the
// derivative term a perspective grid aliases into moiré long before it reaches the horizon,
// because the lines get closer together than the pixels sampling them.
inline float rtGridLine(float coord)
{
    float w = max(fwidth(coord), 1e-5);
    float f = abs(frac(coord + 0.5) - 0.5);
    return 1.0 - smoothstep(0.0, w * 1.5, f);
}

// GRID — a wireframe plane running out to a horizon, mirrored overhead.
//
// The one sky made of STRAIGHT LINES. Every other mode here is weather — clouds, ribbons, haze,
// a sun — and weather all reads roughly the same at a glance in a dark palette. This is
// architecture: it recedes, it has a vanishing point, and it moves TOWARD you with the music,
// which is the same motion the notes have and the reason it feels like somewhere rather than
// like a backdrop.
//
// It exists because the theme called "Grid" did not have one: its whole identity lived in the
// highway's own beat grid, and `backdropOnly` switches the highway off — so on the side stages
// and behind every menu it was a dark gradient with a few stars in it, i.e. Starfield.
inline float3 rtSkyGrid(float2 uv, float aspect, float scroll, float time,
                        float3 colA, float3 colB, float amount, float horizon)
{
    float3 col = float3(0.0, 0.0, 0.0);

    // Ground: everything below the horizon, projected so z runs to infinity at it.
    float below = horizon - uv.y;
    if (below > 0.0)
    {
        float z = 0.25 / max(below, 1e-4);
        // The two scale factors are the whole difference between "a floor" and "one line down
        // the middle of the screen". At world scale 1 only a single lateral line ever crosses a
        // frame this size, and the depth lines all bunch against the horizon.
        float x = (uv.x - 0.5) * aspect * z * 6.0;
        float t = z * 2.2 - scroll * 0.10 - time * 0.22;   // rushing toward the viewer

        float lines = saturate(rtGridLine(t) + rtGridLine(x));
        float fade = exp(-z * 0.16);                       // dies out into the distance
        col += lerp(colB, colA, saturate(below * 2.2)) * lines * fade;
    }

    // Ceiling: the same plane mirrored, dimmer. Two planes is what turns a floor into a CORRIDOR,
    // and a corridor is a place; one floor is a poster of a floor.
    float above = uv.y - horizon;
    if (above > 0.0)
    {
        float z = 0.35 / max(above, 1e-4);
        float x = (uv.x - 0.5) * aspect * z * 6.0;
        float t = z * 2.2 - scroll * 0.10 - time * 0.22;

        float lines = saturate(rtGridLine(t) + rtGridLine(x));
        float fade = exp(-z * 0.16);
        col += lerp(colB, colA, saturate(above * 2.2)) * lines * fade * 0.35;
    }

    // The horizon itself — a hard bright line with a bloom off it. This is the single feature
    // that makes the whole thing read at a glance, and the one place the two planes meet.
    float dh = abs(uv.y - horizon);
    col += colA * (1.0 - smoothstep(0.0, max(fwidth(uv.y) * 1.5, 1e-5), dh)) * 1.2;
    col += colA * exp(-dh * 26.0) * 0.30;

    return col * amount * 0.9;
}

// ── compositing (premultiplied, matches Blend One OneMinusSrcAlpha) ─────────

inline void rtOver(inout float4 acc, float3 rgb, float a)
{
    a = saturate(a);
    acc.rgb = acc.rgb * (1.0 - a) + rgb * a;
    acc.a   = acc.a   * (1.0 - a) + a;
}

// Additive light: adds energy without claiming coverage (radiance/bloom look).
inline void rtAdd(inout float4 acc, float3 rgb)
{
    acc.rgb += rgb;
}

// Blend between "solid object" (over) and "pure light" (additive) compositing
// by `additive` 0..1 — the note-body radiance style axis.
inline void rtStyleComposite(inout float4 acc, float3 rgb, float a, float additive)
{
    a = saturate(a);
    float cover = a * (1.0 - additive);
    acc.rgb = acc.rgb * (1.0 - cover) + rgb * a;
    acc.a   = acc.a   * (1.0 - cover) + cover;
}

#endif // SDF_RHYTHM_TRACK_INCLUDED
