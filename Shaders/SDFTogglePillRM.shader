// ============================================================================
// SDFTogglePillRM.shader — Pill / iOS-style slide toggle, Raymarch variant
// Identical to SDFTogglePill.shader but includes SDF3DExtrusion.cginc for
// 3D sphere raymarching of the handle body.
// _Handle* = the sliding ball   _Track* = the pill groove
// ============================================================================
Shader "UI/SDFTogglePillRM"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        // ====================================================================
        // Core state
        // ====================================================================
        _Value ("Value (0=off, 1=on)", Range(0,1)) = 0
        [IntRange] _StateCount ("State Count", Range(2,8)) = 2

        // ====================================================================
        // RM view parameters
        // ====================================================================
        _ViewTilt  ("View Tilt",  Range(0, 10)) = 0
        _ViewAngle ("View Angle", Range(-180, 180)) = 0
        _ViewFOV   ("View FOV",   Range(0, 1)) = 0
        _ViewShift ("View Shift", Range(-5, 5)) = 0

        // ====================================================================
        // Background (Bg)
        // ====================================================================
        _BgEnabled ("Bg Enabled", Float) = 1
        _BgColor ("Bg Color", Color) = (0.18, 0.18, 0.18, 1)
        _BgRenderAlpha ("Bg Render Alpha", Range(0,1)) = 1
        _BgRenderEmissive ("Bg Render Emissive", Range(0,1)) = 0
        _BgPadding ("Bg Padding", Range(0.0, 1.5)) = 0.05
        _BgRounding ("Bg Rounding", Range(0,1)) = 0.3
        _BgBevelEnabled ("Bg Bevel Enabled", Float) = 0
        _BgBevelDepth ("Bg Bevel Depth", Range(-1.0,1.0)) = 0.2
        _BgBevelSmoothness ("Bg Bevel Smoothness", Range(0.001,1.0)) = 0.02
        _BgBevelDistance ("Bg Bevel Distance", Range(0.001,1.0)) = 0.1
        _BgFaceSmoothness ("Bg Face Smoothness", Range(-1.0,1.0)) = 0.0
        _BgBevelProfileType ("Bg Bevel Profile Type", Int) = 0
        _BgBevelProfileSharpness ("Bg Bevel Profile Sharpness", Range(0,1)) = 0.5
        _BgBevelPatternEnabled ("Bg Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _BgBevelPatternType ("Bg Bevel Pattern Type", Int) = 0
        _BgBevelPatternScale ("Bg Bevel Pattern Scale", Range(1,100)) = 20
        _BgBevelPatternIntensity ("Bg Bevel Pattern Intensity", Range(0,1)) = 0.3
        _BgBevelPatternContrast ("Bg Bevel Pattern Contrast", Range(0.1,5)) = 1.5
        _BgBevelPatternSpecularEffect ("Bg Bevel Pattern Specular", Range(0,2)) = 1.0
        _BgBevelPatternRoughnessEffect ("Bg Bevel Pattern Roughness", Range(0,2)) = 0.3
        _BgBevelPatternParam1 ("Bg Bevel Pattern Param1", Range(0,1)) = 0.5
        _BgBevelPatternParam2 ("Bg Bevel Pattern Param2", Range(0,1)) = 0.5
        _BgBevelPatternParam3 ("Bg Bevel Pattern Param3", Range(0,1)) = 0.5
        _BgBevelPatternColorEnabled ("Bg Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _BgBevelPatternColorType ("Bg Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _BgBevelPatternColorMode ("Bg Bevel Pattern Color Mode", Int) = 1
        [IntRange] _BgBevelPatternColorUsed ("Bg Bevel Pattern Color Used", Range(2,4)) = 2
        _BgBevelPatternColorA ("Bg Bevel Pattern Color A", Color) = (1,1,1,1)
        _BgBevelPatternColorB ("Bg Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _BgBevelPatternColorC ("Bg Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _BgBevelPatternColorD ("Bg Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)
        _BgBevelGradientEnabled ("Bg Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BgBevelGradientType ("Bg Bevel Gradient Type", Int) = 1
        _BgBevelGradientColorA ("Bg Bevel Gradient Color A", Color) = (1,1,1,1)
        _BgBevelGradientColorB ("Bg Bevel Gradient Color B", Color) = (0.5,0.5,0.5,1)
        _BgBevelGradientColorC ("Bg Bevel Gradient Color C", Color) = (0.3,0.3,0.3,1)
        _BgBevelGradientColorD ("Bg Bevel Gradient Color D", Color) = (0.1,0.1,0.1,1)
        _BgBevelGradientDirection ("Bg Bevel Gradient Dir", Vector) = (1,0,0,0)
        _BgBevelGradientSpeed ("Bg Bevel Gradient Speed", Float) = 1.0
        _BgBevelGradientScale ("Bg Bevel Gradient Scale", Range(0.1,5)) = 1.0
        _BgBevelGradientOffset ("Bg Bevel Gradient Offset", Range(-2,2)) = 0.0
        [IntRange] _BgBevelGradientColorUsed ("Bg Bevel Gradient Color Used", Range(2,4)) = 4
        _BgRimEnabled ("Bg Rim Enabled", Float) = 0
        _BgRimDepth ("Bg Rim Depth", Range(-0.5,0.5)) = 0.1
        _BgRimWidth ("Bg Rim Width", Range(0.001,1.0)) = 0.02
        _BgRimSmoothness ("Bg Rim Smoothness", Range(0.001,0.1)) = 0.01
        _BgPatternEnabled ("Bg Pattern Enabled", Float) = 0
        [Enum(PatternType)] _BgPatternType ("Bg Pattern Type", Int) = 0
        _BgPatternScale ("Bg Pattern Scale", Range(1,100)) = 20
        _BgPatternIntensity ("Bg Pattern Intensity", Range(0,1)) = 0.3
        _BgPatternContrast ("Bg Pattern Contrast", Range(0.1,5)) = 1.5
        _BgPatternSpecularEffect ("Bg Pattern Specular Effect", Range(0,2)) = 1.0
        _BgPatternRoughnessEffect ("Bg Pattern Roughness Effect", Range(0,2)) = 0.3
        _BgPatternRotateEnabled ("Bg Pattern Rotate Enabled", Float) = 0
        _BgPatternModEnabled ("Bg Pattern Mod Enabled", Float) = 0
        _BgPatternModAmount ("Bg Pattern Mod Amount", Range(0,90)) = 20
        _BgPatternModFrequency ("Bg Pattern Mod Frequency", Range(0.1,10)) = 1
        _BgPatternOffset ("Bg Pattern Offset", Range(-180,180)) = 0
        _BgPatternParam1 ("Bg Pattern Param1", Range(0,1)) = 0.5
        _BgPatternParam2 ("Bg Pattern Param2", Range(0,1)) = 0.5
        _BgPatternParam3 ("Bg Pattern Param3", Range(0,1)) = 0.5
        _BgPatternColorEnabled ("Bg Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _BgPatternColorType ("Bg Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _BgPatternColorMode ("Bg Pattern Color Mode", Int) = 1
        [IntRange] _BgPatternColorUsed ("Bg Pattern Color Used", Range(2,4)) = 2
        _BgPatternColorA ("Bg Pattern Color A", Color) = (1,1,1,1)
        _BgPatternColorB ("Bg Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _BgPatternColorC ("Bg Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _BgPatternColorD ("Bg Pattern Color D", Color) = (0.1,0.1,0.1,1)
        _BgGradientEnabled ("Bg Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BgGradientType ("Bg Gradient Type", Int) = 0
        _BgGradientColorA ("Bg Gradient Color A", Color) = (0.3,0.3,0.3,1)
        _BgGradientColorB ("Bg Gradient Color B", Color) = (0.2,0.2,0.2,1)
        _BgGradientColorC ("Bg Gradient Color C", Color) = (0.15,0.15,0.15,1)
        _BgGradientColorD ("Bg Gradient Color D", Color) = (0.1,0.1,0.1,1)
        _BgGradientDirection ("Bg Gradient Direction", Vector) = (0,1,0,0)
        _BgGradientSpeed ("Bg Gradient Speed", Float) = 1.0
        _BgGradientScale ("Bg Gradient Scale", Range(0.1,5)) = 1.0
        _BgGradientOffset ("Bg Gradient Offset", Range(-2,2)) = 0.0
        _BgGlobalBlend ("Bg Global Blend", Range(0,1)) = 0.0
        _BgGlobalIntensity ("Bg Global Intensity", Range(0,2)) = 1.0
        [IntRange] _BgGradientColorUsed ("Bg Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // Track — pill-shaped groove (geometry + material)
        // (naming aligned with SDFSlider.shader)
        // ====================================================================
        // Track geometry
        _TrackHeight       ("Track Height", Range(0,1)) = 0.5
        _TrackCornerRadius ("Track Corner Radius", Range(0,1)) = 0.25
        _TrackInsetDepth   ("Track Inset Depth", Range(0,1)) = 0.5

        // Track material
        _TrackEnabled ("Track Enabled", Float) = 1
        _TrackColor ("Track Color", Color) = (0.1, 0.1, 0.1, 1)
        _TrackRenderAlpha ("Track Render Alpha", Range(0,1)) = 1
        _TrackRenderEmissive ("Track Render Emissive", Range(0,1)) = 0
        _TrackBevelEnabled ("Track Bevel Enabled", Float) = 0
        _TrackBevelDepth ("Track Bevel Depth", Range(-1.0,1.0)) = -0.15
        _TrackBevelSmoothness ("Track Bevel Smoothness", Range(0.001,1.0)) = 0.02
        _TrackBevelDistance ("Track Bevel Distance", Range(0.001,1.0)) = 0.15
        _TrackFaceSmoothness ("Track Face Smoothness", Range(-1.0,1.0)) = 0.0
        _TrackBevelProfileType ("Track Bevel Profile Type", Int) = 0
        _TrackBevelProfileSharpness ("Track Bevel Profile Sharpness", Range(0,1)) = 0.5
        _TrackPatternEnabled ("Track Pattern Enabled", Float) = 0
        [Enum(PatternType)] _TrackPatternType ("Track Pattern Type", Int) = 0
        _TrackPatternScale ("Track Pattern Scale", Range(1,100)) = 20
        _TrackPatternIntensity ("Track Pattern Intensity", Range(0,1)) = 0.3
        _TrackPatternContrast ("Track Pattern Contrast", Range(0.1,5)) = 1.5
        _TrackPatternSpecularEffect ("Track Pattern Specular", Range(0,2)) = 1.0
        _TrackPatternRoughnessEffect ("Track Pattern Roughness", Range(0,2)) = 0.3
        _TrackPatternParam1 ("Track Pattern Param1", Range(0,1)) = 0.5
        _TrackPatternParam2 ("Track Pattern Param2", Range(0,1)) = 0.5
        _TrackPatternParam3 ("Track Pattern Param3", Range(0,1)) = 0.5
        _TrackPatternColorEnabled ("Track Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _TrackPatternColorType ("Track Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _TrackPatternColorMode ("Track Pattern Color Mode", Int) = 1
        [IntRange] _TrackPatternColorUsed ("Track Pattern Color Used", Range(2,4)) = 2
        _TrackPatternColorA ("Track Pattern Color A", Color) = (1,1,1,1)
        _TrackPatternColorB ("Track Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _TrackPatternColorC ("Track Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _TrackPatternColorD ("Track Pattern Color D", Color) = (0.1,0.1,0.1,1)
        _TrackGradientEnabled ("Track Gradient Enabled", Float) = 0
        [Enum(GradientType)] _TrackGradientType ("Track Gradient Type", Int) = 0
        _TrackGradientColorA ("Track Gradient Color A", Color) = (0.12,0.12,0.12,1)
        _TrackGradientColorB ("Track Gradient Color B", Color) = (0.08,0.08,0.08,1)
        _TrackGradientColorC ("Track Gradient Color C", Color) = (0.06,0.06,0.06,1)
        _TrackGradientColorD ("Track Gradient Color D", Color) = (0.04,0.04,0.04,1)
        _TrackGradientDirection ("Track Gradient Direction", Vector) = (0,1,0,0)
        _TrackGradientSpeed ("Track Gradient Speed", Float) = 1.0
        _TrackGradientScale ("Track Gradient Scale", Range(0.1,5)) = 1.0
        _TrackGradientOffset ("Track Gradient Offset", Range(-2,2)) = 0.0
        _TrackGlobalBlend ("Track Global Blend", Range(0,1)) = 0.0
        _TrackGlobalIntensity ("Track Global Intensity", Range(0,2)) = 1.0
        [IntRange] _TrackGradientColorUsed ("Track Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // Handle — the sliding ball
        // (naming aligned with SDFSlider.shader; replaces generic _Toggle*)
        // ====================================================================
        // Handle geometry
        _HandlePadding ("Handle Padding (ball-to-track gap)", Range(0,1)) = 0.3
        _HandleFlatten ("Handle Flatten (0=sphere, 1=disc)", Range(0,1)) = 0.3

        // Handle material
        _HandleEnabled ("Handle Enabled", Float) = 1
        _HandleColor ("Handle Color", Color) = (0.7, 0.7, 0.7, 1)
        _HandleRenderAlpha ("Handle Render Alpha", Range(0,1)) = 1
        _HandleRenderEmissive ("Handle Render Emissive", Range(0,1)) = 0
        _HandleBevelEnabled ("Handle Bevel Enabled", Float) = 1
        _HandleBevelDepth ("Handle Bevel Depth", Range(-1.0,1.0)) = 0.25
        _HandleBevelSmoothness ("Handle Bevel Smoothness", Range(0.001,1.0)) = 0.02
        _HandleBevelDistance ("Handle Bevel Distance", Range(0.001,1.0)) = 0.12
        _HandleFaceSmoothness ("Handle Face Smoothness", Range(-1.0,1.0)) = 0.0
        _HandleBevelProfileType ("Handle Bevel Profile Type", Int) = 0
        _HandleBevelProfileSharpness ("Handle Bevel Profile Sharpness", Range(0,1)) = 0.5
        _HandleBevelPatternEnabled ("Handle Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _HandleBevelPatternType ("Handle Bevel Pattern Type", Int) = 0
        _HandleBevelPatternScale ("Handle Bevel Pattern Scale", Range(1,100)) = 20
        _HandleBevelPatternIntensity ("Handle Bevel Pattern Intensity", Range(0,1)) = 0.3
        _HandleBevelPatternContrast ("Handle Bevel Pattern Contrast", Range(0.1,5)) = 1.5
        _HandleBevelPatternSpecularEffect ("Handle Bevel Pattern Specular", Range(0,2)) = 1.0
        _HandleBevelPatternRoughnessEffect ("Handle Bevel Pattern Roughness", Range(0,2)) = 0.3
        _HandleBevelPatternParam1 ("Handle Bevel Pattern Param1", Range(0,1)) = 0.5
        _HandleBevelPatternParam2 ("Handle Bevel Pattern Param2", Range(0,1)) = 0.5
        _HandleBevelPatternParam3 ("Handle Bevel Pattern Param3", Range(0,1)) = 0.5
        _HandleBevelPatternColorEnabled ("Handle Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _HandleBevelPatternColorType ("Handle Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _HandleBevelPatternColorMode ("Handle Bevel Pattern Color Mode", Int) = 1
        [IntRange] _HandleBevelPatternColorUsed ("Handle Bevel Pattern Color Used", Range(2,4)) = 2
        _HandleBevelPatternColorA ("Handle Bevel Pattern Color A", Color) = (1,1,1,1)
        _HandleBevelPatternColorB ("Handle Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _HandleBevelPatternColorC ("Handle Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _HandleBevelPatternColorD ("Handle Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)
        _HandleBevelGradientEnabled ("Handle Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _HandleBevelGradientType ("Handle Bevel Gradient Type", Int) = 1
        _HandleBevelGradientColorA ("Handle Bevel Gradient Color A", Color) = (1,1,1,1)
        _HandleBevelGradientColorB ("Handle Bevel Gradient Color B", Color) = (0.5,0.5,0.5,1)
        _HandleBevelGradientColorC ("Handle Bevel Gradient Color C", Color) = (0.3,0.3,0.3,1)
        _HandleBevelGradientColorD ("Handle Bevel Gradient Color D", Color) = (0.1,0.1,0.1,1)
        _HandleBevelGradientDirection ("Handle Bevel Gradient Dir", Vector) = (1,0,0,0)
        _HandleBevelGradientSpeed ("Handle Bevel Gradient Speed", Float) = 1.0
        _HandleBevelGradientScale ("Handle Bevel Gradient Scale", Range(0.1,5)) = 1.0
        _HandleBevelGradientOffset ("Handle Bevel Gradient Offset", Range(-2,2)) = 0.0
        [IntRange] _HandleBevelGradientColorUsed ("Handle Bevel Gradient Color Used", Range(2,4)) = 4
        _HandleRimEnabled ("Handle Rim Enabled", Float) = 0
        _HandleRimDepth ("Handle Rim Depth", Range(-0.5,0.5)) = 0.1
        _HandleRimWidth ("Handle Rim Width", Range(0.001,1.0)) = 0.02
        _HandleRimSmoothness ("Handle Rim Smoothness", Range(0.001,0.1)) = 0.01
        _HandlePatternEnabled ("Handle Pattern Enabled", Float) = 0
        [Enum(PatternType)] _HandlePatternType ("Handle Pattern Type", Int) = 1
        _HandlePatternScale ("Handle Pattern Scale", Range(1,100)) = 20
        _HandlePatternIntensity ("Handle Pattern Intensity", Range(0,1)) = 0.3
        _HandlePatternContrast ("Handle Pattern Contrast", Range(0.1,5)) = 1.5
        _HandlePatternSpecularEffect ("Handle Pattern Specular", Range(0,2)) = 1.0
        _HandlePatternRoughnessEffect ("Handle Pattern Roughness", Range(0,2)) = 0.3
        _HandlePatternRotateEnabled ("Handle Pattern Rotate Enabled", Float) = 0
        _HandlePatternModEnabled ("Handle Pattern Mod Enabled", Float) = 0
        _HandlePatternModAmount ("Handle Pattern Mod Amount", Range(0,90)) = 20
        _HandlePatternModFrequency ("Handle Pattern Mod Frequency", Range(0.1,10)) = 1
        _HandlePatternOffset ("Handle Pattern Offset", Range(-180,180)) = 0
        _HandlePatternParam1 ("Handle Pattern Param1", Range(0,1)) = 0.5
        _HandlePatternParam2 ("Handle Pattern Param2", Range(0,1)) = 0.5
        _HandlePatternParam3 ("Handle Pattern Param3", Range(0,1)) = 0.5
        _HandlePatternColorEnabled ("Handle Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _HandlePatternColorType ("Handle Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _HandlePatternColorMode ("Handle Pattern Color Mode", Int) = 1
        [IntRange] _HandlePatternColorUsed ("Handle Pattern Color Used", Range(2,4)) = 2
        _HandlePatternColorA ("Handle Pattern Color A", Color) = (1,1,1,1)
        _HandlePatternColorB ("Handle Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _HandlePatternColorC ("Handle Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _HandlePatternColorD ("Handle Pattern Color D", Color) = (0.1,0.1,0.1,1)
        _HandleGradientEnabled ("Handle Gradient Enabled", Float) = 0
        [Enum(GradientType)] _HandleGradientType ("Handle Gradient Type", Int) = 1
        _HandleGradientColorA ("Handle Gradient Color A", Color) = (0.9,0.9,0.9,1)
        _HandleGradientColorB ("Handle Gradient Color B", Color) = (0.7,0.7,0.7,1)
        _HandleGradientColorC ("Handle Gradient Color C", Color) = (0.5,0.5,0.5,1)
        _HandleGradientColorD ("Handle Gradient Color D", Color) = (0.4,0.4,0.4,1)
        _HandleGradientDirection ("Handle Gradient Direction", Vector) = (0,1,0,0)
        _HandleGradientSpeed ("Handle Gradient Speed", Float) = 1.0
        _HandleGradientScale ("Handle Gradient Scale", Range(0.1,5)) = 1.0
        _HandleGradientOffset ("Handle Gradient Offset", Range(-2,2)) = 0.0
        _HandleGlobalBlend ("Handle Global Blend", Range(0,1)) = 0.0
        _HandleGlobalIntensity ("Handle Global Intensity", Range(0,2)) = 1.0
        [IntRange] _HandleGradientColorUsed ("Handle Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // Handle Face — reflective highlight disc on the ball surface
        // ====================================================================
        _HandleFaceEnabled ("Handle Face Enabled", Float) = 1
        _HandleFaceColor ("Handle Face Color", Color) = (0.6, 0.6, 0.6, 1)
        _HandleFaceRenderAlpha ("Handle Face Render Alpha", Range(0,1)) = 1
        _HandleFaceRenderEmissive ("Handle Face Render Emissive", Range(0,1)) = 0
        _HandleFaceSize ("Handle Face Size", Range(0.01,1.0)) = 0.75
        _HandleFaceGradientEnabled ("Handle Face Gradient Enabled", Float) = 0
        [Enum(GradientType)] _HandleFaceGradientType ("Handle Face Gradient Type", Int) = 1
        _HandleFaceGradientColorA ("Handle Face Gradient Color A", Color) = (0.8,0.8,0.8,1)
        _HandleFaceGradientColorB ("Handle Face Gradient Color B", Color) = (0.55,0.55,0.55,1)
        _HandleFaceGradientColorC ("Handle Face Gradient Color C", Color) = (0.45,0.45,0.45,1)
        _HandleFaceGradientColorD ("Handle Face Gradient Color D", Color) = (0.35,0.35,0.35,1)
        _HandleFaceGradientDirection ("Handle Face Gradient Direction", Vector) = (0,1,0,0)
        _HandleFaceGradientSpeed ("Handle Face Gradient Speed", Float) = 1.0
        _HandleFaceGradientScale ("Handle Face Gradient Scale", Range(0.1,5)) = 1.0
        _HandleFaceGradientOffset ("Handle Face Gradient Offset", Range(-2,2)) = 0.0
        [IntRange] _HandleFaceGradientColorUsed ("Handle Face Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // LED
        // ====================================================================
        _LedEnabled ("LED Enabled", Float) = 0
        _LedColor ("LED Color", Color) = (0.2, 1.0, 0.3, 1)
        _LedIntensity ("LED Intensity", Range(0,4)) = 1.5
        _LedGlowRadius ("LED Glow Radius", Range(0.01,1.0)) = 0.15
        _LedGlowSharpness ("LED Glow Sharpness", Range(0.5,20)) = 6.0
        _LedSurfaceBlend ("LED Surface Blend", Range(0,1)) = 0.0
        _LedRenderEmissive ("LED Render Emissive", Range(0,4)) = 1.5

        // ====================================================================
        // Edge indent
        // ====================================================================
        _EdgeEnabled ("Edge Enabled", Float) = 0
        _EdgeColor ("Edge Color", Color) = (0,0,0,0.5)
        _EdgeRenderAlpha ("Edge Render Alpha", Range(0,1)) = 1
        _EdgeRenderEmissive ("Edge Render Emissive", Range(0,1)) = 0
        _EdgeWidth ("Edge Width", Range(0.001,0.2)) = 0.03
        _EdgeSoftness ("Edge Softness", Range(0,1)) = 0.5
        _EdgeIntensity ("Edge Intensity", Range(0,2)) = 1.0
        _EdgeInset ("Edge Inset", Range(-0.1,0.1)) = 0.0
        _EdgeGradientEnabled ("Edge Gradient Enabled", Float) = 0
        [Enum(GradientType)] _EdgeGradientType ("Edge Gradient Type", Int) = 0
        _EdgeGradientColorA ("Edge Gradient Color A", Color) = (1,1,1,1)
        _EdgeGradientColorB ("Edge Gradient Color B", Color) = (0.5,0.5,0.5,1)
        _EdgeGradientColorC ("Edge Gradient Color C", Color) = (0.3,0.3,0.3,1)
        _EdgeGradientColorD ("Edge Gradient Color D", Color) = (0.1,0.1,0.1,1)
        _EdgeGradientDirection ("Edge Gradient Direction", Vector) = (1,0,0,0)
        _EdgeGradientSpeed ("Edge Gradient Speed", Float) = 1.0
        _EdgeGradientScale ("Edge Gradient Scale", Range(0.1,5)) = 1.0
        _EdgeGradientOffset ("Edge Gradient Offset", Range(-2,2)) = 0.0
        _EdgeGlobalBlend ("Edge Global Blend", Range(0,1)) = 0.0
        _EdgeGlobalIntensity ("Edge Global Intensity", Range(0,2)) = 1.0
        [IntRange] _EdgeGradientColorUsed ("Edge Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // Border
        // ====================================================================
        _BorderEnabled ("Border Enabled", Float) = 0
        _BorderColor ("Border Color", Color) = (0,0,0,0.3)
        _BorderRenderAlpha ("Border Render Alpha", Range(0,1)) = 1
        _BorderRenderEmissive ("Border Render Emissive", Range(0,1)) = 0
        _BorderWidth ("Border Width", Range(0.001,0.2)) = 0.05
        _BorderSoftness ("Border Softness", Range(0,0.2)) = 0.02
        _BorderIntensity ("Border Intensity", Range(0,2)) = 1.0
        _BorderGradientEnabled ("Border Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BorderGradientType ("Border Gradient Type", Int) = 0
        _BorderGradientColorA ("Border Gradient Color A", Color) = (1,1,1,1)
        _BorderGradientColorB ("Border Gradient Color B", Color) = (0.5,0.5,0.5,1)
        _BorderGradientColorC ("Border Gradient Color C", Color) = (0.3,0.3,0.3,1)
        _BorderGradientColorD ("Border Gradient Color D", Color) = (0.1,0.1,0.1,1)
        _BorderGradientDirection ("Border Gradient Direction", Vector) = (1,0,0,0)
        _BorderGradientSpeed ("Border Gradient Speed", Float) = 1.0
        _BorderGradientScale ("Border Gradient Scale", Range(0.1,5)) = 1.0
        _BorderGradientOffset ("Border Gradient Offset", Range(-2,2)) = 0.0
        _BorderGlobalBlend ("Border Global Blend", Range(0,1)) = 0.0
        _BorderGlobalIntensity ("Border Global Intensity", Range(0,2)) = 1.0
        [IntRange] _BorderGradientColorUsed ("Border Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // Receive shadows cast by other widgets/panels through the shared buffer.
        // AppShell clears this on overlay contents so a menu does not show the shadows of
        // whatever it is covering.
        _ReceiveSceneShadows ("Receive Scene Shadows", Float) = 1

        // Shadows
        // ====================================================================
        _LightingShadow1Enabled ("Shadow 1 Enabled", Float) = 0
        _LightingShadow1Color ("Shadow 1 Color", Color) = (0,0,0,0.5)
        _LightingShadow1Blur ("Shadow 1 Blur (softness at contact)", Range(0,1)) = 0.3
        _LightingShadow1Distance ("Shadow 1 Distance", Range(0,0.2)) = 0.02
        _LightingShadow1BlurFactor ("Shadow 1 Blur Factor (softens with distance)", Range(0,1)) = 0.5
        _LightingShadow1Intensity ("Shadow 1 Intensity", Range(0,2)) = 1.0
        _LightingShadow2Enabled ("Shadow 2 Enabled", Float) = 0
        _LightingShadow2Color ("Shadow 2 Color", Color) = (0,0,0,0.3)
        _LightingShadow2Blur ("Shadow 2 Blur (softness at contact)", Range(0,1)) = 0.3
        _LightingShadow2Distance ("Shadow 2 Distance", Range(0,0.2)) = 0.02
        _LightingShadow2BlurFactor ("Shadow 2 Blur Factor (softens with distance)", Range(0,1)) = 0.5
        _LightingShadow2Intensity ("Shadow 2 Intensity", Range(0,2)) = 1.0
        _LightingShadow3Enabled ("Shadow 3 Enabled", Float) = 0
        _LightingShadow3Color ("Shadow 3 Color", Color) = (0,0,0,0.3)
        _LightingShadow3Blur ("Shadow 3 Blur (softness at contact)", Range(0,1)) = 0.3
        _LightingShadow3Distance ("Shadow 3 Distance", Range(0,0.2)) = 0.02
        _LightingShadow3BlurFactor ("Shadow 3 Blur Factor (softens with distance)", Range(0,1)) = 0.5
        _LightingShadow3Intensity ("Shadow 3 Intensity", Range(0,2)) = 1.0
        _ToggleShadow1Enabled ("Handle Shadow 1 Enabled", Float) = 0
        _ToggleShadow1Color ("Handle Shadow 1 Color", Color) = (0,0,0,0.5)
        _ToggleShadow1Blur ("Handle Shadow 1 Blur (softness at contact)", Range(0,1)) = 0.2
        _ToggleShadow1Distance ("Handle Shadow 1 Distance", Range(0,0.2)) = 0.01
        _ToggleShadow1BlurFactor ("Handle Shadow 1 Blur Factor (softens with distance)", Range(0,1)) = 0.3
        _ToggleShadow1Intensity ("Handle Shadow 1 Intensity", Range(0,2)) = 1.0
        _ToggleShadow1Cast ("Handle Shadow 1 Cast", Range(0,2)) = 1.0
        _ToggleShadow2Enabled ("Handle Shadow 2 Enabled", Float) = 0
        _ToggleShadow2Color ("Handle Shadow 2 Color", Color) = (0,0,0,0.3)
        _ToggleShadow2Blur ("Handle Shadow 2 Blur (softness at contact)", Range(0,1)) = 0.2
        _ToggleShadow2Distance ("Handle Shadow 2 Distance", Range(0,0.2)) = 0.01
        _ToggleShadow2BlurFactor ("Handle Shadow 2 Blur Factor (softens with distance)", Range(0,1)) = 0.3
        _ToggleShadow2Intensity ("Handle Shadow 2 Intensity", Range(0,2)) = 1.0
        _ToggleShadow2Cast ("Handle Shadow 2 Cast", Range(0,2)) = 1.0
        _ToggleShadow3Enabled ("Handle Shadow 3 Enabled", Float) = 0
        _ToggleShadow3Color ("Handle Shadow 3 Color", Color) = (0,0,0,0.3)
        _ToggleShadow3Blur ("Handle Shadow 3 Blur (softness at contact)", Range(0,1)) = 0.2
        _ToggleShadow3Distance ("Handle Shadow 3 Distance", Range(0,0.2)) = 0.01
        _ToggleShadow3BlurFactor ("Handle Shadow 3 Blur Factor (softens with distance)", Range(0,1)) = 0.3
        _ToggleShadow3Intensity ("Handle Shadow 3 Intensity", Range(0,2)) = 1.0
        _ToggleShadow3Cast ("Handle Shadow 3 Cast", Range(0,2)) = 1.0

        // ====================================================================
        // Lighting
        // ====================================================================
        _LightingAmbient ("Lighting Ambient", Range(0,1)) = 0.3
        [ToggleUI] _LightingUnlit ("Unlit (skip lighting)", Float) = 0

        [HideInInspector] _StencilComp  ("Stencil Comparison",  Float) = 8
        [HideInInspector] _Stencil      ("Stencil ID",          Float) = 0
        [HideInInspector] _StencilOp    ("Stencil Operation",   Float) = 0
        [HideInInspector] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask  ("Stencil Read Mask",  Float) = 255
        [HideInInspector] _ColorMask    ("Color Mask",          Float) = 15
        [HideInInspector] _AspectRatio  ("Aspect Ratio Override",Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"
               "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

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
            Name "Raymarch"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON

            // Per-material unlit switch — see UI_LIGHTING_UNLIT in CG/Core/UILighting.cginc.
            float _LightingUnlit;
            #define UI_LIGHTING_UNLIT _LightingUnlit
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #include "CG/SDF/SDFPrimitives.cginc"
            #include "CG/SDF/SDFOperations.cginc"
            #include "CG/Core/Constants.cginc"
            #include "CG/Core/UIMath.cginc"
            #include "CG/Core/UIComponents.cginc"
            #include "CG/Core/UIPatterns.cginc"
            #include "CG/Core/UILighting.cginc"
            #include "CG/Core/UIRenderer.cginc"
            #include "CG/Core/UIGradients.cginc"
            #include "CG/SDF/SDF3DExtrusion.cginc"
            #include "CG/SDF/SDFToggleSharedUniforms.cginc"
            #include "CG/SDF/SDFTogglePillDefs.cginc"
            #include "CG/SDF/SDFPillShapes.cginc"

            // RM-specific uniforms (not in SDFToggleSharedUniforms.cginc)
            float _ViewTilt;
            float _ViewAngle;
            float _ViewFOV;
            float _ViewShift;

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
                // Shadow-buffer lookup. Panels are the surface knobs and buttons actually sit ON,
                // so without this a faceplate was the one thing in the UI that could never show a
                // shadow — every cast landed on it and vanished.
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

            #include "CG/SDF/SDFToggleLayers.cginc"
            #include "CG/SDF/SDFToggleRenderCore.cginc"

            ENDCG
        }
    }
    FallBack "UI/Default"
}
