// ============================================================================
// DecorStroke.shader — every freehand tool of PAINT mode (Docs/Decor.md §2.2, §4)
// ============================================================================
// Draws ONE stroke into a panel's four decor targets (UIDecorPaint.cginc). The geometry is a RIBBON built by
// DecorStrokeMesh.cs along the user's resampled pointer path, so a stroke can be any length (the 6-point
// UI/Decal/* generators cannot). Per vertex:
//   TEXCOORD0 = (s, l, w, pressure)   s = arc length in canvas units (negative behind the first point,
//                                     > L past the last: the caps), l = lateral offset in units of the core
//                                     half-width w (the ribbon reaches |l| = ext), pressure 0..1
//   TEXCOORD1 = (L, ext, mode, unused) L = stroke length, ext = ribbon half-extent in core widths,
//                                     mode 0 = ribbon, 1 = a DRIP quad (DecorStrokeMesh.Drips) whose
//                                     TEXCOORD0 is (x, y-down, top half-width, run length) in canvas units.
// Position is decor space (canvas units, y up); the C# side sets an orthographic projection over the panel.
//
// _Kind picks the tool. Each decides coverage, tone and RELIEF (thickness → the plate's lighting shades it);
// gloss / metal / holo / glitter / glow come from the finish (_DecorMat, _DecorMat2) and are not decided here.
//   0 Brush   loaded bristles, streaks, dry-brush break-up toward the tail, ridges of piled paint
//   1 Marker  flat translucent ink, pooled darker at the edges, faint streaks, overlaps darken
//   2 Spray   Gaussian core, stippled falloff, overspray droplets out to the ribbon's reach
//   3 Chalk   broken coverage on paper tooth, pressure fills it in, pastel and matte
//   4 Pen     crisp ink line
//   5 Neon    glass tube: white-hot core, coloured body, glow spill onto the plate (emissive)
//   6 Tape    strip with torn ends, fibres, darker edges, optional printed pattern (_Pattern, _Color2)
//   7 Stripe  sign-writer's pinstripe: a raised enamel bead
//   8 Drip    wet marker whose paint runs: drip quads hang under the stroke
//   9 Gel     glitter-glue bead: tall round profile (pair with the glitter finish)
// Pass 1 ERASES (same geometry, Blend Zero OneMinusSrcAlpha) — the Eraser tool.
// Derivatives are taken once, at the top of the fragment, outside every branch.
// ============================================================================

