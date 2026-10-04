// ============================================================================
// LoadingPads.shader — the boot splash's indeterminate "working" mark, redone as a pure
// function of _Time (2026-09-22, user direction).
//
// v1 of this drove four Image components from a MonoBehaviour Update(): C# state that could
// only advance on an Update() tick, which cannot run while the main thread is blocked building
// a workspace behind the splash — a stalled step sequencer resuming after a skipped beat reads
// as WRONG (a pad stuck lit), not just slow.
//
// v2 moved the pattern into this shader but kept it STEP-TRIGGERED: every 1/4 second, hash the
// step index to pick one cell, flash it, let it decay. That is still a discrete event with a
// discrete moment it happens at — and boot still isn't perfectly smooth even chunked, so the
// remaining uneven gaps between rendered frames landed on step boundaries unevenly too: some
// gaps swallowed one step, some swallowed several, and the result read as "spastic" rather than
// as a groove (2026-09-22 user report).
//
// v3 (this version) has no discrete events at all. Every cell's brightness is
// `pow(0.5 + 0.5*sin(_Time.y * freq + phase), power)` — a smooth, continuously-varying value
// with its own frequency and phase per cell. There is no "step" to land on or miss: sampled at
// ANY instant, for ANY two instants however far apart, the value in between was exactly what a
// smooth sine implies. A ragged sequence of rendered frames reads as a ragged FRAME RATE (still
// true, still not this shader's to fix — nothing can make a blocked main thread present more
// frames), not as a wrong or stuttering PATTERN.
// ============================================================================

Shader "UI/LoadingPads"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _Color0 ("Pad Color 0", Color) = (1, 0.30, 0.36, 1)
        _Color1 ("Pad Color 1", Color) = (0.25, 0.95, 0.62, 1)
        _Color2 ("Pad Color 2", Color) = (1, 0.80, 0.20, 1)
        _Color3 ("Pad Color 3", Color) = (0.25, 0.80, 1, 1)

        _Grid ("Grid Size (cells per side)", Float) = 4
        _Gap ("Cell Gap (fraction of cell)", Range(0, 0.6)) = 0.16
        _IdleAlpha ("Idle Cell Alpha", Range(0, 1)) = 0.14
        _WaveSpeed ("Breathing Speed (radians/sec, base)", Float) = 2.2
        _WavePower ("Breathing Shape (>1 = brief bloom, long dim)", Range(1, 8)) = 3.5

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex        : SV_POSITION;
                fixed4 color         : COLOR;
                float2 texcoord      : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            float4 _ClipRect;

            fixed4 _Color0, _Color1, _Color2, _Color3;
            float _Grid;
            float _Gap;
            float _IdleAlpha;
            float _WaveSpeed;
            float _WavePower;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, OUT);
                UNITY_TRANSFER_INSTANCE_ID(v, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            // Cheap deterministic hash — no state, no texture lookup, gives each cell its
            // own phase and speed.
            float hash11(float x)
            {
                return frac(sin(x * 12.9898) * 43758.5453);
            }

            fixed4 padColor(int i)
            {
                int c = i % 4;
                if (c == 0) return _Color0;
                if (c == 1) return _Color1;
                if (c == 2) return _Color2;
                return _Color3;
            }

            // Continuous per-cell breathing: own phase, own slightly different speed, no steps.
            float litAmount(int i, float nowSeconds)
            {
                float phase = hash11(i * 3.17 + 1.0) * 6.2831853;
                float speed = _WaveSpeed * (0.7 + 0.6 * hash11(i * 9.73 + 2.0));
                float wave = 0.5 + 0.5 * sin(nowSeconds * speed + phase);
                return pow(wave, _WavePower);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float grid = max(1.0, _Grid);
                float2 cellPos = IN.texcoord * grid;
                float2 cellUV = frac(cellPos) - 0.5;
                int cx = (int)floor(cellPos.x);
                int cy = (int)floor(cellPos.y);
                int i = cy * (int)grid + cx;

                float halfSize = 0.5 - _Gap * 0.5;
                float2 d = abs(cellUV) - halfSize;
                float inside = step(max(d.x, d.y), 0.0);

                float lit = saturate(litAmount(i, _Time.y));

                fixed4 col = padColor(i) * IN.color;
                col.a *= lerp(_IdleAlpha, 1.0, lit) * inside;

                #ifdef UNITY_UI_CLIP_RECT
                col.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(col.a - 0.001);
                #endif

                return col;
            }
            ENDCG
        }
    }
}
