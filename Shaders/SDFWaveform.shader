// ============================================================================
// SDFWaveform.shader — GPU waveform display (tracker §1.6)
// ============================================================================
// One UGUI quad renders the whole waveform from a baked peak-pyramid data
// texture (see WaveformGpuData for the contract): min/max envelope + RMS core
// with SDF antialiasing, frequency-based coloring, a moving playhead that
// highlights the played region, and a programmable view window
// (_ViewStart/_ViewEnd) so pan/zoom/start-end framing are pure uniform writes
// — nothing is ever repainted on the CPU.
//
// PER-CLIP DATA (set by WaveformView when the LastPlayed clip changes):
//   _WaveTex (COLS × LEVELS peak pyramid), _FreqTex (COLS × 1 band energies).
// PER-FRAME UNIFORMS (WaveformView.LateUpdate):
//   _PlayheadPos (0..1 clip time), _QuadSize (px), _AnalysisPending.
// PROGRAMMATIC WINDOW: _ViewStart/_ViewEnd (0..1) — WaveformView.SetViewWindow.
//
// FRAGMENT SECTIONS:
//   1 Window mapping + LOD   2 Background   3 Baseline   4 Envelope + RMS core
//   5 Played/unplayed split (playhead highlight)   6 Playhead line
//   7 Pending-analysis shimmer   8 Clip + final composite
// ============================================================================

