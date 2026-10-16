// ============================================================================
// BackdropRain.shader — rain on a window over blurred city lights
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic, _Speed
// is cycles per second). Behind the glass: a soft field of out-of-focus lights (_ColorA night, _ColorB/C/D
// bokeh). On the glass: columns of drops each sliding down a whole number of times per cycle with a trail of
// beads behind them, plus static condensation. Every drop is a little lens — the lights behind are sampled
// through it, refracted and sharpened — which is what makes it read as water. `_UIBeat` flares the lights.
// ============================================================================

Shader "UI/Backdrop/Rain"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15

        [Header(Motion)]
        _Speed ("Speed (cycles per second)", Range(0, 0.5)) = 0.06
        _Phase ("Phase (cycles, scrubs a still)", Range(0, 1)) = 0
        _Aspect ("Aspect override (0 = from the target)", Float) = 0

        [Header(Rain)]
        _Scale ("Scale (features per picture height)", Range(0.2, 8)) = 1.0
        _Drops ("Sliding drops", Range(0, 1)) = 0.7
        _Mist ("Condensation", Range(0, 1)) = 0.45
        _Lights ("City lights", Range(0, 1)) = 0.7
        _Refract ("Refraction", Range(0, 0.3)) = 0.12
        _BeatAmount ("Beat reaction", Range(0, 1)) = 0.3

        [Header(Colour)]
        _ColorA ("Night", Color) = (0.020, 0.030, 0.060, 1)
        _ColorB ("Light warm", Color) = (1.000, 0.550, 0.200, 1)
        _ColorC ("Light cool", Color) = (0.200, 0.550, 1.000, 1)
        _ColorD ("Light neon", Color) = (1.000, 0.200, 0.550, 1)

        [Header(Finish)]
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Contrast ("Contrast", Range(0.5, 2)) = 1
        _Saturation ("Saturation", Range(0, 2)) = 1
        _Vignette ("Vignette", Range(0, 1)) = 0.3
        _Grain ("Film grain", Range(0, 0.2)) = 0.015
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
            float _Scale, _Drops, _Mist, _Lights, _Refract, _BeatAmount;
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

            // the out-of-focus city behind the glass; `sharp` 0 = bokeh blur, 1 = through a drop (crisper)
            float3 city(float2 p, float cyc, float sharp)
            {
                float3 col = lerp(_ColorA.rgb * 0.6, _ColorA.rgb * 1.8, saturate(0.5 - p.y * 0.6));
                float flare = 1.0 + _UIBeat * _BeatAmount * 0.8;
                [unroll] for (int layer = 0; layer < 2; layer++)
                {
                    float fl = (float)layer;
                    float2 g = p * (2.2 + fl * 1.6) + float2(fl * 7.1, 0.0);
                    float2 cell = floor(g);
                    [unroll] for (int y = -1; y <= 1; y++)
                    [unroll] for (int x = -1; x <= 1; x++)
                    {
                        float2 c = cell + float2(x, y);
                        float h = bdHash21(c + fl * 13.0);
                        if (h > _Lights * 0.9) continue;
                        float2 o = bdHash22(c + fl * 5.0) * 0.8 + 0.1;
                        float rr = 0.18 + 0.22 * bdHash21(c + 3.3);
                        float d = length(g - c - o);
                        float soft = lerp(0.22, 0.04, sharp);
                        float disc = smoothstep(rr + soft, rr - soft, d) * (0.55 - fl * 0.2);
                        float tw = 0.75 + 0.25 * sin(BD_TAU * (cyc * (1.0 + floor(h * 3.0)) + h));
                        float3 lc = h < 0.33 ? _ColorB.rgb : (h < 0.66 ? _ColorC.rgb : _ColorD.rgb);
                        col += lc * disc * tw * flare;
                    }
                }
                return col;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float cyc = _Time.y * _Speed + _Phase;
                float2 uv = IN.texcoord;
                float2 p = bdPos(uv, _Aspect, _Scale);

                // drops in three layers (big and slow, medium, small and quick): columns of cells; each drop
                // slides down a whole number of times per cycle, wobbling, leaving a wet trail that beads
                float2 n = float2(0, 0);
                float drop = 0.0, dropEdge = 0.0, bead = 0.0, trail = 0.0, lip = 0.0;
                [unroll] for (int L = 0; L < 3; L++)
                {
                    float fl = (float)L;
                    float cx = 2.2 + fl * 1.9, cyy = 0.8 + fl * 0.7;
                    float2 g = p * float2(cx, cyy) + float2(fl * 3.7, fl * 1.3);
                    float colId = floor(g.x) + fl * 100.0;
                    float hc = bdHash21(float2(colId, 4.2));
                    float present = step(hc, _Drops);
                    float trips = 1.0 + floor(hc * 2.0) + fl;
                    float fy = frac(g.y + cyc * trips + hc * 7.0);
                    float x = frac(g.x) - 0.5 - 0.12 * sin(fy * 9.0 + hc * 20.0) * (1.0 - fy);
                    float2 dp = float2(x / cx, (fy - 0.35) / cyy);
                    float dropR = (0.03 + 0.02 * hc) * (1.0 - fl * 0.28);
                    float dd = length(dp * float2(1.0, 0.82)) - dropR;
                    float d1 = smoothstep(0.004, -0.004, dd) * present;
                    n += normalize(dp + 1e-4) * saturate(1.0 - (dd + dropR) / dropR) * d1;
                    drop = max(drop, d1);
                    dropEdge = max(dropEdge, d1 * smoothstep(-0.012, 0.0, dd));
                    lip = max(lip, d1 * saturate(dp.y / dropR));
                    float above = fy - 0.35;
                    float tr = smoothstep(0.006, 0.0, abs(dp.x)) * step(0.0, above) * smoothstep(0.65, 0.0, above) * present;
                    trail = max(trail, tr);
                    float bg2 = frac(fy * 7.0 + hc * 3.0);
                    float bd = smoothstep(0.011, 0.006, length(float2(dp.x, (bg2 - 0.5) / (7.0 * cyy)))) * step(0.0, above) * present
                             * step(bdHash21(float2(colId, floor(fy * 7.0 + hc * 3.0))), 0.4) * smoothstep(0.8, 0.1, above);
                    n += normalize(float2(dp.x, bg2 - 0.5) + 1e-4) * bd * 0.6;
                    bead = max(bead, bd);
                }

                // static condensation: fine, faint, everywhere
                float2 mg = p * 30.0;
                float2 mc = floor(mg);
                float mh = bdHash21(mc + 2.0);
                float2 mo = bdHash22(mc) - 0.5;
                float2 md = frac(mg) - 0.5 - mo * 0.5;
                float mist = smoothstep(0.16, 0.06, length(md)) * step(1.0 - _Mist * 0.45, mh);
                n += md * 0.5 * mist;
                float wet = saturate(drop + bead + trail * 0.45 + mist * 0.35);

                float3 bg = city(p, cyc, 0.0);
                // through a drop the city is flipped, sharper and a little brighter — a lens
                float3 through = city(p - n * _Refract * 2.0, cyc, 1.0);
                float3 col = lerp(bg, through * 1.2 + 0.02, wet);
                // a highlight on each drop's upper lip and a thin dark meniscus at its edge
                col += 0.22 * lip * lip;
                col *= 1.0 - 0.22 * dropEdge;

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
