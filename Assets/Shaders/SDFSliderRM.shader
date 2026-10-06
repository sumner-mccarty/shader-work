// ============================================================================
// SDFSliderRM.shader - 3D Raymarched Handle Slider (RM variant of SDFSlider)
// ============================================================================
// Identical to SDFSlider.shader except the handle body (section 9) is rendered
// via sphere-marching SDF extrusion (SDF3DExtrusion.cginc), giving a true 3D
// bevel/rim/lip with per-pixel lighting and self-shadowing.
//
// Differences from SDFSlider:
//   • Shader name: "UI/SDFSliderRM"
//   • Extra properties: _HandleLipHeight, _ViewTilt, _ViewAngle, _ViewFOV, _ViewShift
//   • Includes SDF3DExtrusion.cginc (3D extrusion helpers)
//   • Handle bevel geometry uses totalHeight = lipHeight + bevelHeight
//   • Section 9 replaced with raymarched extrusion of the handle shape
//   • Sections 1-8, 10-11 are unchanged from SDFSlider
// ============================================================================

Shader "UI/SDFSliderRM"
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
        _BgRimWidth ("Background Rim Width", Range(0.001, 1.0)) = 0.022
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

        // Track Value bevel (applies to filled, unfilled, negative — all relative to track face)
        _TrackValueBevelEnabled ("Track Value Bevel Enabled", Float) = 0
        _TrackValueBevelDepth ("Track Value Bevel Depth", Range(-1.0, 1.0)) = 0.1
        _TrackValueBevelSmoothness ("Track Value Bevel Smoothness", Range(0.001, 1.0)) = 0.02
        _TrackValueBevelDistance ("Track Value Bevel Distance", Range(0.001, 1.0)) = 0.08
        _TrackValueFaceSmoothness ("Track Value Face Smoothness", Range(-1.0, 1.0)) = 0.0

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
        _HandleBevelDepth ("Handle Bevel Depth", Range(-4.0, 4.0)) = 0.3
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
        // the track beside it whatever the lamps are doing, and without it the handle reads

        // Receive shadows cast by other widgets/panels through the shared buffer.
        // Same opt-out SDFPanel has — AppShell clears it on overlay contents so a menu
        // doesn't show the shadows of whatever it is covering.
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

        // ====================================================================
        // RM-specific (SDFSliderRM only)
        // ====================================================================
        _HandleLipHeight ("Handle Lip Height", Range(0,0.5)) = 0.05
        _ViewTilt ("View Tilt", Range(0,10)) = 2
        _ViewAngle ("View Angle", Range(-180,180)) = 0
        _ViewFOV ("View FOV (0=ortho)", Range(0,1)) = 0
        _ViewShift ("View Shift", Range(-5, 5)) = 0

        // Scene camera (§4.16 B) — a BOUNDED add-on to the authored view above. The app
        // publishes one eye point for the screen (_GlobalViewCam); these are the most it
        // may move THIS material. 0 = ignore the camera entirely.
        _ViewCamEnabled ("View Cam Enabled", Float) = 1
        _ViewCamShift ("View Cam Max Shift +/-", Range(0, 5)) = 0.6
        _ViewCamTilt ("View Cam Max Tilt +/-", Range(0, 10)) = 0.8
        _BgViewTiltEnabled ("Background View Tilt Enabled", Float) = 0
        _BgViewShiftEnabled ("Background View Shift Enabled", Float) = 0
        _TrackViewTiltEnabled ("Track View Tilt Enabled", Float) = 1
        _TrackViewShiftEnabled ("Track View Shift Enabled", Float) = 0
        _ViewValueShiftEnabled ("View Value Shift Enabled", Float) = 0
        _ViewValueShiftMin ("View Value Shift Min", Range(-5, 5)) = 0
        _ViewValueShiftMax ("View Value Shift Max", Range(-5, 5)) = 0
        _ViewValueTiltEnabled ("View Value Tilt Enabled", Float) = 0
        _ViewValueTiltMin ("View Value Tilt Min", Range(-10, 10)) = 0
        _ViewValueTiltMax ("View Value Tilt Max", Range(-10, 10)) = 0
        _ViewValueAspectEnabled ("View Value Aspect Enabled", Float) = 0
        _TrackViewElevation ("Track View Elevation", Float) = 0
        _HandleViewElevation ("Handle View Elevation", Float) = 0

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
            #pragma target 3.5
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
            #include "CG/Core/UIViewCamera.cginc"
            #include "CG/Core/UIRenderer.cginc"
            #include "CG/Core/UIGradients.cginc"
            #include "CG/SDF/SDFSliderUniforms.cginc"

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
            // 3D extrusion SDF helpers: sdfExtrusion3D, normalToScreenSpace, ExtrusionParams, SURFACE_*
            #include "CG/SDF/SDF3DExtrusion.cginc"

            // RM-specific uniforms (not in SDFSliderUniforms.cginc)
            float _ViewTilt;
            float _ViewAngle;
            float _ViewFOV;
            float _ViewShift;
            float _ViewCamEnabled;
            float _ViewCamShift;
            float _ViewCamTilt;
            float _ReceiveSceneShadows;
            float _ShadowPassMode;
            float _ShadowUvExpand;
            float _BgViewTiltEnabled;
            float _BgViewShiftEnabled;
            float _TrackViewTiltEnabled;
            float _TrackViewShiftEnabled;
            float _ViewValueShiftEnabled;
            float _ViewValueShiftMin;
            float _ViewValueShiftMax;
            float _ViewValueTiltEnabled;
            float _ViewValueTiltMin;
            float _ViewValueTiltMax;
            float _ViewValueAspectEnabled;
            float _TrackViewElevation;
            float _HandleViewElevation;
            float _HandleLipHeight;
            float _TrackValueBevelEnabled;
            float _TrackValueBevelDepth;
            float _TrackValueBevelSmoothness;
            float _TrackValueBevelDistance;
            float _TrackValueFaceSmoothness;

            // Evaluates the handle shape SDF in handle-local XZ space,
            // applying _HandleShapeRotation internally.
            float evalHandleSDF(float2 p)
            {
                float2 pRot = (abs(_HandleShapeRotation) > 0.001)
                    ? rotate2D(p, _HandleShapeRotation * (PI / 180.0)) : p;
                return getHandleSDF(pRot, _HandleWidth, _HandleHeight,
                    (int)_HandleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3);
            }

            // Returns the face SDF for the RM extrusion.
            // If _HandleFaceShapeEnabled, uses the face shape shrunken by faceInset.
            // Otherwise falls back to baseSDF + faceInset (same as knob RM).
            float computeHandleFaceSDF(float2 p, float baseSDF, float faceInset, float bevelDist)
            {
                if (_HandleFaceShapeEnabled > 0.5)
                {
                    float faceMargin = (1.0 - saturate(_HandleFaceSize)) * min(_HandleWidth, _HandleHeight);
                    float faceHalfW  = max(0.001, _HandleWidth  - faceMargin);
                    float faceHalfH  = max(0.001, _HandleHeight - faceMargin);
                    float2 pRot = (abs(_HandleFaceShapeRotation) > 0.001)
                        ? rotate2D(p, _HandleFaceShapeRotation * (PI / 180.0)) : p;
                    return getHandleSDF(pRot, faceHalfW, faceHalfH,
                        (int)_HandleFaceShapeType,
                        _HandleFaceShapeParam1, _HandleFaceShapeParam2, _HandleFaceShapeParam3)
                        + bevelDist;
                }
                return baseSDF + faceInset;
            }

            // Inverse-project screen-space 2D coordinates back to the untilted shape space.
            // This gives actual geometry foreshortening (not just normal/light rotation).
            float2 ApplyViewTiltToPos(float2 p, float2 tiltDir, float2 tiltNormDir, float cosT)
            {
                float across = dot(p, tiltNormDir);
                float along  = dot(p, tiltDir) / max(0.001, cosT);
                return across * tiltNormDir + along * tiltDir;
            }

            // Rounded-rect variant of handle body shadow, used by RM track casting.
            float calculateTrackBodyShadowRM(float2 uv, float3 lightDir,
                float blur, float dist, float blurFactor, float castMul,
                float2 halfExt, float cornerR, float faceInset, float pseudoHeight,
                float2 aspectScale, float2 posOffset)
            {
                float2 ld2  = normalize(lightDir.xy);
                float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist + posOffset;
                float sD    = RoundedRectSDF(sPos, halfExt, cornerR);

                if (castMul > 0.001 && pseudoHeight > 0.001)
                {
                    float  ps      = pseudoHeight * castMul;
                    float2 topOff  = -ld2 * ps;
                    float2 faceExt = max(float2(0.001, 0.001), halfExt - faceInset);
                    float  faceR   = max(0.0, cornerR - faceInset);

                    float  segLen2 = dot(topOff, topOff);
                    float  t       = saturate(-dot(sPos, topOff) / max(0.0001, segLen2));
                    float2 sPosH   = sPos + topOff * t;
                    float2 hullExt = lerp(halfExt, faceExt, t);
                    float  hullR   = lerp(cornerR, faceR, t);
                    float  sDH     = RoundedRectSDF(sPosH, hullExt, hullR);

                    float2 sPosT = sPos + topOff;
                    float  sDT   = RoundedRectSDF(sPosT, faceExt, faceR);
                    sD = min(sD, min(sDH, sDT));
                }

                float lightProj = dot(sPos, ld2);
                float maxDim    = max(halfExt.x, halfExt.y);
                float dirBlend  = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
                return buttonShadowEdgeAlpha(sD, blur, blurFactor, dirBlend);
            }

            // ─────────────────────────────────────────────────────────────────────
            // Marches a rounded-rect extrusion sharing the track's view tilt.
            //   sign > 0 → raised prism (base at elevation, face at elevation+height)
            //   sign < 0 → carved groove (opening at elevation+height, floor at elevation)
            // This is the same geometry/marching the Track RM block uses, factored so the
            // Track Value layer can reuse it without a second hand-written copy. Returns
            // true on hit with the hit point, baseSDF (for normals/silhouette), surface
            // class, and the ray (for groove aperture occlusion). Pure function.
            // ─────────────────────────────────────────────────────────────────────
            bool marchTrackPrism(
                float2 localP, float2 canonOff, float2 halfExt, float cornerR,
                float elevation, float height, float bevelDistRM, float bevelSmoothness, float prismSign,
                float cosT, float sinT, float2 tiltDirC, float2 tiltNormDirC, float viewShiftCam,
                float maxDim,
                out float3 outP, out float outBaseSDF, out int outSurface,
                out float3 outRayDir, out float3 outRayOrigin)
            {
                float totalHeight = max(0.001, height);
                float bevelDist   = max(0.001, bevelDistRM);
                float diag        = length(halfExt) + bevelDist;
                float boundRadius = diag * (1.2 + abs(sinT)) + totalHeight;
                float startDist   = boundRadius;

                float across = dot(localP, tiltNormDirC);
                float along  = dot(localP, tiltDirC);
                float3 planePoint = float3(across, along * sinT, -along * cosT);

                float3 rayDir, rayOrigin;
                if (_ViewFOV > 0.001)
                {
                    float focalDist = 1.0 / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                    float3 camPos   = float3(viewShiftCam, focalDist * cosT, focalDist * sinT);
                    rayDir    = normalize(planePoint - camPos);
                    rayOrigin = planePoint - rayDir * startDist;
                }
                else
                {
                    rayDir    = float3(0.0, -cosT, -sinT);
                    rayOrigin = float3(across, along * sinT + startDist * cosT, -along * cosT + startDist * sinT);
                }
                outRayDir = rayDir; outRayOrigin = rayOrigin;
                outP = rayOrigin; outBaseSDF = 0.0; outSurface = SURFACE_WALL;

                float2 faceHalfExt = max(float2(0.001, 0.001), halfExt - bevelDist);
                float  faceCornerR = max(0.0, cornerR - bevelDist);

                ExtrusionParams prm;
                prm.knobRadius = maxDim; prm.lipHeight = 0.0; prm.rimWidth = 0.0;
                prm.bevelHeight = totalHeight; prm.bevelDist = bevelDist; prm.totalHeight = totalHeight;
                prm.hasFaceShape = 0; prm.filletRadius = totalHeight * bevelSmoothness * 0.4;

                float3 boundCenter = float3(canonOff.x, elevation + totalHeight * 0.5, canonOff.y);
                float3 oc = rayOrigin - boundCenter;
                float bC = dot(oc, rayDir);
                float cC = dot(oc, oc) - boundRadius * boundRadius;
                float disc = bC * bC - cC;
                if (disc < 0.0) return false;
                float tStart = max(0.0, -bC - sqrt(disc));
                float tEnd   = -bC + sqrt(disc);
                if (tEnd <= 0.0) return false;

                float marchEps  = maxDim * 0.001;
                float taperCos  = totalHeight * rsqrt(totalHeight * totalHeight + bevelDist * bevelDist);
                float openingY  = elevation + totalHeight;
                float guardDepth = marchEps * (1.0 / max(0.001, taperCos) + 1.0);

                float t = tStart;
                float3 p = rayOrigin + t * rayDir;
                bool hitFound = false; float hitBase = 0.0;
                float closestD = 1e9; float3 closestP = p; float closestBase = 0.0;

                UNITY_LOOP for (int i = 0; i < 112; i++)
                {
                    float baseSDF_m = RoundedRectSDF(p.xz - canonOff, halfExt, cornerR);
                    float d;
                    if (prismSign < 0.0)
                    {
                        if (p.y > openingY)
                        {
                            d = max(marchEps, max(p.y - openingY, baseSDF_m));
                        }
                        else
                        {
                            float yLocal = openingY - p.y;
                            float faceSDF_m = RoundedRectSDF(p.xz - canonOff, faceHalfExt, faceCornerR);
                            float extSDF = sdfExtrusion3D(float3(p.x, yLocal, p.z), baseSDF_m, faceSDF_m, prm);
                            if (extSDF > 0.0)
                            {
                                d = max(marchEps * 0.5, extSDF * taperCos);
                                if (extSDF < closestD) { closestD = extSDF; closestP = p; closestBase = baseSDF_m; }
                            }
                            else
                            {
                                if (-extSDF < closestD) { closestD = -extSDF; closestP = p; closestBase = baseSDF_m; }
                                float floorDist = max(0.0, totalHeight - yLocal);
                                float wallStep  = -extSDF * taperCos;
                                d = max(marchEps * 0.25, min(wallStep, floorDist));
                            }
                        }
                    }
                    else
                    {
                        float faceSDF_m = RoundedRectSDF(p.xz - canonOff, faceHalfExt, faceCornerR);
                        float yLocal = p.y - elevation;
                        float extSDF = sdfExtrusion3D(float3(p.x, yLocal, p.z), baseSDF_m, faceSDF_m, prm);
                        if (extSDF > 0.0)
                        {
                            d = max(marchEps * 0.5, extSDF * taperCos);
                            if (extSDF < closestD) { closestD = extSDF; closestP = p; closestBase = baseSDF_m; }
                        }
                        else d = extSDF;
                    }
                    if (d < marchEps)
                    {
                        if (prismSign < 0.0 && p.y > openingY - guardDepth)
                            d = guardDepth / max(0.001, abs(rayDir.y));
                        else { hitFound = true; hitBase = baseSDF_m; break; }
                    }
                    if (t > tEnd) break;
                    t += max(d, marchEps * 0.5);
                    p = rayOrigin + t * rayDir;
                }
                if (!hitFound && closestD < marchEps * 30.0) { hitFound = true; p = closestP; hitBase = closestBase; }
                if (!hitFound) return false;

                int surface;
                if (prismSign < 0.0)
                    surface = (p.y <= elevation + marchEps * 4.0) ? SURFACE_FACE : SURFACE_WALL;
                else
                {
                    float yL = p.y - elevation;
                    surface = (yL >= totalHeight - maxDim * 0.005) ? SURFACE_FACE : SURFACE_WALL;
                }
                outP = p; outBaseSDF = hitBase; outSurface = surface;
                return true;
            }

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
                // One screen pixel, in the aspect-scaled quad units every shadow SDF below
                // works in. Taken HERE, at the top of frag, because it needs a derivative —
                // it becomes the minimum width of a shadow's edge, so a contact-sharp shadow
                // can never terminate in a sub-pixel step.
                float shadowAaUnit = max(fwidth(uv.x) * 2.0 * aspectScale.x,
                                         fwidth(uv.y) * 2.0 * aspectScale.y) * 0.75;
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
                float2 trackHalfExtCanon = float2(trackAxisHalf, _TrackWidth);
                float trackCornerRCanon = _TrackCornerRadius * min(trackHalfExtCanon.x, trackHalfExtCanon.y);
                float2 trackLocalP = pos;
                if (sliderHoriz < 0.5)
                    trackLocalP = float2(trackLocalP.y, -trackLocalP.x);
                float trackDist     = RoundedRectSDF(pos, trackHalfExt, trackCornerR);
                float trackAA       = fwidth(trackDist) * 0.75;
                float trackMask     = smoothstep(trackAA, -trackAA, trackDist);

                // ============================================================
                // View tilt parameters — hoisted so track + fills can share them
                // ============================================================
                // Subtract 90° for vertical sliders: handleLocalP canonical space is
                // rotated 90° (canonical.x=world.y, canonical.y=-world.x), so we
                // compensate so that tilt/shift always map to world Y/X respectively.
                float tiltRad      = (_ViewAngle + (sliderHoriz > 0.5 ? 90.0 : 0.0)) * (PI / 180.0);
                float2 tiltDir     = float2(cos(tiltRad), sin(tiltRad));
                float2 tiltNormDir = float2(-tiltDir.y, tiltDir.x);
                // Canonical-space tilt vectors for section 9 handle RM projections.
                // For horiz: canonical == world, so tiltDirCanon == tiltDir.
                // For vert: canonical.x=worldY, canonical.y=-worldX; to project onto worldX
                // (perp-to-travel) for screenAlong: dot((worldY,-worldX),(0,-1)) = worldX.
                float2 tiltDirCanon     = sliderHoriz > 0.5 ? tiltDir : float2(tiltDir.y, -tiltDir.x);
                float2 tiltNormDirCanon = float2(-tiltDirCanon.y, tiltDirCanon.x);
                // Value-driven shift/tilt, optionally aspect-gated (wide->shift only, tall->tilt only)
                float vvAspect    = _ViewValueAspectEnabled;
                float shiftActive = (_ViewValueShiftEnabled > 0.5) ? (vvAspect < 0.5 || sliderHoriz > 0.5 ? 1.0 : 0.0) : 0.0;
                float tiltActive  = (_ViewValueTiltEnabled  > 0.5) ? (vvAspect < 0.5 || sliderHoriz < 0.5 ? 1.0 : 0.0) : 0.0;
                float viewShiftEffective = UI_VIEW_SHIFT + (shiftActive > 0.5 ? lerp(_ViewValueShiftMin, _ViewValueShiftMax, _Value) : 0.0);
                float viewTiltEffective  = UI_VIEW_TILT  + (tiltActive  > 0.5 ? lerp(_ViewValueTiltMin,  _ViewValueTiltMax,  _Value) : 0.0);
                float tiltNorm     = clamp(viewTiltEffective / 10.0, -1.0, 1.0);
                float tiltAnglePre = tiltNorm * (PI * 0.5);
                float cosT         = cos(tiltAnglePre);
                float sinT         = sin(tiltAnglePre);
                float bgTiltApply    = (_BgViewTiltEnabled > 0.5) ? 1.0 : 0.0;
                float bgShiftApply   = (_BgViewShiftEnabled > 0.5) ? 1.0 : 0.0;
                float trackTiltApply = (_TrackViewTiltEnabled > 0.5) ? 1.0 : 0.0;
                float trackShiftApply = (_TrackViewShiftEnabled > 0.5) ? 1.0 : 0.0;
                float bgCosT         = lerp(1.0, cosT, bgTiltApply);
                float bgSinT         = sinT * bgTiltApply;
                float trackCosT      = lerp(1.0, cosT, trackTiltApply);
                float trackSinT      = sinT * trackTiltApply;
                float2 bgViewShiftOff    = -viewShiftEffective * tiltNormDir * bgShiftApply;
                float2 trackViewShiftOff = -viewShiftEffective * tiltNormDir * trackShiftApply;
                float bgViewShiftCamera    = viewShiftEffective * bgShiftApply;
                float trackViewShiftCamera = viewShiftEffective * trackShiftApply;
                bool bgRmEnabled    = (_BgEnabled > 0.5) && (_BgBevelEnabled > 0.5) && (_BgViewTiltEnabled > 0.5);
                bool trackRmEnabled = (_TrackEnabled > 0.5) && (_TrackBevelEnabled > 0.5) && (_TrackViewTiltEnabled > 0.5);

                // Per-part transformed positions. Handle keeps its existing RM transform path.
                float2 bgPosView    = ApplyViewTiltToPos(bgPos + bgViewShiftOff, tiltDir, tiltNormDir, bgCosT);
                float2 trackPosView = ApplyViewTiltToPos(pos + trackViewShiftOff, tiltDir, tiltNormDir, trackCosT);
                trackDist = RoundedRectSDF(trackPosView, trackHalfExt, trackCornerR);
                trackAA   = fwidth(trackDist) * 0.75;
                trackMask = smoothstep(trackAA, -trackAA, trackDist);

                // ============================================================
                // Fill region masks (on the track)
                // ============================================================
                float fillOrigin  = lerp(-sliderLength, sliderLength, saturate(_TrackValueZeroPoint));
                float axisCoord   = sliderHoriz > 0.5 ? trackPosView.x : trackPosView.y;
                // Project fill-origin and handle position through the same track tilt/shift transform
                // so mask boundaries are in the same coordinate space as axisCoord.
                float2 fillOriginPos = sliderHoriz > 0.5 ? float2(fillOrigin, 0.0) : float2(0.0, fillOrigin);
                float2 handleAxisPos2 = sliderHoriz > 0.5 ? float2(handleAxisPos, 0.0) : float2(0.0, handleAxisPos);
                float2 fillOriginViewPos = ApplyViewTiltToPos(fillOriginPos + trackViewShiftOff, tiltDir, tiltNormDir, trackCosT);
                float2 handleAxisViewPos = ApplyViewTiltToPos(handleAxisPos2 + trackViewShiftOff, tiltDir, tiltNormDir, trackCosT);
                float fillOriginView = sliderHoriz > 0.5 ? fillOriginViewPos.x : fillOriginViewPos.y;
                float handleAxisPosView = sliderHoriz > 0.5 ? handleAxisViewPos.x : handleAxisViewPos.y;
                float fillMin     = min(fillOriginView, handleAxisPosView);
                float fillMax     = max(fillOriginView, handleAxisPosView);
                float aa1         = fwidth(axisCoord) * 0.75;
                // Inset track for value fills: _TrackValuePadding shrinks the fill region inside the track groove
                float trackValueWidth    = max(0.001, _TrackWidth - _TrackValuePadding);
                float2 trackValueHalfExt = sliderHoriz > 0.5
                    ? float2(trackAxisHalf, trackValueWidth)
                    : float2(trackValueWidth, trackAxisHalf);
                float trackValueCornerR  = _TrackCornerRadius * min(trackValueHalfExt.x, trackValueHalfExt.y);
                float trackValueDist     = (_TrackValuePadding > 0.0001)
                    ? RoundedRectSDF(trackPosView, trackValueHalfExt, trackValueCornerR)
                    : trackDist;
                float trackValueAA       = fwidth(trackValueDist) * 0.75;
                float trackValueMask     = smoothstep(trackValueAA, -trackValueAA, trackValueDist);
                float filledMask  = trackValueMask
                    * smoothstep(fillMin - aa1, fillMin + aa1, axisCoord)
                    * (1.0 - smoothstep(fillMax - aa1, fillMax + aa1, axisCoord));
                float unfilledMask = trackValueMask * (1.0 - (
                    smoothstep(fillMin - aa1, fillMin + aa1, axisCoord)
                    * (1.0 - smoothstep(fillMax - aa1, fillMax + aa1, axisCoord))));
                // Canonical (untilted) fill boundaries for use inside the RM hit block
                float fillMinCanon = min(fillOrigin, handleAxisPos);
                float fillMaxCanon = max(fillOrigin, handleAxisPos);
                // Fill bevel normal — uses TrackValue bevel params (independent of track bevel).
                // When _TrackValuePadding == 0, trackValueDist == trackDist.
                // Apply view tilt so fill bevel lighting matches the handle perspective.
                float tvBevelDist  = (_TrackValueBevelEnabled > 0.5) ? max(0.001, _TrackValueBevelDistance) : 0.001;
                float tvBevelDepth = (_TrackValueBevelEnabled > 0.5) ? _TrackValueBevelDepth : 0.0;
                float fillFaceDist = trackValueDist + tvBevelDist;
                float3 fillNormal = CalculateShapeBevelNormal(fillFaceDist,
                    tvBevelDepth, tvBevelDist, _TrackValueBevelSmoothness, _TrackValueFaceSmoothness,
                    0, 0.5, aspectScale);
                {
                    float3 ta = float3(tiltDir.x, tiltDir.y, 0.0);
                    float kd = dot(ta, fillNormal);
                    float3 kc = cross(ta, fillNormal);
                    fillNormal = normalize(fillNormal * trackCosT + kc * trackSinT + ta * kd * (1.0 - trackCosT));
                }

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
                float bgPseudoHeight    = bgMaxDim * lerp(0.05, 0.5, bgBevelDepthRaw);
                float bgBevelHeightAuto = bgMaxDim * lerp(0.05, 1.0, bgBevelDepthRaw); // matches bgBevelHeightRM inside bg RM block
                float bgRimWidth    = (_BgRimEnabled > 0.5) ? _BgRimWidth : 0.0;
                float bgFaceInset   = bgRimWidth + bgBevelDist;

                float trackBevelDepthRaw = (_TrackBevelEnabled > 0.5) ? abs(_TrackBevelDepth) : 0.0;
                float trackMaxDim        = min(trackHalfExt.x, trackHalfExt.y);
                float trackPseudoHeight  = trackMaxDim * lerp(0.0, 1.0, trackBevelDepthRaw);
                float trackFaceInsetRM   = max(0.0, _TrackBevelDistance);

                // TrackValue bevel geometry — fill bevel height relative to trackValueWidth
                float trackValueBevelDepthRaw = (_TrackValueBevelEnabled > 0.5) ? abs(_TrackValueBevelDepth) : 0.0;
                float trackValuePseudoHeight  = trackValueWidth * lerp(0.0, 1.0, trackValueBevelDepthRaw);

                // Place track so its face aligns with the bg's face: no visible gap from the side.
                // trackElevation + trackPseudoHeight = bgBevelHeightAuto → track face flush with bg face.
                float bgHeightAuto  = max(0.0, bgBevelHeightAuto - trackPseudoHeight);

                // ============================================================
                // Handle RM bevel geometry (3D extrusion parameters)
                // ============================================================
                float handleBevelDist     = (_HandleBevelEnabled > 0.5) ? _HandleBevelDistance : 0.0;
                float handleBevelDepthRaw = (_HandleBevelEnabled > 0.5) ? abs(_HandleBevelDepth) : 0.0;
                float handleMinDim        = min(_HandleWidth, _HandleHeight);
                float handleBevelHeight   = handleMinDim * lerp(0.05, 1.0, handleBevelDepthRaw);
                float handleLipHeight     = handleMinDim * _HandleLipHeight;
                float handleRimWidth      = (_HandleRimEnabled > 0.5) ? _HandleRimWidth : 0.0;
                float handleFaceInset     = handleRimWidth + handleBevelDist;
                float handleTotalHeight   = handleLipHeight + handleBevelHeight;

                // ============================================================
                // SHADOW QUAD ONLY: exact original shadow rendering (bg external + track body
                // + handle body), unchanged — it just runs on the expanded backing quad
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
                        float2 ld2 = normalize(lightDir1.xy);
                        float2 bgShadowViewOff = (bgSinT * bgPseudoHeight) * tiltDir + bgViewShiftOff;
                        float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * _LightingShadow1Distance * 2.0;
                        float2 sPosRot = (abs(bgRotRad) > 0.001) ? rotate2D(sPos, bgRotRad) : sPos;
                        float2 sPosView = ApplyViewTiltToPos(sPosRot + bgShadowViewOff, tiltDir, tiltNormDir, bgCosT);
                        float sD = getPanelBodySDF(sPosView, bgHalfW, bgHalfH, bgShapeType,
                            _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                        float lightProj = dot(sPosView, ld2);
                        float maxDim = max(bgHalfW, bgHalfH);
                        float dirBlend = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
                        float sa = buttonShadowEdgeAlpha(sD, _LightingShadow1Blur, _LightingShadow1BlurFactor, dirBlend);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow1Color.rgb,
                            _LightingShadow1Color.a * sa * _LightingShadow1Intensity);
                    }
                    if (_LightingShadow2Enabled > 0.5)
                    {
                        float2 ld2 = normalize(lightDir2.xy);
                        float2 bgShadowViewOff = (bgSinT * bgPseudoHeight) * tiltDir + bgViewShiftOff;
                        float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * _LightingShadow2Distance * 2.0;
                        float2 sPosRot = (abs(bgRotRad) > 0.001) ? rotate2D(sPos, bgRotRad) : sPos;
                        float2 sPosView = ApplyViewTiltToPos(sPosRot + bgShadowViewOff, tiltDir, tiltNormDir, bgCosT);
                        float sD = getPanelBodySDF(sPosView, bgHalfW, bgHalfH, bgShapeType,
                            _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                        float lightProj = dot(sPosView, ld2);
                        float maxDim = max(bgHalfW, bgHalfH);
                        float dirBlend = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
                        float sa = buttonShadowEdgeAlpha(sD, _LightingShadow2Blur, _LightingShadow2BlurFactor, dirBlend);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow2Color.rgb,
                            _LightingShadow2Color.a * sa * _LightingShadow2Intensity);
                    }
                    if (_LightingShadow3Enabled > 0.5)
                    {
                        float2 ld2 = normalize(lightDir3.xy);
                        float2 bgShadowViewOff = (bgSinT * bgPseudoHeight) * tiltDir + bgViewShiftOff;
                        float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * _LightingShadow3Distance * 2.0;
                        float2 sPosRot = (abs(bgRotRad) > 0.001) ? rotate2D(sPos, bgRotRad) : sPos;
                        float2 sPosView = ApplyViewTiltToPos(sPosRot + bgShadowViewOff, tiltDir, tiltNormDir, bgCosT);
                        float sD = getPanelBodySDF(sPosView, bgHalfW, bgHalfH, bgShapeType,
                            _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                        float lightProj = dot(sPosView, ld2);
                        float maxDim = max(bgHalfW, bgHalfH);
                        float dirBlend = saturate(0.5 + lightProj / max(0.0001, maxDim * 2.0));
                        float sa = buttonShadowEdgeAlpha(sD, _LightingShadow3Blur, _LightingShadow3BlurFactor, dirBlend);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow3Color.rgb,
                            _LightingShadow3Color.a * sa * _LightingShadow3Intensity);
                    }

                    // Track body shadow: only for raised (positive) bevel — a groove has no
                    // raised surface to cast a shadow, and the raised-track offset would produce
                    // a phantom strip below the groove in the side view.
                    if (trackRmEnabled && _TrackBevelDepth >= 0.0)
                    {
                        float2 trackShadowViewOff = trackSinT * trackPseudoHeight * tiltDir
                            - trackViewShiftCamera * tiltNormDir;
                        float trackShadowCast = 0.5;

                        if (_LightingShadow1Enabled > 0.5)
                        {
                            float sa = calculateTrackBodyShadowRM(uv, lightDir1,
                                _LightingShadow1Blur, _LightingShadow1Distance, _LightingShadow1BlurFactor, trackShadowCast,
                                trackHalfExt, trackCornerR, trackFaceInsetRM, trackPseudoHeight,
                                aspectScale, trackShadowViewOff);
                            if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow1Color.rgb,
                                _LightingShadow1Color.a * sa * _LightingShadow1Intensity * _TrackRenderAlpha);
                        }
                        if (_LightingShadow2Enabled > 0.5)
                        {
                            float sa = calculateTrackBodyShadowRM(uv, lightDir2,
                                _LightingShadow2Blur, _LightingShadow2Distance, _LightingShadow2BlurFactor, trackShadowCast,
                                trackHalfExt, trackCornerR, trackFaceInsetRM, trackPseudoHeight,
                                aspectScale, trackShadowViewOff);
                            if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow2Color.rgb,
                                _LightingShadow2Color.a * sa * _LightingShadow2Intensity * _TrackRenderAlpha);
                        }
                        if (_LightingShadow3Enabled > 0.5)
                        {
                            float sa = calculateTrackBodyShadowRM(uv, lightDir3,
                                _LightingShadow3Blur, _LightingShadow3Distance, _LightingShadow3BlurFactor, trackShadowCast,
                                trackHalfExt, trackCornerR, trackFaceInsetRM, trackPseudoHeight,
                                aspectScale, trackShadowViewOff);
                            if (sa > 0.001) buttonCompositeOver(castShadow, _LightingShadow3Color.rgb,
                                _LightingShadow3Color.a * sa * _LightingShadow3Intensity * _TrackRenderAlpha);
                        }
                    }

                    // Handle body shadows (uses handleTotalHeight, not the 2D pseudoHeight).
                    // View-tilt/shift offset: the 3D extrusion overhangs by sinT*height in the
                    // tilt direction; camera parallax adds -viewShiftEffective along tiltNormDir.
                    float2 shadowViewOff = sinT * handleTotalHeight * tiltDir
                        - viewShiftEffective * tiltNormDir;
                    if (_HandleShadow1Enabled > 0.5)
                    {
                        float sa = calculateHandleBodyShadow(uv, lightDir1,
                            _HandleShadow1Blur, _HandleShadow1Distance, _HandleShadow1BlurFactor, _HandleShadow1Cast,
                            handleWorldPos, _HandleWidth, _HandleHeight,
                            handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3,
                            handleFaceInset, handleTotalHeight, aspectScale, handleRotRad, shadowViewOff, shadowAaUnit);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _HandleShadow1Color.rgb,
                            _HandleShadow1Color.a * sa * _HandleShadow1Intensity);
                    }
                    if (_HandleShadow2Enabled > 0.5)
                    {
                        float sa = calculateHandleBodyShadow(uv, lightDir2,
                            _HandleShadow2Blur, _HandleShadow2Distance, _HandleShadow2BlurFactor, _HandleShadow2Cast,
                            handleWorldPos, _HandleWidth, _HandleHeight,
                            handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3,
                            handleFaceInset, handleTotalHeight, aspectScale, handleRotRad, shadowViewOff, shadowAaUnit);
                        if (sa > 0.001) buttonCompositeOver(castShadow, _HandleShadow2Color.rgb,
                            _HandleShadow2Color.a * sa * _HandleShadow2Intensity);
                    }
                    if (_HandleShadow3Enabled > 0.5)
                    {
                        float sa = calculateHandleBodyShadow(uv, lightDir3,
                            _HandleShadow3Blur, _HandleShadow3Distance, _HandleShadow3BlurFactor, _HandleShadow3Cast,
                            handleWorldPos, _HandleWidth, _HandleHeight,
                            handleShapeType, _HandleShapeParam1, _HandleShapeParam2, _HandleShapeParam3,
                            handleFaceInset, handleTotalHeight, aspectScale, handleRotRad, shadowViewOff, shadowAaUnit);
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
                    float indentAlpha = calculateSliderEdgeIndent(uv, bgPosView, _EdgeWidth, _EdgeSoftness,
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
                // 2. External shadows (bg + track) — render in the shadow-pass block above
                // (_ShadowPassMode=1, expanded backing quad), not here.
                // ============================================================

                // ============================================================
                // 3. Background body + bevel + rim + lighting
                // ============================================================
                if (_BgEnabled > 0.5)
                {
                    if (bgRmEnabled)
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

                        float bgBevelDistRM   = max(0.001, bgBevelDist);
                        float bgBevelHeightRM = bgMaxDim * lerp(0.05, 1.0, bgBevelDepthRaw);
                        float bgLipHeightRM   = 0.0;
                        float bgTotalHeightRM = bgLipHeightRM + bgBevelHeightRM;
                        float bgDiag = length(float2(bgHalfW, bgHalfH)) + bgBevelDistRM;

                        float screenAcross = dot(bgPos, tiltNormDir);
                        float screenAlong  = dot(bgPos, tiltDir);
                        float boundRadius  = bgDiag * (1.2 + abs(bgSinT)) + bgTotalHeightRM;
                        float startDist    = boundRadius;
                        float3 bgPlanePoint = float3(screenAcross, screenAlong * bgSinT, -screenAlong * bgCosT);

                        float3 rayDir;
                        float3 rayOrigin;
                        if (_ViewFOV > 0.001)
                        {
                            float focalDist = 1.0 / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                            float3 camPos   = float3(bgViewShiftCamera, focalDist * bgCosT, focalDist * bgSinT);
                            rayDir          = normalize(bgPlanePoint - camPos);
                            rayOrigin       = bgPlanePoint - rayDir * startDist;
                        }
                        else
                        {
                            rayDir    = float3(0.0, -bgCosT, -bgSinT);
                            rayOrigin = float3(
                                screenAcross,
                                screenAlong * bgSinT + startDist * bgCosT,
                                -screenAlong * bgCosT + startDist * bgSinT
                            );
                        }

                        float3 boundCenter = float3(0.0, bgTotalHeightRM * 0.5, 0.0);
                        float3 oc = rayOrigin - boundCenter;
                        float bCoeff = dot(oc, rayDir);
                        float cCoeff = dot(oc, oc) - boundRadius * boundRadius;
                        float disc = bCoeff * bCoeff - cCoeff;

                        if (disc >= 0.0)
                        {
                            float tStart = max(0.0, -bCoeff - sqrt(disc));
                            float tEnd   = -bCoeff + sqrt(disc);
                            if (tEnd > 0.0)
                            {
                                ExtrusionParams extParams;
                                extParams.knobRadius   = bgMaxDim;
                                extParams.lipHeight    = bgLipHeightRM;
                                extParams.rimWidth     = bgRimWidth;
                                extParams.bevelHeight  = bgBevelHeightRM;
                                extParams.bevelDist    = bgBevelDistRM;
                                extParams.totalHeight  = bgTotalHeightRM;
                                extParams.hasFaceShape = 0;
                                extParams.filletRadius = bgBevelHeightRM * _BgBevelSmoothness * 0.4;

                                // sdfExtrusion3D's bevel body has gradient magnitude
                                // sqrt(1 + (bevelDist/bevelH)^2) > 1. Scaling steps by cosB
                                // (= 1/gradMag) keeps sphere-march conservative at acute view angles.
                                float bgBevelCosB = bgBevelHeightRM / max(0.0001, sqrt(
                                    bgBevelHeightRM * bgBevelHeightRM + bgBevelDistRM * bgBevelDistRM));

                                float t = tStart;
                                float3 p = rayOrigin + t * rayDir;
                                float marchEps = bgMaxDim * 0.001;
                                float hitBaseSDF = 0.0;
                                bool hitFound = false;
                                // Track closest approach — fallback when march exits bound without converging.
                                float closestD  = 1e10;
                                float3 closestP = p;
                                float closestBase = 0.0;

                                UNITY_LOOP for (int i = 0; i < 128; i++)
                                {
                                    float baseSDF_m = getPanelBodySDF(p.xz, bgHalfW, bgHalfH, bgShapeType,
                                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                                    float faceSDF_m = baseSDF_m + bgFaceInset;
                                    float d = sdfExtrusion3D(p, baseSDF_m, faceSDF_m, extParams);
                                    if (d < marchEps) {
                                        hitFound = true;
                                        hitBaseSDF = baseSDF_m;
                                        break;
                                    }
                                    if (d > 0.0 && d < closestD) { closestD = d; closestP = p; closestBase = baseSDF_m; }
                                    if (t > tEnd) break;
                                    t += max(d * bgBevelCosB, marchEps * 0.5);
                                    p = rayOrigin + t * rayDir;
                                }
                                // Fallback: came very close but exited bounding sphere before converging
                                // (near-tangent rays at acute tilt). Threshold covers max overshoot.
                                if (!hitFound && closestD < marchEps * 30.0)
                                {
                                    hitFound = true;
                                    p = closestP;
                                    hitBaseSDF = closestBase;
                                }

                                if (hitFound)
                                {
                                    float y = p.y;
                                    float surfaceEps = bgMaxDim * 0.004;
                                    int hitSurface = (y >= bgTotalHeightRM - surfaceEps) ? SURFACE_FACE : SURFACE_WALL;

                                    float eps2d = max(0.0005, bgMaxDim * 0.004);
                                    float bdx = getPanelBodySDF(p.xz + float2(eps2d, 0), bgHalfW, bgHalfH, bgShapeType,
                                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                                    float bdz = getPanelBodySDF(p.xz + float2(0, eps2d), bgHalfW, bgHalfH, bgShapeType,
                                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                                    float2 grad2D = float2(bdx - hitBaseSDF, bdz - hitBaseSDF);
                                    float gLen = length(grad2D);
                                    float2 gradN = (gLen > 0.0001) ? (grad2D / gLen) : float2(1, 0);

                                    float3 hitNormal;
                                    if (hitSurface == SURFACE_FACE)
                                    {
                                        hitNormal = float3(0, 1, 0);
                                        if (abs(_BgFaceSmoothness) > 0.001)
                                        {
                                            float r = length(p.xz);
                                            float radialT = saturate(r / max(0.001, bgMaxDim - bgFaceInset));
                                            float2 radialDir2D = (r > 0.0001) ? (p.xz / r) : float2(0, 0);
                                            hitNormal = normalize(hitNormal + float3(radialDir2D.x, 0, radialDir2D.y) * (_BgFaceSmoothness * radialT));
                                        }
                                    }
                                    else
                                    {
                                        float bevelAngleRM = atan2(bgBevelHeightRM, max(0.0001, bgBevelDistRM));
                                        float sinB = sin(bevelAngleRM);
                                        float cosB = cos(bevelAngleRM);
                                        hitNormal = normalize(float3(gradN.x * sinB, cosB, gradN.y * sinB));
                                    }

                                    float3 screenNormal3D = normalToScreenSpace(hitNormal, bgSinT, bgCosT);
                                    float2 screenNorm2D = screenNormal3D.x * tiltNormDir + screenNormal3D.y * tiltDir;
                                    float3 lightNormal = normalize(float3(-screenNorm2D, max(0.0, screenNormal3D.z)));

                                    float outerAA = fwidth(hitBaseSDF) * 0.75;
                                    float outerMask = (hitSurface == SURFACE_FACE)
                                        ? smoothstep(outerAA, -outerAA, hitBaseSDF)
                                        : 1.0;

                                    float bgSpecularMod = 1.0;
                                    float2 bgNormalOffset = float2(0, 0);
                                    float2 faceUV = p.xz / float2(bgHalfW * 2.0, bgHalfH * 2.0) + 0.5;
                                    faceUV = saturate(faceUV);
                                    float2 faceUVPattern = saturate(p.xz * 0.5 + 0.5);

                                    float3 surfaceColorBase = bgBaseColor;
                                    if (hitSurface == SURFACE_FACE && _BgPatternEnabled > 0.5)
                                    {
                                        surfaceColorBase = ApplyMaterialPattern(bgBaseColor, faceUVPattern, bgComp,
                                            0.0, 0.0, bgSpecularMod, bgNormalOffset);
                                    }
                                    if (hitSurface == SURFACE_WALL)
                                    {
                                        if (_BgBevelGradientEnabled > 0.5)
                                        {
                                            float4 gc = CalculateGradient(faceUV,
                                                _BgBevelGradientColorA, _BgBevelGradientColorB,
                                                _BgBevelGradientColorC, _BgBevelGradientColorD,
                                                _BgBevelGradientDirection, _BgBevelGradientType,
                                                _BgBevelGradientSpeed, _BgBevelGradientScale,
                                                _BgBevelGradientOffset, time, _BgBevelGradientColorUsed);
                                            surfaceColorBase = gc.rgb;
                                        }
                                    }

                                    float3 surfaceLit = ApplyUILighting(lightNormal, surfaceColorBase,
                                        _LightingAmbient, bgSpecularMod, bgNormalOffset, light1, light2, light3);

                                    buttonCompositeOver(finalColor, surfaceLit, outerMask * _BgRenderAlpha);
                                    emissiveAccum += bgBaseColor * outerMask * _BgRenderEmissive;
                                }
                                else
                                {
                                    // RM miss: render flat BG face as fallback to seal seams at extreme tilt angles.
                                    float bgDist2D = getPanelBodySDF(bgPosView, bgHalfW, bgHalfH, bgShapeType,
                                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                                    float bgAA2D   = fwidth(bgDist2D) * 0.75;
                                    float bgMask2D = smoothstep(bgAA2D, -bgAA2D, bgDist2D);
                                    if (bgMask2D > 0.001)
                                    {
                                        float3 bgFaceScreenN = normalToScreenSpace(float3(0, 1, 0), bgSinT, bgCosT);
                                        float2 bgFaceN2D = bgFaceScreenN.x * tiltNormDir + bgFaceScreenN.y * tiltDir;
                                        float3 bgFaceLightN = normalize(float3(-bgFaceN2D, max(0.0, bgFaceScreenN.z)));
                                        float3 fallbackLit = ApplyUILighting(bgFaceLightN, bgBaseColor, _LightingAmbient, 1.0, float2(0, 0), light1, light2, light3);
                                        buttonCompositeOver(finalColor, fallbackLit, bgMask2D * _BgRenderAlpha);
                                        emissiveAccum += bgBaseColor * bgMask2D * _BgRenderEmissive;
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        float bgDist     = getPanelBodySDF(bgPosView, bgHalfW, bgHalfH, bgShapeType,
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
                            {
                                float3 ta = float3(tiltDir.x, tiltDir.y, 0.0);
                                float kd = dot(ta, bgNormal);
                                float3 kc = cross(ta, bgNormal);
                                bgNormal = normalize(bgNormal * bgCosT + kc * bgSinT + ta * kd * (1.0 - bgCosT));
                            }

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
                }

                // Track RM hit point (world/tilted space) + valid flag — captured here so
                // the Track Value layer (4b) can depth-sort against the track for mutual
                // occlusion (groove wall in front of the value, value in front of floor).
                bool   trackHitValid = false;
                float3 trackHitP     = float3(0, 0, 0);

                // ============================================================
                // 4. Track base (simple: no bevel profile, no pattern color)
                // ============================================================
                if (_TrackEnabled > 0.5 && (trackRmEnabled || trackMask > 0.001))
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

                    if (trackRmEnabled)
                    {
                        float trackBevelDistRM = max(0.001, _TrackBevelDistance);
                        float trackTotalHeight = max(0.001, trackPseudoHeight);
                        // Track elevation:
                        //   positive depth → prism base AT bgFaceLevel, face extrudes UP
                        //   negative depth → prism base at bgFaceLevel-h, face FLUSH with bgFaceLevel
                        //   Both cases: face is always h above base, walls visible from outside
                        float bgFaceLevel    = bgRmEnabled ? bgBevelHeightAuto : 0.0;
                        float trackBevelSign = (_TrackBevelDepth >= 0.0) ? 1.0 : -1.0;
                        // Use trackTotalHeight (clamped) not trackPseudoHeight so that
                        // grooveOpeningY = trackElevation + trackTotalHeight = bgFaceLevel exactly,
                        // keeping the groove flush with the BG face at all depth values.
                        float trackElevation = bgFaceLevel + min(0.0, trackBevelSign) * trackTotalHeight + _TrackViewElevation;
                        float trackDiag = length(trackHalfExtCanon) + trackBevelDistRM;
                        float trackBoundRadius = trackDiag * (1.2 + abs(trackSinT)) + trackTotalHeight;
                        float trackStartDist = trackBoundRadius;

                        float trAcross = dot(trackLocalP, tiltNormDirCanon);
                        float trAlong  = dot(trackLocalP, tiltDirCanon);
                        float3 trPlanePoint = float3(trAcross, trAlong * trackSinT, -trAlong * trackCosT);

                        float3 trRayDir;
                        float3 trRayOrigin;
                        if (_ViewFOV > 0.001)
                        {
                            float focalDist = 1.0 / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                            float3 camPos   = float3(trackViewShiftCamera, focalDist * trackCosT, focalDist * trackSinT);
                            trRayDir        = normalize(trPlanePoint - camPos);
                            trRayOrigin     = trPlanePoint - trRayDir * trackStartDist;
                        }
                        else
                        {
                            trRayDir = float3(0.0, -trackCosT, -trackSinT);
                            trRayOrigin = float3(
                                trAcross,
                                trAlong * trackSinT + trackStartDist * trackCosT,
                                -trAlong * trackCosT + trackStartDist * trackSinT
                            );
                        }

                        float3 trBoundCenter = float3(0.0, trackElevation + trackTotalHeight * 0.5, 0.0);
                        float3 ocT = trRayOrigin - trBoundCenter;
                        float bCoeffT = dot(ocT, trRayDir);
                        float cCoeffT = dot(ocT, ocT) - trackBoundRadius * trackBoundRadius;
                        float discT = bCoeffT * bCoeffT - cCoeffT;

                        if (discT >= 0.0)
                        {
                            float tStartT = max(0.0, -bCoeffT - sqrt(discT));
                            float tEndT   = -bCoeffT + sqrt(discT);
                            if (tEndT > 0.0)
                            {
                                ExtrusionParams trParams;
                                trParams.knobRadius   = trackMaxDim;
                                trParams.lipHeight    = 0.0;
                                trParams.rimWidth     = 0.0;
                                trParams.bevelHeight  = trackTotalHeight;
                                trParams.bevelDist    = trackBevelDistRM;
                                trParams.totalHeight  = trackTotalHeight;
                                trParams.hasFaceShape = 0;
                                trParams.filletRadius = trackTotalHeight * _TrackBevelSmoothness * 0.4;

                                float t = tStartT;
                                float marchEps = trackMaxDim * 0.001;
                                float3 p = trRayOrigin + t * trRayDir;
                                float hitBaseSDF = 0.0;
                                bool hitFound = false;
                                float2 trackFaceHalfExt = max(float2(0.001, 0.001), trackHalfExtCanon - trackFaceInsetRM);
                                float trackFaceCornerR = max(0.0, trackCornerRCanon - trackFaceInsetRM);
                                // Groove opening Y (= bgFaceLevel for negative bevel; unused but harmless for positive).
                                float grooveOpeningY = trackElevation + trackTotalHeight;
                                // Projects the lateral wall SDF onto the ray direction (conservative sphere-march
                                // step for a vertical ray hitting the sloped bevel wall).
                                // grooveTaperCos = cos(bevelAngle from vertical) = totalH / sqrt(totalH²+bevelDist²)
                                float grooveTaperCos = trackTotalHeight * rsqrt(
                                    trackTotalHeight * trackTotalHeight + trackBevelDistRM * trackBevelDistRM);
                                // Opening guard: depth past which d = yLocal*grooveTaperCos exceeds marchEps,
                                // so the guard jump never causes a spurious immediate re-hit.
                                float grooveGuardDepth = marchEps * (1.0 / max(0.001, grooveTaperCos) + 1.0);

                                float trClosestD = 1e9;
                                float3 trClosestP = p;
                                float trClosestBase = 0.0;
                                UNITY_LOOP for (int i = 0; i < 112; i++)
                                {
                                    float baseSDF_m = RoundedRectSDF(p.xz, trackHalfExtCanon, trackCornerRCanon);
                                    float d;
                                    if (trackBevelSign < 0.0)
                                    {
                                        // Groove: march the INSIDE of an inverted extrusion — same shape as the
                                        // positive bevel but with Y flipped so the wide opening is at grooveOpeningY
                                        // and the narrow floor is below.  sdfExtrusion3D returns NEGATIVE inside
                                        // the solid; negate to get distance to the nearest inner surface (wall/floor).
                                        if (p.y > grooveOpeningY)
                                        {
                                            // Conservative advance toward the groove opening: use the LARGER of
                                            // the vertical gap to the opening plane and the lateral gap to the
                                            // footprint (a valid distance lower bound). The previous SUM of the
                                            // two overshot the rim at tilt and skipped the top of the far wall,
                                            // leaving a flat hole where the groove wall should be.
                                            d = max(marchEps, max(p.y - grooveOpeningY, baseSDF_m));
                                        }
                                        else
                                        {
                                            float yLocal = grooveOpeningY - p.y; // 0 at opening, + going deeper
                                            float faceSDF_m = RoundedRectSDF(p.xz, trackFaceHalfExt, trackFaceCornerR);
                                            float extSDF = sdfExtrusion3D(float3(p.x, yLocal, p.z), baseSDF_m, faceSDF_m, trParams);
                                            if (extSDF > 0.0)
                                            {
                                                // Scale by grooveTaperCos: bevel SDF gradient > 1 (= 1/grooveTaperCos),
                                                // so unscaled extSDF overshoots the surface. Scaling makes it conservative.
                                                d = max(marchEps * 0.5, extSDF * grooveTaperCos);
                                                if (extSDF < trClosestD) { trClosestD = extSDF; trClosestP = p; trClosestBase = baseSDF_m; }
                                            }
                                            else
                                            {
                                                // Inside the prism (groove air): distance to the nearest wall/floor
                                                // is -extSDF. Track it for the closest-approach fallback so a wall
                                                // hit the march steps past is still recovered — mirrors the outside
                                                // branch. Without this the groove far wall vanishes on a near miss.
                                                if (-extSDF < trClosestD) { trClosestD = -extSDF; trClosestP = p; trClosestBase = baseSDF_m; }
                                                // Project lateral wall SDF onto the ray direction (grooveTaperCos),
                                                // but clamp to the floor distance so shallow grooves converge fast.
                                                float floorDist = max(0.0, trackTotalHeight - yLocal);
                                                float wallStep = -extSDF * grooveTaperCos;
                                                d = max(marchEps * 0.25, min(wallStep, floorDist));
                                            }
                                        }
                                    }
                                    else
                                    {
                                        float faceSDF_m = RoundedRectSDF(p.xz, trackFaceHalfExt, trackFaceCornerR);
                                        float yLocal = p.y - trackElevation;
                                        float extSDF = sdfExtrusion3D(float3(p.x, yLocal, p.z), baseSDF_m, faceSDF_m, trParams);
                                        if (extSDF > 0.0)
                                        {
                                            // Conservative step (bevel SDF gradient > 1, same reasoning
                                            // as grooveTaperCos above) so the raised wall is not tunnelled
                                            // through at grazing tilt. Track closest approach for fallback.
                                            d = max(marchEps * 0.5, extSDF * grooveTaperCos);
                                            if (extSDF < trClosestD) { trClosestD = extSDF; trClosestP = p; trClosestBase = baseSDF_m; }
                                        }
                                        else
                                        {
                                            d = extSDF;
                                        }
                                    }
                                    if (d < marchEps) {
                                        // Groove: skip hits at the opening face (yLocal ≈ 0 = p.y ≈ grooveOpeningY).
                                        // grooveGuardDepth is chosen so the first step after the jump gives
                                        // d = yLocal*grooveTaperCos ≥ marchEps, preventing immediate re-trigger.
                                        if (trackBevelSign < 0.0 && p.y > grooveOpeningY - grooveGuardDepth)
                                        {
                                            d = grooveGuardDepth / max(0.001, abs(trRayDir.y));
                                        }
                                        else
                                        {
                                            hitFound = true;
                                            hitBaseSDF = baseSDF_m;
                                            break;
                                        }
                                    }
                                    if (t > tEndT) break;
                                    t += max(d, marchEps * 0.5);
                                    p = trRayOrigin + t * trRayDir;
                                }
                                // Closest-approach fallback for both groove (negative) and raised
                                // (positive) bevels: near-tangent rays at steep tilt may exhaust the
                                // loop before converging onto the wall. Snapping to the nearest sampled
                                // surface point keeps the wall from disappearing.
                                if (!hitFound && trClosestD < marchEps * 30.0)
                                {
                                    hitFound = true;
                                    p = trClosestP;
                                    hitBaseSDF = trClosestBase;
                                }


                                if (hitFound)
                                {
                                    // Record nearest track surface for the value layer's depth sort.
                                    trackHitValid = true;
                                    trackHitP     = p;

                                    int hitSurface;
                                    if (trackBevelSign < 0.0)
                                        hitSurface = (p.y <= trackElevation + marchEps * 4.0) ? SURFACE_FACE : SURFACE_WALL;
                                    else
                                    {
                                        float yLocalHit = p.y - trackElevation;
                                        hitSurface = (yLocalHit >= trackTotalHeight - trackMaxDim * 0.005) ? SURFACE_FACE : SURFACE_WALL;
                                    }

                                    float3 hitNormal;
                                    {
                                        float eps2d = max(0.0005, trackMaxDim * 0.004);
                                        // Gradient of baseSDF in foreshortened p.xz space — correct for both the
                                        // positive extrusion (outer wall direction) and the inverted groove
                                        // (sdfExtrusion3D wall gradient is baseSDF gradient in same p.xz space).
                                        // The (trackBevelSign < 0 ? -1 : 1) below flips wall normals inward for groove.
                                        float gradRef = hitBaseSDF;
                                        float bdx = RoundedRectSDF(p.xz + float2(eps2d, 0), trackHalfExtCanon, trackCornerRCanon);
                                        float bdz = RoundedRectSDF(p.xz + float2(0, eps2d), trackHalfExtCanon, trackCornerRCanon);
                                        float2 grad2D = float2(bdx - gradRef, bdz - gradRef);
                                        float gLen = length(grad2D);
                                        float2 gradN = (gLen > 0.0001) ? (grad2D / gLen) : float2(1, 0);

                                        if (hitSurface == SURFACE_FACE)
                                        {
                                            hitNormal = float3(0, 1, 0);
                                        }
                                        else
                                        {
                                            float bevelAngleRM = atan2(trackTotalHeight, max(0.0001, trackBevelDistRM));
                                            float sinB = sin(bevelAngleRM);
                                            float cosB = cos(bevelAngleRM);
                                            hitNormal = normalize(float3(gradN.x * sinB * ((trackBevelSign < 0.0) ? -1.0 : 1.0), cosB, gradN.y * sinB * ((trackBevelSign < 0.0) ? -1.0 : 1.0)));
                                        }
                                    }

                                    UNITY_BRANCH if (hitSurface == SURFACE_FACE && abs(_TrackFaceSmoothness) > 0.001)
                                    {
                                        // p.xz is the physical position at the hit point in the tilted SDF space.
                                        // For groove floor, p.z is the physical cross-track position — same space
                                        // as _TrackWidth. Do NOT use -(p.y*sinT - p.z*cosT) here: that is the
                                        // canonical screen-space coordinate, which diverges from p.z at any tilt>0
                                        // and shifts the dome center off the floor center.
                                        float2 xz = p.xz;
                                        float r = length(xz);
                                        float refR = max(0.001, trackMaxDim - trackFaceInsetRM);
                                        float rt = saturate(r / refR);
                                        float2 rdir = (r > 0.0001) ? (xz / r) : float2(0, 0);
                                        float dome = _TrackFaceSmoothness * rt;
                                        hitNormal = normalize(hitNormal + float3(rdir.x * dome, 0, rdir.y * dome));
                                    }

                                    // Pre-compute fill zone (axisHit/crossHit) — also used for fill bevel normal below.
                                    // trAlongHit recovers the canonical along-track coord from the tilted hit point.
                                    float trAlongHit = p.y * trackSinT - p.z * trackCosT;
                                    float axisHit    = p.x * tiltNormDirCanon.x + trAlongHit * tiltDirCanon.x;
                                    float crossSigned = p.x * tiltNormDirCanon.y + trAlongHit * tiltDirCanon.y;
                                    float crossHit   = abs(crossSigned);
                                    bool inValueInset = (crossHit <= trackValueWidth);
                                    bool inFillRange  = (axisHit >= fillMinCanon && axisHit <= fillMaxCanon);

                                    // Surface-space UV for the value-fill gradients so they conform to the
                                    // tilted floor instead of being screen-locked. axisHit/crossSigned are
                                    // physical floor coords (same space the fill region is masked in), so the
                                    // gradient now foreshortens with the groove just like the face pattern.
                                    float2 trackFillUV = saturate(float2(
                                        axisHit    / max(0.0001, 2.0 * trackAxisHalf)   + 0.5,
                                        crossSigned / max(0.0001, 2.0 * trackValueWidth) + 0.5));

                                    // TrackValue bevel normal override (legacy fake-bevel, shading only):
                                    // SUPERSEDED by the real RM value geometry in section 4b, which draws
                                    // the raised/lowered value strip as actual marched geometry over the
                                    // track. Disabled here so the two don't double up and so the bare track
                                    // shows through in the unfilled channel when Unfilled is off.
                                    if (false && hitSurface == SURFACE_FACE && _TrackValueBevelEnabled > 0.5 && abs(_TrackValueBevelDepth) > 0.0001 && inValueInset)
                                    {
                                        float2 tvHalfExt2  = float2(trackAxisHalf, trackValueWidth);
                                        float  tvCornerR2  = _TrackCornerRadius * min(tvHalfExt2.x, tvHalfExt2.y);
                                        float2 tvP2D       = float2(axisHit, crossSigned);
                                        float  tvSDF2D     = RoundedRectSDF(tvP2D, tvHalfExt2, tvCornerR2);

                                        float eps2dv = max(0.0005, trackValueWidth * 0.02);
                                        float2 tvGrad2D = float2(
                                            RoundedRectSDF(tvP2D + float2(eps2dv, 0), tvHalfExt2, tvCornerR2) - tvSDF2D,
                                            RoundedRectSDF(tvP2D + float2(0, eps2dv), tvHalfExt2, tvCornerR2) - tvSDF2D
                                        ) / eps2dv;
                                        float  tvGLen  = length(tvGrad2D);
                                        float2 tvGradN = (tvGLen > 0.0001) ? (tvGrad2D / tvGLen) : float2(1, 0);

                                        float tvBevelDistRM  = max(0.001, _TrackValueBevelDistance);
                                        float tvBevelHeight  = trackValueWidth * lerp(0.0, 1.0, trackValueBevelDepthRaw);
                                        float tvBevelAngle   = atan2(tvBevelHeight, tvBevelDistRM);
                                        float tvSinB         = sin(tvBevelAngle);
                                        float tvCosB         = cos(tvBevelAngle);
                                        float tvDepthSign    = (_TrackValueBevelDepth >= 0.0) ? 1.0 : -1.0;

                                        float tvFaceD     = tvSDF2D + tvBevelDistRM;
                                        float tvWallBlend = 1.0 - saturate(tvFaceD / tvBevelDistRM);

                                        float3 tvWallNorm = normalize(float3(tvGradN.x * tvSinB * tvDepthSign, tvCosB, tvGradN.y * tvSinB * tvDepthSign));
                                        float3 tvFaceNorm = float3(0, 1, 0);
                                        UNITY_BRANCH if (abs(_TrackValueFaceSmoothness) > 0.001)
                                        {
                                            float tvR    = length(tvP2D);
                                            float tvRefR = max(0.001, min(tvHalfExt2.x, tvHalfExt2.y) - tvBevelDistRM);
                                            float tvRT   = saturate(tvR / tvRefR);
                                            float2 tvRDir = (tvR > 0.0001) ? (tvP2D / tvR) : float2(0, 0);
                                            tvFaceNorm = normalize(float3(tvRDir.x * _TrackValueFaceSmoothness * tvRT, 1.0, tvRDir.y * _TrackValueFaceSmoothness * tvRT));
                                        }
                                        hitNormal = lerp(tvFaceNorm, tvWallNorm, tvWallBlend);
                                    }

                                    // Groove rim fillet: blend wall normal toward flat at the groove opening
                                    // so _TrackBevelSmoothness rounds the visible rim rather than doing nothing.
                                    if (trackBevelSign < 0.0 && hitSurface == SURFACE_WALL)
                                    {
                                        float grooveFilletR = trackTotalHeight * _TrackBevelSmoothness * 0.4;
                                        if (grooveFilletR > 0.001)
                                        {
                                            float grooveOpeningYHit = trackElevation + trackTotalHeight;
                                            float openingDist = grooveOpeningYHit - p.y;
                                            float rimT = 1.0 - saturate(openingDist / grooveFilletR);
                                            hitNormal = normalize(lerp(hitNormal, float3(0, 1, 0), rimT * rimT));
                                        }
                                    }

                                    float3 screenNormal3D = normalToScreenSpace(hitNormal, trackSinT, trackCosT);
                                    float2 screenNorm2D = screenNormal3D.x * tiltNormDir + screenNormal3D.y * tiltDir;
                                    float3 lightNormal = normalize(float3(-screenNorm2D, max(0.0, screenNormal3D.z)));

                                    // For groove floor, clip to floor footprint (R-bd), not opening footprint (R).
                                    // p.xz is the physical hit position in the tilted SDF space — same units as
                                    // _TrackWidth and trackFaceHalfExt. Do NOT use (p.x, -trAlongHit): -trAlongHit
                                    // equals p.z*cosT - trackElevation*sinT, which shifts the footprint away from
                                    // the floor center at any tilt>0 and with FOV, clipping the near side of the floor.
                                    float outerMaskSDF = hitBaseSDF;
                                    if (trackBevelSign < 0.0 && hitSurface == SURFACE_FACE)
                                        outerMaskSDF = RoundedRectSDF(p.xz, trackFaceHalfExt, trackFaceCornerR);
                                    float outerAA = fwidth(outerMaskSDF) * 0.75;
                                    float outerMask = (hitSurface == SURFACE_FACE)
                                        ? smoothstep(outerAA, -outerAA, outerMaskSDF)
                                        : 1.0;

                                    float3 trackSurfaceColor = trackBaseColor;
                                    float trackSpecMod = 0.0;
                                    float2 trackNormOff = float2(0, 0);
                                    if (hitSurface == SURFACE_FACE && _TrackPatternEnabled > 0.5)
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
                                        float2 trUVPattern = p.xz * 0.5 + 0.5;
                                        trackSurfaceColor = ApplyMaterialPattern(trackBaseColor, saturate(trUVPattern), trackCompSimple,
                                            0.0, 0.0, trackSpecMod, trackNormOff);
                                    }

                                    // Fill zone color override (face and wall both get fill color for bevel).
                                    // axisHit/crossHit/inValueInset/inFillRange are pre-computed above.
                                    float trackFinalAlpha = _TrackRenderAlpha;
                                    float3 trackFinalEmissiveBase = trackBaseColor;
                                    float trackFinalEmissive = _TrackRenderEmissive;
                                    {
                                        if (inValueInset && inFillRange)
                                        {
                                            float3 fillCol = trackSurfaceColor;
                                            float fillAlpha = _TrackRenderAlpha;
                                            float fillEmissive = _TrackRenderEmissive;
                                            if (handleAxisPos >= fillOrigin)
                                            {
                                                if (_TrackValueFilledEnabled > 0.5)
                                                {
                                                    fillCol = _TrackValueFilledColor.rgb;
                                                    if (_TrackValueFilledGradientEnabled > 0.5)
                                                    { float4 gc = CalculateGradient(trackFillUV, _TrackValueFilledGradientColorA, _TrackValueFilledGradientColorB, _TrackValueFilledGradientColorC, _TrackValueFilledGradientColorD, _TrackValueFilledGradientDirection, _TrackValueFilledGradientType, _TrackValueFilledGradientSpeed, _TrackValueFilledGradientScale, _TrackValueFilledGradientOffset, time, _TrackValueFilledGradientColorUsed); fillCol = lerp(fillCol, gc.rgb, gc.a); }
                                                    if (_TrackValueFilledGlobalBlend > 0.0)
                                                    { float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time); fillCol = lerp(fillCol, gc.rgb, _TrackValueFilledGlobalBlend * _TrackValueFilledGlobalIntensity); }
                                                    fillAlpha = _TrackValueFilledRenderAlpha;
                                                    fillEmissive = _TrackValueFilledRenderEmissive;
                                                }
                                            }
                                            else
                                            {
                                                if (_TrackValueNegativeEnabled > 0.5)
                                                {
                                                    fillCol = _TrackValueNegativeColor.rgb;
                                                    if (_TrackValueNegativeGradientEnabled > 0.5)
                                                    { float4 gc = CalculateGradient(trackFillUV, _TrackValueNegativeGradientColorA, _TrackValueNegativeGradientColorB, _TrackValueNegativeGradientColorC, _TrackValueNegativeGradientColorD, _TrackValueNegativeGradientDirection, _TrackValueNegativeGradientType, _TrackValueNegativeGradientSpeed, _TrackValueNegativeGradientScale, _TrackValueNegativeGradientOffset, time, _TrackValueNegativeGradientColorUsed); fillCol = lerp(fillCol, gc.rgb, gc.a); }
                                                    if (_TrackValueNegativeGlobalBlend > 0.0)
                                                    { float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time); fillCol = lerp(fillCol, gc.rgb, _TrackValueNegativeGlobalBlend * _TrackValueNegativeGlobalIntensity); }
                                                    fillAlpha = _TrackValueNegativeRenderAlpha;
                                                    fillEmissive = _TrackValueNegativeRenderEmissive;
                                                }
                                                else if (_TrackValueFilledEnabled > 0.5)
                                                {
                                                    fillCol = _TrackValueFilledColor.rgb;
                                                    if (_TrackValueFilledGradientEnabled > 0.5)
                                                    { float4 gc = CalculateGradient(trackFillUV, _TrackValueFilledGradientColorA, _TrackValueFilledGradientColorB, _TrackValueFilledGradientColorC, _TrackValueFilledGradientColorD, _TrackValueFilledGradientDirection, _TrackValueFilledGradientType, _TrackValueFilledGradientSpeed, _TrackValueFilledGradientScale, _TrackValueFilledGradientOffset, time, _TrackValueFilledGradientColorUsed); fillCol = lerp(fillCol, gc.rgb, gc.a); }
                                                    if (_TrackValueFilledGlobalBlend > 0.0)
                                                    { float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time); fillCol = lerp(fillCol, gc.rgb, _TrackValueFilledGlobalBlend * _TrackValueFilledGlobalIntensity); }
                                                    fillAlpha = _TrackValueFilledRenderAlpha;
                                                    fillEmissive = _TrackValueFilledRenderEmissive;
                                                }
                                            }
                                            trackSurfaceColor = fillCol;
                                            trackFinalAlpha = fillAlpha;
                                            trackFinalEmissiveBase = fillCol;
                                            trackFinalEmissive = fillEmissive;
                                        }
                                        else if (inValueInset && !inFillRange && _TrackValueUnfilledEnabled > 0.5)
                                        {
                                            float3 vufc = _TrackValueUnfilledColor.rgb;
                                            if (_TrackValueUnfilledGradientEnabled > 0.5)
                                            { float4 gc = CalculateGradient(trackFillUV, _TrackValueUnfilledGradientColorA, _TrackValueUnfilledGradientColorB, _TrackValueUnfilledGradientColorC, _TrackValueUnfilledGradientColorD, _TrackValueUnfilledGradientDirection, _TrackValueUnfilledGradientType, _TrackValueUnfilledGradientSpeed, _TrackValueUnfilledGradientScale, _TrackValueUnfilledGradientOffset, time, _TrackValueUnfilledGradientColorUsed); vufc = lerp(vufc, gc.rgb, gc.a); }
                                            if (_TrackValueUnfilledGlobalBlend > 0.0)
                                            { float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time); vufc = lerp(vufc, gc.rgb, _TrackValueUnfilledGlobalBlend * _TrackValueUnfilledGlobalIntensity); }
                                            trackSurfaceColor = vufc;
                                            trackFinalAlpha = _TrackValueUnfilledRenderAlpha;
                                            trackFinalEmissiveBase = vufc;
                                            trackFinalEmissive = _TrackValueUnfilledRenderEmissive;
                                        }
                                    }

                                    // For groove: only render if the view ray passes through the physical
                                    // groove aperture — i.e. its intersection with the groove opening plane
                                    // (y = grooveOpeningY) falls inside the track footprint in 3D.
                                    // Using trAlong (screen Y) directly would make the aperture 1/cosT times
                                    // too wide at tilt T, causing groove to bleed through the BG side walls.
                                    float bgOccFactor = 1.0;
                                    if (trackBevelSign < 0.0)
                                    {
                                        if (trRayDir.y < -0.0001)
                                        {
                                            // Intersect the ray with the groove opening plane (y = grooveOpeningY).
                                            float t_face = (grooveOpeningY - trRayOrigin.y) / trRayDir.y;
                                            float physZ_face = trRayOrigin.z + trRayDir.z * t_face;
                                            float apertureSDF = RoundedRectSDF(float2(trAcross, physZ_face), trackHalfExtCanon, trackCornerRCanon);
                                            float apertureAA = fwidth(apertureSDF) * 0.75;
                                            bgOccFactor = smoothstep(apertureAA, -apertureAA, apertureSDF);
                                        }
                                        else
                                        {
                                            bgOccFactor = 0.0; // horizontal/upward ray cannot see groove through aperture
                                        }
                                    }

                                    float3 trackLitColor = ApplyUILighting(lightNormal, trackSurfaceColor,
                                        _LightingAmbient, trackSpecMod, trackNormOff, light1, light2, light3);

                                    buttonCompositeOver(finalColor, trackLitColor, outerMask * trackFinalAlpha * bgOccFactor);
                                    emissiveAccum += trackFinalEmissiveBase * outerMask * trackFinalEmissive * bgOccFactor;
                                }
                            }
                        }

                    }
                    else
                    {
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
                        // Apply view tilt rotation to track normal (shared perspective with handle)
                        {
                            float3 ta = float3(tiltDir.x, tiltDir.y, 0.0);
                            float kd = dot(ta, trackNormal);
                            float3 kc = cross(ta, trackNormal);
                            trackNormal = normalize(trackNormal * trackCosT + kc * trackSinT + ta * kd * (1.0 - trackCosT));
                        }

                        float3 trackLitColor = ApplyUILighting(trackNormal, trackPatternedColor,
                            _LightingAmbient, 0.0, float2(0,0), light1, light2, light3);

                        buttonCompositeOver(finalColor, trackLitColor, trackMask * _TrackRenderAlpha);
                        emissiveAccum += trackBaseColor * trackMask * _TrackRenderEmissive;
                    }
                }

                // ============================================================
                // 4b. Track Value geometry (RM) — raised/lowered strip in the
                //     padding-inset value channel, marched with the same code as
                //     the track. Composited over the track, under the handle.
                // ============================================================
                if (trackRmEnabled && _TrackValueBevelEnabled > 0.5
                    && abs(_TrackValueBevelDepth) > 0.0001 && trackValuePseudoHeight > 0.0001)
                {
                    bool valFilledOn   = (_TrackValueFilledEnabled > 0.5) || (_TrackValueNegativeEnabled > 0.5);
                    bool valUnfilledOn = (_TrackValueUnfilledEnabled > 0.5);
                    if (valFilledOn || valUnfilledOn)
                    {
                        // Along-track footprint: filled segment only, unless Unfilled is
                        // enabled (then the whole channel is one continuous strip).
                        // _TrackValuePadding insets the strip from the track ENDS too (matching
                        // the top/bottom inset), so the value never runs flush to the track caps.
                        float valPadEnd = _TrackValuePadding;
                        float chanMin = -trackAxisHalf + valPadEnd;
                        float chanMax =  trackAxisHalf - valPadEnd;
                        float valMin, valMax;
                        if (valUnfilledOn) { valMin = chanMin; valMax = chanMax; }
                        else { valMin = max(fillMinCanon, chanMin); valMax = min(fillMaxCanon, chanMax); }
                        float valCenter  = 0.5 * (valMin + valMax);
                        float valHalfLen = max(0.001, 0.5 * (valMax - valMin));
                        float2 valHalfExt = float2(valHalfLen, trackValueWidth);
                        float  valCornerR = _TrackCornerRadius * min(valHalfExt.x, valHalfExt.y);
                        float2 valCanonOff = float2(valCenter * tiltNormDirCanon.x,
                                                   -valCenter * tiltDirCanon.x);

                        // Value base sits on the padding-inset track surface:
                        //   raised track → track face (bgFace + trackPseudoHeight)
                        //   groove track → groove floor (bgFace - trackPseudoHeight)
                        float bgFaceLevelV = bgRmEnabled ? bgBevelHeightAuto : 0.0;
                        float trBvSignV    = (_TrackBevelDepth >= 0.0) ? 1.0 : -1.0;
                        float valBaseLevel = bgFaceLevelV + trBvSignV * trackPseudoHeight + _TrackViewElevation;
                        float valBvSign    = (_TrackValueBevelDepth >= 0.0) ? 1.0 : -1.0;
                        float valHeight    = max(0.001, trackValuePseudoHeight);
                        float valBevelDist = max(0.001, _TrackValueBevelDistance);
                        // Prism base: positive raises from the base level up; negative carves down.
                        float valElevation = valBaseLevel + min(0.0, valBvSign) * valHeight;

                        float3 vP, vRayDir, vRayOrigin; float vBaseSDF; int vSurface;
                        bool vHit = marchTrackPrism(trackLocalP, valCanonOff, valHalfExt, valCornerR,
                            valElevation, valHeight, valBevelDist, _TrackValueBevelSmoothness, valBvSign,
                            trackCosT, trackSinT, tiltDirCanon, tiltNormDirCanon, trackViewShiftCamera,
                            trackMaxDim, vP, vBaseSDF, vSurface, vRayDir, vRayOrigin);

                        if (vHit)
                        {
                            // Along/cross-track hit coords (same recovery as the track block).
                            float vAlongHit   = vP.y * trackSinT - vP.z * trackCosT;
                            float vAxisHit    = vP.x * tiltNormDirCanon.x + vAlongHit * tiltDirCanon.x;
                            float vCrossSigned = vP.x * tiltNormDirCanon.y + vAlongHit * tiltDirCanon.y;
                            bool  vInFill = (vAxisHit >= fillMinCanon && vAxisHit <= fillMaxCanon);

                            // Surface-space UV so the value gradients foreshorten with the strip.
                            float2 vFillUV = saturate(float2(
                                vAxisHit     / max(0.0001, 2.0 * trackAxisHalf)   + 0.5,
                                vCrossSigned / max(0.0001, 2.0 * trackValueWidth) + 0.5));

                            // ---- Per-segment color ----
                            float3 vCol; float vAlpha; float vEmiss;
                            bool useNeg = (handleAxisPos < fillOrigin) && (_TrackValueNegativeEnabled > 0.5);
                            if (vInFill && useNeg)
                            {
                                vCol = _TrackValueNegativeColor.rgb; vAlpha = _TrackValueNegativeRenderAlpha; vEmiss = _TrackValueNegativeRenderEmissive;
                                if (_TrackValueNegativeGradientEnabled > 0.5)
                                { float4 gc = CalculateGradient(vFillUV, _TrackValueNegativeGradientColorA, _TrackValueNegativeGradientColorB, _TrackValueNegativeGradientColorC, _TrackValueNegativeGradientColorD, _TrackValueNegativeGradientDirection, _TrackValueNegativeGradientType, _TrackValueNegativeGradientSpeed, _TrackValueNegativeGradientScale, _TrackValueNegativeGradientOffset, time, _TrackValueNegativeGradientColorUsed); vCol = lerp(vCol, gc.rgb, gc.a); }
                            }
                            else if (vInFill)
                            {
                                vCol = _TrackValueFilledColor.rgb; vAlpha = _TrackValueFilledRenderAlpha; vEmiss = _TrackValueFilledRenderEmissive;
                                if (_TrackValueFilledGradientEnabled > 0.5)
                                { float4 gc = CalculateGradient(vFillUV, _TrackValueFilledGradientColorA, _TrackValueFilledGradientColorB, _TrackValueFilledGradientColorC, _TrackValueFilledGradientColorD, _TrackValueFilledGradientDirection, _TrackValueFilledGradientType, _TrackValueFilledGradientSpeed, _TrackValueFilledGradientScale, _TrackValueFilledGradientOffset, time, _TrackValueFilledGradientColorUsed); vCol = lerp(vCol, gc.rgb, gc.a); }
                            }
                            else
                            {
                                vCol = _TrackValueUnfilledColor.rgb; vAlpha = _TrackValueUnfilledRenderAlpha; vEmiss = _TrackValueUnfilledRenderEmissive;
                                if (_TrackValueUnfilledGradientEnabled > 0.5)
                                { float4 gc = CalculateGradient(vFillUV, _TrackValueUnfilledGradientColorA, _TrackValueUnfilledGradientColorB, _TrackValueUnfilledGradientColorC, _TrackValueUnfilledGradientColorD, _TrackValueUnfilledGradientDirection, _TrackValueUnfilledGradientType, _TrackValueUnfilledGradientSpeed, _TrackValueUnfilledGradientScale, _TrackValueUnfilledGradientOffset, time, _TrackValueUnfilledGradientColorUsed); vCol = lerp(vCol, gc.rgb, gc.a); }
                            }

                            // ---- Surface normal (baseSDF gradient → bevel wall, flat face) ----
                            float eps2dv = max(0.0005, trackMaxDim * 0.004);
                            float bdx = RoundedRectSDF(vP.xz - valCanonOff + float2(eps2dv, 0), valHalfExt, valCornerR);
                            float bdz = RoundedRectSDF(vP.xz - valCanonOff + float2(0, eps2dv), valHalfExt, valCornerR);
                            float2 vGrad = float2(bdx - vBaseSDF, bdz - vBaseSDF);
                            float  vGLen = length(vGrad);
                            float2 vGradN = (vGLen > 0.0001) ? (vGrad / vGLen) : float2(1, 0);

                            float3 vNormal;
                            if (vSurface == SURFACE_FACE)
                                vNormal = float3(0, 1, 0);
                            else
                            {
                                float ang = atan2(valHeight, max(0.0001, valBevelDist));
                                float sB = sin(ang), cB = cos(ang);
                                float wf = (valBvSign < 0.0) ? -1.0 : 1.0;
                                vNormal = normalize(float3(vGradN.x * sB * wf, cB, vGradN.y * sB * wf));
                            }
                            float3 vScreenN  = normalToScreenSpace(vNormal, trackSinT, trackCosT);
                            float2 vScreenN2 = vScreenN.x * tiltNormDir + vScreenN.y * tiltDir;
                            float3 vLightN   = normalize(float3(-vScreenN2, max(0.0, vScreenN.z)));

                            // ---- Silhouette mask (face trimmed to inset footprint; wall solid) ----
                            float vOuterMask;
                            if (vSurface == SURFACE_FACE)
                            {
                                float2 vFaceHE = max(float2(0.001, 0.001), valHalfExt - valBevelDist);
                                float  vFaceCR = max(0.0, valCornerR - valBevelDist);
                                float  vFaceSDF = RoundedRectSDF(vP.xz - valCanonOff, vFaceHE, vFaceCR);
                                float  vAA = fwidth(vFaceSDF) * 0.75;
                                vOuterMask = smoothstep(vAA, -vAA, vFaceSDF);
                            }
                            else vOuterMask = 1.0;

                            // ---- Groove-value aperture occlusion (negative value only) ----
                            float vOcc = 1.0;
                            if (valBvSign < 0.0)
                            {
                                if (vRayDir.y < -0.0001)
                                {
                                    float valOpeningY = valElevation + valHeight; // = valBaseLevel
                                    float tface = (valOpeningY - vRayOrigin.y) / vRayDir.y;
                                    float physX = vRayOrigin.x + vRayDir.x * tface;
                                    float physZ = vRayOrigin.z + vRayDir.z * tface;
                                    float apSDF = RoundedRectSDF(float2(physX, physZ) - valCanonOff, valHalfExt, valCornerR);
                                    float apAA  = fwidth(apSDF) * 0.75;
                                    vOcc = smoothstep(apAA, -apAA, apSDF);
                                }
                                else vOcc = 0.0;
                            }

                            // ---- Depth sort vs the track (mutual occlusion) ----
                            // The track was composited first, so the value already occludes the
                            // track where it is in front (paint order). The missing direction is
                            // the track occluding the value (e.g. the near groove wall standing in
                            // front of a recessed value). Both hits lie on the same view ray, so
                            // the smaller projection onto rayDir is nearer the camera. Suppress the
                            // value where the track surface is closer.
                            float vDepthMask = 1.0;
                            if (trackHitValid)
                            {
                                float dProjTrack = dot(trackHitP, vRayDir);
                                float dProjVal   = dot(vP,        vRayDir);
                                float diff = dProjVal - dProjTrack; // > 0 ⇒ track is in front of value
                                float aa   = max(1e-4, trackMaxDim * 0.003);
                                vDepthMask = smoothstep(aa, -aa, diff);
                            }

                            float3 vLit = ApplyUILighting(vLightN, vCol, _LightingAmbient, 0.0, float2(0, 0), light1, light2, light3);
                            buttonCompositeOver(finalColor, vLit, vOuterMask * vAlpha * vOcc * vDepthMask);
                            emissiveAccum += vCol * vOuterMask * vEmiss * vOcc * vDepthMask;
                        }
                    }
                }

                // ============================================================
                // 5. ValueUnfilled (track segment: handle → max end)
                // ============================================================
                if (!trackRmEnabled && _TrackValueUnfilledEnabled > 0.5 && unfilledMask > 0.001)
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
                    float3 vufLitColor = ApplyUILighting(fillNormal, vufColor,
                        _LightingAmbient, 0.0, float2(0,0), light1, light2, light3);
                    buttonCompositeOver(finalColor, vufLitColor, unfilledMask * _TrackValueUnfilledRenderAlpha);
                    emissiveAccum += vufColor * unfilledMask * _TrackValueUnfilledRenderEmissive;
                }

                // ============================================================
                // 6. ValueFilled (handle >= zero point) / ValueNegFilled (handle < zero point)
                // ============================================================
                if (!trackRmEnabled && filledMask > 0.001)
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
                        float3 vfLitColor = ApplyUILighting(fillNormal, vfColor,
                            _LightingAmbient, 0.0, float2(0,0), light1, light2, light3);
                        buttonCompositeOver(finalColor, vfLitColor, filledMask * _TrackValueFilledRenderAlpha);
                        emissiveAccum += vfColor * filledMask * _TrackValueFilledRenderEmissive;
                    }
                    else if (handleAxisPos < fillOrigin)
                    {
                        if (_TrackValueNegativeEnabled > 0.5)
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
                            float3 vnfLitColor = ApplyUILighting(fillNormal, vnfColor,
                                _LightingAmbient, 0.0, float2(0,0), light1, light2, light3);
                            buttonCompositeOver(finalColor, vnfLitColor, filledMask * _TrackValueNegativeRenderAlpha);
                            emissiveAccum += vnfColor * filledMask * _TrackValueNegativeRenderEmissive;
                        }
                        else if (_TrackValueFilledEnabled > 0.5)
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
                            float3 vfLitColor = ApplyUILighting(fillNormal, vfColor,
                                _LightingAmbient, 0.0, float2(0,0), light1, light2, light3);
                            buttonCompositeOver(finalColor, vfLitColor, filledMask * _TrackValueFilledRenderAlpha);
                            emissiveAccum += vfColor * filledMask * _TrackValueFilledRenderEmissive;
                        }
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

                        float2 markRelPos = trackPosView - markCenter;
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
                // 9. Handle body — 3D raymarched extrusion (SDFSliderRM only)
                // ============================================================
                if (_HandleEnabled > 0.5)
                {
                    // No 2D silhouette pre-gate — the bounding sphere test below is the early-out.
                    // A tight 2D gate would clip the RM bevel walls that extend beyond the shape outline.

                    // ---- View tilt params (tiltDir, tiltNormDir, cosT, sinT, viewShiftEffective, etc.)
                    //      are computed before section 1 so the track + fills can share them. ----

                        // ---- Geometry params (from RM handle bevel block above) ----
                        float bevelDist    = handleBevelDist;
                        float bevelHeight  = handleBevelHeight;
                        float lipHeight    = handleLipHeight;
                        float rimWidth     = handleRimWidth;
                        float faceInset    = handleFaceInset;
                        float totalHeight  = handleTotalHeight;
                        // Handle sits atop the fill face, which sits atop the track face.
                        // All contributions are signed: positive = above, negative = below.
                        float hBgFL         = bgRmEnabled ? bgBevelHeightAuto : 0.0;
                        float hTrackBvSign  = (_TrackBevelDepth >= 0.0) ? 1.0 : -1.0;
                        // Mirror trackElevation formula: elevation = bgFace + min(0,sign)*h
                        //   track face = elevation + h
                        //   positive: face = bgFace + h (raised above bg)  
                        //   negative: face = bgFace - h + h = bgFace (flush, groove opening)
                        float hTrackFaceL   = trackRmEnabled
                            ? (hBgFL + min(0.0, hTrackBvSign) * trackPseudoHeight) + _TrackViewElevation + trackPseudoHeight
                            : hBgFL;
                        float hTVBvSign     = (_TrackValueBevelEnabled > 0.5 && _TrackValueBevelDepth >= 0.0) ? 1.0 : -1.0;
                        float hFillFaceL    = hTrackFaceL + (_TrackValueBevelEnabled > 0.5 ? hTVBvSign * trackValuePseudoHeight : 0.0);
                        // Clamp to all relevant faces: handle bottom never goes below bg, track, or value face.
                        float handleFloor = max(hBgFL, max(hTrackFaceL, hFillFaceL));
                        float handleElevation = handleFloor + _HandleViewElevation;
                        // Diagonal of the rect handle + bevel is the true XZ extent; sinT term widens
                        // the sphere as the screen-along direction projects into world-Y under tilt.
                        float handleDiag   = length(float2(_HandleWidth, _HandleHeight)) + bevelDist;

                        // ---- Ray setup in handle-local space ----
                        // handleLocalP is already handle-centred in canonical horizontal orientation
                        // (same relationship as SDFKnobRM's pos to the knob centre).
                        // Use trackLocalP (quad-centred) so handle tilts around the background centre,
                        // same pivot as the track and background RM sections.
                        float screenAcross = dot(trackLocalP, tiltNormDirCanon);
                        float screenAlong  = dot(trackLocalP, tiltDirCanon);
                        // Canonical XZ offset of the handle centre in global extrusion space.
                        // In canonical space the handle is always at (handleAxisPos, 0) so:
                        //   p.x_handle = handleAxisPos * tiltNormDirCanon.x
                        //   p.z_handle = -handleAxisPos * tiltDirCanon.x
                        float2 handleCanonOff = float2(
                            handleAxisPos * tiltNormDirCanon.x,
                           -handleAxisPos * tiltDirCanon.x);
                        float boundRadius  = handleDiag * (1.2 + sinT) + totalHeight;
                        float startDist    = boundRadius + handleDiag * 0.5;
                        float3 handlePlanePoint = float3(screenAcross,
                            screenAlong * sinT,
                            -screenAlong * cosT);

                        float3 rayDir;
                        float3 rayOrigin;
                        if (_ViewFOV > 0.001)
                        {
                            float focalDist = 1.0 / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                            float3 camPos   = float3(viewShiftEffective, focalDist * cosT, focalDist * sinT);
                            rayDir          = normalize(handlePlanePoint - camPos);
                            rayOrigin       = handlePlanePoint - rayDir * startDist;
                        }
                        else
                        {
                            float3 orthoDir = float3(0.0, -cosT, -sinT);
                            rayDir    = orthoDir;
                            rayOrigin = float3(
                                screenAcross,
                                screenAlong * sinT + startDist * cosT,
                                -screenAlong * cosT + startDist * sinT
                            );
                        }
                        // No value-driven rotation — slider handle does not rotate with _Value

                        // ---- Bounding sphere test ----
                        float3 boundCenter = float3(handleCanonOff.x, handleElevation + totalHeight * 0.5, handleCanonOff.y);
                        float3 oc     = rayOrigin - boundCenter;
                        float bCoeff  = dot(oc, rayDir);
                        float cCoeff  = dot(oc, oc) - boundRadius * boundRadius;
                        float disc    = bCoeff * bCoeff - cCoeff;

                        if (disc >= 0.0)
                        {
                            float tStart = max(0.0, -bCoeff - sqrt(disc));
                            float tEnd   = -bCoeff + sqrt(disc);

                            if (tEnd > 0.0)
                            {
                                ExtrusionParams extParams;
                                extParams.knobRadius   = handleMinDim;
                                extParams.lipHeight    = lipHeight;
                                extParams.rimWidth     = rimWidth;
                                extParams.bevelHeight  = bevelHeight;
                                extParams.bevelDist    = bevelDist;
                                extParams.totalHeight  = totalHeight;
                                extParams.hasFaceShape = (_HandleFaceShapeEnabled > 0.5) ? 1 : 0;
                                extParams.filletRadius = bevelHeight * _HandleBevelSmoothness * 0.4;

                                // ---- Sphere-march ----
                                // Conservative step factor: the bevel-body SDF has gradient
                                // magnitude sqrt(1+(bevelDist/bevelHeight)^2) > 1, so the raw SDF
                                // OVERESTIMATES the true distance. Stepping by the unscaled value
                                // lets the ray tunnel straight through the thin slanted wall at
                                // grazing view tilt, and the wall vanishes. Scaling by cosB
                                // (= 1/gradMag) keeps every step shorter than the true distance.
                                // Clamped so very shallow bevels don't starve the iteration budget;
                                // the closest-approach fallback below covers any residual overshoot.
                                float handleBevelCosB = max(0.2, bevelHeight * rsqrt(
                                    bevelHeight * bevelHeight + bevelDist * bevelDist));

                                float t = tStart;
                                float3 p = rayOrigin + t * rayDir;
                                float marchEps   = handleMinDim * 0.001;
                                float hitBaseSDF = 0.0;
                                bool  hitFound   = false;
                                // Closest-approach fallback — near-tangent rays at steep tilt can
                                // exhaust the loop while crawling along the wall. Snapping to the
                                // nearest sampled surface point keeps the wall from disappearing;
                                // the outerMask AA below trims the true silhouette.
                                float  closestD    = 1e9;
                                float3 closestP    = p;
                                float  closestBase = 0.0;

                                UNITY_LOOP for (int i = 0; i < 96; i++)
                                {
                                    float2 pHandle_m = p.xz - handleCanonOff;
                                    float baseSDF_m = evalHandleSDF(pHandle_m);
                                    float faceSDF_m = computeHandleFaceSDF(pHandle_m, baseSDF_m, faceInset, bevelDist);
                                    float d = sdfExtrusion3D(float3(p.x, p.y - handleElevation, p.z), baseSDF_m, faceSDF_m, extParams);
                                    if (d < marchEps) {
                                        hitFound   = true;
                                        hitBaseSDF = baseSDF_m;
                                        break;
                                    }
                                    if (d > 0.0 && d < closestD) { closestD = d; closestP = p; closestBase = baseSDF_m; }
                                    if (t > tEnd) break;
                                    t += max(d * handleBevelCosB, marchEps * 0.5);
                                    p  = rayOrigin + t * rayDir;
                                }
                                if (!hitFound && closestD < marchEps * 30.0)
                                {
                                    hitFound   = true;
                                    p          = closestP;
                                    hitBaseSDF = closestBase;
                                }

                                if (hitFound)
                                {
                                    float2 pHandle = p.xz - handleCanonOff;
                                    float y          = p.y - handleElevation;
                                    float surfaceEps = handleMinDim * 0.005;
                                    float lipEps     = max(surfaceEps, marchEps * 4.0);

                                    // Surface classification
                                    int hitSurface = SURFACE_WALL;
                                    if (y >= totalHeight - surfaceEps) {
                                        hitSurface = SURFACE_FACE;
                                    } else if (y <= lipHeight + lipEps) {
                                        hitSurface = (y < lipHeight - lipEps) ? SURFACE_LIP : SURFACE_RIM;
                                    }
                                    float surfaceTint = (hitSurface == SURFACE_WALL) ? 0.9 :
                                                        (hitSurface == SURFACE_RIM)  ? 1.0 :
                                                        (hitSurface == SURFACE_LIP)  ? 0.75 : 1.0;

                                    // ---- Analytical surface normals ----
                                    float2 wallGradN = float2(1, 0);
                                    float3 hitNormal;
                                    {
                                        float eps2d = max(0.0005, handleMinDim * 0.004);
                                        float bdx   = evalHandleSDF(pHandle + float2(eps2d, 0));
                                        float bdz   = evalHandleSDF(pHandle + float2(0, eps2d));
                                        float2 grad2D = float2(bdx - hitBaseSDF, bdz - hitBaseSDF);
                                        float  gLen   = length(grad2D);
                                        float2 gradN  = (gLen > 0.0001) ? (grad2D / gLen) : float2(1, 0);

                                        if (hitSurface == SURFACE_FACE || hitSurface == SURFACE_RIM) {
                                            hitNormal = float3(0, 1, 0);
                                        } else if (hitSurface == SURFACE_LIP) {
                                            hitNormal = normalize(float3(gradN.x, 0.6, gradN.y));
                                        } else {
                                            wallGradN = gradN;
                                            float bevelAngleRM = atan2(bevelHeight, max(0.0001, bevelDist));
                                            float sinB = sin(bevelAngleRM);
                                            float cosB = cos(bevelAngleRM);
                                            float3 wallNorm = normalize(float3(gradN.x * sinB, cosB, gradN.y * sinB));
                                            UNITY_BRANCH if (_HandleBevelSmoothness > 0.001)
                                            {
                                                float filletR = bevelHeight * _HandleBevelSmoothness * 0.4;
                                                float edgeT   = saturate((y - (totalHeight - filletR)) / max(filletR, 0.0001));
                                                hitNormal = normalize(lerp(wallNorm, float3(0, 1, 0), smoothstep(0.0, 1.0, edgeT)));
                                            }
                                            else
                                            {
                                                hitNormal = wallNorm;
                                            }
                                        }
                                    }

                                    // Face dome/bowl perturbation (SURFACE_FACE only)
                                    UNITY_BRANCH if (hitSurface == SURFACE_FACE && abs(_HandleFaceSmoothness) > 0.001)
                                    {
                                        float2 xz = pHandle;
                                        float r = length(xz);
                                        float faceRefRadius = max(0.001, handleMinDim - faceInset);
                                        float radialT = saturate(r / faceRefRadius);
                                        float2 radialDir2D = (r > 0.0001) ? (xz / r) : float2(0, 0);
                                        float domeStrength = _HandleFaceSmoothness * radialT;
                                        float3 domeDir = float3(radialDir2D.x * domeStrength, 0, radialDir2D.y * domeStrength);
                                        hitNormal = normalize(hitNormal + domeDir);
                                    }

                                    // Map normal to screen space
                                    float3 screenNormal3D = normalToScreenSpace(hitNormal, sinT, cosT);
                                    float2 screenNorm2D   = screenNormal3D.x * tiltNormDir + screenNormal3D.y * tiltDir;
                                    float3 lightNormal    = normalize(float3(-screenNorm2D, max(0.0, screenNormal3D.z)));

                                    // ---- Silhouette AA ----
                                    float outerAA = fwidth(hitBaseSDF) * 0.75;
                                    float outerMask;
                                    if (hitSurface == SURFACE_FACE && _HandleFaceShapeEnabled > 0.5)
                                    {
                                        float faceMarginRM = (1.0 - saturate(_HandleFaceSize)) * handleMinDim;
                                        float faceHalfW_rm = max(0.001, _HandleWidth  - faceMarginRM);
                                        float faceHalfH_rm = max(0.001, _HandleHeight - faceMarginRM);
                                        float2 fpRot = (abs(_HandleFaceShapeRotation) > 0.001)
                                            ? rotate2D(pHandle, _HandleFaceShapeRotation * (PI / 180.0)) : pHandle;
                                        float faceShapeDist = getHandleSDF(fpRot, faceHalfW_rm, faceHalfH_rm,
                                            (int)_HandleFaceShapeType,
                                            _HandleFaceShapeParam1, _HandleFaceShapeParam2, _HandleFaceShapeParam3);
                                        float faceAA2 = fwidth(faceShapeDist) * 0.75;
                                        outerMask = smoothstep(faceAA2, -faceAA2, faceShapeDist);
                                    }
                                    else if (hitSurface == SURFACE_FACE)
                                    {
                                        outerMask = smoothstep(outerAA, -outerAA, hitBaseSDF);
                                    }
                                    else if (sinT < 0.05)
                                    {
                                        // UNTILTED WALL/RIM/LIP: AA the silhouette with the PIXEL's own
                                        // distance to the base contour (2026-09-14, the SDFButtonRM fix).
                                        // A wall hit sits ON the contour, so the hit's own SDF is ~0 and a
                                        // flat 1.0 left the handle's edge a crust of hit/miss pixels — the
                                        // speckled ring round Neomorphic Light's fader ball. Face-on, the
                                        // ortho ray's xz IS the pixel's base position, so this is exact.
                                        // Tilted handles keep 1.0: their silhouette is not the contour.
                                        float2 pixBase = float2(screenAcross, -screenAlong) - handleCanonOff;
                                        float  sdPix   = evalHandleSDF(pixBase);
                                        float  aaPix   = max(fwidth(sdPix), 1e-6) * 0.75;
                                        outerMask = smoothstep(aaPix, -aaPix, sdPix);
                                    }
                                    else
                                    {
                                        outerMask = 1.0;
                                    }

                                    // ---- Base color + gradient ----
                                    float3 handleBaseColor  = _HandleColor.rgb;
                                    float  handleSpecularMod = 1.0;
                                    float2 handleNormalOffset = float2(0, 0);
                                    // faceUV: per-axis stretch for gradients (fills shape edge-to-edge).
                                    // faceUVPattern: world-scale iso UV — same feature size as track/bg patterns.
                                    float2 faceUV = pHandle / float2(_HandleWidth * 2.0, _HandleHeight * 2.0) + 0.5;
                                    faceUV = saturate(faceUV);
                                    float2 faceUVPattern = pHandle * 0.5 + 0.5;
                                    faceUVPattern = saturate(faceUVPattern);

                                    UNITY_BRANCH if (_HandleGradientEnabled > 0.5)
                                    {
                                        float4 gc = CalculateGradient(faceUV,
                                            _HandleGradientColorA, _HandleGradientColorB,
                                            _HandleGradientColorC, _HandleGradientColorD,
                                            _HandleGradientDirection, _HandleGradientType,
                                            _HandleGradientSpeed, _HandleGradientScale,
                                            _HandleGradientOffset, time, _HandleGradientColorUsed);
                                        handleBaseColor = lerp(handleBaseColor, gc.rgb, gc.a);
                                    }
                                    if (_HandleGlobalBlend > 0.0)
                                    {
                                        float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                                        handleBaseColor = lerp(handleBaseColor, gc.rgb, _HandleGlobalBlend * _HandleGlobalIntensity);
                                    }

                                    float3 surfaceBaseColor = handleBaseColor * surfaceTint;

                                    // Face pattern (SURFACE_FACE only)
                                    UNITY_BRANCH if (hitSurface == SURFACE_FACE && _HandlePatternEnabled > 0.5)
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
                                        surfaceBaseColor = ApplyMaterialPattern(handleBaseColor, faceUVPattern, handleComp,
                                            0.0, 0.0, handleSpecularMod, handleNormalOffset);
                                    }

                                    // Wall bevel gradient (SURFACE_WALL only)
                                    UNITY_BRANCH if (hitSurface == SURFACE_WALL && _HandleBevelGradientEnabled > 0.5)
                                    {
                                        float4 gc = CalculateGradient(faceUV,
                                            _HandleBevelGradientColorA, _HandleBevelGradientColorB,
                                            _HandleBevelGradientColorC, _HandleBevelGradientColorD,
                                            _HandleBevelGradientDirection, _HandleBevelGradientType,
                                            _HandleBevelGradientSpeed, _HandleBevelGradientScale,
                                            _HandleBevelGradientOffset, time, _HandleBevelGradientColorUsed);
                                        surfaceBaseColor = gc.rgb;
                                    }

                                    // Wall bevel pattern (SURFACE_WALL only)
                                    UNITY_BRANCH if (hitSurface == SURFACE_WALL && _HandleBevelPatternEnabled > 0.5)
                                    {
                                        UIComponent bevelComp = CreateUIComponent(
                                            float4(1,1,1,1), 1.0,
                                            0.0, 0.0, 0.0, 0.0,
                                            float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                                            float2(1,0), 1.0, 1.0, 0.0, 0.0, 1.0, 0,
                                            _HandleBevelPatternType, _HandleBevelPatternScale,
                                            _HandleBevelPatternIntensity, _HandleBevelPatternContrast,
                                            _HandleBevelPatternSpecularEffect, _HandleBevelPatternRoughnessEffect,
                                            1.0, 0.0, 0.0, 1.0, 0.0,
                                            _HandleBevelPatternParam1, _HandleBevelPatternParam2, _HandleBevelPatternParam3,
                                            0.0, 1.0,
                                            _HandleBevelPatternColorEnabled, _HandleBevelPatternColorMode,
                                            _HandleBevelPatternColorType, _HandleBevelPatternColorUsed,
                                            _HandleBevelPatternColorA, _HandleBevelPatternColorB,
                                            _HandleBevelPatternColorC, _HandleBevelPatternColorD
                                        );
                                        surfaceBaseColor = ApplyMaterialPattern(surfaceBaseColor, faceUVPattern, bevelComp,
                                            0.0, 0.0, handleSpecularMod, handleNormalOffset);
                                    }

                                    // ---- Lighting ----
                                    float3 surfaceColor = ApplyUILighting(lightNormal, surfaceBaseColor,
                                        _LightingAmbient, handleSpecularMod, handleNormalOffset,
                                        light1, light2, light3);

                                    // ---- Self-shadow: bevel wall occludes rim/lip ----
                                    UNITY_BRANCH
                                    if ((hitSurface == SURFACE_RIM || hitSurface == SURFACE_LIP) && bevelHeight > 0.01)
                                    {
                                        float rl = length(pHandle);
                                        float2 outDir = (rl > 0.0001) ? (pHandle / rl) : float2(1, 0);
                                        float wallTanAngle = bevelHeight / max(0.001, bevelDist + rimWidth);

                                        #define HANDLE_SELF_SHADOW(lightEnabled, lightDir3, factor) \
                                        if (lightEnabled) { \
                                            float3 tl = UIToLightVector(lightDir3); \
                                            float2 ld = tl.xy; \
                                            float lacross = dot(ld, tiltNormDir); \
                                            float lalong  = dot(ld, tiltDir); \
                                            float lz = tl.z; \
                                            float3 lLocal = float3(lacross, \
                                                lalong * sinT + lz * cosT, \
                                                -lalong * cosT + lz * sinT); \
                                            float lHorizLen = length(lLocal.xz); \
                                            float2 lHoriz = (lHorizLen > 0.0001) ? (lLocal.xz / lHorizLen) : float2(0, 0); \
                                            float shadowSide = saturate(dot(outDir, lHoriz)); \
                                            float lightTan = lLocal.y / max(0.001, lHorizLen); \
                                            float occluded = saturate(1.0 - lightTan / max(0.001, wallTanAngle)); \
                                            factor = min(factor, 1.0 - shadowSide * occluded); \
                                        }

                                        float selfShadow = 1.0;
                                        HANDLE_SELF_SHADOW(light1.enabled, light1.direction, selfShadow)
                                        HANDLE_SELF_SHADOW(light2.enabled, light2.direction, selfShadow)
                                        HANDLE_SELF_SHADOW(light3.enabled, light3.direction, selfShadow)
                                        #undef HANDLE_SELF_SHADOW

                                        surfaceColor *= lerp(1.0, selfShadow, 0.85);
                                    }

                                    // ---- Composite ----
                                    buttonCompositeOver(finalColor, surfaceColor, outerMask * _HandleRenderAlpha);
                                    emissiveAccum += handleBaseColor * outerMask * _HandleRenderEmissive;
                                }
                            }
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
                    float borderBodyDist = getPanelBodySDF(bgPosView, bgHalfW, bgHalfH, bgShapeType,
                        _BgShapeParam1, _BgShapeParam2, _BgShapeParam3);
                    float borderAA = fwidth(borderBodyDist) * 0.75;
                    float innerEdge = smoothstep(-borderAA, borderAA, borderBodyDist);
                    float outerEdge = 1.0 - smoothstep(_BorderWidth, _BorderWidth + max(_BorderSoftness, borderAA), borderBodyDist);
                    float borderTerritory = innerEdge * outerEdge;
                    float borderMask = borderTerritory * _BorderIntensity;

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
                        buttonCompositeOver(finalColor, borderColor, occludedBorderMask * _BorderRenderAlpha);
                        emissiveAccum += borderColor * occludedBorderMask * _BorderRenderEmissive;
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
                // Receive shadows cast by every OTHER widget and panel.
                //
                // This slider's own contribution is not in the buffer at its own pixels — the
                // shadow pass punched its plate's silhouette out (see the punch-out in the
                // _ShadowPassMode block). So this is other people's shadows only.
                //
                // BEFORE the emissive add, deliberately: an emissive fill is its own light
                // source and is not shadowed by a neighbour standing next to it.
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
