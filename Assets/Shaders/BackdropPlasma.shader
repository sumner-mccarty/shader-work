// ============================================================================
// BackdropPlasma.shader — interfering colour waves (plasma / liquid gradient)
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic,
// _Speed is cycles per second). Four sine fields with whole-turn phases interfere over a gently warped
// domain; their sum picks a colour from the four-stop ramp, `_Bands` times across. Low `_Sharpness` is a
// smooth mesh gradient, high is the hard-banded classic plasma.
// ============================================================================

Shader "UI/Backdrop/Plasma"
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

        [Header(Plasma)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.6
        _Warp ("Domain warp", Range(0, 2)) = 0.6
        _Bands ("Colour bands", Range(0.25, 4)) = 1
        _Sharpness ("Band sharpness", Range(0, 1)) = 0.15

        [Header(Colour)]
        _ColorA ("Colour A", Color) = (0.070, 0.050, 0.250, 1)
        _ColorB ("Colour B", Color) = (0.300, 0.150, 0.700, 1)
        _ColorC ("Colour C", Color) = (0.950, 0.300, 0.550, 1)
        _ColorD ("Colour D", Color) = (1.000, 0.700, 0.350, 1)

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1
        _Vignette ("Vignette", Range(0, 1)) = 0.2
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
            float _Speed, _Phase, _Aspect;
            float _Scale, _Warp, _Bands, _Sharpness;
            float4 _ColorA, _ColorB, _ColorC, _ColorD;
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
                float t = BD_TAU * frac(cyc);
                float2 uv = IN.texcoord;
                float2 p = bdPos(uv, _Aspect, _Scale);

                // a slow warp walked once round a circle per cycle, so the bends breathe without a seam
                float2 w = float2(bdFbm(p * 0.7 + bdOrbit(cyc, 0.5, 0.0), 2.0),
                                  bdFbm(p * 0.7 + 5.2 + bdOrbit(cyc, 0.5, 0.31), 2.0)) - 0.5;
                float2 q = p + _Warp * w;

                // four interfering waves; every phase advances a whole number of turns per cycle
                float2 c = bdOrbit(cyc, 0.6, 0.17);
                float v = sin(q.x * 1.7 + t)
                        + sin(q.y * 2.1 - t)
                        + sin((q.x + q.y) * 1.3 + 2.0 * t)
                        + sin(length(q - c) * 2.6 - t);
                float u = 0.5 + 0.5 * sin(v * 0.785398 * _Bands);           // 0..1, _Bands sweeps per unit
                // sharpness pushes the ramp position toward the stops (hard bands)
                float s = u * 3.0;
                float stepped = (floor(s) + smoothstep(0.5 - 0.5 * (1.0 - _Sharpness), 0.5 + 0.5 * (1.0 - _Sharpness), frac(s))) / 3.0;
                u = lerp(u, stepped, _Sharpness);
                float3 col = bdRamp4(u, _ColorA.rgb, _ColorB.rgb, _ColorC.rgb, _ColorD.rgb);

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
