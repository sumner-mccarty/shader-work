// ============================================================================
// SDFButton.shader - 2D SDF UI Button with Pure Function Architecture
// ============================================================================
// Modern SDF-based button control following SDFKnob.shader's architecture.
// 2D composited from a top-down perspective with lighting and full material system.
//
// COMPONENTS:
// 1. Button - Main button shape (supports 11 shape types, full material pipeline)
// 2. Face   - Optional inner face shape for stacked/inset bevel appearance
// 3. Icon   - Optional indicator on button face (16 icon shapes)
// 4. Edge   - Recessed indent around button boundary
// 5. Border - Cut-in border at canvas edge
// 6. Shadow System - External shadows and button cast shadows
//
// BUTTON FEATURES:
// - _ButtonEnabled: Toggle button visibility
// - _ButtonShapeType: 0=Squircle 1=Polygircle 2=Tab 3=Hexagon 4=Octagon
// - _ButtonShapeParam1/2/3: per-shape tuning parameters
// - _ButtonRoundness: universal post-SDF rounding (0-1)
// - _ButtonPadding: equi-pixel margin per side (0 = touches edge, higher = more inset)
// - Full material system support (patterns, gradients, lighting)
//
// FACE SHAPE (inner face region, grouped with Button):
// - _ButtonFaceEnabled: 0 = face area hidden (ring/outline mode); bevel/rim still render
// - _ButtonFaceShapeEnabled: 1 = face uses its own SDF shape; 0 = face is body inset
// - _ButtonFaceSize: fraction of button size (0.01-1), lower = wider bevel wall
// - _ButtonFaceShape*/Rotation/TexLayer/TexScale: custom face shape params
//
// ICON (indicator on face):
// - _IconEnabled: Toggle icon visibility
// - _IconShapeType: 0-15 (circle, rect, triangle, arrow, star, cross, etc.)
// - _IconWidth/_IconHeight: icon dimensions
// - _IconOffset: position offset from center
// - Full material system support
//
// KEY ARCHITECTURAL PRINCIPLES:
// 1. .cginc files contain ONLY functions, structs, and constants (no properties)
// 2. Shader-specific properties declared in .shader file Properties block
// 3. All function parameters passed explicitly (no hidden dependencies)
// 4. Exception: Global uniforms in UIGlobalUniforms.cginc for screen effects
// ============================================================================

