// ============================================================================
// BackdropContours.shader — topographic contour lines over a slowly reshaping terrain
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic,
// _Speed is cycles per second). A height field (fbm, sampled along two orbits so it reshapes and returns
// each cycle) is drawn as iso-lines `_Count` per unit height, every `_MajorEvery`-th one heavier, over a
// height-tinted fill. Lines are anti-aliased by their own derivative, so they stay crisp at any size.
// ============================================================================

Shader "UI/Backdrop/Contours"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.02
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0

        [Header(Terrain)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.4
        _Detail ("Detail (fbm octaves)", Range(1, 4)) = 3
        _Drift ("Reshape amount", Range(0, 1.5)) = 0.5

        [Header(Lines)]
        _Count ("Lines per unit height", Range(2, 40)) = 14
        _LineWidth ("Line width (screen px)", Range(0.5, 4)) = 1.1
        _MajorEvery ("Heavier line every", Range(0, 10)) = 5
        _LineColor ("Line colour", Color) = (0.550, 0.950, 0.850, 1)
        _LineStrength ("Line strength", Range(0, 1)) = 0.8

        [Header(Fill)]
        _ColorA ("Low", Color) = (0.020, 0.060, 0.080, 1)
        _ColorB ("Mid low", Color) = (0.030, 0.140, 0.160, 1)
        _ColorC ("Mid high", Color) = (0.060, 0.220, 0.220, 1)
        _ColorD ("High", Color) = (0.120, 0.300, 0.260, 1)

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
            float _Speed, _Phase, _Aspect;
            float _Scale, _Detail, _Drift;
            float _Count, _LineWidth, _MajorEvery, _LineStrength;
            float4 _LineColor, _ColorA, _ColorB, _ColorC, _ColorD;
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

                // height: two fbm samples walked round circles (once per cycle) — the terrain reshapes and returns
                float h = 0.75 * bdFbm(p + bdOrbit(cyc, _Drift, 0.0), _Detail)
                        + 0.25 * bdFbm(p * 1.9 + 3.7 + bdOrbit(cyc, _Drift * 0.7, 0.41), _Detail);

                float3 col = bdRamp4(smoothstep(0.2, 0.8, h), _ColorA.rgb, _ColorB.rgb, _ColorC.rgb, _ColorD.rgb);

                float f = h * _Count;
                float w = max(fwidth(f), 1e-5);
                float d = abs(frac(f + 0.5) - 0.5) / w;               // screen pixels from the nearest iso-line
                float idx = floor(f + 0.5);
                float major = (_MajorEvery >= 1.0 && fmod(abs(idx), max(round(_MajorEvery), 1.0)) < 0.5) ? 1.0 : 0.0;
                float width = _LineWidth * (1.0 + major * 0.9);
                float ln = saturate(1.0 - (d - width * 0.5));
                col = lerp(col, _LineColor.rgb, ln * _LineStrength * (0.55 + 0.45 * major));

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
