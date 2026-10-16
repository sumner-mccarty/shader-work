// ============================================================================
// BackdropAurora.shader — northern-light curtains over a starry sky
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic, _Speed
// is cycles per second). Three curtains hang across the sky: each is a band whose bottom edge is sharp and
// whose top fades upward, pleated by vertical rays and swayed by a warp walked once round a circle per cycle.
// Colour runs from _ColorB at a curtain's foot to _ColorC at its top; _ColorA is the night, _ColorD the
// stars. `_UIBeat` (a global the app pulses on hits, 0..1) brightens the curtains by `_BeatAmount`.
// ============================================================================

Shader "UI/Backdrop/Aurora"
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

        [Header(Aurora)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.3
        _Height ("Curtain height", Range(0.1, 1.2)) = 0.55
        _Sway ("Sway", Range(0, 2)) = 0.8
        _Rays ("Rays", Range(0, 1)) = 0.6
        _Glow ("Glow", Range(0, 3)) = 1.3
        _Stars ("Stars", Range(0, 1)) = 0.6
        _BeatAmount ("Beat reaction", Range(0, 1)) = 0.35

        [Header(Colour)]
        _ColorA ("Night", Color) = (0.010, 0.020, 0.060, 1)
        _ColorB ("Curtain foot", Color) = (0.150, 0.950, 0.550, 1)
        _ColorC ("Curtain top", Color) = (0.550, 0.250, 0.950, 1)
        _ColorD ("Stars", Color) = (0.850, 0.900, 1.000, 1)

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1
        _Vignette ("Vignette", Range(0, 1)) = 0.3
        _Grain ("Film grain", Range(0, 0.2)) = 0
    }

    SubShader
    {
        Tags { "Queue"="Background" "IgnoreProjector"="True" "RenderType"="Opaque" "PreviewType"="Plane" }
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

            struct appdata_t { float4 vertex : POSITION; float2 texcoord : TEXCOORD0; };
            struct v2f { float4 vertex : SV_POSITION; float2 texcoord : TEXCOORD0; };

            fixed4 _Color;
            float _Speed, _Phase, _Aspect;
            float _Scale, _Height, _Sway, _Rays, _Glow, _Stars, _BeatAmount;
            float4 _ColorA, _ColorB, _ColorC, _ColorD;
            float _Brightness, _Contrast, _Saturation, _Vignette, _Grain;
            float _UIBeat;

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float cyc = _Time.y * _Speed + _Phase;
                float t = BD_TAU * frac(cyc);
                float2 uv = IN.texcoord;
                float2 p = bdPos(uv, _Aspect, _Scale);

                // the night: deeper at the top, a little glow near the horizon
                float3 col = lerp(_ColorA.rgb * 1.6, _ColorA.rgb * 0.6, saturate(uv.y));

                // stars, twinkling with a whole number of turns per cycle
                float2 sp = p * 22.0;
                float2 cell = floor(sp);
                float h = bdHash21(cell + 3.1);
                float2 o = bdHash22(cell) - 0.5;
                float sd = length(frac(sp) - 0.5 - o * 0.6);
                float tw = 0.6 + 0.4 * sin(t * (1.0 + floor(h * 3.0)) + h * 40.0);
                float star = smoothstep(0.08, 0.0, sd) * step(0.82, h) * tw * _Stars;
                col += _ColorD.rgb * star * saturate(uv.y * 1.4);

                float beat = 1.0 + _UIBeat * _BeatAmount * 1.5;
                float3 glow = float3(0, 0, 0);
                [unroll] for (int k = 0; k < 3; k++)
                {
                    float fk = (float)k;
                    float2 orb = bdOrbit(cyc, 0.5, fk * 0.31);
                    float sway = (bdFbm(float2(p.x * 0.6 + fk * 7.3, fk) + orb, 3.0) - 0.5) * _Sway;
                    float base = -0.05 + fk * 0.12 + sway * 0.35 + 0.08 * sin(p.x * (1.2 + fk * 0.4) + t + fk * 2.0);
                    float y = p.y / max(_Scale, 0.01) * 1.0 - base;           // height above this curtain's foot
                    float foot = smoothstep(-0.03, 0.02, y);
                    float top = exp(-max(y, 0.0) / max(_Height * (0.7 + 0.3 * fk), 0.05));
                    float rays = lerp(1.0, 0.55 + 0.45 * bdNoise(float2(p.x * 9.0 + sway * 6.0 + fk * 13.0, y * 0.6 + fk)), _Rays);
                    float band = foot * top * rays;
                    float3 c = lerp(_ColorB.rgb, _ColorC.rgb, saturate(y / max(_Height, 0.05)));
                    glow += c * band * (0.55 - fk * 0.12);
                }
                col += glow * _Glow * beat;

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
