// ============================================================================
// SDFButtonRM.shader - 3D Raymarched SDF UI Button
// ============================================================================
// Raymarched version of SDFButton, following SDFKnobRM.shader's architecture.
// The body is rendered via 96-iteration sphere-march using SDF3DExtrusion.cginc
// cross-section, with surfaces classified as LIP/RIM/WALL/FACE for material.
//
// RM-SPECIFIC ADDITIONS vs SDFButton.shader:
// - _ViewTilt/_ViewAngle/_ViewFOV/_ViewShift: 3D camera perspective controls
// - _ButtonLipHeight: vertical lip at outer edge of 3D extrusion
// - Compile toggles: COMPILE_BODY, COMPILE_ICON for selective compilation
// - Hull sweep shadow casting for accurate 3D body shadows
// - Analytical normals computed from surface classification + SDF gradients
// - Self-shadow: bevel walls cast shadows onto rim/lip surfaces
//
// Shared 2D layers (Edge, Border, External Shadows) rendered identically
// to SDFButton.shader via SDFButtonLayers.cginc.
// ============================================================================

Shader "UI/SDFButtonRM"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        // Button state
        _Value ("Value (Pressed)", Range(0,1)) = 0

        // RM-specific view controls
        _ViewTilt ("View Tilt", Range(0, 10)) = 0
        _ViewAngle ("View Angle", Range(-180, 180)) = 0
        _ViewFOV ("View FOV", Range(0, 1)) = 0
        _ViewShift ("View Shift", Range(-5, 5)) = 0

        // Scene camera (§4.16 B) — a BOUNDED add-on to the authored view above. The app
        // publishes one eye point for the screen (_GlobalViewCam); these are the most it
        // may move THIS material. 0 = ignore the camera entirely.
        _ViewCamEnabled ("View Cam Enabled", Float) = 1
        _ViewCamShift ("View Cam Max Shift +/-", Range(0, 5)) = 0.6
        _ViewCamTilt ("View Cam Max Tilt +/-", Range(0, 10)) = 0.8

        // Shadow pass: 0 = widget quad (renders everything EXCEPT shadows — they'd clip at
        // this quad's edge); 1 = shadow quad (renders ONLY the shadows, on a backing quad
        // _ShadowUvExpand× the widget's size — see MaterialStateUiControls/WidgetShadowQuad.cs).
        // Same shader both ways, so the shadow math/appearance is IDENTICAL to the original.
        _ShadowPassMode ("Shadow Pass Mode (0=widget, 1=shadow quad)", Float) = 0
        _ShadowUvExpand ("Shadow Quad UV Expand", Float) = 1

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

        // RM-specific: lip extrusion
        _ButtonLipHeight ("Button Lip Height", Range(0, 1)) = 0.08

        // RM-specific: antialiasing
        _AAWidth ("AA Width", Range(0.5, 4.0)) = 1.0

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
        // Same opt-out SDFPanel has — AppShell clears it on overlay contents so a menu
        // doesn't show the shadows of whatever it is covering.
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

        // Button shadows (cast by 3D button body)
        _ButtonShadow1Enabled ("Button Shadow 1 Enabled", Float) = 0
        _ButtonShadow1Color ("Button Shadow 1 Color", Color) = (0, 0, 0, 0.5)
        _ButtonShadow1Blur ("Button Shadow 1 Blur (softness at contact)", Range(0, 1)) = 0.2
        _ButtonShadow1Distance ("Button Shadow 1 Distance", Range(0, 0.2)) = 0.01
        _ButtonShadow1BlurFactor ("Button Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _ButtonShadow1Intensity ("Button Shadow 1 Intensity", Range(0, 2)) = 1.0
        _ButtonShadow1Cast ("Button Shadow 1 Cast", Range(0, 5)) = 1.0
        // Caps how far the cast (hull-sweep) throw can push the shadow, in units of this
        // quad's own half-size (1.0 = reaches exactly to the quad edge, 2.0 = twice that,
        // matching WidgetShadowQuad's default 2x backing-quad expansion). Without this, a
        // grazing light angle (lBy -> 0) sends `ps = totalHeight*cast/lBy` toward infinity —
        // the shadow doesn't get bigger, it just stops appearing, because the projected tip
        // lands so far off-quad that every remaining term saturates to nothing. RM-only:
        // the 2D SDFButton's flat cast shadow doesn't have this failure mode.
        _ButtonShadow1MaxCast ("Button Shadow 1 Max Cast Distance", Range(0.25, 10)) = 2.0

        _ButtonShadow2Enabled ("Button Shadow 2 Enabled", Float) = 0
        _ButtonShadow2Color ("Button Shadow 2 Color", Color) = (0, 0, 0, 0.3)
        _ButtonShadow2Blur ("Button Shadow 2 Blur (softness at contact)", Range(0, 1)) = 0.2
        _ButtonShadow2Distance ("Button Shadow 2 Distance", Range(0, 0.2)) = 0.01
        _ButtonShadow2BlurFactor ("Button Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _ButtonShadow2Intensity ("Button Shadow 2 Intensity", Range(0, 2)) = 1.0
        _ButtonShadow2Cast ("Button Shadow 2 Cast", Range(0, 5)) = 1.0
        _ButtonShadow2MaxCast ("Button Shadow 2 Max Cast Distance", Range(0.25, 10)) = 2.0

        _ButtonShadow3Enabled ("Button Shadow 3 Enabled", Float) = 0
        _ButtonShadow3Color ("Button Shadow 3 Color", Color) = (0, 0, 0, 0.3)
        _ButtonShadow3Blur ("Button Shadow 3 Blur (softness at contact)", Range(0, 1)) = 0.2
        _ButtonShadow3Distance ("Button Shadow 3 Distance", Range(0, 0.2)) = 0.01
        _ButtonShadow3BlurFactor ("Button Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.3
        _ButtonShadow3Intensity ("Button Shadow 3 Intensity", Range(0, 2)) = 1.0
        _ButtonShadow3Cast ("Button Shadow 3 Cast", Range(0, 5)) = 1.0
        _ButtonShadow3MaxCast ("Button Shadow 3 Max Cast Distance", Range(0.25, 10)) = 2.0

        // ====================================================================
        // Lighting (3 directional lights)
        // ====================================================================
        _LightingAmbient ("Ambient", Range(0, 2)) = 0.3
        [ToggleUI] _LightingUnlit ("Unlit (skip lighting)", Float) = 0




        // Global light overrides
        _Position ("UI Position", Vector) = (0, 0, 0, 0)

        // Unity UI standard properties
        // Materials v2 (CG/Core/UIMaterials.cginc): matcap reflection + backdrop glass on the Button body.
        _ButtonMatcapEnabled ("Button Matcap Enabled", Float) = 0
        _ButtonMatcapLayer ("Button Matcap Layer (UiMaterials/catalog.json)", Float) = 0
        _ButtonMatcapStrength ("Button Matcap Strength", Range(0, 1)) = 1
        _ButtonMatcapMode ("Button Matcap Mode (0 metal, 1 coat, 2 tint)", Float) = 0
        _ButtonGlassEnabled ("Button Glass Enabled", Float) = 0
        _ButtonGlassStrength ("Button Glass Strength", Range(0, 1)) = 0.85
        _ButtonGlassRefract ("Button Glass Refraction", Range(0, 0.2)) = 0.03
        _ButtonGlassBlur ("Button Glass Blur (mip)", Range(0, 8)) = 3
        _ButtonGlassTint ("Button Glass Tint", Color) = (1, 1, 1, 1)
        _ButtonGlassRim ("Button Glass Rim", Range(0, 2)) = 0.6
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

            // === DEV COMPILE TOGGLES — comment out to skip compilation ===
            #define COMPILE_BODY
            #define COMPILE_ICON

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
            UI_MATERIAL_V2_UNIFORMS(Button)
            #include "CG/Core/UIViewCamera.cginc"
            #include "CG/Core/UIRenderer.cginc"
            #include "CG/Core/UIGradients.cginc"
            #include "CG/SDF/SDF3DExtrusion.cginc"
            #include "CG/SDF/SDFButtonUniforms.cginc"
            #include "CG/SDF/SDFPlayRing.cginc"

            // RM-specific uniforms (not in shared .cginc)
            float _ViewTilt;
            float _ViewAngle;
            float _ViewFOV;
            float _ViewShift;
            float _ViewCamEnabled;
            float _ViewCamShift;
            float _ViewCamTilt;
            float _ButtonLipHeight;
            float _EdgeFalloff;
            float _BorderInset;
            float _BorderFalloff;
            float _ShadowPassMode;
            float _ShadowUvExpand;
            float _AAWidth;
            float _ReceiveSceneShadows;
            float _ButtonShadow1MaxCast;
            float _ButtonShadow2MaxCast;
            float _ButtonShadow3MaxCast;

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

            // ================================================================
            // evalButtonSDF — wrapper for button 2D SDF with rotation
            // ================================================================
            float evalButtonSDF(float2 p, float halfW, float halfH) {
                float2 pRot = p;
                if (abs(_ButtonShapeRotation) > 0.001) {
                    pRot = rotate2D(p, _ButtonShapeRotation * (PI / 180.0));
                }
                return getButtonSDF(pRot, halfW, halfH, (int)_ButtonShapeType,
                    _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3);
            }

            // ================================================================
            // computeButtonFaceSDF — face boundary SDF for bevel zone
            // ================================================================
            float computeButtonFaceSDF(float2 p, float baseSDF, float faceInsetVal, float bevelDistVal, float halfW, float halfH) {
                UNITY_BRANCH
                if (_ButtonFaceShapeEnabled > 0.5) {
                    float faceMargin = (1.0 - saturate(_ButtonFaceSize)) * min(halfW, halfH);
                    float faceHalfW = max(0.001, halfW - faceMargin);
                    float faceHalfH = max(0.001, halfH - faceMargin);
                    float2 pRot = p;
                    if (abs(_ButtonFaceShapeRotation) > 0.001) {
                        pRot = rotate2D(p, _ButtonFaceShapeRotation * (PI / 180.0));
                    }
                    float faceShapeSDF = getButtonSDF(pRot, faceHalfW, faceHalfH, (int)_ButtonFaceShapeType,
                        _ButtonFaceShapeParam1, _ButtonFaceShapeParam2, _ButtonFaceShapeParam3,
                        _ButtonFaceShapeTexLayer, _ButtonFaceShapeTexScale);
                    return faceShapeSDF + bevelDistVal;
                }
                return baseSDF + faceInsetVal;
            }

            // ================================================================
            // buttonScreenToBase — a screen point, on the button's BASE PLANE.
            //
            // The same projection frag2dBasePos uses for the Edge, Border and icon, exposed
            // so the cast shadow can use it too. It has to: the shadow falls on the panel,
            // the panel IS that plane, and the body's own footprint is drawn through this
            // map. An orthographic stand-in (what the sweep used before) ignores _ViewShift
            // and _ViewFOV, so the shadow drifted off the foot of the body it came from —
            // most visibly across the drum-pad grid, where the layout hands every pad a
            // different _ViewShift.
            // ================================================================
            float2 buttonScreenToBase(float2 sPos, float2 tiltDir, float2 tiltNormDir,
                                      float cosT, float sinT, float maxDim)
            {
                float sa = dot(sPos, tiltNormDir);
                float sl = dot(sPos, tiltDir);
                if (_ViewFOV > 0.001) {
                    float focD = maxDim / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                    // FLOOR THE DIVIDE RELATIVE TO THE CAMERA DISTANCE, not at an absolute
                    // epsilon. W = focD*cosT - sl*sinT passes through zero at this
                    // projection's horizon, and on the 2x backing quad `sl` reaches far
                    // enough to get there for a wide _ViewFOV. An absolute floor lets the
                    // term explode just short of it — that singularity is what made an
                    // earlier pinhole shadow crease and blow up. A relative floor caps the
                    // perspective stretch at 4x instead, which no UI needs to exceed.
                    float base = focD * cosT;
                    float W    = max(base - sl * sinT, base * 0.25);
                    return float2((sa * base - UI_VIEW_SHIFT * sl * sinT) / W, -focD * sl / W);
                }
                return float2(sa, -sl / max(0.001, cosT));
            }

            // ================================================================
            // computeRMButtonShadowAlpha — cast shadow of the 3D body
            //
            // The silhouette is the convex hull of the base footprint and the
            // light-projected face. For two convex sets that hull is EXACTLY the union
            // over s in [0,1] of their linear interpolation, so a uniform sweep of s with
            // a running min IS the hull rather than an approximation of it — see
            // UIShadowHullSamples for how many steps that takes and what the old
            // construction cost in accuracy.
            //
            // It used to be built from a closest-point-on-segment parameter plus a
            // smooth-min against the tip's own footprint. That estimate is only correct
            // when the swept shape does not change size, and the sweep tapers by the face
            // inset, so the two fields crossed over early on one side of a corner and late
            // on the other — measured 0.146 quad units of error against a reference sweep,
            // which is a visible notch bitten out of the shadow's side. The smooth-min was
            // added to hide that notch and could only blur it.
            //
            // Tilt-only projection — no _ViewFOV perspective divide, matching the knob (see
            // computeRMKnobShadowAlpha). A pinhole W-divide was tried here and its
            // W = focD*cosT - al*sinT passes through zero for ordinary tilt/cast pairs,
            // which is a singularity in the middle of the shadow.
            // ================================================================
            float computeRMButtonShadowAlpha(
                float2 uv, float3 lightDir,
                float blur, float dist, float blurFac, float castMul, float maxCast,
                float2 tiltDir, float2 tiltNormDir, float cosTpre, float sinTpre,
                float bodyHalfW, float bodyHalfH, float faceInset, float totalHeight,
                float2 aspectScale, float aaUnit)
            {
                // _ViewTilt 10 is a full 90 degrees, where cos(tilt) is 0 and this whole
                // projection degenerates: every `-al / cosT` blows up to +-1000 and, worse,
                // `sDist = sD * cosT` collapses to 0 for EVERY pixel, so the edge test reads
                // "just inside the shadow" across the entire backing quad and the widget
                // vanishes into a uniform grey slab (measured: 97.7% of the quad covered).
                // Past ~81 degrees the face is edge-on and its shadow is meaningless anyway,
                // so the frame is held there instead of being allowed to collapse.
                float cosTsafe = max(0.15, cosTpre);
                float2 ld2  = normalize(lightDir.xy);
                // See SDFButtonLayers.cginc's calculateButtonExternalShadow for why the offset is
                // added after aspect-scaling the base position rather than being multiplied by
                // aspectScale too (matches the fix already present in SDFSliderRM's equivalent).
                float2 sPos = (uv - float2(0.5, 0.5)) * 2.0 * aspectScale - ld2 * dist * 2.0;

                float  maxDim = max(bodyHalfW, bodyHalfH);
                // Everything below works in BASE-PLANE coordinates — the plane the shadow
                // actually falls on, projected the way the body is drawn. See
                // buttonScreenToBase.
                float2 bxz = buttonScreenToBase(sPos, tiltDir, tiltNormDir, cosTsafe, sinTpre, maxDim);

                float  sD  = evalButtonSDF(bxz, bodyHalfW, bodyHalfH);

                // When face is disabled (ring/outline mode), cut the face opening from the shadow.
                // Ring SDF = max(outer, -inner): positive outside outer or inside inner hole.
                if (_ButtonFaceEnabled < 0.5 && faceInset > 0.001) {
                    float innerHalfW = max(0.001, bodyHalfW - faceInset);
                    float innerHalfH = max(0.001, bodyHalfH - faceInset);
                    float sD_inner   = evalButtonSDF(bxz, innerHalfW, innerHalfH);
                    sD = max(sD, -sD_inner);
                }

                // Transform light into button 3D tilt frame
                // Raymarched paths rotate the light into the widget's tilted 3D frame and use xy and z
                // TOGETHER, so they need a coherent vector — see UIToLightVector.
                float3 toLight = UIToLightVector(lightDir);
                float la  = dot(toLight.xy, tiltNormDir);
                float lb  = dot(toLight.xy, tiltDir);
                float lZ  = toLight.z;
                // lBy is "how far above the TILTED FACE's plane the lamp sits". It goes
                // NEGATIVE whenever the lamp is below that plane — which is not exotic: any
                // widget sitting higher on screen than the rig's lamps is in that state, i.e.
                // every button in a top toolbar under the shipped rig.
                //
                // This used to gate the entire hull sweep (`lBy > 0.001 && ...`), so crossing
                // zero did not shorten the shadow, it DELETED it: measured on the offline port,
                // a toolbar button's shadow went from 21% of the quad at lamp height 0.25 to
                // 0.9% at 0.15 — a 23x step for a small light move, which is exactly the
                // "sometimes the shadow disappears" report.
                //
                // Letting the sign through instead is also wrong, and worse: ps flips, topOff
                // flips, and the shadow lands on the SAME side as the lamp (tried offline; a
                // lamp below the widget threw the shadow downwards, under the lamp).
                //
                // A positive floor is the right answer. Below the face plane the top face
                // stops being the silhouette, but the solid still blocks light, so the throw
                // saturates LONG — and the cap below already holds it there.
                float lByRaw = lb * sinTpre + lZ * cosTpre;
                float lBy    = max(lByRaw, 0.08);

                // Penumbra half-width AT THE CONTACT POINT: the skin's own softness, and the
                // floor that the distance term below is added to.
                float penHalf  = UI_SHADOW_CONTACT_BLUR(blur, maxDim);
                float umbraMul = 1.0;

                // Hull sweep + face projection
                // When face is disabled (ring/outline mode) the button has no solid top cap,
                // so the hull sweep must be skipped — only the base footprint casts shadow.
                float effectiveCastMul = (_ButtonFaceEnabled > 0.5) ? castMul : 0.0;
                if (effectiveCastMul > 0.001) {
                    float lBx = la;
                    float lBz = -lb * cosTsafe + lZ * sinTpre;

                    float faceMarginS = (1.0 - saturate(_ButtonFaceSize)) * min(bodyHalfW, bodyHalfH);
                    float faceHalfW = (_ButtonFaceShapeEnabled > 0.5)
                        ? max(0.001, bodyHalfW - faceMarginS)
                        : max(0.001, bodyHalfW - faceInset);
                    float faceHalfH = (_ButtonFaceShapeEnabled > 0.5)
                        ? max(0.001, bodyHalfH - faceMarginS)
                        : max(0.001, bodyHalfH - faceInset);

                    float  ps     = totalHeight * effectiveCastMul / lBy;
                    // The throw, as a BASE-PLANE vector. It always was one — the screen-space
                    // `topOff` this replaces was exactly this pair pushed back through the
                    // orthographic map, which is why that map could not be swapped for a
                    // perspective one without moving the sweep here first.
                    //
                    // It points TOWARD the lamp: it is added to the SAMPLE position, which
                    // shifts the drawn shadow the other way, AWAY from the lamp. Signs are
                    // inverted from lBx/lBz because those come from the to-light vector.
                    float2 topOff = float2(lBx * ps, lBz * ps);

                    // Cap the throw. A grazing light (lBy at its floor) sends `ps` very long,
                    // and an unclamped topOff doesn't make the shadow bigger, it makes it
                    // disappear — the projected tip lands so far off-quad that nothing draws.
                    // NOTE: this must NOT read _ShadowUvExpand. That uniform is 1 on the widget's
                    // own material and 2 on the backing quad's copy, so keying the cap to it
                    // would give the two passes DIFFERENT cast lengths.
                    float quadReach  = 2.0 * max(aspectScale.x, aspectScale.y);
                    float capLimit   = min(maxCast, quadReach * 0.95);
                    float rawCastLen = length(topOff);
                    if (rawCastLen > capLimit) {
                        topOff    *= capLimit / max(0.0001, rawCastLen);
                        rawCastLen = capLimit;
                    }

                    // CONTACT HARDENING. `t` is where along the throw this pixel sits: 0 at the
                    // foot of the solid, 1 out at the projected tip. The penumbra opens up with
                    // it and the umbra dissolves with it, so ONE shadow is sharp and dark where
                    // it meets the widget and broad and faint at its far end — which is what a
                    // real shadow does, and what a single per-widget softness can never say.
                    // The old code evaluated the falloff once per WIDGET with the full throw,
                    // giving every pixel of the shadow the same blur: a flat card, hovering.
                    float  segLen2 = dot(topOff, topOff);
                    float  t       = saturate(-dot(bxz, topOff) / max(0.0001, segLen2));
                    float2 fall    = UIShadowPenumbra(rawCastLen * t, maxDim, blurFac);
                    penHalf       += fall.x;
                    umbraMul       = fall.y;

                    // The hull, swept in the tilt frame. DYNAMIC loop on purpose: the compiler
                    // emits ONE evalButtonSDF for the whole sweep instead of unrolling it, which
                    // is why this can afford to be more accurate than the two-evaluation
                    // construction it replaces rather than more expensive. s = 0 is the base
                    // footprint, already in sD above, so the loop starts at 1.
                    int   hullN = UIShadowHullSamples(rawCastLen, maxDim);
                    float invN  = 1.0 / (float)max(hullN - 1, 1);
                    UNITY_LOOP for (int hs = 1; hs < hullN; hs++) {
                        float  s     = (float)hs * invN;
                        float2 bxzS  = bxz + topOff * s;
                        float2 hHalf = lerp(float2(bodyHalfW, bodyHalfH),
                                            float2(faceHalfW, faceHalfH), s);
                        float  dS;
                        if (_ButtonFaceShapeEnabled > 0.5 && s > 0.5) {
                            float2 pRot = bxzS;
                            if (abs(_ButtonFaceShapeRotation) > 0.001)
                                pRot = rotate2D(bxzS, _ButtonFaceShapeRotation * (PI / 180.0));
                            dS = getButtonSDF(pRot, hHalf.x, hHalf.y,
                                (int)_ButtonFaceShapeType,
                                _ButtonFaceShapeParam1, _ButtonFaceShapeParam2, _ButtonFaceShapeParam3);
                        } else {
                            dS = evalButtonSDF(bxzS, hHalf.x, hHalf.y);
                        }
                        sD = min(sD, dS);
                    }
                }

                // Tilt frame -> screen, ONCE, on the finished hull. Converting each swept sample
                // separately (which the old two-evaluation version did) applies a
                // direction-dependent scale to fields that are then min'd together, and that
                // creases the result into visible rays along the shadow's flanks.
                float sDist = buttonTiltToScreenDist(sD, bxz, cosTsafe);
                float alpha = UIShadowEdgeAlpha(sDist, penHalf, aaUnit) * umbraMul;

                // Dissolve into the quad's own edge. Capping the throw above stops the tip
                // reaching the boundary, but a wide shadow cast diagonally still can, and a
                // shadow that ends in a straight cut reads as a bug however correct its length
                // is. `uv` is already remapped into widget space here, so this is 0 at the
                // centre and 1 at the backing quad's rim.
                if (_ShadowPassMode > 0.5) {
                    float2 qEdge = abs(uv - 0.5) * 2.0 / max(_ShadowUvExpand, 1.0);
                    alpha *= 1.0 - smoothstep(0.82, 1.0, max(qEdge.x, qEdge.y));
                }
                return alpha;
            }

            // ---- One shadow slot's uniforms, selected by index --------------------
            // The three _ButtonShadowN* sets are the same parameters three times over, one per
            // rig lamp. Selecting them here lets both shadow passes (the backing quad's and the
            // widget's own in-quad half) run ONE loop instead of three call sites, so
            // computeRMButtonShadowAlpha — and the shape switch inside it — is compiled once
            // per pass rather than three times.
            struct ButtonShadowSlot {
                float  enabled;
                float  blur, dist, blurFac, castMul, maxCast, intensity;
                float3 color;
                float  colorA;
                float3 lightDir;
            };

            ButtonShadowSlot buttonShadowSlot(int i, float3 l1, float3 l2, float3 l3)
            {
                ButtonShadowSlot s;
                s.enabled   = (i == 0) ? _ButtonShadow1Enabled   : (i == 1) ? _ButtonShadow2Enabled   : _ButtonShadow3Enabled;
                s.blur      = (i == 0) ? _ButtonShadow1Blur      : (i == 1) ? _ButtonShadow2Blur      : _ButtonShadow3Blur;
                s.dist      = (i == 0) ? _ButtonShadow1Distance  : (i == 1) ? _ButtonShadow2Distance  : _ButtonShadow3Distance;
                s.blurFac   = (i == 0) ? _ButtonShadow1BlurFactor: (i == 1) ? _ButtonShadow2BlurFactor: _ButtonShadow3BlurFactor;
                s.castMul   = (i == 0) ? _ButtonShadow1Cast      : (i == 1) ? _ButtonShadow2Cast      : _ButtonShadow3Cast;
                s.maxCast   = (i == 0) ? _ButtonShadow1MaxCast   : (i == 1) ? _ButtonShadow2MaxCast   : _ButtonShadow3MaxCast;
                s.intensity = (i == 0) ? _ButtonShadow1Intensity : (i == 1) ? _ButtonShadow2Intensity : _ButtonShadow3Intensity;
                s.color     = (i == 0) ? _ButtonShadow1Color.rgb : (i == 1) ? _ButtonShadow2Color.rgb : _ButtonShadow3Color.rgb;
                s.colorA    = (i == 0) ? _ButtonShadow1Color.a   : (i == 1) ? _ButtonShadow2Color.a   : _ButtonShadow3Color.a;
                s.lightDir  = (i == 0) ? l1 : (i == 1) ? l2 : l3;
                return s;
            }

            // ================================================================
            // renderRaymarchButton — 3D raymarched button body
            // ================================================================
            void renderRaymarchButton(
                float2 uv, float2 pos,
                float time, UILight light1, UILight light2, UILight light3,
                inout float4 finalColor, inout float3 emissiveAccum)
            {
            #ifdef COMPILE_BODY
                if (_ButtonEnabled < 0.5) return;

                float rectAspect = (_AspectRatio > 0.001) ? _AspectRatio : abs(ddy(uv.y)) / max(0.0001, abs(ddx(uv.x)));
                float2 aspectScale = float2(max(rectAspect, 1.0), max(1.0 / rectAspect, 1.0));
                float bodyHalfW = max(0.001, aspectScale.x - _ButtonPadding);
                float bodyHalfH = max(0.001, aspectScale.y - _ButtonPadding);
                float maxDim = max(bodyHalfW, bodyHalfH);
                // SHORT half-extent — all extrusion HEIGHTS scale by this (matching the 2D
                // SDFButton's pseudoHeight and SDFSliderRM's handleMinDim convention): the
                // short side doesn't grow with aspect ratio, so a wide button keeps the same
                // physical thickness/padding on screen instead of getting proportionally
                // taller until its projected wall+face overflow the quad (user-reported:
                // same params looked right at ~1:1, ballooned off-quad when wide). maxDim
                // stays the reference for CAMERA framing (focalDist/bounds) — see the
                // focalDist comment below; that part was already aspect-corrected.
                float minDim = min(bodyHalfW, bodyHalfH);

                // ONE SCREEN PIXEL in `pos` units. Taken here, at the top of the function and
                // outside every branch, because it needs a derivative and the only place it is
                // used — the miss-path silhouette AA after the sphere-march — sits inside two
                // levels of per-pixel branch where ddx/ddy are undefined.
                float silAaUnit = max(fwidth(pos.x), fwidth(pos.y)) * 0.75;

                // Tilt setup
                float effectiveTilt = UI_VIEW_TILT;
                float tiltRad = (_ViewAngle + 90.0) * (PI / 180.0);
                float2 tiltDir     = float2(cos(tiltRad), sin(tiltRad));
                float2 tiltNormDir = float2(-tiltDir.y, tiltDir.x);
                float tiltNorm     = saturate(effectiveTilt / 10.0);
                float tiltAnglePre = tiltNorm * (PI * 0.5);
                float cosTpre = cos(tiltAnglePre);
                float sinTpre = sin(tiltAnglePre);

                // Geometry params
                float bevelDist     = (_ButtonBevelEnabled > 0.5) ? _ButtonBevelDistance : 0.0;
                float bevelDepthRaw = (_ButtonBevelEnabled > 0.5) ? abs(_ButtonBevelDepth) : 0.0;
                float bevelHeight   = minDim * lerp(0.05, 1.0, bevelDepthRaw);
                float lipHeight     = minDim * _ButtonLipHeight;
                float rimWidth      = (_ButtonRimEnabled > 0.5) ? _ButtonRimWidth : 0.0;
                float totalHeight   = lipHeight + bevelHeight;
                float faceInset     = rimWidth + bevelDist;

                // Body/cast shadows (_ButtonShadow1/2/3) render in the frag's shadow-pass block
                // (_ShadowPassMode=1, on the expanded backing quad driven by WidgetShadowQuad)
                // instead of here — same computeRMButtonShadowAlpha math with identical inputs
                // (frag2dTiltDir/frag2dCosT/frag2dTotalH mirror this function's tilt/totalHeight
                // formulas), so the look is unchanged, it just can't clip at this quad's edge.

                // ---- 3D Raymarch button body ----

                // Ray setup
                float cosT = cosTpre;
                float sinT = sinTpre;
                float screenAcross = dot(pos, tiltNormDir);
                float screenAlong  = dot(pos, tiltDir);
                float3 orthoDir = float3(0.0, -cosT, -sinT);
                float boundRadius = maxDim * 1.2 + totalHeight;
                float startDist = boundRadius + maxDim * 0.5;
                float3 btnPlanePoint = float3(screenAcross, screenAlong * sinT, -screenAlong * cosT);

                // FOV
                float3 rayDir;
                float3 rayOrigin;
                if (_ViewFOV > 0.001) {
                    // focalDist = 1/tan(halfFOV): 0.5→45°, 0.667→60°, 0.889→80°, 1→90°
                    // Scaled by maxDim (the shape's own half-extent) so the camera backs away
                    // proportionally as the control gets wider/taller — without this, a fixed
                    // focalDist sits at a constant distance while the geometry it's viewing
                    // grows, so the same _ViewFOV subtends a progressively wider angle and the
                    // shape looks like it's being pushed toward the camera the more it's
                    // stretched. At maxDim≈1 (square, the aspect controls were tuned at) this is
                    // numerically unchanged from before.
                    float focalDist = maxDim / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                    float3 camPos = float3(UI_VIEW_SHIFT, focalDist * cosT, focalDist * sinT);
                    rayDir = normalize(btnPlanePoint - camPos);
                    rayOrigin = btnPlanePoint - rayDir * startDist;
                } else {
                    rayDir = orthoDir;
                    rayOrigin = float3(
                        screenAcross,
                        screenAlong * sinT + startDist * cosT,
                        -screenAlong * cosT + startDist * sinT
                    );
                }

                // Note: buttons do not rotate like knobs, no knobAngle rotation needed

                // Sphere-bound test
                float3 boundCenter = float3(0.0, totalHeight * 0.5, 0.0);
                float3 oc = rayOrigin - boundCenter;
                float bCoeff = dot(oc, rayDir);
                float cCoeff = dot(oc, oc) - boundRadius * boundRadius;
                float disc = bCoeff * bCoeff - cCoeff;

                if (disc >= 0.0) {
                    float tStart = max(0.0, -bCoeff - sqrt(disc));
                    float tEnd   = -bCoeff + sqrt(disc);

                    if (tEnd > 0.0) {
                        // Map button's rectangular shape to extrusion params
                        // Use maxDim as "radius" for the extrusion geometry
                        ExtrusionParams extParams;
                        extParams.knobRadius  = maxDim;
                        extParams.lipHeight   = lipHeight;
                        extParams.rimWidth    = rimWidth;
                        extParams.bevelHeight = bevelHeight;
                        extParams.bevelDist   = bevelDist;
                        extParams.totalHeight = totalHeight;
                        extParams.hasFaceShape = (_ButtonFaceShapeEnabled > 0.5) ? 1 : 0;
                        extParams.filletRadius = bevelHeight * _ButtonBevelSmoothness * 0.4;

                        // Sphere-march
                        float t = tStart;
                        float3 p = rayOrigin + t * rayDir;
                        // Precision epsilons follow minDim: they gate hits/classification
                        // against lip/bevel features, which now scale with minDim — a
                        // maxDim-scaled eps on a very wide button would swallow the lip.
                        float marchEps = minDim * 0.001;
                        float hitBaseSDF = 0.0;
                        bool hitFound = false;
                        float minDist3D = 1e9;
                        float3 pAtMin = p; // position of closest 3D approach (for miss-path AA)

                        UNITY_LOOP for (int i = 0; i < 64; i++) {
                            float baseSDF_m = evalButtonSDF(p.xz, bodyHalfW, bodyHalfH);
                            float faceSDF_m = computeButtonFaceSDF(p.xz, baseSDF_m, faceInset, bevelDist, bodyHalfW, bodyHalfH);
                            float d = sdfExtrusion3D(p, baseSDF_m, faceSDF_m, extParams);
                            if (d < minDist3D) { minDist3D = d; pAtMin = p; }
                            if (d < marchEps) {
                                // Groove skip: if deep inside base shape AND below lip,
                                // advance through interior to avoid getting stuck
                                bool isGroove = (baseSDF_m < -(rimWidth + marchEps * 6.0)) &&
                                                (p.y < lipHeight + marchEps * 4.0);
                                if (isGroove) {
                                    float xzSpeed = max(length(rayDir.xz), marchEps * 2.0);
                                    float xzDist  = max(-baseSDF_m, marchEps * 4.0);
                                    t += xzDist / xzSpeed;
                                    p = rayOrigin + t * rayDir;
                                    continue;
                                }
                                hitFound = true;
                                hitBaseSDF = baseSDF_m;
                                break;
                            }
                            if (t > tEnd) break;
                            t += max(d, marchEps * 0.5);
                            p = rayOrigin + t * rayDir;
                        }

                        if (hitFound) {
                            float y = p.y;
                            float surfaceEps = minDim * 0.005;
                            float lipEps     = max(surfaceEps, marchEps * 4.0);

                            // Surface classification
                            int hitSurface = SURFACE_WALL;
                            if (y >= totalHeight - surfaceEps) {
                                hitSurface = SURFACE_FACE;
                            } else if (y <= lipHeight + lipEps) {
                                if (y < lipHeight - lipEps) {
                                    hitSurface = SURFACE_LIP;
                                } else {
                                    hitSurface = SURFACE_RIM;
                                }
                            }
                            // NO LIP = NO LIP SURFACE (2026-09-13, same fix as SDFKnobRM). With an
                            // explicit _ButtonLipHeight 0, hits at the very foot of the wall classify
                            // as RIM/LIP (normal straight up, lit bright) and draw a one-pixel
                            // detached sliver along the body's lit edge. There is no lip to draw.
                            // Only skins that author lip 0 are affected: the property default is 0.08.
                            bool noLipSeam = (lipHeight <= lipEps) && (hitSurface == SURFACE_RIM || hitSurface == SURFACE_LIP);
                            float surfaceTint = (hitSurface == SURFACE_WALL) ? 0.9 :
                                                (hitSurface == SURFACE_RIM)  ? 1.0 :
                                                (hitSurface == SURFACE_LIP)  ? 0.75 : 1.0;

                            // Analytical surface normals
                            float2 wallGradN = float2(1, 0);
                            float3 hitNormal;
                            {
                                float eps2d = max(0.0005, minDim * 0.004);
                                float bdx   = evalButtonSDF(p.xz + float2(eps2d, 0), bodyHalfW, bodyHalfH);
                                float bdz   = evalButtonSDF(p.xz + float2(0, eps2d), bodyHalfW, bodyHalfH);
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
                                    UNITY_BRANCH if (_ButtonBevelSmoothness > 0.001) {
                                        float filletR = bevelHeight * _ButtonBevelSmoothness * 0.4;
                                        float edgeT   = saturate((y - (totalHeight - filletR)) / max(filletR, 0.0001));
                                        hitNormal = normalize(lerp(wallNorm, float3(0, 1, 0), smoothstep(0.0, 1.0, edgeT)));
                                    } else {
                                        hitNormal = wallNorm;
                                    }
                                }
                            }

                            // Face dome/bowl perturbation
                            UNITY_BRANCH if (hitSurface == SURFACE_FACE && abs(_ButtonFaceSmoothness) > 0.001) {
                                float2 xz = p.xz;
                                float rx = abs(xz.x);
                                float rz = abs(xz.y);
                                float faceHalfW = (_ButtonFaceShapeEnabled > 0.5)
                                    ? max(0.001, bodyHalfW * _ButtonFaceSize)
                                    : max(0.001, bodyHalfW - faceInset);
                                float faceHalfH = (_ButtonFaceShapeEnabled > 0.5)
                                    ? max(0.001, bodyHalfH * _ButtonFaceSize)
                                    : max(0.001, bodyHalfH - faceInset);
                                float radialTx = saturate(rx / faceHalfW);
                                float radialTz = saturate(rz / faceHalfH);
                                float radialT = max(radialTx, radialTz);
                                float2 radialDir2D = (radialT > 0.0001) ? normalize(xz) : float2(0, 0);
                                float domeStrength = _ButtonFaceSmoothness * radialT;
                                float3 domeDir = float3(radialDir2D.x * domeStrength, 0, radialDir2D.y * domeStrength);
                                hitNormal = normalize(hitNormal + domeDir);
                            }

                            // Transform normal to screen space (no knobAngle rotation for buttons)
                            float3 screenNormal3D = normalToScreenSpace(hitNormal, sinT, cosT);
                            float2 screenNorm2D   = screenNormal3D.x * tiltNormDir + screenNormal3D.y * tiltDir;
                            float3 lightNormal    = normalize(float3(-screenNorm2D, max(0.0, screenNormal3D.z)));

                            // Silhouette AA
                            // Wall/rim/lip use footprintAlpha (screen-space 2D SDF) for clean silhouette AA.
                            // Face uses its own SDF for interior shape AA.
                            // Silhouette AA:
                            // • Hit wall/rim/lip: always 1.0. These pixels are definitively inside the
                            //   3D shape — dimming them causes the corner-clipping artefact.
                            //   AA for the outer silhouette edge now comes from the pixel's own footprint.
                            // • Face: fwidth(hitBaseSDF) — all face-neighbours are also hits, so
                            //   the derivative is valid and gives a smooth interior edge fade.
                            // • Custom face shape: SDF of the shape boundary.
                            float aaScale = max(0.5, _AAWidth);
                            float outerMask;
                            if (hitSurface == SURFACE_FACE && _ButtonFaceShapeEnabled > 0.5) {
                                float faceMarginAA = (1.0 - saturate(_ButtonFaceSize)) * min(bodyHalfW, bodyHalfH);
                                float faceHalfW = max(0.001, bodyHalfW - faceMarginAA);
                                float faceHalfH = max(0.001, bodyHalfH - faceMarginAA);
                                float2 pRotFace = p.xz;
                                if (abs(_ButtonFaceShapeRotation) > 0.001) {
                                    pRotFace = rotate2D(p.xz, _ButtonFaceShapeRotation * (PI / 180.0));
                                }
                                float faceShapeDist = getButtonSDF(pRotFace, faceHalfW, faceHalfH,
                                    (int)_ButtonFaceShapeType,
                                    _ButtonFaceShapeParam1, _ButtonFaceShapeParam2, _ButtonFaceShapeParam3);
                                float faceAA = fwidth(faceShapeDist) * 0.75 * aaScale;
                                outerMask = smoothstep(faceAA, -faceAA, faceShapeDist);
                            } else if (hitSurface == SURFACE_FACE) {
                                float outerAA = fwidth(hitBaseSDF) * 0.75 * aaScale;
                                outerMask = smoothstep(outerAA, -outerAA, hitBaseSDF);
                            } else {
                                // WALL / RIM / LIP — the SILHOUETTE. This was a flat 1.0, with the
                                // comment above deferring the outer edge to "the miss path below";
                                // no such path existed (`minDist3D` and `pAtMin` were recorded by
                                // the march and never read), so the outline was a binary in/out
                                // test. Measured on a 209x198 pad at 1 sample/pixel, the profile
                                // across a corner fell 98 -> 14 in ONE sample while the 2D panel
                                // beside it graded 244 -> 142 -> 28: that hard cliff is why a pad's
                                // corner read as a different curve from the aperture around it.
                                //
                                // The right distance is the PIXEL's own 2D distance to the base
                                // contour, not the hit point's — a wall hit sits ON the contour, so
                                // hitBaseSDF is ~0 across the whole wall and using it would fade
                                // the entire side. Projecting the pixel back into base space and
                                // measuring there is exact at _ViewTilt 0 and a good approximation
                                // under tilt, where the wall is foreshortened anyway.
                                // ⚠ ONLY WHEN UNTILTED. Face-on, the projected silhouette IS the
                                // base contour and this is exact. Under tilt it is not — the wall
                                // is foreshortened and its outline bows away from the contour, so
                                // the same smoothstep reads the wrong side near the corner and
                                // brightens it (measured: a 217 spike in a 103-valued wall at
                                // _ViewTilt 1.6). Tilted RM controls keep the old flat 1.0, so
                                // every button/toggle in the app that leans is byte-identical.
                                if (effectiveTilt < 0.05) {
                                    float2 bxzPix  = buttonScreenToBase(pos, tiltDir, tiltNormDir,
                                                                       max(0.15, cosTpre), sinTpre, maxDim);
                                    float  sdOuter = evalButtonSDF(bxzPix, bodyHalfW, bodyHalfH);
                                    float  outerAA = max(fwidth(sdOuter), 1e-6) * 0.75 * aaScale;
                                    outerMask = noLipSeam ? 0.0 : smoothstep(outerAA, -outerAA, sdOuter);
                                } else {
                                    outerMask = noLipSeam ? 0.0 : 1.0;
                                }
                            }

                            // ---- Surface coloring ----

                            // Compute face-local UV from 3D hit point so patterns
                            // track the surface under ViewTilt / ViewAngle changes.
                            // p.xz is already in the button's tilted local frame.
                            float2 faceUV = p.xz / float2(bodyHalfW, bodyHalfH) * 0.5 + 0.5;

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

                            // Base surface color with gradient
                            float3 bodyBaseColor = bodyComponent.color.rgb;
                            if (bodyComponent.gradientEnabled > 0.5) {
                                float4 gradientColor = CalculateGradient(faceUV, bodyComponent.gradientColorA, bodyComponent.gradientColorB,
                                                                       bodyComponent.gradientColorC, bodyComponent.gradientColorD,
                                                                       bodyComponent.gradientDirection, bodyComponent.gradientType,
                                                                       bodyComponent.gradientSpeed, bodyComponent.gradientScale,
                                                                       bodyComponent.gradientOffset, time, _ButtonGradientColorUsed);
                                bodyBaseColor = lerp(bodyBaseColor, gradientColor.rgb, gradientColor.a);
                            }
                            if (bodyComponent.globalBlend > 0.0) {
                                float4 globalColor = CalculateGlobalGradient(uv, time);
                                bodyBaseColor = lerp(bodyBaseColor, globalColor.rgb, bodyComponent.globalBlend * bodyComponent.globalIntensity);
                            }

                            // Pattern on surface (faceUV = 3D object-space UV)
                            float specularMod;
                            float2 normalOffset;
                            float3 surfaceColor = ApplyMaterialPattern(bodyBaseColor, faceUV, bodyComponent,
                                                                       0.0, 0.0, specularMod, normalOffset);

                            // On walls, start from unpatterned base so face pattern doesn't bleed
                            UNITY_BRANCH if (hitSurface == SURFACE_WALL) {
                                surfaceColor = bodyBaseColor;
                            }

                            // RM Bevel gradient (types 5=BevelDepth, 6=BevelWalls)
                            UNITY_BRANCH if (hitSurface == SURFACE_WALL && _ButtonBevelEnabled > 0.5 && _ButtonBevelGradientEnabled > 0.5) {
                                int bevelGradType = (int)_ButtonBevelGradientType;
                                if (bevelGradType == 5) {
                                    // BevelDepth: ramp A→D based on normalDot (wall angle vs outward radial)
                                    float2 outDir = (length(p.xz) > 0.0001) ? normalize(p.xz) : float2(1, 0);
                                    float normalDot = saturate(dot(wallGradN, outDir));
                                    float4 bevelGradColor;
                                    if (normalDot < 0.333) {
                                        bevelGradColor = lerp(_ButtonBevelGradientColorA, _ButtonBevelGradientColorB, normalDot * 3.0);
                                    } else if (normalDot < 0.667) {
                                        bevelGradColor = lerp(_ButtonBevelGradientColorB, _ButtonBevelGradientColorC, (normalDot - 0.333) * 3.0);
                                    } else {
                                        bevelGradColor = lerp(_ButtonBevelGradientColorC, _ButtonBevelGradientColorD, (normalDot - 0.667) * 3.0);
                                    }
                                    surfaceColor = lerp(surfaceColor, bevelGradColor.rgb, bevelGradColor.a);
                                } else if (bevelGradType == 6) {
                                    // BevelWalls: 4-zone partition using normalDot + tangentialMag
                                    float2 outDir = (length(p.xz) > 0.0001) ? normalize(p.xz) : float2(1, 0);
                                    float normalDot = dot(wallGradN, outDir);
                                    float2 tangent = float2(-outDir.y, outDir.x);
                                    float tangentialMag = abs(dot(wallGradN, tangent));
                                    float4 zoneColor;
                                    if (normalDot > 0.5) {
                                        zoneColor = _ButtonBevelGradientColorA; // outer wall
                                    } else if (tangentialMag > 0.7) {
                                        zoneColor = (dot(wallGradN, tangent) > 0.0)
                                            ? _ButtonBevelGradientColorB   // slit side A
                                            : _ButtonBevelGradientColorC;  // slit side B
                                    } else {
                                        zoneColor = _ButtonBevelGradientColorD; // groove back
                                    }
                                    surfaceColor = lerp(surfaceColor, zoneColor.rgb, zoneColor.a);
                                } else {
                                    // Standard gradient types on bevel
                                    float4 gradientColor = CalculateGradient(uv,
                                        _ButtonBevelGradientColorA, _ButtonBevelGradientColorB,
                                        _ButtonBevelGradientColorC, _ButtonBevelGradientColorD,
                                        _ButtonBevelGradientDirection, bevelGradType,
                                        _ButtonBevelGradientSpeed, _ButtonBevelGradientScale,
                                        _ButtonBevelGradientOffset, time, _ButtonBevelGradientColorUsed);
                                    surfaceColor = lerp(surfaceColor, gradientColor.rgb, gradientColor.a);
                                }
                            }

                            // Bevel pattern on walls
                            UNITY_BRANCH if (hitSurface == SURFACE_WALL && _ButtonBevelEnabled > 0.5 && _ButtonBevelPatternEnabled > 0.5) {
                                // Bevel pattern uses screen-space UV (uv = quad texcoord) so it acts as
                                // a fixed "window into a global texture" — does not follow the 3D surface
                                // under ViewTilt rotations, matching a world-space material appearance.
                                float2 bevelPatUV = uv; // quad screen-space coords (0-1), tilt-invariant
                                float bpVal = SamplePatternValue(_ButtonBevelPatternType, bevelPatUV, float2(0.5, 0.5), _ButtonBevelPatternScale,
                                    _ButtonBevelPatternParam1, _ButtonBevelPatternParam2, _ButtonBevelPatternParam3);
                                bpVal = saturate((bpVal - 0.5) * _ButtonBevelPatternContrast + 0.5);
                                float bpIntensity = bpVal * _ButtonBevelPatternIntensity;
                                surfaceColor = lerp(surfaceColor, surfaceColor * (1.0 - bpIntensity), bpIntensity);
                                specularMod *= lerp(1.0, 1.0 + bpVal * _ButtonBevelPatternSpecularEffect, bpIntensity);
                            }

                            // Apply surface tint
                            surfaceColor *= surfaceTint;

                            // Self-shadow: bevel wall casts shadow onto rim/lip
                            UNITY_BRANCH
                            if ((hitSurface == SURFACE_RIM || hitSurface == SURFACE_LIP) && bevelHeight > 0.01) {
                                float rl = length(p.xz);
                                float2 outDir = (rl > 0.0001) ? (p.xz / rl) : float2(1, 0);
                                float wallTanAngle = bevelHeight / max(0.001, bevelDist + rimWidth);

                                #define SELF_SHADOW_LIGHT_BTN(lightEnabled, lightDir, lightIntensity, factor) \
                                if (lightEnabled) { \
                                    float3 tl = UIToLightVector(lightDir); \
                                    float2 ld = tl.xy; \
                                    float lacross = dot(ld, tiltNormDir); \
                                    float lalong  = dot(ld, tiltDir); \
                                    float lz = tl.z; \
                                    float3 lBtn = float3(lacross, \
                                        lalong * sinT + lz * cosT, \
                                        -lalong * cosT + lz * sinT); \
                                    float lHorizLen = length(lBtn.xz); \
                                    float2 lHoriz = (lHorizLen > 0.0001) ? (lBtn.xz / lHorizLen) : float2(0, 0); \
                                    float shadowSide = saturate(dot(outDir, lHoriz)); \
                                    float lightTan = lBtn.y / max(0.001, lHorizLen); \
                                    float occluded = saturate(1.0 - lightTan / max(0.001, wallTanAngle)); \
                                    factor = min(factor, 1.0 - shadowSide * occluded); \
                                }
                                float selfShadow = 1.0;
                                SELF_SHADOW_LIGHT_BTN(light1.enabled, light1.direction, light1.intensity, selfShadow)
                                SELF_SHADOW_LIGHT_BTN(light2.enabled, light2.direction, light2.intensity, selfShadow)
                                SELF_SHADOW_LIGHT_BTN(light3.enabled, light3.direction, light3.intensity, selfShadow)
                                #undef SELF_SHADOW_LIGHT_BTN

                                surfaceColor *= lerp(1.0, selfShadow, 0.85);
                            }

                            // Apply 3D lighting using analytical normal
                            float3 litColor = ApplyUILighting(lightNormal, surfaceColor,
                                                             _LightingAmbient, specularMod, normalOffset,
                                                             light1, light2, light3);
                            UI_MATERIAL_V2(litColor, surfaceColor, lightNormal, Button, -1.0)

                            // Composite into layer stack
                            // Skip face surface if _ButtonFaceEnabled is off (ring/outline mode)
                            bool drawThisFragment = (hitSurface != SURFACE_FACE) || (_ButtonFaceEnabled > 0.5);
                            if (drawThisFragment) {
                                buttonCompositeOver(finalColor, litColor, outerMask * _ButtonRenderAlpha);
                                emissiveAccum += bodyBaseColor * outerMask * _ButtonRenderEmissive;
                            }
                        } // hitFound


                    } // tEnd > 0
                } // disc >= 0
            #endif // COMPILE_BODY
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                UI_SET_SCREEN_UV(IN.screenPos)
                float2 uv = IN.texcoord;
                // Shadow quad: remap uv into the widget's own uv space (quad is
                // _ShadowUvExpand× the widget, centered) so all SDF math is unchanged and
                // shadows can extend past where the widget quad would end. Equal scaling on
                // both axes keeps the ddx/ddy aspect detection below correct.
                if (_ShadowPassMode > 0.5) uv = (uv - 0.5) * _ShadowUvExpand + 0.5;
                float2 center = float2(0.5, 0.5);
                float rectAspect = (_AspectRatio > 0.001) ? _AspectRatio : abs(ddy(uv.y)) / max(0.0001, abs(ddx(uv.x)));
                float2 aspectScale = float2(max(rectAspect, 1.0), max(1.0 / rectAspect, 1.0));
                float2 pos = (uv - center) * 2.0 * aspectScale;

                // One screen pixel, in the aspect-scaled quad units every shadow SDF below
                // works in. Taken HERE, at the top of frag, because it needs a derivative and
                // the self-shadow call site further down sits inside `finalColor.a > 0.001` —
                // a per-pixel branch, where ddx/ddy are undefined. It becomes the minimum
                // width of a shadow's edge, so a shadow can never terminate in a sub-pixel
                // step (which is what made the button's edges stair-step and crawl).
                float shadowAaUnit = max(fwidth(uv.x) * 2.0 * aspectScale.x,
                                         fwidth(uv.y) * 2.0 * aspectScale.y) * 0.75;

                float bodyHalfW = max(0.001, aspectScale.x - _ButtonPadding);
                float bodyHalfH = max(0.001, aspectScale.y - _ButtonPadding);
                int bodyShapeType = (int)_ButtonShapeType;

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

                // ── Tilt params for all 2D flat layers (edge, border, icon) ──────────────
                // Mirrors the per-tilt setup in renderRaymarchButton; computed once here
                // so that edge, border, and icon all match the 3D body's projected shape.
                float  frag2dTiltRad     = (_ViewAngle + 90.0) * (PI / 180.0);
                float2 frag2dTiltDir     = float2(cos(frag2dTiltRad), sin(frag2dTiltRad));
                float2 frag2dTiltNormDir = float2(-frag2dTiltDir.y, frag2dTiltDir.x);
                float  frag2dTiltAngle   = saturate(UI_VIEW_TILT / 10.0) * (PI * 0.5);
                float  frag2dCosT        = cos(frag2dTiltAngle);
                float  frag2dSinT        = sin(frag2dTiltAngle);
                // totalHeight: same formula as renderRaymarchButton — heights scale by the
                // SHORT half-extent (see minDim comment there); frag2dMaxDim stays the
                // camera/focalDist reference so flat layers keep matching the 3D body.
                float  frag2dMaxDim      = max(bodyHalfW, bodyHalfH);
                float  frag2dMinDim      = min(bodyHalfW, bodyHalfH);
                float  frag2dBevelD      = (_ButtonBevelEnabled > 0.5) ? abs(_ButtonBevelDepth) : 0.0;
                float  frag2dTotalH      = frag2dMinDim * _ButtonLipHeight
                                         + frag2dMinDim * lerp(0.05, 1.0, frag2dBevelD);
                // Per-pixel position in button 3D frame at base (y=0) and face (y=totalH).
                // Derived by tracing the camera ray to each plane — handles both ortho and FOV.
                // Ortho:  basePos = (sa, -sl/cosT),  facePos = (sa, -sl/cosT + totalH*sinT/cosT)
                // FOV:    perspective divide by W = focD*cosT - sl*sinT (standard pinhole project)
                float frag2d_sa = dot(pos, frag2dTiltNormDir);
                float frag2d_sl = dot(pos, frag2dTiltDir);
                float2 frag2dBasePos, frag2dFacePos;
                if (_ViewFOV > 0.001) {
                    // focalDist = 1/tan(halfFOV): 0.5→45°, 0.667→60°, 0.889→80°, 1→90°
                    // Scaled by frag2dMaxDim to match renderRaymarchButton's camera (see its
                    // comment) so the edge/border/icon layers stay aligned with the 3D body.
                    float focD = frag2dMaxDim / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                    float W    = max(0.001, focD * frag2dCosT - frag2d_sl * frag2dSinT);
                    // Camera at (_ViewShift, focD*cosT, focD*sinT): shift adds lateral parallax.
                    // base (y=0):  x = (sa*focD*cosT - shift*sl*sinT) / W
                    // face (y=tH): x = (sa*(focD*cosT-tH) + shift*(tH-sl*sinT)) / W
                    frag2dBasePos = float2(
                         (frag2d_sa * focD * frag2dCosT - UI_VIEW_SHIFT * frag2d_sl * frag2dSinT) / W,
                        -focD * frag2d_sl / W);
                    frag2dFacePos = float2(
                         (frag2d_sa * (focD * frag2dCosT - frag2dTotalH) + UI_VIEW_SHIFT * (frag2dTotalH - frag2d_sl * frag2dSinT)) / W,
                        (frag2dTotalH * (frag2d_sl * frag2dCosT + focD * frag2dSinT) - focD * frag2d_sl) / W);
                } else {
                    float cosTsafe = max(0.001, frag2dCosT);
                    frag2dBasePos = float2(frag2d_sa, -frag2d_sl / cosTsafe);
                    frag2dFacePos = float2(frag2d_sa, -frag2d_sl / cosTsafe + frag2dTotalH * frag2dSinT / cosTsafe);
                }
                // frag2dBodyPos = base-plane pos with button shape rotation (for edge + border)
                float2 frag2dBodyPos = frag2dBasePos;
                if (abs(_ButtonShapeRotation) > 0.001)
                    frag2dBodyPos = rotate2D(frag2dBodyPos, _ButtonShapeRotation * (PI / 180.0));
                // ─────────────────────────────────────────────────────────────────────────

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

                    // frag2dBodyPos, not `pos`: the base-plane projection the body is actually
                    // drawn at, so the recess follows the widget through _ViewTilt/_ViewShift/_ViewFOV
                    // instead of sitting at the untilted footprint.
                    float indentAlpha = calculateButtonEdgeIndent(uv, frag2dBodyPos, _EdgeWidth, _EdgeSoftness,
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
                // 2. External shadows (behind button) — tilt-aware
                // ============================================================
                // External shadows reuse the shared flat-layer tilt params (frag2d*)
                float2 extTiltDir     = frag2dTiltDir;
                float2 extTiltNormDir = frag2dTiltNormDir;
                float  extCosTpre     = frag2dCosT;
                float  extSinTpre     = frag2dSinT;

                // Compute faceInset so external shadows can cut the face opening hole.
                float extBevelDist = (_ButtonBevelEnabled > 0.5) ? _ButtonBevelDistance : 0.0;
                float extRimWidth  = (_ButtonRimEnabled  > 0.5) ? _ButtonRimWidth  : 0.0;
                float extFaceInset = extRimWidth + extBevelDist;

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
                        float shadowAlpha = computeRMButtonShadowAlpha(uv, lightDir1,
                            _LightingShadow1Blur, _LightingShadow1Distance, _LightingShadow1BlurFactor, 0.0, 1.0,
                            extTiltDir, extTiltNormDir, extCosTpre, extSinTpre,
                            bodyHalfW, bodyHalfH, extFaceInset, 0.0, aspectScale, shadowAaUnit);
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _LightingShadow1Color.rgb, _LightingShadow1Color.a * shadowAlpha * _LightingShadow1Intensity);
                        }
                    }
                    if (_LightingShadow2Enabled > 0.5) {
                        float shadowAlpha = computeRMButtonShadowAlpha(uv, lightDir2,
                            _LightingShadow2Blur, _LightingShadow2Distance, _LightingShadow2BlurFactor, 0.0, 1.0,
                            extTiltDir, extTiltNormDir, extCosTpre, extSinTpre,
                            bodyHalfW, bodyHalfH, extFaceInset, 0.0, aspectScale, shadowAaUnit);
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _LightingShadow2Color.rgb, _LightingShadow2Color.a * shadowAlpha * _LightingShadow2Intensity);
                        }
                    }
                    if (_LightingShadow3Enabled > 0.5) {
                        float shadowAlpha = computeRMButtonShadowAlpha(uv, lightDir3,
                            _LightingShadow3Blur, _LightingShadow3Distance, _LightingShadow3BlurFactor, 0.0, 1.0,
                            extTiltDir, extTiltNormDir, extCosTpre, extSinTpre,
                            bodyHalfW, bodyHalfH, extFaceInset, 0.0, aspectScale, shadowAaUnit);
                        if (shadowAlpha > 0.001) {
                            buttonCompositeOver(castShadow, _LightingShadow3Color.rgb, _LightingShadow3Color.a * shadowAlpha * _LightingShadow3Intensity);
                        }
                    }

                    // RM body/cast shadows via hull sweep (identical inputs to what
                    // renderRaymarchButton computed for these blocks originally:
                    // frag2dTiltDir==tiltDir, frag2dCosT==cosTpre, frag2dTotalH==totalHeight,
                    // extFaceInset==faceInset — same formulas, shared here).
                    UNITY_LOOP for (int si = 0; si < 3; si++) {
                        ButtonShadowSlot sl = buttonShadowSlot(si, lightDir1, lightDir2, lightDir3);
                        if (sl.enabled < 0.5) continue;
                        float sa = computeRMButtonShadowAlpha(uv, sl.lightDir,
                            sl.blur, sl.dist, sl.blurFac, sl.castMul, sl.maxCast,
                            frag2dTiltDir, frag2dTiltNormDir, frag2dCosT, frag2dSinT,
                            bodyHalfW, bodyHalfH, extFaceInset, frag2dTotalH, aspectScale, shadowAaUnit);
                        if (sa > 0.001) buttonCompositeOver(castShadow, sl.color, sl.colorA * sa * sl.intensity);
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
                // 3. Body edge indent (before RM body)
                // ============================================================
                // (Edge indent already rendered above in section 1)

                // ============================================================
                // 4a. Border — rendered BEFORE body so body composites on top.
                // Uses frag2dBodyPos (base-plane, tilt+FOV corrected) so it follows
                // the button's projected canvas footprint and doesn't render over walls
                // (wall pixels unproject to inside the base shape → borderInner = 0).
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

                    // Same ring the Edge draws, same base-plane frame — see UIRingMask. The only
                    // difference between the two components is _BorderFalloff vs _EdgeFalloff.
                    float borderBodyDist = getButtonSDF(frag2dBodyPos, bodyHalfW, bodyHalfH, bodyShapeType,
                                                        _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3);
                    float borderAAVal    = fwidth(borderBodyDist) * 0.75;
                    float borderTerritory = UIRingMask(borderBodyDist, _BorderInset, _BorderWidth,
                                                       _BorderSoftness, _BorderFalloff, borderAAVal);
                    float borderMask     = borderTerritory * _BorderIntensity;

                    float borderPresence = max(_BorderRenderAlpha, _BorderRenderEmissive);
                    float effectiveTerritory = borderTerritory * borderPresence;
                    if (effectiveTerritory > 0.001) {
                        float clearFactor = 1.0 - effectiveTerritory;
                        finalColor.rgb *= clearFactor;
                        finalColor.a   *= clearFactor;
                        emissiveAccum  *= clearFactor;
                    }

                    if (borderMask > 0.001) {
                        buttonCompositeOver(finalColor, borderBaseColor, borderMask * _BorderRenderAlpha);
                        emissiveAccum += borderBaseColor * borderMask * _BorderRenderEmissive;
                    }
                }

                // ============================================================
                // 4a2. Self-shadow — the IN-QUAD half of this button's own cast shadow.
                //
                // The body stands above the Edge recess and the Border ring, so it throws a
                // shadow across them. The shared buffer holds only the OUTSIDE half (see the
                // cast-shadow block at the top of frag), precisely so this button can read that
                // buffer for its neighbours' shadows without darkening its own face with its
                // own. `castShadow` was already scaled by the in-quad complement up there, so
                // this is just the application — and it is the SAME layer the backing quad
                // emits, which is what makes the two halves the same silhouette by
                // construction, with no second hand-synced approximation to drift out of step.
                //
                // BEFORE the body, so the body's own draw covers its footprint. Unlike the knob
                // a button has no separate raised element standing on a base, so applying it
                // again after the body would just smear the button's own face with its own
                // shadow (tried, reverted — it reads as painted over rather than lit).
                // ============================================================
                if (castShadow.a > 0.002) {
                    UIApplySelfShadow(finalColor, castShadow.rgb / max(castShadow.a, 1e-4), castShadow.a);
                }

                // ============================================================
                // 4b. Raymarched body (composites on top of border)
                // ============================================================
                renderRaymarchButton(uv, pos, time, light1, light2, light3, finalColor, emissiveAccum);

                // ============================================================
                // 5. Icon rendering (on top of body)
                // ============================================================
            #ifdef COMPILE_ICON
                if (_IconEnabled > 0.5) {
                    // Icon sits on the tilted face plane (FOV-corrected via frag2dFacePos).
                    // _IconOffset.xy is a screen-space offset; convert to face-local coords
                    // by the same tilt-basis decomposition used to build frag2dFacePos.
                    float2 iconFaceOff = float2(
                         dot(_IconOffset.xy, frag2dTiltNormDir),
                        -dot(_IconOffset.xy, frag2dTiltDir) / max(0.001, frag2dCosT));
                    float2 iconPos = frag2dFacePos - iconFaceOff;
                    // ⚠ THE FACE'S LATERAL AXIS POINTS LEFT, AND AN ICON IS THE ONE LAYER THAT
                    // CAN TELL. frag2dTiltNormDir is (-cos A, -sin A), so frag2d_sa — and every
                    // x that comes out of the projection above — is the NEGATIVE of screen x.
                    // The button's own shape never noticed (a rounded rect is its own mirror),
                    // but getIconSDF's marks are drawn +x to the RIGHT: the built-in play
                    // triangle (case 6), the mute speaker (17) and every PanelGlyphAtlas slice
                    // came out mirrored, which is why the transport's PLAY pointed left and the
                    // takes strip's PREV/NEXT arrows had swapped.
                    //
                    // Flipped HERE rather than inside getIconSDF, because this is the shader that
                    // knows which way its own face runs; the icon library stays a plain
                    // "+x right, -y up" space that every caller can author against. Applied
                    // before the rotation so _IconShapeRotation turns the way it reads on screen.
                    iconPos.x = -iconPos.x;
                    if (abs(_IconShapeRotation) > 0.001)
                        iconPos = rotate2D(iconPos, _IconShapeRotation * (PI / 180.0));

                    float iconDist = getIconSDF(iconPos, _IconShapeType, _IconWidth, _IconHeight,
                                                 _IconShapeParam1, _IconShapeParam2, _IconShapeParam3);
                    float iconDistScreen = iconDist * frag2dCosT;
                    float iconAA   = fwidth(iconDistScreen) * 0.75;
                    float iconMask = smoothstep(iconAA, -iconAA, iconDistScreen);

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
                        float3 patternedColor = ApplyMaterialPattern(baseColor, uv, iconComponent, 0.0, 0.0,
                                                                   specularMod, normalOffset);

                        float effectiveIconBevelDepth = (_IconBevelEnabled > 0.5) ? iconComponent.bevelDepth : 0.0;
                        float3 iconNormal = CalculateShapeBevelNormal(iconDist, effectiveIconBevelDepth,
                                               iconComponent.bevelDistance, iconComponent.bevelSmoothness, iconComponent.fillFaceSmoothness,
                                               0, 0.5);

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
            #endif // COMPILE_ICON

                // ============================================================
                // 6. Play ring + loop glyph (on the face plane, over the icon)
                // ============================================================
                // Uniform-driven branches only, so fwidth() stays defined inside them.
                if (_PlayRingEnabled > 0.5 || _LoopGlyphActive > 0.5) {
                    float dPad = getButtonSDF(frag2dFacePos, bodyHalfW, bodyHalfH, bodyShapeType,
                                              _ButtonShapeParam1, _ButtonShapeParam2, _ButtonShapeParam3);
                    // face lateral axis is screen-mirrored (see the icon block)
                    PlayRingApply(dPad, float2(-frag2dFacePos.x, frag2dFacePos.y), float2(bodyHalfW, bodyHalfH),
                                  extFaceInset, finalColor, emissiveAccum);
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

                // Receive shadows cast by every OTHER widget and panel.
                //
                // This widget's own contribution is not in the buffer at its own pixels — the
                // shadow pass punched its silhouette out (see the punch-out in the
                // _ShadowPassMode block). So this is other people's shadows only, and a pad
                // finally darkens under the pad above it instead of the shadow stopping dead
                // at the neighbour's edge.
                //
                // BEFORE the emissive add, deliberately: an emissive face is its own light
                // source and is not shadowed by a neighbour standing next to it.
                // _ReceiveSceneShadows is the same opt-out SDFPanel has, so AppShell's
                // "an overlay must not show what is behind it" pass now actually reaches
                // buttons — it only ever reached panels before, because only panels had the
                // property it writes.
                if (_ReceiveSceneShadows > 0.5 && finalColor.a > 0.001) {
                    finalColor.rgb *= sampleUIShadowBuffer(IN.screenPos.xy / IN.screenPos.w);
                }

                // Premultiplied alpha output with additive emissive
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
