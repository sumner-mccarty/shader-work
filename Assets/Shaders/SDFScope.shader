// ============================================================================
// SDFScope.shader — reusable mixer "scope" display (MixerDisplays.md)
// ============================================================================
// ONE shader renders every curve/signal screen in the mixer rack, selected by
// _Mode. The picture is computed FROM the effect's own parameters (_P0.._P2),
// so a knob turn reshapes it. Driven by ScopeDisplay.cs (the SDFRhythmTrack /
// TrackLanesView pattern: Shader.Find + material + per-frame uniform push).
//
// _Mode → screen (params meaning in CG/SDF/SDFScope.cginc header):
//   0 ENVELOPE(ADSR)  1 FREQ RESPONSE  2 COMP TRANSFER  3 DIST TRANSFER
//   4 LFO(chorus)     5 COMB(flange)   6 TAPS(echo)     7 DECAY(reverb)
//   8 SPECTRUM backdrop
//
// FRAGMENT SECTIONS:
//   1 Background well   2 Grid lines   3 Filled area under curve
//   4 The curve line (SDF)  5 Glow   6 Handles (freq mode)
//   7 Playhead sweep   7.5 Emitter structure + body tint (what MAKES the picture)
//   7.6 Cover sheet — glass/plastic reflections from the scene light rig, plus the
//       lit bezel it is recessed into (CG/Core/UIDisplaySurface.cginc)
//   8 Clip + final composite
//
// Follows the §1 STANDING RULE: _ClipRect + UnityGet2DClipping +
// `#pragma multi_compile __ UNITY_UI_CLIP_RECT`. No tex2Dlod, no #pragma target
// bump (per §4.3 pink-shader lessons).
// ============================================================================

