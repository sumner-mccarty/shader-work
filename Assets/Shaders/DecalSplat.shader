// ============================================================================
// DecalSplat.shader — thrown paint (generator for the paint layer, Docs/UiDecals.md §3.1)
// ============================================================================
// Draws ONE splat into a transparent quad: uv 0..1 = the decoration's bounds (draw it into a square quad;
// the picture is centred, -1..1 on both axes). Output is PREMULTIPLIED rgba (rgb * a, a = coverage),
// Blend One OneMinusSrcAlpha. Fully seeded and deterministic (bdHash* from UIBackdropFlow.cginc): the same
// properties always give the same splat, so a decoration is just its Properties.
//
// What makes it read as paint rather than a blob:
//   * a main blob with lobes, squashed along the throw and an fbm-roughened edge,
//   * SATELLITES flung along _ThrowAngle: they fall in size with distance, stretch along the throw and are
//     smooth-unioned, so the nearest ones are still joined to the body by a wet neck,
//   * thin tapered STREAKS ending in a bulb, mostly inside a cone around the throw direction,
//   * tiny DROPLETS in the same cone,
//   * DRIPS: gravity runs (capsule + bulb end) hanging downward from the underside (down = -v, the picture's
//     bottom), each with its own length and width,
//   * a faint WET SHEEN: a lighter band just inside the edge plus a small highlight on the lit side,
//     and thin-film variation (thicker = deeper colour) so one flat fill never shows.
// _Reveal 0..1 plays the throw: the blob punches out from the impact point (with overshoot), satellites and
// droplets fly out along the throw, streaks lengthen, drips start once the blob has landed.
// _Reveal = 1 is the finished splat; 0 draws nothing.
//
// Every look decision is a Property; there are no textures. No derivatives inside branches (the shader has
// no branches on varying data), no reserved HLSL names.
// ============================================================================

