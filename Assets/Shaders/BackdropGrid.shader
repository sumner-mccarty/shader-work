// ============================================================================
// BackdropGrid.shader — a glowing perspective grid running to a horizon (retro / synthwave floor)
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic,
// _Speed is cycles per second). The floor scrolls toward the viewer by a WHOLE number of cells per
// cycle, so the loop is seamless; above the horizon, a sky gradient and an optional striped sun whose
// cuts drift down by whole stripes per cycle. Lines are anti-aliased by their own screen derivative and
// fade into a horizon haze, so the far field never moirés.
// ============================================================================

Shader "UI/Backdrop/Grid"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.05
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0
        _ScrollCells ("Cells scrolled per cycle (whole)", Range(0, 16)) = 4

        [Header(Floor)]
        _Horizon ("Horizon height (0 bottom, 1 top)", Range(0.1, 0.9)) = 0.45
        _CameraHeight ("Camera height", Range(0.1, 4)) = 1
        _CellSize ("Cell size", Range(0.1, 4)) = 1
        _LineWidth ("Line width (screen px)", Range(0.5, 6)) = 1.4
        _LineColor ("Line colour", Color) = (1.000, 0.250, 0.800, 1)
        _LineGlow ("Line glow", Range(0, 2)) = 0.8
        _Floor ("Floor", Color) = (0.030, 0.010, 0.060, 1)
        _Haze ("Horizon haze", Range(0, 1)) = 0.6
        _HazeColor ("Haze colour", Color) = (0.900, 0.300, 0.700, 1)

        [Header(Sky)]
        _SkyTop ("Sky top", Color) = (0.020, 0.010, 0.080, 1)
        _SkyBottom ("Sky at horizon", Color) = (0.350, 0.050, 0.350, 1)
        _Sun ("Sun", Range(0, 1)) = 1
        _SunSize ("Sun radius (picture heights)", Range(0.05, 0.6)) = 0.22
        _SunTop ("Sun top", Color) = (1.000, 0.850, 0.300, 1)
        _SunBottom ("Sun bottom", Color) = (1.000, 0.200, 0.550, 1)
        _SunStripes ("Sun stripes (per radius)", Range(0, 12)) = 5

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1
        _Vignette ("Vignette", Range(0, 1)) = 0.25
        _Grain ("Film grain", Range(0, 0.2)) = 0
    }

    SubShader
    {
        Tags { "Queue"="Background" "IgnoreProjector"="True" "RenderType"="Opaque" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }
        Cull Off Lighting Off ZWrite Off ZTest Always
        ColorMask [_ColorMask]
        Blend Off

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

            fixed4 _Color;
            float _Speed, _Phase, _Aspect, _ScrollCells;
            float _Horizon, _CameraHeight, _CellSize, _LineWidth, _LineGlow, _Haze;
            float4 _LineColor, _Floor, _HazeColor;
            float4 _SkyTop, _SkyBottom, _SunTop, _SunBottom;
            float _Sun, _SunSize, _SunStripes;
            float _Brightness, _Contrast, _Saturation, _Vignette, _Grain;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                return OUT;
            }

            // distance to the nearest grid line in cell units, anti-aliased by its own derivative
            float gridLine(float x, float widthPx)
            {
                float w = max(fwidth(x), 1e-5);
                float d = abs(frac(x + 0.5) - 0.5) / w;      // screen pixels from the line centre
                return saturate(1.0 - (d - widthPx * 0.5));
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float cyc = _Time.y * _Speed + _Phase;
                float2 uv = IN.texcoord;
                float asp = _Aspect > 0.01 ? _Aspect : _ScreenParams.x / max(_ScreenParams.y, 1.0);
                float below = _Horizon - uv.y;                       // > 0 on the floor

                // ---- sky + sun --------------------------------------------------------------------------
                float sky = saturate((uv.y - _Horizon) / max(1.0 - _Horizon, 1e-3));
                float3 col = lerp(_SkyBottom.rgb, _SkyTop.rgb, sqrt(sky));
                float2 sp = (uv - float2(0.5, _Horizon + _SunSize * 0.55)) * float2(asp, 1.0);
                float sd = length(sp);
                float sunPx = fwidth(sd);
                float sunMask = saturate((_SunSize - sd) / max(sunPx, 1e-5) + 0.5) * step(0.0, -below);
                // stripes cut the lower part, gaps widening toward the horizon; they drift down one whole
                // stripe per cycle (frac(cyc) shifts the pattern by exactly one period)
                float sv = sp.y / _SunSize;                                    // -0.55 at the horizon .. 1 at the top
                float gapT = saturate((0.35 - sv) / 0.9);                      // 0 above 0.35 R, 1 at the horizon
                float stripe = frac(sv * _SunStripes + frac(cyc));
                float cut = _SunStripes > 0.5 ? step(gapT * 0.6, stripe) : 1.0;
                float3 sunCol = lerp(_SunBottom.rgb, _SunTop.rgb, saturate(sp.y / (_SunSize * 2.0) + 0.5));
                col = lerp(col, sunCol, sunMask * cut * _Sun);
                col += sunCol * _Sun * 0.25 * exp(-max(sd - _SunSize, 0.0) * 9.0) * step(0.0, -below);

                // ---- floor (computed everywhere, then masked: derivatives must stay out of branches) ------
                float z = _CameraHeight / max(below, 1e-3);          // depth, grows to infinity at the horizon
                float x = (uv.x - 0.5) * asp * z;
                float2 g = float2(x, z) / _CellSize;
                g.y += frac(cyc) * round(_ScrollCells);              // whole cells per cycle: seamless
                float lx = gridLine(g.x, _LineWidth);
                float lz = gridLine(g.y, _LineWidth);
                float ln = max(lx, lz);
                float fog = exp(-z * 0.08 * (1.0 + _Haze * 3.0));
                float3 floorCol = _Floor.rgb;
                floorCol += _LineColor.rgb * ln * fog;
                floorCol += _LineColor.rgb * _LineGlow * 0.25 * fog * (exp(-abs(frac(g.x + 0.5) - 0.5) * 9.0) + exp(-abs(frac(g.y + 0.5) - 0.5) * 9.0)) * 0.5;
                floorCol = lerp(floorCol, _HazeColor.rgb, (1.0 - fog) * _Haze);
                col = below > 0.0 ? floorCol : col;
                // the haze line itself, either side of the horizon
                col += _HazeColor.rgb * _Haze * 0.35 * exp(-abs(below) * 28.0);

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
