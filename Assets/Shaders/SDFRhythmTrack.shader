// ============================================================================
// SDFRhythmTrack.shader — the Guitar-Hero note highway (tracker §1.7)
// ============================================================================
// The whole play surface renders on ONE UGUI quad: a perspective-projected
// 4-lane track with neon rails, scrolling beat grid, note gems colored by pad
// ROW (red=bottom, green=2nd, orange=3rd, blue=top — lanes are pad COLUMNS),
// glowing hit-line receptors, per-lane hit/miss flashes, starfield backdrop,
// depth fog and a radiance/additive style axis. All pure math + one data
// texture — no per-note GameObjects, so a full song costs the same as an
// empty track.
//
// DATA CONTRACT (written by TrackLanesView.RebuildNoteTexture):
//   _NoteTex — RGBAFloat, width = time texels, height = 4 (one row per lane),
//   point-filtered, clamped. Texel at (t, lane) describes the NEAREST note in
//   that lane at time t:  R = start16th   G = end16th
//                         B = padRow + bank*4   A = velocity 0..1
//   Empty lane regions store R=+1e7, G=-1e7 (any distance test fails).
//   The shader reconstructs exact SDF edges from R/G, so gem outlines stay
//   crisp at any resolution — texel density only limits how close two notes
//   can sit before the nearer one wins the texel.
//
//   REVIEW OVERLAY (Docs/RecordingPlan.md §5) — two more strips on the SAME
//   width and time mapping as _NoteTex, so one `uSelf` samples all three:
//   _GhostTex — what you actually PLAYED. R = your hit's start16th,
//               G = the reference note it was aiming at, B = padRow + bank*4,
//               A = signed offset in 16ths (negative early), or >40 for a hit
//               with no target at all. Drawn as an outline beside the gem.
//   _HeatTex  — how the note has gone across the runs on show. R = hit rate
//               0..1, G = mean offset, B = spread, A = 1 if any run attempted
//               it. Drives the heat ring and the hollow-missed-note treatment.
//   _OnionMode picks what's drawn: 0 off · 1 last run · 2 stack · 3 heat.
//   With _OnionMode 0 (normal play) neither strip is sampled.
//
// PER-FRAME UNIFORMS (set by TrackLanesView.LateUpdate):
//   _Scroll16 (time at the hit line, in 16ths — countdown pre-roll included),
//   _BeatPhase/_BarPhase (0..1 saw), _CountdownFactor, _QuadSize (px),
//   _HitFlash (per-lane 0..1 decay), _HitColor0..3 (accuracy-tinted flash),
//   _Looping (0/1 — gates whether time past the end of a one-shot song wraps
//   back to show phantom notes from the start; see section 3/6/7 pastEnd).
//
// FRAGMENT SECTIONS:
//   1 Background  2 Track bed  3 Beat grid  4 Lane dividers  5 Rails
//   6 Hit line + receptors + flashes  7 Note gems + sustain tails
//   7b Ghost hits + drift tails (review overlay)
//   8 Depth fog veil  9 Vignette + countdown  10 Clip + final composite
// ============================================================================