Shader "UI/SDFWaveform"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        // ── waveform data (runtime) ──
        _WaveTex ("Waveform Peak Pyramid", 2D) = "black" {}
        _FreqTex ("Frequency Bands", 2D) = "black" {}
        _WaveCols ("Data Columns", Float) = 2048
        _WaveLevels ("Pyramid Levels", Float) = 12
        _QuadSize ("Quad Size px (set at runtime)", Vector) = (480, 90, 0, 0)
        _AnalysisPending ("Analysis Pending (0/1)", Float) = 0
        _HasData ("Has Data (0/1)", Float) = 0

        // ── view window (programmatic pan/zoom/start-end framing) ──
        _ViewStart ("View Start (0-1)", Range(0, 1)) = 0
        _ViewEnd ("View End (0-1)", Range(0, 1)) = 1

        // ── color modes: 0 solid · 1 centroid gradient · 2 band mix ──
        _ColorMode ("Color Mode", Float) = 2
        _BodyColor ("Body Color (mode 0)", Color) = (0.55, 0.78, 1.0, 1)
        _LowColor ("Low Band Color", Color) = (1.0, 0.35, 0.28, 1)
        _MidColor ("Mid Band Color", Color) = (0.21, 0.91, 0.42, 1)
        _HighColor ("High Band Color", Color) = (0.25, 0.66, 1.0, 1)

        // ── waveform body ──
        _AmpScale ("Amplitude Scale", Range(0.2, 1)) = 0.9
        _EnvelopeAlpha ("Peak Envelope Opacity", Range(0, 1)) = 0.45
        _CoreBoost ("RMS Core Brightness", Range(0, 2)) = 1.15
        _WaveGlow ("Waveform Glow", Range(0, 2)) = 0.55
        _MinThicknessPx ("Min Envelope Half-Thickness px", Range(0, 2)) = 0.6

        // ── playhead / played-region highlight ──
        _PlayheadEnabled ("Playhead Enabled (0/1)", Float) = 1
        _PlayheadPos ("Playhead Position (0-1)", Range(0, 1)) = 0
        _PlayheadColor ("Playhead Color", Color) = (1.0, 1.0, 1.0, 1)
        _PlayheadWidthPx ("Playhead Half-Width px", Range(0.5, 4)) = 1.1
        _PlayheadGlow ("Playhead Glow", Range(0, 3)) = 1.2
        _UnplayedDim ("Unplayed Region Dim", Range(0, 1)) = 0.45
        _PlayedBoost ("Played Region Boost", Range(0.5, 2)) = 1.15

        // ── backdrop ──
        _BgEnabled ("Background Enabled (0/1)", Float) = 1
        _BgTopColor ("Background Top", Color) = (0.016, 0.02, 0.05, 0.92)
        _BgBottomColor ("Background Bottom", Color) = (0.04, 0.05, 0.10, 0.92)
        _BaselineEnabled ("Baseline Enabled (0/1)", Float) = 1
        _BaselineColor ("Baseline Color", Color) = (0.45, 0.55, 0.75, 0.35)

        _Radiance ("Master Radiance", Range(0, 3)) = 1.0

        // ── DISPLAY SURFACE ───────────────────────────────────────────────────
        // The cover the waveform is seen through, lit by the SAME three scene lamps
        // every knob and button reads (CG/Core/UIDisplaySurface.cginc). This panel
        // had no surface at all before — it was a bare emissive picture sitting in a
        // rack of lit hardware, which is why it read as a hole rather than a screen.
        // Off by default (_SurfaceMode 0), so an un-authored waveform is unchanged.
        //   0 none / 1 glass / 2 plastic / 3 LED matrix / 4 LCD
        _SurfaceMode ("Surface Mode", Float) = 0
        _SurfaceReflect ("Surface Reflectivity x", Range(0, 3)) = 1
        _SurfaceGloss ("Surface Gloss x", Range(0, 3)) = 1
        _SurfaceRough ("Surface Roughness x", Range(0, 3)) = 1
        _SurfaceFresnel ("Surface Fresnel x", Range(0, 3)) = 1
        _SurfaceCurveOptical ("Surface Optical Curve x", Range(0, 3)) = 1
        _SurfaceEnv ("Surface Environment x", Range(0, 3)) = 1
        _SurfaceInnerShadow ("Surface Inner Shadow x", Range(0, 3)) = 1
        _SurfaceSignalMask ("Signal Reflection Suppression", Range(0, 1)) = 0.6
        _SurfaceEnvColor ("Reflected Room (a = strength)", Color) = (0.62, 0.68, 0.82, 1)

        _BezelPx ("Bezel Inset px", Range(0, 24)) = 0
        // Cut-in: the hole in the faceplate this display sits in (UIDisplaySurface.cginc).
        _CutEdgePx ("Cut-in Edge px (0 = off)", Range(0, 24)) = 0
        _CutEdgeColor ("Cut-in Edge Color", Color) = (0, 0, 0, 0.85)
        _CutEdgeStrength ("Cut-in Edge Strength", Range(0, 2)) = 0.8
        _CutRoundPx ("Cut-in Corner px", Range(0, 24)) = 6
        _CutBevelPx ("Cut-in Bevel px (0 = off)", Range(0, 24)) = 0
        _CutBevelDepth ("Cut-in Bevel Depth", Range(0, 2)) = 1
        _CutBevelMinPx ("Cut-in Bevel Min Size px", Float) = 80
        _CutWallColor ("Cut-in Wall Color", Color) = (0.22, 0.23, 0.25, 0.9)
        _BezelRoundPx ("Bezel Corner px", Range(0, 24)) = 5
        _BezelColor ("Bezel Color", Color) = (0.05, 0.06, 0.08, 1)

        _ReceiveSceneShadows ("Receive Scene Shadows", Float) = 1

        // Unity UI standard properties
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

        Stencil {
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
        ColorMask [_ColorMask]
        Blend One OneMinusSrcAlpha

        Pass
        {
            Name "Main"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #include "CG/SDF/SDFWaveform.cginc"
            // The cover sheet + the scene light rig it reflects. Also declares _GlobalLight*.
            #include "CG/Core/UIDisplaySurface.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            float4 _ClipRect;

            sampler2D _WaveTex;
            sampler2D _FreqTex;
            float _WaveCols, _WaveLevels, _AnalysisPending, _HasData;
            float4 _QuadSize;
            float _ViewStart, _ViewEnd;

            float _ColorMode;
            float4 _BodyColor, _LowColor, _MidColor, _HighColor;
            float _AmpScale, _EnvelopeAlpha, _CoreBoost, _WaveGlow, _MinThicknessPx;

            float _PlayheadEnabled, _PlayheadPos, _PlayheadWidthPx, _PlayheadGlow;
            float4 _PlayheadColor;
            float _UnplayedDim, _PlayedBoost;

            float _BgEnabled, _BaselineEnabled;
            float4 _BgTopColor, _BgBottomColor, _BaselineColor;
            float _Radiance;

            float _SurfaceMode;
            UI_DISPLAY_SURFACE_UNIFORMS
            float _BezelPx, _BezelRoundPx;
            float4 _BezelColor;
            float _ReceiveSceneShadows;

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
                // Screen position for the light rig — a waveform strip is far too wide to
                // light from one anchor, so the lamp is sampled per fragment.
                float4 screenPos     : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color;
                OUT.screenPos = ComputeScreenPos(OUT.vertex);
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float4 acc = float4(0, 0, 0, 0);

                // ============================================================
                // 1. Window mapping + LOD
                // ============================================================
                float viewSpan = max(_ViewEnd - _ViewStart, 1e-4);
                float t = _ViewStart + uv.x * viewSpan;          // clip time 0..1
                float sy = (uv.y - 0.5) * 2.0 / max(_AmpScale, 1e-3); // signal -1..1
                float pxPerT = _QuadSize.x / viewSpan;           // horizontal px per clip unit
                float pxPerY = _QuadSize.y * 0.5 * _AmpScale;    // vertical px per signal unit
                float lod = wvLodLevel(viewSpan, _WaveCols, _WaveLevels, _QuadSize.x);

                // ============================================================
                // 2. Background — subtle screen-inset gradient
                // ============================================================
                if (_BgEnabled > 0.5)
                {
                    float4 bg = lerp(_BgBottomColor, _BgTopColor, uv.y);
                    wvOver(acc, bg.rgb, bg.a);
                }

                // ============================================================
                // 3. Baseline (center zero line)
                // ============================================================
                if (_BaselineEnabled > 0.5)
                {
                    float dBase = abs(sy) * pxPerY - 0.5;
                    wvOver(acc, _BaselineColor.rgb, wvFillPx(dBase) * _BaselineColor.a);
                }

                if (_HasData > 0.5)
                {
                    // ========================================================
                    // 4. Envelope + RMS core
                    // ========================================================
                    float4 wave = wvSampleWave(_WaveTex, t, lod, _WaveCols, _WaveLevels);
                    float mn = wave.r * 2.0 - 1.0;
                    float mx = wave.g * 2.0 - 1.0;
                    float rms = wave.b;
                    float spectralPos = wave.a; // centroid ("centroid" is reserved in HLSL)
                    float4 freq = wvSampleFreq(_FreqTex, t, _WaveCols);

                    float3 waveCol = wvWaveColor(_ColorMode, spectralPos, freq.rgb,
                        _BodyColor.rgb, _LowColor.rgb, _MidColor.rgb, _HighColor.rgb);

                    // ====================================================
                    // 5. Played/unplayed split — the playhead highlight.
                    //    Played side keeps full/boosted color, unplayed
                    //    side dims. Disabled → uniform full brightness.
                    // ====================================================
                    float played = step(t, _PlayheadPos);
                    float regionGain = _PlayheadEnabled > 0.5
                        ? lerp(_UnplayedDim, _PlayedBoost, played)
                        : 1.0; // idle: uniform full brightness, no split

                    // Envelope: filled band between min and max peaks.
                    float dEnv = max(mn - sy, sy - mx) * pxPerY - _MinThicknessPx;
                    float envMask = wvFillPx(dEnv);
                    wvOver(acc, waveCol * regionGain, envMask * _EnvelopeAlpha);

                    // RMS core: the solid "energy" body inside the peaks.
                    float dCore = (abs(sy) - rms) * pxPerY - _MinThicknessPx * 0.5;
                    float coreMask = wvFillPx(dCore) * envMask;
                    wvOver(acc, waveCol * _CoreBoost * regionGain, coreMask);

                    // Soft glow around the envelope silhouette.
                    wvAdd(acc, waveCol * wvGlowPx(dEnv, 3.0) * (1.0 - envMask)
                               * _WaveGlow * 0.35 * regionGain * _Radiance);

                    // ====================================================
                    // 6. Playhead line
                    // ====================================================
                    if (_PlayheadEnabled > 0.5)
                    {
                        float dPlay = abs(t - _PlayheadPos) * pxPerT;
                        float lineMask = wvFillPx(dPlay - _PlayheadWidthPx);
                        wvOver(acc, _PlayheadColor.rgb, lineMask * _PlayheadColor.a);
                        wvAdd(acc, _PlayheadColor.rgb * wvGlowPx(dPlay, 6.0)
                                   * _PlayheadGlow * 0.25 * _Radiance);
                    }
                }
                else if (_AnalysisPending > 0.5)
                {
                    // ========================================================
                    // 7. Pending-analysis shimmer — a quiet scanning sweep so
                    //    the panel reads "working", not "broken".
                    // ========================================================
                    float sweep = frac(uv.x * 1.5 - _Time.y * 0.5);
                    float band = smoothstep(0.0, 0.5, sweep) * smoothstep(1.0, 0.5, sweep);
                    wvOver(acc, _MidColor.rgb * 0.5, band * 0.12);
                }

                // ============================================================
                // 8. Display surface — the cover sheet, lit by the scene rig
                // ============================================================
                if (_SurfaceMode > 0.5)
                {
                    float2 px = float2(max(_QuadSize.x, 1.0), max(_QuadSize.y, 1.0));
                    float2 lightSpacePos = UI_DISPLAY_LIGHT_POS(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));
                    UI_DISPLAY_SURFACE_DESC(surf, _SurfaceMode, _BezelPx, _BezelRoundPx, px)
                    UI_APPLY_DISPLAY_SURFACE(acc, uv, lightSpacePos, surf);

                    if (_BezelPx > 0.001)
                    {
                        float2 halfPx = px * 0.5;
                        float r = min(_BezelRoundPx, min(halfPx.x, halfPx.y));
                        float2 pxPos = abs(uv * px - halfPx) - (halfPx - _BezelPx - r);
                        float bd = length(max(pxPos, 0.0)) + min(max(pxPos.x, pxPos.y), 0.0) - r;
                        float frame = smoothstep(-1.0, 1.0, bd);
                        wvOver(acc, _BezelColor.rgb, frame * _BezelColor.a);

                        // The frame is raised moulding and takes the light too — same
                        // construction as SDFScope's bezel; see the comment there.
                        // Analytic outward normal, NOT ddx/ddy — ddy is a screen derivative
                        // (y down) while uv and the lamps are y up, so a derivative here would
                        // light the top edge as if it were the bottom. See uiDispApertureGrad.
                        float2 bnorm = uiDispApertureGrad(uv, px, _BezelPx, _BezelRoundPx);
                        float3 keyToL = UIToLightVector(UILightDirection(_GlobalLightPos1, lightSpacePos));
                        float  facing = dot(bnorm, normalize(keyToL.xy + 1e-5));
                        float  edgeBand = saturate(1.0 - abs(bd) / max(_BezelPx, 1.0));
                        float3 keyRgb = (_GlobalLightFx1.x > 0.5) ? _GlobalLightColor1.rgb : float3(1, 1, 1);
                        wvAdd(acc, keyRgb * saturate(facing) * edgeBand * frame * 0.13);
                        acc.rgb *= 1.0 - saturate(-facing) * edgeBand * frame * 0.35;
                    }
                }

                // ── Cut-in: the hole in the faceplate this display sits in ───
                {
                    float2 cutPx = float2(max(_QuadSize.x, 1.0), max(_QuadSize.y, 1.0));
                    float2 cutL = UI_DISPLAY_LIGHT_POS(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));
                    UI_APPLY_DISPLAY_CUT_IN(acc, uv, cutPx, cutL);
                }

                // ── Receive shadows cast by neighbouring widgets ──────────────
                // Gated like SDFPanel's: the shared buffer has no per-panel stacking concept,
                // so a display sitting in FRONT of other panels must be able to opt out rather
                // than pick up shadows cast by widgets behind it.
                if (_ReceiveSceneShadows > 0.5 && acc.a > 0.001)
                    acc.rgb *= UIDisplayReceiveShadow(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));

                // ============================================================
                // 9. Clip + final composite (premultiplied)
                // ============================================================
                #ifdef UNITY_UI_CLIP_RECT
                float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                acc *= clipMask;
                #endif

                acc *= IN.color;
                return acc;
            }
            ENDCG
        }
    }
    FallBack "UI/Default"
}
