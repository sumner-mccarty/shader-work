// ============================================================================
// DecorWrap.shader — a full-faceplate finish: the vinyl wrap / paint job (Docs/Decor.md §2.2)
// ============================================================================
// One quad over the whole decor group. Everything is a function of the decor-space position P (canvas units),
// so a wrap is LAYOUT-INDEPENDENT: dock the panel somewhere else, resize it, switch its variant — the tiger
// is still a tiger and the checks are still square. _Scale is the feature size in canvas units, _Angle turns
// the pattern, _Seed re-rolls it, _Size is the group's size (gradients and flames span it).
//
// Colours: _C0 is the BACKGROUND and its alpha is the background's coverage — set it to 0 and the pattern
// sits on the bare plate (flames, racing stripes, sprinkles, polka dots on brushed metal). _C1.._C3 are the
// pattern's colours. Relief is small and per mode (carbon weave, wood grain, terrazzo chips); finish
// (gloss/metal/holo/glitter/glow) comes from _DecorMat like every item.
//
//  0 Solid            7 Zebra           14 Terrazzo        21 Wood
//  1 Linear gradient  8 Carbon fibre    15 Honeycomb       22 Brushed metal
//  2 Radial gradient  9 Flames          16 Plaid           23 Hazard stripes
//  3 Camo             10 Checker        17 Seigaiha waves  24 Splatter
//  4 Digital camo     11 Racing stripes 18 Halftone        25 Confetti
//  5 Tiger            12 Polka dots     19 Sprinkles       26 Aurora
//  6 Leopard          13 Marble         20 Stars           27 Holo foil
// ============================================================================

