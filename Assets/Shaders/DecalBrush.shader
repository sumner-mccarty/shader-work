// ============================================================================
// DecalBrush.shader — brush stroke (generator for the paint layer, Docs/UiDecals.md §3.1)
// ============================================================================
// Draws ONE stroke into a transparent quad: uv 0..1 = the decoration's bounds (v up, draw it into a square quad).
// Output is PREMULTIPLIED rgba (rgb * a, a = coverage), Blend One OneMinusSrcAlpha. Seeded and deterministic
// (bdHash* from UIBackdropFlow.cginc).
//
// THE STROKE. Same point scheme as DecalSpray (CG/Core/UIDecalStroke.cginc): up to six points _P0.._P5
// (float4: x, y, pressure, unused; uv 0..1) and _PointCount on a Catmull-Rom spline. Pressure sets the ribbon
// width; the stroke is a ribbon, so the shader also gets the SIGNED lateral coordinate l (-1..1 across it).
//
// WHAT MAKES IT A BRUSH.
//   * BRISTLES: the ribbon is cut into _Bristles strands across its width. Each strand carries its own paint
//     load, wandering slowly along the stroke, so you see long streaks that part and rejoin — and each strand
//     is a touch lighter/darker, with a faint groove between strands.
//   * DRY BRUSH: the load runs out toward the tail. From _DryStart on, strands whose load is below a rising
//     threshold go empty (edge strands first), so the stroke breaks into separate streaks and ragged tips.
//   * a loaded START (heavier, rounder), a ragged edge (outer strands differ in length), and a thin ridge of
//     piled-up paint along both edges.
// ============================================================================

