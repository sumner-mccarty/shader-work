// ============================================================================
// BackdropSplotch.shader — drifting colour splotches (liquid colour pools)
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic,
// _Speed is cycles per second). Up to 8 soft blobs of the four palette colours drift on small closed
// loops over a base colour; a noise warp makes every edge wobble like liquid. _Softness is the whole
// character knob: wide = a smooth mesh-gradient, narrow = crisp coloured pools whose EDGES a glass lens
// can bend (a lens refracts structure, not a smooth gradient).
//
// Each blob i has its own seed: a home position, a radius, two integer harmonics (how many loops it
// makes per cycle) and a palette colour (i mod 4). Everything is a Properties entry.
//
// Self-contained: no widget includes, no lighting, no clip rect — a backdrop fills its quad.
// ============================================================================

Shader "UI/Backdrop/Splotch"
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
        _Seed ("Layout seed", Range(0, 64)) = 3

        [Header(Blobs)]
        _Count ("Blob count", Range(1, 8)) = 6
        _Size ("Blob radius (picture heights)", Range(0.05, 1.2)) = 0.34
        _SizeVar ("Radius variation", Range(0, 1)) = 0.5
        _Spread ("Layout spread", Range(0.2, 1.5)) = 0.9
        _Drift ("Drift radius", Range(0, 0.6)) = 0.16
        _Softness ("Edge softness", Range(0.005, 1)) = 0.30
        _Warp ("Edge wobble (noise warp)", Range(0, 1)) = 0.22
        _WarpScale ("Wobble scale", Range(0.5, 8)) = 2.4
        _Opacity ("Blob opacity", Range(0, 1)) = 0.92
        _Merge ("Overlap blending (0 stack, 1 add)", Range(0, 1)) = 0.35

        [Header(Colour)]
        _Base ("Base", Color) = (0.030, 0.040, 0.100, 1)
        _ColorA ("Blob A", Color) = (0.070, 0.650, 0.800, 1)
        _ColorB ("Blob B", Color) = (0.150, 0.300, 0.950, 1)
        _ColorC ("Blob C", Color) = (0.550, 0.200, 0.900, 1)
        _ColorD ("Blob D", Color) = (0.950, 0.350, 0.550, 1)
        _ColorFlow ("Colour breathing (each blob drifts toward its neighbour colour)", Range(0, 1)) = 0.0
        _EdgeShade ("Edge shade (inner rim)", Range(0, 1)) = 0.0

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
            float _Count, _Size, _SizeVar, _Spread, _Drift, _Softness, _Warp, _WarpScale, _Opacity, _Merge;
            float4 _Base, _ColorA, _ColorB, _ColorC, _ColorD;
            float _ColorFlow, _EdgeShade;
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
                float2 p = (uv - 0.5) * float2(asp, 1.0);          // 1 unit = the picture's height

                // liquid edges: the sample point itself is pushed round by an orbiting noise field
                float2 w = float2(bdNoise(p * _WarpScale + bdOrbit(cyc, 0.7, 0.00)),
                                  bdNoise(p * _WarpScale + 5.2 + bdOrbit(cyc, 0.7, 0.29))) - 0.5;
                float2 q = p + _Warp * 0.5 * w;

                float3 col = _Base.rgb;
                float soft = max(_Softness, 0.005);
                float3 pal[4];
                pal[0] = _ColorA.rgb; pal[1] = _ColorB.rgb; pal[2] = _ColorC.rgb; pal[3] = _ColorD.rgb;

                [unroll]
                for (int i = 0; i < 8; i++)
                {
                    float on = saturate(_Count - (float)i);
                    float2 h0 = bdHash22(float2((float)i * 1.37 + _Seed, 4.1 + _Seed * 0.71));
                    float2 h1 = bdHash22(float2((float)i * 2.11 + 9.3, _Seed * 1.13 + 2.7));
                    // home position, spread over the picture
                    float2 home = (h0 - 0.5) * float2(asp, 1.0) * _Spread;
                    // a small closed loop; the harmonics are INTEGER turns per cycle, so it is exactly periodic
                    float fx = 1.0 + floor(h1.x * 2.99);
                    float fy = 1.0 + floor(h1.y * 2.99);
                    float2 c = home + _Drift * float2(sin(BD_TAU * (cyc * fx + h0.x)), cos(BD_TAU * (cyc * fy + h0.y)));
                    float r = _Size * (1.0 - _SizeVar * 0.5 + _SizeVar * h1.x);
                    float d = length(q - c);
                    float m = smoothstep(r + soft * r, r - soft * r, d) * on * _Opacity;
                    // the colour: palette slot i, breathing toward slot i+1 and back once per cycle (periodic)
                    float3 a = pal[i & 3];
                    float3 b = pal[(i + 1) & 3];
                    float3 bc = lerp(a, b, _ColorFlow * (0.5 + 0.5 * sin(BD_TAU * (cyc + h0.y))));
                    float shade = 1.0 - _EdgeShade * smoothstep(r * 0.55, r, d);
                    col = lerp(col, bc * shade, m);                                   // stack
                    col += bc * m * m * _Merge * 0.5;                                 // overlap glows (add)
                }

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
