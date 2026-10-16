// ============================================================================
// BackdropSynthwave.shader — retro sun, mountain silhouettes, a neon grid rolling toward you
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic, _Speed
// is cycles per second). The grid scrolls exactly one row per cycle, so it loops without a seam. The sun is a
// _ColorC → _ColorD disc with the classic slits through its lower half; the sky runs _ColorA (top) to _ColorB
// (horizon); ridges are a dark fbm silhouette; grid lines glow _ColorD. `_UIBeat` pulses the sun and grid.
// ============================================================================

Shader "UI/Backdrop/Synthwave"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.35
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0

        [Header(Scene)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.0
        _Horizon ("Horizon height", Range(-0.4, 0.4)) = -0.05
        _SunSize ("Sun size", Range(0.05, 0.6)) = 0.3
        _GridDensity ("Grid density", Range(2, 24)) = 8
        _GridGlow ("Grid glow", Range(0, 3)) = 1.2
        _Mountains ("Mountains", Range(0, 1)) = 0.8
        _BeatAmount ("Beat reaction", Range(0, 1)) = 0.4

        [Header(Colour)]
        _ColorA ("Sky top", Color) = (0.050, 0.010, 0.120, 1)
        _ColorB ("Horizon", Color) = (0.650, 0.100, 0.450, 1)
        _ColorC ("Sun top", Color) = (1.000, 0.850, 0.250, 1)
        _ColorD ("Sun foot / grid", Color) = (1.000, 0.200, 0.600, 1)

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1
        _Vignette ("Vignette", Range(0, 1)) = 0.3
        _Grain ("Film grain", Range(0, 0.2)) = 0.02
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
            float _Scale, _Horizon, _SunSize, _GridDensity, _GridGlow, _Mountains, _BeatAmount;
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
                float2 uv = IN.texcoord;
                float2 p = bdPos(uv, _Aspect, _Scale);
                float y = p.y - _Horizon;
                float beat = _UIBeat * _BeatAmount;
                float px = fwidth(p.y) + 1e-4;

                float3 col;
                if (y > 0.0)
                {
                    // sky
                    col = lerp(_ColorB.rgb, _ColorA.rgb, saturate(y / 0.55));
                    // sun with slits through its lower half
                    float2 sc = float2(0.0, _SunSize * 0.62);
                    float r = _SunSize * (1.0 + beat * 0.08);
                    float d = length(float2(p.x, y) - sc) - r;
                    float disc = smoothstep(px, -px, d);
                    float sy = (y - sc.y) / r;                                   // -1 bottom .. 1 top
                    float3 sun = lerp(_ColorD.rgb, _ColorC.rgb, saturate(sy * 0.5 + 0.5));
                    float slitK = saturate(-sy * 1.2 + 0.1);
                    float slit = step(frac(sy * 4.5 + 0.2), slitK * 0.55) * step(sy, 0.15);
                    col = lerp(col, sun, disc * (1.0 - slit));
                    col += sun * 0.35 * exp(-max(d, 0.0) * 6.0) * (1.0 + beat);  // haze
                    // ridges in front of the sun
                    float ridge = 0.06 + 0.13 * bdFbm(float2(p.x * 1.6 + 3.0, 1.7), 4.0) + 0.05 * bdNoise(float2(p.x * 7.0, 2.0));
                    float m = smoothstep(ridge + px, ridge - px, y) * _Mountains;
                    float3 mc = lerp(_ColorA.rgb * 0.5, _ColorB.rgb * 0.35, saturate(y / ridge));
                    col = lerp(col, mc, m);
                }
                else
                {
                    // ground: a perspective grid rolling one row per cycle
                    float z = 1.0 / max(-y, 0.002);
                    float gx = p.x * z * _GridDensity * 0.08;
                    float gz = z * _GridDensity * 0.08 + frac(cyc);
                    float lx = abs(frac(gx) - 0.5);
                    float lz = abs(frac(gz) - 0.5);
                    float w = fwidth(gx) + fwidth(gz) + 1e-4;
                    float line_ = max(smoothstep(0.5 - w * 1.5, 0.5, lx), smoothstep(0.5 - w * 1.5, 0.5, lz));
                    float fade = saturate(-y * 3.0);
                    col = lerp(_ColorA.rgb * 0.35, _ColorB.rgb * 0.25, saturate(1.0 + y * 2.0));
                    col += _ColorD.rgb * line_ * _GridGlow * fade * (1.0 + beat);
                    col += _ColorD.rgb * 0.25 * exp(y * 14.0);                    // horizon glow on the ground
                }

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
