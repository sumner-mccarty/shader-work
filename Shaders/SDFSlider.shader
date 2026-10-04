// ============================================================================
// SDFSlider.shader - 2D SDF UI Slider with Pure Function Architecture
// ============================================================================
// Slider renders a background panel, a track channel, value fill regions,
// a draggable handle thumb with full 3D material system, optional scale marks,
// edge indent, border, and shadow layers.
//
// COMPONENTS:
// 1. Background     — Overall slider background panel (full material pipeline)
// 2. Track          — Groove/slot channel running the slider length
//    2a. ValueFilled   — Filled track segment (fill origin → handle)
//    2b. ValueUnfilled — Unfilled track segment (handle → max)
// 3. Handle         — Draggable thumb (full 3D bevel+rim+lighting material)
// 4. HandleFace     — Optional inner face shape on the handle
// 5. ScaleMarks     — Optional tick marks along the slider axis
// 6. Edge           — Recessed indent around the slider quad
// 7. Border         — Cut-in border at canvas edge
// 8. Shadows        — 3 external cast shadows + 3 handle body shadows
// ============================================================================

Shader "UI/SDFSlider"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _Value ("Value", Range(0,1)) = 0
        _TrackValueZeroPoint ("Track Value Zero Point (0=start, 0.5=mid)", Range(0,1)) = 0

        // ====================================================================
        // Background
        // ====================================================================
        _BgEnabled ("Background Enabled", Float) = 1
        _BgColor ("Background Color", Color) = (0.15, 0.15, 0.15, 1)
        _BgRenderAlpha ("Background Render Alpha", Range(0,1)) = 1
        _BgRenderEmissive ("Background Render Emissive", Range(0,1)) = 0

        // Background shape
        [Enum(PanelBodyShapeType)] _BgShapeType ("Background Shape Type", Int) = 0
        _BgShapeParam1 ("Background Shape Param1", Range(0,1)) = 0.2
        _BgShapeParam2 ("Background Shape Param2", Range(0,1)) = 0.5
        _BgShapeParam3 ("Background Shape Param3", Range(0,1)) = 0.5
        _BgShapeRotation ("Background Shape Rotation", Range(-180,180)) = 0
        _BgPadding ("Background Padding", Range(0.0, 1.5)) = 0.1
        _PanelBodyRoundness ("Background Roundness", Range(0,1)) = 0
        _PanelBodyShapeTexLayer ("Background Shape Tex Layer", Float) = -1
        _PanelBodyShapeTexScale ("Background Shape Tex Scale", Vector) = (1, 1, 0, 0)

        // Background bevel
        _BgBevelEnabled ("Background Bevel Enabled", Float) = 0
        _BgBevelDepth ("Background Bevel Depth", Range(-1.0, 1.0)) = 0.2
        _BgBevelSmoothness ("Background Bevel Smoothness", Range(0.001, 1.0)) = 0.02
        _BgBevelDistance ("Background Bevel Distance", Range(0.001, 1.0)) = 0.1
        _BgFaceSmoothness ("Background Face Smoothness", Range(-1.0, 1.0)) = 0.0
        _BgBevelProfileType ("Background Bevel Profile Type", Int) = 0
        _BgBevelProfileSharpness ("Background Bevel Profile Sharpness", Range(0,1)) = 0.5

        // Background bevel pattern
        _BgBevelPatternEnabled ("Background Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _BgBevelPatternType ("Background Bevel Pattern Type", Int) = 0
        _BgBevelPatternScale ("Background Bevel Pattern Scale", Range(1,100)) = 20
        _BgBevelPatternIntensity ("Background Bevel Pattern Intensity", Range(0,1)) = 0.3
        _BgBevelPatternContrast ("Background Bevel Pattern Contrast", Range(0.1,5)) = 1.5
        _BgBevelPatternSpecularEffect ("Background Bevel Pattern Specular", Range(0,2)) = 1.0
        _BgBevelPatternRoughnessEffect ("Background Bevel Pattern Roughness", Range(0,2)) = 0.3
        _BgBevelPatternParam1 ("Background Bevel Pattern Detail", Range(0,1)) = 0.5
        _BgBevelPatternParam2 ("Background Bevel Pattern Distortion", Range(0,1)) = 0.5
        _BgBevelPatternParam3 ("Background Bevel Pattern Blend", Range(0,1)) = 0.5

        // Background bevel pattern color
        _BgBevelPatternColorEnabled ("Background Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _BgBevelPatternColorType ("Background Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _BgBevelPatternColorMode ("Background Bevel Pattern Color Mode", Int) = 1
        [IntRange] _BgBevelPatternColorUsed ("Background Bevel Pattern Color Used", Range(2,4)) = 2
        _BgBevelPatternColorA ("Background Bevel Pattern Color A", Color) = (1,1,1,1)
        _BgBevelPatternColorB ("Background Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _BgBevelPatternColorC ("Background Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _BgBevelPatternColorD ("Background Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Background bevel gradient
        _BgBevelGradientEnabled ("Background Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BgBevelGradientType ("Background Bevel Gradient Type", Int) = 1
        _BgBevelGradientColorA ("Background Bevel Gradient Color A", Color) = (1,1,1,1)
        _BgBevelGradientColorB ("Background Bevel Gradient Color B", Color) = (0.5,0.5,0.5,1)
        _BgBevelGradientColorC ("Background Bevel Gradient Color C", Color) = (0.3,0.3,0.3,1)
        _BgBevelGradientColorD ("Background Bevel Gradient Color D", Color) = (0.1,0.1,0.1,1)
        _BgBevelGradientDirection ("Background Bevel Gradient Dir", Vector) = (1,0,0,0)
        _BgBevelGradientSpeed ("Background Bevel Gradient Speed", Float) = 1.0
        _BgBevelGradientScale ("Background Bevel Gradient Scale", Range(0.1,5)) = 1.0
        _BgBevelGradientOffset ("Background Bevel Gradient Offset", Range(-2,2)) = 0.0
        [IntRange] _BgBevelGradientColorUsed ("Background Bevel Gradient Color Used", Range(2,4)) = 4

        // Background rim
        _BgRimEnabled ("Background Rim Enabled", Float) = 0
        _BgRimDepth ("Background Rim Depth", Range(-0.5, 0.5)) = 0.1
        _BgRimWidth ("Background Rim Width", Range(0.001, 1.0)) = 0.02
        _BgRimSmoothness ("Background Rim Smoothness", Range(0.001, 0.1)) = 0.01

        // Background pattern
        _BgPatternEnabled ("Background Pattern Enabled", Float) = 0
        [Enum(PatternType)] _BgPatternType ("Background Pattern Type", Int) = 0
        _BgPatternScale ("Background Pattern Scale", Range(1,100)) = 20
        _BgPatternIntensity ("Background Pattern Intensity", Range(0,1)) = 0.3
        _BgPatternContrast ("Background Pattern Contrast", Range(0.1,5)) = 1.5
        _BgPatternSpecularEffect ("Background Pattern Specular", Range(0,2)) = 1.0
        _BgPatternRoughnessEffect ("Background Pattern Roughness", Range(0,2)) = 0.3
        _BgPatternRotateEnabled ("Background Pattern Rotate", Float) = 0
        _BgPatternModEnabled ("Background Pattern Mod", Float) = 0
        _BgPatternModAmount ("Background Pattern Mod Amount", Range(0,90)) = 20
        _BgPatternModFrequency ("Background Pattern Mod Freq", Range(0.1,10)) = 1
        _BgPatternOffset ("Background Pattern Offset", Range(-180,180)) = 0
        _BgPatternParam1 ("Background Pattern Detail", Range(0,1)) = 0.5
        _BgPatternParam2 ("Background Pattern Distortion", Range(0,1)) = 0.5
        _BgPatternParam3 ("Background Pattern Blend", Range(0,1)) = 0.5

        // Background pattern color
        _BgPatternColorEnabled ("Background Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _BgPatternColorType ("Background Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _BgPatternColorMode ("Background Pattern Color Mode", Int) = 1
        [IntRange] _BgPatternColorUsed ("Background Pattern Color Used", Range(2,4)) = 2
        _BgPatternColorA ("Background Pattern Color A", Color) = (1,1,1,1)
        _BgPatternColorB ("Background Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _BgPatternColorC ("Background Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _BgPatternColorD ("Background Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Background gradient
        _BgGradientEnabled ("Background Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BgGradientType ("Background Gradient Type", Int) = 0
        _BgGradientColorA ("Background Gradient Color A", Color) = (0.2,0.2,0.2,1)
        _BgGradientColorB ("Background Gradient Color B", Color) = (0.1,0.1,0.1,1)
        _BgGradientColorC ("Background Gradient Color C", Color) = (0.15,0.15,0.15,1)
        _BgGradientColorD ("Background Gradient Color D", Color) = (0.05,0.05,0.05,1)
        _BgGradientDirection ("Background Gradient Direction", Vector) = (1,0,0,0)
        _BgGradientSpeed ("Background Gradient Speed", Float) = 1.0
        _BgGradientScale ("Background Gradient Scale", Range(0.1,5)) = 1.0
        _BgGradientOffset ("Background Gradient Offset", Range(-2,2)) = 0.0
        _BgGlobalBlend ("Background Global Blend", Range(0,1)) = 0.0
        _BgGlobalIntensity ("Background Global Intensity", Range(0,2)) = 1.0
        [IntRange] _BgGradientColorUsed ("Background Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // Track, ValueFilled, ValueUnfilled
        // ====================================================================
        _TrackEnabled ("Track Enabled", Float) = 1
        _TrackColor ("Track Color", Color) = (0.08, 0.08, 0.08, 1)
        _TrackRenderAlpha ("Track Render Alpha", Range(0,1)) = 1
        _TrackRenderEmissive ("Track Render Emissive", Range(0,1)) = 0

        // Value Filled (track segment: fill-origin → handle)
        _TrackValueFilledEnabled ("Value Filled Enabled", Float) = 1
        _TrackValueFilledColor ("Value Filled Color", Color) = (0.3, 0.7, 1.0, 1)
        _TrackValueFilledRenderAlpha ("Value Filled Render Alpha", Range(0,1)) = 1
        _TrackValueFilledRenderEmissive ("Value Filled Render Emissive", Range(0,1)) = 0

        // Value Unfilled (track segment: handle → end)
        _TrackValueUnfilledEnabled ("Value Unfilled Enabled", Float) = 0
        _TrackValueUnfilledColor ("Value Unfilled Color", Color) = (0.05, 0.05, 0.05, 1)
        _TrackValueUnfilledRenderAlpha ("Value Unfilled Render Alpha", Range(0,1)) = 1
        _TrackValueUnfilledRenderEmissive ("Value Unfilled Render Emissive", Range(0,1)) = 0

        _TrackWidth ("Track Width", Range(0.001, 1.0)) = 0.05
        _TrackCornerRadius ("Track Corner Radius", Range(0,1)) = 1.0
        _TrackExtension ("Track Extension Beyond Handle Travel", Range(0.0, 0.5)) = 0.0
        _TrackValuePadding ("Track Value Padding (fill inset inside track)", Range(0, 0.5)) = 0

        // Track bevel
        _TrackBevelEnabled ("Track Bevel Enabled", Float) = 0
        _TrackBevelDepth ("Track Bevel Depth", Range(-1.0, 1.0)) = -0.2
        _TrackBevelSmoothness ("Track Bevel Smoothness", Range(0.001,1.0)) = 0.02
        _TrackBevelDistance ("Track Bevel Distance", Range(0.001,1.0)) = 0.08
        _TrackFaceSmoothness ("Track Face Smoothness", Range(-1.0,1.0)) = 0.0

        // Track pattern
        _TrackPatternEnabled ("Track Pattern Enabled", Float) = 0
        [Enum(PatternType)] _TrackPatternType ("Track Pattern Type", Int) = 0
        _TrackPatternScale ("Track Pattern Scale", Range(1,100)) = 20
        _TrackPatternIntensity ("Track Pattern Intensity", Range(0,1)) = 0.3
        _TrackPatternContrast ("Track Pattern Contrast", Range(0.1,5)) = 1.5
        _TrackPatternParam1 ("Track Pattern Detail", Range(0,1)) = 0.5
        _TrackPatternParam2 ("Track Pattern Distortion", Range(0,1)) = 0.5
        _TrackPatternParam3 ("Track Pattern Blend", Range(0,1)) = 0.5

        // Track gradient
        _TrackGradientEnabled ("Track Gradient Enabled", Float) = 0
        [Enum(GradientType)] _TrackGradientType ("Track Gradient Type", Int) = 0
        _TrackGradientColorA ("Track Gradient Color A", Color) = (0.05,0.05,0.05,1)
        _TrackGradientColorB ("Track Gradient Color B", Color) = (0.12,0.12,0.12,1)
        _TrackGradientColorC ("Track Gradient Color C", Color) = (0.08,0.08,0.08,1)
        _TrackGradientColorD ("Track Gradient Color D", Color) = (0.03,0.03,0.03,1)
        _TrackGradientDirection ("Track Gradient Direction", Vector) = (0,1,0,0)
        _TrackGradientSpeed ("Track Gradient Speed", Float) = 1.0
        _TrackGradientScale ("Track Gradient Scale", Range(0.1,5)) = 1.0
        _TrackGradientOffset ("Track Gradient Offset", Range(-2,2)) = 0.0
        _TrackGlobalBlend ("Track Global Blend", Range(0,1)) = 0.0
        _TrackGlobalIntensity ("Track Global Intensity", Range(0,2)) = 1.0
        [IntRange] _TrackGradientColorUsed ("Track Gradient Color Used", Range(2,4)) = 2

        // ValueFilled pattern / gradient
        _TrackValueFilledPatternEnabled ("Value Filled Pattern Enabled", Float) = 0
        [Enum(PatternType)] _TrackValueFilledPatternType ("Value Filled Pattern Type", Int) = 0
        _TrackValueFilledPatternScale ("Value Filled Pattern Scale", Range(1,100)) = 20
        _TrackValueFilledPatternIntensity ("Value Filled Pattern Intensity", Range(0,1)) = 0.3
        _TrackValueFilledPatternContrast ("Value Filled Pattern Contrast", Range(0.1,5)) = 1.5
        _TrackValueFilledPatternParam1 ("Value Filled Pattern Detail", Range(0,1)) = 0.5
        _TrackValueFilledPatternParam2 ("Value Filled Pattern Distortion", Range(0,1)) = 0.5
        _TrackValueFilledPatternParam3 ("Value Filled Pattern Blend", Range(0,1)) = 0.5

        _TrackValueFilledGradientEnabled ("Value Filled Gradient Enabled", Float) = 0
        [Enum(GradientType)] _TrackValueFilledGradientType ("Value Filled Gradient Type", Int) = 0
        _TrackValueFilledGradientColorA ("Value Filled Gradient Color A", Color) = (0.2,0.6,1.0,1)
        _TrackValueFilledGradientColorB ("Value Filled Gradient Color B", Color) = (0.4,0.8,1.0,1)
        _TrackValueFilledGradientColorC ("Value Filled Gradient Color C", Color) = (0.3,0.7,1.0,1)
        _TrackValueFilledGradientColorD ("Value Filled Gradient Color D", Color) = (0.1,0.5,1.0,1)
        _TrackValueFilledGradientDirection ("Value Filled Gradient Direction", Vector) = (1,0,0,0)
        _TrackValueFilledGradientSpeed ("Value Filled Gradient Speed", Float) = 1.0
        _TrackValueFilledGradientScale ("Value Filled Gradient Scale", Range(0.1,5)) = 1.0
        _TrackValueFilledGradientOffset ("Value Filled Gradient Offset", Range(-2,2)) = 0.0
        _TrackValueFilledGlobalBlend ("Value Filled Global Blend", Range(0,1)) = 0.0
        _TrackValueFilledGlobalIntensity ("Value Filled Global Intensity", Range(0,2)) = 1.0
        [IntRange] _TrackValueFilledGradientColorUsed ("Value Filled Gradient Color Used", Range(2,4)) = 2

        // ValueUnfilled pattern / gradient
        _TrackValueUnfilledPatternEnabled ("Value Unfilled Pattern Enabled", Float) = 0
        [Enum(PatternType)] _TrackValueUnfilledPatternType ("Value Unfilled Pattern Type", Int) = 0
        _TrackValueUnfilledPatternScale ("Value Unfilled Pattern Scale", Range(1,100)) = 20
        _TrackValueUnfilledPatternIntensity ("Value Unfilled Pattern Intensity", Range(0,1)) = 0.3
        _TrackValueUnfilledPatternContrast ("Value Unfilled Pattern Contrast", Range(0.1,5)) = 1.5
        _TrackValueUnfilledPatternParam1 ("Value Unfilled Pattern Detail", Range(0,1)) = 0.5
        _TrackValueUnfilledPatternParam2 ("Value Unfilled Pattern Distortion", Range(0,1)) = 0.5
        _TrackValueUnfilledPatternParam3 ("Value Unfilled Pattern Blend", Range(0,1)) = 0.5

        _TrackValueUnfilledGradientEnabled ("Value Unfilled Gradient Enabled", Float) = 0
        [Enum(GradientType)] _TrackValueUnfilledGradientType ("Value Unfilled Gradient Type", Int) = 0
        _TrackValueUnfilledGradientColorA ("Value Unfilled Gradient Color A", Color) = (0.05,0.05,0.05,1)
        _TrackValueUnfilledGradientColorB ("Value Unfilled Gradient Color B", Color) = (0.1,0.1,0.1,1)
        _TrackValueUnfilledGradientColorC ("Value Unfilled Gradient Color C", Color) = (0.07,0.07,0.07,1)
        _TrackValueUnfilledGradientColorD ("Value Unfilled Gradient Color D", Color) = (0.03,0.03,0.03,1)
        _TrackValueUnfilledGradientDirection ("Value Unfilled Gradient Direction", Vector) = (1,0,0,0)
        _TrackValueUnfilledGradientSpeed ("Value Unfilled Gradient Speed", Float) = 1.0
        _TrackValueUnfilledGradientScale ("Value Unfilled Gradient Scale", Range(0.1,5)) = 1.0
        _TrackValueUnfilledGradientOffset ("Value Unfilled Gradient Offset", Range(-2,2)) = 0.0
        _TrackValueUnfilledGlobalBlend ("Value Unfilled Global Blend", Range(0,1)) = 0.0
        _TrackValueUnfilledGlobalIntensity ("Value Unfilled Global Intensity", Range(0,2)) = 1.0
        [IntRange] _TrackValueUnfilledGradientColorUsed ("Value Unfilled Gradient Color Used", Range(2,4)) = 2

        // Value NegFilled (track segment: handle → fill-origin, when value < zero point)
        _TrackValueNegativeEnabled ("Value Negative Enabled", Float) = 0
        _TrackValueNegativeColor ("Value Negative Color", Color) = (1.0, 0.3, 0.3, 1)
        _TrackValueNegativeRenderAlpha ("Value Negative Render Alpha", Range(0,1)) = 1
        _TrackValueNegativeRenderEmissive ("Value Negative Render Emissive", Range(0,1)) = 0

        // ValueNegative pattern / gradient
        _TrackValueNegativePatternEnabled ("Value Negative Pattern Enabled", Float) = 0
        [Enum(PatternType)] _TrackValueNegativePatternType ("Value Negative Pattern Type", Int) = 0
        _TrackValueNegativePatternScale ("Value Negative Pattern Scale", Range(1,100)) = 20
        _TrackValueNegativePatternIntensity ("Value Negative Pattern Intensity", Range(0,1)) = 0.3
        _TrackValueNegativePatternContrast ("Value Negative Pattern Contrast", Range(0.1,5)) = 1.5
        _TrackValueNegativePatternParam1 ("Value Negative Pattern Detail", Range(0,1)) = 0.5
        _TrackValueNegativePatternParam2 ("Value Negative Pattern Distortion", Range(0,1)) = 0.5
        _TrackValueNegativePatternParam3 ("Value Negative Pattern Blend", Range(0,1)) = 0.5

        _TrackValueNegativeGradientEnabled ("Value Negative Gradient Enabled", Float) = 0
        [Enum(GradientType)] _TrackValueNegativeGradientType ("Value Negative Gradient Type", Int) = 0
        _TrackValueNegativeGradientColorA ("Value Negative Gradient Color A", Color) = (1.0,0.2,0.2,1)
        _TrackValueNegativeGradientColorB ("Value Negative Gradient Color B", Color) = (0.8,0.1,0.1,1)
        _TrackValueNegativeGradientColorC ("Value Negative Gradient Color C", Color) = (0.9,0.15,0.15,1)
        _TrackValueNegativeGradientColorD ("Value Negative Gradient Color D", Color) = (0.6,0.1,0.1,1)
        _TrackValueNegativeGradientDirection ("Value Negative Gradient Direction", Vector) = (1,0,0,0)
        _TrackValueNegativeGradientSpeed ("Value Negative Gradient Speed", Float) = 1.0
        _TrackValueNegativeGradientScale ("Value Negative Gradient Scale", Range(0.1,5)) = 1.0
        _TrackValueNegativeGradientOffset ("Value Negative Gradient Offset", Range(-2,2)) = 0.0
        _TrackValueNegativeGlobalBlend ("Value Negative Global Blend", Range(0,1)) = 0.0
        _TrackValueNegativeGlobalIntensity ("Value Negative Global Intensity", Range(0,2)) = 1.0
        [IntRange] _TrackValueNegativeGradientColorUsed ("Value Negative Gradient Color Used", Range(2,4)) = 2

        // ====================================================================
        // Handle
        // ====================================================================
        _HandleEnabled ("Handle Enabled", Float) = 1
        _HandleColor ("Handle Color", Color) = (0.6, 0.6, 0.6, 1)
        _HandleRenderAlpha ("Handle Render Alpha", Range(0,1)) = 1
        _HandleRenderEmissive ("Handle Render Emissive", Range(0,1)) = 0

        // Handle shape
        [Enum(SliderHandleShapeType)] _HandleShapeType ("Handle Shape Type", Int) = 0
        _HandleWidth ("Handle Width", Range(0.01, 2.0)) = 0.15
        _HandleHeight ("Handle Height", Range(0.01, 2.0)) = 0.15
        _HandlePadding ("Handle Padding (extra margin from edge)", Range(0, 0.5)) = 0
        _HandleShapeParam1 ("Handle Shape Param1", Range(0,1)) = 0.5
        _HandleShapeParam2 ("Handle Shape Param2", Range(0,1)) = 0.5
        _HandleShapeParam3 ("Handle Shape Param3", Range(0,1)) = 0.5
        _HandleShapeRotation ("Handle Shape Rotation", Range(-180,180)) = 0
        _HandleRoundness ("Handle Roundness", Range(0,1)) = 0
        _HandleShapeTexLayer ("Handle Shape Tex Layer", Float) = -1
        _HandleShapeTexScale ("Handle Shape Tex Scale", Vector) = (1,1,0,0)

        // Handle bevel
        _HandleBevelEnabled ("Handle Bevel Enabled", Float) = 1
        _HandleBevelDepth ("Handle Bevel Depth", Range(-1.0, 1.0)) = 0.3
        _HandleBevelSmoothness ("Handle Bevel Smoothness", Range(0.001,1.0)) = 0.02
        _HandleBevelDistance ("Handle Bevel Distance", Range(0.001,1.0)) = 0.1
        _HandleFaceSmoothness ("Handle Face Smoothness", Range(-1.0,1.0)) = 0.0
        _HandleBevelProfileType ("Handle Bevel Profile Type", Int) = 0
        _HandleBevelProfileSharpness ("Handle Bevel Profile Sharpness", Range(0,1)) = 0.5

        // Handle bevel pattern
        _HandleBevelPatternEnabled ("Handle Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _HandleBevelPatternType ("Handle Bevel Pattern Type", Int) = 0
        _HandleBevelPatternScale ("Handle Bevel Pattern Scale", Range(1,100)) = 20
        _HandleBevelPatternIntensity ("Handle Bevel Pattern Intensity", Range(0,1)) = 0.3
        _HandleBevelPatternContrast ("Handle Bevel Pattern Contrast", Range(0.1,5)) = 1.5
        _HandleBevelPatternSpecularEffect ("Handle Bevel Pattern Specular", Range(0,2)) = 1.0
        _HandleBevelPatternRoughnessEffect ("Handle Bevel Pattern Roughness", Range(0,2)) = 0.3
        _HandleBevelPatternParam1 ("Handle Bevel Pattern Detail", Range(0,1)) = 0.5
        _HandleBevelPatternParam2 ("Handle Bevel Pattern Distortion", Range(0,1)) = 0.5
        _HandleBevelPatternParam3 ("Handle Bevel Pattern Blend", Range(0,1)) = 0.5

        // Handle bevel pattern color
        _HandleBevelPatternColorEnabled ("Handle Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _HandleBevelPatternColorType ("Handle Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _HandleBevelPatternColorMode ("Handle Bevel Pattern Color Mode", Int) = 1
        [IntRange] _HandleBevelPatternColorUsed ("Handle Bevel Pattern Color Used", Range(2,4)) = 2
        _HandleBevelPatternColorA ("Handle Bevel Pattern Color A", Color) = (1,1,1,1)
        _HandleBevelPatternColorB ("Handle Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _HandleBevelPatternColorC ("Handle Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _HandleBevelPatternColorD ("Handle Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Handle bevel gradient
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

        // Handle rim
        _HandleRimEnabled ("Handle Rim Enabled", Float) = 0
        _HandleRimDepth ("Handle Rim Depth", Range(-0.5, 0.5)) = 0.1
        _HandleRimWidth ("Handle Rim Width", Range(0.001, 1.0)) = 0.02
        _HandleRimSmoothness ("Handle Rim Smoothness", Range(0.001, 0.1)) = 0.01

        // Handle pattern
        _HandlePatternEnabled ("Handle Pattern Enabled", Float) = 0
        [Enum(PatternType)] _HandlePatternType ("Handle Pattern Type", Int) = 0
        _HandlePatternScale ("Handle Pattern Scale", Range(1,100)) = 20
        _HandlePatternIntensity ("Handle Pattern Intensity", Range(0,1)) = 0.3
        _HandlePatternContrast ("Handle Pattern Contrast", Range(0.1,5)) = 1.5
        _HandlePatternSpecularEffect ("Handle Pattern Specular", Range(0,2)) = 1.0
        _HandlePatternRoughnessEffect ("Handle Pattern Roughness", Range(0,2)) = 0.3
        _HandlePatternRotateEnabled ("Handle Pattern Rotate", Float) = 0
        _HandlePatternModEnabled ("Handle Pattern Mod", Float) = 0
        _HandlePatternModAmount ("Handle Pattern Mod Amount", Range(0,90)) = 20
        _HandlePatternModFrequency ("Handle Pattern Mod Freq", Range(0.1,10)) = 1
        _HandlePatternOffset ("Handle Pattern Offset", Range(-180,180)) = 0
        _HandlePatternParam1 ("Handle Pattern Detail", Range(0,1)) = 0.5
        _HandlePatternParam2 ("Handle Pattern Distortion", Range(0,1)) = 0.5
        _HandlePatternParam3 ("Handle Pattern Blend", Range(0,1)) = 0.5

        // Handle pattern color
        _HandlePatternColorEnabled ("Handle Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _HandlePatternColorType ("Handle Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _HandlePatternColorMode ("Handle Pattern Color Mode", Int) = 1
        [IntRange] _HandlePatternColorUsed ("Handle Pattern Color Used", Range(2,4)) = 2
        _HandlePatternColorA ("Handle Pattern Color A", Color) = (1,1,1,1)
        _HandlePatternColorB ("Handle Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _HandlePatternColorC ("Handle Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _HandlePatternColorD ("Handle Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Handle gradient
        _HandleGradientEnabled ("Handle Gradient Enabled", Float) = 0
        [Enum(GradientType)] _HandleGradientType ("Handle Gradient Type", Int) = 0
        _HandleGradientColorA ("Handle Gradient Color A", Color) = (0.8,0.8,0.8,1)
        _HandleGradientColorB ("Handle Gradient Color B", Color) = (0.5,0.5,0.5,1)
        _HandleGradientColorC ("Handle Gradient Color C", Color) = (0.65,0.65,0.65,1)
        _HandleGradientColorD ("Handle Gradient Color D", Color) = (0.4,0.4,0.4,1)
        _HandleGradientDirection ("Handle Gradient Direction", Vector) = (0,1,0,0)
        _HandleGradientSpeed ("Handle Gradient Speed", Float) = 1.0
        _HandleGradientScale ("Handle Gradient Scale", Range(0.1,5)) = 1.0
        _HandleGradientOffset ("Handle Gradient Offset", Range(-2,2)) = 0.0
        _HandleGlobalBlend ("Handle Global Blend", Range(0,1)) = 0.0
        _HandleGlobalIntensity ("Handle Global Intensity", Range(0,2)) = 1.0
        [IntRange] _HandleGradientColorUsed ("Handle Gradient Color Used", Range(2,4)) = 4

        // ====================================================================
        // HandleFace
        // ====================================================================
        _HandleFaceEnabled ("Handle Face Enabled", Float) = 0
        _HandleFaceShapeEnabled ("Handle Face Shape Enabled", Float) = 0
        [Enum(SliderHandleShapeType)] _HandleFaceShapeType ("Handle Face Shape Type", Int) = 0
        _HandleFaceShapeParam1 ("Handle Face Shape Param1", Range(0,1)) = 0.5
        _HandleFaceShapeParam2 ("Handle Face Shape Param2", Range(0,1)) = 0.5
        _HandleFaceShapeParam3 ("Handle Face Shape Param3", Range(0,1)) = 0.5
        _HandleFaceShapeRotation ("Handle Face Shape Rotation", Range(-180,180)) = 0
        _HandleFaceSize ("Handle Face Size", Range(0.01,1.0)) = 0.6

        _HandleFaceColor ("Handle Face Color", Color) = (0.3,0.3,0.3,1)
        _HandleFaceRenderAlpha ("Handle Face Render Alpha", Range(0,1)) = 1
        _HandleFaceRenderEmissive ("Handle Face Render Emissive", Range(0,1)) = 0

        _HandleFacePatternEnabled ("Handle Face Pattern Enabled", Float) = 0
        [Enum(PatternType)] _HandleFacePatternType ("Handle Face Pattern Type", Int) = 0
        _HandleFacePatternScale ("Handle Face Pattern Scale", Range(1,100)) = 20
        _HandleFacePatternIntensity ("Handle Face Pattern Intensity", Range(0,1)) = 0.3
        _HandleFacePatternContrast ("Handle Face Pattern Contrast", Range(0.1,5)) = 1.5
        _HandleFacePatternParam1 ("Handle Face Pattern Detail", Range(0,1)) = 0.5
        _HandleFacePatternParam2 ("Handle Face Pattern Distortion", Range(0,1)) = 0.5
        _HandleFacePatternParam3 ("Handle Face Pattern Blend", Range(0,1)) = 0.5

        _HandleFaceGradientEnabled ("Handle Face Gradient Enabled", Float) = 0
        [Enum(GradientType)] _HandleFaceGradientType ("Handle Face Gradient Type", Int) = 0
        _HandleFaceGradientColorA ("Handle Face Gradient Color A", Color) = (0.3,0.3,0.3,1)
        _HandleFaceGradientColorB ("Handle Face Gradient Color B", Color) = (0.2,0.2,0.2,1)
        _HandleFaceGradientColorC ("Handle Face Gradient Color C", Color) = (0.25,0.25,0.25,1)
        _HandleFaceGradientColorD ("Handle Face Gradient Color D", Color) = (0.15,0.15,0.15,1)
        _HandleFaceGradientDirection ("Handle Face Gradient Direction", Vector) = (0,1,0,0)
        _HandleFaceGradientScale ("Handle Face Gradient Scale", Range(0.1,5)) = 1.0
        _HandleFaceGradientOffset ("Handle Face Gradient Offset", Range(-2,2)) = 0.0
        _HandleFaceGlobalBlend ("Handle Face Global Blend", Range(0,1)) = 0.0
        _HandleFaceGlobalIntensity ("Handle Face Global Intensity", Range(0,2)) = 1.0
        [IntRange] _HandleFaceGradientColorUsed ("Handle Face Gradient Color Used", Range(2,4)) = 2

        // ====================================================================
        // ScaleMarks
        // ====================================================================
        _ScaleMarkEnabled ("Scale Mark Enabled", Float) = 0
        _ScaleMarkColor ("Scale Mark Color", Color) = (0.5,0.5,0.5,1)
        _ScaleMarkRenderAlpha ("Scale Mark Render Alpha", Range(0,1)) = 1
        _ScaleMarkRenderEmissive ("Scale Mark Render Emissive", Range(0,1)) = 0
        _ScaleMarkCount ("Scale Mark Count", Range(2, 32)) = 5
        _ScaleMarkWidth ("Scale Mark Width", Range(0.001, 0.1)) = 0.01
        _ScaleMarkLength ("Scale Mark Length", Range(0.01, 0.5)) = 0.05
        _ScaleMarkOffset ("Scale Mark Offset", Range(0, 0.5)) = 0.08
        _ScaleMarkSoftness ("Scale Mark Softness", Range(0, 0.05)) = 0.005

        _ScaleMarkGradientEnabled ("Scale Mark Gradient Enabled", Float) = 0
        [Enum(GradientType)] _ScaleMarkGradientType ("Scale Mark Gradient Type", Int) = 0
        _ScaleMarkGradientColorA ("Scale Mark Gradient Color A", Color) = (0.7,0.7,0.7,1)
        _ScaleMarkGradientColorB ("Scale Mark Gradient Color B", Color) = (0.3,0.3,0.3,1)
        _ScaleMarkGradientDirection ("Scale Mark Gradient Direction", Vector) = (1,0,0,0)
        _ScaleMarkGradientScale ("Scale Mark Gradient Scale", Range(0.1,5)) = 1.0
        _ScaleMarkGradientOffset ("Scale Mark Gradient Offset", Range(-2,2)) = 0.0

        // ====================================================================
        // Edge
        // ====================================================================
        _EdgeEnabled ("Edge Enabled", Float) = 0
        _EdgeColor ("Edge Color", Color) = (0,0,0,0.5)
        _EdgeRenderAlpha ("Edge Render Alpha", Range(0,1)) = 1
        _EdgeRenderEmissive ("Edge Render Emissive", Range(0,1)) = 0
        _EdgeWidth ("Edge Width", Range(0.001, 1.0)) = 0.1
        _EdgeSoftness ("Edge Softness", Range(0,1)) = 0.3
        _EdgeIntensity ("Edge Intensity", Range(0,2)) = 0.5
        _EdgeInset ("Edge Inset", Range(0.0, 0.5)) = 0.0

        _EdgeGradientEnabled ("Edge Gradient Enabled", Float) = 0
        [Enum(GradientType)] _EdgeGradientType ("Edge Gradient Type", Int) = 0
        _EdgeGradientColorA ("Edge Gradient Color A", Color) = (0,0,0,1)
        _EdgeGradientColorB ("Edge Gradient Color B", Color) = (0.1,0.1,0.1,1)
        _EdgeGradientColorC ("Edge Gradient Color C", Color) = (0,0,0,1)
        _EdgeGradientColorD ("Edge Gradient Color D", Color) = (0.05,0.05,0.05,1)
        _EdgeGradientDirection ("Edge Gradient Direction", Vector) = (0,1,0,0)
        _EdgeGradientSpeed ("Edge Gradient Speed", Float) = 1.0
        _EdgeGradientScale ("Edge Gradient Scale", Range(0.1,5)) = 1.0
        _EdgeGradientOffset ("Edge Gradient Offset", Range(-2,2)) = 0.0
        _EdgeGlobalBlend ("Edge Global Blend", Range(0,1)) = 0.0
        _EdgeGlobalIntensity ("Edge Global Intensity", Range(0,2)) = 1.0
        [IntRange] _EdgeGradientColorUsed ("Edge Gradient Color Used", Range(2,4)) = 2

        // ====================================================================
        // Border
        // ====================================================================
        _BorderEnabled ("Border Enabled", Float) = 0
        _BorderColor ("Border Color", Color) = (1,1,1,1)
        _BorderRenderAlpha ("Border Render Alpha", Range(0,1)) = 1
        _BorderRenderEmissive ("Border Render Emissive", Range(0,1)) = 0
        _BorderWidth ("Border Width", Range(0.001, 0.5)) = 0.02
        _BorderSoftness ("Border Softness", Range(0, 0.5)) = 0.01
        _BorderIntensity ("Border Intensity", Range(0,2)) = 1.0

        _BorderGradientEnabled ("Border Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BorderGradientType ("Border Gradient Type", Int) = 0
        _BorderGradientColorA ("Border Gradient Color A", Color) = (1,1,1,1)
        _BorderGradientColorB ("Border Gradient Color B", Color) = (0.8,0.8,0.8,1)
        _BorderGradientColorC ("Border Gradient Color C", Color) = (0.6,0.6,0.6,1)
        _BorderGradientColorD ("Border Gradient Color D", Color) = (0.4,0.4,0.4,1)
        _BorderGradientDirection ("Border Gradient Direction", Vector) = (0,1,0,0)
        _BorderGradientSpeed ("Border Gradient Speed", Float) = 1.0
        _BorderGradientScale ("Border Gradient Scale", Range(0.1,5)) = 1.0
        _BorderGradientOffset ("Border Gradient Offset", Range(-2,2)) = 0.0
        _BorderGlobalBlend ("Border Global Blend", Range(0,1)) = 0.0
        _BorderGlobalIntensity ("Border Global Intensity", Range(0,2)) = 1.0
        [IntRange] _BorderGradientColorUsed ("Border Gradient Color Used", Range(2,4)) = 2

        // ====================================================================

        // Receive shadows cast by other widgets/panels through the shared buffer.
        _ReceiveSceneShadows ("Receive Scene Shadows", Float) = 1

        // Shadows
        // ====================================================================
        // External shadows
        _LightingShadow1Enabled ("Shadow 1 Enabled", Float) = 0
        _LightingShadow1Color ("Shadow 1 Color", Color) = (0,0,0,0.5)
        _LightingShadow1Blur ("Shadow 1 Blur (softness at contact)", Range(0,2)) = 0.5
        _LightingShadow1Distance ("Shadow 1 Distance", Range(0,0.5)) = 0.02
        _LightingShadow1BlurFactor ("Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow1Intensity ("Shadow 1 Intensity", Range(0,2)) = 1.0

        _LightingShadow2Enabled ("Shadow 2 Enabled", Float) = 0
        _LightingShadow2Color ("Shadow 2 Color", Color) = (0,0,0,0.3)
        _LightingShadow2Blur ("Shadow 2 Blur (softness at contact)", Range(0,2)) = 0.8
        _LightingShadow2Distance ("Shadow 2 Distance", Range(0,0.5)) = 0.05
        _LightingShadow2BlurFactor ("Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow2Intensity ("Shadow 2 Intensity", Range(0,2)) = 1.0

        _LightingShadow3Enabled ("Shadow 3 Enabled", Float) = 0
        _LightingShadow3Color ("Shadow 3 Color", Color) = (0,0,0,0.2)
        _LightingShadow3Blur ("Shadow 3 Blur (softness at contact)", Range(0,2)) = 1.0
        _LightingShadow3Distance ("Shadow 3 Distance", Range(0,0.5)) = 0.08
        _LightingShadow3BlurFactor ("Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow3Intensity ("Shadow 3 Intensity", Range(0,2)) = 1.0

        // Handle body shadows
        _HandleShadow1Enabled ("Handle Shadow 1 Enabled", Float) = 0
        _HandleShadow1Color ("Handle Shadow 1 Color", Color) = (0,0,0,0.6)
        _HandleShadow1Blur ("Handle Shadow 1 Blur (softness at contact)", Range(0,2)) = 0.3
        _HandleShadow1Distance ("Handle Shadow 1 Distance", Range(0,0.5)) = 0.01
        _HandleShadow1BlurFactor ("Handle Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _HandleShadow1Intensity ("Handle Shadow 1 Intensity", Range(0,2)) = 1.0
        _HandleShadow1Cast ("Handle Shadow 1 Cast", Range(0,1)) = 0.5

        _HandleShadow2Enabled ("Handle Shadow 2 Enabled", Float) = 0
        _HandleShadow2Color ("Handle Shadow 2 Color", Color) = (0,0,0,0.4)
        _HandleShadow2Blur ("Handle Shadow 2 Blur (softness at contact)", Range(0,2)) = 0.5
        _HandleShadow2Distance ("Handle Shadow 2 Distance", Range(0,0.5)) = 0.02
        _HandleShadow2BlurFactor ("Handle Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _HandleShadow2Intensity ("Handle Shadow 2 Intensity", Range(0,2)) = 1.0
        _HandleShadow2Cast ("Handle Shadow 2 Cast", Range(0,1)) = 0.5

        _HandleShadow3Enabled ("Handle Shadow 3 Enabled", Float) = 0
        _HandleShadow3Color ("Handle Shadow 3 Color", Color) = (0,0,0,0.3)
        _HandleShadow3Blur ("Handle Shadow 3 Blur (softness at contact)", Range(0,2)) = 0.7
        _HandleShadow3Distance ("Handle Shadow 3 Distance", Range(0,0.5)) = 0.03
        _HandleShadow3BlurFactor ("Handle Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _HandleShadow3Intensity ("Handle Shadow 3 Intensity", Range(0,2)) = 1.0
        _HandleShadow3Cast ("Handle Shadow 3 Cast", Range(0,1)) = 0.5

        // ====================================================================
        // Lighting
        // ====================================================================
        _LightingAmbient ("Ambient", Range(0,1)) = 0.5
        [ToggleUI] _LightingUnlit ("Unlit (skip lighting)", Float) = 0




        _Position ("UI Position", Vector) = (0,0,0,0)
        _AspectRatio ("Aspect Ratio Override (0=auto)", Float) = 0

        // Shadow pass: 0 = widget quad (renders everything EXCEPT shadows — they'd clip at
        // this quad's edge); 1 = shadow quad (renders ONLY the shadows, on a backing quad
        // _ShadowUvExpand× the widget's size — see MaterialStateUiControls/WidgetShadowQuad.cs).
        // Same shader both ways, so the shadow math/appearance is IDENTICAL to the original.
        _ShadowPassMode ("Shadow Pass Mode (0=widget, 1=shadow quad)", Float) = 0
        _ShadowUvExpand ("Shadow Quad UV Expand", Float) = 1

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
            #include "CG/SDF/SDFSliderUniforms.cginc"

            float _ReceiveSceneShadows;
            float _ShadowPassMode;
            float _ShadowUvExpand;

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
                float4 screenPos     : TEXCOORD2; // for sampling the shared cross-widget shadow buffer
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.screenPos = ComputeScreenPos(OUT.vertex);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color;
                return OUT;
            }

            // Includes SDFButtonLayers (shared utilities) + SDFPanelShapes + SDFSliderHandleShapes
            // + slider-specific shadow/edge/border/handle-shadow functions
            #include "CG/SDF/SDFSliderLayers.cginc"

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv     = IN.texcoord;
                // Shadow quad: remap uv into the widget's own uv space (quad is
                // _ShadowUvExpand× the widget, centered) so all SDF math is unchanged and
                // shadows can extend past where the widget quad would end. Equal scaling on
                // both axes keeps the ddx/ddy aspect detection below correct.
                if (_ShadowPassMode > 0.5) uv = (uv - 0.5) * _ShadowUvExpand + 0.5;
                float2 center = float2(0.5, 0.5);

                // ============================================================
                // Aspect-correct equi-pixel coordinate space
                // ============================================================
                float rectAspect = (_AspectRatio > 0.001)
                    ? _AspectRatio
                    : abs(ddy(uv.y)) / max(0.0001, abs(ddx(uv.x)));
                float2 aspectScale = float2(max(rectAspect, 1.0), max(1.0 / rectAspect, 1.0));
                float2 pos    = (uv - center) * 2.0 * aspectScale;
                // Pattern UV: pos*0.5+center scales each axis by its pixel count so feature size
                // is constant in screen pixels; wider quads show more repetitions, not larger features.
                float2 uvIso  = pos * 0.5 + center;

                // ============================================================
                // Slider orientation: horizontal when width > height
                // ============================================================
                float sliderHoriz  = (rectAspect >= 1.0) ? 1.0 : 0.0;
                float sliderLength = sliderHoriz > 0.5 ? aspectScale.x : aspectScale.y;

                // ============================================================
                // Background half-extents and shape rotation
                // ============================================================
                float bgHalfW    = max(0.001, aspectScale.x - _BgPadding);
                float bgHalfH    = max(0.001, aspectScale.y - _BgPadding);
                int   bgShapeType = (int)_BgShapeType;
                float bgRotRad   = _BgShapeRotation * (PI / 180.0);
                float2 bgPos     = (abs(bgRotRad) > 0.001) ? rotate2D(pos, bgRotRad) : pos;

                // ============================================================
                // Handle position and local space
                // ============================================================
                // Handle centre clamped so the handle edge (half-width + padding) never exceeds the quad boundary
                float handleHalfTravel = max(0.0, sliderLength - _HandleWidth - _HandlePadding);
                float handleAxisPos = lerp(-handleHalfTravel, handleHalfTravel, _Value);
                float2 handleWorldPos = sliderHoriz > 0.5
                    ? float2(handleAxisPos, 0.0)
                    : float2(0.0, handleAxisPos);

                // Handle-local space: X = along main axis, Y = perpendicular
                // We always evaluate getHandleSDF in a canonical horizontal orientation
                float2 handleLocalP = pos - handleWorldPos;
                if (sliderHoriz < 0.5)
                    handleLocalP = float2(handleLocalP.y, -handleLocalP.x);

                float  handleRotRad = _HandleShapeRotation * (PI / 180.0);
                float2 handleRotP   = (abs(handleRotRad) > 0.001)
                    ? rotate2D(handleLocalP, handleRotRad)
                    : handleLocalP;

                int handleShapeType = (int)_HandleShapeType;

                // ============================================================
                // Track SDF
                // ============================================================
                // Track half-length = handle travel + optional small extension beyond the handle centres.
                // Changing _HandleWidth or _HandlePadding automatically adjusts track length and travel.
                float trackAxisHalf = handleHalfTravel + _TrackExtension;
                // In pos space the track rectangle is oriented along the slider axis
                float2 trackHalfExt = sliderHoriz > 0.5
                    ? float2(trackAxisHalf, _TrackWidth)
                    : float2(_TrackWidth, trackAxisHalf);
                float trackCornerR  = _TrackCornerRadius * min(trackHalfExt.x, trackHalfExt.y);
                float trackDist     = RoundedRectSDF(pos, trackHalfExt, trackCornerR);
                float trackAA       = fwidth(trackDist) * 0.75;
                float trackMask     = smoothstep(trackAA, -trackAA, trackDist);

                // ============================================================
                // Fill region masks (on the track)
                // ============================================================
                float fillOrigin  = lerp(-sliderLength, sliderLength, saturate(_TrackValueZeroPoint));
                float axisCoord   = sliderHoriz > 0.5 ? pos.x : pos.y;
                float fillMin     = min(fillOrigin, handleAxisPos);
                float fillMax     = max(fillOrigin, handleAxisPos);
                float aa1         = fwidth(axisCoord) * 0.75;
                // Inset track for value fills: _TrackValuePadding shrinks the fill region inside the track groove
                float trackValueWidth    = max(0.001, _TrackWidth - _TrackValuePadding);
                float2 trackValueHalfExt = sliderHoriz > 0.5
                    ? float2(trackAxisHalf, trackValueWidth)
                    : float2(trackValueWidth, trackAxisHalf);
                float trackValueCornerR  = _TrackCornerRadius * min(trackValueHalfExt.x, trackValueHalfExt.y);
                float trackValueDist     = (_TrackValuePadding > 0.0001)
                    ? RoundedRectSDF(pos, trackValueHalfExt, trackValueCornerR)
                    : trackDist;
                float trackValueAA       = fwidth(trackValueDist) * 0.75;
                float trackValueMask     = smoothstep(trackValueAA, -trackValueAA, trackValueDist);
                float filledMask  = trackValueMask
                    * smoothstep(fillMin - aa1, fillMin + aa1, axisCoord)
                    * (1.0 - smoothstep(fillMax - aa1, fillMax + aa1, axisCoord));
                float unfilledMask = trackValueMask * (1.0 - (
                    smoothstep(fillMin - aa1, fillMin + aa1, axisCoord)
                    * (1.0 - smoothstep(fillMax - aa1, fillMax + aa1, axisCoord))));

                // ============================================================
                // Lights
                // ============================================================
                // The three scene lights. No per-material lights exist any more — see UILighting.cginc.
                // Resolved ONCE here; every shadow call below reads these locals instead of re-expanding
                // the macro (which is what made this fragment program so expensive to compile).
                UILight light1 = UI_LIGHT_1;
                UILight light2 = UI_LIGHT_2;
                UILight light3 = UI_LIGHT_3;
                float3 lightDir1 = light1.direction;
                float3 lightDir2 = light2.direction;
                float3 lightDir3 = light3.direction;

                float4 finalColor   = float4(0, 0, 0, 0);
                float3 emissiveAccum = float3(0, 0, 0);
                float  time         = _Time.y;

                // ============================================================
                // Background bevel geometry
                // ============================================================
                float bgBevelDist   = (_BgBevelEnabled > 0.5) ? _BgBevelDistance : 0.0;
                float bgBevelDepthRaw = (_BgBevelEnabled > 0.5) ? abs(_BgBevelDepth) : 0.0;
                float bgMaxDim      = min(bgHalfW, bgHalfH);
                float bgPseudoHeight = bgMaxDim * lerp(0.05, 0.5, bgBevelDepthRaw);
                float bgRimWidth    = (_BgRimEnabled > 0.5) ? _BgRimWidth : 0.0;
                float bgFaceInset   = bgRimWidth + bgBevelDist;

                // ============================================================
                // Handle bevel geometry
                // ============================================================
                float handleBevelDist    = (_HandleBevelEnabled > 0.5) ? _HandleBevelDistance : 0.0;
                float handleBevelDepthRaw = (_HandleBevelEnabled > 0.5) ? abs(_HandleBevelDepth) : 0.0;
                float handleMaxDim      = min(_HandleWidth, _HandleHeight);
                float handlePseudoHeight = handleMaxDim * lerp(0.05, 0.5, handleBevelDepthRaw);
                float handleRimWidth    = (_HandleRimEnabled > 0.5) ? _HandleRimWidth : 0.0;
                float handleFaceInset   = handleRimWidth + handleBevelDist;

                // ============================================================
                // SHADOW QUAD ONLY: exact original shadow rendering (bg external + handle
                // body), unchanged — it just runs on the expanded backing quad
                // (_ShadowPassMode=1, driven by WidgetShadowQuad) instead of the widget's own
                // quad, so it can extend without being clipped. Everything above this point is
                // pure setup (no compositing), so returning here skips all visible sections.
                // ============================================================
                // ============================================================
                // THE CAST SHADOW — computed ONCE, consumed by BOTH passes.
                //
                // `castShadow` is a premultiplied layer holding everything this widget throws.
                // The backing quad (_ShadowPassMode=1) emits the half that falls OUTSIDE the
                // widget's own quad, into the buffer every other surface reads. The widget's
                // own program keeps the half that falls INSIDE it and applies it over its own
                // siblings further down. The two halves are exact complements (see
                // UIShadowQuadSplit), so the seam at the quad boundary cannot show, and the
                // widget can then safely READ the buffer for everyone else's shadows without
                // multiplying its own back over its own face.
                //
                // Computing it once rather than once per pass also halves how many times the
                // shape switch inside it is instantiated in this fragment program.
                // ============================================================
                float4 castShadow = float4(0, 0, 0, 0);
                {
                    if (_LightingShadow1Enabled > 0.5)
                    {
                        float sa = calculateSliderExternalShadow(uv, lightDir1,
                            _LightingShadow1Blur, _LightingShadow1Distance, _LightingShadow1BlurFactor,
                            bgHalfW, bgHalfH, bgShapeType,
                            _BgShapeParam1, _BgShapeParam2, _BgShapeParam3, aspectScale, bgRotRad);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow1Color.rgb,
                            _LightingShadow1Color.a * sa * _LightingShadow1Intensity);
                    }
                    if (_LightingShadow2Enabled > 0.5)
                    {
                        float sa = calculateSliderExternalShadow(uv, lightDir2,
                            _LightingShadow2Blur, _LightingShadow2Distance, _LightingShadow2BlurFactor,
                            bgHalfW, bgHalfH, bgShapeType,
                            _BgShapeParam1, _BgShapeParam2, _BgShapeParam3, aspectScale, bgRotRad);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow2Color.rgb,
                            _LightingShadow2Color.a * sa * _LightingShadow2Intensity);
                    }
                    if (_LightingShadow3Enabled > 0.5)
                    {
                        float sa = calculateSliderExternalShadow(uv, lightDir3,
                            _LightingShadow3Blur, _LightingShadow3Distance, _LightingShadow3BlurFactor,
                            bgHalfW, bgHalfH, bgShapeType,
                            _BgShapeParam1, _BgShapeParam2, _BgShapeParam3, aspectScale, bgRotRad);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow3Color.rgb,
                            _LightingShadow3Color.a * sa * _LightingShadow3Intensity);
                    }

                    if (_HandleShadow1Enabled > 0.5)
                    {
                        float sa = calculateHandleBodyShadow(uv, lightDir1,
                            _HandleShadow1Blur, _HandleShadow1Distance, _HandleShadow1BlurFactor, _HandleShadow1Cast,
                            handleWorldPos, _HandleWidth, _HandleHeight,
                            handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3,
                            handleFaceInset, handlePseudoHeight, aspectScale, handleRotRad, float2(0, 0));
                        if (sa > 0.001) buttonCompositeOver(castShadow, _HandleShadow1Color.rgb,
                            _HandleShadow1Color.a * sa * _HandleShadow1Intensity);
                    }
                    if (_HandleShadow2Enabled > 0.5)
                    {
                        float sa = calculateHandleBodyShadow(uv, lightDir2,
                            _HandleShadow2Blur, _HandleShadow2Distance, _HandleShadow2BlurFactor, _HandleShadow2Cast,
                            handleWorldPos, _HandleWidth, _HandleHeight,
                            handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3,
                            handleFaceInset, handlePseudoHeight, aspectScale, handleRotRad, float2(0, 0));
                        if (sa > 0.001) buttonCompositeOver(castShadow, _HandleShadow2Color.rgb,
                            _HandleShadow2Color.a * sa * _HandleShadow2Intensity);
                    }
                    if (_HandleShadow3Enabled > 0.5)
                    {
                        float sa = calculateHandleBodyShadow(uv, lightDir3,
                            _HandleShadow3Blur, _HandleShadow3Distance, _HandleShadow3BlurFactor, _HandleShadow3Cast,
                            handleWorldPos, _HandleWidth, _HandleHeight,
                            handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3,
                            handleFaceInset, handlePseudoHeight, aspectScale, handleRotRad, float2(0, 0));
                        if (sa > 0.001) buttonCompositeOver(castShadow, _HandleShadow3Color.rgb,
                            _HandleShadow3Color.a * sa * _HandleShadow3Intensity);
                    }
                }

                if (_ShadowPassMode > 0.5) {
                    // Backing quad: emit the OUTSIDE half, and nothing else.
                    finalColor = UIShadowSplitLayer(castShadow, UIShadowQuadSplit(uv));
                    #ifdef UNITY_UI_CLIP_RECT
                    float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                    finalColor *= clipMask;
                    #endif
                    finalColor *= IN.color;
                    return finalColor;
                }
                // Widget quad: keep the INSIDE half for the self-shadow block below.
                castShadow = UIShadowSplitLayer(castShadow, 1.0 - UIShadowQuadSplit(uv));

                // ============================================================
                // 1. Edge indent
                // ============================================================
                if (_EdgeEnabled > 0.5)
                {
                    float3 edgeBaseColor = _EdgeColor.rgb;
                    if (_EdgeGradientEnabled > 0.5)
                    {
                        float4 gc = CalculateGradient(uv, _EdgeGradientColorA, _EdgeGradientColorB,
                            _EdgeGradientColorC, _EdgeGradientColorD, _EdgeGradientDirection,
                            _EdgeGradientType, _EdgeGradientSpeed, _EdgeGradientScale,
                            _EdgeGradientOffset, time, _EdgeGradientColorUsed);
                        edgeBaseColor = lerp(edgeBaseColor, gc.rgb, gc.a);
                    }
                    if (_EdgeGlobalBlend > 0.0)
                    {
                        float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                        edgeBaseColor = lerp(edgeBaseColor, gc.rgb, _EdgeGlobalBlend * _EdgeGlobalIntensity);
                    }
                    float indentAlpha = calculateSliderEdgeIndent(uv, bgPos, _EdgeWidth, _EdgeSoftness,
                        bgHalfW, bgHalfH, bgShapeType,
                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3, _EdgeInset);
                    if (indentAlpha > 0.001)
                    {
                        float edgeMask = indentAlpha * _EdgeIntensity;
                        buttonCompositeOver(finalColor, edgeBaseColor, edgeMask * _EdgeRenderAlpha);
                        emissiveAccum += edgeBaseColor * edgeMask * _EdgeRenderEmissive;
                    }
                }

                // ============================================================
                // 2. External shadows — render in the shadow-pass block above
                // (_ShadowPassMode=1, expanded backing quad), not here.
                // ============================================================

                // ============================================================
                // 3. Background body + bevel + rim + lighting
                // ============================================================
                if (_BgEnabled > 0.5)
                {
                    float bgDist     = getPanelBodySDF(bgPos, bgHalfW, bgHalfH, bgShapeType,
                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                    float bgTopFaceDist = bgDist + bgFaceInset;

                    float bgAA   = fwidth(bgDist) * 0.75;
                    float bgMask = smoothstep(bgAA, -bgAA, bgDist);

                    if (bgMask > 0.001)
                    {
                        UIComponent bgComp = CreateUIComponent(
                            _BgColor, _BgRenderAlpha,
                            _BgBevelDepth, _BgBevelSmoothness, _BgBevelDistance, _BgFaceSmoothness,
                            _BgGradientColorA, _BgGradientColorB, _BgGradientColorC, _BgGradientColorD,
                            _BgGradientDirection, _BgGradientSpeed, _BgGradientScale, _BgGradientOffset,
                            _BgGlobalBlend, _BgGlobalIntensity, _BgGradientType,
                            _BgPatternType, _BgPatternScale, _BgPatternIntensity, _BgPatternContrast,
                            _BgPatternSpecularEffect, _BgPatternRoughnessEffect, _BgPatternRotateEnabled,
                            _BgPatternModEnabled, _BgPatternModAmount, _BgPatternModFrequency, _BgPatternOffset,
                            _BgPatternParam1, _BgPatternParam2, _BgPatternParam3,
                            _BgGradientEnabled, _BgPatternEnabled,
                            _BgPatternColorEnabled, _BgPatternColorMode,
                            _BgPatternColorType, _BgPatternColorUsed,
                            _BgPatternColorA, _BgPatternColorB, _BgPatternColorC, _BgPatternColorD
                        );

                        float3 bgBaseColor = bgComp.color.rgb;
                        if (bgComp.gradientEnabled > 0.5)
                        {
                            float4 gc = CalculateGradient(uv, bgComp.gradientColorA, bgComp.gradientColorB,
                                bgComp.gradientColorC, bgComp.gradientColorD, bgComp.gradientDirection,
                                bgComp.gradientType, bgComp.gradientSpeed, bgComp.gradientScale,
                                bgComp.gradientOffset, time, _BgGradientColorUsed);
                            bgBaseColor = lerp(bgBaseColor, gc.rgb, gc.a);
                        }
                        if (bgComp.globalBlend > 0.0)
                        {
                            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            bgBaseColor = lerp(bgBaseColor, gc.rgb, bgComp.globalBlend * bgComp.globalIntensity);
                        }

                        float bgSpecularMod;
                        float2 bgNormalOffset;
                        float3 bgPatternedColor = ApplyMaterialPattern(bgBaseColor, uvIso, bgComp, 0.0, 0.0, bgSpecularMod, bgNormalOffset);

                        float bgEffBevelDepth = (_BgBevelEnabled > 0.5) ? bgComp.bevelDepth : 0.0;
                        float bgEffBevelDist  = bgComp.bevelDistance;

                        if (abs(bgEffBevelDepth) > 0.0001)
                        {
                            float depthSign   = sign(bgEffBevelDepth);
                            float bevelHeightRM = bgMaxDim * lerp(0.05, 1.0, abs(bgEffBevelDepth));
                            float bevelDistRM   = max(0.0001, bgEffBevelDist);
                            float tanB          = bevelHeightRM / bevelDistRM;
                            bgEffBevelDepth = depthSign * tanB / (1.0 + tanB * 0.5);
                        }

                        float3 bgNormal = CalculateShapeBevelNormal(bgTopFaceDist, bgEffBevelDepth,
                            bgEffBevelDist, bgComp.bevelSmoothness, bgComp.fillFaceSmoothness,
                            _BgBevelProfileType, _BgBevelProfileSharpness, aspectScale);

                        ButtonBevelRenderResult bgBevelResult = RenderButtonBevelWithPatternAndGradient(
                            uv, uvIso, bgBaseColor, bgPatternedColor, bgNormal, bgTopFaceDist,
                            bgEffBevelDepth, bgEffBevelDist, bgComp.bevelSmoothness,
                            _BgBevelEnabled,
                            _BgBevelPatternEnabled, _BgBevelPatternType, _BgBevelPatternScale,
                            _BgBevelPatternIntensity, _BgBevelPatternContrast,
                            _BgBevelPatternSpecularEffect, _BgBevelPatternRoughnessEffect,
                            _BgBevelGradientEnabled, _BgBevelGradientType,
                            _BgBevelGradientColorA, _BgBevelGradientColorB,
                            _BgBevelGradientColorC, _BgBevelGradientColorD, _BgBevelGradientDirection,
                            _BgBevelGradientSpeed, _BgBevelGradientScale, _BgBevelGradientOffset,
                            _BgBevelPatternParam1, _BgBevelPatternParam2, _BgBevelPatternParam3,
                            _BgBevelGradientColorUsed,
                            _BgBevelPatternColorEnabled, _BgBevelPatternColorMode,
                            _BgBevelPatternColorType, _BgBevelPatternColorUsed,
                            _BgBevelPatternColorA, _BgBevelPatternColorB,
                            _BgBevelPatternColorC, _BgBevelPatternColorD,
                            time, light1, light2, light3
                        );

                        ButtonRimResult bgRimResult = CalculateButtonRimFromSDF(
                            uv, bgBevelResult.litColor, bgBevelResult.normal, bgDist,
                            _BgRimEnabled, _BgRimDepth, _BgRimWidth, _BgRimSmoothness,
                            light1, light2, light3, aspectScale
                        );

                        float3 bgLitColor = ApplyUILighting(bgRimResult.normal, bgRimResult.litColor,
                            _LightingAmbient, bgSpecularMod, bgNormalOffset, light1, light2, light3);

                        buttonCompositeOver(finalColor, bgLitColor, bgMask * bgComp.alpha);
                        emissiveAccum += bgBaseColor * bgMask * _BgRenderEmissive;
                    }
                }

                // ============================================================
                // 4. Track base (simple: no bevel profile, no pattern color)
                // ============================================================
                if (_TrackEnabled > 0.5 && trackMask > 0.001)
                {
                    float3 trackBaseColor = _TrackColor.rgb;

                    if (_TrackGradientEnabled > 0.5)
                    {
                        float4 gc = CalculateGradient(uv,
                            _TrackGradientColorA, _TrackGradientColorB,
                            _TrackGradientColorC, _TrackGradientColorD, _TrackGradientDirection,
                            _TrackGradientType, _TrackGradientSpeed, _TrackGradientScale,
                            _TrackGradientOffset, time, _TrackGradientColorUsed);
                        trackBaseColor = lerp(trackBaseColor, gc.rgb, gc.a);
                    }
                    if (_TrackGlobalBlend > 0.0)
                    {
                        float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                        trackBaseColor = lerp(trackBaseColor, gc.rgb, _TrackGlobalBlend * _TrackGlobalIntensity);
                    }

                    // Track pattern (simple: no specular/roughness/mod/rotate/color)
                    float3 trackPatternedColor = trackBaseColor;
                    if (_TrackPatternEnabled > 0.5)
                    {
                        UIComponent trackCompSimple = CreateUIComponent(
                            float4(trackBaseColor, 1), 1.0,
                            0, 0.02, 0.05, 0,
                            float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                            float2(1,0), 1.0, 1.0, 0.0,
                            0.0, 1.0, 0,
                            _TrackPatternType, _TrackPatternScale, _TrackPatternIntensity, _TrackPatternContrast,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 1.0, 0.0,
                            _TrackPatternParam1, _TrackPatternParam2, _TrackPatternParam3,
                            0.0, 1.0,
                            0.0, 0, 0, 0,
                            float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1)
                        );
                        float trackSpecMod;
                        float2 trackNormOff;
                        trackPatternedColor = ApplyMaterialPattern(trackBaseColor, uvIso, trackCompSimple, 0.0, 0.0, trackSpecMod, trackNormOff);
                    }

                    // Track bevel normal (inward = recessed groove when depth < 0)
                    float trackFaceDist = trackDist + max(0.0, _TrackBevelDistance);
                    float trackEffBevelDepth = (_TrackBevelEnabled > 0.5) ? _TrackBevelDepth : 0.0;
                    float3 trackNormal = CalculateShapeBevelNormal(trackFaceDist, trackEffBevelDepth,
                        _TrackBevelDistance, _TrackBevelSmoothness, _TrackFaceSmoothness,
                        0, 0.5, aspectScale);

                    float3 trackLitColor = ApplyUILighting(trackNormal, trackPatternedColor,
                        _LightingAmbient, 0.0, float2(0,0), light1, light2, light3);

                    buttonCompositeOver(finalColor, trackLitColor, trackMask * _TrackRenderAlpha);
                    emissiveAccum += trackBaseColor * trackMask * _TrackRenderEmissive;
                }

                // ============================================================
                // 5. ValueUnfilled (track segment: handle → max end)
                // ============================================================
                if (_TrackValueUnfilledEnabled > 0.5 && unfilledMask > 0.001)
                {
                    float3 vufColor = _TrackValueUnfilledColor.rgb;
                    if (_TrackValueUnfilledGradientEnabled > 0.5)
                    {
                        float4 gc = CalculateGradient(uv,
                            _TrackValueUnfilledGradientColorA, _TrackValueUnfilledGradientColorB,
                            _TrackValueUnfilledGradientColorC, _TrackValueUnfilledGradientColorD,
                            _TrackValueUnfilledGradientDirection, _TrackValueUnfilledGradientType,
                            _TrackValueUnfilledGradientSpeed, _TrackValueUnfilledGradientScale,
                            _TrackValueUnfilledGradientOffset, time, _TrackValueUnfilledGradientColorUsed);
                        vufColor = lerp(vufColor, gc.rgb, gc.a);
                    }
                    if (_TrackValueUnfilledGlobalBlend > 0.0)
                    {
                        float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                        vufColor = lerp(vufColor, gc.rgb, _TrackValueUnfilledGlobalBlend * _TrackValueUnfilledGlobalIntensity);
                    }
                    if (_TrackValueUnfilledPatternEnabled > 0.5)
                    {
                        UIComponent vufComp = CreateUIComponent(
                            float4(vufColor, 1), 1.0,
                            0, 0.02, 0.05, 0,
                            float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                            float2(1,0), 1.0, 1.0, 0.0,
                            0.0, 1.0, 0,
                            _TrackValueUnfilledPatternType, _TrackValueUnfilledPatternScale,
                            _TrackValueUnfilledPatternIntensity, _TrackValueUnfilledPatternContrast,
                            0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
                            _TrackValueUnfilledPatternParam1, _TrackValueUnfilledPatternParam2, _TrackValueUnfilledPatternParam3,
                            0.0, 1.0,
                            0.0, 0, 0, 0,
                            float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1)
                        );
                        float sm; float2 no;
                        vufColor = ApplyMaterialPattern(vufColor, uvIso, vufComp, 0.0, 0.0, sm, no);
                    }
                    buttonCompositeOver(finalColor, vufColor, unfilledMask * _TrackValueUnfilledRenderAlpha);
                    emissiveAccum += vufColor * unfilledMask * _TrackValueUnfilledRenderEmissive;
                }

                // ============================================================
                // 6. ValueFilled (handle >= zero point) / ValueNegFilled (handle < zero point)
                // ============================================================
                if (filledMask > 0.001)
                {
                    if (handleAxisPos >= fillOrigin && _TrackValueFilledEnabled > 0.5)
                    {
                        float3 vfColor = _TrackValueFilledColor.rgb;
                        if (_TrackValueFilledGradientEnabled > 0.5)
                        {
                            float4 gc = CalculateGradient(uv,
                                _TrackValueFilledGradientColorA, _TrackValueFilledGradientColorB,
                                _TrackValueFilledGradientColorC, _TrackValueFilledGradientColorD,
                                _TrackValueFilledGradientDirection, _TrackValueFilledGradientType,
                                _TrackValueFilledGradientSpeed, _TrackValueFilledGradientScale,
                                _TrackValueFilledGradientOffset, time, _TrackValueFilledGradientColorUsed);
                            vfColor = lerp(vfColor, gc.rgb, gc.a);
                        }
                        if (_TrackValueFilledGlobalBlend > 0.0)
                        {
                            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            vfColor = lerp(vfColor, gc.rgb, _TrackValueFilledGlobalBlend * _TrackValueFilledGlobalIntensity);
                        }
                        if (_TrackValueFilledPatternEnabled > 0.5)
                        {
                            UIComponent vfComp = CreateUIComponent(
                                float4(vfColor, 1), 1.0,
                                0, 0.02, 0.05, 0,
                                float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                                float2(1,0), 1.0, 1.0, 0.0,
                                0.0, 1.0, 0,
                                _TrackValueFilledPatternType, _TrackValueFilledPatternScale,
                                _TrackValueFilledPatternIntensity, _TrackValueFilledPatternContrast,
                                0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
                                _TrackValueFilledPatternParam1, _TrackValueFilledPatternParam2, _TrackValueFilledPatternParam3,
                                0.0, 1.0,
                                0.0, 0, 0, 0,
                                float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1)
                            );
                            float sm; float2 no;
                            vfColor = ApplyMaterialPattern(vfColor, uvIso, vfComp, 0.0, 0.0, sm, no);
                        }
                        buttonCompositeOver(finalColor, vfColor, filledMask * _TrackValueFilledRenderAlpha);
                        emissiveAccum += vfColor * filledMask * _TrackValueFilledRenderEmissive;
                    }
                    else if (handleAxisPos < fillOrigin && _TrackValueNegativeEnabled > 0.5)
                    {
                        float3 vnfColor = _TrackValueNegativeColor.rgb;
                        if (_TrackValueNegativeGradientEnabled > 0.5)
                        {
                            float4 gc = CalculateGradient(uv,
                                _TrackValueNegativeGradientColorA, _TrackValueNegativeGradientColorB,
                                _TrackValueNegativeGradientColorC, _TrackValueNegativeGradientColorD,
                                _TrackValueNegativeGradientDirection, _TrackValueNegativeGradientType,
                                _TrackValueNegativeGradientSpeed, _TrackValueNegativeGradientScale,
                                _TrackValueNegativeGradientOffset, time, _TrackValueNegativeGradientColorUsed);
                            vnfColor = lerp(vnfColor, gc.rgb, gc.a);
                        }
                        if (_TrackValueNegativeGlobalBlend > 0.0)
                        {
                            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            vnfColor = lerp(vnfColor, gc.rgb, _TrackValueNegativeGlobalBlend * _TrackValueNegativeGlobalIntensity);
                        }
                        if (_TrackValueNegativePatternEnabled > 0.5)
                        {
                            UIComponent vnfComp = CreateUIComponent(
                                float4(vnfColor, 1), 1.0,
                                0, 0.02, 0.05, 0,
                                float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                                float2(1,0), 1.0, 1.0, 0.0,
                                0.0, 1.0, 0,
                                _TrackValueNegativePatternType, _TrackValueNegativePatternScale,
                                _TrackValueNegativePatternIntensity, _TrackValueNegativePatternContrast,
                                0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
                                _TrackValueNegativePatternParam1, _TrackValueNegativePatternParam2, _TrackValueNegativePatternParam3,
                                0.0, 1.0,
                                0.0, 0, 0, 0,
                                float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1)
                            );
                            float sm; float2 no;
                            vnfColor = ApplyMaterialPattern(vnfColor, uvIso, vnfComp, 0.0, 0.0, sm, no);
                        }
                        buttonCompositeOver(finalColor, vnfColor, filledMask * _TrackValueNegativeRenderAlpha);
                        emissiveAccum += vnfColor * filledMask * _TrackValueNegativeRenderEmissive;
                    }
                }

                // ============================================================
                // 7. ScaleMarks (tick marks along the slider axis)
                // ============================================================
                if (_ScaleMarkEnabled > 0.5)
                {
                    // ScaleMark gradient color (shared per pass, not per mark)
                    float3 smBaseColor = _ScaleMarkColor.rgb;
                    if (_ScaleMarkGradientEnabled > 0.5)
                    {
                        float4 gc = CalculateGradient(uv,
                            _ScaleMarkGradientColorA, _ScaleMarkGradientColorB,
                            _ScaleMarkGradientColorA, _ScaleMarkGradientColorB,  // only 2 colours
                            _ScaleMarkGradientDirection, _ScaleMarkGradientType,
                            1.0, _ScaleMarkGradientScale, _ScaleMarkGradientOffset, time, 2);
                        smBaseColor = lerp(smBaseColor, gc.rgb, gc.a);
                    }

                    int smCount = max(2, (int)_ScaleMarkCount);
                    [loop]
                    for (int mi = 0; mi < smCount; mi++)
                    {
                        float t = (smCount > 1) ? (float)mi / (float)(smCount - 1) : 0.5;
                        float markAxisPos = lerp(-trackAxisHalf, trackAxisHalf, t);

                        // Mark centre in pos space: offset perpendicular to axis
                        float2 markCenter;
                        if (sliderHoriz > 0.5)
                            markCenter = float2(markAxisPos, _ScaleMarkOffset);
                        else
                            markCenter = float2(_ScaleMarkOffset, markAxisPos);

                        float2 markRelPos = pos - markCenter;
                        // Mark rectangle: width along axis, length perpendicular
                        float2 markHalfExt = sliderHoriz > 0.5
                            ? float2(_ScaleMarkWidth, _ScaleMarkLength)
                            : float2(_ScaleMarkLength, _ScaleMarkWidth);

                        float markDist = RoundedRectSDF(markRelPos, markHalfExt, 0.0);
                        float markAA   = max(_ScaleMarkSoftness, fwidth(markDist) * 0.75);
                        float markMask = smoothstep(markAA, -markAA, markDist);

                        if (markMask > 0.001)
                        {
                            buttonCompositeOver(finalColor, smBaseColor, markMask * _ScaleMarkRenderAlpha);
                            emissiveAccum += smBaseColor * markMask * _ScaleMarkRenderEmissive;
                        }
                    }
                }

                // ============================================================
                // 8. Handle body shadows — render in the shadow-pass block near the top of
                // frag (_ShadowPassMode=1, expanded backing quad), not here.
                // ============================================================

                // ============================================================
                // Self-shadow — the IN-QUAD half of this slider's own cast shadow.
                //
                // Placed here, after the plate/track/value segments and BEFORE the handle, so
                // the handle's shadow falls across the track it rides on. The shared buffer
                // holds only the OUTSIDE half (see the cast-shadow block at the top of frag),
                // precisely so this slider can read that buffer for its neighbours' shadows
                // without darkening its own face with its own.
                //
                // ⚠ One layer, one application point. A skin that enables the flat
                // _LightingShadowN casts (the PLATE's own drop shadow, meant for the panel
                // behind it) will see a little of it land on its own plate here. No shipped
                // slider skin does — they all use _HandleShadowN — and splitting the layer in
                // two to serve one unused case is not worth a second application point.
                // ============================================================
                if (castShadow.a > 0.002) {
                    UIApplySelfShadow(finalColor, castShadow.rgb / max(castShadow.a, 1e-4), castShadow.a);
                }

                // ============================================================
                // 9. Handle body + bevel + rim + lighting
                // ============================================================
                if (_HandleEnabled > 0.5)
                {
                    float handleDist     = getHandleSDF(handleRotP, _HandleWidth, _HandleHeight,
                        handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3);
                    float handleTopFaceDist = handleDist + handleFaceInset;

                    float handleAA   = fwidth(handleDist) * 0.75;
                    float handleMask = smoothstep(handleAA, -handleAA, handleDist);

                    if (handleMask > 0.001)
                    {
                        UIComponent handleComp = CreateUIComponent(
                            _HandleColor, _HandleRenderAlpha,
                            _HandleBevelDepth, _HandleBevelSmoothness, _HandleBevelDistance, _HandleFaceSmoothness,
                            _HandleGradientColorA, _HandleGradientColorB, _HandleGradientColorC, _HandleGradientColorD,
                            _HandleGradientDirection, _HandleGradientSpeed, _HandleGradientScale, _HandleGradientOffset,
                            _HandleGlobalBlend, _HandleGlobalIntensity, _HandleGradientType,
                            _HandlePatternType, _HandlePatternScale, _HandlePatternIntensity, _HandlePatternContrast,
                            _HandlePatternSpecularEffect, _HandlePatternRoughnessEffect, _HandlePatternRotateEnabled,
                            _HandlePatternModEnabled, _HandlePatternModAmount, _HandlePatternModFrequency, _HandlePatternOffset,
                            _HandlePatternParam1, _HandlePatternParam2, _HandlePatternParam3,
                            _HandleGradientEnabled, _HandlePatternEnabled,
                            _HandlePatternColorEnabled, _HandlePatternColorMode,
                            _HandlePatternColorType, _HandlePatternColorUsed,
                            _HandlePatternColorA, _HandlePatternColorB, _HandlePatternColorC, _HandlePatternColorD
                        );

                        float3 handleBaseColor = handleComp.color.rgb;
                        if (handleComp.gradientEnabled > 0.5)
                        {
                            // Sample gradient in handle-local UV space for clean orientation
                            float2 handleUV = handleLocalP / float2(_HandleWidth * 2.0, _HandleHeight * 2.0) + 0.5;
                            handleUV = saturate(handleUV);
                            float4 gc = CalculateGradient(handleUV, handleComp.gradientColorA, handleComp.gradientColorB,
                                handleComp.gradientColorC, handleComp.gradientColorD, handleComp.gradientDirection,
                                handleComp.gradientType, handleComp.gradientSpeed, handleComp.gradientScale,
                                handleComp.gradientOffset, time, _HandleGradientColorUsed);
                            handleBaseColor = lerp(handleBaseColor, gc.rgb, gc.a);
                        }
                        if (handleComp.globalBlend > 0.0)
                        {
                            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            handleBaseColor = lerp(handleBaseColor, gc.rgb, handleComp.globalBlend * handleComp.globalIntensity);
                        }

                        float handleSpecularMod;
                        float2 handleNormalOffset;
                        // Pattern UV: same world-space scale as global uvIso — consistent feature size across handle and track.
                        float2 handleUvIso = handleLocalP * 0.5 + 0.5;
                        handleUvIso = saturate(handleUvIso);
                        float3 handlePatternedColor = ApplyMaterialPattern(handleBaseColor, handleUvIso, handleComp, 0.0, 0.0, handleSpecularMod, handleNormalOffset);

                        float handleEffBevelDepth = (_HandleBevelEnabled > 0.5) ? handleComp.bevelDepth : 0.0;
                        float handleEffBevelDist  = handleComp.bevelDistance;

                        if (abs(handleEffBevelDepth) > 0.0001)
                        {
                            float depthSign     = sign(handleEffBevelDepth);
                            float bevelHeightRM = handleMaxDim * lerp(0.05, 1.0, abs(handleEffBevelDepth));
                            float bevelDistRM   = max(0.0001, handleEffBevelDist);
                            float tanB          = bevelHeightRM / bevelDistRM;
                            handleEffBevelDepth = depthSign * tanB / (1.0 + tanB * 0.5);
                        }

                        float3 handleNormal = CalculateShapeBevelNormal(handleTopFaceDist, handleEffBevelDepth,
                            handleEffBevelDist, handleComp.bevelSmoothness, handleComp.fillFaceSmoothness,
                            _HandleBevelProfileType, _HandleBevelProfileSharpness, aspectScale);

                        ButtonBevelRenderResult handleBevelResult = RenderButtonBevelWithPatternAndGradient(
                            uv, handleUvIso, handleBaseColor, handlePatternedColor, handleNormal, handleTopFaceDist,
                            handleEffBevelDepth, handleEffBevelDist, handleComp.bevelSmoothness,
                            _HandleBevelEnabled,
                            _HandleBevelPatternEnabled, _HandleBevelPatternType, _HandleBevelPatternScale,
                            _HandleBevelPatternIntensity, _HandleBevelPatternContrast,
                            _HandleBevelPatternSpecularEffect, _HandleBevelPatternRoughnessEffect,
                            _HandleBevelGradientEnabled, _HandleBevelGradientType,
                            _HandleBevelGradientColorA, _HandleBevelGradientColorB,
                            _HandleBevelGradientColorC, _HandleBevelGradientColorD, _HandleBevelGradientDirection,
                            _HandleBevelGradientSpeed, _HandleBevelGradientScale, _HandleBevelGradientOffset,
                            _HandleBevelPatternParam1, _HandleBevelPatternParam2, _HandleBevelPatternParam3,
                            _HandleBevelGradientColorUsed,
                            _HandleBevelPatternColorEnabled, _HandleBevelPatternColorMode,
                            _HandleBevelPatternColorType, _HandleBevelPatternColorUsed,
                            _HandleBevelPatternColorA, _HandleBevelPatternColorB,
                            _HandleBevelPatternColorC, _HandleBevelPatternColorD,
                            time, light1, light2, light3
                        );

                        ButtonRimResult handleRimResult = CalculateButtonRimFromSDF(
                            uv, handleBevelResult.litColor, handleBevelResult.normal, handleDist,
                            _HandleRimEnabled, _HandleRimDepth, _HandleRimWidth, _HandleRimSmoothness,
                            light1, light2, light3, aspectScale
                        );

                        float3 handleLitColor = ApplyUILighting(handleRimResult.normal, handleRimResult.litColor,
                            _LightingAmbient, handleSpecularMod, handleNormalOffset, light1, light2, light3);

                        buttonCompositeOver(finalColor, handleLitColor, handleMask * handleComp.alpha);
                        emissiveAccum += handleBaseColor * handleMask * _HandleRenderEmissive;
                    }
                }

                // ============================================================
                // 10. HandleFace (optional inner face shape on the handle)
                // ============================================================
                if (_HandleFaceEnabled > 0.5)
                {
                    // Face SDF: inset the handle by (1 - size) fraction of min half-extent
                    float faceMargin   = (1.0 - saturate(_HandleFaceSize)) * min(_HandleWidth, _HandleHeight);
                    float faceHalfW    = max(0.001, _HandleWidth  - faceMargin);
                    float faceHalfH    = max(0.001, _HandleHeight - faceMargin);

                    int faceShapeType = _HandleFaceShapeEnabled > 0.5
                        ? (int)_HandleFaceShapeType : handleShapeType;
                    float fp1 = _HandleFaceShapeEnabled > 0.5 ? _HandleFaceShapeParam1 : _HandleShapeParam1;
                    float fp2 = _HandleFaceShapeEnabled > 0.5 ? _HandleFaceShapeParam2 : _HandleShapeParam2;
                    float fp3 = _HandleFaceShapeEnabled > 0.5 ? _HandleFaceShapeParam3 : _HandleShapeParam3;

                    float2 faceRotP = handleRotP;
                    if (_HandleFaceShapeEnabled > 0.5 && abs(_HandleFaceShapeRotation) > 0.001)
                        faceRotP = rotate2D(handleLocalP, _HandleFaceShapeRotation * (PI / 180.0));

                    float faceDist = getHandleSDF(faceRotP, faceHalfW, faceHalfH,
                        faceShapeType, fp1, fp2, fp3);

                    float faceAA   = fwidth(faceDist) * 0.75;
                    float faceMask = smoothstep(faceAA, -faceAA, faceDist);

                    if (faceMask > 0.001)
                    {
                        float3 hfColor = _HandleFaceColor.rgb;

                        if (_HandleFaceGradientEnabled > 0.5)
                        {
                            float2 faceUV = handleLocalP / float2(faceHalfW * 2.0, faceHalfH * 2.0) + 0.5;
                            faceUV = saturate(faceUV);
                            float4 gc = CalculateGradient(faceUV,
                                _HandleFaceGradientColorA, _HandleFaceGradientColorB,
                                _HandleFaceGradientColorC, _HandleFaceGradientColorD,
                                _HandleFaceGradientDirection, _HandleFaceGradientType,
                                1.0, _HandleFaceGradientScale, _HandleFaceGradientOffset,
                                time, _HandleFaceGradientColorUsed);
                            hfColor = lerp(hfColor, gc.rgb, gc.a);
                        }
                        if (_HandleFaceGlobalBlend > 0.0)
                        {
                            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            hfColor = lerp(hfColor, gc.rgb, _HandleFaceGlobalBlend * _HandleFaceGlobalIntensity);
                        }

                        if (_HandleFacePatternEnabled > 0.5)
                        {
                            UIComponent hfComp = CreateUIComponent(
                                float4(hfColor, 1), 1.0,
                                0, 0.02, 0.05, 0,
                                float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                                float2(1,0), 1.0, 1.0, 0.0,
                                0.0, 1.0, 0,
                                _HandleFacePatternType, _HandleFacePatternScale,
                                _HandleFacePatternIntensity, _HandleFacePatternContrast,
                                0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
                                _HandleFacePatternParam1, _HandleFacePatternParam2, _HandleFacePatternParam3,
                                0.0, 1.0,
                                0.0, 0, 0, 0,
                                float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1)
                            );
                            float2 faceUvIso = handleLocalP * 0.5 + 0.5;
                            faceUvIso = saturate(faceUvIso);
                            float sm; float2 no;
                            hfColor = ApplyMaterialPattern(hfColor, faceUvIso, hfComp, 0.0, 0.0, sm, no);
                        }

                        buttonCompositeOver(finalColor, hfColor, faceMask * _HandleFaceRenderAlpha);
                        emissiveAccum += hfColor * faceMask * _HandleFaceRenderEmissive;
                    }
                }

                // ============================================================
                // 11. Border
                // ============================================================
                if (_BorderEnabled > 0.5)
                {
                    float3 borderColor = _BorderColor.rgb;
                    if (_BorderGradientEnabled > 0.5)
                    {
                        float4 gc = CalculateGradient(uv, _BorderGradientColorA, _BorderGradientColorB,
                            _BorderGradientColorC, _BorderGradientColorD, _BorderGradientDirection,
                            _BorderGradientType, _BorderGradientSpeed, _BorderGradientScale,
                            _BorderGradientOffset, time, _BorderGradientColorUsed);
                        borderColor = lerp(borderColor, gc.rgb, gc.a);
                    }
                    if (_BorderGlobalBlend > 0.0)
                    {
                        float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                        borderColor = lerp(borderColor, gc.rgb, _BorderGlobalBlend * _BorderGlobalIntensity);
                    }
                    float borderTerritory;
                    float4 borderResult = calculateSliderBorder(uv, borderColor, _BorderWidth, _BorderSoftness,
                        bgHalfW, bgHalfH, bgShapeType,
                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3,
                        aspectScale, borderTerritory);
                    float borderMask = borderResult.a * _BorderIntensity;

                    // Handle occludes border: do not render border over the handle
                    float borderHandleDist = getHandleSDF(handleRotP, _HandleWidth, _HandleHeight,
                        handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3);
                    float borderHandleAA   = fwidth(borderHandleDist) * 0.75;
                    float borderHandleOcclusion = (_HandleEnabled > 0.5)
                        ? (1.0 - smoothstep(borderHandleAA, -borderHandleAA, borderHandleDist))
                        : 1.0;

                    float borderPresence = max(_BorderRenderAlpha, _BorderRenderEmissive);
                    float effectiveTerr  = borderTerritory * borderPresence * borderHandleOcclusion;
                    if (effectiveTerr > 0.001)
                    {
                        float clearFactor = 1.0 - effectiveTerr;
                        finalColor.rgb  *= clearFactor;
                        finalColor.a    *= clearFactor;
                        emissiveAccum   *= clearFactor;
                    }
                    if (borderMask > 0.001)
                    {
                        float occludedBorderMask = borderMask * borderHandleOcclusion;
                        buttonCompositeOver(finalColor, borderResult.rgb, occludedBorderMask * _BorderRenderAlpha);
                        emissiveAccum += borderResult.rgb * occludedBorderMask * _BorderRenderEmissive;
                    }
                }

                // UI clipping
                #ifdef UNITY_UI_CLIP_RECT
                float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                finalColor    *= clipMask;
                emissiveAccum *= clipMask;
                #endif

                finalColor    *= IN.color;
                emissiveAccum *= IN.color.rgb;
                // Receive shadows cast by every OTHER widget and panel. This slider's own
                // contribution is not in the buffer at its own pixels — the shadow pass punched
                // its plate's silhouette out — so this is other people's shadows only.
                // BEFORE the emissive add: an emissive fill is its own light source.
                if (_ReceiveSceneShadows > 0.5 && finalColor.a > 0.001) {
                    finalColor.rgb *= sampleUIShadowBuffer(IN.screenPos.xy / IN.screenPos.w);
                }

                finalColor.rgb = finalColor.rgb + emissiveAccum;

                // Cross-widget shadow buffer: multiply in shadows cast by OTHER widgets. This
                // widget's own casting pass (_ShadowPassMode=1) already returned above, so this
                // point is only ever reached by the normal receiving quad.
                // NOT a receiver. This widget CASTS — WidgetShadowQuad renders its shadow into
                // _UIShadowBuffer in _ShadowPassMode=1. Sampling that buffer here multiplied the
                // widget's OWN cast shadow back over its own body, after all compositing, which is
                // why shadows appeared on top of knobs and buttons; it also double-darkened, since
                // the in-quad self-shadow pass above already covers these same pixels.
                // A caster's shadow onto its own siblings is that in-quad pass's job; onto
                // everything else it is the buffer's, and the surfaces that read the buffer are the
                // non-casters (SDFPanel, the toggles) — exactly the faceplate case.
                // TRADE-OFF: a knob is no longer darkened by a NEIGHBOURING knob's shadow. Undoing
                // that needs the caster's own silhouette punched out of the buffer in the shadow
                // pass, which costs a body-SDF evaluation in the one place that has repeatedly
                // blown the compile budget — deliberately not done.

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "UI/Default"
}
