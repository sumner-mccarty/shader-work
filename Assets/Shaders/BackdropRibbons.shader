// ============================================================================
// BackdropRibbons.shader — flowing colour ribbons (silk / aurora / rainbow bands)
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic,
// _Speed is cycles per second). Up to 6 ribbons undulate across a base colour; each ribbon's colour
// slides along its length through the four-colour palette (the rainbow-slider look), and its edges are
// as soft or as crisp as _Softness says. Phases advance a whole number of turns per cycle, so a ribbon
// waves forever without a seam.
//
// Self-contained: no widget includes, no lighting, no clip rect — a backdrop fills its quad.
// ============================================================================

Shader "UI/Backdrop/Ribbons"
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
        _Seed ("Layout seed", Range(0, 64)) = 5

        [Header(Ribbons)]
        _Count ("Ribbon count", Range(1, 6)) = 4
        _Thickness ("Thickness (picture heights)", Range(0.02, 0.6)) = 0.14
        _Softness ("Edge softness", Range(0.02, 1)) = 0.45
        _Wave ("Wave height", Range(0, 0.6)) = 0.18
        _WaveFreq ("Wave frequency", Range(0.3, 6)) = 1.4
        _Tilt ("Tilt (radians)", Range(-1.2, 1.2)) = -0.25
        _Spread ("Vertical spread", Range(0.1, 1.2)) = 0.8
        _Glow ("Glow (additive bleed)", Range(0, 2)) = 0.6
        _Opacity ("Ribbon opacity", Range(0, 1)) = 0.9

        [Header(Colour)]
        _Base ("Base", Color) = (0.020, 0.030, 0.080, 1)
        _ColorA ("Ribbon A", Color) = (0.100, 0.900, 0.650, 1)
        _ColorB ("Ribbon B", Color) = (0.350, 0.400, 1.000, 1)
        _ColorC ("Ribbon C", Color) = (0.900, 0.250, 0.750, 1)
        _ColorD ("Ribbon D", Color) = (1.000, 0.650, 0.250, 1)
        _ColorSpan ("Colour span along a ribbon (picture heights per palette)", Range(0.2, 6)) = 2.2

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
            float _Speed, _Phase, _Aspect, _Seed;
            float _Count, _Thickness, _Softness, _Wave, _WaveFreq, _Tilt, _Spread, _Glow, _Opacity;
            float4 _Base, _ColorA, _ColorB, _ColorC, _ColorD;
            float _ColorSpan;
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
                // rotate the whole composition by the tilt
                float cs = cos(_Tilt), sn = sin(_Tilt);
                p = float2(p.x * cs - p.y * sn, p.x * sn + p.y * cs);

                float3 col = _Base.rgb;
                float3 glow = float3(0.0, 0.0, 0.0);
                float soft = max(_Softness, 0.02) * _Thickness;

                [unroll]
                for (int i = 0; i < 6; i++)
                {
                    float on = saturate(_Count - (float)i);
                    float2 h = bdHash22(float2((float)i * 1.73 + _Seed, 2.9 + _Seed * 0.57));
                    // the ribbon's centre line: a tilted baseline plus two waves, phases in whole turns per cycle
                    float y0 = (((float)i + 0.5) / 6.0 - 0.5) * 2.0 * _Spread * (0.6 + 0.4 * h.x) + (h.y - 0.5) * 0.2;
                    float k = _WaveFreq * (0.8 + 0.5 * h.x);
                    float t1 = BD_TAU * (cyc * (1.0 + (float)(i & 1)) + h.x);
                    float t2 = BD_TAU * (-cyc * (1.0 + (float)((i + 1) & 1)) + h.y);
                    float cl = y0 + _Wave * (sin(p.x * k + t1) + 0.45 * sin(p.x * k * 2.3 + t2));
                    float d = abs(p.y - cl);
                    float m = smoothstep(_Thickness + soft, _Thickness - soft, d) * on * _Opacity;
                    // colour along the ribbon: the palette slid by position and a per-ribbon offset, breathing once per cycle
                    float u = 0.5 + 0.5 * sin(BD_TAU * (p.x / (_ColorSpan * 2.0) + h.y + cyc));
                    float3 rc = bdRamp4(u, _ColorA.rgb, _ColorB.rgb, _ColorC.rgb, _ColorD.rgb);
                    col = lerp(col, rc, m);
                    glow += rc * exp(-d / max(_Thickness * 2.5, 1e-3)) * on;
                }
                col += glow * _Glow * 0.12;

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
