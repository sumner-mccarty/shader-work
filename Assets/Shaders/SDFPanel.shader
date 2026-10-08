// ============================================================================
// SDFPanel.shader - 2D SDF UI Panel with Pure Function Architecture
// ============================================================================
// Panel is a rectangular SDF UI element — the body-face-bevel-rim material
// pipeline of SDFButton, extended with an InnerFrame nested shape and
// without an Icon component.
//
// COMPONENTS:
// 1. Panel      — Main panel shape (full material pipeline, 5 shape types)
// 2. Face       — Optional inner face shape (controls bevel wall width)
// 3. InnerFrame — Nested SDF shape on the panel face (full material pipeline)
// 4. Edge       — Recessed indent around the panel quad
// 5. Border     — Cut-in border at canvas edge
// 6. Shadows    — 3 external cast shadows + 3 panel body shadows
// ============================================================================

Shader "UI/SDFPanel"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _Value ("Value", Range(0,1)) = 0

        // ====================================================================
        // Panel (main panel shape)
        // ====================================================================
        _PanelEnabled ("Panel Enabled", Float) = 1
        _PanelColor ("Panel Color", Color) = (0.25, 0.25, 0.25, 1)
        _PanelRenderAlpha ("Panel Render Alpha", Range(0,1)) = 1
        _PanelRenderEmissive ("Panel Render Emissive", Range(0,1)) = 0

        // Panel shape
        [Enum(PanelBodyShapeType)] _PanelShapeType ("Panel Shape Type", Int) = 0
        _PanelShapeParam1 ("Panel Shape Param1", Range(0,1)) = 0.2
        _PanelShapeParam2 ("Panel Shape Param2", Range(0,1)) = 0.5
        _PanelShapeParam3 ("Panel Shape Param3", Range(0,1)) = 0.5
        _PanelShapeRotation ("Panel Shape Rotation", Range(-180,180)) = 0
        _PanelPadding ("Panel Padding", Range(0.0, 1.5)) = 0.15
        _PanelBodyRoundness ("Panel Roundness", Range(0,1)) = 0
        // Absolute corner radius in real pixels (Squircle only). 0 = use Param1 proportional
        // squareness. Needs _WidgetPixelSize, pushed per-instance by MaterialStateController.
        _PanelCornerRadiusPx ("Panel Corner Radius (px)", Float) = 0
        // Padding in the same CANVAS units (2026-09-13). 0 = use _PanelPadding, which is a fraction
        // of the half short side — so on a big plate the visible edge walks inward past whatever the
        // layout put near it (the PD-48 title and bank keys sat across Neomorphic's plate border).
        _PanelPaddingPx ("Panel Padding (px, 0 = use Padding)", Float) = 0
        _BorderWidthPx ("Border Width (px, 0 = use Border Width)", Float) = 0
        _EdgeWidthPx ("Edge Width (px, 0 = use Edge Width)", Float) = 0
        _EdgeCutInside ("Edge Outside Only (bloom)", Float) = 0
        _WidgetPixelSize ("Widget Pixel Size (set at runtime)", Vector) = (0, 0, 0, 0)
        _PanelBodyShapeTexLayer ("Panel Shape Tex Layer", Float) = -1
        _PanelBodyShapeTexScale ("Panel Shape Tex Scale", Vector) = (1, 1, 0, 0)

        // Panel bevel
        _PanelBevelEnabled ("Panel Bevel Enabled", Float) = 0
        _PanelBevelDepth ("Panel Bevel Depth", Range(-1.0, 1.0)) = 0.2
        _PanelBevelSmoothness ("Panel Bevel Smoothness", Range(0.001, 1.0)) = 0.02
        _PanelBevelDistance ("Panel Bevel Distance", Range(0.001, 1.0)) = 0.1
        _PanelFaceSmoothness ("Panel Face Smoothness", Range(-1.0, 1.0)) = 0.0
        _PanelBevelProfileType ("Panel Bevel Profile Type", Int) = 0
        _PanelBevelProfileSharpness ("Panel Bevel Profile Sharpness", Range(0, 1)) = 0.5

        // Panel bevel pattern
        _PanelBevelPatternEnabled ("Panel Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _PanelBevelPatternType ("Panel Bevel Pattern Type", Int) = 0
        _PanelBevelPatternScale ("Panel Bevel Pattern Scale", Range(1, 100)) = 20
        _PanelBevelPatternIntensity ("Panel Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _PanelBevelPatternContrast ("Panel Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _PanelBevelPatternSpecularEffect ("Panel Bevel Pattern Specular", Range(0, 2)) = 1.0
        _PanelBevelPatternRoughnessEffect ("Panel Bevel Pattern Roughness", Range(0, 2)) = 0.3
        _PanelBevelPatternParam1 ("Panel Bevel Pattern Detail", Range(0, 1)) = 0.5
        _PanelBevelPatternParam2 ("Panel Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _PanelBevelPatternParam3 ("Panel Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Panel bevel pattern color
        _PanelBevelPatternColorEnabled ("Panel Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _PanelBevelPatternColorType ("Panel Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _PanelBevelPatternColorMode ("Panel Bevel Pattern Color Mode", Int) = 1
        [IntRange] _PanelBevelPatternColorUsed ("Panel Bevel Pattern Color Used", Range(2, 4)) = 2
        _PanelBevelPatternColorA ("Panel Bevel Pattern Color A", Color) = (1,1,1,1)
        _PanelBevelPatternColorB ("Panel Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _PanelBevelPatternColorC ("Panel Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _PanelBevelPatternColorD ("Panel Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Panel bevel gradient
        _PanelBevelGradientEnabled ("Panel Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _PanelBevelGradientType ("Panel Bevel Gradient Type", Int) = 1
        _PanelBevelGradientColorA ("Panel Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _PanelBevelGradientColorB ("Panel Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _PanelBevelGradientColorC ("Panel Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _PanelBevelGradientColorD ("Panel Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _PanelBevelGradientDirection ("Panel Bevel Gradient Dir", Vector) = (1, 0, 0, 0)
        _PanelBevelGradientSpeed ("Panel Bevel Gradient Speed", Float) = 1.0
        _PanelBevelGradientScale ("Panel Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _PanelBevelGradientOffset ("Panel Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _PanelBevelGradientColorUsed ("Panel Bevel Gradient Color Used", Range(2, 4)) = 4

        // Panel rim bevel
        _PanelRimEnabled ("Panel Rim Bevel Enabled", Float) = 0
        _PanelRimDepth ("Panel Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _PanelRimWidth ("Panel Rim Bevel Width", Range(0.001, 1.0)) = 0.02
        _PanelRimSmoothness ("Panel Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01

        // Panel pattern
        _PanelPatternEnabled ("Panel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _PanelPatternType ("Panel Pattern Type", Int) = 0
        _PanelPatternScale ("Panel Pattern Scale", Range(1, 100)) = 20
        _PanelPatternIntensity ("Panel Pattern Intensity", Range(0, 1)) = 0.3
        // Pixel-locked grain (2026-10-04): CANVAS units one pattern tile spans, so the scale counts
        // cycles per that many units instead of per widget. A brushed plate then keeps the same grain
        // at 60 or 1200 units wide. 0 = legacy widget-relative UV (grain stretches with the panel).
        // Applies to every pattern this shader samples (face, bevel, inner frame + its bevel).
        _PanelPatternPx ("Panel Pattern Tile (px, 0 = per-widget UV)", Float) = 0
        _PanelPatternContrast ("Panel Pattern Contrast", Range(0.1, 5)) = 1.5
        _PanelPatternSpecularEffect ("Panel Pattern Specular", Range(0, 2)) = 1.0
        _PanelPatternRoughnessEffect ("Panel Pattern Roughness", Range(0, 2)) = 0.3
        _PanelPatternRotateEnabled ("Panel Pattern Rotate Enabled", Float) = 0
        _PanelPatternModEnabled ("Panel Pattern Mod Enabled", Float) = 0
        _PanelPatternModAmount ("Panel Pattern Mod Amount", Range(0, 90)) = 20
        _PanelPatternModFrequency ("Panel Pattern Mod Frequency", Range(0.1, 10)) = 1
        _PanelPatternOffset ("Panel Pattern Offset", Range(-180, 180)) = 0
        _PanelPatternParam1 ("Panel Pattern Detail", Range(0, 1)) = 0.5
        _PanelPatternParam2 ("Panel Pattern Distortion", Range(0, 1)) = 0.5
        _PanelPatternParam3 ("Panel Pattern Blend", Range(0, 1)) = 0.5

        // Panel pattern color
        _PanelPatternColorEnabled ("Panel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _PanelPatternColorType ("Panel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _PanelPatternColorMode ("Panel Pattern Color Mode", Int) = 1
        [IntRange] _PanelPatternColorUsed ("Panel Pattern Color Used", Range(2, 4)) = 2
        _PanelPatternColorA ("Panel Pattern Color A", Color) = (1,1,1,1)
        _PanelPatternColorB ("Panel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _PanelPatternColorC ("Panel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _PanelPatternColorD ("Panel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Panel gradient
        _PanelGradientEnabled ("Panel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _PanelGradientType ("Panel Gradient Type", Int) = 0
        _PanelGradientColorA ("Panel Gradient Color A", Color) = (1, 0, 0, 1)
        _PanelGradientColorB ("Panel Gradient Color B", Color) = (0, 1, 0, 1)
        _PanelGradientColorC ("Panel Gradient Color C", Color) = (0, 0, 1, 1)
        _PanelGradientColorD ("Panel Gradient Color D", Color) = (1, 1, 0, 1)
        _PanelGradientDirection ("Panel Gradient Direction", Vector) = (1, 0, 0, 0)
        _PanelGradientSpeed ("Panel Gradient Speed", Float) = 1.0
        _PanelGradientScale ("Panel Gradient Scale", Range(0.1, 5)) = 1.0
        _PanelGradientOffset ("Panel Gradient Offset", Range(-2, 2)) = 0.0
        _PanelGlobalBlend ("Panel Global Blend", Range(0, 1)) = 0.0
        _PanelGlobalIntensity ("Panel Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _PanelGradientColorUsed ("Panel Gradient Color Used", Range(2, 4)) = 4

        // Panel face (inner face: controls bevel/rim wall width; optional custom shape)
        _PanelFaceEnabled ("Panel Face Enabled", Float) = 1
        _PanelFaceShapeEnabled ("Panel Face Shape Enabled", Float) = 0
        [Enum(PanelBodyShapeType)] _PanelFaceShapeType ("Panel Face Shape Type", Int) = 0
        _PanelFaceShapeParam1 ("Panel Face Shape Param1", Range(0,1)) = 0.2
        _PanelFaceShapeParam2 ("Panel Face Shape Param2", Range(0,1)) = 0.5
        _PanelFaceShapeParam3 ("Panel Face Shape Param3", Range(0,1)) = 0.5
        _PanelFaceShapeRotation ("Panel Face Shape Rotation", Range(-180,180)) = 0
        _PanelFaceSize ("Panel Face Size", Range(0.01, 1.0)) = 0.85
        _PanelFaceShapeTexLayer ("Panel Face Shape Tex Layer", Float) = -1
        _PanelFaceShapeTexScale ("Panel Face Shape Tex Scale", Vector) = (1, 1, 0, 0)

        // ====================================================================
        // InnerFrame (nested shape on panel face)
        // ====================================================================
        _InnerFrameEnabled ("InnerFrame Enabled", Float) = 0
        _InnerFrameColor ("InnerFrame Color", Color) = (0.15, 0.15, 0.15, 1)
        _InnerFrameRenderAlpha ("InnerFrame Render Alpha", Range(0,1)) = 1
        _InnerFrameRenderEmissive ("InnerFrame Render Emissive", Range(0,1)) = 0

        // InnerFrame shape
        _InnerFrameShapeEnabled ("InnerFrame Shape Enabled", Float) = 0
        [Enum(PanelBodyShapeType)] _InnerFrameShapeType ("InnerFrame Shape Type", Int) = 0
        _InnerFrameShapeParam1 ("InnerFrame Shape Param1", Range(0,1)) = 0.2
        _InnerFrameShapeParam2 ("InnerFrame Shape Param2", Range(0,1)) = 0.5
        _InnerFrameShapeParam3 ("InnerFrame Shape Param3", Range(0,1)) = 0.5
        _InnerFrameShapeRotation ("InnerFrame Shape Rotation", Range(-180,180)) = 0
        _InnerFrameSize ("InnerFrame Size", Range(0.01, 1.0)) = 0.75
        _InnerFrameShapeTexLayer ("InnerFrame Shape Tex Layer", Float) = -1
        _InnerFrameShapeTexScale ("InnerFrame Shape Tex Scale", Vector) = (1, 1, 0, 0)

        // InnerFrame bevel
        _InnerFrameBevelEnabled ("InnerFrame Bevel Enabled", Float) = 0
        _InnerFrameBevelDepth ("InnerFrame Bevel Depth", Range(-1.0, 1.0)) = 0.2
        _InnerFrameBevelSmoothness ("InnerFrame Bevel Smoothness", Range(0.001, 1.0)) = 0.02
        _InnerFrameBevelDistance ("InnerFrame Bevel Distance", Range(0.001, 1.0)) = 0.1
        _InnerFrameFaceSmoothness ("InnerFrame Face Smoothness", Range(-1.0, 1.0)) = 0.0
        _InnerFrameBevelProfileType ("InnerFrame Bevel Profile Type", Int) = 0
        _InnerFrameBevelProfileSharpness ("InnerFrame Bevel Profile Sharpness", Range(0, 1)) = 0.5

        // InnerFrame bevel pattern
        _InnerFrameBevelPatternEnabled ("InnerFrame Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _InnerFrameBevelPatternType ("InnerFrame Bevel Pattern Type", Int) = 0
        _InnerFrameBevelPatternScale ("InnerFrame Bevel Pattern Scale", Range(1, 100)) = 20
        _InnerFrameBevelPatternIntensity ("InnerFrame Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _InnerFrameBevelPatternContrast ("InnerFrame Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _InnerFrameBevelPatternSpecularEffect ("InnerFrame Bevel Pattern Specular", Range(0, 2)) = 1.0
        _InnerFrameBevelPatternRoughnessEffect ("InnerFrame Bevel Pattern Roughness", Range(0, 2)) = 0.3
        _InnerFrameBevelPatternParam1 ("InnerFrame Bevel Pattern Detail", Range(0, 1)) = 0.5
        _InnerFrameBevelPatternParam2 ("InnerFrame Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _InnerFrameBevelPatternParam3 ("InnerFrame Bevel Pattern Blend", Range(0, 1)) = 0.5

        // InnerFrame bevel pattern color
        _InnerFrameBevelPatternColorEnabled ("InnerFrame Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _InnerFrameBevelPatternColorType ("InnerFrame Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _InnerFrameBevelPatternColorMode ("InnerFrame Bevel Pattern Color Mode", Int) = 1
        [IntRange] _InnerFrameBevelPatternColorUsed ("InnerFrame Bevel Pattern Color Used", Range(2, 4)) = 2
        _InnerFrameBevelPatternColorA ("InnerFrame Bevel Pattern Color A", Color) = (1,1,1,1)
        _InnerFrameBevelPatternColorB ("InnerFrame Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _InnerFrameBevelPatternColorC ("InnerFrame Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _InnerFrameBevelPatternColorD ("InnerFrame Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // InnerFrame bevel gradient
        _InnerFrameBevelGradientEnabled ("InnerFrame Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _InnerFrameBevelGradientType ("InnerFrame Bevel Gradient Type", Int) = 1
        _InnerFrameBevelGradientColorA ("InnerFrame Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _InnerFrameBevelGradientColorB ("InnerFrame Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _InnerFrameBevelGradientColorC ("InnerFrame Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _InnerFrameBevelGradientColorD ("InnerFrame Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _InnerFrameBevelGradientDirection ("InnerFrame Bevel Gradient Dir", Vector) = (1, 0, 0, 0)
        _InnerFrameBevelGradientSpeed ("InnerFrame Bevel Gradient Speed", Float) = 1.0
        _InnerFrameBevelGradientScale ("InnerFrame Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _InnerFrameBevelGradientOffset ("InnerFrame Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _InnerFrameBevelGradientColorUsed ("InnerFrame Bevel Gradient Color Used", Range(2, 4)) = 4

        // InnerFrame rim
        _InnerFrameRimEnabled ("InnerFrame Rim Bevel Enabled", Float) = 0
        _InnerFrameRimDepth ("InnerFrame Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _InnerFrameRimWidth ("InnerFrame Rim Bevel Width", Range(0.001, 1.0)) = 0.02
        _InnerFrameRimSmoothness ("InnerFrame Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01

        // InnerFrame pattern
        _InnerFramePatternEnabled ("InnerFrame Pattern Enabled", Float) = 0
        [Enum(PatternType)] _InnerFramePatternType ("InnerFrame Pattern Type", Int) = 0
        _InnerFramePatternScale ("InnerFrame Pattern Scale", Range(1, 100)) = 20
        _InnerFramePatternIntensity ("InnerFrame Pattern Intensity", Range(0, 1)) = 0.3
        _InnerFramePatternContrast ("InnerFrame Pattern Contrast", Range(0.1, 5)) = 1.5
        _InnerFramePatternSpecularEffect ("InnerFrame Pattern Specular", Range(0, 2)) = 1.0
        _InnerFramePatternRoughnessEffect ("InnerFrame Pattern Roughness", Range(0, 2)) = 0.3
        _InnerFramePatternRotateEnabled ("InnerFrame Pattern Rotate Enabled", Float) = 0
        _InnerFramePatternModEnabled ("InnerFrame Pattern Mod Enabled", Float) = 0
        _InnerFramePatternModAmount ("InnerFrame Pattern Mod Amount", Range(0, 90)) = 20
        _InnerFramePatternModFrequency ("InnerFrame Pattern Mod Frequency", Range(0.1, 10)) = 1
        _InnerFramePatternOffset ("InnerFrame Pattern Offset", Range(-180, 180)) = 0
        _InnerFramePatternParam1 ("InnerFrame Pattern Detail", Range(0, 1)) = 0.5
        _InnerFramePatternParam2 ("InnerFrame Pattern Distortion", Range(0, 1)) = 0.5
        _InnerFramePatternParam3 ("InnerFrame Pattern Blend", Range(0, 1)) = 0.5

        // InnerFrame pattern color
        _InnerFramePatternColorEnabled ("InnerFrame Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _InnerFramePatternColorType ("InnerFrame Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _InnerFramePatternColorMode ("InnerFrame Pattern Color Mode", Int) = 1
        [IntRange] _InnerFramePatternColorUsed ("InnerFrame Pattern Color Used", Range(2, 4)) = 2
        _InnerFramePatternColorA ("InnerFrame Pattern Color A", Color) = (1,1,1,1)
        _InnerFramePatternColorB ("InnerFrame Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _InnerFramePatternColorC ("InnerFrame Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _InnerFramePatternColorD ("InnerFrame Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // InnerFrame gradient
        _InnerFrameGradientEnabled ("InnerFrame Gradient Enabled", Float) = 0
        [Enum(GradientType)] _InnerFrameGradientType ("InnerFrame Gradient Type", Int) = 0
        _InnerFrameGradientColorA ("InnerFrame Gradient Color A", Color) = (0.1, 0.1, 0.1, 1)
        _InnerFrameGradientColorB ("InnerFrame Gradient Color B", Color) = (0.2, 0.2, 0.2, 1)
        _InnerFrameGradientColorC ("InnerFrame Gradient Color C", Color) = (0.15, 0.15, 0.15, 1)
        _InnerFrameGradientColorD ("InnerFrame Gradient Color D", Color) = (0.05, 0.05, 0.05, 1)
        _InnerFrameGradientDirection ("InnerFrame Gradient Direction", Vector) = (1, 0, 0, 0)
        _InnerFrameGradientSpeed ("InnerFrame Gradient Speed", Float) = 1.0
        _InnerFrameGradientScale ("InnerFrame Gradient Scale", Range(0.1, 5)) = 1.0
        _InnerFrameGradientOffset ("InnerFrame Gradient Offset", Range(-2, 2)) = 0.0
        _InnerFrameGlobalBlend ("InnerFrame Global Blend", Range(0, 1)) = 0.0
        _InnerFrameGlobalIntensity ("InnerFrame Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _InnerFrameGradientColorUsed ("InnerFrame Gradient Color Used", Range(2, 4)) = 4

        // ====================================================================
        // Edge (recessed indent around panel quad)
        // ====================================================================
        _EdgeEnabled ("Edge Enabled", Float) = 0
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 0.5)
        _EdgeRenderAlpha ("Edge Render Alpha", Range(0,1)) = 1
        _EdgeRenderEmissive ("Edge Render Emissive", Range(0,1)) = 0
        _EdgeWidth ("Edge Width", Range(0.001, 1.0)) = 0.1
        _EdgeSoftness ("Edge Softness", Range(0, 1)) = 0.3
        _EdgeIntensity ("Edge Intensity", Range(0, 2)) = 0.5
        _EdgeInset ("Edge Inset", Range(0.0, 0.5)) = 0.0

        _EdgeGradientEnabled ("Edge Gradient Enabled", Float) = 0
        [Enum(GradientType)] _EdgeGradientType ("Edge Gradient Type", Int) = 0
        _EdgeGradientColorA ("Edge Gradient Color A", Color) = (0, 0, 0, 1)
        _EdgeGradientColorB ("Edge Gradient Color B", Color) = (0.1, 0.1, 0.1, 1)
        _EdgeGradientColorC ("Edge Gradient Color C", Color) = (0, 0, 0, 1)
        _EdgeGradientColorD ("Edge Gradient Color D", Color) = (0.05, 0.05, 0.05, 1)
        _EdgeGradientDirection ("Edge Gradient Direction", Vector) = (0, 1, 0, 0)
        _EdgeGradientSpeed ("Edge Gradient Speed", Float) = 1.0
        _EdgeGradientScale ("Edge Gradient Scale", Range(0.1, 5)) = 1.0
        _EdgeGradientOffset ("Edge Gradient Offset", Range(-2, 2)) = 0.0
        _EdgeGlobalBlend ("Edge Global Blend", Range(0, 1)) = 0.0
        _EdgeGlobalIntensity ("Edge Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _EdgeGradientColorUsed ("Edge Gradient Color Used", Range(2, 4)) = 2

        // ====================================================================
        // Border (cut-in border at canvas edge)
        // ====================================================================
        _BorderEnabled ("Border Enabled", Float) = 0
        _BorderColor ("Border Color", Color) = (1, 1, 1, 1)
        _BorderRenderAlpha ("Border Render Alpha", Range(0,1)) = 1
        _BorderRenderEmissive ("Border Render Emissive", Range(0,1)) = 0
        _BorderWidth ("Border Width", Range(0.001, 0.5)) = 0.02
        _BorderSoftness ("Border Softness", Range(0, 0.5)) = 0.01
        _BorderIntensity ("Border Intensity", Range(0, 2)) = 1.0

        _BorderGradientEnabled ("Border Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BorderGradientType ("Border Gradient Type", Int) = 0
        _BorderGradientColorA ("Border Gradient Color A", Color) = (1, 1, 1, 1)
        _BorderGradientColorB ("Border Gradient Color B", Color) = (0.8, 0.8, 0.8, 1)
        _BorderGradientColorC ("Border Gradient Color C", Color) = (0.6, 0.6, 0.6, 1)
        _BorderGradientColorD ("Border Gradient Color D", Color) = (0.4, 0.4, 0.4, 1)
        _BorderGradientDirection ("Border Gradient Direction", Vector) = (0, 1, 0, 0)
        _BorderGradientSpeed ("Border Gradient Speed", Float) = 1.0
        _BorderGradientScale ("Border Gradient Scale", Range(0.1, 5)) = 1.0
        _BorderGradientOffset ("Border Gradient Offset", Range(-2, 2)) = 0.0
        _BorderGlobalBlend ("Border Global Blend", Range(0, 1)) = 0.0
        _BorderGlobalIntensity ("Border Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _BorderGradientColorUsed ("Border Gradient Color Used", Range(2, 4)) = 2

        // ====================================================================
        // Shadows
        // ====================================================================
        // External shadows
        _LightingShadow1Enabled ("Shadow 1 Enabled", Float) = 0
        _LightingShadow1Color ("Shadow 1 Color", Color) = (0, 0, 0, 0.5)
        _LightingShadow1Blur ("Shadow 1 Blur (softness at contact)", Range(0, 2)) = 0.5
        _LightingShadow1Distance ("Shadow 1 Distance", Range(0, 0.5)) = 0.02
        _LightingShadow1BlurFactor ("Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow1Intensity ("Shadow 1 Intensity", Range(0, 2)) = 1.0

        _LightingShadow2Enabled ("Shadow 2 Enabled", Float) = 0
        _LightingShadow2Color ("Shadow 2 Color", Color) = (0, 0, 0, 0.3)
        _LightingShadow2Blur ("Shadow 2 Blur (softness at contact)", Range(0, 2)) = 0.8
        _LightingShadow2Distance ("Shadow 2 Distance", Range(0, 0.5)) = 0.05
        _LightingShadow2BlurFactor ("Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow2Intensity ("Shadow 2 Intensity", Range(0, 2)) = 1.0

        _LightingShadow3Enabled ("Shadow 3 Enabled", Float) = 0
        _LightingShadow3Color ("Shadow 3 Color", Color) = (0, 0, 0, 0.2)
        _LightingShadow3Blur ("Shadow 3 Blur (softness at contact)", Range(0, 2)) = 1.0
        _LightingShadow3Distance ("Shadow 3 Distance", Range(0, 0.5)) = 0.08
        _LightingShadow3BlurFactor ("Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow3Intensity ("Shadow 3 Intensity", Range(0, 2)) = 1.0

        // Panel body shadows
        _PanelShadow1Enabled ("Panel Shadow 1 Enabled", Float) = 0
        _PanelShadow1Color ("Panel Shadow 1 Color", Color) = (0, 0, 0, 0.6)
        _PanelShadow1Blur ("Panel Shadow 1 Blur (softness at contact)", Range(0, 2)) = 0.3
        _PanelShadow1Distance ("Panel Shadow 1 Distance", Range(0, 0.5)) = 0.01
        _PanelShadow1BlurFactor ("Panel Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _PanelShadow1Intensity ("Panel Shadow 1 Intensity", Range(0, 2)) = 1.0
        _PanelShadow1Cast ("Panel Shadow 1 Cast", Range(0, 1)) = 0.5

        _PanelShadow2Enabled ("Panel Shadow 2 Enabled", Float) = 0
        _PanelShadow2Color ("Panel Shadow 2 Color", Color) = (0, 0, 0, 0.4)
        _PanelShadow2Blur ("Panel Shadow 2 Blur (softness at contact)", Range(0, 2)) = 0.5
        _PanelShadow2Distance ("Panel Shadow 2 Distance", Range(0, 0.5)) = 0.02
        _PanelShadow2BlurFactor ("Panel Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _PanelShadow2Intensity ("Panel Shadow 2 Intensity", Range(0, 2)) = 1.0
        _PanelShadow2Cast ("Panel Shadow 2 Cast", Range(0, 1)) = 0.5

        _PanelShadow3Enabled ("Panel Shadow 3 Enabled", Float) = 0
        _PanelShadow3Color ("Panel Shadow 3 Color", Color) = (0, 0, 0, 0.3)
        _PanelShadow3Blur ("Panel Shadow 3 Blur (softness at contact)", Range(0, 2)) = 0.7
        _PanelShadow3Distance ("Panel Shadow 3 Distance", Range(0, 0.5)) = 0.03
        _PanelShadow3BlurFactor ("Panel Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _PanelShadow3Intensity ("Panel Shadow 3 Intensity", Range(0, 2)) = 1.0
        _PanelShadow3Cast ("Panel Shadow 3 Cast", Range(0, 1)) = 0.5

        // ====================================================================
        // Lighting (3 directional lights)
        // ====================================================================
        _LightingAmbient ("Ambient", Range(0, 1)) = 0.5
        [ToggleUI] _LightingUnlit ("Unlit (skip lighting)", Float) = 0




        _Position ("UI Position", Vector) = (0, 0, 0, 0)
        _AspectRatio ("Aspect Ratio Override (0=auto)", Float) = 0

        // Corner screws (rack-gear realism) — see CG/SDF/SDFPanelScrews.cginc.
        // Inset and radius are in the SAME units as _PanelPadding and are measured in from the
        // PANEL BODY's corner, so the hardware keeps a set distance from the corner it is holding
        // down at any panel size, exactly the way padding keeps its distance from the quad edge.
        // (They were `...Px` real-screen-pixel offsets from the raw QUAD corner, which drifted off
        // the visible corner as soon as the padding or the panel size changed.)
        // Disabled by default so nothing changes for panels that don't opt in.
        _PanelScrewsEnabled ("Panel Screws Enabled", Float) = 0
        [Enum(ScrewShapeType)] _PanelScrewShapeType ("Panel Screw Shape", Int) = 0
        _PanelScrewInset ("Panel Screw Inset", Range(0, 1.5)) = 0.12
        _PanelScrewRadius ("Panel Screw Radius", Range(0.002, 0.5)) = 0.055
        // Fixed-SIZE hardware. _PanelScrewInset/_PanelScrewRadius are in the panel's own
        // isotropic space, where one unit is HALF THE SHORT SIDE — so one skin puts a 46-unit
        // bolt on a tall panel and a 2-unit speck on a 58-high strip, and the app ends up with
        // screws in half a dozen physical sizes, none of them agreeing. Set either of these
        // above 0.5 and it wins, giving the same screw everywhere the skin is used. Units match
        // _PanelCornerRadiusPx and _WidgetPixelSize: the RectTransform's own size, i.e. CANVAS
        // units, not device pixels — so hardware keeps its size relative to the UI at any DPI.
        // 0 keeps the proportional behaviour.
        _PanelScrewInsetPx ("Panel Screw Inset (px, 0 = use Inset)", Float) = 0
        _PanelScrewRadiusPx ("Panel Screw Radius (px, 0 = use Radius)", Float) = 0
        _PanelScrewColor ("Panel Screw Color", Color) = (0.62, 0.63, 0.655, 1)
        _PanelScrewSlotColor ("Panel Screw Slot Color", Color) = (0.07, 0.07, 0.08, 1)
        _PanelScrewRotation ("Panel Screw Rotation", Range(-180, 180)) = 32
        _PanelScrewDepth ("Panel Screw Recess Depth", Range(0, 1)) = 0.85
        _PanelScrewMetallic ("Panel Screw Metallic", Range(0, 1)) = 0.8
        // How far the counterbore the bolt sits in reaches past the head, in head radii.
        // 0 = none (a head pasted flat on the panel, which is how these used to read).
        _PanelScrewBore ("Panel Screw Counterbore", Range(0, 1.5)) = 0

        // Set to 0 on panels mounted into an overlay/modal layer (see AppShell.MountOverlay)
        // so they stop multiplying in the shared _UIShadowBuffer — that buffer has no concept
        // of panel stacking, so an overlay sitting in front of other panels was still receiving
        // (and visibly showing) shadows cast by widgets on the panels behind it. Default 1 keeps
        // every panel that isn't an overlay behaving exactly as before.
        _ReceiveSceneShadows ("Receive Scene Shadows", Float) = 1

        // Unity UI standard properties
        // Materials v2 (CG/Core/UIMaterials.cginc): matcap reflection + backdrop glass on the Panel body.
        _PanelMatcapEnabled ("Panel Matcap Enabled", Float) = 0
        _PanelMatcapLayer ("Panel Matcap Layer (UiMaterials/catalog.json)", Float) = 0
        _PanelMatcapStrength ("Panel Matcap Strength", Range(0, 1)) = 1
        _PanelMatcapMode ("Panel Matcap Mode (0 metal, 1 coat, 2 tint)", Float) = 0
        _PanelGlassEnabled ("Panel Glass Enabled", Float) = 0
        _PanelGlassStrength ("Panel Glass Strength", Range(0, 1)) = 0.85
        _PanelGlassRefract ("Panel Glass Refraction", Range(0, 0.2)) = 0.03
        _PanelGlassBlur ("Panel Glass Blur (mip)", Range(0, 8)) = 3
        _PanelGlassTint ("Panel Glass Tint", Color) = (1, 1, 1, 1)
        _PanelGlassRim ("Panel Glass Rim", Range(0, 2)) = 0.6
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
            #define UI_PATTERN_TEXTURE 1   // Materials v2 texture patterns (opt-in: see UIPatterns.cginc)
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #include "CG/SDF/SDFPrimitives.cginc"
            #include "CG/SDF/SDFOperations.cginc"
            #include "CG/Core/Constants.cginc"
            #include "CG/Core/UIMath.cginc"
            #include "CG/Core/UIComponents.cginc"
            #include "CG/Core/UIPatterns.cginc"
            #include "CG/Core/UILighting.cginc"
            #include "CG/Core/UIMaterials.cginc"
            UI_MATERIAL_V2_UNIFORMS(Panel)
            #include "CG/Core/UIRenderer.cginc"
            #include "CG/Core/UIGradients.cginc"
            #include "CG/SDF/SDFPanelUniforms.cginc"

            // Corner-screw uniforms (not in SDFPanelUniforms.cginc — this shader owns them).
            float _PanelScrewsEnabled, _PanelScrewInset, _PanelScrewRadius;
            float _PanelScrewInsetPx, _PanelScrewRadiusPx;
            float _PanelScrewShapeType, _PanelScrewRotation, _PanelScrewDepth, _PanelScrewMetallic;
            float _PanelScrewBore;
            float4 _PanelScrewColor, _PanelScrewSlotColor;
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

            // Includes SDFButtonLayers (shared utilities) + SDFPanelShapes + Panel shadow/edge/border functions
            #include "CG/SDF/SDFPanelLayers.cginc"
            // After the layers, which is where buttonCompositeOver comes from.
            #include "CG/SDF/SDFPanelScrews.cginc"

            float _PanelPaddingPx;   // see Properties — 0 = proportional _PanelPadding
            float _BorderWidthPx;    // canvas units, 0 = proportional _BorderWidth
            float _EdgeWidthPx;      // canvas units, 0 = proportional _EdgeWidth
            float _EdgeCutInside;    // 1 = the Edge is a bloom outside the plate, never under it
            float _PanelPatternPx;   // canvas units per pattern tile, 0 = widget-relative uvIso

            fixed4 frag(v2f IN) : SV_Target
            {
                UI_SET_SCREEN_UV(IN.screenPos)
                float2 uv     = IN.texcoord;
                float2 center = float2(0.5, 0.5);

                float rectAspect = (_AspectRatio > 0.001)
                    ? _AspectRatio
                    : abs(ddy(uv.y)) / max(0.0001, abs(ddx(uv.x)));
                float2 aspectScale = float2(max(rectAspect, 1.0), max(1.0 / rectAspect, 1.0));
                float2 pos    = (uv - center) * 2.0 * aspectScale;
                float2 uvIso  = (uv - center) / float2(aspectScale.x, aspectScale.y) + center;
                // Pattern sampling space. uvIso spans the widget's short side, so grain size scaled
                // with the panel (blotches on a rack, mush on a strip); with _PanelPatternPx it is
                // fixed canvas units instead, centred so the grain doesn't slide when the rect grows.
                float2 patUV = (_PanelPatternPx > 0.001 && _WidgetPixelSize.x > 1.0 && _WidgetPixelSize.y > 1.0)
                             ? (uv - center) * _WidgetPixelSize.xy / _PanelPatternPx + center
                             : uvIso;

                // Panel body half-extents (nine-slice: padding is constant equi-pixel margin, or a
                // fixed canvas-unit margin when _PanelPaddingPx is set — same 2/minPix conversion as
                // _PanelCornerRadiusPx and the screws)
                float padMinPix    = min(_WidgetPixelSize.x, _WidgetPixelSize.y);
                float panelPad     = (_PanelPaddingPx > 0.001 && padMinPix > 1.0)
                                   ? _PanelPaddingPx * 2.0 / padMinPix : _PanelPadding;
                float bodyHalfW    = max(0.001, aspectScale.x - panelPad);
                float bodyHalfH    = max(0.001, aspectScale.y - panelPad);
                // Line weights pinned the same way (2026-09-14, Tron): a proportional border is a
                // hairline on a 60-unit strip and a 4px bar on an 850-unit rack. 0 = proportional.
                float borderWidthPos = (_BorderWidthPx > 0.001 && padMinPix > 1.0)
                                     ? _BorderWidthPx * 2.0 / padMinPix : _BorderWidth;
                float edgeWidthPos   = (_EdgeWidthPx > 0.001 && padMinPix > 1.0)
                                     ? _EdgeWidthPx * 2.0 / padMinPix : _EdgeWidth;
                int   bodyShapeType = (int)_PanelShapeType;

                float2 bodyPos = pos;
                if (abs(_PanelShapeRotation) > 0.001)
                    bodyPos = rotate2D(pos, _PanelShapeRotation * (PI / 180.0));

                // Lights
                // The three scene lights. No per-material lights exist any more — see UILighting.cginc.
                // Resolved ONCE here; every shadow call below reads these locals instead of re-expanding
                // the macro (which is what made this fragment program so expensive to compile).
                UILight light1 = UI_LIGHT_1;
                UILight light2 = UI_LIGHT_2;
                UILight light3 = UI_LIGHT_3;
                float3 lightDir1 = light1.direction;
                float3 lightDir2 = light2.direction;
                float3 lightDir3 = light3.direction;

                float4 finalColor  = float4(0, 0, 0, 0);
                float3 emissiveAccum = float3(0, 0, 0);
                float  time        = _Time.y;

                // Bevel geometry (drives pseudoHeight for shadow hull sweep)
                float bevelDist    = (_PanelBevelEnabled > 0.5) ? _PanelBevelDistance : 0.0;
                float bevelDepthRaw = (_PanelBevelEnabled > 0.5) ? abs(_PanelBevelDepth) : 0.0;
                float maxDim       = min(bodyHalfW, bodyHalfH);
                float pseudoHeight = maxDim * lerp(0.05, 0.5, bevelDepthRaw);
                float rimWidth     = (_PanelRimEnabled > 0.5) ? _PanelRimWidth : 0.0;
                float faceInset    = rimWidth + bevelDist;

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
                    float indentAlpha = calculatePanelEdgeIndent(uv, bodyPos, edgeWidthPos, _EdgeSoftness,
                        bodyHalfW, bodyHalfH, bodyShapeType,
                        _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3, _EdgeInset);
                    if (_EdgeCutInside > 0.5)
                    {
                        // A BLOOM, not an indent. The indent is full strength everywhere inside the
                        // body (the opaque body normally hides that), but its EMISSIVE is additive and
                        // survives the body composite — so an emissive halo lit the whole face. Cut it
                        // to the outside, the way UIRingMask cuts the button's Edge (Tron, 2026-09-14).
                        float edgeBd = getPanelBodySDF(bodyPos, bodyHalfW, bodyHalfH, bodyShapeType,
                            _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3);
                        float edgeAa = max(fwidth(edgeBd), 1e-5);
                        indentAlpha *= smoothstep(-edgeAa, edgeAa, edgeBd);
                    }
                    if (indentAlpha > 0.001)
                    {
                        float edgeMask = indentAlpha * _EdgeIntensity;
                        buttonCompositeOver(finalColor, edgeBaseColor, edgeMask * _EdgeRenderAlpha);
                        emissiveAccum += edgeBaseColor * edgeMask * _EdgeRenderEmissive;
                    }
                }

                // ============================================================
                // 2. External shadows
                // ============================================================
                if (_LightingShadow1Enabled > 0.5)
                {
                    float sa = calculatePanelExternalShadow(uv, lightDir1, _LightingShadow1Blur, _LightingShadow1Distance, _LightingShadow1BlurFactor,
                        bodyHalfW, bodyHalfH, bodyShapeType, _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3, aspectScale, _PanelShapeRotation * (PI / 180.0));
                    if (sa > 0.001) buttonCompositeOver(finalColor, _LightingShadow1Color.rgb, _LightingShadow1Color.a * sa * _LightingShadow1Intensity);
                }
                if (_LightingShadow2Enabled > 0.5)
                {
                    float sa = calculatePanelExternalShadow(uv, lightDir2, _LightingShadow2Blur, _LightingShadow2Distance, _LightingShadow2BlurFactor,
                        bodyHalfW, bodyHalfH, bodyShapeType, _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3, aspectScale, _PanelShapeRotation * (PI / 180.0));
                    if (sa > 0.001) buttonCompositeOver(finalColor, _LightingShadow2Color.rgb, _LightingShadow2Color.a * sa * _LightingShadow2Intensity);
                }
                if (_LightingShadow3Enabled > 0.5)
                {
                    float sa = calculatePanelExternalShadow(uv, lightDir3, _LightingShadow3Blur, _LightingShadow3Distance, _LightingShadow3BlurFactor,
                        bodyHalfW, bodyHalfH, bodyShapeType, _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3, aspectScale, _PanelShapeRotation * (PI / 180.0));
                    if (sa > 0.001) buttonCompositeOver(finalColor, _LightingShadow3Color.rgb, _LightingShadow3Color.a * sa * _LightingShadow3Intensity);
                }

                // ============================================================
                // 3. Panel body shadows
                // ============================================================
                float shadowFaceHole = (_PanelFaceEnabled < 0.5) ? 1.0 : 0.0;
                float bodyRotRad = _PanelShapeRotation * (PI / 180.0);

                if (_PanelShadow1Enabled > 0.5)
                {
                    float sa = calculatePanelBodyShadow(uv, lightDir1, _PanelShadow1Blur, _PanelShadow1Distance, _PanelShadow1BlurFactor, _PanelShadow1Cast,
                        bodyHalfW, bodyHalfH, bodyShapeType, _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3,
                        faceInset, pseudoHeight, aspectScale, bodyRotRad, shadowFaceHole);
                    if (sa > 0.001) buttonCompositeOver(finalColor, _PanelShadow1Color.rgb, _PanelShadow1Color.a * sa * _PanelShadow1Intensity);
                }
                if (_PanelShadow2Enabled > 0.5)
                {
                    float sa = calculatePanelBodyShadow(uv, lightDir2, _PanelShadow2Blur, _PanelShadow2Distance, _PanelShadow2BlurFactor, _PanelShadow2Cast,
                        bodyHalfW, bodyHalfH, bodyShapeType, _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3,
                        faceInset, pseudoHeight, aspectScale, bodyRotRad, shadowFaceHole);
                    if (sa > 0.001) buttonCompositeOver(finalColor, _PanelShadow2Color.rgb, _PanelShadow2Color.a * sa * _PanelShadow2Intensity);
                }
                if (_PanelShadow3Enabled > 0.5)
                {
                    float sa = calculatePanelBodyShadow(uv, lightDir3, _PanelShadow3Blur, _PanelShadow3Distance, _PanelShadow3BlurFactor, _PanelShadow3Cast,
                        bodyHalfW, bodyHalfH, bodyShapeType, _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3,
                        faceInset, pseudoHeight, aspectScale, bodyRotRad, shadowFaceHole);
                    if (sa > 0.001) buttonCompositeOver(finalColor, _PanelShadow3Color.rgb, _PanelShadow3Color.a * sa * _PanelShadow3Intensity);
                }

                // ============================================================
                // 4. Panel body + face + bevel + rim + lighting
                // ============================================================
                if (_PanelEnabled > 0.5)
                {
                    float bodyDist = getPanelBodySDF(bodyPos, bodyHalfW, bodyHalfH, bodyShapeType,
                        _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3);

                    // Face SDF (inner boundary for bevel region)
                    float topFaceDist;
                    // Inradius of the face region — centre-to-nearest-edge distance. Drives the
                    // full-face dome/bowl profile so it spans the whole face instead of saturating
                    // a few bevel-widths in.
                    float faceInradius;
                    if (_PanelFaceShapeEnabled > 0.5)
                    {
                        float faceMargin = (1.0 - saturate(_PanelFaceSize)) * min(bodyHalfW, bodyHalfH);
                        float faceHalfW  = max(0.001, bodyHalfW - faceMargin);
                        float faceHalfH  = max(0.001, bodyHalfH - faceMargin);
                        faceInradius     = max(0.001, min(faceHalfW, faceHalfH) - bevelDist);
                        float2 facePos   = bodyPos;
                        if (abs(_PanelFaceShapeRotation) > 0.001)
                            facePos = rotate2D(bodyPos, _PanelFaceShapeRotation * (PI / 180.0));
                        float faceShapeDist = getPanelBodySDF(facePos, faceHalfW, faceHalfH,
                            (int)_PanelFaceShapeType, _PanelFaceShapeParam1, _PanelFaceShapeParam2, _PanelFaceShapeParam3,
                            _PanelFaceShapeTexLayer, _PanelFaceShapeTexScale);
                        topFaceDist = faceShapeDist + bevelDist;
                    }
                    else
                    {
                        topFaceDist  = bodyDist + faceInset;
                        faceInradius = max(0.001, min(bodyHalfW, bodyHalfH) - faceInset);
                    }

                    float panelDist;
                    if (_PanelFaceShapeEnabled > 0.5)
                    {
                        float rawFaceDist = topFaceDist - bevelDist;
                        panelDist = min(bodyDist, rawFaceDist);
                    }
                    else
                    {
                        panelDist = bodyDist;
                    }

                    float bodyAA   = fwidth(panelDist) * 0.75;
                    float bodyMask = smoothstep(bodyAA, -bodyAA, panelDist);

                    if (_PanelFaceEnabled < 0.5)
                    {
                        if (faceInset < 0.0001)
                            bodyMask = 0.0;
                        else if (bodyMask > 0.001)
                        {
                            float faceAA   = fwidth(topFaceDist) * 0.75;
                            float faceMask = smoothstep(-faceAA, faceAA, topFaceDist);
                            bodyMask *= faceMask;
                        }
                    }

                    if (bodyMask > 0.001)
                    {
                        UIComponent panelComp = CreateUIComponent(
                            _PanelColor, _PanelRenderAlpha,
                            _PanelBevelDepth, _PanelBevelSmoothness, _PanelBevelDistance, _PanelFaceSmoothness,
                            _PanelGradientColorA, _PanelGradientColorB, _PanelGradientColorC, _PanelGradientColorD,
                            _PanelGradientDirection, _PanelGradientSpeed, _PanelGradientScale, _PanelGradientOffset,
                            _PanelGlobalBlend, _PanelGlobalIntensity, _PanelGradientType,
                            _PanelPatternType, _PanelPatternScale, _PanelPatternIntensity, _PanelPatternContrast,
                            _PanelPatternSpecularEffect, _PanelPatternRoughnessEffect, _PanelPatternRotateEnabled,
                            _PanelPatternModEnabled, _PanelPatternModAmount, _PanelPatternModFrequency, _PanelPatternOffset,
                            _PanelPatternParam1, _PanelPatternParam2, _PanelPatternParam3,
                            _PanelGradientEnabled, _PanelPatternEnabled,
                            _PanelPatternColorEnabled, _PanelPatternColorMode,
                            _PanelPatternColorType, _PanelPatternColorUsed,
                            _PanelPatternColorA, _PanelPatternColorB, _PanelPatternColorC, _PanelPatternColorD
                        );

                        float3 baseColor = panelComp.color.rgb;
                        if (panelComp.gradientEnabled > 0.5)
                        {
                            float4 gc = CalculateGradient(uv, panelComp.gradientColorA, panelComp.gradientColorB,
                                panelComp.gradientColorC, panelComp.gradientColorD, panelComp.gradientDirection,
                                panelComp.gradientType, panelComp.gradientSpeed, panelComp.gradientScale,
                                panelComp.gradientOffset, time, _PanelGradientColorUsed);
                            baseColor = lerp(baseColor, gc.rgb, gc.a);
                        }
                        if (panelComp.globalBlend > 0.0)
                        {
                            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            baseColor = lerp(baseColor, gc.rgb, panelComp.globalBlend * panelComp.globalIntensity);
                        }

                        float specularMod;
                        float2 normalOffset;
                        float3 mainPatternedColor = ApplyMaterialPattern(baseColor, patUV, panelComp, 0.0, 0.0, specularMod, normalOffset);

                        float effectiveBevelDepth = (_PanelBevelEnabled > 0.5) ? panelComp.bevelDepth : 0.0;
                        float effectiveBevelDist  = panelComp.bevelDistance;

                        if (abs(effectiveBevelDepth) > 0.0001)
                        {
                            float depthSign    = sign(effectiveBevelDepth);
                            float bevelHeightRM = maxDim * lerp(0.05, 1.0, abs(effectiveBevelDepth));
                            float bevelDistRM  = max(0.0001, effectiveBevelDist);
                            float tanB         = bevelHeightRM / bevelDistRM;
                            effectiveBevelDepth = depthSign * tanB / (1.0 + tanB * 0.5);
                        }

                        float  bevelSDF   = topFaceDist;
                        float3 faceNormal = CalculateShapeBevelNormal(bevelSDF, effectiveBevelDepth,
                            effectiveBevelDist, panelComp.bevelSmoothness, panelComp.fillFaceSmoothness,
                            _PanelBevelProfileType, _PanelBevelProfileSharpness, aspectScale,
                            bodyPos, faceInradius);

                        if (_PanelFaceShapeEnabled > 0.5 && topFaceDist > 0.0 && bodyDist < 0.0)
                        {
                            float approxBevelFactor = smoothstep(effectiveBevelDist,
                                max(0.0001, effectiveBevelDist - panelComp.bevelSmoothness), abs(bevelSDF));
                            float gapFactor = 1.0 - approxBevelFactor;
                            if (gapFactor > 0.001)
                            {
                                float2 wallGrad = float2(ddx(bodyDist), ddy(bodyDist));
                                float wallLen = length(wallGrad);
                                if (wallLen > 0.0001)
                                {
                                    float2 inwardDir = -wallGrad / wallLen;
                                    float wallTilt   = gapFactor * abs(effectiveBevelDepth) * 0.35;
                                    faceNormal = normalize(faceNormal + float3(inwardDir * wallTilt, 0));
                                }
                            }
                        }

                        ButtonBevelRenderResult bevelResult = RenderButtonBevelWithPatternAndGradient(
                            uv, patUV, baseColor, mainPatternedColor, faceNormal, bevelSDF,
                            effectiveBevelDepth, effectiveBevelDist, panelComp.bevelSmoothness,
                            _PanelBevelEnabled,
                            _PanelBevelPatternEnabled, _PanelBevelPatternType, _PanelBevelPatternScale,
                            _PanelBevelPatternIntensity, _PanelBevelPatternContrast,
                            _PanelBevelPatternSpecularEffect, _PanelBevelPatternRoughnessEffect,
                            _PanelBevelGradientEnabled, _PanelBevelGradientType,
                            _PanelBevelGradientColorA, _PanelBevelGradientColorB,
                            _PanelBevelGradientColorC, _PanelBevelGradientColorD, _PanelBevelGradientDirection,
                            _PanelBevelGradientSpeed, _PanelBevelGradientScale, _PanelBevelGradientOffset,
                            _PanelBevelPatternParam1, _PanelBevelPatternParam2, _PanelBevelPatternParam3,
                            _PanelBevelGradientColorUsed,
                            _PanelBevelPatternColorEnabled, _PanelBevelPatternColorMode,
                            _PanelBevelPatternColorType, _PanelBevelPatternColorUsed,
                            _PanelBevelPatternColorA, _PanelBevelPatternColorB,
                            _PanelBevelPatternColorC, _PanelBevelPatternColorD,
                            time, light1, light2, light3
                        );

                        float rimSDF   = panelDist;
                        bool faceActive = (_PanelFaceShapeEnabled > 0.5) && (topFaceDist <= 0.0);
                        if (faceActive) rimSDF = -1.0;

                        ButtonRimResult rimResult = CalculateButtonRimFromSDF(
                            uv, bevelResult.litColor, bevelResult.normal, rimSDF,
                            _PanelRimEnabled, _PanelRimDepth, _PanelRimWidth, _PanelRimSmoothness,
                            light1, light2, light3, aspectScale
                        );

                        float3 litColor = ApplyUILighting(rimResult.normal, rimResult.litColor,
                            _LightingAmbient, specularMod, normalOffset, light1, light2, light3);
                        UI_MATERIAL_V2(litColor, rimResult.litColor, rimResult.normal, Panel, 1.0)

                        buttonCompositeOver(finalColor, litColor, bodyMask * panelComp.alpha);
                        emissiveAccum += baseColor * bodyMask * _PanelRenderEmissive;
                    }
                }

                // ============================================================
                // 5. InnerFrame (nested shape on the panel face)
                // ============================================================
                if (_InnerFrameEnabled > 0.5)
                {
                    // Compute InnerFrame SDF
                    float innerMargin = (1.0 - saturate(_InnerFrameSize)) * min(bodyHalfW, bodyHalfH);
                    float innerHalfW  = max(0.001, bodyHalfW - innerMargin);
                    float innerHalfH  = max(0.001, bodyHalfH - innerMargin);
                    float2 innerPos   = bodyPos;
                    if (_InnerFrameShapeEnabled > 0.5)
                    {
                        if (abs(_InnerFrameShapeRotation) > 0.001)
                            innerPos = rotate2D(pos, _InnerFrameShapeRotation * (PI / 180.0));
                        // Own shape type
                    }
                    int innerShapeType = _InnerFrameShapeEnabled > 0.5 ? (int)_InnerFrameShapeType : bodyShapeType;
                    float ifp1 = _InnerFrameShapeEnabled > 0.5 ? _InnerFrameShapeParam1 : _PanelShapeParam1;
                    float ifp2 = _InnerFrameShapeEnabled > 0.5 ? _InnerFrameShapeParam2 : _PanelShapeParam2;
                    float ifp3 = _InnerFrameShapeEnabled > 0.5 ? _InnerFrameShapeParam3 : _PanelShapeParam3;
                    float innerTexLayer = _InnerFrameShapeEnabled > 0.5 ? _InnerFrameShapeTexLayer : -2;
                    float2 innerTexScale = _InnerFrameShapeEnabled > 0.5 ? _InnerFrameShapeTexScale : float2(0,0);

                    float innerDist = getPanelBodySDF(innerPos, innerHalfW, innerHalfH,
                        innerShapeType, ifp1, ifp2, ifp3, innerTexLayer, innerTexScale);

                    float innerAA   = fwidth(innerDist) * 0.75;
                    float innerMask = smoothstep(innerAA, -innerAA, innerDist);

                    if (innerMask > 0.001)
                    {
                        UIComponent ifComp = CreateUIComponent(
                            _InnerFrameColor, _InnerFrameRenderAlpha,
                            _InnerFrameBevelDepth, _InnerFrameBevelSmoothness, _InnerFrameBevelDistance, _InnerFrameFaceSmoothness,
                            _InnerFrameGradientColorA, _InnerFrameGradientColorB, _InnerFrameGradientColorC, _InnerFrameGradientColorD,
                            _InnerFrameGradientDirection, _InnerFrameGradientSpeed, _InnerFrameGradientScale, _InnerFrameGradientOffset,
                            _InnerFrameGlobalBlend, _InnerFrameGlobalIntensity, _InnerFrameGradientType,
                            _InnerFramePatternType, _InnerFramePatternScale, _InnerFramePatternIntensity, _InnerFramePatternContrast,
                            _InnerFramePatternSpecularEffect, _InnerFramePatternRoughnessEffect, _InnerFramePatternRotateEnabled,
                            _InnerFramePatternModEnabled, _InnerFramePatternModAmount, _InnerFramePatternModFrequency, _InnerFramePatternOffset,
                            _InnerFramePatternParam1, _InnerFramePatternParam2, _InnerFramePatternParam3,
                            _InnerFrameGradientEnabled, _InnerFramePatternEnabled,
                            _InnerFramePatternColorEnabled, _InnerFramePatternColorMode,
                            _InnerFramePatternColorType, _InnerFramePatternColorUsed,
                            _InnerFramePatternColorA, _InnerFramePatternColorB, _InnerFramePatternColorC, _InnerFramePatternColorD
                        );

                        float3 ifBaseColor = ifComp.color.rgb;
                        if (ifComp.gradientEnabled > 0.5)
                        {
                            float4 gc = CalculateGradient(uv, ifComp.gradientColorA, ifComp.gradientColorB,
                                ifComp.gradientColorC, ifComp.gradientColorD, ifComp.gradientDirection,
                                ifComp.gradientType, ifComp.gradientSpeed, ifComp.gradientScale,
                                ifComp.gradientOffset, time, _InnerFrameGradientColorUsed);
                            ifBaseColor = lerp(ifBaseColor, gc.rgb, gc.a);
                        }
                        if (ifComp.globalBlend > 0.0)
                        {
                            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            ifBaseColor = lerp(ifBaseColor, gc.rgb, ifComp.globalBlend * ifComp.globalIntensity);
                        }

                        float ifSpecularMod;
                        float2 ifNormalOffset;
                        float3 ifPatternedColor = ApplyMaterialPattern(ifBaseColor, patUV, ifComp, 0.0, 0.0, ifSpecularMod, ifNormalOffset);

                        float ifEffBevelDepth = (_InnerFrameBevelEnabled > 0.5) ? ifComp.bevelDepth : 0.0;
                        float3 ifNormal = CalculateShapeBevelNormal(innerDist, ifEffBevelDepth,
                            ifComp.bevelDistance, ifComp.bevelSmoothness, ifComp.fillFaceSmoothness,
                            _InnerFrameBevelProfileType, _InnerFrameBevelProfileSharpness, aspectScale);

                        ButtonBevelRenderResult ifBevelResult = RenderButtonBevelWithPatternAndGradient(
                            uv, patUV, ifBaseColor, ifPatternedColor, ifNormal, innerDist,
                            ifEffBevelDepth, ifComp.bevelDistance, ifComp.bevelSmoothness,
                            _InnerFrameBevelEnabled,
                            _InnerFrameBevelPatternEnabled, _InnerFrameBevelPatternType, _InnerFrameBevelPatternScale,
                            _InnerFrameBevelPatternIntensity, _InnerFrameBevelPatternContrast,
                            _InnerFrameBevelPatternSpecularEffect, _InnerFrameBevelPatternRoughnessEffect,
                            _InnerFrameBevelGradientEnabled, _InnerFrameBevelGradientType,
                            _InnerFrameBevelGradientColorA, _InnerFrameBevelGradientColorB,
                            _InnerFrameBevelGradientColorC, _InnerFrameBevelGradientColorD, _InnerFrameBevelGradientDirection,
                            _InnerFrameBevelGradientSpeed, _InnerFrameBevelGradientScale, _InnerFrameBevelGradientOffset,
                            _InnerFrameBevelPatternParam1, _InnerFrameBevelPatternParam2, _InnerFrameBevelPatternParam3,
                            _InnerFrameBevelGradientColorUsed,
                            _InnerFrameBevelPatternColorEnabled, _InnerFrameBevelPatternColorMode,
                            _InnerFrameBevelPatternColorType, _InnerFrameBevelPatternColorUsed,
                            _InnerFrameBevelPatternColorA, _InnerFrameBevelPatternColorB,
                            _InnerFrameBevelPatternColorC, _InnerFrameBevelPatternColorD,
                            time, light1, light2, light3
                        );

                        ButtonRimResult ifRimResult = CalculateButtonRimFromSDF(
                            uv, ifBevelResult.litColor, ifBevelResult.normal, innerDist,
                            _InnerFrameRimEnabled, _InnerFrameRimDepth, _InnerFrameRimWidth, _InnerFrameRimSmoothness,
                            light1, light2, light3, aspectScale
                        );

                        float3 ifLitColor = ApplyUILighting(ifRimResult.normal, ifRimResult.litColor,
                            _LightingAmbient, ifSpecularMod, ifNormalOffset, light1, light2, light3);

                        buttonCompositeOver(finalColor, ifLitColor, innerMask * ifComp.alpha);
                        emissiveAccum += ifBaseColor * innerMask * _InnerFrameRenderEmissive;
                    }
                }

                // ============================================================
                // 6. Border
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
                    float4 borderResult = calculatePanelBorder(uv, borderColor, borderWidthPos, _BorderSoftness,
                        bodyHalfW, bodyHalfH, bodyShapeType,
                        _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3,
                        aspectScale, borderTerritory);
                    float borderMask = borderResult.a * _BorderIntensity;

                    float borderPresence = max(_BorderRenderAlpha, _BorderRenderEmissive);
                    float effectiveTerr  = borderTerritory * borderPresence;
                    if (effectiveTerr > 0.001)
                    {
                        float clearFactor = 1.0 - effectiveTerr;
                        finalColor.rgb  *= clearFactor;
                        finalColor.a    *= clearFactor;
                        emissiveAccum   *= clearFactor;
                    }
                    if (borderMask > 0.001)
                    {
                        buttonCompositeOver(finalColor, borderResult.rgb, borderMask * _BorderRenderAlpha);
                        emissiveAccum += borderResult.rgb * borderMask * _BorderRenderEmissive;
                    }
                }

                // ============================================================
                // 6.5 Corner screws (rack-gear realism) — see CG/SDF/SDFPanelScrews.cginc.
                //     Drawn in the panel BODY's own space, so they sit a constant
                //     distance in from the visible corner (same units as
                //     _PanelPadding) and inherit the body's rotation.
                // ============================================================
                if (_PanelScrewsEnabled > 0.5)
                {
                    // One pixel measured in `pos` units. `pos` is linear in uv, so this single
                    // derivative is exact for all four corners — and it must be taken HERE,
                    // outside the per-screw loop, because a derivative under flow control is
                    // undefined.
                    float aaPos = max(fwidth(pos.x), 1e-6);

                    // px -> pos units. `pos` spans 2.0 across the SHORT side, so one pixel is
                    // 2/minPix — the same conversion _PanelCornerRadiusPx uses. Falls back to the
                    // authored proportional values when the px pair is left at 0, and whenever the
                    // widget size has not been published (a preview material, an editor swatch).
                    float minPix    = min(_WidgetPixelSize.x, _WidgetPixelSize.y);
                    float pxToPos   = (minPix > 1.0) ? (2.0 / minPix) : 0.0;
                    float screwIn   = (_PanelScrewInsetPx  > 0.5 && pxToPos > 0.0)
                                    ? _PanelScrewInsetPx  * pxToPos : _PanelScrewInset;
                    float screwRad  = (_PanelScrewRadiusPx > 0.5 && pxToPos > 0.0)
                                    ? _PanelScrewRadiusPx * pxToPos : _PanelScrewRadius;

                    panelDrawScrews(finalColor, bodyPos, bodyHalfW, bodyHalfH, bodyShapeType,
                                    _PanelShapeParam1, _PanelShapeParam2, _PanelShapeParam3, aaPos,
                                    screwIn, screwRad,
                                    (int)_PanelScrewShapeType, _PanelScrewRotation * (PI / 180.0),
                                    _PanelScrewColor.rgb, _PanelScrewSlotColor.rgb,
                                    _PanelScrewDepth, _PanelScrewMetallic, _PanelScrewBore,
                                    UIToLightVector(lightDir1), _LightingAmbient);
                }

                // UI clipping
                #ifdef UNITY_UI_CLIP_RECT
                float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                finalColor   *= clipMask;
                emissiveAccum *= clipMask;
                #endif

                finalColor    *= IN.color;
                emissiveAccum *= IN.color.rgb;
                finalColor.rgb = finalColor.rgb + emissiveAccum;

                // Receive shadows cast by the widgets sitting on this panel. Panels never cast
                // (no _ShadowPassMode, no WidgetShadowQuad), so there is no self-shadow to exclude.
                // Gated by _ReceiveSceneShadows: the shared buffer has no per-panel depth/stacking
                // concept, so without this an overlay panel sitting in FRONT of other panels still
                // multiplied in shadows cast by widgets on whatever is behind it.
                if (finalColor.a > 0.001 && _ReceiveSceneShadows > 0.5) {
                    float2 shadowUV = IN.screenPos.xy / IN.screenPos.w;
                    finalColor.rgb *= sampleUIShadowBuffer(shadowUV);
                }

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "UI/Default"
}
