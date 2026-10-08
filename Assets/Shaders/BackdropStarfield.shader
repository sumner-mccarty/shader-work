// ============================================================================
// BackdropStarfield.shader — layered, twinkling stars drifting over a faint nebula
// ============================================================================
// A procedural, animated backdrop (time contract: CG/Core/UIBackdropFlow.cginc — exactly periodic,
// _Speed is cycles per second). Three star layers (near ones bigger, brighter, faster) drift by a
// WHOLE number of cells per cycle, so the field loops without a seam; each star twinkles on a whole-turn
// phase. A two-colour fbm nebula sits behind them, reshaping along an orbit.
// ============================================================================

Shader "UI/Backdrop/Starfield"
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
        _DriftCells ("Cells drifted per cycle (whole)", Range(0, 8)) = 1
        _DriftAngle ("Drift direction (radians)", Range(-3.14, 3.14)) = 0.35

        [Header(Stars)]
        _Density ("Density (cells per picture height)", Range(4, 60)) = 18
        _Fill ("Share of cells with a star", Range(0, 1)) = 0.35
        _StarSize ("Star size (cells)", Range(0.01, 0.3)) = 0.07
        _Twinkle ("Twinkle", Range(0, 1)) = 0.5
        _Flare ("Bright-star flare", Range(0, 1)) = 0.35
        _StarA ("Star colour A", Color) = (0.750, 0.850, 1.000, 1)
        _StarB ("Star colour B", Color) = (1.000, 0.850, 0.700, 1)

        [Header(Nebula)]
        _Base ("Space", Color) = (0.010, 0.010, 0.030, 1)
        _Nebula ("Nebula amount", Range(0, 1)) = 0.45
        _NebulaScale ("Nebula scale", Range(0.2, 6)) = 1.2
        _NebulaA ("Nebula A", Color) = (0.200, 0.080, 0.400, 1)
        _NebulaB ("Nebula B", Color) = (0.050, 0.250, 0.450, 1)

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
            float _Speed, _Phase, _Aspect, _DriftCells, _DriftAngle;
            float _Density, _Fill, _StarSize, _Twinkle, _Flare;
            float4 _StarA, _StarB, _Base, _NebulaA, _NebulaB;
            float _Nebula, _NebulaScale;
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
                float fc = frac(cyc);
                float2 uv = IN.texcoord;
                float asp = _Aspect > 0.01 ? _Aspect : _ScreenParams.x / max(_ScreenParams.y, 1.0);
                float2 p = (uv - 0.5) * float2(asp, 1.0);

                // nebula: two fbm fields walked round an orbit, tinted between two colours
                float n1 = bdFbm(p * _NebulaScale + bdOrbit(cyc, 0.25, 0.0), 4.0);
                float n2 = bdFbm(p * _NebulaScale * 1.7 + 6.1 + bdOrbit(cyc, 0.2, 0.5), 3.0);
                float3 col = _Base.rgb;
                col += lerp(_NebulaA.rgb, _NebulaB.rgb, n2) * smoothstep(0.35, 0.85, n1) * _Nebula;

                float2 dir = float2(cos(_DriftAngle), sin(_DriftAngle));
                float drift = round(_DriftCells);
                [unroll]
                for (int L = 0; L < 3; L++)
                {
                    float layer = (float)L;
                    float dens = _Density * (1.0 + layer * 0.9);
                    // whole cells per cycle (more for the near layers — parallax), so the layer loops seamlessly
                    float2 q = p * dens + float2(layer * 17.3, layer * 5.1) + dir * fc * drift * (3.0 - layer);
                    float2 cell = floor(q);
                    float2 f = frac(q) - 0.5;
                    float2 h = bdHash22(cell + layer * 31.7);
                    float exists = step(bdHash21(cell * 1.37 + layer * 7.9), _Fill);
                    float2 o = (h - 0.5) * 0.5;                       // star position inside its cell
                    float2 d2 = f - o;
                    float size = _StarSize * (0.5 + h.x) * (1.0 + (2.0 - layer) * 0.35);
                    float tw = 1.0 - _Twinkle * (0.5 + 0.5 * sin(BD_TAU * (fc * (1.0 + floor(h.y * 3.99)) + h.x)));
                    float core = exp(-dot(d2, d2) / max(size * size, 1e-6));
                    float bright = step(0.85, h.y) * _Flare;
                    float flare = bright * (exp(-abs(d2.x) / (size * 0.5)) * exp(-abs(d2.y) / (size * 3.0))
                                          + exp(-abs(d2.y) / (size * 0.5)) * exp(-abs(d2.x) / (size * 3.0))) * 0.5;
                    // a star lives in its own cell: fade the flare before the cell edge so no cut line shows
                    float cellFade = smoothstep(0.5, 0.3, max(abs(f.x), abs(f.y)));
                    flare *= cellFade;
                    core *= cellFade;
                    float3 sc = lerp(_StarA.rgb, _StarB.rgb, h.y);
                    col += sc * (core + flare) * tw * exists * (1.0 - layer * 0.25);
                }

                col = bdFinish(col, uv, _Brightness, _Contrast, _Saturation, _Vignette, _Grain, cyc);
                return fixed4(col * _Color.rgb, _Color.a);
            }
            ENDCG
        }
    }
}
