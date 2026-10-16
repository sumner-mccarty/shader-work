// ============================================================================
// BackdropLava.shader — a lava lamp: wax blobs rising, merging, falling
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic, _Speed
// is cycles per second). Eight metaballs each travel a whole number of up-and-down trips per cycle, so the
// lamp loops without a seam; where their summed field passes 1 they merge into wax. Wax shades from _ColorC
// (thin) to _ColorD (core) with a soft rim light; the liquid glows _ColorB near wax over a _ColorA ground.
// `_UIBeat` swells the wax by `_BeatAmount`.
// ============================================================================

Shader "UI/Backdrop/Lava"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.025
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0

        [Header(Lava)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.0
        _BlobSize ("Blob size", Range(0.03, 0.4)) = 0.1
        _Merge ("Merge (gooeyness)", Range(0.3, 2)) = 1.0
        _Rim ("Rim light", Range(0, 1)) = 0.6
        _Glow ("Liquid glow", Range(0, 2)) = 0.8
        _BeatAmount ("Beat reaction", Range(0, 1)) = 0.3

        [Header(Colour)]
        _ColorA ("Liquid", Color) = (0.180, 0.020, 0.120, 1)
        _ColorB ("Liquid glow", Color) = (0.800, 0.120, 0.350, 1)
        _ColorC ("Wax", Color) = (1.000, 0.450, 0.150, 1)
        _ColorD ("Wax core", Color) = (1.000, 0.850, 0.300, 1)

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1
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
            float _Scale, _BlobSize, _Merge, _Rim, _Glow, _BeatAmount;
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

            float field(float2 p, float cyc, float r)
            {
                float f = 0.0;
                [unroll] for (int i = 0; i < 8; i++)
                {
                    float fi = (float)i;
                    float hx = bdHash21(float2(fi, 1.7));
                    float hp = bdHash21(float2(fi, 9.2));
                    float trips = 1.0 + floor(bdHash21(float2(fi, 4.4)) * 2.0);       // 1 or 2 round trips per cycle
                    float y = -cos(BD_TAU * (cyc * trips + hp)) * 0.62;
                    float x = (hx - 0.5) * 1.5 + 0.08 * sin(BD_TAU * (cyc * trips + hp * 3.0));
                    float rr = r * (0.6 + 0.8 * bdHash21(float2(fi, 2.3)));
                    float2 d = p - float2(x, y);
                    f += rr * rr / max(dot(d, d), 1e-4);
                }
                return f;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float cyc = _Time.y * _Speed + _Phase;
                float2 uv = IN.texcoord;
                float2 p = bdPos(uv, _Aspect, _Scale);
                float r = _BlobSize * (1.0 + _UIBeat * _BeatAmount * 0.35);
                float f = field(p, cyc, r);
                float e = 0.02;
                float fx = field(p + float2(e, 0), cyc, r) - f;
                float fy = field(p + float2(0, e), cyc, r) - f;

                float th = 1.0 / max(_Merge, 0.05);
                float edge = min(fwidth(f), th * 0.25) + 1e-4;
                float wax = smoothstep(th - edge, th + edge, f);
                float core = saturate((f - th) / (th * 3.0));
                float3 waxCol = lerp(_ColorC.rgb, _ColorD.rgb, core);
                // rim: the field gradient leans toward the lamp at the top of the screen
                float2 n = normalize(float2(fx, fy) + 1e-5);
                waxCol += _Rim * 0.35 * saturate(dot(-n, float2(-0.3, 0.95))) * (1.0 - core);

                float3 liquid = lerp(_ColorA.rgb, _ColorA.rgb * 1.6, uv.y);
                liquid += _ColorB.rgb * _Glow * saturate(f / th) * 0.45;
                float3 col = lerp(liquid, waxCol, wax);

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
