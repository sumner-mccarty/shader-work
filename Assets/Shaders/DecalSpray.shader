// ============================================================================
// DecalSpray.shader — spray-can stroke (generator for the paint layer, Docs/UiDecals.md §3.1)
// ============================================================================
// Draws ONE stroke into a transparent quad: uv 0..1 = the decoration's bounds (v up, draw it into a square quad).
// Output is PREMULTIPLIED rgba (rgb * a, a = coverage), Blend One OneMinusSrcAlpha. Seeded and deterministic
// (bdHash* from UIBackdropFlow.cginc).
//
// THE STROKE. Up to six points _P0.._P5 (float4: x, y, pressure, unused; uv 0..1) and _PointCount, joined by a
// Catmull-Rom spline (CG/Core/UIDecalStroke.cginc, shared with DecalBrush). Pressure sets the width (and a bit of
// the flow) along the path.
//
// WHAT MAKES IT SPRAY. Paint leaves a can as a cone of droplets whose density is Gaussian about the path:
//   * a SOFT CORE: accumulated density -> alpha = 1 - exp(-flow * gauss(d / width)); high flow = a solid centre,
//     low flow = see-through mist. _Softness runs a tight can-at-the-wall line -> a wide diffuse puff.
//   * SPECKLE: the core's falloff is stippled against a fine noise (the edge breaks into dots, not a clean blur).
//   * OVERSPRAY: droplets outside the core, two sizes, their number falling off with distance from the path.
// ============================================================================

Shader "UI/Decal/Spray"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Paint colour (alpha = overall opacity)", Color) = (1.0, 0.83, 0.0, 1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Seed)]
        _Seed ("Seed", Float) = 1

        [Header(Stroke points  x y pressure unused)]
        _PointCount ("Point count (1..6)", Range(1, 6)) = 4
        _P0 ("P0", Vector) = (0.10, 0.80, 1.0, 0)
        _P1 ("P1", Vector) = (0.32, 0.32, 0.9, 0)
        _P2 ("P2", Vector) = (0.58, 0.68, 0.7, 0)
        _P3 ("P3", Vector) = (0.90, 0.22, 0.4, 0)
        _P4 ("P4", Vector) = (0.90, 0.22, 0.4, 0)
        _P5 ("P5", Vector) = (0.90, 0.22, 0.4, 0)

        [Header(Core)]
        _Width ("Core radius at pressure 1 (picture heights)", Range(0.01, 0.4)) = 0.1
        _PressureWidth ("Pressure -> width", Range(0, 1)) = 0.8
        _PressureFlow ("Pressure -> flow", Range(0, 1)) = 0.5
        _Flow ("Flow (paint amount; high = solid centre)", Range(0.2, 8)) = 3.5
        _Softness ("Softness (tight line -> diffuse puff)", Range(0, 1)) = 0.5

        [Header(Speckle)]
        _Speckle ("Speckle (stippled edge)", Range(0, 1)) = 0.7
        _GrainScale ("Grain scale (features per picture)", Range(40, 400)) = 170

        [Header(Overspray)]
        _Overspray ("Overspray amount", Range(0, 1)) = 0.6
        _OversprayReach ("Overspray reach (x core radius)", Range(1, 5)) = 2.4
        _DotSize ("Overspray dot size", Range(0.2, 2)) = 1
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
            float _Width, _PressureWidth, _PressureFlow, _Flow, _Softness;
            float _Speckle, _GrainScale;
            float _Overspray, _OversprayReach, _DotSize;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                return OUT;
            }

            // One layer of overspray droplets: a jittered cell grid (cells of 1/scale), each cell holds at most one dot;
            // `prob` is the chance a cell has one (already faded by distance from the path).
            float dsDots(float2 uv, float scale, float prob, float rad, float salt)
            {
                float2 g = uv * scale;
                float2 ci = floor(g);
                float cov = 0.0;
                float aa = 0.75 / max(_ScreenParams.y, 1.0) * scale;                 // ~one pixel in cell units
                [unroll]
                for (int y = -1; y <= 1; y++)
                {
                    [unroll]
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 cell = ci + float2((float)x, (float)y);
                        float3 h = float3(bdHash21(cell + _Seed * 3.17 + salt),
                                          bdHash21(cell * 1.31 + 17.7 + _Seed * 1.91 + salt),
                                          bdHash21(cell * 0.77 + 5.3 + _Seed * 0.53 + salt));
                        float2 centre = cell + 0.15 + 0.7 * float2(h.y, h.z);
                        float r = rad * (0.25 + 0.75 * h.y * h.y);
                        float exists = step(h.x, prob);
                        float dd = length(g - centre);
                        float a = 1.0 - smoothstep(r - aa, r + aa, dd);
                        cov = max(cov, a * exists * (0.55 + 0.45 * h.z));
                    }
                }
                return cov;
            }

            float4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float dist, arc, pres, side;
                dcStroke(uv, dist, arc, pres, side);

                float w = _Width * lerp(1.0, saturate(pres), _PressureWidth);
                w = max(w, 0.004);
                float x = dist / w;
                float flow = _Flow * lerp(1.0, saturate(pres), _PressureFlow);

                // soft core: Gaussian droplet density -> accumulated alpha
                float k = lerp(9.0, 1.6, _Softness);
                float dens = exp(-x * x * k);
                float core = 1.0 - exp(-flow * dens);

                // speckle: stipple the falloff against a fine, slightly blotchy noise
                float gf = _GrainScale;
                float rnd = 0.6 * bdNoise(uv * gf + _Seed * 7.1) + 0.4 * bdHash21(floor(uv * gf * 0.7) + _Seed);
                float e = 0.12;
                float stip = smoothstep(rnd - e, rnd + e, core);
                float cov = lerp(core, stip, _Speckle * (1.0 - smoothstep(0.55, 0.98, core)));

                // overspray: fine + coarse droplets, density falling off with distance from the path
                float far = dist / (w * _OversprayReach);
                float fade = exp(-far * far * 2.2) * _Overspray;
                float fineDots = dsDots(uv, 90.0 / max(_DotSize, 0.05) * 0.8, fade * 0.55, 0.30 * _DotSize, 0.0);
                float bigDots = dsDots(uv, 34.0 / max(_DotSize, 0.05) * 0.8, fade * 0.22, 0.22 * _DotSize, 41.0);
                cov = max(cov, max(fineDots, bigDots));

                float a = saturate(cov) * _Color.a;
                return float4(_Color.rgb * a, a);                                       // premultiplied
            }
            ENDCG
        }
    }
}