Shader "UI/SDFRhythmTrack"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        // ── note data (runtime) ──
        _NoteTex ("Note Data (RGBAFloat strip)", 2D) = "black" {}
        // Which note OWNS each stretch of a lane for its row numeral: R = that note's start16th,
        // G = 16ths to the next note in the lane, B = padRow + bank*4, A = 1 (0 = no note yet).
        _CardTex ("Numeral Owners (RGBAFloat strip)", 2D) = "black" {}

        // ── take review overlay (Docs/RecordingPlan.md §5) ──
        _GhostTex ("Ghost Hits (RGBAFloat strip)", 2D) = "black" {}
        _HeatTex ("Per-note Heat (RGBAFloat strip)", 2D) = "black" {}
        _OnionMode ("Review Mode 0=off 1=last 2=stack 3=heat", Float) = 0
        _OnionOpacity ("Review Overlay Opacity", Range(0,1)) = 1
        _HasGhost ("Ghost Data Present", Float) = 0
        _HasHeat ("Heat Data Present", Float) = 0
        _ShowDrift ("Draw Drift Tails", Float) = 1
        _ShowExtra ("Draw Extra Hits", Float) = 1
        _ShowMissed ("Hollow Out Missed Notes", Float) = 1
        _MissRevealAhead ("Mark Misses Before They Arrive", Float) = 1
        _GhostWindow16 ("Offset Normalisation (16ths)", Float) = 4
        _GhostEarlyColor ("Ghost Early (rushing)", Color) = (0.39, 0.72, 1.0, 1)
        _GhostLateColor ("Ghost Late (dragging)", Color) = (1.0, 0.65, 0.24, 1)
        _GhostOnColor ("Ghost On Time", Color) = (0.49, 0.88, 0.54, 1)
        _GhostExtraColor ("Ghost Extra (no target)", Color) = (0.84, 0.42, 1.0, 1)
        _HeatColdColor ("Heat: never land it", Color) = (0.77, 0.17, 0.24, 1)
        _HeatMidColor ("Heat: sometimes", Color) = (0.91, 0.69, 0.24, 1)
        _HeatHotColor ("Heat: own it", Color) = (0.27, 0.85, 0.53, 1)
        _SeqLen16 ("Sequence Length (16ths)", Float) = 0
        _Looping ("Looping (0/1)", Float) = 1
        _Scroll16 ("Scroll Position (16ths)", Float) = 0
        // +1 = notes APPROACH the hit line (play-along: you match what's coming).
        // -1 = notes RECEDE from it (recording: they're being created and flow away).
        _TimeDir ("Time Direction (+1 approach / -1 recede)", Float) = 1
        _BeatPhase ("Beat Phase 0-1", Range(0,1)) = 0
        _BarPhase ("Bar Phase 0-1", Range(0,1)) = 0
        _CountdownFactor ("Countdown Factor", Range(0,1)) = 1
        _QuadSize ("Quad Size px (set at runtime)", Vector) = (380, 560, 0, 0)
        // Where the track's far end sits, as a fraction of the quad's height (1 = the top edge).
        // Below 1 the highway ends there and the sky carries on above it — room for a HUD that
        // the notes never scroll underneath (TrackLanesView.TrackTop).
        _TrackTop ("Track Far End (fraction of height)", Range(0.3, 1)) = 1
        _HitFlash ("Hit Flash per lane", Vector) = (0, 0, 0, 0)
        _HitColor0 ("Hit Flash Color L0", Color) = (1, 0.91, 0.66, 1)
        _HitColor1 ("Hit Flash Color L1", Color) = (1, 0.91, 0.66, 1)
        _HitColor2 ("Hit Flash Color L2", Color) = (1, 0.91, 0.66, 1)
        _HitColor3 ("Hit Flash Color L3", Color) = (1, 0.91, 0.66, 1)

        // ── row colors (pad row → gem color; bottom row first) ──
        _NoteColor0 ("Row 0 Color (bottom / RED)", Color) = (1.0, 0.23, 0.29, 1)
        _NoteColor1 ("Row 1 Color (GREEN)", Color) = (0.21, 0.91, 0.42, 1)
        _NoteColor2 ("Row 2 Color (ORANGE)", Color) = (1.0, 0.62, 0.18, 1)
        _NoteColor3 ("Row 3 Color (top / BLUE)", Color) = (0.25, 0.66, 1.0, 1)
        _BankDim ("Bank B/C Dim Step", Range(0, 0.4)) = 0.16

        // ── bank zones (TrackLanesView.BakeBankZones) ──
        // _BankTex: one row, bilinear. RGB = how much of this moment is bank A / B / C (blurred
        // across a change, so zones cross-fade); A = 1 when the song uses bank B or C at all.
        _BankTex ("Bank Zones (RGBA strip)", 2D) = "black" {}
        _BankColorA ("Bank A Colour", Color) = (1.0, 0.82, 0.25, 1)
        _BankColorB ("Bank B Colour", Color) = (0.26, 0.88, 0.45, 1)
        _BankColorC ("Bank C Colour", Color) = (1.0, 0.53, 0.16, 1)
        _BankRails ("Bank Colour on Rails", Range(0, 1)) = 1

        // ── track palette ──
        _RailColor ("Rail Color", Color) = (0.5, 0.9, 1.0, 1)
        _LaneLineColor ("Lane Divider Color", Color) = (0.55, 0.68, 0.9, 1)
        _LaneFillColor ("Track Bed Color", Color) = (0.045, 0.055, 0.10, 1)
        _HitLineColor ("Hit Line Color", Color) = (0.92, 0.97, 1.0, 1)
        _ReceptorColor ("Receptor Ring Color", Color) = (0.62, 0.72, 0.85, 1)
        _GridBarColor ("Grid Bar Color", Color) = (0.65, 0.80, 1.0, 1)
        _GridBeatColor ("Grid Beat Color", Color) = (0.40, 0.48, 0.66, 1)
        _BgTopColor ("Background Top", Color) = (0.012, 0.014, 0.035, 1)
        _BgBottomColor ("Background Bottom", Color) = (0.035, 0.045, 0.09, 1)
        _FogColor ("Fog / Horizon Color", Color) = (0.30, 0.38, 0.62, 1)
        _StarColor ("Star Color", Color) = (0.75, 0.83, 1.0, 1)
        _MissColor ("Miss Color", Color) = (1.0, 0.13, 0.22, 1)

        // ── geometry ──
        _Tilt ("View Tilt 0=flat 1=extreme", Range(0, 1)) = 0.55
        _NearWidth ("Track Width at Near Edge", Range(0.3, 1)) = 0.96
        _Visible16 ("Visible 16ths", Range(8, 128)) = 34
        _PlayLead16 ("Hit Line Lead (16ths)", Range(0, 16)) = 3
        _LaneUnit16 ("Lane Width in 16th Units", Range(0.4, 4)) = 1.5
        _NoteWidth ("Note Width (lane fraction)", Range(0.3, 1)) = 0.78
        _NoteCorner ("Note Corner Roundness", Range(0, 1)) = 0.42
        _MinNoteLen16 ("Gem Length (16ths)", Range(0.3, 2)) = 0.85
        _NoteBorderFrac ("Note Border Thickness (fraction)", Range(0, 0.45)) = 0.4
        _NoteSeparatorFrac ("Note Separator Thickness (fraction)", Range(0, 0.2)) = 0.06

        // ── style / effects ──
        _LaneFillAlpha ("Track Bed Opacity", Range(0, 1)) = 0.62
        _GridBrightness ("Grid Brightness", Range(0, 2)) = 0.7
        _PreRollDim ("Pre-roll Dim (track before bar 1)", Range(0, 1)) = 0.4
        _RailGlow ("Rail Glow", Range(0, 3)) = 1.1
        _NoteGlow ("Note Glow", Range(0, 3)) = 1.0
        _NoteCoreBoost ("Note Core Brightness", Range(0, 3)) = 1.0
        _Additive ("Note Body Additive Blend", Range(0, 1)) = 0.30
        _Radiance ("Master Radiance", Range(0, 3)) = 1.0
        _BeatPulse ("Beat Pulse Amount", Range(0, 2)) = 0.7
        _StarDensity ("Star Density", Range(0, 1)) = 0.45
        _HorizonGlow ("Horizon Glow", Range(0, 2)) = 0.7

        // ── SKY (the game-track theme axis) ───────────────────────────────────
        // An extra light layer between the gradient and the stars. 0 leaves the
        // background exactly as it was before skies existed, so every shipped
        // layout renders unchanged until a theme asks for one.
        //   0 none (stars only) · 1 nebula · 2 synthwave sun · 3 aurora
        //   4 club beams · 5 lit cable strands · 6 silk (smooth banded gradient)
        //   7 wireframe grid corridor
        // 1–3 are SPACE; 4–6 deliberately are not, so the game's look isn't one
        // genre with six palettes on it.
        _SkyMode ("Sky Mode", Float) = 0
        _SkyColorA ("Sky Color A", Color) = (0.42, 0.24, 0.72, 1)
        _SkyColorB ("Sky Color B", Color) = (0.11, 0.44, 0.78, 1)
        _SkyAmount ("Sky Strength", Range(0, 3)) = 1
        _SkyScale ("Sky Feature Scale", Range(0.2, 12)) = 3
        // Where the sun sits, in SCREEN v. NOT derived from _Tilt: at every tilt the
        // app actually uses, the track's true vanishing point is well ABOVE the
        // quad (H > 1), so a sun placed on it would be entirely off screen. This is
        // a composition choice, and the theme gets to make it.
        _SkyHorizon ("Sky Horizon (screen v)", Range(0, 1)) = 0.72

        // ── ONE SKY, MANY QUADS ───────────────────────────────────────────────
        // This quad's footprint in screen space: xy = bottom-left, zw = size, both
        // normalized 0..1. The sky is sampled through it, so the track and the two
        // stages either side of it are three windows onto ONE continuous space
        // rather than three copies of the same picture — which is what a big
        // feature like the sun makes unmissable (three suns, one per panel).
        // Default (0,0,1,1) = "this quad IS the screen", so anything that doesn't
        // set it renders exactly as before.
        _SkyRect ("Sky Window (x, y, w, h)", Vector) = (0, 0, 1, 1)
        // Screen aspect for that shared space. 0 = fall back to this quad's own.
        _SkyAspect ("Sky Space Aspect", Float) = 0
        // Where the ONE sun sits horizontally in that shared space. 0.5 is the
        // middle of the screen, which is the middle of the TRACK only when the
        // track happens to be centred — and on the front door it isn't, so the sun
        // rose out of the panel's right edge with half of it cut off. The app sets
        // this to the track's own centre; every surface gets the same number, so
        // there is still exactly one sun and it is behind the highway.
        _SkySunU ("Sky Sun (shared u)", Range(0, 1)) = 0.5
        // How much of the sky survives behind the track bed. Low enough that the
        // notes always win, high enough that the sun the highway is running into is
        // still visibly there.
        _SkyTrackDim ("Sky Dim Behind Track", Range(0, 1)) = 0.35
        _Fog ("Depth Fog", Range(0, 1)) = 0.62
        _Vignette ("Vignette", Range(0, 1)) = 0.4
        _HitFlashStrength ("Hit Flash Strength", Range(0, 3)) = 1.2
        _EnergizeOnPass ("Receptor Lights On Note Pass", Float) = 1

        // ── NOTE NUMERALS ─────────────────────────────────────────────────────
        // The pad ROW (1 at the bottom, 4 at the top) printed on a tab standing up
        // out of every gem, matching the numbers silkscreened either side of the
        // PD-48's grid. Colour tells you which row a note is in and always has;
        // this is the same fact in a second channel, for anyone who cannot use the
        // first one and for anyone learning the grid. Off is a preference, not a
        // different game: nothing else changes with it.
        _NoteNumbers ("Note Numerals", Float) = 1
        _NoteNumberSize ("Note Numeral Size", Range(0.2, 4)) = 1.86
        _NoteNumberLift ("Note Numeral Lift (gem heights)", Range(0.6, 8)) = 3.6

        // ── BACKDROP MODE ─────────────────────────────────────────────────────
        // 1 = draw the SKY ONLY — gradient, starfield, horizon glow, fog, vignette —
        // with the highway itself (bed, grid, lane lines, rails, hit line, receptors,
        // gems, ghosts, flashes) switched off. Same shader, same palette, same scrolling
        // clock, so a panel using it is visibly the SAME SPACE the track lives in rather
        // than a second look somebody has to keep in step by hand. That is what lets the
        // play screen's side stages read as one continuous sky with the track cut into it.
        _BackdropOnly ("Backdrop Only (sky, no highway)", Float) = 0

        // ── DISPLAY SURFACE ───────────────────────────────────────────────────
        // The cover the highway is seen through, lit by the SAME three scene lamps
        // every knob and button reads (CG/Core/UIDisplaySurface.cginc). The track had
        // no surface at all before — a bare emissive picture in a rack of lit hardware.
        // Off by default (_SurfaceMode 0), so an un-authored track is unchanged.
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
            #include "CG/SDF/SDFRhythmTrack.cginc"
            #include "CG/SDF/SDFDigits.cginc"
            // The cover sheet + the scene light rig it reflects. Also declares _GlobalLight*.
            #include "CG/Core/UIDisplaySurface.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            float4 _ClipRect;

            sampler2D _NoteTex;
            sampler2D _CardTex;
            sampler2D _GhostTex;
            sampler2D _HeatTex;
            float _OnionMode, _OnionOpacity, _HasGhost, _HasHeat;
            float _ShowDrift, _ShowExtra, _ShowMissed, _MissRevealAhead, _GhostWindow16;
            float _NoteNumbers, _NoteNumberSize, _NoteNumberLift;
            float4 _GhostEarlyColor, _GhostLateColor, _GhostOnColor, _GhostExtraColor;
            float4 _HeatColdColor, _HeatMidColor, _HeatHotColor;
            float _SeqLen16, _Looping, _Scroll16, _BeatPhase, _BarPhase, _CountdownFactor;
            float _TimeDir;
            float4 _QuadSize;
            float _TrackTop;
            float4 _HitFlash;
            float4 _HitColor0, _HitColor1, _HitColor2, _HitColor3;

            float4 _NoteColor0, _NoteColor1, _NoteColor2, _NoteColor3;
            float _BankDim;
            sampler2D _BankTex;
            float4 _BankColorA, _BankColorB, _BankColorC;
            float _BankRails;
            float4 _RailColor, _LaneLineColor, _LaneFillColor, _HitLineColor, _ReceptorColor;
            float4 _GridBarColor, _GridBeatColor, _BgTopColor, _BgBottomColor;
            float4 _FogColor, _StarColor, _MissColor;

            float _Tilt, _NearWidth, _Visible16, _PlayLead16, _LaneUnit16;
            float _NoteWidth, _NoteCorner, _MinNoteLen16, _NoteBorderFrac, _NoteSeparatorFrac;
            float _LaneFillAlpha, _GridBrightness, _PreRollDim, _RailGlow, _NoteGlow, _NoteCoreBoost;
            float _Additive, _Radiance, _BeatPulse, _StarDensity, _HorizonGlow;
            float _Fog, _Vignette, _HitFlashStrength, _EnergizeOnPass;
            float _BackdropOnly;
            float _SkyMode, _SkyAmount, _SkyScale, _SkyHorizon;
            float4 _SkyColorA, _SkyColorB;
            float4 _SkyRect;
            float _SkyAspect, _SkyTrackDim, _SkySunU;

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
                // Screen position for the light rig — the highway fills most of a panel,
                // so the lamp is sampled per fragment rather than from one anchor.
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

            // Select this lane's row color from packed row+bank*4.
            float3 rowColorFor(float rowBank)
            {
                float row = fmod(rowBank, 4.0);
                float bank = floor(rowBank / 4.0);
                float4 m = rtLaneMask4(row);
                float3 c = _NoteColor0.rgb * m.x + _NoteColor1.rgb * m.y
                         + _NoteColor2.rgb * m.z + _NoteColor3.rgb * m.w;
                return c * (1.0 - bank * _BankDim);
            }

            // Hit rate 0..1 → cold/mid/hot. Two-segment so the midpoint is a real amber rather
            // than the muddy olive a straight red→green lerp gives. Mirrors ReviewPalette
            // .ForHitRate exactly — the highway and the editor must not disagree about what a
            // colour means (see ReviewPalette's header).
            float3 rtHeatColor(float rate)
            {
                rate = saturate(rate);
                return (rate < 0.5)
                    ? lerp(_HeatColdColor.rgb, _HeatMidColor.rgb, rate * 2.0)
                    : lerp(_HeatMidColor.rgb, _HeatHotColor.rgb, (rate - 0.5) * 2.0);
            }

            // Signed offset in 16ths → the diverging early/late scale. Inside the Perfect window
            // it reads as "good" regardless of side; the side only starts mattering once you're
            // actually off. Mirrors ReviewPalette.ForOffset.
            float3 rtOffsetColor(float offset)
            {
                float a = abs(offset);
                float3 side = (offset < 0.0) ? _GhostEarlyColor.rgb : _GhostLateColor.rgb;
                float t = saturate((a - 0.5) / max(_GhostWindow16 - 0.5, 1e-3));
                float3 off = lerp(side, _MissColor.rgb, t * t);
                return (a <= 0.5) ? _GhostOnColor.rgb : off;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float aspect = _QuadSize.x / max(_QuadSize.y, 1.0);
                float time = _Time.y;

                // ── TRACK SPACE vs QUAD SPACE ──
                // The highway can end short of the quad's top edge (_TrackTop < 1): the sky still
                // fills the whole quad, but the track — and everything that lives on it — is laid
                // out in the band below. `vT` is the height up THAT band (0 bottom, 1 far end) and
                // `trackPxY`/`aspectT` are its pixel height and aspect; every perspective formula
                // below reads those instead of the quad's own. At _TrackTop 1 they ARE the quad's
                // own, so a highway that never sets it renders exactly as before.
                float trackTop = clamp(_TrackTop, 0.3, 1.0);
                float vT       = uv.y / trackTop;
                float trackPxY = max(_QuadSize.y * trackTop, 1.0);
                float aspectT  = _QuadSize.x / trackPxY;
                // A soft stop just short of the far end — only when there IS something above it.
                float farKeep  = (trackTop < 0.999) ? 1.0 - smoothstep(0.965, 1.0, vT) : 1.0;

                // ── perspective mapping (see SDFRhythmTrack.cginc header) ──
                float H    = rtHorizonFromTilt(_Tilt);
                float zs   = rtZScale(min(vT, 1.0), H);
                float d01  = rtDepth01(min(vT, 1.0), H);
                // _TimeDir flips which end of the highway is the FUTURE. At +1 this is the
                // original mapping exactly (far = later, notes come at you). At -1 the far end
                // becomes the PAST, so notes appear at the hit line and stream away — which is what
                // you want while recording, where the notes are yours and already played.
                float tNear = _Scroll16 - _TimeDir * _PlayLead16;
                float t16  = tNear + _TimeDir * d01 * _Visible16;

                float halfW  = 0.5 * _NearWidth;
                float trackX = (uv.x - 0.5) * zs / halfW;          // -1..1 inside track
                float laneF  = (clamp(trackX, -1.0, 1.0) * 0.5 + 0.5) * 4.0;
                float lane   = floor(min(laneF, 3.999));
                float laneLocal = frac(laneF) - 0.5;
                float xs = laneLocal * _LaneUnit16;                 // note-space lateral

                float trackD    = abs(trackX) - 1.0;                // >0 outside rails

                // Backdrop mode turns the HIGHWAY off, never the sky. Everything that lives on
                // the track is gated by `trackMask` already; `track` covers the four things that
                // are positioned by the track but not masked BY it — rails, receptors, hit
                // flashes and the rail energy dots — so section 1 needs no guard of its own.
                float track     = (1.0 - step(0.5, _BackdropOnly)) * farKeep;
                float trackMask = rtFill(trackD) * track;

                // Depth fade shared by everything that lives ON the track.
                float fogF     = _Fog * smoothstep(0.30, 1.0, d01);
                float fogAtten = 1.0 - fogF * 0.85;

                // Beat energy: sharp attack, cubic decay; countdown holds it back.
                float pulse  = pow(saturate(1.0 - _BeatPhase), 3.0) * _BeatPulse;
                float energy = lerp(0.8, 1.0, _CountdownFactor);

                // Wrapped time for looping sequences (t<0 = countdown pre-roll).
                // With no sequence loaded the wrap is a no-op (huge period) so the
                // idle grid stays a plain continuous bar/beat ruler.
                //
                // _Looping gates the wrap itself: for a ONE-SHOT (non-looping) song,
                // time must NOT wrap back to 0 once it passes the sequence length —
                // wrapping would resample _NoteTex's start and show phantom notes
                // from the beginning in the distance as playback nears the end, even
                // though the song was never going to loop (they never played — just
                // a rendering artifact of always-periodic sampling). `pastEnd` masks
                // note-gem/receptor sampling for any t16 beyond the true end in that
                // case; the grid/rails etc. are unaffected (nothing to wrap there).
                float haveNotes = step(0.5, _SeqLen16);
                float safeLen   = (haveNotes > 0.5) ? _SeqLen16 : 1e8;
                float looping   = (_Looping > 0.5) ? 1.0 : 0.0;
                float tCmp  = (looping > 0.5)
                    ? ((t16 >= 0.0) ? fmod(t16, safeLen) : t16)
                    : t16;
                float uSelf = saturate((looping > 0.5)
                    ? (((t16 >= 0.0) ? fmod(t16, safeLen) : 0.0) / safeLen)
                    : (t16 / safeLen));
                float pastEnd = (haveNotes > 0.5 && looping < 0.5 && t16 >= safeLen) ? 1.0 : 0.0;

                // HOW SQUASHED IS NOTE SPACE AT THIS PIXEL.
                //
                // Note space is deliberately NOT screen space: x is lateral and y is musical time,
                // and the ground-plane projection compresses time hard near the bottom of the
                // frame and harder still toward the horizon. A shape that is square in note space
                // therefore renders as a wide flat bar down here — fine for a gem, which is meant
                // to be a wide flat bar, and ruinous for anything with a READABLE shape: the row
                // numerals came out as a smear of segments until they were sized through this.
                //
                // One pixel spans `noteTexel` units of each axis, so the ratio is the correction a
                // shape needs to come out with the proportions it was drawn in. Computed here,
                // outside every branch, because a derivative taken inside non-uniform control flow
                // is undefined — and the note data that gates those branches is per-pixel.
                float2 noteTexel = float2(max(fwidth(xs), 1e-6), max(fwidth(tCmp), 1e-6));
                float laneV = (lane + 0.5) / 4.0;

                // ============================================================
                // 1. Background — vertical gradient + starfield + horizon glow
                // ============================================================
                // SHARED SKY SPACE. Everything in section 1 is sampled through this
                // rather than through the quad's own uv, so every panel showing the
                // sky is a window onto the same one — the stars line up across the
                // gap between the track and the stages, and there is exactly one sun.
                // The vertical gradient stays quad-local on purpose: it is the
                // TRACK's own depth ramp, not scenery.
                float2 skyUV = _SkyRect.xy + uv * _SkyRect.zw;
                float skyAspect = (_SkyAspect > 0.001) ? _SkyAspect : aspect;

                float3 bg = lerp(_BgBottomColor.rgb, _BgTopColor.rgb, uv.y);
                float4 acc = float4(bg, 1.0);

                // Sky layer FIRST, under the stars: a nebula with stars punched
                // through it reads as depth, a nebula painted over them reads as a
                // filter. Dimmed behind the track bed for the same reason the stars
                // are — the notes have to stay the brightest thing on the panel.
                float skyDim = lerp(1.0, _SkyTrackDim, trackMask);

                if (_SkyMode > 0.5 && _SkyAmount > 0.001)
                {
                    float3 sky = float3(0.0, 0.0, 0.0);
                    float3 skyA = _SkyColorA.rgb;
                    float3 skyB = _SkyColorB.rgb;

                    if (_SkyMode < 1.5)
                        sky = rtSkyNebula(skyUV, skyAspect, _Scroll16, time, skyA, skyB, _SkyAmount, _SkyScale);
                    else if (_SkyMode < 2.5)
                        sky = rtSkySun(skyUV, skyAspect, time, skyA, skyB, _SkyAmount, _SkyHorizon, _SkySunU);
                    else if (_SkyMode < 3.5)
                        sky = rtSkyAurora(skyUV, skyAspect, time, skyA, skyB, _SkyAmount);
                    else if (_SkyMode < 4.5)
                        sky = rtSkyBeams(skyUV, skyAspect, time, skyA, skyB, _SkyAmount);
                    else if (_SkyMode < 5.5)
                        sky = rtSkyStrands(skyUV, skyAspect, time, skyA, skyB, _SkyAmount);
                    else if (_SkyMode < 6.5)
                        sky = rtSkySilk(skyUV, skyAspect, time, skyA, skyB, _SkyAmount, _SkyScale);
                    else
                        sky = rtSkyGrid(skyUV, skyAspect, _Scroll16, time, skyA, skyB,
                                        _SkyAmount, _SkyHorizon);

                    rtAdd(acc, sky * skyDim * _Radiance);
                }

                if (_StarDensity > 0.001)
                {
                    // Two parallax layers streaming toward the player with the music.
                    float2 sp1 = skyUV * float2(skyAspect, 1.0) * 26.0 + float2(0.0, _Scroll16 * 0.030);
                    float2 sp2 = skyUV * float2(skyAspect, 1.0) * 52.0 + float2(3.7, _Scroll16 * 0.075);
                    float stars = rtStarLayer(sp1, _StarDensity * 0.5, time) * 0.85
                                + rtStarLayer(sp2, _StarDensity * 0.4, time) * 0.5;
                    stars *= lerp(1.0, 0.30, trackMask); // dimmed behind the track bed
                    rtAdd(acc, _StarColor.rgb * stars * _Radiance);
                }

                // The glow sits where the TRACK vanishes, and dies away above a lowered one — the
                // band up there is the HUD's, and a bright wash behind text is what makes it hard to
                // read. At _TrackTop 1, vT <= 1 everywhere and this is the original term exactly.
                float horizonV = pow(saturate(vT), 7.0) * saturate(1.0 - (vT - 1.0) * 4.0);
                rtAdd(acc, _FogColor.rgb * _HorizonGlow * horizonV * 0.55 * _Radiance);

                // ============================================================
                // 2. Track bed — dark glass surface, faint alternating lanes
                // ============================================================
                float laneAlt = fmod(lane, 2.0);
                float3 bedCol = _LaneFillColor.rgb * (1.0 + laneAlt * 0.18);
                rtOver(acc, bedCol, _LaneFillAlpha * trackMask);

                // ============================================================
                // 3. Beat grid — 16th / beat / bar lines scrolling with time
                // ============================================================
                float fw16 = max(fwidth(t16), 1e-5);              // 16ths per pixel
                float dInt  = abs(tCmp - round(tCmp));
                float dBeat = abs(tCmp / 4.0  - round(tCmp / 4.0))  * 4.0;
                float dBar  = abs(tCmp / 16.0 - round(tCmp / 16.0)) * 16.0;

                float show16ths = smoothstep(0.22, 0.08, fw16);    // hide when zoomed out
                float grid16  = rtLine(dInt,  0.55 * fw16) * show16ths * 0.30;
                float gridBeat = rtLine(dBeat, 0.75 * fw16) * 0.65;
                float gridBar  = rtLine(dBar,  1.10 * fw16) * (1.0 + pulse * 0.8);

                float gridA = _GridBrightness * trackMask * fogAtten * energy;
                rtOver(acc, _GridBeatColor.rgb, (grid16 + gridBeat) * 0.35 * gridA);
                rtOver(acc, _GridBarColor.rgb, gridBar * 0.55 * gridA);
                rtAdd(acc, _GridBarColor.rgb * gridBar * 0.22 * gridA * _Radiance);

                // ============================================================
                // 3b. Bank zone — which bank this stretch of the song is played on
                // ============================================================
                // THE SIDES OF THE TRACK SAY WHICH BANK (user, 2026-09-26: "all 4 lanes side
                // changes color if the notes expected are on bank B or C … bank A yellow, bank B
                // green, bank C orange"). The same three colours light the bank buttons on the pad
                // panel, so a stretch of green rails coming down the track means "switch to B"
                // before a single gem of it has to be read. A song that never leaves bank A keeps
                // the theme's own rails (A channel 0) — the colour only appears when it means
                // something.
                float4 bankW = tex2D(_BankTex, float2(uSelf, 0.5));
                float bankSum = max(bankW.r + bankW.g + bankW.b, 1e-4);
                float3 bankCol = (bankW.r * _BankColorA.rgb + bankW.g * _BankColorB.rgb
                                + bankW.b * _BankColorC.rgb) / bankSum;
                float bankAmt = saturate(bankW.a * (bankW.r + bankW.g + bankW.b)) * _BankRails * haveNotes;
                float3 railCol = lerp(_RailColor.rgb, bankCol, bankAmt);
                // Where one bank hands over to the next the weights cross, and their products peak:
                // a line across the track, a checkpoint in the new bank's colour. Sharpened from the
                // raw product (which is as wide as the whole cross-fade) to a narrow core with a soft
                // halo — a broad wash read as fog rolling over the notes, a line reads as a line.
                float bankCross = saturate(4.0 * (bankW.r * bankW.g + bankW.g * bankW.b + bankW.r * bankW.b));
                float bankGate = smoothstep(0.55, 1.0, bankCross) * bankAmt;
                float bankHalo = bankCross * bankAmt;
                rtOver(acc, bankCol, bankGate * 0.30 * trackMask * fogAtten);
                rtAdd(acc, bankCol * (bankGate * 0.22 + bankHalo * 0.06) * trackMask * fogAtten * _Radiance);
                // Light off the rails onto the bed, the width of a lane at the most: the zone is
                // readable at the edge of the eye without laying colour over the gems.
                float bankEdge = smoothstep(0.62, 1.0, abs(trackX)) * trackMask;
                rtAdd(acc, bankCol * bankEdge * bankEdge * 0.16 * bankAmt * fogAtten * _Radiance);

                // ============================================================
                // 4. Lane dividers (interior boundaries only)
                // ============================================================
                float fwLane = max(fwidth(laneF), 1e-5);
                float dLaneLine = abs(frac(laneF + 0.5) - 0.5);
                float interior = step(0.5, laneF) * step(laneF, 3.5);
                // `* trackMask` on BOTH, and the second one is a fix: the additive pass was the
                // only composite in the whole shader missing its gate, so the lane dividers kept
                // drawing in BACKDROP mode. That is the faint vertical banding that made the
                // stages either side of the track look like they had a grid in them whatever sky
                // was chosen — the one thing every theme appeared to share.
                float laneLine = rtLine(dLaneLine, 0.85 * fwLane) * interior * trackMask;
                float3 laneCol = lerp(_LaneLineColor.rgb, bankCol, bankAmt * 0.45);
                rtOver(acc, laneCol, laneLine * 0.40 * fogAtten);
                rtAdd(acc, laneCol * laneLine * 0.10 * fogAtten * _Radiance);

                // ============================================================
                // 4b. Pre-roll — the stretch of track before bar 1 recedes
                // ============================================================
                // t16 < 0 is the count-in (2026-09-14, the highway's half of MultiTrack's pre-roll
                // shade). Eased toward the theme's own far-sky colour rather than darkened by a
                // fixed amount, so it recedes inside every track theme's palette — a multiply would
                // do nothing to a near-black bed; what visibly fades is the grid and the lane lines.
                // Placed before the rails, hit line and notes, so an early hit in the count-in still
                // draws at full strength over it. fw16 is section 3's 16ths-per-pixel: the bar-1
                // edge is antialiased exactly like the bar line lying on it.
                float preRoll = saturate(0.5 - t16 / fw16) * trackMask;
                acc.rgb = lerp(acc.rgb, _BgBottomColor.rgb, preRoll * _PreRollDim);

                // ============================================================
                // 5. Rails — neon tube edges + outer glow + energy dots
                // ============================================================
                float fwX = max(fwidth(trackX), 1e-5);
                float dRailX = abs(abs(trackX) - 1.0);
                float railHalf = max(0.010, 1.2 * fwX);            // thins with distance
                float railCore = rtLine(dRailX, railHalf) * track;
                float railPulse = 1.0 + pulse * 0.5;
                float railG = _RailGlow * track;

                rtOver(acc, lerp(railCol, float3(1,1,1), 0.35), railCore * 0.95 * fogAtten);
                rtAdd(acc, railCol * rtGlow(dRailX, 0.10) * 0.35 * railG * railPulse * fogAtten * _Radiance * energy
                           * (1.0 + bankAmt * 0.35));
                // soft spill outside the track edges
                rtAdd(acc, railCol * rtGlow(max(trackD, 0.0), 0.16) * step(0.0, trackD) * 0.10 * railG * fogAtten * _Radiance);

                // Energy dots streaming up the rails with the music.
                {
                    float side = sign(trackX);
                    float dotTrack = tCmp * 0.5 + side * 13.7;
                    float cell = floor(dotTrack);
                    float fpos = frac(dotTrack);
                    float h = rtHash21(float2(cell, side * 4.2));
                    float dotGlow = exp(-pow(fpos - h, 2.0) * 220.0) * exp(-dRailX * dRailX * 2600.0);
                    rtAdd(acc, railCol * dotGlow * (0.25 + 0.55 * h) * railG * fogAtten * _Radiance);
                }

                // ============================================================
                // 6. Hit line + receptors + hit/miss flash
                // ============================================================
                float vHit  = rtInvDepth01(_PlayLead16 / max(_Visible16, 1e-3), H);
                float zsHit = rtZScale(vHit, H);
                float linePx = (vT - vHit) * trackPxY;

                float hitLine = rtLine(linePx, 1.4) * trackMask;
                float lineGlow = rtGlow(abs(linePx), 15.0) * trackMask;
                rtOver(acc, _HitLineColor.rgb, hitLine * 0.85);
                rtAdd(acc, _HitLineColor.rgb * lineGlow * 0.28 * (0.7 + pulse * 0.6) * _Radiance * energy);

                // Receptor ring for this fragment's lane (perspective ellipse).
                float laneHalfPx = (halfW / zsHit) / 4.0 * _QuadSize.x;   // half lane width @ hit line
                float centerTrackX = (lane + 0.5) * 0.5 - 1.0;
                float xCenterU = 0.5 + centerTrackX * halfW / zsHit;
                float squash = lerp(1.0, 0.42, saturate(_Tilt * 1.15));
                float2 pr = float2((uv.x - xCenterU) * _QuadSize.x,
                                   (vT - vHit) * trackPxY / max(squash, 1e-3));

                // Receptor energizes in the incoming note's row color as it crosses.
                // Same looping-gated time as the gems above — a one-shot song must
                // not wrap _Scroll16 back to sampling the start once it's actually over.
                float tHitCmp = (looping > 0.5)
                    ? ((_Scroll16 >= 0.0) ? fmod(_Scroll16, safeLen) : _Scroll16)
                    : _Scroll16;
                float uHit = saturate((looping > 0.5)
                    ? (((_Scroll16 >= 0.0) ? fmod(_Scroll16, safeLen) : 0.0) / safeLen)
                    : (_Scroll16 / safeLen));
                float pastEndHit = (haveNotes > 0.5 && looping < 0.5 && _Scroll16 >= safeLen) ? 1.0 : 0.0;
                float4 hitData = tex2D(_NoteTex, float2(uHit, laneV));
                float dHitNote = max(hitData.r - tHitCmp, tHitCmp - hitData.g);
                float energize = smoothstep(0.45, -0.05, dHitNote) * _EnergizeOnPass * haveNotes * (1.0 - pastEndHit);
                float3 receptorCol = lerp(_ReceptorColor.rgb, rowColorFor(hitData.b), energize);

                float ringR = laneHalfPx * (0.66 + pulse * 0.05 + energize * 0.10);
                float dRing = length(pr) - ringR;
                float ringMask = rtLine(dRing, 1.7) * track;
                rtOver(acc, receptorCol, ringMask * (0.55 + energize * 0.45));
                rtAdd(acc, receptorCol * rtGlow(abs(dRing), 9.0) * (0.12 + energize * 0.5) * _Radiance * energy * track);

                // Per-lane hit flash: filled burst + expanding shockwave + lane beam.
                float4 laneMask4 = rtLaneMask4(lane);
                float flash = dot(_HitFlash, laneMask4) * track;
                if (flash > 0.001)
                {
                    float3 flashCol = _HitColor0.rgb * laneMask4.x + _HitColor1.rgb * laneMask4.y
                                    + _HitColor2.rgb * laneMask4.z + _HitColor3.rgb * laneMask4.w;
                    float f2 = flash * flash;
                    // core burst
                    rtAdd(acc, flashCol * rtGlow(max(dRing, 0.0) + ringR * 0.4, ringR * 0.75) * f2 * 1.4 * _HitFlashStrength);
                    // expanding shockwave ring
                    float shockR = ringR * (1.0 + (1.0 - flash) * 2.1);
                    float shock = rtLine(length(pr) - shockR, 2.6) * f2;
                    rtAdd(acc, flashCol * shock * 0.9 * _HitFlashStrength);
                    // beam shooting up the lane
                    float beam = smoothstep(0.5, 0.10, abs(laneLocal))
                               * step(vHit, vT) * exp(-(vT - vHit) * 5.0);
                    rtAdd(acc, flashCol * beam * flash * 0.30 * _HitFlashStrength * fogAtten);
                }

                // ============================================================
                // 7. Note gems + sustain tails (crisp SDF from texel data)
                // ============================================================
                // Masked past the end of a one-shot (non-looping) song — see the
                // pastEnd/_Looping remarks above; without this, gems from the start
                // of the song would visibly wrap back into view as playback nears
                // the end even though they'll never actually play again.
                // Gem geometry is hoisted out of the branch: the review overlay below draws its
                // ghosts with the SAME box so a hit and the note it was aiming at are directly
                // comparable shapes — a ghost that is a different size reads as a different KIND
                // of thing, which is the opposite of the point.
                float gemLen = _MinNoteLen16;
                float hx = 0.5 * _NoteWidth * _LaneUnit16;
                float hy = 0.5 * gemLen;
                float rr = _NoteCorner * min(hx, hy);
                float laneEdgeFade = smoothstep(0.50, 0.34, abs(laneLocal));
                float reviewOn = (_OnionMode > 0.5) ? _OnionOpacity : 0.0;

                if (haveNotes > 0.5 && pastEnd < 0.5)
                {
                    float4 nd = tex2D(_NoteTex, float2(uSelf, laneV));
                    float nStart = nd.r, nEnd = nd.g, vel = nd.a;
                    float3 rowCol = rowColorFor(nd.b);
                    // Border ring color — used to be the "part"/instrument-identity color from
                    // _PartPalette, dropped so the highway reads as pure ROW color (red/green/
                    // orange/blue), matching the drum pads now that they carry no group tint
                    // either (2026-08-05 feedback).
                    float3 borderCol = rowCol;

                    // ── review: how this note has gone across the runs on show ──
                    // R = hit rate, G = mean offset, B = spread, A = was it ever attempted.
                    float4 heat = (_HasHeat > 0.5 && reviewOn > 0.0)
                        ? tex2D(_HeatTex, float2(uSelf, laneV)) : float4(0, 0, 0, 0);
                    float attempted = heat.a;
                    float hitRate = heat.r;

                    // A note you never landed becomes a HOLLOW ring instead of a solid gem — the
                    // shape of a hole, so a dropped note is visible at a glance in the distance
                    // rather than something you work out after it has already gone past.
                    float missed = (attempted > 0.5 && hitRate < 0.001 && _ShowMissed > 0.5)
                                 ? reviewOn : 0.0;
                    // While a pass is IN PROGRESS, a note ahead of the playhead hasn't been missed
                    // — it hasn't happened. Without this gate the live diff paints the entire rest
                    // of the song as failed, which is both wrong and demoralising.
                    missed *= max(_MissRevealAhead, step(nStart, _Scroll16));

                    // In HEAT mode the border ring carries the hit rate, so a bar of red-ringed
                    // gems is the practice list, visible while playing.
                    float heatMix = (_OnionMode > 2.5 && attempted > 0.5) ? reviewOn : 0.0;
                    borderCol = lerp(borderCol, rtHeatColor(hitRate), heatMix);

                    // gem head — anchored at the note's START (the hit moment)
                    float2 pGem = float2(xs, tCmp - (nStart + hy));
                    float dGem = rtRoundedBox(pGem, float2(hx, hy), rr);
                    float gemMask = rtFill(dGem) * trackMask;

                    // Gem: a ROW-colored border ring around a ROW-colored center fill (same
                    // color both rings now — see borderCol above), separated by a thin BLACK
                    // ring purely for definition/depth, not identity. Two inset copies of the
                    // same rounded-box SDF — one at the border/separator boundary, one at the
                    // separator/center boundary — give both rings the same AA the outer edge
                    // already gets.
                    float minHalf = min(hx, hy);
                    float border = _NoteBorderFrac * minHalf;
                    float sep = _NoteSeparatorFrac * minHalf;

                    float2 sepHalf = max(float2(0.001, 0.001), float2(hx, hy) - border);
                    float sepRR = max(0.0, rr - border);
                    float dGemSepOuter = rtRoundedBox(pGem, sepHalf, sepRR);
                    float sepMask = rtFill(dGemSepOuter); // inside the separator+center region

                    float2 innerHalf = max(float2(0.001, 0.001), float2(hx, hy) - border - sep);
                    float innerRR = max(0.0, rr - border - sep);
                    float dGemInner = rtRoundedBox(pGem, innerHalf, innerRR);
                    float centerMask = rtFill(dGemInner); // inside the true center-only region

                    float3 baseCol = lerp(borderCol, float3(0, 0, 0), sepMask);
                    baseCol = lerp(baseCol, rowCol, centerMask);

                    // Hollow out a missed note: knock the interior out of the fill mask and stain
                    // what's left red. `missed` is already 0 when review is off, so this whole
                    // treatment costs nothing in normal play.
                    baseCol = lerp(baseCol, _MissColor.rgb, missed * max(sepMask, centerMask));
                    gemMask *= 1.0 - missed * centerMask;

                    // sustain tail for held notes
                    float dur = max(nEnd - nStart, 0.0);
                    float tailMask = 0.0;
                    float dTail = 1e6;
                    if (dur > gemLen * 1.6)
                    {
                        float tA = nStart + gemLen * 0.5;
                        float tB = nStart + dur;
                        float2 pT = float2(xs, tCmp - (tA + tB) * 0.5);
                        dTail = rtRoundedBox(pT, float2(hx * 0.42, (tB - tA) * 0.5), rr * 0.5);
                        tailMask = rtFill(dTail) * trackMask;
                    }

                    // gem body shading: leading-edge energy, rim light, glass
                    // highlight, hot core — all from the SDF, no textures
                    float ins = saturate(-dGem / max(min(hx, hy), 1e-4));
                    float lead = saturate((tCmp - nStart) / gemLen);
                    float3 body = baseCol * lerp(1.30, 0.66, lead);
                    float rim = pow(1.0 - ins, 3.0);
                    body = lerp(body, lerp(baseCol, float3(1,1,1), 0.72), rim * 0.75);
                    float hl = smoothstep(0.12, 0.55, ins)
                             * smoothstep(0.95, 0.30, abs(pGem.x) / max(hx, 1e-4))
                             * smoothstep(0.10, -0.55, pGem.y / max(hy, 1e-4));
                    body += (baseCol * 0.4 + 0.35) * hl;
                    float core = exp(-(pGem.x * pGem.x / max(hx * hx, 1e-6)
                                     + pGem.y * pGem.y / max(hy * hy, 1e-6)) * 2.6);
                    body += (baseCol * 0.55 + 0.45) * core * 0.55 * _NoteCoreBoost;
                    body *= lerp(0.78, 1.16, vel) * energy;

                    // tail body: translucent column of the row color
                    float3 tailBody = rowCol * 0.75 * energy;

                    rtStyleComposite(acc, tailBody * fogAtten, tailMask * 0.55 * fogAtten, _Additive);
                    rtStyleComposite(acc, body * fogAtten, gemMask * fogAtten, _Additive);

                    // additive halo — the gem casts light onto the track
                    float halo = rtGlow(dGem, 0.34 * gemLen) * laneEdgeFade * trackMask;
                    float haloTail = rtGlow(dTail, 0.18 * gemLen) * laneEdgeFade * trackMask;
                    rtAdd(acc, rowCol * (halo * 0.55 + haloTail * 0.20) * _NoteGlow * fogAtten * _Radiance * energy);

                    // ── 7a. (the numerals are drawn after this block — see section 7n) ──
                }

                // ============================================================
                // 7n. Row numerals — a badge on EVERY note, no stick
                // ============================================================
                // THE NUMERAL IS NOT PAINTED ON THE FLOOR. Drawn in note space it lay flat on the
                // ground plane: foreshortened to a sliver near the horizon, and clipped by whatever
                // note happened to be behind it. A label belongs to the VIEWER — so it is drawn
                // square on screen, a row-coloured badge with the number dark on it, sitting on
                // its own note.
                //
                // NO STICK (user, 2026-09-26: "sometimes they don't have a stick at all and they are
                // at the bottom. This actually looks pretty tight so let's just do that and try 'no
                // stick' for any"). The card-on-a-pole had three sizes it switched between as a note
                // came down the track — full, lowered, badge — and each switch was a jump; the user
                // saw numbers hop as the notes around them moved. One shape at every distance grows
                // smoothly with the perspective and nothing else.
                //
                // EVERY NOTE GETS ONE, SIZED TO THE ROOM IT HAS. Each note OWNS the stretch of its
                // lane from its own front edge up to the next note's (_CardTex, baked by
                // TrackLanesView: the latest note — or cluster of near-simultaneous notes —
                // starting at or before each texel), and its badge is fitted inside that stretch.
                // A pixel has exactly one owner per lane, so two badges can never share a pixel and
                // there is nothing to sort.
                //
                // Only while notes APPROACH (_TimeDir > 0): while you record, the notes streaming
                // away are ones you have just played. Above a lowered far end the band belongs to
                // the HUD, so nothing is drawn up there (cardKeep).
                if (_NoteNumbers > 0.5 && haveNotes > 0.5 && _BackdropOnly < 0.5 && vT < 1.05 && _TimeDir > 0.0)
                {
                    float cardKeep = (trackTop < 0.999) ? 1.0 - smoothstep(0.985, 1.02, vT) : 1.0;

                    // ⚠ Not gated on this pixel's pastEnd: on the last bar a badge's top can sit
                    // past the end of the sequence, and the owner strip saturates there to the last
                    // note — which is exactly the note whose badge it is.
                    float4 own = tex2D(_CardTex, float2(uSelf, laneV));
                    float nStartC = own.r;
                    float d01N = (nStartC - tNear) / max(_Visible16, 1e-3);
                    bool haveC = own.a > 0.5 && d01N <= 1.0 && !(looping < 0.5 && nStartC >= safeLen);

                    // It goes as its note arrives — eased over a sixteenth or so either side of the
                    // line, so the hand-off from "coming" to "played" is a fade, not a blink.
                    float toLine = nStartC - tHitCmp;
                    if (looping > 0.5) toLine -= safeLen * round(toLine / safeLen);
                    float arriving = smoothstep(-0.7, 0.9, toLine);

                    if (haveC && arriving > 0.002)
                    {
                        float gapNext = own.g;

                        // The note on screen: its FRONT edge (the moment it crosses the line).
                        float vNote = rtInvDepth01(d01N, H);
                        float zsN = rtZScale(vNote, H);
                        float uNote = 0.5 + centerTrackX * halfW / max(zsN, 1e-4);

                        // Sized at the NOTE's depth (÷ trackTop: the same on screen however short
                        // the track band is), and never past the next note's front edge.
                        float bh0 = _NoteNumberSize * 0.030 / max(zsN, 1e-3) / trackTop;
                        float vGemTop = rtInvDepth01(min((nStartC + gemLen - tNear) / max(_Visible16, 1e-3), 1.0), H);
                        float gemV = max(vGemTop - vNote, 0.0);
                        float d01Next = (nStartC + gapNext - tNear) / max(_Visible16, 1e-3);
                        float vNext = d01Next < 0.999 ? rtInvDepth01(d01Next, H) : 1e3;
                        float room = vNext - vNote - 0.08 * bh0;

                        float bh = min(0.62 * bh0, room * 0.5);
                        // Centred on its gem, and never below the gem's front edge — below it is
                        // the previous note's stretch of lane.
                        float lift = max(gemV * 0.5, bh);

                        if (bh > 0.16 * bh0)
                        {
                            float3 rowC = rowColorFor(own.b);
                            int digitC = ((int)round(own.b)) % 4 + 1;
                            float badgeFog = lerp(1.0, fogAtten, 0.5) * cardKeep * arriving;

                            float bw = bh / max(aspectT, 1e-3);                 // square on screen
                            float2 badgeC = float2(uNote, vNote + lift);
                            float2 pB = float2((uv.x - badgeC.x) * aspectT, vT - badgeC.y);
                            float2 half2 = float2(bw * aspectT, bh);

                            float dPlate = rtRoundedBox(pB, half2, min(half2.x, half2.y) * 0.30);
                            float plate = rtFill(dPlate);
                            float ring = plate * (1.0 - rtFill(dPlate + min(half2.x, half2.y) * 0.16));

                            float2 pd = float2(pB.x / max(half2.x * 0.62, 1e-5),
                                               pB.y / max(half2.y * 0.62, 1e-5));
                            // sdgNumeral, not sdgDigit: a lone seven-segment 1 reads as ":".
                            float dNum = sdgNumeral(pd, digitC) * half2.y * 0.62;
                            float numMask = rtFill(dNum) * plate;

                            // Bright in the row's colour with the number dark on it: the note still
                            // reads as its colour first and its number second.
                            rtStyleComposite(acc, lerp(rowC, float3(1, 1, 1), 0.18) * energy * badgeFog,
                                             plate * badgeFog, 0.0);
                            rtStyleComposite(acc, lerp(rowC, float3(1, 1, 1), 0.65) * badgeFog, ring * badgeFog, 0.0);
                            rtStyleComposite(acc, rowC * 0.10, numMask * 0.95 * badgeFog, 0.0);
                        }
                    }
                }

                // ============================================================
                // 7b. Ghost hits — where you ACTUALLY played (RecordingPlan §5)
                // ============================================================
                // The same gem outline as the note it was aiming at, drawn at YOUR time rather
                // than the challenge's, with a tail linking the two. That gap is the error, drawn
                // to scale on the timeline you're already reading — no number to interpret and
                // nothing to remember between the hit and the verdict.
                //
                // DATA: R = your hit's start16th, G = the reference note's start16th (= R for an
                // extra), B = padRow + bank*4, A = signed offset in 16ths, or the ExtraSentinel
                // (>40) for a hit with no target. Empty regions carry _NoteTex's ±1e7 sentinel.
                //
                // Skipped in HEAT mode: with many runs folded together the per-hit ghosts are the
                // confetti the heatmap exists to replace.
                if (_HasGhost > 0.5 && reviewOn > 0.0 && _OnionMode < 2.5 && pastEnd < 0.5)
                {
                    float4 gd = tex2D(_GhostTex, float2(uSelf, laneV));
                    float gStart = gd.r;
                    float gRef = gd.g;
                    float gOffset = gd.a;

                    float isExtra = step(40.0, gOffset);
                    float3 ghostCol = lerp(rtOffsetColor(gOffset), _GhostExtraColor.rgb, isExtra);
                    // An extra you asked not to see costs one multiply rather than a branch.
                    float ghostGate = reviewOn * lerp(1.0, step(0.5, _ShowExtra), isExtra);

                    // Drift tail: a narrow column spanning slot → hit, so a lane full of tails
                    // leaning the same way IS the finding ("I am always ahead of the beat").
                    //
                    // Gated by MULTIPLY, not by a branch: `isExtra` comes from a texture and so
                    // varies per fragment, and rtFill/rtLine take screen derivatives — putting
                    // those inside divergent flow control is where SDF edges pick up seams.
                    float driftSpan = abs(gStart - gRef);
                    float driftGate = ghostGate * step(0.5, _ShowDrift) * (1.0 - isExtra)
                                    * step(0.03, driftSpan);
                    float tMid = (gStart + gRef) * 0.5;
                    float tailHalfX = hx * 0.13;
                    float2 pDrift = float2(xs, tCmp - (tMid + hy));
                    float dDrift = rtRoundedBox(pDrift, float2(tailHalfX, driftSpan * 0.5),
                                                min(tailHalfX, driftSpan * 0.5));
                    float driftMask = rtFill(dDrift) * trackMask;
                    rtOver(acc, ghostCol, driftMask * 0.55 * driftGate * fogAtten);
                    rtAdd(acc, ghostCol * driftMask * 0.20 * driftGate * fogAtten * _Radiance);

                    // The ghost itself: an OUTLINE, never a fill. A filled ghost competes with the
                    // gem it sits beside and you lose track of which one is the target.
                    float2 pGhost = float2(xs, tCmp - (gStart + hy));
                    float dGhost = rtRoundedBox(pGhost, float2(hx * 0.94, hy * 0.94), rr * 0.9);
                    float ringPx = max(0.012, 0.09 * min(hx, hy));
                    float ghostRing = rtLine(dGhost, ringPx) * trackMask;

                    rtOver(acc, lerp(ghostCol, float3(1, 1, 1), 0.25), ghostRing * 0.9 * ghostGate * fogAtten);
                    rtAdd(acc, ghostCol * rtGlow(abs(dGhost), 0.10 * gemLen)
                               * 0.35 * ghostGate * laneEdgeFade * trackMask * fogAtten * _Radiance);
                }

                // ============================================================
                // 8. Depth fog veil over the track surface
                // ============================================================
                rtOver(acc, _FogColor.rgb * 0.55, fogF * 0.45 * trackMask);

                // ============================================================
                // 9. Vignette (+ countdown dim already folded into `energy`)
                // ============================================================
                float vig = _Vignette * smoothstep(0.55, 1.15, length((uv - 0.5) * float2(1.55, 1.35)));
                acc.rgb *= 1.0 - vig * 0.8;

                // ============================================================
                // 9.5 Display surface — the cover sheet, lit by the scene rig
                // ============================================================
                if (_SurfaceMode > 0.5)
                {
                    float2 spx = float2(max(_QuadSize.x, 1.0), max(_QuadSize.y, 1.0));
                    float2 lightSpacePos = UI_DISPLAY_LIGHT_POS(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));
                    UI_DISPLAY_SURFACE_DESC(surf, _SurfaceMode, _BezelPx, _BezelRoundPx, spx)
                    UI_APPLY_DISPLAY_SURFACE(acc, uv, lightSpacePos, surf);

                    if (_BezelPx > 0.001)
                    {
                        float2 halfPx = spx * 0.5;
                        float r = min(_BezelRoundPx, min(halfPx.x, halfPx.y));
                        float2 pxPos = abs(uv * spx - halfPx) - (halfPx - _BezelPx - r);
                        float bd = length(max(pxPos, 0.0)) + min(max(pxPos.x, pxPos.y), 0.0) - r;
                        float frame = smoothstep(-1.0, 1.0, bd);
                        rtOver(acc, _BezelColor.rgb, frame * _BezelColor.a);

                        // The frame is raised moulding and takes the light too — same
                        // construction as SDFScope's bezel; see the comment there.
                        // Analytic outward normal, NOT ddx/ddy — ddy is a screen derivative
                        // (y down) while uv and the lamps are y up, so a derivative here would
                        // light the top edge as if it were the bottom. See uiDispApertureGrad.
                        float2 bnorm = uiDispApertureGrad(uv, spx, _BezelPx, _BezelRoundPx);
                        float3 keyToL = UIToLightVector(UILightDirection(_GlobalLightPos1, lightSpacePos));
                        float  facing = dot(bnorm, normalize(keyToL.xy + 1e-5));
                        float  edgeBand = saturate(1.0 - abs(bd) / max(_BezelPx, 1.0));
                        float3 keyRgb = (_GlobalLightFx1.x > 0.5) ? _GlobalLightColor1.rgb : float3(1, 1, 1);
                        rtAdd(acc, keyRgb * saturate(facing) * edgeBand * frame * 0.13);
                        acc.rgb *= 1.0 - saturate(-facing) * edgeBand * frame * 0.35;
                    }
                }

                // ── Receive shadows cast by neighbouring widgets ──────────────
                // Gated like SDFPanel's: the shared buffer has no per-panel stacking concept,
                // so a display sitting in FRONT of other panels must be able to opt out rather
                // than pick up shadows cast by widgets behind it.
                if (_ReceiveSceneShadows > 0.5 && acc.a > 0.001)
                    acc.rgb *= UIDisplayReceiveShadow(IN.screenPos.xy / max(IN.screenPos.w, 1e-5));

                // ============================================================
                // 10. Clip + final composite (premultiplied)
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