Shader "UI/Decal/Brush"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Paint colour (alpha = overall opacity)", Color) = (0.95, 0.12, 0.38, 1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Seed)]
        _Seed ("Seed", Float) = 1

        [Header(Stroke points  x y pressure unused)]
        _PointCount ("Point count (1..6)", Range(1, 6)) = 4
        _P0 ("P0", Vector) = (0.08, 0.70, 1.0, 0)
        _P1 ("P1", Vector) = (0.35, 0.35, 1.0, 0)
        _P2 ("P2", Vector) = (0.65, 0.60, 0.9, 0)
        _P3 ("P3", Vector) = (0.92, 0.30, 0.6, 0)
        _P4 ("P4", Vector) = (0.92, 0.30, 0.6, 0)
        _P5 ("P5", Vector) = (0.92, 0.30, 0.6, 0)

        [Header(Ribbon)]
        _Width ("Half width at pressure 1 (picture heights)", Range(0.01, 0.4)) = 0.09
        _PressureWidth ("Pressure -> width", Range(0, 1)) = 0.8
        _Taper ("Tail taper", Range(0, 1)) = 0.55
        _EdgeRagged ("Ragged edge", Range(0, 1)) = 0.45

        [Header(Bristles)]
        _Bristles ("Bristles across the stroke", Range(4, 80)) = 26
        _Streakiness ("Streakiness (strand tone variation)", Range(0, 1)) = 0.45
        _StrandLen ("Strand wander length (x width)", Range(0.5, 12)) = 4
        _Groove ("Groove between strands", Range(0, 1)) = 0.25

        [Header(Dry brush)]
        _DryBrush ("Dry brush (paint runs out toward the tail)", Range(0, 1)) = 0.6
        _DryStart ("Dry brush starts at (0..1 along the stroke)", Range(0, 1)) = 0.4
        _Ridge ("Edge ridge (piled-up paint)", Range(0, 1)) = 0.4
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }
        Cull Off Lighting Off ZWrite Off ZTest Always
        ColorMask [_ColorMask]
        Blend One OneMinusSrcAlpha

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "CG/Core/UIBackdropFlow.cginc"
            #include "CG/Core/UIDecalStroke.cginc"

            struct appdata_t { float4 vertex : POSITION; float2 texcoord : TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct v2f { float4 vertex : SV_POSITION; float2 texcoord : TEXCOORD0; UNITY_VERTEX_OUTPUT_STEREO };

            float4 _Color;
            float _Seed;
            float _Width, _PressureWidth, _Taper, _EdgeRagged;
            float _Bristles, _Streakiness, _StrandLen, _Groove;
            float _DryBrush, _DryStart, _Ridge;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                return OUT;
            }

            float4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float dist, arc, pres, side;
                dcStroke(uv, dist, arc, pres, side);

                // path length from the control polygon: strands are measured along the stroke in widths
                float cnt = clamp(_PointCount, 1.0, 6.0);
                float plen = length(_P1.xy - _P0.xy) * step(1.5, cnt) + length(_P2.xy - _P1.xy) * step(2.5, cnt)
                           + length(_P3.xy - _P2.xy) * step(3.5, cnt) + length(_P4.xy - _P3.xy) * step(4.5, cnt)
                           + length(_P5.xy - _P4.xy) * step(5.5, cnt);

                float taper = 1.0 - _Taper * smoothstep(0.55, 1.0, arc);
                float w = max(_Width * lerp(1.0, saturate(pres), _PressureWidth) * taper, 0.004);
                float l = side * dist / w;                                           // signed lateral coordinate, edges at +-1
                float u = saturate(l * 0.5 + 0.5);                                   // 0..1 across the ribbon
                float along = arc * plen / max(_Width, 1e-3) / max(_StrandLen, 0.1); // slow coordinate along the stroke

                // THE START CAP. Behind the first point (capS) the nearest-point distance is radial, which would give
                // ring-shaped strands. Instead measure in the stroke's own frame: lc = lateral (same axis as the body's
                // l, so the strands run straight on into the cap), e = how far behind the first point. The cap outline
                // is a slightly blunt superellipse, and `along` keeps counting backwards so the strand wander continues.
                float capS = step(arc, 0.0005);
                float capE = step(0.9995, arc);
                float cnt1 = step(1.5, cnt);
                float2 q1 = lerp(_P0.xy, _P1.xy, cnt1);
                float2 q2 = lerp(q1, _P2.xy, step(2.5, cnt));
                float2 d0 = dcCR(_P0.xy, _P0.xy, q1, q2, 1.0 / 6.0) - _P0.xy;           // direction of the first piece
                d0 = (dot(d0, d0) > 1e-10) ? normalize(d0) : float2(1.0, 0.0);
                float2 rel = uv - _P0.xy;
                float lc = dot(rel, float2(-d0.y, d0.x)) / w;
                float e = dot(rel, -d0) / w;
                e = lerp(abs(e), max(e, 0.0), cnt1);                                      // a lone dab is round all the way round
                float lm = pow(pow(abs(lc), 2.5) + pow(e, 2.5), 0.4);                    // blunt-round metric, 1 at the cap rim
                l = lerp(l, lc, capS);
                u = saturate(l * 0.5 + 0.5);
                along = lerp(along, -e * w / max(_Width, 1e-3) / max(_StrandLen, 0.1), capS);
                float lmEdge = lerp(abs(l), lm, capS);                                    // the metric the outline/ridge use

                // strands: each has its own load, wandering along the stroke
                float N = max(_Bristles, 1.0);
                float sid = min(floor(u * N), N - 1.0);                                   // |l| >= 1 shares the outermost strand
                float base = bdHash21(float2(sid, _Seed * 3.7 + 1.0));
                float wander = bdNoise(float2(sid * 3.13 + _Seed * 5.0, along));
                float load = lerp(base, wander, 0.55);

                // dry brush: the threshold rises toward the tail, outer strands run dry first (none at the loaded start)
                float dry = _DryBrush * smoothstep(_DryStart, 1.0, arc);
                float edgeBias = pow(abs(l), 3.0) * 0.35 * _DryBrush * smoothstep(_DryStart * 0.5, 1.0, arc);
                float thresh = dry * 0.92 + edgeBias;
                float strand = smoothstep(thresh, thresh + 0.1, load + 0.05);
                // the strands end at different points along the tail, each with a soft little feather
                float endAt = 1.0 - (0.03 + dry * 0.14) * bdHash21(float2(sid, _Seed + 21.0));
                strand *= (1.0 - smoothstep(endAt - 0.012, endAt, arc)) * (1.0 - capE);

                // ragged edge: the outer strands are different lengths (the cap rim gets the same ragging)
                float rag = (bdHash21(float2(sid, _Seed + 9.0)) - 0.5) * 2.0;
                float outer = step(0.8, abs(l));
                float lim = 1.0 + _EdgeRagged * (0.16 * rag * outer + 0.1 * (bdNoise(float2(along * 6.0 + side * 17.0, _Seed)) - 0.5));
                float aa = max(fwidth(dist) / w, 0.02);
                float shape = 1.0 - smoothstep(lim - aa, lim + aa, lmEdge);
                float cov = shape * strand;

                // tone: strands lighter/darker, grooves, a ridge of piled paint at the edges. The loaded start is a
                // little calmer than the body (paint pooled), easing into the streaks over the cap's length.
                float pat = lerp(1.0, 1.0 - 0.4 * smoothstep(0.0, 1.0, e), capS);
                float3 col = _Color.rgb;
                float tone = ((base - 0.5) * 0.5 + (wander - 0.5)) * pat;
                col *= 1.0 + tone * _Streakiness * 0.55;
                float fu = frac(u * N);
                float groove = (1.0 - smoothstep(0.0, 0.16, min(fu, 1.0 - fu))) * pat;
                col *= 1.0 - _Groove * 0.35 * groove;
                float ridge = smoothstep(0.78, 0.98, lmEdge) * (1.0 - smoothstep(0.98, 1.1, lmEdge));
                col = lerp(col, lerp(col, float3(1.0, 1.0, 1.0), 0.22), _Ridge * ridge);

                // thin paint (dry strands, strand edges) is a little see-through
                float a = cov * lerp(1.0, 0.82 + 0.18 * load, dry) * _Color.a * (1.0 - 0.12 * _Groove * groove);
                return float4(saturate(col) * a, a);                                // premultiplied
            }
            ENDCG
        }
    }
}