Shader "UI/Decal/Splat"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Paint colour (alpha = overall opacity)", Color) = (0.95, 0.12, 0.38, 1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Seed and animation)]
        _Seed ("Seed", Float) = 1
        _Reveal ("Reveal (throw animation 0..1)", Range(0, 1)) = 1

        [Header(Throw)]
        _ThrowAngle ("Throw direction (degrees, 0 = right, 90 = up)", Range(0, 360)) = 25
        _Reach ("Reach (how far the spray is flung)", Range(0.2, 0.95)) = 0.8
        _Directional ("Directional (0 = burst in all directions, 1 = tight cone)", Range(0, 1)) = 0.65

        [Header(Main blob)]
        _Size ("Blob radius", Range(0.08, 0.6)) = 0.30
        _Lobes ("Lobes (outline irregularity)", Range(0, 1)) = 0.45
        _Tendrils ("Tendrils (pointed tongues, biased to the throw)", Range(0, 1)) = 0.5
        _Stretch ("Stretch along the throw", Range(0, 1)) = 0.3
        _Rough ("Edge roughness", Range(0, 1)) = 0.2
        _RoughScale ("Edge roughness scale", Range(2, 40)) = 14
        _Smooth ("Neck smoothing (wet joins)", Range(0, 1)) = 0.35

        [Header(Flung paint)]
        _Satellites ("Satellites (amount)", Range(0, 1)) = 0.8
        _SatSize ("Satellite size", Range(0.05, 0.8)) = 0.5
        _Spread ("Satellite sideways spread", Range(0, 1)) = 0.45
        _Streaks ("Streaks (amount)", Range(0, 1)) = 0.6
        _StreakLen ("Streak length", Range(0.2, 2)) = 1
        _Droplets ("Droplets (amount)", Range(0, 1)) = 0.8

        [Header(Drips)]
        _Drips ("Drips (amount, 6 runs)", Range(0, 1)) = 0.5
        _DripLen ("Drip length", Range(0.05, 1)) = 0.45

        [Header(Finish)]
        _Gloss ("Wet sheen", Range(0, 1)) = 0.45
        _GlossWidth ("Sheen width", Range(0.005, 0.1)) = 0.018
        _Depth ("Thickness shading (thicker = deeper)", Range(0, 0.6)) = 0.12
        _Variation ("Pigment variation", Range(0, 0.4)) = 0.08
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

            struct appdata_t { float4 vertex : POSITION; float2 texcoord : TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct v2f { float4 vertex : SV_POSITION; float2 texcoord : TEXCOORD0; UNITY_VERTEX_OUTPUT_STEREO };

            float4 _Color;
            float _Seed, _Reveal;
            float _ThrowAngle, _Reach, _Directional;
            float _Size, _Lobes, _Tendrils, _Stretch, _Rough, _RoughScale, _Smooth;
            float _Satellites, _SatSize, _Spread, _Streaks, _StreakLen, _Droplets;
            float _Drips, _DripLen;
            float _Gloss, _GlossWidth, _Depth, _Variation;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                return OUT;
            }

            // polynomial smooth minimum: a wet neck between two shapes
            float dsMin(float a, float b, float k)
            {
                float h = saturate(0.5 + 0.5 * (b - a) / max(k, 1e-4));
                return lerp(b, a, h) - k * h * (1.0 - h);
            }
            float dsOut(float x) { x = saturate(x); float m = 1.0 - x; return 1.0 - m * m * m; }          // fast then settling
            float dsBack(float x) { x = saturate(x); float m = x - 1.0; return 1.0 + 2.70158 * m * m * m + 1.70158 * m * m; }  // overshoot
            // seeded random: item i, channel k
            float dsRand(float i, float k)
            {
                return bdHash21(float2(i * 1.7 + k * 31.3 + _Seed * 0.137, k * 7.9 + _Seed * 0.731 + i * 0.37 + 11.0));
            }
            // tapered segment a->b, radius ra at a, rb at b
            float dsTaper(float2 p, float2 a, float2 b, float ra, float rb)
            {
                float2 pa = p - a;
                float2 ba = b - a;
                float h = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-6));
                return length(pa - ba * h) - lerp(ra, rb, h);
            }

            float4 frag(v2f IN) : SV_Target
            {
                float2 q = (IN.texcoord - 0.5) * 2.0;                                // -1..1, v up
                float ta = radians(_ThrowAngle);
                float2 D = float2(cos(ta), sin(ta));                                 // throw direction
                float2 N = float2(-D.y, D.x);                                        // sideways
                float2 down = float2(0.0, -1.0);
                float R = _Size;
                float2 c = -D * _Reach * 0.28;                                       // impact point: the spray needs the room
                float rv = _Reveal;
                float k = _Smooth * 0.06;
                float cone = 3.14159 * (2.0 - 1.85 * _Directional);                  // total angle spread around the throw

                // one low-frequency + one edge noise, shared by every shape (each scales it by its own size)
                float edge = bdFbm(q * _RoughScale + _Seed * 1.37, 3.0) - 0.5;

                // ---- main blob: lobed, squashed along the throw, punches out with overshoot --------------------
                float2 pm = q - c;
                float2 um = pm / max(length(pm), 1e-4);
                float lobe = bdFbm(um * 1.7 + _Seed * 0.91, 2.0) - 0.5;
                float tongue = pow(bdNoise(um * 4.5 + _Seed * 1.7), 3.5) * (0.35 + 0.65 * saturate(dot(um, D) + 0.3));
                float Re = R * (1.0 + _Lobes * lobe * 1.6 + _Tendrils * 1.1 * tongue) * dsBack(rv / 0.45);
                float2 pl = float2(dot(pm, D) / (1.0 + _Stretch), dot(pm, N));
                float d = length(pl) - Re + edge * R * _Rough * 0.7;

                // ---- satellites flung along the throw, falling in size ------------------------------------------
                [unroll]
                for (int i = 0; i < 10; i++)
                {
                    float fi = (float)i;
                    float t = (fi + 0.5 + 0.8 * (dsRand(fi, 1.0) - 0.5)) / 10.0;
                    float dist = lerp(R * 1.25, _Reach, pow(t, 0.8));
                    float side = (dsRand(fi, 2.0) - 0.5) * 2.0 * _Spread * (0.12 + 0.55 * t);
                    float2 pf = c + D * dist + N * side;
                    float amount = saturate(_Satellites * 10.0 + 0.5 - fi);
                    float ph = saturate((rv - 0.05 - 0.4 * t) / 0.45);              // launched in order of distance
                    float2 pos = c + (pf - c) * dsOut(ph);
                    float r = R * _SatSize * pow(saturate(1.0 - t * 0.85), 1.5) * (0.55 + 0.9 * dsRand(fi, 3.0)) * amount * dsBack(ph);
                    float2 lp = q - pos;
                    float2 sl = float2(dot(lp, D) / (1.0 + 0.9 * _Stretch * (1.0 - t)), dot(lp, N));
                    float ds = length(sl) - r + edge * r * _Rough * 0.8;
                    ds = lerp(1000.0, ds, step(0.0005, r));
                    d = dsMin(d, ds, k * (1.0 - t));                                // near ones stay joined by a neck
                }

                // ---- streaks: tapered, tip bulb, inside the cone ------------------------------------------------
                [unroll]
                for (int j = 0; j < 8; j++)
                {
                    float fj = (float)j;
                    float ang = ta + (dsRand(fj, 4.0) - 0.5) * cone;
                    float2 sd2 = float2(cos(ang), sin(ang));
                    float amount = saturate(_Streaks * 8.0 + 0.5 - fj);
                    float len = R * (0.5 + 1.1 * dsRand(fj, 5.0)) * _StreakLen * dsOut((rv - 0.1) / 0.5) * amount;
                    float w0 = (0.012 + 0.018 * dsRand(fj, 6.0)) * (0.4 + 0.6 * amount);
                    float2 sa = c + sd2 * R * 0.55;
                    float2 sb = sa + sd2 * len;
                    float dstr = dsTaper(q, sa, sb, w0, w0 * 0.3);
                    float dbulb = length(q - sb) - w0 * 0.7;
                    float dj = min(dstr, dbulb);
                    dj = lerp(1000.0, dj, step(0.002, len));
                    d = dsMin(d, dj, k * 0.5);
                }

                // ---- droplets: tiny, same cone, beyond the satellites ---------------------------------------------
                [unroll]
                for (int m = 0; m < 16; m++)
                {
                    float fm = (float)m;
                    float ang = ta + (dsRand(fm, 7.0) - 0.5) * cone * 1.15;
                    float rr = lerp(R * 1.15, min(_Reach * 1.12, 0.97), pow(dsRand(fm, 8.0), 0.75));
                    float amount = saturate(_Droplets * 16.0 + 0.5 - fm);
                    float ph = saturate((rv - 0.08 - 0.35 * rr) / 0.4);
                    float2 pos = c + float2(cos(ang), sin(ang)) * rr * dsOut(ph);
                    float r = (0.006 + 0.022 * pow(dsRand(fm, 9.0), 2.0)) * amount * dsBack(ph);
                    float dm = length(q - pos) - r;
                    dm = lerp(1000.0, dm, step(0.0008, r));
                    d = min(d, dm);
                }

                // ---- drips: gravity runs from the underside -------------------------------------------------------
                [unroll]
                for (int n = 0; n < 6; n++)
                {
                    float fn = (float)n;
                    float amount = saturate(_Drips * 6.0 + 0.5 - fn);
                    float u = (fn + 0.5 + 0.7 * (dsRand(fn, 10.0) - 0.5)) / 6.0;      // across the blob, left to right
                    float dx = (u * 2.0 - 1.0) * Re * 0.7;
                    float2 top = c + float2(dx, -sqrt(max(Re * Re - dx * dx, 0.0)) * 0.3);
                    float runPh = dsOut((rv - 0.55 - 0.04 * fn) / 0.45);
                    float len = (_DripLen * (0.25 + 0.75 * dsRand(fn, 11.0)) * R * 2.0 + Re * 0.9) * amount * runPh;
                    len = min(len, max(top.y + 0.96, 0.0));                           // stay inside the picture
                    float w = (0.011 + 0.016 * dsRand(fn, 12.0)) * (0.5 + 0.5 * amount);
                    float2 tip = top + down * len;
                    float dcap = dsTaper(q, top, tip, w, w * 0.7);
                    float dbulb = length(q - tip) - w * 1.45;
                    float dn = min(dcap, dbulb);
                    dn = lerp(1000.0, dn, step(0.004, len));
                    d = dsMin(d, dn, k * 1.4);
                }

                // keep inside the picture
                d = max(d, max(abs(q.x), abs(q.y)) - 0.995);

                // ---- coverage ----------------------------------------------------------------------------------------
                float aa = max(fwidth(d) * 0.8, 0.0012);
                float cov = 1.0 - smoothstep(-aa, aa, d);

                // ---- paint: thickness, pigment, wet sheen ---------------------------------------------------------------
                float inside = max(-d, 0.0);
                float3 col = _Color.rgb;
                float lum = dot(col, float3(0.2126, 0.7152, 0.0722));
                col *= 1.0 - _Depth * (1.0 - 0.75 * lum) * smoothstep(0.0, 0.12, inside);               // thin at the rim, deep in the pool
                float pig = bdFbm(q * 3.1 + _Seed * 2.3, 3.0) - 0.5;
                col *= 1.0 + pig * 2.0 * _Variation;

                float w = max(_GlossWidth, 0.004);
                float band = exp(-pow((inside - w * 0.8) / (w * 0.6), 2.0));        // lighter rim just inside the edge
                float2 g = float2(ddx(d), ddy(d));
                float2 outward = g / max(length(g), 1e-6);
                float facing = saturate(dot(outward, normalize(float2(-0.55, 0.85))));   // lit side (screen up-left)
                float hl = exp(-pow((inside - w * 0.55) / (w * 0.45), 2.0)) * pow(facing, 2.0);
                float3 lighter = lerp(col, float3(1.0, 1.0, 1.0), 0.45);
                col = lerp(col, lighter, _Gloss * 0.55 * band);
                col = lerp(col, float3(1.0, 1.0, 1.0), _Gloss * 0.85 * hl);

                float a = cov * _Color.a;
                return float4(saturate(col) * a, a);                                // premultiplied
            }
            ENDCG
        }
    }
}
