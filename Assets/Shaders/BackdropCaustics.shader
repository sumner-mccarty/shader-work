// ============================================================================
// BackdropCaustics.shader — flowing water: a caustic network over cold colour fields
// ============================================================================
// A procedural, animated backdrop (see CG/Core/UIBackdropFlow.cginc for the time contract: everything is
// exactly periodic, _Speed is cycles per second). Rendered by a host into a render texture and bound as
// _UIBackdropTex, it is what a glass part refracts; drawn as a UI Image / Blit it is the visible wallpaper.
//
// Layers: (1) colour FIELDS — two fbm fields pick a 4-stop ramp (deep → mid → light) and a pool colour;
// (2) a domain warp makes every edge wander like water; (3) CAUSTIC LINES — the zero-crossings of two
// warped sine sums, thickness _LineWidth, whose phases move a whole number of turns per cycle.
//
// Self-contained: no widget includes, no lighting, no clip rect — a backdrop fills its quad.
// ============================================================================

Shader "UI/Backdrop/Caustics"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.04
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0

        [Header(Shape)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.8
        _Warp ("Domain warp", Range(0, 2)) = 0.7
        _Detail ("Detail (fbm octaves)", Range(1, 4)) = 3
        _FieldScale ("Colour field scale", Range(0.2, 4)) = 0.9

        [Header(Colour)]
        _ColorA ("Deep", Color) = (0.000, 0.040, 0.090, 1)
        _ColorB ("Mid", Color) = (0.050, 0.350, 0.560, 1)
        _ColorC ("Light", Color) = (0.150, 0.650, 0.800, 1)
        _ColorD ("Pool", Color) = (0.420, 0.160, 0.850, 1)
        _PoolAmount ("Pool amount", Range(0, 1)) = 0.7
        _Depth ("Depth fade (bright top, dark bottom)", Range(0, 1)) = 0.5

        [Header(Caustic lines)]
        _LineColor ("Line colour", Color) = (0.300, 0.850, 0.950, 1)
        _LineStrength ("Line strength", Range(0, 2)) = 0.9
        _LineWidth ("Line width", Range(0.04, 0.8)) = 0.30
        _LineLayers ("Line layers", Range(1, 3)) = 2

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

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest Always
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

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            float _Speed, _Phase, _Aspect;
            float _Scale, _Warp, _Detail, _FieldScale;
            float4 _ColorA, _ColorB, _ColorC, _ColorD;
            float _PoolAmount, _Depth;
            float4 _LineColor;
            float _LineStrength, _LineWidth, _LineLayers;
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

            fixed4 frag(v2f IN) : SV_Target
            {
                float cyc = _Time.y * _Speed + _Phase;
                float2 uv = IN.texcoord;
                float2 p = bdPos(uv, _Aspect, _Scale);

                // 1) water-like domain warp: the position is pushed round by two slowly orbiting noise fields
                float2 warp = float2(bdFbm(p * 0.9 + bdOrbit(cyc, 0.6, 0.00), _Detail),
                                     bdFbm(p * 0.9 + 7.3 + bdOrbit(cyc, 0.6, 0.37), _Detail)) - 0.5;
                float2 q = p + _Warp * warp;

                // 2) colour fields: one chooses the ramp stop, one scatters the pool colour
                float f = bdFbm(q * _FieldScale + bdOrbit(cyc, 0.5, 0.11), _Detail);
                float g = bdFbm(q * _FieldScale * 0.8 + 3.1 + bdOrbit(cyc, 0.45, 0.63), _Detail);
                float3 col = bdRamp4(smoothstep(0.15, 0.85, f) * 0.66, _ColorA.rgb, _ColorB.rgb, _ColorC.rgb, _ColorC.rgb);
                col = lerp(col, _ColorD.rgb, smoothstep(0.50, 0.85, g) * _PoolAmount);

                // 3) caustic network: zero-crossings of warped sine pairs, phases a whole number of turns per cycle
                float c = 0.0;
                [unroll]
                for (int l = 0; l < 3; l++)
                {
                    float on = saturate(_LineLayers - (float)l);
                    float k = (1.0 + 0.8 * (float)l) * 1.6;
                    float t = BD_TAU * cyc * (float)(l + 1);
                    float w = sin(q.x * k * 2.0 + 1.6 * sin(q.y * k * 1.7 + t))
                            + sin(q.y * k * 2.4 + 1.4 * sin(q.x * k * 1.3 - t));
                    c += exp(-(w / _LineWidth) * (w / _LineWidth)) * on * (1.0 - 0.35 * (float)l);
                }
                float depth = lerp(1.0, saturate(1.15 - uv.y), _Depth);        // uv.y 0 = bottom: the surface is bright
                col += _LineColor.rgb * c * _LineStrength * depth;
                col *= lerp(1.0, 0.45 + 0.55 * depth, _Depth);

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