Shader "UI/Decor/Wrap"
{
    Properties
    {
        _Color ("Tint (a = opacity)", Color) = (1, 1, 1, 1)
        _Mode ("Pattern", Float) = 0
        _C0 ("Background (a = coverage)", Color) = (0.12, 0.12, 0.14, 1)
        _C1 ("Colour 1", Color) = (0.95, 0.55, 0.10, 1)
        _C2 ("Colour 2", Color) = (0.08, 0.06, 0.05, 1)
        _C3 ("Colour 3", Color) = (0.96, 0.91, 0.78, 1)
        _Scale ("Feature size (canvas units)", Float) = 60
        _Angle ("Angle (deg)", Float) = 0
        _Seed ("Seed", Float) = 1
        _Size ("Group size (canvas units)", Vector) = (800, 400, 0, 0)
        _DecorMat ("Finish: gloss, metal, holo, glitter", Vector) = (0.5, 0, 0, 0)
        _DecorMat2 ("Finish: emissive, thickness", Vector) = (0, 0.2, 0, 0)
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
        Cull Off ZWrite Off ZTest Always Lighting Off

        Pass
        {
            Name "Paint"
            Blend 0 One OneMinusSrcAlpha
            Blend 1 One OneMinusSrcAlpha
            Blend 2 One OneMinusSrcAlpha
            Blend 3 One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #include "CG/Core/UIDecorPaint.cginc"

            float4 _C0, _C1, _C2, _C3, _Size;
            float _Mode, _Scale, _Angle, _Seed;

            struct appdata_t { float4 vertex : POSITION; };
            struct v2f { float4 vertex : SV_POSITION; float2 P : TEXCOORD0; };

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.P = mul(unity_ObjectToWorld, v.vertex).xy;
                return o;
            }

            float2 rot(float2 p, float a) { float c = cos(a), s = sin(a); return float2(c * p.x - s * p.y, s * p.x + c * p.y); }

            // Voronoi: distance to the nearest jittered feature point, that point's id hash, and the offset.
            float3 vor(float2 q, float seed, out float2 off)
            {
                float2 c = floor(q);
                float best = 8.0; float id = 0.0; off = float2(0, 0);
                [unroll] for (int y = -1; y <= 1; y++)
                [unroll] for (int x = -1; x <= 1; x++)
                {
                    float2 g = c + float2(x, y);
                    float2 o = bdHash22(g + seed) * 0.8 + 0.1;
                    float2 d = g + o - q;
                    float dd = dot(d, d);
                    if (dd < best) { best = dd; id = bdHash21(g * 1.31 + seed); off = d; }
                }
                return float3(sqrt(best), id, 0.0);
            }

            // Layer `col` (a = coverage) over the running premultiplied result.
            void over(inout float4 acc, float3 col, float a)
            {
                a = saturate(a);
                acc.rgb = col * a + acc.rgb * (1.0 - a);
                acc.a = a + acc.a * (1.0 - a);
            }

            DecorOut frag(v2f IN)
            {
                float2 P = IN.P;
                float2 fw = fwidth(P);
                float px = max(max(fw.x, fw.y), 1e-3);                // canvas units per pixel
                float sc = max(_Scale, 1.0);
                float2 C = _Size.xy * 0.5;
                float ang = radians(_Angle);
                float2 Q = rot(P - C, -ang) / sc;                     // pattern space: one feature per unit
                float aq = px / sc;                                   // one pixel in pattern units
                float seed = _Seed * 7.31;
                float m = _Mode;

                float4 acc = float4(_C0.rgb * _C0.a, _C0.a);          // background, premultiplied
                float relief = 0.0;

                if (m < 0.5)
                {
                    acc = float4(_C0.rgb, 1.0);
                }
                else if (m < 1.5)                                     // linear gradient (C2.a > 0.5 → 3 stops)
                {
                    float2 dir = float2(cos(ang), sin(ang));
                    float ext = abs(dir.x) * _Size.x * 0.5 + abs(dir.y) * _Size.y * 0.5;
                    float t = saturate(dot(P - C, dir) / max(ext, 1.0) * 0.5 + 0.5);
                    float3 c = (_C2.a > 0.5) ? (t < 0.5 ? lerp(_C0.rgb, _C1.rgb, t * 2.0) : lerp(_C1.rgb, _C2.rgb, t * 2.0 - 1.0))
                                             : lerp(_C0.rgb, _C1.rgb, t);
                    acc = float4(c, 1.0);
                }
                else if (m < 2.5)                                     // radial gradient
                {
                    float t = saturate(length((P - C) / max(_Size.x, _Size.y)) * 2.0);
                    float3 c = (_C2.a > 0.5) ? (t < 0.5 ? lerp(_C0.rgb, _C1.rgb, t * 2.0) : lerp(_C1.rgb, _C2.rgb, t * 2.0 - 1.0))
                                             : lerp(_C0.rgb, _C1.rgb, t);
                    acc = float4(c, 1.0);
                }
                else if (m < 4.5)                                     // camo / digital camo
                {
                    float2 q = Q * 0.5;
                    if (m > 3.5) q = floor(q * 9.0) / 9.0;            // pixelated
                    float2 warp = float2(bdFbm(q * 1.3 + seed, 3.0), bdFbm(q * 1.3 + seed + 11.0, 3.0)) - 0.5;
                    float n = bdFbm(q + warp * 0.9 + seed * 0.37, 4.0);
                    float n2 = bdFbm(q * 1.7 - warp + seed * 1.9, 3.0);
                    float e = (m > 3.5) ? 0.0001 : 0.012;
                    float3 c = _C0.rgb;
                    c = lerp(c, _C1.rgb, smoothstep(0.47 - e, 0.47 + e, n));
                    c = lerp(c, _C2.rgb, smoothstep(0.58 - e, 0.58 + e, n2));
                    c = lerp(c, _C3.rgb, smoothstep(0.62 - e, 0.62 + e, n) * smoothstep(0.45, 0.47, n2));
                    acc = float4(c, 1.0);
                }
                else if (m < 5.5)                                     // tiger
                {
                    // Stripes run ACROSS the pattern's x, each a tapered brush mark: a centre line bent by
                    // a slow warp, thickness swelling in the middle and going to a point at both ends, split
                    // into segments of random length (gaps, short dashes), the odd one forked.
                    float2 q = Q * float2(1.15, 1.0);
                    float warp = (bdFbm(q * 0.2 + seed, 3.0) - 0.5) * 2.6 + sin(q.y * 0.45 + seed) * 0.35
                               + (bdFbm(q * 0.6 + seed * 3.0, 2.0) - 0.5) * 0.5;
                    float u = q.x * 0.85 + q.y * 0.12 + warp;
                    float id = floor(u + 0.5);
                    float du = u - id;                                   // -0.5..0.5 across one stripe spacing
                    float vv = q.y * (0.30 + 0.10 * bdHash21(float2(id, seed))) + bdHash21(float2(id, seed + 3.0)) * 9.0;
                    float seg = floor(vv);
                    float f = frac(vv);
                    float hs = bdHash21(float2(id * 7.0 + seg, seed + 11.0));
                    float present = step(0.16, hs);
                    float thick = (0.10 + 0.17 * bdHash21(float2(id + seg * 3.0, seed + 5.0)))
                                * pow(saturate(sin(3.14159 * pow(f, 0.75))), 0.6)
                                * (0.75 + 0.5 * bdNoise(q * 0.9 + seed * 2.0));
                    float dS = abs(du + (bdNoise(float2(vv * 2.3, id)) - 0.5) * 0.08) - thick;
                    // forks: a split down the middle of the fattest marks
                    float fork = step(0.78, hs) * smoothstep(0.25, 0.5, f) * smoothstep(0.75, 0.5, f);
                    if (fork > 0.01) dS = max(dS, -(abs(du) - thick * 0.28 * fork));
                    float e = max(fwidth(u), 1e-4) * 0.9;
                    // a mark thinner than the AA band fades out instead of leaving a hairline down its axis
                    float stripe = (1.0 - smoothstep(-e, e, dS)) * present * saturate(thick / e);
                    // a second, finer family of strokes between the main ones
                    float u2 = u + 0.5;
                    float id2 = floor(u2 + 0.5);
                    float du2 = u2 - id2;
                    float v2 = q.y * 0.55 + bdHash21(float2(id2, seed + 41.0)) * 7.0;
                    float f2 = frac(v2);
                    float th2 = 0.075 * pow(saturate(sin(3.14159 * f2)), 0.7) * step(0.62, bdHash21(float2(id2, floor(v2) + seed)));
                    stripe = max(stripe, (1.0 - smoothstep(-e, e, abs(du2) - th2)) * saturate(th2 / e));
                    float3 base = lerp(_C0.rgb, _C3.rgb, smoothstep(0.58, 0.82, bdFbm(Q * 0.16 + seed * 5.0, 3.0)));
                    float fur = bdNoise(float2(Q.x * 1.5, Q.y * 9.0) + seed);   // streaks along the coat
                    base *= 0.90 + 0.16 * fur;
                    acc = float4(lerp(base, _C2.rgb, stripe), 1.0);
                    relief = 0.1 * fur;
                }
                else if (m < 6.5)                                     // leopard
                {
                    float2 q = Q * 1.2;
                    float2 off;
                    float3 v = vor(q + (bdFbm(q * 0.8 + seed, 2.0) - 0.5) * 0.4, seed, off);
                    float d = v.x;
                    float a = atan2(off.y, off.x);
                    float gaps = smoothstep(0.35, 0.55, bdNoise(float2(a * 1.6, v.y * 30.0) + seed));
                    float rIn = 0.17 + 0.05 * v.y, rOut = rIn + 0.13;
                    float ring = smoothstep(rIn - 0.02, rIn, d) * (1.0 - smoothstep(rOut, rOut + 0.02, d)) * gaps;
                    float centre = 1.0 - smoothstep(rIn - 0.03, rIn, d);
                    float3 c = _C0.rgb * (0.92 + 0.14 * bdFbm(Q * 2.0 + seed, 3.0));
                    c = lerp(c, _C3.rgb, centre * 0.85);
                    c = lerp(c, _C2.rgb, ring);
                    float spot = 1.0 - smoothstep(0.06, 0.08, length(frac(q * 1.9 + 0.31) - 0.5 + (bdHash22(floor(q * 1.9)) - 0.5) * 0.4));
                    c = lerp(c, _C2.rgb, spot * step(0.7, bdHash21(floor(q * 1.9) + seed)) * (1.0 - ring));
                    acc = float4(c, 1.0);
                }
                else if (m < 7.5)                                     // zebra
                {
                    float warp = (bdFbm(Q * float2(0.4, 0.8) + seed, 3.0) - 0.5) * 1.8;
                    float band = abs(frac(Q.x * 0.6 + warp) - 0.5) * 2.0;
                    float wdt = 0.45 + 0.15 * bdNoise(Q * 0.5 + seed * 2.0);
                    float e = max(fwidth(band), 1e-4) * 0.8;
                    float stripe = smoothstep(wdt - e, wdt + e, band);
                    acc = float4(lerp(_C0.rgb, _C2.rgb, stripe), 1.0);
                }
                else if (m < 8.5)                                     // carbon fibre (2x2 twill)
                {
                    float2 q = Q * 6.0;
                    float2 cell = floor(q);
                    float2 f = frac(q);
                    float k = fmod(cell.x + cell.y * 1.0 + 64.0, 4.0);
                    float horiz = step(k, 1.5);
                    float along = horiz > 0.5 ? f.y : f.x;
                    float across = horiz > 0.5 ? f.x : f.y;
                    float tow = sin(along * 3.14159);
                    float fib = 0.85 + 0.15 * sin(across * 60.0 + bdHash21(cell) * 6.0);
                    float lum = 0.35 + 0.65 * tow * fib;
                    float3 c = lerp(_C0.rgb, _C1.rgb, lum * (horiz > 0.5 ? 0.85 : 1.0));
                    acc = float4(c, 1.0);
                    relief = 0.25 * tow;
                }
                else if (m < 9.5)                                     // flames (hot-rod), licking up and back
                {
                    // Tongues rise from the bottom edge of the group and sweep sideways as they climb, each a
                    // tapered, slightly bellied stroke with a curl at the tip; a solid band joins their roots.
                    // Sized by _Scale (canvas units), not by the panel, so a short strip and a tall rack get the
                    // same flames, just more or fewer of them. Pinstripe outline in a darkened tip colour.
                    float2 u = rot(P - C, -ang) + C;
                    float y = u.y;
                    float spacing = sc * 0.62;
                    float dmin = 1e4;
                    float cell = floor(u.x / spacing);
                    [unroll] for (int k = -3; k <= 1; k++)
                    {
                        float id = cell + k;
                        float r1 = bdHash21(float2(id, seed));
                        float r2 = bdHash21(float2(id, seed + 7.0));
                        float r3 = bdHash21(float2(id, seed + 13.0));
                        float h = sc * (1.0 + 1.7 * r1);
                        float bx = (id + 0.5) * spacing;
                        float t = saturate(y / h);
                        float sweep = h * (0.42 + 0.25 * r2);
                        float xc = bx + sweep * pow(t, 1.5) + sin(t * 5.5 + r3 * 6.28) * sc * 0.06 * t;
                        xc -= sc * 0.22 * smoothstep(0.72, 1.0, t) * (0.5 + r3);       // the tip curls back
                        float wdt = spacing * (0.62 + 0.25 * r3) * pow(1.0 - t, 0.75) * (1.0 + 0.35 * sin(t * 3.14159));
                        float d = abs(u.x - xc) - wdt * 0.5;
                        // past the tip: distance to the tip point, so the field stays continuous (a hard cut
                        // there put a hairline across the top of every tongue through fwidth)
                        float xt = bx + sweep + sin(5.5 + r3 * 6.28) * sc * 0.06 - sc * 0.22 * (0.5 + r3);
                        d = (y > h) ? length(float2(u.x - xt, y - h)) : d;
                        dmin = min(dmin, d);
                    }
                    float root = y - sc * 0.32;                           // the solid band the tongues grow out of
                    dmin = min(dmin, root);
                    float ey = max(fwidth(dmin), 1e-3);
                    float inside = 1.0 - smoothstep(-ey, ey, dmin);
                    float tg = saturate(y / (sc * 2.4));
                    float3 fc = tg < 0.45 ? lerp(_C1.rgb, _C2.rgb, tg / 0.45) : lerp(_C2.rgb, _C3.rgb, (tg - 0.45) / 0.55);
                    float pin = 1.0 - smoothstep(ey * 0.6, ey * 1.8, abs(dmin + ey * 1.6));
                    over(acc, fc, inside);
                    over(acc, _C3.rgb * 0.45, pin * inside);
                    relief = inside * 0.35;
                }
                else if (m < 10.5)                                    // checker
                {
                    // Per-axis square waves with a one-pixel ramp: the product of two signed waves IS the
                    // checker, and each ramp anti-aliases its own edge (the product of offsets blurred them).
                    float e = max(aq, 1e-4) * 1.2;
                    float wx = clamp((0.25 - abs(frac(Q.x * 0.5 + 0.25) - 0.5)) / e, -1.0, 1.0);
                    float wy = clamp((0.25 - abs(frac(Q.y * 0.5 + 0.25) - 0.5)) / e, -1.0, 1.0);
                    acc = float4(lerp(_C2.rgb, _C1.rgb, 0.5 + 0.5 * wx * wy), 1.0);
                }
                else if (m < 11.5)                                    // racing stripes: two bars + pinstripes
                {
                    float y = abs(Q.y);
                    float e = aq;
                    float bar = smoothstep(0.18 - e, 0.18 + e, y) * (1.0 - smoothstep(0.88 - e, 0.88 + e, y));
                    float pin = (1.0 - smoothstep(0.05, 0.05 + e * 1.5, abs(y - 1.0))) + (1.0 - smoothstep(0.05, 0.05 + e * 1.5, abs(y - 0.06)));
                    over(acc, _C1.rgb, bar);
                    over(acc, _C2.rgb, saturate(pin));
                    relief = bar * 0.15;
                }
                else if (m < 12.5)                                    // polka dots (staggered)
                {
                    float2 q = Q;
                    q.x += step(1.0, fmod(floor(q.y) + 64.0, 2.0)) * 0.5;
                    float d = length(frac(q) - 0.5);
                    float dot_ = 1.0 - smoothstep(0.28 - aq, 0.28 + aq, d);
                    over(acc, _C1.rgb, dot_);
                    relief = dot_ * 0.3;
                }
                else if (m < 13.5)                                    // marble
                {
                    float2 q = Q * 0.6;
                    float w = bdFbm(q * 0.8 + seed, 4.0) * 6.0;
                    float v = abs(sin(q.x * 1.2 + q.y * 0.4 + w));
                    float vein = pow(saturate(1.0 - v), 14.0);
                    float vein2 = pow(saturate(1.0 - abs(sin(q.x * 3.1 - q.y * 1.3 + w * 1.7))), 30.0) * 0.6;
                    float3 c = lerp(_C0.rgb, _C1.rgb, bdFbm(q * 1.4 + seed * 2.0, 3.0));
                    c = lerp(c, _C2.rgb, saturate(vein + vein2));
                    acc = float4(c, 1.0);
                }
                else if (m < 14.5)                                    // terrazzo
                {
                    float2 q = Q * 2.0;
                    float2 off;
                    float3 v = vor(q, seed, off);
                    float a = atan2(off.y, off.x);
                    float r = 0.12 + 0.24 * bdHash21(float2(v.y, 3.0)) + 0.05 * sin(a * 3.0 + v.y * 40.0) + 0.04 * sin(a * 5.0 + v.y * 9.0);
                    float chip = (1.0 - smoothstep(r - aq * 2.0, r + aq * 2.0, v.x)) * step(0.3, v.y);
                    float3 cc = v.y < 0.53 ? _C1.rgb : (v.y < 0.76 ? _C2.rgb : _C3.rgb);
                    float3 c = _C0.rgb * (0.95 + 0.1 * bdNoise(Q * 9.0 + seed));
                    c = lerp(c, cc, chip);
                    acc = float4(c, 1.0);
                    relief = chip * 0.12;
                }
                else if (m < 15.5)                                    // honeycomb
                {
                    float2 q = Q * float2(1.0, 1.1547);
                    float2 r = float2(1.0, 1.7320508);
                    float2 h = r * 0.5;
                    float2 a = fmod(q + 64.0 * r, r) - h;
                    float2 b = fmod(q - h + 64.0 * r, r) - h;
                    float2 g = dot(a, a) < dot(b, b) ? a : b;
                    float2 ag = abs(g);
                    float edge = 0.5 - max(dot(ag, normalize(float2(1.0, 1.7320508))), ag.x);
                    float line_ = 1.0 - smoothstep(0.035, 0.035 + aq * 1.5, edge);
                    float3 c = _C0.rgb * (0.9 + 0.2 * bdHash21(floor(q * 2.0) + seed));
                    acc = float4(c * _C0.a, _C0.a);
                    over(acc, _C1.rgb, line_);
                    relief = line_ * 0.3;
                }
                else if (m < 16.5)                                    // plaid / tartan
                {
                    float2 q = Q;
                    float bx = step(0.62, frac(q.x * 0.5)) + 0.6 * step(0.92, frac(q.x * 0.5 + 0.3));
                    float by = step(0.62, frac(q.y * 0.5)) + 0.6 * step(0.92, frac(q.y * 0.5 + 0.3));
                    float thin = step(0.96, frac(q.x * 2.0)) + step(0.96, frac(q.y * 2.0));
                    float twill = step(0.5, frac((q.x + q.y) * 8.0));
                    float3 cx = lerp(_C0.rgb, _C1.rgb, saturate(bx));
                    float3 cy = lerp(_C0.rgb, _C2.rgb, saturate(by));
                    float3 c = lerp(cx, cy, 0.5 + 0.25 * (twill - 0.5));
                    c = lerp(c, _C3.rgb, saturate(thin) * 0.8);
                    acc = float4(c, 1.0);
                }
                else if (m < 17.5)                                    // seigaiha waves
                {
                    float2 q = Q * float2(1.0, 2.0);
                    float row = floor(q.y);
                    float2 f = float2(frac(q.x + step(1.0, fmod(row + 64.0, 2.0)) * 0.5), frac(q.y));
                    float lines = 0.0;
                    [unroll] for (int k = 0; k < 3; k++)
                    {
                        float2 d2 = (f - float2(0.5 + (k - 1) * 0.5, 0.0)) * float2(1.0, 0.5);
                        float rr = length(d2);
                        float ring = abs(frac(rr * 5.0) - 0.5);
                        lines = max(lines, (1.0 - smoothstep(0.08, 0.08 + aq * 6.0, ring)) * step(rr, 0.5));
                    }
                    over(acc, _C1.rgb, lines);
                }
                else if (m < 18.5)                                    // halftone dots, size from a gradient
                {
                    float2 dir = float2(cos(ang), sin(ang));
                    float ext = abs(dir.x) * _Size.x * 0.5 + abs(dir.y) * _Size.y * 0.5;
                    float t = saturate(dot(P - C, dir) / max(ext, 1.0) * 0.5 + 0.5);
                    float2 q = rot(P - C, radians(45.0)) / (sc * 0.25);
                    float d = length(frac(q) - 0.5);
                    float rad = 0.62 * sqrt(t);
                    float dot_ = 1.0 - smoothstep(rad - aq * 4.0, rad + aq * 4.0, d);
                    over(acc, _C1.rgb, dot_);
                }
                else if (m < 19.5)                                    // sprinkles
                {
                    float2 q = Q * 1.1;
                    float2 cell = floor(q);
                    float sum = 0.0; float3 sc_ = _C1.rgb;
                    [unroll] for (int y = -1; y <= 1; y++)
                    [unroll] for (int x = -1; x <= 1; x++)
                    {
                        float2 g = cell + float2(x, y);
                        float h = bdHash21(g + seed);
                        float2 o = bdHash22(g * 1.7 + seed) * 0.8 + 0.1;
                        float aa = bdHash21(g * 2.3 + seed) * 6.2832;
                        float2 pp = rot(q - (g + o), aa);
                        float d = length(float2(max(abs(pp.x) - 0.17, 0.0), pp.y)) - 0.065;
                        float k = (1.0 - smoothstep(-aq * 2.5, aq * 2.5, d)) * step(0.25, h);
                        float3 cc = h < 0.45 ? _C1.rgb : (h < 0.65 ? _C2.rgb : (h < 0.85 ? _C3.rgb : float3(1, 1, 1)));
                        sc_ = lerp(sc_, cc, k);
                        sum = max(sum, k);
                    }
                    over(acc, sc_, sum);
                    relief = sum * 0.6;
                }
                else if (m < 20.5)                                    // stars
                {
                    float2 q = Q * 3.0;
                    float2 cell = floor(q);
                    float h = bdHash21(cell + seed);
                    float2 o = bdHash22(cell * 1.3 + seed) * 0.7 + 0.15;
                    float2 d = q - cell - o;
                    float r = length(d);
                    float size = 0.03 + 0.07 * pow(bdHash21(cell * 3.1 + seed), 4.0);
                    float core = 1.0 - smoothstep(size * 0.5, size, r);
                    float spike = max(1.0 - smoothstep(0.0, aq * 3.0 + 0.008, abs(d.x)), 1.0 - smoothstep(0.0, aq * 3.0 + 0.008, abs(d.y)))
                                * (1.0 - smoothstep(0.0, size * 4.0, r)) * step(0.93, h);
                    float st = saturate(core + spike * 0.8) * step(0.35, h);
                    float3 sky = lerp(_C0.rgb, _C1.rgb, bdFbm(Q * 0.25 + seed, 3.0) * 0.8);
                    acc = float4(sky * _C0.a, _C0.a);
                    over(acc, lerp(_C2.rgb, _C3.rgb, bdHash21(cell * 7.0)), st);
                }
                else if (m < 21.5)                                    // wood
                {
                    float2 q = Q * float2(0.25, 2.5);
                    float w = bdFbm(q * float2(0.6, 0.25) + seed, 4.0) * 3.0;
                    float ring = frac(q.y * 0.7 + w);
                    float late = smoothstep(0.55, 0.95, ring);
                    float fibre = bdNoise(float2(Q.x * 0.5, Q.y * 40.0) + seed);
                    float3 c = lerp(_C0.rgb, _C1.rgb, late);
                    c *= 0.9 + 0.2 * fibre;
                    acc = float4(c, 1.0);
                    relief = 0.12 * (late + fibre * 0.5);
                }
                else if (m < 22.5)                                    // brushed metal
                {
                    float n = bdNoise(float2(Q.x * 0.6, Q.y * 55.0) + seed) * 0.6 + bdNoise(float2(Q.x * 2.0, Q.y * 160.0) + seed * 2.0) * 0.4;
                    float3 c = _C0.rgb * (0.86 + 0.24 * n);
                    acc = float4(c, 1.0);
                    relief = 0.05 * n;
                }
                else if (m < 23.5)                                    // hazard stripes
                {
                    float v = frac((Q.x + Q.y) * 0.5);
                    float e = aq;
                    float t = smoothstep(0.5 - e, 0.5 + e, v) * (1.0 - smoothstep(1.0 - e, 1.0, v));
                    acc = float4(lerp(_C1.rgb, _C2.rgb, t), 1.0);
                }
                else if (m < 24.5)                                    // splatter (three colours flung in layers)
                {
                    [unroll] for (int k = 0; k < 3; k++)
                    {
                        float fk = (float)k;
                        float2 q = Q * (0.9 + fk * 0.35) + seed * (fk + 2.0);
                        float blob = bdFbm(q, 4.0);
                        float t = 0.66 + fk * 0.015;
                        float cov = smoothstep(t - 0.01, t + 0.01, blob);
                        float drops = 1.0 - smoothstep(0.08, 0.1, length(frac(q * 3.0) - 0.5 + (bdHash22(floor(q * 3.0)) - 0.5) * 0.5));
                        drops *= step(0.86, bdHash21(floor(q * 3.0) + fk));
                        float3 cc = k == 0 ? _C1.rgb : (k == 1 ? _C2.rgb : _C3.rgb);
                        over(acc, cc, max(cov, drops));
                        relief = max(relief, max(cov, drops) * 0.5);
                    }
                }
                else if (m < 25.5)                                    // confetti
                {
                    float2 q = Q * 0.9;
                    float2 cell = floor(q);
                    float sum = 0.0; float3 cc = _C1.rgb;
                    [unroll] for (int y = -1; y <= 1; y++)
                    [unroll] for (int x = -1; x <= 1; x++)
                    {
                        float2 g = cell + float2(x, y);
                        float h = bdHash21(g + seed);
                        float2 o = bdHash22(g * 1.9 + seed) * 0.8 + 0.1;
                        float2 pp = rot(q - (g + o), h * 9.0);
                        float sq = max(abs(pp.x) - 0.11, abs(pp.y) - 0.06);
                        float ci = length(pp) - 0.08;
                        float d = h < 0.5 ? sq : ci;
                        float k = (1.0 - smoothstep(-aq * 2.0, aq * 2.0, d)) * step(0.2, h);
                        float3 col = frac(h * 7.0) < 0.33 ? _C1.rgb : (frac(h * 7.0) < 0.66 ? _C2.rgb : _C3.rgb);
                        cc = lerp(cc, col, k);
                        sum = max(sum, k);
                    }
                    over(acc, cc, sum);
                    relief = sum * 0.2;
                }
                else if (m < 26.5)                                    // aurora: four colours blended by slow fields
                {
                    float2 q = Q * 0.35;
                    float a1 = bdFbm(q + seed, 3.0), a2 = bdFbm(q * 1.3 + seed + 7.0, 3.0), a3 = bdFbm(q * 0.8 - seed, 3.0);
                    float3 c = _C0.rgb;
                    c = lerp(c, _C1.rgb, smoothstep(0.35, 0.7, a1));
                    c = lerp(c, _C2.rgb, smoothstep(0.45, 0.75, a2));
                    c = lerp(c, _C3.rgb, smoothstep(0.55, 0.8, a3) * 0.8);
                    acc = float4(c, 1.0);
                }
                else                                                  // holo foil base (pair with the holo finish)
                {
                    float lines = 0.5 + 0.5 * sin((Q.x * 0.7 + Q.y * 0.4) * 18.0 + bdFbm(Q * 0.6 + seed, 3.0) * 6.0);
                    float3 c = lerp(_C0.rgb, _C1.rgb, lines * 0.35);
                    acc = float4(c, 1.0);
                    relief = 0.05 * lines;
                }

                float a = acc.a;
                float3 rgb = acc.rgb / max(a, 1e-4);
                return DecorEmit(rgb * _Color.rgb, a * _Color.a, relief + 0.25, 1.0);
            }
            ENDCG
        }
    }
}