Shader "UI/SDFButton"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        // Button state
        _Value ("Value (Pressed)", Range(0,1)) = 0

        // ====================================================================
        // Play ring + loop glyph (SDFPlayRing.cginc) — the pad's sample timeline. Driven live
        // by DrumPadPanel; every skin leaves _PlayRingEnabled at 0 and is unaffected.
        // ====================================================================
        _PlayRingEnabled ("Play Ring Enabled", Float) = 0
        _PlayRingColor ("Play Ring Color", Color) = (1,1,1,1)
        _PlayRingWidth ("Play Ring Half Width", Range(0.002,0.08)) = 0.03
        _PlayRingInset ("Play Ring Inset From Face Edge", Range(0,0.3)) = 0.07
        _PlayRingProgress ("Play Ring Progress", Range(0,1)) = 0
        _PlayRingActive ("Play Ring Active (glow)", Range(0,1)) = 0
        _PlayRingGlow ("Play Ring Glow", Range(0,4)) = 1.6
        _PlayRingTrail ("Play Ring Trail Length", Range(0,1)) = 0.22
        _PlayRingTrack ("Play Ring Track Alpha", Range(0,1)) = 0.5
        _LoopGlyphActive ("Loop Glyph Shown", Range(0,1)) = 0
        _LoopGlyphLit ("Loop Glyph Lit", Range(0,1)) = 0
        _LoopGlyphColor ("Loop Glyph Color", Color) = (1,1,1,1)
        _LoopGlyphSize ("Loop Glyph Size (fraction of max that clears the ring)", Range(0.1,1)) = 0.9
        _LoopGlyphRotation ("Loop Glyph Rotation (deg, clockwise)", Range(-90,90)) = 25
        _PlayBackColor ("Play Ring/Glyph Backing", Color) = (0.02,0.03,0.05,0.7)
        _LoopGlyphOffset ("Loop Glyph Offset", Vector) = (0,0,0,0)

        // ====================================================================
        // Button (main button shape)
        // ====================================================================
        _ButtonEnabled ("Button Enabled", Float) = 1
        _ButtonColor ("Button Color", Color) = (0.3, 0.3, 0.3, 1)
        _ButtonRenderAlpha ("Button Render Alpha", Range(0,1)) = 1
        _ButtonRenderEmissive ("Button Render Emissive", Range(0,1)) = 0

        // Button shape
        [Enum(ButtonShapeType)] _ButtonShapeType ("Button Shape Type", Int) = 0
        _ButtonShapeParam1 ("Button Shape Param1", Range(0,1)) = 0.2
        _ButtonShapeParam2 ("Button Shape Param2", Range(0,1)) = 0.5
        _ButtonShapeParam3 ("Button Shape Param3", Range(0,1)) = 0.5
        _ButtonShapeRotation ("Button Shape Rotation", Range(-180,180)) = 0
        _ButtonPadding ("Button Padding", Range(0.0, 1.5)) = 0.3
        _ButtonRoundness ("Button Roundness", Range(0,1)) = 0
        _ButtonShapeTexLayer ("Button Shape Tex Layer", Float) = -1
        _ButtonShapeTexScale ("Button Shape Tex Scale", Vector) = (1, 1, 0, 0)

        // Button bevel
        _ButtonBevelEnabled ("Button Bevel Enabled", Float) = 0
        _ButtonBevelDepth ("Button Bevel Depth", Range(-1.0, 1.0)) = 0.2
        _ButtonBevelSmoothness ("Button Bevel Smoothness", Range(0.001, 1.0)) = 0.02
        _ButtonBevelDistance ("Button Bevel Distance", Range(0.001, 1.0)) = 0.1
        _ButtonFaceSmoothness ("Button Face Smoothness", Range(-1.0, 1.0)) = 0.0
        _ButtonBevelProfileType ("Button Bevel Profile Type", Int) = 0
        _ButtonBevelProfileSharpness ("Button Bevel Profile Sharpness", Range(0, 1)) = 0.5

        // Button bevel pattern
        _ButtonBevelPatternEnabled ("Button Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _ButtonBevelPatternType ("Button Bevel Pattern Type", Int) = 0
        _ButtonBevelPatternScale ("Button Bevel Pattern Scale", Range(1, 100)) = 20
        _ButtonBevelPatternIntensity ("Button Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _ButtonBevelPatternContrast ("Button Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _ButtonBevelPatternSpecularEffect ("Button Bevel Pattern Specular Effect", Range(0, 2)) = 1.0
        _ButtonBevelPatternRoughnessEffect ("Button Bevel Pattern Roughness Effect", Range(0, 2)) = 0.3
        _ButtonBevelPatternParam1 ("Button Bevel Pattern Detail", Range(0, 1)) = 0.5
        _ButtonBevelPatternParam2 ("Button Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _ButtonBevelPatternParam3 ("Button Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Button bevel pattern color
        _ButtonBevelPatternColorEnabled ("Button Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _ButtonBevelPatternColorType ("Button Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _ButtonBevelPatternColorMode ("Button Bevel Pattern Color Mode", Int) = 1
        [IntRange] _ButtonBevelPatternColorUsed ("Button Bevel Pattern Color Used", Range(2, 4)) = 2
        _ButtonBevelPatternColorA ("Button Bevel Pattern Color A", Color) = (1,1,1,1)
        _ButtonBevelPatternColorB ("Button Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _ButtonBevelPatternColorC ("Button Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _ButtonBevelPatternColorD ("Button Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Button bevel gradient
        _ButtonBevelGradientEnabled ("Button Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _ButtonBevelGradientType ("Button Bevel Gradient Type", Int) = 1
        _ButtonBevelGradientColorA ("Button Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _ButtonBevelGradientColorB ("Button Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _ButtonBevelGradientColorC ("Button Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _ButtonBevelGradientColorD ("Button Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _ButtonBevelGradientDirection ("Button Bevel Gradient Direction", Vector) = (1, 0, 0, 0)
        _ButtonBevelGradientSpeed ("Button Bevel Gradient Speed", Float) = 1.0
        _ButtonBevelGradientScale ("Button Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _ButtonBevelGradientOffset ("Button Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _ButtonBevelGradientColorUsed ("Button Bevel Gradient Color Used", Range(2, 4)) = 4

        // Button rim bevel
        _ButtonRimEnabled ("Button Rim Bevel Enabled", Float) = 0
        _ButtonRimDepth ("Button Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _ButtonRimWidth ("Button Rim Bevel Width", Range(0.001, 1.0)) = 0.02
        _ButtonRimSmoothness ("Button Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01

        // Button pattern
        _ButtonPatternEnabled ("Button Pattern Enabled", Float) = 0
        [Enum(PatternType)] _ButtonPatternType ("Button Pattern Type", Int) = 0
        _ButtonPatternScale ("Button Pattern Scale", Range(1, 100)) = 20
        _ButtonPatternIntensity ("Button Pattern Intensity", Range(0, 1)) = 0.3
        _ButtonPatternContrast ("Button Pattern Contrast", Range(0.1, 5)) = 1.5
        _ButtonPatternSpecularEffect ("Button Pattern Specular Effect", Range(0, 2)) = 1.0
        _ButtonPatternRoughnessEffect ("Button Pattern Roughness Effect", Range(0, 2)) = 0.3
        _ButtonPatternRotateEnabled ("Button Pattern Rotate Enabled", Float) = 0
        _ButtonPatternModEnabled ("Button Pattern Mod Enabled", Float) = 0
        _ButtonPatternModAmount ("Button Pattern Mod Amount", Range(0, 90)) = 20
        _ButtonPatternModFrequency ("Button Pattern Mod Frequency", Range(0.1, 10)) = 1
        _ButtonPatternOffset ("Button Pattern Offset", Range(-180, 180)) = 0
        _ButtonPatternParam1 ("Button Pattern Detail", Range(0, 1)) = 0.5
        _ButtonPatternParam2 ("Button Pattern Distortion", Range(0, 1)) = 0.5
        _ButtonPatternParam3 ("Button Pattern Blend", Range(0, 1)) = 0.5

        // Button pattern color
        _ButtonPatternColorEnabled ("Button Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _ButtonPatternColorType ("Button Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _ButtonPatternColorMode ("Button Pattern Color Mode", Int) = 1
        [IntRange] _ButtonPatternColorUsed ("Button Pattern Color Used", Range(2, 4)) = 2
        _ButtonPatternColorA ("Button Pattern Color A", Color) = (1,1,1,1)
        _ButtonPatternColorB ("Button Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _ButtonPatternColorC ("Button Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _ButtonPatternColorD ("Button Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Button gradient
        _ButtonGradientEnabled ("Button Gradient Enabled", Float) = 0
        [Enum(GradientType)] _ButtonGradientType ("Button Gradient Type", Int) = 0
        _ButtonGradientColorA ("Button Gradient Color A", Color) = (1, 0, 0, 1)
        _ButtonGradientColorB ("Button Gradient Color B", Color) = (0, 1, 0, 1)
        _ButtonGradientColorC ("Button Gradient Color C", Color) = (0, 0, 1, 1)
        _ButtonGradientColorD ("Button Gradient Color D", Color) = (1, 1, 0, 1)
        _ButtonGradientDirection ("Button Gradient Direction", Vector) = (1, 0, 0, 0)
        _ButtonGradientSpeed ("Button Gradient Speed", Float) = 1.0
        _ButtonGradientScale ("Button Gradient Scale", Range(0.1, 5)) = 1.0
        _ButtonGradientOffset ("Button Gradient Offset", Range(-2, 2)) = 0.0
        _ButtonGlobalBlend ("Button Global Blend", Range(0, 1)) = 0.0
        _ButtonGlobalIntensity ("Button Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _ButtonGradientColorUsed ("Button Gradient Color Used", Range(2, 4)) = 4

        // Button face (inner face area: controls rendering and optional custom shape)
        _ButtonFaceEnabled ("Button Face Enabled", Float) = 1
        _ButtonFaceShapeEnabled ("Button Face Shape Enabled", Float) = 0
        [Enum(ButtonShapeType)] _ButtonFaceShapeType ("Button Face Shape Type", Int) = 0
        _ButtonFaceShapeParam1 ("Button Face Shape Param1", Range(0,1)) = 0.2
        _ButtonFaceShapeParam2 ("Button Face Shape Param2", Range(0,1)) = 0.5
        _ButtonFaceShapeParam3 ("Button Face Shape Param3", Range(0,1)) = 0.5
        _ButtonFaceShapeRotation ("Button Face Shape Rotation", Range(-180,180)) = 0
        _ButtonFaceSize ("Button Face Size", Range(0.01, 1.0)) = 0.8
        _ButtonFaceShapeTexLayer ("Button Face Shape Tex Layer", Float) = -1
        _ButtonFaceShapeTexScale ("Button Face Shape Tex Scale", Vector) = (1, 1, 0, 0)

        // ====================================================================
        // Icon (indicator on button face)
        // ====================================================================
        _IconEnabled ("Icon Enabled", Float) = 0
        _IconColor ("Icon Color", Color) = (1, 1, 1, 1)
        _IconRenderAlpha ("Icon Render Alpha", Range(0,1)) = 1
        _IconRenderEmissive ("Icon Render Emissive", Range(0,1)) = 0
        _IconShapeType ("Icon Shape Type", Float) = 0
        // 2.0, not 1.0: _IconWidth is in half-extents of the SHORT axis, so a mark
        // measured against the button's body needs more than 1 — and Unity CLAMPS a
        // Range property on SetFloat, so the old ceiling silently shrank every mark.
        _IconWidth ("Icon Width", Range(0.01, 2.0)) = 0.1
        _IconHeight ("Icon Height", Range(0.01, 2.0)) = 0.1
        _IconShapeParam1 ("Icon Shape Param1", Range(0,1)) = 0.5
        _IconShapeParam2 ("Icon Shape Param2", Range(0,1)) = 0.5
        _IconShapeParam3 ("Icon Shape Param3", Range(0,1)) = 0.5
        _IconShapeRotation ("Icon Shape Rotation", Range(-180,180)) = 0
        _IconOffset ("Icon Offset", Vector) = (0, 0, 0, 0)
        _IconShapeTexLayer ("Icon Shape Tex Layer", Float) = -1
        _IconShapeTexScale ("Icon Shape Tex Scale", Vector) = (1, 1, 0, 0)

        // Icon bevel
        _IconBevelEnabled ("Icon Bevel Enabled", Float) = 0
        _IconBevelDepth ("Icon Bevel Depth", Range(-1.0, 1.0)) = 0.2
        _IconBevelSmoothness ("Icon Bevel Smoothness", Range(0.001, 1.0)) = 0.02
        _IconBevelDistance ("Icon Bevel Distance", Range(0.001, 1.0)) = 0.1
        _IconFaceSmoothness ("Icon Face Smoothness", Range(-1.0, 1.0)) = 0.0

        // Icon pattern
        _IconPatternEnabled ("Icon Pattern Enabled", Float) = 0
        [Enum(PatternType)] _IconPatternType ("Icon Pattern Type", Int) = 0
        _IconPatternScale ("Icon Pattern Scale", Range(1, 100)) = 20
        _IconPatternIntensity ("Icon Pattern Intensity", Range(0, 1)) = 0.3
        _IconPatternContrast ("Icon Pattern Contrast", Range(0.1, 5)) = 1.5
        _IconPatternSpecularEffect ("Icon Pattern Specular Effect", Range(0, 2)) = 1.0
        _IconPatternRoughnessEffect ("Icon Pattern Roughness Effect", Range(0, 2)) = 0.3
        _IconPatternRotateEnabled ("Icon Pattern Rotate Enabled", Float) = 0
        _IconPatternModEnabled ("Icon Pattern Mod Enabled", Float) = 0
        _IconPatternModAmount ("Icon Pattern Mod Amount", Range(0, 90)) = 20
        _IconPatternModFrequency ("Icon Pattern Mod Frequency", Range(0.1, 10)) = 1
        _IconPatternOffset ("Icon Pattern Offset", Range(-180, 180)) = 0
        _IconPatternParam1 ("Icon Pattern Detail", Range(0, 1)) = 0.5
        _IconPatternParam2 ("Icon Pattern Distortion", Range(0, 1)) = 0.5
        _IconPatternParam3 ("Icon Pattern Blend", Range(0, 1)) = 0.5

        // Icon pattern color
        _IconPatternColorEnabled ("Icon Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _IconPatternColorType ("Icon Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _IconPatternColorMode ("Icon Pattern Color Mode", Int) = 1
        [IntRange] _IconPatternColorUsed ("Icon Pattern Color Used", Range(2, 4)) = 2
        _IconPatternColorA ("Icon Pattern Color A", Color) = (1,1,1,1)
        _IconPatternColorB ("Icon Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _IconPatternColorC ("Icon Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _IconPatternColorD ("Icon Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Icon gradient
        _IconGradientEnabled ("Icon Gradient Enabled", Float) = 0
        [Enum(GradientType)] _IconGradientType ("Icon Gradient Type", Int) = 0
        _IconGradientColorA ("Icon Gradient Color A", Color) = (1, 0, 0, 1)
        _IconGradientColorB ("Icon Gradient Color B", Color) = (0, 1, 0, 1)
        _IconGradientColorC ("Icon Gradient Color C", Color) = (0, 0, 1, 1)
        _IconGradientColorD ("Icon Gradient Color D", Color) = (1, 1, 0, 1)
        _IconGradientDirection ("Icon Gradient Direction", Vector) = (1, 0, 0, 0)
        _IconGradientSpeed ("Icon Gradient Speed", Float) = 1.0
        _IconGradientScale ("Icon Gradient Scale", Range(0.1, 5)) = 1.0
        _IconGradientOffset ("Icon Gradient Offset", Range(-2, 2)) = 0.0
        _IconGlobalBlend ("Icon Global Blend", Range(0, 1)) = 0.0
        _IconGlobalIntensity ("Icon Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _IconGradientColorUsed ("Icon Gradient Color Used", Range(2, 4)) = 4

        // Icon rim bevel
        _IconRimEnabled ("Icon Rim Bevel Enabled", Float) = 0
        _IconRimDepth ("Icon Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _IconRimWidth ("Icon Rim Bevel Width", Range(0.001, 0.1)) = 0.02
        _IconRimSmoothness ("Icon Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01

        // ====================================================================
        // Edge indent (around button boundary)
        // ====================================================================
        _EdgeEnabled ("Edge Enabled", Float) = 0
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 0.5)
        _EdgeRenderAlpha ("Edge Render Alpha", Range(0,1)) = 1
        _EdgeRenderEmissive ("Edge Render Emissive", Range(0,1)) = 0
        _EdgeWidth ("Edge Width", Range(0.001, 0.2)) = 0.03
        _EdgeSoftness ("Edge Softness", Range(0, 1)) = 0.5
        _EdgeIntensity ("Edge Intensity", Range(0, 2)) = 1.0
        _EdgeInset ("Edge Inset", Range(-0.1, 0.1)) = 0.0

        // Edge gradient
        _EdgeGradientEnabled ("Edge Gradient Enabled", Float) = 0
        [Enum(GradientType)] _EdgeGradientType ("Edge Gradient Type", Int) = 0
        _EdgeGradientColorA ("Edge Gradient Color A", Color) = (1, 1, 1, 1)
        _EdgeGradientColorB ("Edge Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _EdgeGradientColorC ("Edge Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _EdgeGradientColorD ("Edge Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _EdgeGradientDirection ("Edge Gradient Direction", Vector) = (1, 0, 0, 0)
        _EdgeGradientSpeed ("Edge Gradient Speed", Float) = 1.0
        _EdgeGradientScale ("Edge Gradient Scale", Range(0.1, 5)) = 1.0
        _EdgeGradientOffset ("Edge Gradient Offset", Range(-2, 2)) = 0.0
        _EdgeGlobalBlend ("Edge Global Blend", Range(0, 1)) = 0.0
        _EdgeGlobalIntensity ("Edge Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _EdgeGradientColorUsed ("Edge Gradient Color Used", Range(2, 4)) = 4

        // ====================================================================
        // Border (cut-in border at canvas edge)
        // ====================================================================
        _BorderEnabled ("Border Enabled", Float) = 0
        _BorderColor ("Border Color", Color) = (0, 0, 0, 0.3)
        _BorderRenderAlpha ("Border Render Alpha", Range(0,1)) = 1
        _BorderRenderEmissive ("Border Render Emissive", Range(0,1)) = 0
        _BorderWidth ("Border Width", Range(0.001, 0.2)) = 0.05
        _BorderSoftness ("Border Softness", Range(0, 0.2)) = 0.02
        _BorderIntensity ("Border Intensity", Range(0, 2)) = 1.0

        // Border gradient
        _BorderGradientEnabled ("Border Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BorderGradientType ("Border Gradient Type", Int) = 0
        _BorderGradientColorA ("Border Gradient Color A", Color) = (1, 1, 1, 1)
        _BorderGradientColorB ("Border Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _BorderGradientColorC ("Border Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _BorderGradientColorD ("Border Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _BorderGradientDirection ("Border Gradient Direction", Vector) = (1, 0, 0, 0)
        _BorderGradientSpeed ("Border Gradient Speed", Float) = 1.0
        _BorderGradientScale ("Border Gradient Scale", Range(0.1, 5)) = 1.0
        _BorderGradientOffset ("Border Gradient Offset", Range(-2, 2)) = 0.0
        _BorderGlobalBlend ("Border Global Blend", Range(0, 1)) = 0.0
        _BorderGlobalIntensity ("Border Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _BorderGradientColorUsed ("Border Gradient Color Used", Range(2, 4)) = 4

        // ====================================================================

        // Receive shadows cast by other widgets/panels through the shared buffer.
        _ReceiveSceneShadows ("Receive Scene Shadows", Float) = 1

        // THE RING FALLOFF — Edge and Border are the same band now (see UIRingMask).
        // 0 = flat: solid across the band, soft only where it terminates. A drawn ring — a
        //     hover/press outline, a glow, a colour the app swaps at runtime.
        // 1 = graded: strongest against the shape, gone by Width. A recess — the widget is
        //     sitting in a cutout and the faceplate is dark right at the lip.
        // The defaults keep each component looking exactly as it did before they were merged.
        _EdgeFalloff ("Edge Falloff (0 flat ring, 1 graded recess)", Range(0, 1)) = 1
        _BorderInset ("Border Inset", Range(-0.5, 0.5)) = 0
        _BorderFalloff ("Border Falloff (0 flat ring, 1 graded recess)", Range(0, 1)) = 0

        // Shadows
        // ====================================================================
        // External shadows (behind button)
        _LightingShadow1Enabled ("Shadow 1 Enabled", Float) = 0
        _LightingShadow1Color ("Shadow 1 Color", Color) = (0, 0, 0, 0.5)
        _LightingShadow1Blur ("Shadow 1 Blur (softness at contact)", Range(0, 1)) = 0.3
        _LightingShadow1Distance ("Shadow 1 Distance", Range(0, 0.2)) = 0.02
        _LightingShadow1BlurFactor ("Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow1Intensity ("Shadow 1 Intensity", Range(0, 2)) = 1.0

        _LightingShadow2Enabled ("Shadow 2 Enabled", Float) = 0
        _LightingShadow2Color ("Shadow 2 Color", Color) = (0, 0, 0, 0.3)
        _LightingShadow2Blur ("Shadow 2 Blur (softness at contact)", Range(0, 1)) = 0.3
        _LightingShadow2Distance ("Shadow 2 Distance", Range(0, 0.2)) = 0.02
        _LightingShadow2BlurFactor ("Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow2Intensity ("Shadow 2 Intensity", Range(0, 2)) = 1.0

        _LightingShadow3Enabled ("Shadow 3 Enabled", Float) = 0
        _LightingShadow3Color ("Shadow 3 Color", Color) = (0, 0, 0, 0.3)
        _LightingShadow3Blur ("Shadow 3 Blur (softness at contact)", Range(0, 1)) = 0.3
        _LightingShadow3Distance ("Shadow 3 Distance", Range(0, 0.2)) = 0.02
        _LightingShadow3BlurFactor ("Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow3Intensity ("Shadow 3 Intensity", Range(0, 2)) = 1.0

        // Button shadows (cast by 3D button shape)
        _ButtonShadow1Enabled ("Button Shadow 1 Enabled", Float) = 0
        _ButtonShadow1Color ("Button Shadow 1 Color", Color) = (0, 0, 0, 0.5)
        _ButtonShadow1Blur ("Button Shadow 1 Blur (softness at contact)", Range(0, 1)) = 0.2
        _ButtonShadow1Distance ("Button Shadow 1 Distance", Range(0, 0.2)) = 0.01
        _ButtonShadow1BlurFactor ("Button Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _ButtonShadow1Intensity ("Button Shadow 1 Intensity", Range(0, 2)) = 1.0
        _ButtonShadow1Cast ("Button Shadow 1 Cast", Range(0, 2)) = 1.0

        _ButtonShadow2Enabled ("Button Shadow 2 Enabled", Float) = 0
        _ButtonShadow2Color ("Button Shadow 2 Color", Color) = (0, 0, 0, 0.3)
        _ButtonShadow2Blur ("Button Shadow 2 Blur (softness at contact)", Range(0, 1)) = 0.2
        _ButtonShadow2Distance ("Button Shadow 2 Distance", Range(0, 0.2)) = 0.01
        _ButtonShadow2BlurFactor ("Button Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _ButtonShadow2Intensity ("Button Shadow 2 Intensity", Range(0, 2)) = 1.0
        _ButtonShadow2Cast ("Button Shadow 2 Cast", Range(0, 2)) = 1.0

        _ButtonShadow3Enabled ("Button Shadow 3 Enabled", Float) = 0
        _ButtonShadow3Color ("Button Shadow 3 Color", Color) = (0, 0, 0, 0.3)
        _ButtonShadow3Blur ("Button Shadow 3 Blur (softness at contact)", Range(0, 1)) = 0.2
        _ButtonShadow3Distance ("Button Shadow 3 Distance", Range(0, 0.2)) = 0.01
        _ButtonShadow3BlurFactor ("Button Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _ButtonShadow3Intensity ("Button Shadow 3 Intensity", Range(0, 2)) = 1.0
        _ButtonShadow3Cast ("Button Shadow 3 Cast", Range(0, 2)) = 1.0

        // ====================================================================
        // Lighting (3 directional lights)
        // ====================================================================
        _LightingAmbient ("Ambient", Range(0, 2)) = 0.3
        [ToggleUI] _LightingUnlit ("Unlit (skip lighting)", Float) = 0




        // Aspect ratio override — set from C# for preview tools or fixed-aspect quads.
        // 0 = auto-detect via UV screen-space derivatives (default; works for UGUI, UIElements,
        //     and any editor preview that renders to a correctly-sized non-square RT).
        // >0 = force this W/H ratio (e.g. 2.0 for 2:1 wide). Use from a MaterialEditor
        //     preview pane that renders to a square RT and stretches the result.
        _AspectRatio ("Aspect Ratio Override (0=auto)", Float) = 0

        // Shadow pass: 0 = widget quad (renders everything EXCEPT shadows — they'd clip at
        // this quad's edge); 1 = shadow quad (renders ONLY the shadows, on a backing quad
        // _ShadowUvExpand× the widget's size so shadows have room to extend — see
        // MaterialStateUiControls/WidgetShadowQuad.cs). Same shader both ways, so the
        // shadow math/appearance is IDENTICAL to the original in-quad rendering.
        _ShadowPassMode ("Shadow Pass Mode (0=widget, 1=shadow quad)", Float) = 0
        _ShadowUvExpand ("Shadow Quad UV Expand", Float) = 1

        // Global light overrides
        _Position ("UI Position", Vector) = (0, 0, 0, 0)

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
            #include "CG/SDF/SDFButtonUniforms.cginc"
            #include "CG/SDF/SDFPlayRing.cginc"

            float _ReceiveSceneShadows;
            float _EdgeFalloff;
            float _BorderInset;
            float _BorderFalloff;
            float _ShadowPassMode;
            float _ShadowUvExpand;

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                float4 screenPos : TEXCOORD2; // for sampling the shared cross-widget shadow buffer
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

            #include "CG/SDF/SDFButtonLayers.cginc"

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                // Shadow quad: this quad is _ShadowUvExpand× the widget's size, centered on it.
                // Remap uv into the widget's own uv space so every SDF keeps its exact
                // position/scale and shadows can extend past where the widget quad would end.
                // (The remap scales both axes equally, so ddx/ddy aspect detection still works.)
                if (_ShadowPassMode > 0.5) uv = (uv - 0.5) * _ShadowUvExpand + 0.5;
                float2 center = float2(0.5, 0.5);

                // Aspect ratio: use _AspectRatio override if set (> 0), otherwise auto-detect
                // from UV screen-space derivatives (ddx/ddy). The auto-detect works for UGUI,
                // UIElements, and any preview that renders to a correctly-sized non-square RT.
                // Set _AspectRatio from C# in preview tools that render to a square RT and
                // then display it stretched (e.g. material state designer preview panes).
                float rectAspect = (_AspectRatio > 0.001)
                    ? _AspectRatio
                    : abs(ddy(uv.y)) / max(0.0001, abs(ddx(uv.x)));
                float2 aspectScale = float2(max(rectAspect, 1.0), max(1.0 / rectAspect, 1.0));

                float2 pos = (uv - center) * 2.0 * aspectScale; // Equi-pixel space

                // Isotropic UV for pattern sampling: normalise UV so one unit maps to the same
                // screen-pixel count in X and Y. Dividing (uv-0.5) by aspectScale brings the
                // longer axis back to the same fractional range as the shorter axis.
                // This prevents patterns from stretching on non-square rects.
                float2 uvIso = (uv - center) / float2(aspectScale.x, aspectScale.y) + center;

                // Button shape parameters — constant-margin (nine-slice) model:
                // _ButtonPadding is the equi-pixel margin removed from each side.
                // 0 = button fills edge-to-edge; larger values inset on all sides equally.
                // Because equi-pixel units are isotropic (1 unit = H/2 screen-pixels regardless
                // of aspect ratio), the margin stays constant in screen-pixels as the rect stretches.
                // Only the straight middle sections grow; corners stay fixed distance from quad edges.
                float bodyHalfW = max(0.001, aspectScale.x - _ButtonPadding);
                float bodyHalfH = max(0.001, aspectScale.y - _ButtonPadding);
                int bodyShapeType = (int)_ButtonShapeType;

                // Rotate position for button shape if needed
                float2 bodyPos = pos;
                if (abs(_ButtonShapeRotation) > 0.001) {
                    bodyPos = rotate2D(pos, _ButtonShapeRotation * (PI / 180.0));
                }

                // Create lights (global override: direction from 2D UI positions)
                // The three scene lights. No per-material lights exist any more — see UILighting.cginc.
                // Resolved ONCE here; every shadow call below reads these locals instead of re-expanding
                // the macro (which is what made this fragment program so expensive to compile).
                UILight light1 = UI_LIGHT_1;
                UILight light2 = UI_LIGHT_2;
                UILight light3 = UI_LIGHT_3;
                float3 lightDir1 = light1.direction;
                float3 lightDir2 = light2.direction;
                float3 lightDir3 = light3.direction;

                float4 finalColor = float4(0, 0, 0, 0);
                float3 emissiveAccum = float3(0, 0, 0);
                float time = _Time.y;

                // Bevel geometry for shadows
                float bevelDist = (_ButtonBevelEnabled > 0.5) ? _ButtonBevelDistance : 0.0;
                float bevelDepthRaw = (_ButtonBevelEnabled > 0.5) ? abs(_ButtonBevelDepth) : 0.0;
                // Use the SHORT dimension so bevel depth and pseudo-height stay constant in
                // screen-pixels as the rect stretches (nine-slice behaviour).
                // maxDim is intentionally the MIN — the short side doesn't grow with aspect ratio.
                float maxDim = min(bodyHalfW, bodyHalfH);
                float pseudoHeight = maxDim * lerp(0.05, 0.5, bevelDepthRaw);
                float rimWidth = (_ButtonRimEnabled > 0.5) ? _ButtonRimWidth : 0.0;
                float faceInset = rimWidth + bevelDist;

                // ============================================================
                // 1. Edge indent (behind everything)
                // (skipped on the shadow quad — it renders shadows only)
                // ============================================================
                if (_EdgeEnabled > 0.5 && _ShadowPassMode < 0.5) {
                    float3 edgeBaseColor = _EdgeColor.rgb;
                    if (_EdgeGradientEnabled > 0.5) {
                        float4 gradientColor = CalculateGradient(uv, _EdgeGradientColorA, _EdgeGradientColorB,
                                                                _EdgeGradientColorC, _EdgeGradientColorD,
                                                                _EdgeGradientDirection, _EdgeGradientType,
                                                                _EdgeGradientSpeed, _EdgeGradientScale,
                                                                _EdgeGradientOffset, time, _EdgeGradientColorUsed);
                        edgeBaseColor = lerp(edgeBaseColor, gradientColor.rgb, gradientColor.a);
                    }
                    if (_EdgeGlobalBlend > 0.0) {
                        float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                        edgeBaseColor = lerp(edgeBaseColor, globalColor.rgb, _EdgeGlobalBlend * _EdgeGlobalIntensity);
                    }

                    float indentAlpha = calculateButtonEdgeIndent(uv, bodyPos, _EdgeWidth, _EdgeSoftness,
                                                                   bodyHalfW, bodyHalfH, bodyShapeType,
                                                                   _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3,
                                                                   _EdgeInset, _EdgeFalloff);
                    if (indentAlpha > 0.001) {
                        float edgeMask = indentAlpha * _EdgeIntensity;
                        buttonCompositeOver(finalColor, edgeBaseColor, edgeMask * _EdgeRenderAlpha);
                        emissiveAccum += edgeBaseColor * edgeMask * _EdgeRenderEmissive;
                    }
                }

                // ============================================================
                // 2/3. External + body shadows — SHADOW QUAD ONLY
                // ============================================================
                // Exact original shadow rendering, unchanged — it just runs on the expanded
                // backing quad (_ShadowPassMode=1, driven by WidgetShadowQuad) instead of the
                // widget's own quad, so it can extend past the widget without being clipped.
                // The widget quad (_ShadowPassMode=0) skips this and renders everything else.
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
                    if (_LightingShadow1Enabled > 0.5) {
                        float shadowAlpha = calculateButtonExternalShadow(uv, lightDir1, _LightingShadow1Blur, _LightingShadow1Distance, _LightingShadow1BlurFactor,
                                                                           bodyHalfW, bodyHalfH, bodyShapeType, _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3, aspectScale, _ButtonShapeRotation * (PI / 180.0));
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _LightingShadow1Color.rgb, _LightingShadow1Color.a * shadowAlpha * _LightingShadow1Intensity);
                        }
                    }
                    if (_LightingShadow2Enabled > 0.5) {
                        float shadowAlpha = calculateButtonExternalShadow(uv, lightDir2, _LightingShadow2Blur, _LightingShadow2Distance, _LightingShadow2BlurFactor,
                                                                           bodyHalfW, bodyHalfH, bodyShapeType, _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3, aspectScale, _ButtonShapeRotation * (PI / 180.0));
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _LightingShadow2Color.rgb, _LightingShadow2Color.a * shadowAlpha * _LightingShadow2Intensity);
                        }
                    }
                    if (_LightingShadow3Enabled > 0.5) {
                        float shadowAlpha = calculateButtonExternalShadow(uv, lightDir3, _LightingShadow3Blur, _LightingShadow3Distance, _LightingShadow3BlurFactor,
                                                                           bodyHalfW, bodyHalfH, bodyShapeType, _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3, aspectScale, _ButtonShapeRotation * (PI / 180.0));
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _LightingShadow3Color.rgb, _LightingShadow3Color.a * shadowAlpha * _LightingShadow3Intensity);
                        }
                    }

                    float shadowFaceHole = (_ButtonFaceEnabled < 0.5) ? 1.0 : 0.0;
                    if (_ButtonShadow1Enabled > 0.5) {
                        float shadowAlpha = calculateButtonBodyShadow(uv, lightDir1,
                            _ButtonShadow1Blur, _ButtonShadow1Distance, _ButtonShadow1BlurFactor, _ButtonShadow1Cast,
                            bodyHalfW, bodyHalfH, bodyShapeType, _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3,
                            faceInset, pseudoHeight, aspectScale, _ButtonShapeRotation * (PI / 180.0), shadowFaceHole);
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _ButtonShadow1Color.rgb, _ButtonShadow1Color.a * shadowAlpha * _ButtonShadow1Intensity);
                        }
                    }
                    if (_ButtonShadow2Enabled > 0.5) {
                        float shadowAlpha = calculateButtonBodyShadow(uv, lightDir2,
                            _ButtonShadow2Blur, _ButtonShadow2Distance, _ButtonShadow2BlurFactor, _ButtonShadow2Cast,
                            bodyHalfW, bodyHalfH, bodyShapeType, _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3,
                            faceInset, pseudoHeight, aspectScale, _ButtonShapeRotation * (PI / 180.0), shadowFaceHole);
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _ButtonShadow2Color.rgb, _ButtonShadow2Color.a * shadowAlpha * _ButtonShadow2Intensity);
                        }
                    }
                    if (_ButtonShadow3Enabled > 0.5) {
                        float shadowAlpha = calculateButtonBodyShadow(uv, lightDir3,
                            _ButtonShadow3Blur, _ButtonShadow3Distance, _ButtonShadow3BlurFactor, _ButtonShadow3Cast,
                            bodyHalfW, bodyHalfH, bodyShapeType, _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3,
                            faceInset, pseudoHeight, aspectScale, _ButtonShapeRotation * (PI / 180.0), shadowFaceHole);
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _ButtonShadow3Color.rgb, _ButtonShadow3Color.a * shadowAlpha * _ButtonShadow3Intensity);
                        }
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
                // Self-shadow — the IN-QUAD half of this widget's own cast shadow.
                //
                // The shared buffer holds only the OUTSIDE half (see the cast-shadow block at
                // the top of frag), precisely so this widget can read that buffer for its
                // neighbours' shadows without darkening its own face with its own. That leaves
                // the inside half to the widget itself, and this is where it lands: on the
                // siblings it has already drawn, before the element that casts it.
                //
                // `castShadow` was already scaled by the in-quad complement up there, so this
                // is just the application — and it is the SAME layer the backing quad emits,
                // so the two halves are the same silhouette by construction.
                // ============================================================
                if (castShadow.a > 0.002) {
                    UIApplySelfShadow(finalColor, castShadow.rgb / max(castShadow.a, 1e-4), castShadow.a);
                }

                // ============================================================
                // 4. Button rendering (main button shape)
                // ============================================================
                if (_ButtonEnabled > 0.5) {
                    // Evaluate body SDF
                    float bodyDist = getButtonSDF(bodyPos, bodyHalfW, bodyHalfH, bodyShapeType,
                                                  _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3);

                    // Face SDF (inner boundary for bevel region)
                    // _ButtonFaceShapeEnabled: face gets its own SDF shape
                    // _ButtonFaceEnabled: whether the face area renders at all
                    float topFaceDist = bodyDist;
                    if (_ButtonFaceShapeEnabled > 0.5) {
                        // Nine-slice face: constant pixel-space margin on all sides.
                        // Proportional scaling (bodyHalfW * faceSize) gives wider bevel on the
                        // long axis — instead subtract a fixed equi-pixel margin so all four
                        // sides shrink by the same number of screen pixels.
                        float faceMargin = (1.0 - saturate(_ButtonFaceSize)) * min(bodyHalfW, bodyHalfH);
                        float faceHalfW = max(0.001, bodyHalfW - faceMargin);
                        float faceHalfH = max(0.001, bodyHalfH - faceMargin);
                        float2 facePos = bodyPos;
                        if (abs(_ButtonFaceShapeRotation) > 0.001) {
                            facePos = rotate2D(bodyPos, _ButtonFaceShapeRotation * (PI / 180.0));
                        }
                        float faceShapeDist = getButtonSDF(facePos, faceHalfW, faceHalfH, (int)_ButtonFaceShapeType,
                                                            _ButtonFaceShapeParam1, _ButtonFaceShapeParam2, _ButtonFaceShapeParam3,
                                                            _ButtonFaceShapeTexLayer, _ButtonFaceShapeTexScale);
                        topFaceDist = faceShapeDist + bevelDist;
                    } else {
                        topFaceDist = bodyDist + faceInset;
                    }

                    // Union for silhouette (face shape may extend past body)
                    float buttonDist;
                    if (_ButtonFaceShapeEnabled > 0.5) {
                        float rawFaceDist = topFaceDist - bevelDist;
                        buttonDist = min(bodyDist, rawFaceDist);
                    } else {
                        buttonDist = bodyDist;
                    }

                    float bodyAA = fwidth(buttonDist) * 0.75;
                    float bodyMask = smoothstep(bodyAA, -bodyAA, buttonDist);

                    // When face is disabled, punch out the face zone (make it transparent)
                    // so only the rim/bevel ring around the edge renders.
                    // Guard: if faceInset is zero (rim and bevel both off) the face boundary
                    // coincides with the body boundary, causing both smoothsteps to fire on the
                    // same pixels and leave a ghost ring. In that case just hide everything.
                    if (_ButtonFaceEnabled < 0.5) {
                        if (faceInset < 0.0001) {
                            bodyMask = 0.0; // No rim/bevel ring to show; suppress completely
                        } else if (bodyMask > 0.001) {
                            float faceAA = fwidth(topFaceDist) * 0.75;
                            float faceMask = smoothstep(-faceAA, faceAA, topFaceDist); // 0 inside face, 1 outside
                            bodyMask *= faceMask;
                        }
                    }

                    if (bodyMask > 0.001) {
                        // Create body component
                        UIComponent bodyComponent = CreateUIComponent(
                            _ButtonColor, _ButtonRenderAlpha,
                            _ButtonBevelDepth, _ButtonBevelSmoothness, _ButtonBevelDistance, _ButtonFaceSmoothness,
                            _ButtonGradientColorA, _ButtonGradientColorB, _ButtonGradientColorC, _ButtonGradientColorD,
                            _ButtonGradientDirection, _ButtonGradientSpeed, _ButtonGradientScale, _ButtonGradientOffset,
                            _ButtonGlobalBlend, _ButtonGlobalIntensity, _ButtonGradientType,
                            _ButtonPatternType, _ButtonPatternScale, _ButtonPatternIntensity, _ButtonPatternContrast,
                            _ButtonPatternSpecularEffect, _ButtonPatternRoughnessEffect, _ButtonPatternRotateEnabled,
                            _ButtonPatternModEnabled, _ButtonPatternModAmount, _ButtonPatternModFrequency, _ButtonPatternOffset,
                            _ButtonPatternParam1, _ButtonPatternParam2, _ButtonPatternParam3,
                            _ButtonGradientEnabled, _ButtonPatternEnabled,
                            _ButtonPatternColorEnabled, _ButtonPatternColorMode,
                            _ButtonPatternColorType, _ButtonPatternColorUsed,
                            _ButtonPatternColorA, _ButtonPatternColorB, _ButtonPatternColorC, _ButtonPatternColorD
                        );

                        // Base color + gradient
                        float3 baseColor = bodyComponent.color.rgb;
                        if (bodyComponent.gradientEnabled > 0.5) {
                            float4 gradientColor = CalculateGradient(uv, bodyComponent.gradientColorA, bodyComponent.gradientColorB,
                                                                   bodyComponent.gradientColorC, bodyComponent.gradientColorD,
                                                                   bodyComponent.gradientDirection, bodyComponent.gradientType,
                                                                   bodyComponent.gradientSpeed, bodyComponent.gradientScale,
                                                                   bodyComponent.gradientOffset, time, _ButtonGradientColorUsed);
                            baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                        }
                        if (bodyComponent.globalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            baseColor = lerp(baseColor, globalColor.rgb, bodyComponent.globalBlend * bodyComponent.globalIntensity);
                        }

                        // Pattern
                        float specularMod;
                        float2 normalOffset;
                        float3 mainPatternedColor = ApplyMaterialPattern(baseColor, uvIso, bodyComponent,
                                                                         0.0, 0.0, specularMod, normalOffset);

                        // Bevel depth mapping (match RM's 3D bevel angle)
                        float effectiveBevelDepth = (_ButtonBevelEnabled > 0.5) ? bodyComponent.bevelDepth : 0.0;
                        float effectiveBevelDist = bodyComponent.bevelDistance;

                        if (abs(effectiveBevelDepth) > 0.0001) {
                            float depthSign = sign(effectiveBevelDepth);
                            float bevelHeightRM = maxDim * lerp(0.05, 1.0, abs(effectiveBevelDepth));
                            float bevelDistRM = max(0.0001, effectiveBevelDist);
                            float tanB = bevelHeightRM / bevelDistRM;
                            effectiveBevelDepth = depthSign * tanB / (1.0 + tanB * 0.5);
                        }

                        // Bevel SDF
                        float bevelSDF = topFaceDist;

                        // Bevel normal via screen-space SDF gradient
                        float3 faceNormal = CalculateShapeBevelNormal(bevelSDF, effectiveBevelDepth,
                                               effectiveBevelDist, bodyComponent.bevelSmoothness, bodyComponent.fillFaceSmoothness,
                                               _ButtonBevelProfileType, _ButtonBevelProfileSharpness, aspectScale);

                        // Face shape wall normal extension
                        if (_ButtonFaceShapeEnabled > 0.5 && topFaceDist > 0.0 && bodyDist < 0.0) {
                            float approxBevelFactor = smoothstep(effectiveBevelDist,
                                max(0.0001, effectiveBevelDist - bodyComponent.bevelSmoothness), abs(bevelSDF));
                            float gapFactor = 1.0 - approxBevelFactor;
                            if (gapFactor > 0.001) {
                                float2 wallGrad = float2(ddx(bodyDist), ddy(bodyDist));
                                float wallGradLen = length(wallGrad);
                                if (wallGradLen > 0.0001) {
                                    float2 inwardDir = -wallGrad / wallGradLen;
                                    float wallTilt = gapFactor * abs(effectiveBevelDepth) * 0.35;
                                    faceNormal = normalize(faceNormal + float3(inwardDir * wallTilt, 0));
                                }
                            }
                        }

                        // Bevel rendering with pattern and gradient
                        ButtonBevelRenderResult bevelResult = RenderButtonBevelWithPatternAndGradient(
                            uv, uvIso, baseColor, mainPatternedColor, faceNormal,
                            bevelSDF,
                            effectiveBevelDepth, effectiveBevelDist, bodyComponent.bevelSmoothness,
                            _ButtonBevelEnabled,
                            _ButtonBevelPatternEnabled, _ButtonBevelPatternType, _ButtonBevelPatternScale,
                            _ButtonBevelPatternIntensity, _ButtonBevelPatternContrast,
                            _ButtonBevelPatternSpecularEffect, _ButtonBevelPatternRoughnessEffect,
                            _ButtonBevelGradientEnabled, _ButtonBevelGradientType,
                            _ButtonBevelGradientColorA, _ButtonBevelGradientColorB,
                            _ButtonBevelGradientColorC, _ButtonBevelGradientColorD, _ButtonBevelGradientDirection,
                            _ButtonBevelGradientSpeed, _ButtonBevelGradientScale, _ButtonBevelGradientOffset,
                            _ButtonBevelPatternParam1, _ButtonBevelPatternParam2, _ButtonBevelPatternParam3,
                            _ButtonBevelGradientColorUsed,
                            _ButtonBevelPatternColorEnabled, _ButtonBevelPatternColorMode,
                            _ButtonBevelPatternColorType, _ButtonBevelPatternColorUsed,
                            _ButtonBevelPatternColorA, _ButtonBevelPatternColorB,
                            _ButtonBevelPatternColorC, _ButtonBevelPatternColorD,
                            time, light1, light2, light3
                        );

                        // Rim bevel — suppressed on the face surface when face shape is active
                        // Also suppressed entirely when _ButtonFaceEnabled is off (face area hidden,
                        // rim becomes an outline ring of the full button body)
                        float rimSDF = buttonDist;
                        bool faceActive = (_ButtonFaceShapeEnabled > 0.5) && (topFaceDist <= 0.0);
                        bool faceHidden = (_ButtonFaceEnabled < 0.5);
                        // When face is hidden: only render rim zone (the ring between body edge and faceInset)
                        if (faceActive) {
                            rimSDF = -1.0; // suppress rim on face surface
                        }
                        ButtonRimResult rimBevelResult = CalculateButtonRimFromSDF(
                            uv, bevelResult.litColor, bevelResult.normal, rimSDF,
                            _ButtonRimEnabled, _ButtonRimDepth, _ButtonRimWidth, _ButtonRimSmoothness,
                            light1, light2, light3, aspectScale
                        );

                        // Final lighting
                        float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor,
                                                          _LightingAmbient, specularMod, normalOffset,
                                                          light1, light2, light3);
                        buttonCompositeOver(finalColor, litColor, bodyMask * bodyComponent.alpha);
                        emissiveAccum += baseColor * bodyMask * _ButtonRenderEmissive;
                    }
                }

                // ============================================================
                // 5. Icon rendering (on top of button)
                // ============================================================
                if (_IconEnabled > 0.5) {
                    float2 iconPos = pos - _IconOffset.xy * aspectScale;
                    // Into ICON SPACE: +x right, -y up (getIconSDF's convention — case 4's
                    // "triangle pointing up" has its apex at -y, and case 100 samples its texture
                    // slice the same way). `pos` is screen space with +y up, so every asymmetric
                    // mark drew upside down here. The RM shader flips x for the same reason: its
                    // face axis runs the other way. Offsets stay in screen space either side of
                    // the flip.
                    iconPos.y = -iconPos.y;
                    if (abs(_IconShapeRotation) > 0.001) {
                        iconPos = rotate2D(iconPos, _IconShapeRotation * (PI / 180.0));
                    }

                    float iconDist = getIconSDF(iconPos, _IconShapeType, _IconWidth, _IconHeight,
                                                 _IconShapeParam1, _IconShapeParam2, _IconShapeParam3);
                    float iconAA = fwidth(iconDist) * 0.75;
                    float iconMask = smoothstep(iconAA, -iconAA, iconDist);

                    if (iconMask > 0.001) {
                        UIComponent iconComponent = CreateUIComponent(
                            _IconColor, _IconRenderAlpha,
                            _IconBevelDepth, _IconBevelSmoothness, _IconBevelDistance, _IconFaceSmoothness,
                            _IconGradientColorA, _IconGradientColorB, _IconGradientColorC, _IconGradientColorD,
                            _IconGradientDirection, _IconGradientSpeed, _IconGradientScale, _IconGradientOffset,
                            _IconGlobalBlend, _IconGlobalIntensity, _IconGradientType,
                            _IconPatternType, _IconPatternScale, _IconPatternIntensity, _IconPatternContrast,
                            _IconPatternSpecularEffect, _IconPatternRoughnessEffect, _IconPatternRotateEnabled,
                            _IconPatternModEnabled, _IconPatternModAmount, _IconPatternModFrequency, _IconPatternOffset,
                            _IconPatternParam1, _IconPatternParam2, _IconPatternParam3,
                            _IconGradientEnabled, _IconPatternEnabled,
                            _IconPatternColorEnabled, _IconPatternColorMode,
                            _IconPatternColorType, _IconPatternColorUsed,
                            _IconPatternColorA, _IconPatternColorB, _IconPatternColorC, _IconPatternColorD
                        );

                        float3 baseColor = iconComponent.color.rgb;
                        if (iconComponent.gradientEnabled > 0.5) {
                            float2 iconUV = (iconPos * 0.5 + 0.5);
                            float4 gradientColor = CalculateGradient(iconUV, iconComponent.gradientColorA, iconComponent.gradientColorB,
                                                                   iconComponent.gradientColorC, iconComponent.gradientColorD,
                                                                   iconComponent.gradientDirection, iconComponent.gradientType,
                                                                   iconComponent.gradientSpeed, iconComponent.gradientScale,
                                                                   iconComponent.gradientOffset, time, _IconGradientColorUsed);
                            baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                        }
                        if (iconComponent.globalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            baseColor = lerp(baseColor, globalColor.rgb, iconComponent.globalBlend * iconComponent.globalIntensity);
                        }

                        float specularMod;
                        float2 normalOffset;
                        float3 patternedColor = ApplyMaterialPattern(baseColor, uvIso, iconComponent, 0.0, 0.0,
                                                                   specularMod, normalOffset);

                        // Icon bevel normal via SDF gradient
                        float effectiveIconBevelDepth = (_IconBevelEnabled > 0.5) ? iconComponent.bevelDepth : 0.0;
                        float3 iconNormal = CalculateShapeBevelNormal(iconDist, effectiveIconBevelDepth,
                                               iconComponent.bevelDistance, iconComponent.bevelSmoothness, iconComponent.fillFaceSmoothness,
                                               0, 0.5);

                        // Rim bevel
                        ButtonRimResult rimResult = CalculateButtonRimFromSDF(
                            uv, patternedColor, iconNormal, iconDist,
                            _IconRimEnabled, _IconRimDepth, _IconRimWidth, _IconRimSmoothness,
                            light1, light2, light3
                        );

                        float3 litColor = ApplyUILighting(rimResult.normal, rimResult.litColor,
                                                          _LightingAmbient, specularMod, normalOffset,
                                                          light1, light2, light3);
                        buttonCompositeOver(finalColor, litColor, iconMask * iconComponent.alpha);
                        emissiveAccum += baseColor * iconMask * _IconRenderEmissive;
                    }
                }

                // ============================================================
                // 6. Border (on top of everything)
                // ============================================================
                if (_BorderEnabled > 0.5) {
                    float3 borderBaseColor = _BorderColor.rgb;
                    if (_BorderGradientEnabled > 0.5) {
                        float4 gradientColor = CalculateGradient(uv, _BorderGradientColorA, _BorderGradientColorB,
                                                                _BorderGradientColorC, _BorderGradientColorD,
                                                                _BorderGradientDirection, _BorderGradientType,
                                                                _BorderGradientSpeed, _BorderGradientScale,
                                                                _BorderGradientOffset, time, _BorderGradientColorUsed);
                        borderBaseColor = lerp(borderBaseColor, gradientColor.rgb, gradientColor.a);
                    }
                    if (_BorderGlobalBlend > 0.0) {
                        float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                        borderBaseColor = lerp(borderBaseColor, globalColor.rgb, _BorderGlobalBlend * _BorderGlobalIntensity);
                    }

                    float borderTerritory;
                    float4 borderResult = calculateButtonBorder(uv, borderBaseColor, _BorderWidth, _BorderSoftness,
                                                                bodyHalfW, bodyHalfH, bodyShapeType,
                                                                _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3,
                                                                aspectScale, borderTerritory, _BorderInset, _BorderFalloff);
                    float borderMask = borderResult.a * _BorderIntensity;

                    float borderPresence = max(_BorderRenderAlpha, _BorderRenderEmissive);
                    float effectiveTerritory = borderTerritory * borderPresence;
                    if (effectiveTerritory > 0.001) {
                        float clearFactor = 1.0 - effectiveTerritory;
                        finalColor.rgb *= clearFactor;
                        finalColor.a *= clearFactor;
                        emissiveAccum *= clearFactor;
                    }

                    if (borderMask > 0.001) {
                        buttonCompositeOver(finalColor, borderResult.rgb, borderMask * _BorderRenderAlpha);
                        emissiveAccum += borderResult.rgb * borderMask * _BorderRenderEmissive;
                    }
                }

                // ============================================================
                // 6. Play ring + loop glyph (SDFPlayRing.cginc) — see UI/SDFButtonRM
                // ============================================================
                if (_PlayRingEnabled > 0.5 || _LoopGlyphActive > 0.5) {
                    float dPad = getButtonSDF(bodyPos, bodyHalfW, bodyHalfH, bodyShapeType,
                                              _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3);
                    PlayRingApply(dPad, float2(pos.x, -pos.y), float2(bodyHalfW, bodyHalfH),
                                  faceInset, finalColor, emissiveAccum);
                }

                // Apply UI clipping
                #ifdef UNITY_UI_CLIP_RECT
                float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                finalColor *= clipMask;
                emissiveAccum *= clipMask;
                #endif

                // Multiply by vertex color
                finalColor *= IN.color;
                emissiveAccum *= IN.color.rgb;

                // Premultiplied alpha output with additive emissive
                // Receive shadows cast by every OTHER widget and panel. This button's own
                // contribution is not in the buffer at its own pixels — the shadow pass punched
                // its silhouette out — so this is other people's shadows only.
                // BEFORE the emissive add: an emissive face is its own light source.
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
