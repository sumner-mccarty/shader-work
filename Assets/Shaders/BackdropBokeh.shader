// ============================================================================
// BackdropBokeh.shader — drifting out-of-focus lights
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic,
// _Speed is cycles per second). Up to 12 soft discs of light, each orbiting its own anchor a whole
// number of times per cycle and pulsing on a whole-turn phase, over a vertical base gradient. Discs
// screen-blend (overlaps glow instead of clipping) and carry the slightly brighter rim of a real lens.
// ============================================================================

Shader "UI/Backdrop/Bokeh"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.03
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0
        _Seed ("Layout seed", Range(0, 64)) = 7

        [Header(Lights)]
        _Count ("Light count", Range(1, 12)) = 12
        _Size ("Radius (picture heights)", Range(0.02, 0.5)) = 0.17
        _SizeVar ("Radius variation", Range(0, 1)) = 0.5
        _Spread ("Spread", Range(0.2, 1.5)) = 1
        _Drift ("Drift radius", Range(0, 0.5)) = 0.12
        _Softness ("Edge softness", Range(0.01, 1)) = 0.25
        _Rim ("Lens rim", Range(0, 1)) = 0.35
        _Intensity ("Intensity", Range(0, 2)) = 0.95
        _Pulse ("Pulse", Range(0, 1)) = 0.3

        [Header(Colour)]
        _BaseTop ("Base top", Color) = (0.040, 0.040, 0.120, 1)
        _BaseBottom ("Base bottom", Color) = (0.140, 0.050, 0.160, 1)
        _ColorA ("Light A", Color) = (1.000, 0.700, 0.350, 1)
        _ColorB ("Light B", Color) = (1.000, 0.350, 0.550, 1)
        _ColorC ("Light C", Color) = (0.450, 0.550, 1.000, 1)
        _ColorD ("Light D", Color) = (0.400, 1.000, 0.850, 1)

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1
        _Vignette ("Vignette", Range(0, 1)) = 0.3
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
            float _Speed, _Phase, _Aspect, _Seed;
            float _Count, _Size, _SizeVar, _Spread, _Drift, _Softness, _Rim, _Intensity, _Pulse;
            float4 _BaseTop, _BaseBottom, _ColorA, _ColorB, _ColorC, _ColorD;
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
                float asp = _Aspect > 0.01 ? _Aspect : _ScreenParams.x / max(_ScreenParams.y, 1.0);
                float2 p = (uv - 0.5) * float2(asp, 1.0);

                float3 col = lerp(_BaseBottom.rgb, _BaseTop.rgb, uv.y);
                float3 light = float3(0.0, 0.0, 0.0);

                [unroll]
                for (int i = 0; i < 12; i++)
                {
                    float on = saturate(_Count - (float)i);
                    float2 h = bdHash22(float2((float)i * 2.31 + _Seed, 4.7 + _Seed * 0.43));
                    float h3 = bdHash21(float2((float)i + _Seed * 1.7, 9.1));
                    // an anchor spread over the picture, an orbit of 1 or 2 turns per cycle (either way round)
                    float turns = (h3 > 0.5 ? 1.0 : -1.0) * (1.0 + floor(h.x * 1.99));
                    float2 c = (h - 0.5) * float2(asp, 1.0) * _Spread
                             + bdOrbit(frac(cyc) * turns, _Drift * (0.4 + 0.6 * h3), h.y);
                    float r = _Size * (1.0 - _SizeVar * h3);
                    float d = length(p - c);
                    float disc = smoothstep(r, r * (1.0 - _Softness), d);
                    float rim = smoothstep(r * 0.55, r, d) * disc;
                    float pulse = 1.0 - _Pulse * (0.5 + 0.5 * sin(BD_TAU * (frac(cyc) * (1.0 + floor(h3 * 2.99)) + h.x)));
                    float3 lc = bdRamp4(frac(h.y + h3 * 0.37), _ColorA.rgb, _ColorB.rgb, _ColorC.rgb, _ColorD.rgb);
                    light = 1.0 - (1.0 - light) * (1.0 - saturate(lc * (disc * (0.55 + 0.45 * h.x) + rim * _Rim) * _Intensity * pulse * on));
                }
                col = 1.0 - (1.0 - col) * (1.0 - light);

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