Shader "UI/Decor/Stroke"
{
    Properties
    {
        _Color ("Paint (a = opacity)", Color) = (0.95, 0.12, 0.38, 1)
        _Color2 ("Second colour (tape print)", Color) = (1, 1, 1, 1)
        _Kind ("Kind (see header)", Float) = 0
        _Seed ("Seed", Float) = 1
        _Hardness ("Edge hardness (spray core / eraser)", Range(0, 1)) = 0.5
        _Pattern ("Tape print (0 plain, 1 stripes, 2 dots, 3 checks)", Float) = 0
        _DecorMat ("Finish: gloss, metal, holo, glitter", Vector) = (0.4, 0, 0, 0)
        _DecorMat2 ("Finish: emissive, thickness", Vector) = (0, 0.3, 0, 0)
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
        Cull Off ZWrite Off ZTest Always Lighting Off

        CGINCLUDE
        #include "CG/Core/UIDecorPaint.cginc"

        float4 _Color2;
        float _Kind, _Seed, _Hardness, _Pattern;

        struct appdata
        {
            float4 vertex : POSITION;
            float4 a : TEXCOORD0;
            float4 b : TEXCOORD1;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float4 a : TEXCOORD0;
            float4 b : TEXCOORD1;
            float2 P : TEXCOORD2;     // decor space (canvas units)
        };

        v2f vert(appdata v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.a = v.a;
            o.b = v.b;
            o.P = mul(unity_ObjectToWorld, v.vertex).xy;
            return o;
        }

        // Round-capped radial metric in core half-widths: |l| along the body, distance from the end point past
        // either end (the ribbon is extended by ext * w at both ends for the caps).
        float strokeR(float s, float l, float w, float L)
        {
            float sc = (s < 0.0) ? s : ((s > L) ? s - L : 0.0);
            return length(float2(sc / max(w, 1e-3), l));
        }

        // Overspray / glitter droplets on a grid of `cell` canvas units: one candidate dot per cell.
        float sprayDots(float2 P, float cell, float density, float radius, float seed, float px)
        {
            float2 g = P / cell;
            float2 c = floor(g);
            float2 o = bdHash22(c + seed) * 0.6 + 0.2;
            float rr = radius * (0.5 + bdHash21(c * 1.7 + seed));
            float d = length(g - c - o) * cell;
            float on = step(1.0 - density, bdHash21(c * 1.31 + seed + 5.0));
            return on * (1.0 - smoothstep(rr - px * 0.6, rr + px * 0.6, d));
        }

        // Shape coverage + tone + relief for every kind. Returns coverage in `cov` (before item opacity).
        void strokeShade(v2f i, float px, float aaR, out float3 col, out float cov, out float relief,
                         out float glowA)
        {
            float s = i.a.x, l = i.a.y, w = max(i.a.z, 1e-3), pres = saturate(i.a.w);
            float L = i.b.x, ext = i.b.y;
            float2 P = i.P;
            float r = strokeR(s, l, w, L);
            float sn = saturate(s / max(L, 1e-3));
            col = _Color.rgb;
            cov = 0.0;
            relief = 0.0;
            glowA = 0.0;
            float hard = 1.0 - smoothstep(1.0 - aaR, 1.0 + aaR, r);

            if (_Kind < 0.5)                                    // ---- 0 BRUSH ----
            {
                // Strands at least ~3 px wide: 22 strands across a 24-unit stroke were sub-pixel and shimmered
                // as hatching under the lamps.
                float N = clamp(floor(2.0 * w / (3.0 * px)), 5.0, 26.0);
                float u = saturate(l * 0.5 + 0.5);
                float along = s / (2.0 * w) / 4.0;
                float sid = min(floor(u * N), N - 1.0);
                float base = bdHash21(float2(sid, _Seed * 3.7 + 1.0));
                float wander = bdNoise(float2(sid * 3.13 + _Seed * 5.0, along));
                float load = lerp(base, wander, 0.55);
                float longStroke = smoothstep(3.0, 8.0, L / w);
                float dry = 0.6 * smoothstep(0.45, 1.0, sn) * longStroke;
                float edgeBias = pow(abs(l), 3.0) * 0.22 * smoothstep(0.2, 1.0, sn) * longStroke;
                float thresh = dry * 0.92 + edgeBias;
                float strand = smoothstep(thresh, thresh + 0.1, load + 0.05);
                float endAt = L - (0.02 + dry * 0.12) * L * bdHash21(float2(sid, _Seed + 21.0));
                strand *= lerp(1.0, 1.0 - smoothstep(endAt - 0.6 * w, endAt, s), longStroke);
                float rag = (bdHash21(float2(sid, _Seed + 9.0)) - 0.5) * 2.0;
                float outer = step(0.8, abs(l)) * step(0.0, s);
                float lim = 1.0 + 0.45 * (0.16 * rag * outer + 0.1 * (bdNoise(float2(along * 6.0 + sign(l) * 17.0, _Seed)) - 0.5));
                float shape = 1.0 - smoothstep(lim - aaR, lim + aaR, r);
                cov = shape * strand;
                float fu = frac(u * N);
                float groove = 1.0 - smoothstep(0.0, 0.16, min(fu, 1.0 - fu));
                float tone = (base - 0.5) * 0.5 + (wander - 0.5);
                col *= 1.0 + tone * 0.22;
                col *= 1.0 - 0.10 * groove;
                float ridge = smoothstep(0.78, 0.98, r) * (1.0 - smoothstep(0.98, 1.1, r));
                col = lerp(col, lerp(col, float3(1, 1, 1), 0.18), 0.4 * ridge);
                cov *= lerp(1.0, 0.82 + 0.18 * load, dry);
                relief = 0.6 + 0.3 * load - 0.18 * groove + 0.5 * ridge;
            }
            else if (_Kind < 1.5)                               // ---- 1 MARKER ----
            {
                float streak = bdNoise(float2(l * 9.0 + _Seed, s / (w * 6.0)));
                col *= 1.0 - 0.18 * smoothstep(0.62, 1.0, r);
                col *= 0.97 + 0.06 * streak;
                cov = hard * 0.88;
                relief = 0.25;
            }
            else if (_Kind < 2.5)                               // ---- 2 SPRAY ----
            {
                float k = lerp(1.6, 7.0, _Hardness);
                float dens = exp(-r * r * k);
                float flow = 3.2 * lerp(0.55, 1.0, pres);
                float core = 1.0 - exp(-flow * dens);
                float rnd = 0.6 * bdNoise(P * 0.85 + _Seed * 7.1) + 0.4 * bdHash21(floor(P * 0.7) + _Seed);
                float stip = smoothstep(rnd - 0.12, rnd + 0.12, core);
                cov = lerp(core, stip, 0.72 * (1.0 - smoothstep(0.55, 0.98, core)));
                float far = max(r - 0.6, 0.0) / max(ext * 0.55, 0.1);
                float fade = exp(-far * far * 2.2) * 0.55;
                float fine = sprayDots(P, 3.2, fade * 0.6, 0.55, _Seed, px);
                float big = sprayDots(P, 8.5, fade * 0.25, 1.1, _Seed + 41.0, px);
                cov = max(cov, max(fine, big));
                relief = 0.12;
            }
            else if (_Kind < 3.5)                               // ---- 3 CHALK ----
            {
                float wob = (bdNoise(P * 0.45 + _Seed) - 0.5) * 0.35;
                float shape = 1.0 - smoothstep(0.82, 1.04, r + wob);
                float fibre = bdNoise(float2(s * 0.22, l * 3.2) + _Seed * 3.0);
                float tooth = bdHash21(floor(P * 1.15) + _Seed);
                float grain = fibre * 0.55 + tooth * 0.45;
                float t = 0.42 - pres * 0.22;
                cov = shape * smoothstep(t, t + 0.16, grain);
                col = lerp(col, float3(1, 1, 1), 0.10);
                relief = 0.18 * grain;
            }
            else if (_Kind < 4.5)                               // ---- 4 PEN ----
            {
                cov = hard;
                relief = 0.12;
            }
            else if (_Kind < 5.5)                               // ---- 5 NEON ----
            {
                float hot = 1.0 - smoothstep(0.12, 0.6, r);
                col = lerp(col, lerp(col, float3(1, 1, 1), 0.9), hot);
                cov = hard;
                relief = sqrt(saturate(1.0 - r * r));
                float spill = exp(-max(r - 1.0, 0.0) * 1.35) * (1.0 - hard);
                spill *= 1.0 - smoothstep(ext * 0.85, ext, r);
                glowA = spill * 0.5;
            }
            else if (_Kind < 6.5)                               // ---- 6 TAPE ----
            {
                float jagA = (bdHash21(float2(floor(l * 6.0 + 7.0), _Seed)) * 0.6 + bdNoise(float2(l * 11.0, _Seed)) * 0.4) * w * 0.6;
                float jagB = (bdHash21(float2(floor(l * 6.0 + 3.0), _Seed + 5.0)) * 0.6 + bdNoise(float2(l * 11.0, _Seed + 9.0)) * 0.4) * w * 0.6;
                float ends = smoothstep(-px, px, s - jagA) * smoothstep(-px, px, (L - s) - jagB);
                float side = 1.0 - smoothstep(1.0 - aaR, 1.0 + aaR, abs(l));
                float fibre = bdNoise(float2(s * 0.09, l * 15.0) + _Seed);
                col *= 0.95 + 0.08 * fibre;
                col *= 1.0 - 0.10 * smoothstep(0.86, 1.0, abs(l));
                if (_Pattern > 0.5)
                {
                    float m;
                    if (_Pattern < 1.5) m = step(0.5, frac(s / (w * 1.4) + l * 0.35));                        // stripes
                    else if (_Pattern < 2.5) { float2 g = float2(s / (w * 0.9), l * 1.1); float2 f = frac(g) - 0.5; m = step(length(f), 0.26); }  // dots
                    else m = step(0.5, frac(floor(s / (w * 0.8)) * 0.5 + floor(l * 1.0 + 1.0) * 0.5));    // checks
                    col = lerp(col, _Color2.rgb, m);
                }
                cov = side * ends * 0.94;
                relief = 1.0;
            }
            else if (_Kind < 7.5)                               // ---- 7 PINSTRIPE ----
            {
                cov = hard;
                relief = 0.35 + 0.65 * sqrt(saturate(1.0 - r * r));
            }
            else if (_Kind < 8.5)                               // ---- 8 DRIP (the stroke part) ----
            {
                col *= 1.0 - 0.10 * smoothstep(0.6, 1.0, r);
                cov = hard;
                relief = 0.55 + 0.35 * sqrt(saturate(1.0 - r * r));
            }
            else                                                 // ---- 9 GEL ----
            {
                cov = hard * 0.96;
                relief = sqrt(saturate(1.0 - r * r)) * 1.2;
            }
        }
        ENDCG

        // ---- Pass 0: paint ---------------------------------------------------------------------------------
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

            DecorOut frag(v2f i)
            {
                float2 fw = fwidth(i.P);
                float px = max(max(fw.x, fw.y), 1e-3);                // one pixel in canvas units
                float aaR = max(px / max(i.a.z, 1e-3), 1e-3);          // one pixel in core half-widths

                if (i.b.z > 0.5)
                {
                    // DRIP quad: a run hanging from the stroke, tapered, ending in a bulb.
                    float2 p = float2(i.a.x, -i.a.y);
                    float w0 = max(i.a.z, 0.3), len = max(i.a.w, 0.5);
                    float bulbR = w0 * 1.35;
                    float d = dpTaper(p, float2(0, w0), float2(0, -len + bulbR), w0, w0 * 0.72);
                    d = dpSmin(d, length(p - float2(0, -len + bulbR * 0.85)) - bulbR, w0 * 0.6);
                    float cov = 1.0 - smoothstep(-px * 0.7, px * 0.7, d);
                    float inside = saturate(-d / max(w0, 1e-3));
                    float3 col = _Color.rgb * (1.0 - 0.08 * (1.0 - inside));
                    return DecorEmit(col, cov * _Color.a, 0.6 + 0.5 * inside, 1.0);
                }

                float3 col; float cov, relief, glowA;
                strokeShade(i, px, aaR, col, cov, relief, glowA);
                DecorOut o = DecorEmit(col, cov * _Color.a, relief, 1.0);
                if (glowA > 0.0)
                {
                    // Neon spill: colour + emission only, under the tube's own coverage.
                    float ga = glowA * _Color.a * (1.0 - o.albedo.a);
                    o.albedo += float4(_Color.rgb * ga, ga);
                    o.fx += float4(0.0, saturate(_DecorMat2.x) * ga, 0.0, ga);
                }
                return o;
            }
            ENDCG
        }

        // ---- Pass 1: erase ---------------------------------------------------------------------------------
        Pass
        {
            Name "Erase"
            Blend Zero OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragErase
            #pragma target 3.5

            DecorOut fragErase(v2f i)
            {
                float2 fw = fwidth(i.P);
                float px = max(max(fw.x, fw.y), 1e-3);
                float w = max(i.a.z, 1e-3);
                float r = strokeR(i.a.x, i.a.y, w, i.b.x);
                float soft = lerp(0.45, 0.02, _Hardness);
                float aaR = px / w;
                float cov = 1.0 - smoothstep(1.0 - soft - aaR, 1.0 + aaR, r);
                return DecorErase(cov * _Color.a);
            }
            ENDCG
        }
    }
}
