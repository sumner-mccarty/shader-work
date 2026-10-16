// ============================================================================
// BackdropNebula.shader — glowing gas clouds and twinkling stars
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic, _Speed
// is cycles per second). Twice domain-warped fbm (the warp walked once round a circle per cycle) picks a
// colour from the four-stop ramp; density thins it into wisps over a _ColorA void; two layers of stars
// twinkle a whole number of times per cycle. `_UIBeat` lifts the cloud glow.
// ============================================================================

Shader "UI/Backdrop/Nebula"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.015
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0

        [Header(Nebula)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.4
        _Warp ("Swirl", Range(0, 3)) = 1.4
        _Density ("Density", Range(0, 1)) = 0.55
        _Glow ("Glow", Range(0, 3)) = 1.1
        _Stars ("Stars", Range(0, 1)) = 0.7
        _BeatAmount ("Beat reaction", Range(0, 1)) = 0.3

        [Header(Colour)]
        _ColorA ("Void", Color) = (0.010, 0.010, 0.040, 1)
        _ColorB ("Gas deep", Color) = (0.150, 0.050, 0.450, 1)
        _ColorC ("Gas mid", Color) = (0.050, 0.500, 0.700, 1)
        _ColorD ("Gas hot", Color) = (1.000, 0.450, 0.650, 1)

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1.1
        _Vignette ("Vignette", Range(0, 1)) = 0.35
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
            float _Scale, _Warp, _Density, _Glow, _Stars, _BeatAmount;
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

            float stars(float2 p, float density, float t, float seed)
            {
                float2 cell = floor(p);
                float h = bdHash21(cell + seed);
                float2 o = bdHash22(cell + seed * 1.3) - 0.5;
                float d = length(frac(p) - 0.5 - o * 0.6);
                float tw = 0.65 + 0.35 * sin(t * (1.0 + floor(h * 3.0)) + h * 50.0);
                return smoothstep(0.07, 0.0, d) * step(1.0 - density, h) * tw;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float cyc = _Time.y * _Speed + _Phase;
                float t = BD_TAU * frac(cyc);
                float2 uv = IN.texcoord;
                float2 p = bdPos(uv, _Aspect, _Scale);

                float2 q = float2(bdFbm(p + bdOrbit(cyc, 0.6, 0.0), 4.0), bdFbm(p + 5.2 + bdOrbit(cyc, 0.6, 0.4), 4.0));
                float2 r = float2(bdFbm(p + _Warp * q + 1.7, 4.0), bdFbm(p + _Warp * q + 9.2, 4.0));
                float n = bdFbm(p + _Warp * r, 4.0);
                float dens = smoothstep(1.0 - _Density - 0.15, 1.0 - _Density + 0.35, n) * (0.4 + 0.6 * length(r));
                float3 gas = bdRamp4(saturate(n * 1.3 - 0.1 + r.x * 0.3), _ColorA.rgb, _ColorB.rgb, _ColorC.rgb, _ColorD.rgb);
                float3 col = _ColorA.rgb;
                col += _ColorD.rgb * stars(p * 18.0, _Stars * 0.25, t, 3.0) * (1.0 - dens);
                col += float3(1, 1, 1) * stars(p * 46.0, _Stars * 0.35, t, 7.0) * 0.6 * (1.0 - dens);
                col = lerp(col, gas * _Glow * (1.0 + _UIBeat * _BeatAmount), dens);

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