Shader "UI/SDFScope"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _Mode ("Display Mode", Float) = 0
        _QuadSize ("Quad Size px (runtime)", Vector) = (150, 58, 0, 0)

        // Generic parameter banks (meaning per _Mode, see cginc header).
        _P0 ("Param bank 0", Vector) = (0.3, 0.4, 0.6, 0.5)
        _P1 ("Param bank 1", Vector) = (0.4, 0.6, 0.4, 0)
        _P2 ("Param bank 2", Vector) = (0, 0, 0, 0)

        // Handles for the freq-response mode: xy positions in 0..1 (x=axis, y=curve).
        _H0 ("Handle 0 (x,y,on)", Vector) = (0, 0, 0, 0)
        _H1 ("Handle 1 (x,y,on)", Vector) = (0, 0, 0, 0)
        _H2 ("Handle 2 (x,y,on)", Vector) = (0, 0, 0, 0)

        _Phase ("Animation Phase 0-1", Range(0, 1)) = 0
        _Playhead ("Playhead 0-1 (<0 = off)", Float) = -1

        // -- DISPLAY SURFACE (tracker 4.16 D1) --------------------------------
        // What the picture is being viewed THROUGH. Everything above draws the signal;
        // this decides whether you are looking at bare emissive phosphor, a dot-matrix
        // LED panel, a plastic LCD, or curved glass with a sheen on it. Every layer is
        // guarded and defaults to off, so an un-authored scope renders exactly as before.
        //   _SurfaceMode  0 none / 1 glass / 2 plastic / 3 LED matrix / 4 LCD
        _SurfaceMode ("Surface Mode", Float) = 0

        // Pixel/dot structure (LED + LCD). Cells 0 = continuous, no quantization.
        _PixelCellsX ("Pixel Cells X", Float) = 0
        _PixelCellsY ("Pixel Cells Y", Float) = 0
        _PixelGap ("Pixel Gap 0-1", Range(0, 0.9)) = 0.22
        _PixelRound ("Pixel Roundness 0-1", Range(0, 1)) = 1
        _PixelFloor ("Unlit Pixel Level", Range(0, 1)) = 0.05

        _ScanlineAmount ("Scanline Amount", Range(0, 1)) = 0
        _ScanlinePitchPx ("Scanline Pitch px", Range(1, 12)) = 3

        // -- REFLECTIONS come from the LIGHT RIG, not from here ---------------
        // There used to be a `_Sheen*` group (amount/angle/width/position) that drew a
        // gaussian stripe at an authored angle, and a `_PlasticAmount` top-down wash.
        // Both were paintings of a reflection: they sat still while every knob and
        // button beside them relit, which is exactly the "fake unmoving lighting"
        // complaint. They are gone. Reflections are now computed per-fragment from the
        // three scene lamps in CG/Core/UIDisplaySurface.cginc, and the knobs below are
        // MULTIPLIERS on what this kind of display naturally is (1 = natural).
        _SurfaceReflect ("Surface Reflectivity x", Range(0, 3)) = 1
        _SurfaceGloss ("Surface Gloss x", Range(0, 3)) = 1
        _SurfaceRough ("Surface Roughness x", Range(0, 3)) = 1
        _SurfaceFresnel ("Surface Fresnel x", Range(0, 3)) = 1
        _SurfaceCurveOptical ("Surface Optical Curve x", Range(0, 3)) = 1
        _SurfaceEnv ("Surface Environment x", Range(0, 3)) = 1
        _SurfaceInnerShadow ("Surface Inner Shadow x", Range(0, 3)) = 1
        _SurfaceSignalMask ("Signal Reflection Suppression", Range(0, 1)) = 0.6
        _SurfaceEnvColor ("Reflected Room (a = strength)", Color) = (0.62, 0.68, 0.82, 1)

        // Plastic: a milky haze over the whole face. Kept — unlike the wash it replaced,
        // diffusion is a property of the MATERIAL, not a stand-in for a light.
        _PlasticHaze ("Plastic Haze", Range(0, 1)) = 0

        _CurveAmount ("Screen Curve", Range(0, 0.6)) = 0
        _VignetteAmount ("Vignette", Range(0, 2)) = 0
        _SurfaceTint ("Surface Tint (a = strength)", Color) = (1, 1, 1, 0)

        // Bezel: the inset frame the glass sits in. 0 px = no bezel.
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

        // Live audio "liveness" 0..1: gates animated motion (0 = frozen/idle) and scales
        // animated amplitude, so displays only move while the followed pad is sounding.
        _Activity ("Activity 0-1", Range(0, 1)) = 0

        // How much this module is actually contributing to the sound, 0..1 — the module's enable
        // square times its mix/amount knob (MixerPanel.RefreshEngagement). At 0 the picture goes
        // SUBDUED: the signal desaturates and sinks toward the well, the glow drops to a floor,
        // and nothing ripples. Coming up it puts the hue and the light back. Defaults to 1 so a
        // display nobody drives looks exactly as it always did.
        _Engaged ("Engaged 0-1", Range(0, 1)) = 1

        // Is the SCREEN switched on? The module's power/bypass lamp, and nothing else
        // (MixerPanel.RefreshEngagement). 2026-09-07, user direction: power and mix "are the same
        // effect and I want them 2 separate effects".
        //
        // They were multiplied into _Engaged, so a bypassed module and a fully-dry one looked
        // identical — which is wrong twice over. Bypassing is a statement about the DEVICE (it is
        // not in the circuit at all); a mix at zero is a statement about the SIGNAL (the device is
        // running and contributing nothing yet). A rack tells those apart the way real gear does:
        // the power light and the meter are different lights.
        //
        // So this one is about the GLASS. At 0 the whole display goes dark — background, grid,
        // trace, glow, every finish effect — like a screen with the power pulled, and nothing
        // moves. _Engaged keeps its own job: the colour and the life of the SIGNAL on a screen
        // that is already lit.
        _Powered ("Powered 0-1", Range(0, 1)) = 1

        // Real per-sample data (fed by ScopeDisplay from WaveformDataCache):
        //   _WaveTex — peak pyramid, row 0 R=min G=max (mode 0 carrier)
        //   _SpecTex — whole-sample log-freq spectrum, R=magnitude (mode 1 backdrop)
        _WaveTex ("Waveform peaks (mode 0)", 2D) = "black" {}
        _SpecTex ("Spectrum (mode 1)", 2D) = "black" {}
        _FreqTex ("Waveform band energies (mode 0)", 2D) = "black" {}
        _HasWave ("Has waveform", Float) = 0
        _HasSpec ("Has spectrum", Float) = 0
        _HasFreq ("Has band energies", Float) = 0

        // Frequency coloring for the mode-0 waveform body, mirroring SDFWaveform's _ColorMode so
        // the envelope module draws the same sample the same way as the main waveform panel.
        // 0 = solid fill color · 1 = spectral-centroid gradient · 2 = low/mid/high band mix.
        _WaveColorMode ("Wave Color Mode", Float) = 2
        _LowColor ("Low band", Color) = (1.0, 0.35, 0.28, 1)
        _MidColor ("Mid band", Color) = (0.21, 0.91, 0.42, 1)
        _HighColor ("High band", Color) = (0.25, 0.66, 1.0, 1)
        _WaveCols ("Data Columns", Float) = 2048
        _WaveLevels ("Pyramid Levels", Float) = 12
        _MinThicknessPx ("Min Wave Thickness px", Float) = 1.25

        // ENV7 start/end view window (mode 0 only): pans/zooms which portion of the real
        // waveform's carrier is sampled (ScopeDisplay.SetEnvelopeView / legacy SetViewWindow).
        _ViewStart ("View start 0-1 (mode 0)", Range(0, 1)) = 0
        _ViewEnd ("View end 0-1 (mode 0)", Range(0, 1)) = 1

        // Where the ENV7 trim points land WITHIN the current view window above (0-1, mode 0
        // only) — set by ScopeDisplay.SetEnvelopeView. The drawn ADSR envelope is confined to
        // [_MarkStart, _MarkEnd] rather than the full display width, since that's the only
        // region that's actually audible; outside it the envelope amplitude collapses to the
        // flat baseline. In Trim mode these always resolve to exactly 0 and 1 (the view window
        // IS the trim window there), which is a no-op — the confinement only does something
        // visible once Full/Left/Right show more of the clip than is trimmed.
        // Float, NOT Range(0,1): in the Left/Right magnifier views the far marker is genuinely
        // outside the window (often well past 1 or below 0), and that is the value the envelope
        // confinement below needs. Clamping it to the edge would both draw a marker line where
        // there is no trim point and squash the ADSR shape into the visible slice.
        _MarkStart ("Trim Start Marker (mode 0, may leave 0-1)", Float) = 0
        _MarkEnd ("Trim End Marker (mode 0, may leave 0-1)", Float) = 1
        // Left/Right magnifier views: the point of them is to place a trim marker against the
        // audio either side of it, so the carrier is drawn at FULL height across the whole window
        // and the inaudible side is dimmed rather than erased. Without this the excluded side of
        // the marker collapses to the baseline (envelope amplitude is zero there) and you are
        // asked to position a cut against a blank half-screen.
        _MarkerZoom ("Marker Zoom View (mode 0)", Float) = 0
        // 0..1 "the view is about to re-zoom" warning, faded in by MixerPanel over the last moment
        // of the magnifier's settle timer: the trim marker brightens and grows a soft halo. It
        // exists so cancelling the re-zoom (nudge the knob) is a decision you make BEFORE the
        // picture moves rather than a correction after it. 0 = nothing pending, markers draw
        // exactly as they always did.
        _MarkerPulse ("Marker Re-zoom Warning (mode 0)", Range(0, 1)) = 0
        // Draws the two marker lines at _MarkStart/_MarkEnd. Off by default (and in Trim mode)
        // since there they'd sit exactly on the display's own edges — matching the original
        // "no marker lines, just the picture changing" behaviour.
        _ShowTrimMarkers ("Show Trim Markers (mode 0)", Float) = 0
        _TrimStartColor ("Trim Start Marker Color", Color) = (0.35, 0.92, 0.45, 0.9)
        _TrimEndColor ("Trim End Marker Color", Color) = (0.95, 0.35, 0.35, 0.9)

        // Colors
        _BgColor ("Background", Color) = (0.09, 0.075, 0.055, 1)
        _GridColor ("Grid", Color) = (0.5, 0.47, 0.4, 0.25)
        _HousingColor ("VU Unlit Housing (alpha 0 = auto tint)", Color) = (0, 0, 0, 0)
        // VU ladder zones — per LOOK now (2026-09-18): Flat's meter was the only green thing on a
        // monotone rack. alpha 0 = the classic green / amber / red.
        _VuLowColor ("VU Low Zone (alpha 0 = green)", Color) = (0, 0, 0, 0)
        _VuMidColor ("VU Mid Zone (alpha 0 = amber)", Color) = (0, 0, 0, 0)
        _VuHighColor ("VU High Zone (alpha 0 = red)", Color) = (0, 0, 0, 0)
        _VuZones ("VU Zone Starts (x = mid, y = high)", Vector) = (0.6, 0.85, 0, 0)
        _VuSegments ("VU Segments (0 = one solid bar)", Float) = 20
        _CurveColor ("Curve", Color) = (1.0, 0.72, 0.28, 1)
        _FillColor ("Fill under curve", Color) = (1.0, 0.72, 0.28, 0.18)
        _H0Color ("Handle 0", Color) = (0.4, 0.66, 1.0, 1)
        _H1Color ("Handle 1", Color) = (1.0, 0.62, 0.28, 1)
        _H2Color ("Handle 2", Color) = (0.25, 0.66, 1.0, 1)
        _PlayheadColor ("Playhead", Color) = (1.0, 0.72, 0.28, 1)

        _GridEnabled ("Grid Enabled", Float) = 1
        _FillEnabled ("Fill Enabled", Float) = 1
        _CurveThickness ("Curve Half-Thickness px", Range(0.5, 4)) = 1.4
        _Glow ("Curve Glow", Range(0, 2)) = 0.8

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
            #include "CG/SDF/SDFScope.cginc"
            // The glass/plastic the picture is seen through, lit by the SAME three
            // scene lamps every knob and button reads. Also declares _GlobalLight*.
            #include "CG/Core/UIDisplaySurface.cginc"
            // Shared with the main Waveform panel: the SAME peak-pyramid sampling (LOD selection +
            // manual linear filtering) and the SAME frequency-coloring maths. Drawing the envelope
            // module's carrier through these means the two displays are not merely similar — they
            // are the same code, so they can never drift in quality or color.
            #include "CG/SDF/SDFWaveform.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            float4 _ClipRect;

            float _Mode;
            float4 _QuadSize;
            float4 _P0, _P1, _P2;
            float4 _H0, _H1, _H2;
            float _Phase, _Playhead;
            float _SurfaceMode;
            float _PixelCellsX, _PixelCellsY, _PixelGap, _PixelRound, _PixelFloor;
            float _ScanlineAmount, _ScanlinePitchPx;
            UI_DISPLAY_SURFACE_UNIFORMS
            float _PlasticHaze;
            float _CurveAmount, _VignetteAmount;
            float4 _SurfaceTint;
            float _BezelPx, _BezelRoundPx;
            float4 _BezelColor;
            float4 _BgColor, _GridColor, _CurveColor, _FillColor;
            float4 _HousingColor;   // VU ladder unlit segments; alpha 0 = the old dim tint
            float4 _VuLowColor, _VuMidColor, _VuHighColor, _VuZones;
            float _VuSegments;
            float4 _H0Color, _H1Color, _H2Color, _PlayheadColor;
            float _GridEnabled, _FillEnabled, _CurveThickness, _Glow;
            sampler2D _WaveTex, _SpecTex, _FreqTex;
            float _HasWave, _HasSpec, _HasFreq;
            float _ViewStart, _ViewEnd;
            float _MarkStart, _MarkEnd, _ShowTrimMarkers, _MarkerZoom, _MarkerPulse;
            float4 _TrimStartColor, _TrimEndColor;
            float _WaveColorMode;
            float4 _LowColor, _MidColor, _HighColor;
            float _WaveCols, _WaveLevels, _MinThicknessPx;
            float _Activity;
            float _Engaged;
            float _Powered;
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
                // Where this fragment sits on screen, for the light rig. A display is
                // far too big to light from one anchor point the way a knob does — see
                // the per-fragment note in UIDisplaySurface.cginc.
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

            // curve half-thickness expressed in y-units (px → uv.y)
            float thickY() { return _CurveThickness / max(_QuadSize.y, 1.0); }

            // draw one curve mode into acc: (optional) fill + line + glow. `fillOn`, the graded
            // colours and the glow amount are passed rather than read from uniforms — they are
            // frag-locals (engagement grading) and per-call overrides have to stay legal in HLSL.
            //
            // `ripple` is the travelling signal packet at this x. It swells the line slightly and
            // flares the glow a lot: the picture stays exactly where the parameters put it and only
            // the light moving along it changes.
            void drawCurve(inout float4 acc, int mode, float2 uv, float voice, float3 col,
                           float fillOn, float4 fillCol, float glowAmt, float ripple)
            {
                float d = scCurveDist(mode, uv, _P0, _P1, voice);
                float ht = thickY();
                // 3. fill under the curve
                if (fillOn > 0.5)
                {
                    float y0 = scEval(mode, uv.x, _P0, _P1, voice);
                    float under = scFill(uv.y - y0); // 1 below the curve
                    scOver(acc, fillCol.rgb, under * fillCol.a);
                }
                // 4. the curve line
                float lineMask = scLine(d, ht * (1.0 + 0.30 * ripple));
                scOver(acc, col * (1.0 + 0.45 * ripple), lineMask);
                // 5. glow
                float g = scGlow(d, ht * 3.5) * glowAmt * (1.0 + 2.0 * ripple);
                scAdd(acc, col * g * 0.5);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 rawUv = IN.texcoord;
                float2 uv = rawUv;
                int mode = (int)round(_Mode);

                // Screen curve (surface layer) -- bulge the SAMPLING uv so the whole picture
                // bends like it is painted on the inside of glass. Done here rather than as a
                // post-pass because every curve/grid/handle below reads uv: warping the input
                // warps the picture coherently instead of smearing an already-flat render.
                float offGlass = 0.0;
                if (_CurveAmount > 0.001)
                {
                    float2 cc = uv * 2.0 - 1.0;
                    cc *= 1.0 + _CurveAmount * dot(cc, cc) * 0.5;
                    float2 curved = cc * 0.5 + 0.5;
                    offGlass = saturate(max(max(-curved.x, curved.x - 1.0),
                                            max(-curved.y, curved.y - 1.0)) * 60.0);
                    uv = saturate(curved);
                }

                // ============================================================
                // 1. Background well
                // ============================================================
                float4 acc = float4(_BgColor.rgb, _BgColor.a);

                // ── engagement + flow, resolved ONCE for every section below ──
                // lit  — is this device in circuit and turned up? (bypass × mix)
                // flow — is signal actually passing through it right now? (lit × live level)
                // Everything the SIGNAL is drawn with is graded by `lit`; everything that MOVES is
                // gated by `flow`, so a bypassed or fully-dry module is still and colourless even
                // while the pad is sounding, and an engaged one is still only when it is silent.
                float  lit     = saturate(_Engaged);
                // Nothing moves on a dark screen, whatever the signal is doing.
                float  powered = saturate(_Powered);
                float  flow    = lit * powered * saturate(_Activity);
                float  gain    = scLitGain(lit);
                float3 sigCol  = scEngage(_CurveColor.rgb, _BgColor.rgb, lit);
                float3 headCol = scEngage(_PlayheadColor.rgb, _BgColor.rgb, lit);
                float4 fillCol = float4(scEngage(_FillColor.rgb, _BgColor.rgb, lit),
                                        _FillColor.a * (0.35 + 0.65 * lit));
                float  glowAmt = _Glow * gain;
                // The travelling packet, in x. Rides _Phase, which ScopeDisplay only advances
                // while the module is both engaged and sounding — so this stops where it is
                // rather than snapping home when the sound stops.
                float  ripple  = scRipple(uv.x, _Phase, flow);

                // ============================================================
                // 2. Grid lines (center line + quarter divisions)
                // ============================================================
                if (_GridEnabled > 0.5)
                {
                    float gy = abs(frac(uv.y * 4.0 + 0.5) - 0.5) / max(fwidth(uv.y * 4.0), 1e-4);
                    float gx = abs(frac(uv.x * 4.0 + 0.5) - 0.5) / max(fwidth(uv.x * 4.0), 1e-4);
                    float grid = (1.0 - saturate(gy)) * 0.6 + (1.0 - saturate(gx)) * 0.4;
                    scOver(acc, _GridColor.rgb, grid * _GridColor.a);
                    // brighter centre line
                    float cl = 1.0 - saturate(abs(uv.y - 0.5) / max(fwidth(uv.y), 1e-4));
                    scOver(acc, _GridColor.rgb, cl * 0.5);
                }

                // ============================================================
                // 3/4/5. Curve(s) per mode
                // ============================================================
                float aax = 1.5 / max(_QuadSize.x, 1.0); // fixed AA for in-loop line masks
                if (mode == 0)
                {
                    // ENVELOPE: a filled mirrored waveform whose amplitude at every x IS the
                    // ADSR envelope (now attack ramps to _P1.x = peak/"PK" knob, not always
                    // 1.0), with the real sample's carrier when fed (item 3.2), plus a thin
                    // bright outline. attack=0 rises vertically at the left, release=0 drops
                    // vertically at the right (items 3.3/3.4); thin lines (item 3.5). The
                    // envelope SHAPE always spans the full 0..1 width; only which slice of the
                    // carrier is sampled pans/zooms with _ViewStart/_ViewEnd (ENV7 START/END
                    // knobs, ScopeDisplay.SetEnvelopeView). The envelope amplitude is confined to
                    // [_MarkStart, _MarkEnd] — the trim window remapped into this view — rather
                    // than the raw 0..1 display width, so it only ever covers the audible region;
                    // in Trim mode (view == trim) those are always exactly 0 and 1, so this is a
                    // no-op there and the envelope still spans the full width as before.
                    float trimLo = min(_MarkStart, _MarkEnd);
                    float trimHi = max(_MarkStart, _MarkEnd);
                    float trimSpan = max(trimHi - trimLo, 1e-4);
                    float envX = saturate((uv.x - trimLo) / trimSpan);
                    float insideTrim = step(trimLo, uv.x) * step(uv.x, trimHi);
                    float ampEnv = scEnvAmp(envX, _P0, _P1.x) * insideTrim;
                    float wx = lerp(_ViewStart, _ViewEnd, uv.x);
                    // No clip bound → carrier is SILENCE (0), which collapses the filled body to a
                    // flat centre line. That empty line is the correct "no audio loaded" reading;
                    // the envelope outline is drawn separately and stays fully open. (A procedural
                    // stand-in carrier used to be faked here, which made an empty rack look like it
                    // already had audio in it.)
                    // Carrier sampled through the SAME peak pyramid the main Waveform panel uses:
                    // pick the LOD matching pixels-per-column and filter linearly across columns.
                    // Point-sampling row 0 (what this used to do) aliased badly once the clip's
                    // 2048 columns were squeezed into a few hundred pixels — that was the blocky
                    // "jaggies" mismatch between the two displays.
                    float viewSpan = max(_ViewEnd - _ViewStart, 1e-4);
                    float lod = wvLodLevel(viewSpan, _WaveCols, _WaveLevels, _QuadSize.x);
                    float mn = 0.0, mx = 0.0, rms = 0.0, spectralPos = 0.5;
                    float3 bands = float3(0, 0, 0);
                    if (_HasWave > 0.5)
                    {
                        float4 w = wvSampleWave(_WaveTex, wx, lod, _WaveCols, _WaveLevels);
                        mn = w.r * 2.0 - 1.0;
                        mx = w.g * 2.0 - 1.0;
                        rms = w.b;
                        spectralPos = w.a;
                        if (_HasFreq > 0.5) bands = wvSampleFreq(_FreqTex, wx, _WaveCols).rgb;
                    }

                    // Identical coloring path to the main panel (0 solid · 1 centroid · 2 band mix).
                    float3 waveCol = wvWaveColor(_WaveColorMode, spectralPos, bands,
                                                 _FillColor.rgb, _LowColor.rgb, _MidColor.rgb, _HighColor.rgb);

                    // Graded by engagement like every other signal colour, so a bypassed
                    // envelope module's carrier sinks toward the well instead of staying vivid.
                    waveCol = scEngage(waveCol, _BgColor.rgb, lit);

                    // The envelope screen has a REAL position to ride — the playhead MixerPanel
                    // drives from actual playback — so its travelling flare follows that rather
                    // than the free-running phase the effect screens use. Same read, honest source.
                    float envFlow = (_Playhead >= 0.0)
                        ? saturate(_Activity) * lit * exp(-pow((uv.x - _Playhead) / 0.13, 2.0))
                        : ripple;

                    // Silence baseline: the waveform's own centre line, so an empty screen reads as
                    // a deliberate flat line rather than nothing at all.
                    scOver(acc, sigCol, scLine(uv.y - 0.5, thickY() * 0.8) * 0.4);

                    // True min/max envelope (asymmetric, like real audio) scaled by the ADSR
                    // amplitude, with a brighter RMS core — same construction as SDFWaveform, so
                    // both displays read as one instrument. SDF distances in PIXELS give clean AA
                    // and a minimum thickness so quiet passages stay visible instead of dropping out.
                    // In the magnifier views the carrier ignores the envelope and runs full
                    // height, dimmed on the side the trim excludes: you cannot click a start point
                    // onto audio the display has erased. Everywhere else the carrier is shaped by
                    // the envelope exactly as before.
                    float ampCarrier = (_MarkerZoom > 0.5) ? 1.0 : ampEnv;
                    float carrierDim = (_MarkerZoom > 0.5) ? lerp(0.30, 1.0, insideTrim) : 1.0;

                    float amp = ampCarrier * 0.44;
                    float sy = uv.y - 0.5;
                    float pxPerY = _QuadSize.y;
                    float topY = mx * amp, botY = mn * amp;
                    float dBand = max(sy - topY, botY - sy) * pxPerY - _MinThicknessPx * 0.5;
                    float bandMask = saturate(0.5 - dBand);
                    scOver(acc, waveCol * (1.0 + 0.35 * envFlow), bandMask * max(fillCol.a, 0.5) * carrierDim);

                    float dCore = (abs(sy) - rms * amp) * pxPerY - _MinThicknessPx * 0.5;
                    float coreMask = saturate(0.5 - dCore);
                    scOver(acc, waveCol * 1.18, coreMask * 0.85 * carrierDim);
                    scAdd(acc, waveCol * scGlow(dBand / max(pxPerY, 1.0), thickY() * 2.5)
                               * glowAmt * (0.10 + 0.45 * envFlow) * carrierDim);
                    float envTop = 0.5 + ampEnv * 0.44;
                    float envBot = 0.5 - ampEnv * 0.44;
                    float ht = thickY();
                    scOver(acc, sigCol * (1.0 + 0.4 * envFlow), scLine(uv.y - envTop, ht));
                    scOver(acc, sigCol * (1.0 + 0.4 * envFlow), scLine(uv.y - envBot, ht) * 0.6);
                    scAdd(acc, sigCol * scGlow(uv.y - envTop, ht * 3.0) * glowAmt * (0.4 + 1.1 * envFlow));
                    scAdd(acc, sigCol * scGlow(uv.y - envBot, ht * 3.0) * glowAmt * (0.25 + 0.8 * envFlow));

                    // Trim markers — Full/Left/Right only (see _ShowTrimMarkers above); same
                    // thin-line technique as the playhead sweep below, just vertical and gated
                    // per-marker rather than shared.
                    if (_ShowTrimMarkers > 0.5)
                    {
                        // _MarkerPulse rides on top of the plain line — see the property above.
                        // At 0 every term below collapses to what this drew before it existed.
                        float pulseLift = 1.0 + _MarkerPulse * 1.5;
                        float pulseA = saturate(_MarkerPulse * 0.45);
                        float haloW = 0.008 + _MarkerPulse * 0.012;

                        float dStart = abs(uv.x - _MarkStart) / max(fwidth(uv.x), 1e-4);
                        scOver(acc, _TrimStartColor.rgb * pulseLift,
                               (1.0 - saturate(dStart - 0.6)) * saturate(_TrimStartColor.a + pulseA));
                        scAdd(acc, _TrimStartColor.rgb * scGlow(uv.x - _MarkStart, haloW)
                                   * glowAmt * _MarkerPulse * 0.85);

                        float dEnd = abs(uv.x - _MarkEnd) / max(fwidth(uv.x), 1e-4);
                        scOver(acc, _TrimEndColor.rgb * pulseLift,
                               (1.0 - saturate(dEnd - 0.6)) * saturate(_TrimEndColor.a + pulseA));
                        scAdd(acc, _TrimEndColor.rgb * scGlow(uv.x - _MarkEnd, haloW)
                                   * glowAmt * _MarkerPulse * 0.85);
                    }
                }
                else if (mode == 4)
                {
                    // LFO (chorus): a faint dry reference down the centre plus three
                    // phase-offset voices whose spacing comes from the delay (item 9.2/9.3).
                    float sp = 0.5 + _P0.z * 3.0;
                    scOver(acc, sigCol, scLine(uv.y - 0.5, thickY()) * 0.22);
                    // Each voice gets the packet at its own offset, so the three of them light up
                    // in sequence rather than pulsing as one block.
                    float r0 = scRipple(uv.x, _Phase, flow);
                    float r1 = scRipple(uv.x, _Phase + 0.14, flow);
                    float r2 = scRipple(uv.x, _Phase - 0.14, flow);
                    drawCurve(acc, 4, uv, _Phase * 6.28318,      sigCol,
                              0.0, fillCol, glowAmt, r0);
                    drawCurve(acc, 4, uv, _Phase * 6.28318 + sp, scEngage(_H1Color.rgb, _BgColor.rgb, lit),
                              0.0, fillCol, glowAmt, r1);
                    drawCurve(acc, 4, uv, _Phase * 6.28318 - sp, scEngage(_H2Color.rgb, _BgColor.rgb, lit),
                              0.0, fillCol, glowAmt, r2);
                }
                else if (mode == 6)
                {
                    // TAPS (echo): what Unity's Echo actually outputs, on a REAL time axis. The
                    // screen is a fixed window as long as the TIME knob's range (10..2000 ms), so
                    // a longer delay spreads the repeats further apart and fewer fit — it used to
                    // ADD bounces as the delay grew, which drew a long echo as a tight flutter.
                    //   TIME  (_P0.x) delay = 10 + 1990·x ms → spacing on screen
                    //   FB    (_P0.y) Unity Decay: repeat k is decay^(k-1) of the first, 0 = ONE repeat
                    //   MIX   (_P0.z) dry = 1-mix (the arc launched at t=0), wet = mix (every repeat)
                    //   CHNS  (_P0.w) caps how many audio channels the effect processes — it does
                    //                 not change timing or level, so it does not shape this picture.
                    // Each arrival launches a ball-bounce arc as tall as its level and lands on the
                    // next arrival, where a glowing impact cap marks the repeat. The bounce the
                    // playhead is passing flares while the module is live (_Activity > 0).
                    const float window = 2000.0;
                    const float x0 = 0.06, span = 0.88, base = 0.07, top = 0.80;
                    float delayMs = 10.0 + saturate(_P0.x) * 1990.0;
                    float decay = saturate(_P0.y), wet = saturate(_P0.z), dry = 1.0 - wet;
                    float step0 = span * delayMs / window;            // one delay, in uv.x
                    float tq = (uv.x - x0) / max(step0, 1e-5);         // time in delays (0 = the hit)

                    // 1) decay envelope through the repeats' peaks (arc k peaks at k + 0.5)
                    //    (a mask, not a branch: scLine takes fwidth, which needs every lane)
                    float envOn = step(0.001, decay) * step(0.001, wet) * step(1.5, tq) * step(uv.x, x0 + span);
                    float envY = base + wet * pow(max(decay, 1e-4), max(tq - 1.5, 0.0)) * top;
                    scOver(acc, sigCol, scLine(uv.y - envY, thickY()) * 0.45 * envOn);
                    scAdd(acc, sigCol * scGlow(uv.y - envY, thickY() * 3.0) * gain * (0.25 + 0.6 * ripple) * envOn);

                    // 2) baseline the bounces land on (the whole window)
                    float inWin = step(x0, uv.x) * step(uv.x, x0 + span);
                    scOver(acc, sigCol, scLine(uv.y - base, thickY() * 0.8) * 0.35 * inWin);

                    // 3) the arcs: only the one this pixel is under and its neighbours can reach it,
                    //    so the cost does not grow with the repeat count (10 ms = ~176 repeats).
                    float kc = floor(tq);
                    [unroll] for (int j = -1; j <= 1; j++)
                    {
                        // no `continue`: scLine takes fwidth, so every lane runs the same body
                        float k = max(kc + float(j), 0.0);
                        float ax = x0 + k * step0;                     // this arc's launch
                        float valid = step(0.0, kc + float(j)) * step(ax, x0 + span - 1e-5);
                        float lvl = (k < 0.5) ? dry : wet * pow(max(decay, 1e-4), max(k - 1.0, 0.0));
                        lvl *= (k > 1.5 && decay <= 0.001) ? 0.0 : valid;   // decay 0 = a single repeat
                        float h = lvl * top;
                        float u = (uv.x - ax) / max(step0, 1e-5);       // 0..1 across this arc
                        float inSpan = step(0.0, u) * step(u, 1.0) * step(uv.x, x0 + span);
                        float arcY = base + h * 4.0 * saturate(u) * (1.0 - saturate(u));
                        float dArc = uv.y - arcY;
                        float mid = ax + step0 * 0.5;
                        // Flare where the signal packet is passing. Folding `flow` in is what
                        // stops a bypassed or fully-dry echo from twinkling along with the audio.
                        float near = 1.0 - saturate(abs(_Playhead - mid) / max(step0, 1e-4));
                        float flare = saturate(max(saturate(_Activity * 2.0) * lit * near,
                                                   scRipple(mid, _Phase, flow)));
                        float shown = step(0.002, lvl);
                        scOver(acc, sigCol * (1.0 + 0.35 * flare),
                               scLine(dArc, thickY() * 1.1) * inSpan * shown * (0.55 + 0.45 * flare));
                        scAdd(acc, sigCol * scGlow(dArc, thickY() * 3.5) * inSpan * shown * gain * (0.20 + 0.8 * flare));

                        // impact cap on each REPEAT (k >= 1), as bright as that repeat is loud
                        float2 hit = float2(ax, base);
                        float dHit = length((uv - hit) * float2(_QuadSize.x / max(_QuadSize.y, 1.0), 1.0)) - 0.035;
                        scAdd(acc, sigCol * scGlow(dHit, 0.05) * gain * step(0.5, k) * saturate(lvl * 1.5) * (0.25 + 0.75 * flare));
                    }
                }
                else if (mode == 7)
                {
                    // DECAY (reverb): filled exp tail + reflection ticks.
                    float y0 = scEval(7, uv.x, _P0, _P1, 0.0);
                    float under = scFill(uv.y - y0);
                    scOver(acc, fillCol.rgb, under * (fillCol.a + 0.1));
                    float dline = scCurveDist(7, uv, _P0, _P1, 0.0);
                    scOver(acc, sigCol * (1.0 + 0.45 * ripple), scLine(dline, thickY()));
                    scAdd(acc, sigCol * scGlow(dline, thickY() * 3.5) * glowAmt * (0.20 + 1.6 * ripple) * 0.5);
                    // reflection ticks
                    float dens = _P0.y, k = 3.0 + _P0.x * 8.0;
                    int ticks = (int)floor(6.0 + dens * 14.0);
                    [loop] for (int j = 0; j < 20; j++)
                    {
                        if (j >= ticks) break;
                        float t = pow(float(j) / max(float(ticks), 1.0), 0.85);
                        float tx = 0.05 + t * 0.9;
                        float v = exp(-t * 9.0 / k) * (0.55 + 0.45 * scHash(float(j) + 1.0));
                        float dseg = scSeg(uv, float2(tx, 0.06), float2(tx, 0.06 + v * 0.84));
                        // Each reflection lights as the packet reaches it — the tail "rings out".
                        float tickLit = scRipple(tx, _Phase, flow);
                        scOver(acc, sigCol * (1.0 + 0.7 * tickLit),
                               scLineAA(dseg, 0.8 / max(_QuadSize.x, 1.0), aax) * (0.6 + 0.4 * tickLit));
                    }
                }
                else if (mode == 8)
                {
                    // SPECTRUM backdrop stand-in (until a real FFT texture, §1.8):
                    // an animated silhouette; the composite curve draws over it elsewhere.
                    float bars = 22.0;
                    float bi = floor(uv.x * bars);
                    float h = 0.2 + 0.6 * scHash(bi * 1.7)
                            * (0.6 + 0.4 * sin(_Phase * 6.28318 + bi * 0.9));
                    float below = step(uv.y, 0.06 + h * 0.8);
                    scOver(acc, sigCol, below * 0.5);
                }
                else if (mode == 9)
                {
                    // VU LED LADDER (GN-UV meter): a row of segmented LEDs lit from the zero end
                    // up to _P0.x (real output level). green → amber → red near the top, mirroring
                    // the reference broadcast VU meter. Unlit segments show a faint housing so the
                    // ladder reads even in silence; only the LIT extent reacts to audio.
                    //
                    // AUTO-ROTATES from the live quad aspect, exactly like SDFSlider decides
                    // horizontal-vs-vertical from _QuadSize each frame — so a meter squeezed into a
                    // narrow column (DU-K's sidechain activity display, this device's own module
                    // when the panel is narrow) becomes a vertical ladder instead of an unreadable
                    // sliver of horizontal segments. No prop to author either way; the picture
                    // always matches the box it's actually drawn in.
                    bool vertical = _QuadSize.y > _QuadSize.x;
                    float along = vertical ? uv.y : uv.x;
                    float across = vertical ? uv.x : uv.y;

                    float level = saturate(_P0.x);
                    // Segment count is a LOOK choice (MeterStyle): 20 LEDs, 40 fine LEDs, or 0 = one
                    // solid bar with no gaps — where each pixel is its own "segment".
                    bool solid = _VuSegments < 0.5;
                    float segN = solid ? 1.0 : _VuSegments;
                    float seg = floor(along * segN);
                    float segCenter = solid ? along : (seg + 0.5) / segN;
                    // gap between LEDs
                    float within = frac(along * segN);
                    float ledMask = solid ? 1.0 : smoothstep(0.08, 0.14, within) * smoothstep(0.08, 0.14, 1.0 - within);
                    // margin across the ladder's short axis
                    float crossMask = smoothstep(0.12, 0.2, across) * smoothstep(0.12, 0.2, 1.0 - across);
                    float body = ledMask * crossMask;
                    // per-segment colour: low zone, then mid from _VuZones.x, high from _VuZones.y.
                    // Each zone is the look's colour when it names one (alpha > 0), else the
                    // classic broadcast green / amber / red.
                    float3 green = _VuLowColor.a  > 0.001 ? _VuLowColor.rgb  : float3(0.30, 0.95, 0.32);
                    float3 amber = _VuMidColor.a  > 0.001 ? _VuMidColor.rgb  : float3(1.0, 0.72, 0.12);
                    float3 red   = _VuHighColor.a > 0.001 ? _VuHighColor.rgb : float3(1.0, 0.22, 0.16);
                    float midAt = _VuZones.x > 0.0 ? _VuZones.x : 0.6;
                    float highAt = _VuZones.y > 0.0 ? _VuZones.y : 0.85;
                    float3 col = segCenter < midAt ? green : (segCenter < highAt ? amber : red);
                    float lit = step(segCenter, level + 0.0001);
                    // unlit housing: a very dim tint of the segment colour — unless the finish names
                    // one (_HousingColor alpha > 0, 2026-09-13). A dim tint is a housing on a dark
                    // screen and a row of dark stripes on a pale one (Flat/Neomorphic Light).
                    bool housingSet = _HousingColor.a > 0.001;
                    float3 housing = housingSet ? _HousingColor.rgb : col * 0.12;
                    float housingA = housingSet ? _HousingColor.a : 0.6;
                    scOver(acc, housing, body * (1.0 - lit) * housingA);
                    // lit LED + glow (the glow follows the finish: flat screens have none; every
                    // shipped LED finish has _Glow >= 1, so they are unchanged)
                    scOver(acc, col, body * lit);
                    scAdd(acc, col * body * lit * 0.5 * saturate(_Glow));
                }
                else
                {
                    // Curve modes 1,2,3,5 (mode 0 handled above).
                    if (mode == 1)
                    {
                        // STATIC spectrum silhouette of the whole sample behind the response
                        // curve (item 7.2), on the same log-freq x-axis. Real data when fed
                        // (_SpecTex), else a procedural stand-in. NOT animated.
                        if (_HasSpec > 0.5)
                        {
                            // 3-tap horizontal average across neighbouring bins on top of the
                            // analyzer's gaussian — kills the last of the stair-stepping when the
                            // spectrum is stretched wide, matching the waveform's smoothness.
                            float du = 1.0 / max(_QuadSize.x, 1.0);
                            float sh = (tex2D(_SpecTex, float2(uv.x - du, 0.0)).r
                                      + tex2D(_SpecTex, float2(uv.x, 0.0)).r * 2.0
                                      + tex2D(_SpecTex, float2(uv.x + du, 0.0)).r) * 0.25;
                            // FILL THE SCREEN (2026-09-13, user direction). The display has no
                            // amplitude scale, so it is free to present the spectrum for legibility
                            // rather than as a measurement: the analyzer normalises to the peak, and
                            // a perceptual curve lifts the many bins far below it so the silhouette
                            // uses the height instead of hugging the floor. The response line's zero
                            // is unrelated to this and stays where it is.
                            // 2026-09-17: the analyzer now hands over a LEVEL (dB, top 66 dB — see
                            // WaveformAnalyzer.AnalyzeWholeSpectrum), which is already perceptual.
                            // The old pow(0.6) lift was compensating for linear magnitudes and would
                            // now flatten a kick's bass hump into everything else.
                            float shv = saturate(sh);
                            float top = 0.03 + shv * 0.90;
                            float below = 1.0 - smoothstep(top - aax, top + aax, uv.y);
                            // THE NOTE IS THE INFORMATION (2026-09-13, user direction): the
                            // spectrum of what the pad plays is shown in full whenever the module
                            // is POWERED, whether or not the filter is shaping it yet — only the
                            // response LINE (drawCurve below, graded by `lit`) dims when idle and
                            // glows when engaged. Powered off, it is not drawn at all, so a dark
                            // screen does not visibly update when you change pads.
                            float specOn = powered;
                            // bright lit edge along the silhouette, like the waveform's glow
                            float3 edgeCol = (uv.x < 0.366)
                                ? lerp(_LowColor.rgb, _MidColor.rgb, saturate(uv.x / 0.366))
                                : lerp(_MidColor.rgb, _HighColor.rgb, saturate((uv.x - 0.366) / 0.333));
                            float edge = 1.0 - saturate(abs(uv.y - top) / max(fwidth(uv.y) * 1.2, 1e-4));
                            scOver(acc, edgeCol, edge * 0.85 * specOn);
                            scAdd(acc, edgeCol * scGlow(uv.y - top, 0.025) * 0.22 * specOn);
                            // Tint by BAND, using the same low/mid/high colors the waveforms use,
                            // so "where the energy is" reads identically across every display. The
                            // x-axis is log-frequency, and the analyzer splits bands at 250 Hz and
                            // 2.5 kHz, which land at x = 0.366 and x = 0.699 on that axis.
                            float3 bandCol = (uv.x < 0.366)
                                ? lerp(_LowColor.rgb, _MidColor.rgb, saturate(uv.x / 0.366))
                                : lerp(_MidColor.rgb, _HighColor.rgb, saturate((uv.x - 0.366) / 0.333));
                            // vertical ramp: brightest at the silhouette's top, like a lit bar
                            float ramp = saturate(uv.y / max(top, 1e-3));
                            scOver(acc, bandCol, below * (0.38 + 0.30 * ramp) * specOn);
                        }
                        else
                        {
                            float bars = 24.0;
                            float bi = floor(uv.x * bars);
                            float sh = 0.15 + 0.5 * scHash(bi * 1.7);
                            float below = step(uv.y, 0.04 + sh * 0.7);
                            scOver(acc, sigCol, below * 0.14);
                        }
                    }
                    drawCurve(acc, mode, uv, 0.0, sigCol, _FillEnabled, fillCol, glowAmt, ripple);
                }

                // ============================================================
                // 6. Handles (freq-response mode): dots on the curve
                // ============================================================
                float4 H[3]; H[0] = _H0; H[1] = _H1; H[2] = _H2;
                float3 HC[3];
                HC[0] = scEngage(_H0Color.rgb, _BgColor.rgb, lit);
                HC[1] = scEngage(_H1Color.rgb, _BgColor.rgb, lit);
                HC[2] = scEngage(_H2Color.rgb, _BgColor.rgb, lit);
                float aspect = _QuadSize.x / max(_QuadSize.y, 1.0);
                for (int hi = 0; hi < 3; hi++)
                {
                    if (H[hi].z < 0.5) continue;
                    float2 d = (uv - H[hi].xy) * float2(aspect, 1.0);
                    float rr = 4.5 / max(_QuadSize.y, 1.0);
                    float dd = length(d) - rr;
                    scOver(acc, HC[hi], scFill(dd));
                    scAdd(acc, HC[hi] * scGlow(dd, rr) * gain * 0.5);
                }

                // ============================================================
                // 7. Playhead sweep
                // ============================================================
                if (_Playhead >= 0.0)
                {
                    float dph = abs(uv.x - _Playhead) / max(fwidth(uv.x), 1e-4);
                    float phm = 1.0 - saturate(dph - 0.6);
                    scOver(acc, headCol, phm * 0.7);
                }

                // ============================================================
                // 7.5 Display surface -- what you are looking THROUGH
                // ============================================================
                // Order matters and is physical: the emissive picture is first broken into
                // whatever physically emits it (LED cells / LCD segments / scanlines), THEN
                // the things that live in front of it (haze, sheen, tint, vignette), THEN the
                // bezel it is all recessed into. Sheen before pixelation would dice the
                // reflection into the pixel grid, which no real display does.
                if (_SurfaceMode > 0.5)
                {
                    float2 px = float2(max(_QuadSize.x, 1.0), max(_QuadSize.y, 1.0));

                    // -- emitter structure: discrete cells with dark gutters --
                    if (_PixelCellsX > 0.5 || _PixelCellsY > 0.5)
                    {
                        float2 cells = float2(_PixelCellsX > 0.5 ? _PixelCellsX : px.x / 3.0,
                                              _PixelCellsY > 0.5 ? _PixelCellsY : px.y / 3.0);
                        float2 f = frac(uv * cells) * 2.0 - 1.0;   // -1..1 inside the cell
                        float halfCell = 1.0 - saturate(_PixelGap);

                        // Roundness blends a square cell (LCD segment) into a round one (LED dot).
                        float2 q = abs(f);
                        float boxD = max(q.x, q.y) - halfCell;
                        // The DOT has to be round in PIXELS, not in cell space. A module's cell
                        // counts rarely divide its quad into squares (30 x 10 over 110 x 82 px is
                        // nearly 1:2), and an uncorrected disc SDF in cell space then draws a
                        // column of ellipses — which is not what an LED panel looks like. Scaling
                        // the long axis by the cell's own aspect makes it a circle inscribed in
                        // the short side, leaving the extra room as pitch.
                        float2 cellPx = max(px / max(cells, 1e-3), 1e-3);
                        float2 aspectQ = q * (cellPx / min(cellPx.x, cellPx.y));
                        float discD = length(aspectQ) - halfCell;
                        float d = lerp(boxD, discD, saturate(_PixelRound));

                        float aa = fwidth(d) + 1e-4;
                        float cell = 1.0 - smoothstep(-aa, aa, d);

                        // Gutters fall to the unlit level rather than to black, so the panel
                        // still reads as a physical grid of dark emitters when nothing is lit.
                        acc.rgb *= lerp(saturate(_PixelFloor), 1.0, cell);
                    }

                    // -- scanlines --
                    if (_ScanlineAmount > 0.001)
                    {
                        float pitch = max(_ScanlinePitchPx, 1.0);
                        float sl = 0.5 + 0.5 * cos(uv.y * px.y * (6.2831853 / pitch));
                        acc.rgb *= lerp(1.0, sl, saturate(_ScanlineAmount));
                    }

                    // -- plastic: milky haze (diffusion in the material itself) --
                    if (_PlasticHaze > 0.001)
                    {
                        float lum = dot(acc.rgb, float3(0.299, 0.587, 0.114));
                        acc.rgb = lerp(acc.rgb, lerp(acc.rgb, lum.xxx, 0.35) + 0.05, saturate(_PlasticHaze));
                    }

                    // -- tint: the color OF the glass, multiplied not added --
                    if (_SurfaceTint.a > 0.001)
                        acc.rgb = lerp(acc.rgb, acc.rgb * _SurfaceTint.rgb, _SurfaceTint.a);

                    // -- vignette: the face darkening into its own housing --
                    if (_VignetteAmount > 0.001)
                    {
                        float2 vg = (uv - 0.5) * 2.0;
                        acc.rgb *= 1.0 - saturate(dot(vg, vg) * 0.35 * _VignetteAmount);
                    }

                    // -- 7.6 the cover sheet, lit by the scene's three lamps --------
                    // rawUv, NOT the curve-warped uv: the glass is a physical object at
                    // the quad's real coordinates. The warp bends the PICTURE behind it;
                    // bending the reflection by the same amount would mean the glass was
                    // reflecting through itself.
                    float2 lightSpacePos = UI_DISPLAY_LIGHT_POS(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));
                    UI_DISPLAY_SURFACE_DESC(surf, _SurfaceMode, _BezelPx, _BezelRoundPx, px)
                    UI_APPLY_DISPLAY_SURFACE(acc, rawUv, lightSpacePos, surf);

                    // Anything the curve pushed off the glass is housing, not picture.
                    if (offGlass > 0.001)
                        scOver(acc, _BezelColor.rgb, offGlass * _BezelColor.a);

                    // -- bezel: the recess the whole face sits in --
                    if (_BezelPx > 0.001)
                    {
                        float2 halfPx = px * 0.5;
                        float r = min(_BezelRoundPx, min(halfPx.x, halfPx.y));
                        float2 pxPos = abs(rawUv * px - halfPx) - (halfPx - _BezelPx - r);
                        float bd = length(max(pxPos, 0.0)) + min(max(pxPos.x, pxPos.y), 0.0) - r;
                        float frame = smoothstep(-1.0, 1.0, bd);   // 1 outside the glass
                        scOver(acc, _BezelColor.rgb, frame * _BezelColor.a);

                        // The frame is a raised moulding, so it takes the light too —
                        // otherwise a lit screen sits in a dead flat border and the whole
                        // module reads as a sticker. Its surface slopes down into the well,
                        // so the aperture gradient IS its outward normal; lamp-facing side
                        // catches a highlight, far side falls into shade. The old code
                        // added a fixed white inner lip here instead, which is the same
                        // painted-light mistake the sheen band was — and it is redundant
                        // now that the glass has a real rolled edge of its own.
                        // Analytic outward normal, NOT ddx/ddy — ddy is a screen derivative
                        // (y down) while uv and the lamps are y up, so a derivative here would
                        // light the top edge as if it were the bottom. See uiDispApertureGrad.
                        float2 bnorm = uiDispApertureGrad(rawUv, px, _BezelPx, _BezelRoundPx);
                        float3 keyToL = UIToLightVector(UILightDirection(_GlobalLightPos1, lightSpacePos));
                        float  facing = dot(bnorm, normalize(keyToL.xy + 1e-5));
                        float  edgeBand = saturate(1.0 - abs(bd) / max(_BezelPx, 1.0));
                        float3 keyRgb = (_GlobalLightFx1.x > 0.5) ? _GlobalLightColor1.rgb : float3(1, 1, 1);
                        scAdd(acc, keyRgb * saturate(facing) * edgeBand * frame * 0.13);
                        acc.rgb *= 1.0 - saturate(-facing) * edgeBand * frame * 0.35;
                    }
                }

                // ── Cut-in: the hole in the faceplate this display sits in ───
                {
                    float2 cutPx = float2(max(_QuadSize.x, 1.0), max(_QuadSize.y, 1.0));
                    float2 cutL = UI_DISPLAY_LIGHT_POS(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));
                    UI_APPLY_DISPLAY_CUT_IN(acc, rawUv, cutPx, cutL);
                }

                // ── Receive shadows cast by neighbouring widgets ──────────────
                // Gated like SDFPanel's: the shared buffer has no per-panel stacking concept,
                // so a display sitting in FRONT of other panels must be able to opt out rather
                // than pick up shadows cast by widgets behind it.
                if (_ReceiveSceneShadows > 0.5 && acc.a > 0.001)
                    acc.rgb *= UIDisplayReceiveShadow(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));

                // ============================================================
                // 7b. POWER — the glass itself
                // ============================================================
                // Applied LAST of the picture stages and to everything at once, because that is
                // what losing power means: it is not a property of the trace, or of the grid, or
                // of the finish, so it cannot be folded into any of them. What is left at 0 is the
                // well's own colour at a quarter brightness — a dark screen still catches a little
                // light, and going to pure black would read as a hole cut in the faceplate.
                //
                // The floor of 0.10 keeps a hint of the layout visible when the module is
                // bypassed, so the display still reads as a SCREEN that is off rather than as a
                // panel that has nothing on it.
                {
                    float3 dead = _BgColor.rgb * 0.25;
                    acc.rgb = lerp(dead, acc.rgb, 0.10 + 0.90 * powered);
                }

                // ============================================================
                // 8. Clip + final composite (premultiplied)
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
