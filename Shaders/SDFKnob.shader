// SDFKnob Shader
// Advanced UI knob control with multiple visual components:
//
// COMPONENTS:
// 1. Fill - Static circular area (doesn't rotate), base of the knob
// 2. Line - Arc track that shows the available range
// 3. Value - Arc segments showing filled/unfilled portions of the value
// 4. Knob - Rotatable component that shows current position
// 5. Shadow System - External shadows and internal component shadows
// 6. Cut-in Border - Alpha border effect for realistic recessed appearance
//
// KNOB FEATURES:
// - _KnobEnabled: Toggle knob visibility
// - _KnobSize: Size as factor of fill radius (0-1)
// - _KnobShapeType: 0=Circle 1=GripNubs 2=Polygon 3=DShaft 4=Star 5=Squircle 6=Fluted 7=Cross
//                   8=ChickenHead 9=Arrow 10=Gear 11=Skirted 12=OvalPointer 13=MushroomCap
//                   14=DaviesIndicator 15=ColletKnob 16=RingPointer 17=BlobStar 18=CapScrew 19=TaperDisc
// - _KnobShapeScale: multipurpose scale per shape (sides/teeth/points count etc.)
// - _KnobShapeParam1/2/3: per-shape tuning parameters (see KnobShapeType enum for details)
// - _KnobRoundness: universal edge/corner rounding applied post-SDF to any shape (0-1)
// - _KnobRotation: rotation offset in degrees applied to knob body AND KnobNub orbit (independent of value)
// - _KnobNubShapeRotation / _NubShapeRotation: per-shape-instance rotation for KnobNub / Nub shapes
// - _NubRotation: rotation offset applied to the Nub orbit position (independent of value)
// - _KnobFaceShapeEnabled: use an independent face shape (inner boundary of bevel zone / top face silhouette)
//   When disabled: face boundary = outer shape inset by _KnobBevelDistance (original behaviour)
//   When enabled:  face boundary = separate shape with its own type/scale/params/size/rotation
//   _KnobFaceShapeSize: relative radius of face (fraction of knobRadius, 0.01-1). Lower = wider wall/bevel.
//   _KnobFaceShapeType/Scale/Param1-6/Rotation: same semantics as outer shape params.
// - Full material system support (patterns, gradients, lighting)
//
// SHADOW SYSTEM:
// - External shadows cast by the entire knob
// - Internal shadows between components for depth
// - Configurable shadow color, offset, blur, and intensity
//
// CUT-IN BORDER:
// - Creates realistic recessed knob appearance
// - Works with any angle range and start angle
// - Optional bevel effect for enhanced realism
// - Alpha-based for compositing over background textures
//
// FILL vs KNOB:
// - Fill provides static background (pattern doesn't rotate)
// - Knob rotates with _Value and shows current position
// - Both support full rendering pipeline (bevels, patterns, lighting)
//
// ============================================================================
// SDFKnob.shader - Modern SDF UI Shader with Pure Function Architecture
// ============================================================================
// This shader demonstrates the recommended architecture pattern for SDF UI shaders.
// It serves as the reference implementation for SDFButton, SDFSlider, and SDFPanel shaders.
//
// KEY ARCHITECTURAL PRINCIPLES:
// 1. .cginc files contain ONLY functions, structs, and constants (no properties)
// 2. Shader-specific properties declared in .shader file CGPROGRAM section
// 3. All function parameters passed explicitly (no hidden dependencies)
// 4. Exception: Global uniforms in UIGlobalUniforms.cginc for screen effects
//
// LIGHTING PATTERN:
//   - Declare: float _LightingAmbient;
//   - Pass to: ApplyUILighting(normal, color, _LightingAmbient, ...)
//
// This ensures maximum reusability and no hidden coupling between shaders.
// ============================================================================

Shader "UI/SDFKnob"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}

        // Fill component (center area up to _LineRadius)
        _FillEnabled ("Fill Enabled", Float) = 1
        _FillColor ("Fill Color", Color) = (0.2, 0.4, 0.8, 1)
        _FillRenderAlpha ("Fill Render Alpha", Range(0,1)) = 1
        _FillRenderEmissive ("Fill Render Emissive", Range(0, 1)) = 0

        // Line component (from _LineRadius to _LineRadius + _LineWidth)
        _LineEnabled ("Line Enabled", Float) = 1
        _LineColor ("Line Color", Color) = (0.8, 0.8, 0.8, 1)
        _LineRenderAlpha ("Line Render Alpha", Range(0,1)) = 1
        _LineRenderEmissive ("Line Render Emissive", Range(0, 1)) = 0

        // Knob geometry
        _LineRadius ("Line Radius", Range(0.1, 1.0)) = 0.3
        _LineWidth ("Line Width", Range(0.01, 0.5)) = 0.1

        // Angle configuration
        _AngleStart ("Start Angle (Degrees)", Float) = 0
        _AngleRange ("Angle Range (Degrees)", Float) = 270
        _Value ("Value", Range(0,1)) = 0.5
        _LineRoundedEnabled ("Rounded Ends", Float) = 1

        // Fill bevel controls
        _FillBevelEnabled ("Fill Bevel Enabled", Float) = 0
        _FillBevelDepth ("Fill Bevel Depth", Range(-1.0, 1.0)) = 0.2
        _FillBevelSmoothness ("Fill Bevel Smoothness", Range(0.001, 1.0)) = 0.02
        _FillBevelDistance ("Fill Bevel Distance", Range(0.001, 1.0)) = 0.1
        _FillFaceSmoothness ("Fill Face Smoothness", Range(-1.0, 1.0)) = 0.0

        // Fill bevel pattern
        _FillBevelPatternEnabled ("Fill Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _FillBevelPatternType ("Fill Bevel Pattern Type", Int) = 0
        _FillBevelPatternScale ("Fill Bevel Pattern Scale", Range(1, 100)) = 20
        _FillBevelPatternIntensity ("Fill Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _FillBevelPatternContrast ("Fill Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _FillBevelPatternSpecularEffect ("Fill Bevel Pattern Specular Effect", Range(0, 2)) = 1.0
        _FillBevelPatternRoughnessEffect ("Fill Bevel Pattern Roughness Effect", Range(0, 2)) = 0.3
        _FillBevelPatternParam1 ("Fill Bevel Pattern Detail", Range(0, 1)) = 0.5
        _FillBevelPatternParam2 ("Fill Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _FillBevelPatternParam3 ("Fill Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Fill bevel pattern color
        _FillBevelPatternColorEnabled ("Fill Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _FillBevelPatternColorType ("Fill Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _FillBevelPatternColorMode ("Fill Bevel Pattern Color Mode", Int) = 1
        [IntRange] _FillBevelPatternColorUsed ("Fill Bevel Pattern Color Used", Range(2, 4)) = 2
        _FillBevelPatternColorA ("Fill Bevel Pattern Color A", Color) = (1,1,1,1)
        _FillBevelPatternColorB ("Fill Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _FillBevelPatternColorC ("Fill Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _FillBevelPatternColorD ("Fill Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Fill bevel gradient
        _FillBevelGradientEnabled ("Fill Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _FillBevelGradientType ("Fill Bevel Gradient Type", Int) = 1
        _FillBevelGradientColorA ("Fill Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _FillBevelGradientColorB ("Fill Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _FillBevelGradientColorC ("Fill Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _FillBevelGradientColorD ("Fill Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _FillBevelGradientDirection ("Fill Bevel Gradient Direction", Vector) = (1, 0, 0, 0)
        _FillBevelGradientSpeed ("Fill Bevel Gradient Speed", Float) = 1.0
        _FillBevelGradientScale ("Fill Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _FillBevelGradientOffset ("Fill Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _FillBevelGradientColorUsed ("Fill Bevel Gradient Color Used", Range(2, 4)) = 4

        // Fill rim bevel
        _FillRimEnabled ("Fill Rim Bevel Enabled", Float) = 0
        _FillRimDepth ("Fill Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _FillRimWidth ("Fill Rim Bevel Width", Range(0.001, 0.1)) = 0.02
        _FillRimSmoothness ("Fill Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01

        // Fill material pattern
        _FillPatternEnabled ("Fill Pattern Enabled", Float) = 0
        [Enum(PatternType)] _FillPatternType ("Fill Pattern Type", Int) = 0
        _FillPatternScale ("Fill Pattern Scale", Range(1, 100)) = 20
        _FillPatternIntensity ("Fill Pattern Intensity", Range(0, 1)) = 0.3
        _FillPatternContrast ("Fill Pattern Contrast", Range(0.1, 5)) = 1.5
        _FillPatternSpecularEffect ("Fill Pattern Specular Effect", Range(0, 2)) = 1.0
        _FillPatternRoughnessEffect ("Fill Pattern Roughness Effect", Range(0, 2)) = 0.3
        _FillPatternRotateEnabled ("Fill Pattern Rotate Enabled", Float) = 0
        _FillPatternModEnabled ("Fill Pattern Mod Enabled", Float) = 0
        _FillPatternModAmount ("Fill Pattern Mod Amount", Range(0, 90)) = 20
        _FillPatternModFrequency ("Fill Pattern Mod Frequency", Range(0.1, 10)) = 1
        _FillPatternOffset ("Fill Pattern Offset", Range(-180, 180)) = 0
        _FillPatternParam1 ("Fill Pattern Detail", Range(0, 1)) = 0.5
        _FillPatternParam2 ("Fill Pattern Distortion", Range(0, 1)) = 0.5
        _FillPatternParam3 ("Fill Pattern Blend", Range(0, 1)) = 0.5

        // Fill pattern color
        _FillPatternColorEnabled ("Fill Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _FillPatternColorType ("Fill Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _FillPatternColorMode ("Fill Pattern Color Mode", Int) = 1
        [IntRange] _FillPatternColorUsed ("Fill Pattern Color Used", Range(2, 4)) = 2
        _FillPatternColorA ("Fill Pattern Color A", Color) = (1,1,1,1)
        _FillPatternColorB ("Fill Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _FillPatternColorC ("Fill Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _FillPatternColorD ("Fill Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Fill gradient properties
        _FillGradientEnabled ("Fill Gradient Enabled", Float) = 0
        [Enum(GradientType)] _FillGradientType ("Fill Gradient Type", Int) = 0
        _FillGradientColorA ("Fill Gradient Color A", Color) = (1, 0, 0, 1)
        _FillGradientColorB ("Fill Gradient Color B", Color) = (0, 1, 0, 1)
        _FillGradientColorC ("Fill Gradient Color C", Color) = (0, 0, 1, 1)
        _FillGradientColorD ("Fill Gradient Color D", Color) = (1, 1, 0, 1)
        _FillGradientDirection ("Fill Gradient Direction", Vector) = (1, 0, 0, 0)
        _FillGradientSpeed ("Fill Gradient Speed", Float) = 1.0
        _FillGradientScale ("Fill Gradient Scale", Range(0.1, 5)) = 1.0
        _FillGradientOffset ("Fill Gradient Offset", Range(-2, 2)) = 0.0
        _FillGlobalBlend ("Fill Global Blend", Range(0, 1)) = 0.0
        _FillGlobalIntensity ("Fill Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _FillGradientColorUsed ("Fill Gradient Color Used", Range(2, 4)) = 4

        // Line bevel controls
        _LineBevelEnabled ("Line Bevel Enabled", Float) = 0
        _LineBevelDepth ("Line Bevel Depth", Range(-1.0, 1.0)) = 0.05
        _LineBevelSmoothness ("Line Bevel Smoothness", Range(0.001, 3.0)) = 0.02
        _LineBevelDistance ("Line Bevel Distance", Range(0.001, 1.0)) = 0.1
        _LineFaceSmoothness ("Line Face Smoothness", Range(-1.0, 1.0)) = 0.0

        // Line bevel pattern
        _LineBevelPatternEnabled ("Line Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _LineBevelPatternType ("Line Bevel Pattern Type", Int) = 0
        _LineBevelPatternScale ("Line Bevel Pattern Scale", Range(1, 100)) = 20
        _LineBevelPatternIntensity ("Line Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _LineBevelPatternContrast ("Line Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _LineBevelPatternSpecularEffect ("Line Bevel Pattern Specular Effect", Range(0, 2)) = 1.0
        _LineBevelPatternRoughnessEffect ("Line Bevel Pattern Roughness Effect", Range(0, 2)) = 0.3
        _LineBevelPatternParam1 ("Line Bevel Pattern Detail", Range(0, 1)) = 0.5
        _LineBevelPatternParam2 ("Line Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _LineBevelPatternParam3 ("Line Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Line bevel pattern color
        _LineBevelPatternColorEnabled ("Line Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineBevelPatternColorType ("Line Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineBevelPatternColorMode ("Line Bevel Pattern Color Mode", Int) = 1
        [IntRange] _LineBevelPatternColorUsed ("Line Bevel Pattern Color Used", Range(2, 4)) = 2
        _LineBevelPatternColorA ("Line Bevel Pattern Color A", Color) = (1,1,1,1)
        _LineBevelPatternColorB ("Line Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineBevelPatternColorC ("Line Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineBevelPatternColorD ("Line Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Line bevel gradient
        _LineBevelGradientEnabled ("Line Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _LineBevelGradientType ("Line Bevel Gradient Type", Int) = 1
        _LineBevelGradientColorA ("Line Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _LineBevelGradientColorB ("Line Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _LineBevelGradientColorC ("Line Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _LineBevelGradientColorD ("Line Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _LineBevelGradientDirection ("Line Bevel Gradient Direction", Vector) = (1, 0, 0, 0)
        _LineBevelGradientSpeed ("Line Bevel Gradient Speed", Float) = 1.0
        _LineBevelGradientScale ("Line Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _LineBevelGradientOffset ("Line Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _LineBevelGradientColorUsed ("Line Bevel Gradient Color Used", Range(2, 4)) = 4

        // Line rim bevel
        _LineRimEnabled ("Line Rim Bevel Enabled", Float) = 0
        _LineRimDepth ("Line Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _LineRimWidth ("Line Rim Bevel Width", Range(0.001, 0.1)) = 0.02
        _LineRimSmoothness ("Line Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01

        // Line material pattern
        _LinePatternEnabled ("Line Pattern Enabled", Float) = 0
        [Enum(PatternType)] _LinePatternType ("Line Pattern Type", Int) = 0
        _LinePatternScale ("Line Pattern Scale", Range(1, 100)) = 20
        _LinePatternIntensity ("Line Pattern Intensity", Range(0, 1)) = 0.3
        _LinePatternContrast ("Line Pattern Contrast", Range(0.1, 5)) = 1.5
        _LinePatternSpecularEffect ("Line Pattern Specular Effect", Range(0, 2)) = 1.0
        _LinePatternRoughnessEffect ("Line Pattern Roughness Effect", Range(0, 2)) = 0.3
        _LinePatternRotateEnabled ("Line Pattern Rotate Enabled", Float) = 0
        _LinePatternModEnabled ("Line Pattern Mod Enabled", Float) = 0
        _LinePatternModAmount ("Line Pattern Mod Amount", Range(0, 90)) = 20
        _LinePatternModFrequency ("Line Pattern Mod Frequency", Range(0.1, 10)) = 1
        _LinePatternOffset ("Line Pattern Offset", Range(-180, 180)) = 0
        _LinePatternParam1 ("Line Pattern Detail", Range(0, 1)) = 0.5
        _LinePatternParam2 ("Line Pattern Distortion", Range(0, 1)) = 0.5
        _LinePatternParam3 ("Line Pattern Blend", Range(0, 1)) = 0.5

        // Line pattern color
        _LinePatternColorEnabled ("Line Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LinePatternColorType ("Line Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LinePatternColorMode ("Line Pattern Color Mode", Int) = 1
        [IntRange] _LinePatternColorUsed ("Line Pattern Color Used", Range(2, 4)) = 2
        _LinePatternColorA ("Line Pattern Color A", Color) = (1,1,1,1)
        _LinePatternColorB ("Line Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LinePatternColorC ("Line Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LinePatternColorD ("Line Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Line gradient properties
        _LineGradientEnabled ("Line Gradient Enabled", Float) = 0
        [Enum(GradientType)] _LineGradientType ("Line Gradient Type", Int) = 0
        _LineGradientColorA ("Line Gradient Color A", Color) = (1, 0, 0, 1)
        _LineGradientColorB ("Line Gradient Color B", Color) = (0, 1, 0, 1)
        _LineGradientColorC ("Line Gradient Color C", Color) = (0, 0, 1, 1)
        _LineGradientColorD ("Line Gradient Color D", Color) = (1, 1, 0, 1)
        _LineGradientDirection ("Line Gradient Direction", Vector) = (1, 0, 0, 0)
        _LineGradientSpeed ("Line Gradient Speed", Float) = 1.0
        _LineGradientScale ("Line Gradient Scale", Range(0.1, 5)) = 1.0
        _LineGradientOffset ("Line Gradient Offset", Range(-2, 2)) = 0.0
        _LineGlobalBlend ("Line Global Blend", Range(0, 1)) = 0.0
        _LineGlobalIntensity ("Line Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _LineGradientColorUsed ("Line Gradient Color Used", Range(2, 4)) = 4

        // Value components (filled and unfilled)
        _LineSublineFilledEnabled ("Line Subline Filled Enabled", Float) = 1
        _LineSublineFilledColor ("Line Subline Filled Color", Color) = (0.2, 0.8, 0.2, 1.0)
        _LineSublineFilledRenderAlpha ("Line Subline Filled Render Alpha", Range(0, 1)) = 1.0
        _LineSublineFilledRenderEmissive ("Line Subline Filled Render Emissive", Range(0, 1)) = 0
        _LineSublineFilledBevelEnabled ("Line Subline Filled Bevel Enabled", Float) = 0
        _LineSublineFilledBevelDepth ("Line Subline Filled Bevel Depth", Range(-1.0, 1.0)) = 0.03
        _LineSublineFilledBevelSmoothness ("Line Subline Filled Bevel Smoothness", Range(0.001, 0.2)) = 0.02
        _LineSublineFilledBevelDistance ("Line Subline Filled Bevel Distance", Range(0.001, 1.0)) = 0.1
        _LineSublineFilledFaceSmoothness ("Line Subline Filled Face Smoothness", Range(-1.0, 1.0)) = 0.0

        // Value filled bevel pattern
        _LineSublineFilledBevelPatternEnabled ("Line Subline Filled Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _LineSublineFilledBevelPatternType ("Line Subline Filled Bevel Pattern Type", Int) = 0
        _LineSublineFilledBevelPatternScale ("Line Subline Filled Bevel Pattern Scale", Range(1, 100)) = 20
        _LineSublineFilledBevelPatternIntensity ("Line Subline Filled Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _LineSublineFilledBevelPatternContrast ("Line Subline Filled Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _LineSublineFilledBevelPatternSpecularEffect ("Line Subline Filled Bevel Pattern Specular Effect", Range(0, 2)) = 1.0
        _LineSublineFilledBevelPatternRoughnessEffect ("Line Subline Filled Bevel Pattern Roughness Effect", Range(0, 2)) = 0.3
        _LineSublineFilledBevelPatternParam1 ("Line Subline Filled Bevel Pattern Detail", Range(0, 1)) = 0.5
        _LineSublineFilledBevelPatternParam2 ("Line Subline Filled Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _LineSublineFilledBevelPatternParam3 ("Line Subline Filled Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Line subline filled bevel pattern color
        _LineSublineFilledBevelPatternColorEnabled ("Line Subline Filled Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineFilledBevelPatternColorType ("Line Subline Filled Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineFilledBevelPatternColorMode ("Line Subline Filled Bevel Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineFilledBevelPatternColorUsed ("Line Subline Filled Bevel Pattern Color Used", Range(2, 4)) = 2
        _LineSublineFilledBevelPatternColorA ("Line Subline Filled Bevel Pattern Color A", Color) = (1,1,1,1)
        _LineSublineFilledBevelPatternColorB ("Line Subline Filled Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineFilledBevelPatternColorC ("Line Subline Filled Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineFilledBevelPatternColorD ("Line Subline Filled Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Value filled bevel gradient
        _LineSublineFilledBevelGradientEnabled ("Line Subline Filled Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _LineSublineFilledBevelGradientType ("Line Subline Filled Bevel Gradient Type", Int) = 1
        _LineSublineFilledBevelGradientColorA ("Line Subline Filled Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _LineSublineFilledBevelGradientColorB ("Line Subline Filled Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _LineSublineFilledBevelGradientColorC ("Line Subline Filled Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _LineSublineFilledBevelGradientColorD ("Line Subline Filled Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _LineSublineFilledBevelGradientDirection ("Line Subline Filled Bevel Gradient Direction", Vector) = (1, 0, 0, 0)
        _LineSublineFilledBevelGradientSpeed ("Line Subline Filled Bevel Gradient Speed", Float) = 1.0
        _LineSublineFilledBevelGradientScale ("Line Subline Filled Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _LineSublineFilledBevelGradientOffset ("Line Subline Filled Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _LineSublineFilledBevelGradientColorUsed ("Line Subline Filled Bevel Gradient Color Used", Range(2, 4)) = 4

        // Value filled rim bevel
        _LineSublineFilledRimEnabled ("Line Subline Filled Rim Bevel Enabled", Float) = 0
        _LineSublineFilledRimDepth ("Line Subline Filled Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _LineSublineFilledRimWidth ("Line Subline Filled Rim Bevel Width", Range(0.001, 0.1)) = 0.02
        _LineSublineFilledRimSmoothness ("Line Subline Filled Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01
        _LineSublineFilledPatternEnabled ("Line Subline Filled Pattern Enabled", Float) = 0
        [Enum(PatternType)] _LineSublineFilledPatternType ("Line Subline Filled Pattern Type", Int) = 0
        _LineSublineFilledPatternScale ("Line Subline Filled Pattern Scale", Range(1, 100)) = 20
        _LineSublineFilledPatternIntensity ("Line Subline Filled Pattern Intensity", Range(0, 1)) = 0.3
        _LineSublineFilledPatternContrast ("Line Subline Filled Pattern Contrast", Range(0.1, 5)) = 1.5
        _LineSublineFilledPatternSpecularEffect ("Line Subline Filled Pattern Specular Effect", Range(0, 2)) = 0.5
        _LineSublineFilledPatternRoughnessEffect ("Line Subline Filled Pattern Roughness Effect", Range(0, 2)) = 0.3
        _LineSublineFilledPatternRotateEnabled ("Line Subline Filled Pattern Rotate Enabled", Float) = 0
        _LineSublineFilledPatternModEnabled ("Line Subline Filled Pattern Mod Enabled", Float) = 0
        _LineSublineFilledPatternModAmount ("Line Subline Filled Pattern Mod Amount", Range(0, 90)) = 20
        _LineSublineFilledPatternModFrequency ("Line Subline Filled Pattern Mod Frequency", Range(0.1, 10)) = 1
        _LineSublineFilledPatternOffset ("Line Subline Filled Pattern Offset", Range(-180, 180)) = 0
        _LineSublineFilledPatternParam1 ("Line Subline Filled Pattern Detail", Range(0, 1)) = 0.5
        _LineSublineFilledPatternParam2 ("Line Subline Filled Pattern Distortion", Range(0, 1)) = 0.5
        _LineSublineFilledPatternParam3 ("Line Subline Filled Pattern Blend", Range(0, 1)) = 0.5

        // Line subline filled pattern color
        _LineSublineFilledPatternColorEnabled ("Line Subline Filled Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineFilledPatternColorType ("Line Subline Filled Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineFilledPatternColorMode ("Line Subline Filled Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineFilledPatternColorUsed ("Line Subline Filled Pattern Color Used", Range(2, 4)) = 2
        _LineSublineFilledPatternColorA ("Line Subline Filled Pattern Color A", Color) = (1,1,1,1)
        _LineSublineFilledPatternColorB ("Line Subline Filled Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineFilledPatternColorC ("Line Subline Filled Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineFilledPatternColorD ("Line Subline Filled Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Value filled gradient properties
        _LineSublineFilledGradientEnabled ("Line Subline Filled Gradient Enabled", Float) = 0
        [Enum(GradientType)] _LineSublineFilledGradientType ("Line Subline Filled Gradient Type", Int) = 0
        _LineSublineFilledGradientColorA ("Line Subline Filled Gradient Color A", Color) = (1, 0, 0, 1)
        _LineSublineFilledGradientColorB ("Line Subline Filled Gradient Color B", Color) = (0, 1, 0, 1)
        _LineSublineFilledGradientColorC ("Line Subline Filled Gradient Color C", Color) = (0, 0, 1, 1)
        _LineSublineFilledGradientColorD ("Line Subline Filled Gradient Color D", Color) = (1, 1, 0, 1)
        _LineSublineFilledGradientDirection ("Line Subline Filled Gradient Direction", Vector) = (1, 0, 0, 0)
        _LineSublineFilledGradientSpeed ("Line Subline Filled Gradient Speed", Float) = 1.0
        _LineSublineFilledGradientScale ("Line Subline Filled Gradient Scale", Range(0.1, 5)) = 1.0
        _LineSublineFilledGradientOffset ("Line Subline Filled Gradient Offset", Range(-2, 2)) = 0.0
        _LineSublineFilledGlobalBlend ("Line Subline Filled Global Blend", Range(0, 1)) = 0.0
        _LineSublineFilledGlobalIntensity ("Line Subline Filled Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _LineSublineFilledGradientColorUsed ("Line Subline Filled Gradient Color Used", Range(2, 4)) = 4

        _LineSublineUnfilledEnabled ("Line Subline Unfilled Enabled", Float) = 1
        _LineSublineUnfilledColor ("Line Subline Unfilled Color", Color) = (0.3, 0.3, 0.3, 1.0)
        _LineSublineUnfilledRenderAlpha ("Line Subline Unfilled Render Alpha", Range(0, 1)) = 1.0
        _LineSublineUnfilledRenderEmissive ("Line Subline Unfilled Render Emissive", Range(0, 1)) = 0
        _LineSublineUnfilledBevelEnabled ("Line Subline Unfilled Bevel Enabled", Float) = 0
        _LineSublineUnfilledBevelDepth ("Line Subline Unfilled Bevel Depth", Range(-1.0, 1.0)) = 0.02
        _LineSublineUnfilledBevelSmoothness ("Line Subline Unfilled Bevel Smoothness", Range(0.001, 0.2)) = 0.02
        _LineSublineUnfilledBevelDistance ("Line Subline Unfilled Bevel Distance", Range(0.001, 1.0)) = 0.1
        _LineSublineUnfilledFaceSmoothness ("Line Subline Unfilled Face Smoothness", Range(-1.0, 1.0)) = 0.0

        // Value unfilled bevel pattern
        _LineSublineUnfilledBevelPatternEnabled ("Line Subline Unfilled Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _LineSublineUnfilledBevelPatternType ("Line Subline Unfilled Bevel Pattern Type", Int) = 0
        _LineSublineUnfilledBevelPatternScale ("Line Subline Unfilled Bevel Pattern Scale", Range(1, 100)) = 20
        _LineSublineUnfilledBevelPatternIntensity ("Line Subline Unfilled Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _LineSublineUnfilledBevelPatternContrast ("Line Subline Unfilled Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _LineSublineUnfilledBevelPatternSpecularEffect ("Line Subline Unfilled Bevel Pattern Specular Effect", Range(0, 2)) = 1.0
        _LineSublineUnfilledBevelPatternRoughnessEffect ("Line Subline Unfilled Bevel Pattern Roughness Effect", Range(0, 2)) = 0.3
        _LineSublineUnfilledBevelPatternParam1 ("Line Subline Unfilled Bevel Pattern Detail", Range(0, 1)) = 0.5
        _LineSublineUnfilledBevelPatternParam2 ("Line Subline Unfilled Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _LineSublineUnfilledBevelPatternParam3 ("Line Subline Unfilled Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Line subline unfilled bevel pattern color
        _LineSublineUnfilledBevelPatternColorEnabled ("Line Subline Unfilled Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineUnfilledBevelPatternColorType ("Line Subline Unfilled Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineUnfilledBevelPatternColorMode ("Line Subline Unfilled Bevel Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineUnfilledBevelPatternColorUsed ("Line Subline Unfilled Bevel Pattern Color Used", Range(2, 4)) = 2
        _LineSublineUnfilledBevelPatternColorA ("Line Subline Unfilled Bevel Pattern Color A", Color) = (1,1,1,1)
        _LineSublineUnfilledBevelPatternColorB ("Line Subline Unfilled Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineUnfilledBevelPatternColorC ("Line Subline Unfilled Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineUnfilledBevelPatternColorD ("Line Subline Unfilled Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Value unfilled bevel gradient
        _LineSublineUnfilledBevelGradientEnabled ("Line Subline Unfilled Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _LineSublineUnfilledBevelGradientType ("Line Subline Unfilled Bevel Gradient Type", Int) = 1
        _LineSublineUnfilledBevelGradientColorA ("Line Subline Unfilled Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _LineSublineUnfilledBevelGradientColorB ("Line Subline Unfilled Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _LineSublineUnfilledBevelGradientColorC ("Line Subline Unfilled Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _LineSublineUnfilledBevelGradientColorD ("Line Subline Unfilled Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _LineSublineUnfilledBevelGradientDirection ("Line Subline Unfilled Bevel Gradient Direction", Vector) = (1, 0, 0, 0)
        _LineSublineUnfilledBevelGradientSpeed ("Line Subline Unfilled Bevel Gradient Speed", Float) = 1.0
        _LineSublineUnfilledBevelGradientScale ("Line Subline Unfilled Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _LineSublineUnfilledBevelGradientOffset ("Line Subline Unfilled Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _LineSublineUnfilledBevelGradientColorUsed ("Line Subline Unfilled Bevel Gradient Color Used", Range(2, 4)) = 4

        // Value unfilled rim bevel
        _LineSublineUnfilledRimEnabled ("Line Subline Unfilled Rim Bevel Enabled", Float) = 0
        _LineSublineUnfilledRimDepth ("Line Subline Unfilled Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _LineSublineUnfilledRimWidth ("Line Subline Unfilled Rim Bevel Width", Range(0.001, 0.1)) = 0.02
        _LineSublineUnfilledRimSmoothness ("Line Subline Unfilled Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01
        _LineSublineUnfilledPatternEnabled ("Line Subline Unfilled Pattern Enabled", Float) = 0
        [Enum(PatternType)] _LineSublineUnfilledPatternType ("Line Subline Unfilled Pattern Type", Int) = 0
        _LineSublineUnfilledPatternScale ("Line Subline Unfilled Pattern Scale", Range(1, 100)) = 20
        _LineSublineUnfilledPatternIntensity ("Line Subline Unfilled Pattern Intensity", Range(0, 1)) = 0.3
        _LineSublineUnfilledPatternContrast ("Line Subline Unfilled Pattern Contrast", Range(0.1, 5)) = 1.5
        _LineSublineUnfilledPatternSpecularEffect ("Line Subline Unfilled Pattern Specular Effect", Range(0, 2)) = 0.5
        _LineSublineUnfilledPatternRoughnessEffect ("Line Subline Unfilled Pattern Roughness Effect", Range(0, 2)) = 0.3
        _LineSublineUnfilledPatternRotateEnabled ("Line Subline Unfilled Pattern Rotate Enabled", Float) = 0
        _LineSublineUnfilledPatternModEnabled ("Line Subline Unfilled Pattern Mod Enabled", Float) = 0
        _LineSublineUnfilledPatternModAmount ("Line Subline Unfilled Pattern Mod Amount", Range(0, 90)) = 20
        _LineSublineUnfilledPatternModFrequency ("Line Subline Unfilled Pattern Mod Frequency", Range(0.1, 10)) = 1
        _LineSublineUnfilledPatternOffset ("Line Subline Unfilled Pattern Offset", Range(-180, 180)) = 0
        _LineSublineUnfilledPatternParam1 ("Line Subline Unfilled Pattern Detail", Range(0, 1)) = 0.5
        _LineSublineUnfilledPatternParam2 ("Line Subline Unfilled Pattern Distortion", Range(0, 1)) = 0.5
        _LineSublineUnfilledPatternParam3 ("Line Subline Unfilled Pattern Blend", Range(0, 1)) = 0.5

        // Line subline unfilled pattern color
        _LineSublineUnfilledPatternColorEnabled ("Line Subline Unfilled Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineUnfilledPatternColorType ("Line Subline Unfilled Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineUnfilledPatternColorMode ("Line Subline Unfilled Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineUnfilledPatternColorUsed ("Line Subline Unfilled Pattern Color Used", Range(2, 4)) = 2
        _LineSublineUnfilledPatternColorA ("Line Subline Unfilled Pattern Color A", Color) = (1,1,1,1)
        _LineSublineUnfilledPatternColorB ("Line Subline Unfilled Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineUnfilledPatternColorC ("Line Subline Unfilled Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineUnfilledPatternColorD ("Line Subline Unfilled Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Value unfilled gradient properties
        _LineSublineUnfilledGradientEnabled ("Line Subline Unfilled Gradient Enabled", Float) = 0
        [Enum(GradientType)] _LineSublineUnfilledGradientType ("Line Subline Unfilled Gradient Type", Int) = 0
        _LineSublineUnfilledGradientColorA ("Line Subline Unfilled Gradient Color A", Color) = (1, 0, 0, 1)
        _LineSublineUnfilledGradientColorB ("Line Subline Unfilled Gradient Color B", Color) = (0, 1, 0, 1)
        _LineSublineUnfilledGradientColorC ("Line Subline Unfilled Gradient Color C", Color) = (0, 0, 1, 1)
        _LineSublineUnfilledGradientColorD ("Line Subline Unfilled Gradient Color D", Color) = (1, 1, 0, 1)
        _LineSublineUnfilledGradientDirection ("Line Subline Unfilled Gradient Direction", Vector) = (1, 0, 0, 0)
        _LineSublineUnfilledGradientSpeed ("Line Subline Unfilled Gradient Speed", Float) = 1.0
        _LineSublineUnfilledGradientScale ("Line Subline Unfilled Gradient Scale", Range(0.1, 5)) = 1.0
        _LineSublineUnfilledGradientOffset ("Line Subline Unfilled Gradient Offset", Range(-2, 2)) = 0.0
        _LineSublineUnfilledGlobalBlend ("Line Subline Unfilled Global Blend", Range(0, 1)) = 0.0
        _LineSublineUnfilledGlobalIntensity ("Line Subline Unfilled Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _LineSublineUnfilledGradientColorUsed ("Line Subline Unfilled Gradient Color Used", Range(2, 4)) = 4

        _LineSublineThickness ("Line Subline Thickness", Range(0.1, 1.0)) = 0.5

        // Light 1 (primary)

        // Light 2 (secondary)

        // Light 3 (tertiary)

        // Global light overrides (when enabled, direction comes from global uniform instead of per-material)
        _Position ("UI Position", Vector) = (0, 0, 0, 0)

        // Knob component (rotates with value)
        _KnobEnabled ("Knob Enabled", Float) = 1
        _KnobColor ("Knob Color", Color) = (0.9, 0.9, 0.9, 1.0)
        _KnobRenderAlpha ("Knob Render Alpha", Range(0, 1)) = 1.0
        _KnobRenderEmissive ("Knob Render Emissive", Range(0, 1)) = 0
        _KnobSize ("Knob Size", Range(0.1, 1.0)) = 0.8  // Factor of fill radius
        [Enum(KnobShapeType)] _KnobShapeType ("Knob Shape Type", Int) = 0
        _KnobShapeScale ("Knob Shape Scale", Range(1, 20)) = 6  // Number of grip nubs / polygon sides
        _KnobShapeRotation ("Knob Shape Rotation", Range(-180, 180)) = 0
        _KnobShapeParam1 ("Knob Shape Param 1", Range(0, 1)) = 0.5
        _KnobShapeParam2 ("Knob Shape Param 2", Range(0, 1)) = 0.5
        _KnobShapeParam3 ("Knob Shape Param 3", Range(0, 1)) = 0.5
        _KnobShapeParam4 ("Knob Shape Param 4", Range(0, 1)) = 0.5
        _KnobShapeParam5 ("Knob Shape Param 5", Range(0, 1)) = 0.5
        _KnobShapeParam6 ("Knob Shape Param 6", Range(0, 1)) = 0.5
        _KnobRoundness ("Knob Shape Roundness", Range(0, 1)) = 0         // Universal corner/edge rounding applied to all shapes
        _KnobShapeTexLayer ("Knob Shape Tex Layer", Float) = -1
        _KnobShapeTexScale ("Knob Shape Tex Scale", Vector) = (1, 1, 0, 0)
        _KnobRotation ("Knob Rotation", Range(-180, 180)) = 0  // Rotation offset applied to knob body + KnobNub orbit (degrees)
        // Knob face shape (inner boundary of bevel / top face silhouette in 3D)
        _KnobFaceShapeEnabled ("Knob Face Shape Enabled", Float) = 0
        [Enum(KnobShapeType)] _KnobFaceShapeType ("Knob Face Shape Type", Int) = 0
        _KnobFaceShapeScale ("Knob Face Shape Scale", Range(1, 20)) = 6
        _KnobFaceShapeSize ("Knob Face Shape Size", Range(0.01, 1.0)) = 0.7
        _KnobFaceShapeRotation ("Knob Face Shape Rotation", Range(-180, 180)) = 0
        _KnobFaceShapeParam1 ("Knob Face Shape Param 1", Range(0, 1)) = 0.5
        _KnobFaceShapeParam2 ("Knob Face Shape Param 2", Range(0, 1)) = 0.5
        _KnobFaceShapeParam3 ("Knob Face Shape Param 3", Range(0, 1)) = 0.5
        _KnobFaceShapeParam4 ("Knob Face Shape Param 4", Range(0, 1)) = 0.5
        _KnobFaceShapeParam5 ("Knob Face Shape Param 5", Range(0, 1)) = 0.5
        _KnobFaceShapeParam6 ("Knob Face Shape Param 6", Range(0, 1)) = 0.5
        _KnobFaceShapeTexLayer ("Knob Face Shape Tex Layer", Float) = -1
        _KnobFaceShapeTexScale ("Knob Face Shape Tex Scale", Vector) = (1, 1, 0, 0)
        _KnobBevelEnabled ("Knob Bevel Enabled", Float) = 0
        _KnobBevelDepth ("Knob Bevel Depth", Range(-4.0, 4.0)) = 0.1
        _KnobBevelSmoothness ("Knob Bevel Smoothness", Range(0.001, 0.2)) = 0.02
        _KnobBevelDistance ("Knob Bevel Distance", Range(0.001, 1.0)) = 0.1
        _KnobFaceSmoothness ("Knob Face Smoothness", Range(-1.0, 1.0)) = 0.0
        [Enum(BevelProfileType)] _KnobBevelProfileType ("Knob Bevel Profile Type", Int) = 0
        _KnobBevelProfileSharpness ("Knob Bevel Profile Sharpness", Range(0, 1)) = 0.5

        // Knob bevel pattern
        _KnobBevelPatternEnabled ("Knob Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _KnobBevelPatternType ("Knob Bevel Pattern Type", Int) = 0
        _KnobBevelPatternScale ("Knob Bevel Pattern Scale", Range(1, 100)) = 20
        _KnobBevelPatternIntensity ("Knob Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _KnobBevelPatternContrast ("Knob Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _KnobBevelPatternSpecularEffect ("Knob Bevel Pattern Specular Effect", Range(0, 2)) = 1.0
        _KnobBevelPatternRoughnessEffect ("Knob Bevel Pattern Roughness Effect", Range(0, 2)) = 0.3
        _KnobBevelPatternParam1 ("Knob Bevel Pattern Detail", Range(0, 1)) = 0.5
        _KnobBevelPatternParam2 ("Knob Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _KnobBevelPatternParam3 ("Knob Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Knob bevel pattern color
        _KnobBevelPatternColorEnabled ("Knob Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _KnobBevelPatternColorType ("Knob Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _KnobBevelPatternColorMode ("Knob Bevel Pattern Color Mode", Int) = 1
        [IntRange] _KnobBevelPatternColorUsed ("Knob Bevel Pattern Color Used", Range(2, 4)) = 2
        _KnobBevelPatternColorA ("Knob Bevel Pattern Color A", Color) = (1,1,1,1)
        _KnobBevelPatternColorB ("Knob Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _KnobBevelPatternColorC ("Knob Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _KnobBevelPatternColorD ("Knob Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Knob bevel gradient
        _KnobBevelGradientEnabled ("Knob Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _KnobBevelGradientType ("Knob Bevel Gradient Type", Int) = 1
        _KnobBevelGradientColorA ("Knob Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _KnobBevelGradientColorB ("Knob Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _KnobBevelGradientColorC ("Knob Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _KnobBevelGradientColorD ("Knob Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _KnobBevelGradientDirection ("Knob Bevel Gradient Direction", Vector) = (1, 0, 0, 0)
        _KnobBevelGradientSpeed ("Knob Bevel Gradient Speed", Float) = 1.0
        _KnobBevelGradientScale ("Knob Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _KnobBevelGradientOffset ("Knob Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _KnobBevelGradientColorUsed ("Knob Bevel Gradient Color Used", Range(2, 4)) = 4

        // Knob rim bevel
        _KnobRimEnabled ("Knob Rim Bevel Enabled", Float) = 0
        _KnobRimDepth ("Knob Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _KnobRimWidth ("Knob Rim Bevel Width", Range(0.001, 0.1)) = 0.02
        _KnobRimSmoothness ("Knob Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01
        _KnobPatternEnabled ("Knob Pattern Enabled", Float) = 0
        [Enum(PatternType)] _KnobPatternType ("Knob Pattern Type", Int) = 0
        _KnobPatternScale ("Knob Pattern Scale", Range(1, 100)) = 20
        _KnobPatternIntensity ("Knob Pattern Intensity", Range(0, 1)) = 0.3
        _KnobPatternContrast ("Knob Pattern Contrast", Range(0.1, 5)) = 1.5
        _KnobPatternSpecularEffect ("Knob Pattern Specular Effect", Range(0, 2)) = 1.0
        _KnobPatternRoughnessEffect ("Knob Pattern Roughness Effect", Range(0, 2)) = 0.3
        _KnobPatternRotateEnabled ("Knob Pattern Rotate Enabled", Float) = 1
        _KnobPatternModEnabled ("Knob Pattern Mod Enabled", Float) = 0
        _KnobPatternModAmount ("Knob Pattern Mod Amount", Range(0, 90)) = 20
        _KnobPatternModFrequency ("Knob Pattern Mod Frequency", Range(0.1, 10)) = 1
        _KnobPatternOffset ("Knob Pattern Offset", Range(-180, 180)) = 0
        _KnobPatternParam1 ("Knob Pattern Detail", Range(0, 1)) = 0.5
        _KnobPatternParam2 ("Knob Pattern Distortion", Range(0, 1)) = 0.5
        _KnobPatternParam3 ("Knob Pattern Blend", Range(0, 1)) = 0.5

        // Knob pattern color
        _KnobPatternColorEnabled ("Knob Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _KnobPatternColorType ("Knob Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _KnobPatternColorMode ("Knob Pattern Color Mode", Int) = 1
        [IntRange] _KnobPatternColorUsed ("Knob Pattern Color Used", Range(2, 4)) = 2
        _KnobPatternColorA ("Knob Pattern Color A", Color) = (1,1,1,1)
        _KnobPatternColorB ("Knob Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _KnobPatternColorC ("Knob Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _KnobPatternColorD ("Knob Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Knob gradient properties
        _KnobGradientEnabled ("Knob Gradient Enabled", Float) = 0
        [Enum(GradientType)] _KnobGradientType ("Knob Gradient Type", Int) = 0
        _KnobGradientColorA ("Knob Gradient Color A", Color) = (1, 0, 0, 1)
        _KnobGradientColorB ("Knob Gradient Color B", Color) = (0, 1, 0, 1)
        _KnobGradientColorC ("Knob Gradient Color C", Color) = (0, 0, 1, 1)
        _KnobGradientColorD ("Knob Gradient Color D", Color) = (1, 1, 0, 1)
        _KnobGradientDirection ("Knob Gradient Direction", Vector) = (1, 0, 0, 0)
        _KnobGradientSpeed ("Knob Gradient Speed", Float) = 1.0
        _KnobGradientScale ("Knob Gradient Scale", Range(0.1, 5)) = 1.0
        _KnobGradientOffset ("Knob Gradient Offset", Range(-2, 2)) = 0.0
        _KnobGlobalBlend ("Knob Global Blend", Range(0, 1)) = 0.0
        _KnobGlobalIntensity ("Knob Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _KnobGradientColorUsed ("Knob Gradient Color Used", Range(2, 4)) = 4

        // Shadow system (3 shadows driven by light positions)
        _LightingShadow1Enabled ("Shadow 1 Enabled", Float) = 1
        _LightingShadow1Color ("Shadow 1 Color", Color) = (0, 0, 0, 0.5)
        _LightingShadow1Blur ("Shadow 1 Blur (softness at contact)", Range(0, 0.5)) = 0.02
        _LightingShadow1Intensity ("Shadow 1 Intensity", Range(0, 2)) = 1.0
        _LightingShadow1Distance ("Shadow 1 Distance", Range(0, 0.5)) = 0.1

        _LightingShadow2Enabled ("Shadow 2 Enabled", Float) = 0
        _LightingShadow2Color ("Shadow 2 Color", Color) = (0, 0, 0, 0.3)
        _LightingShadow2Blur ("Shadow 2 Blur (softness at contact)", Range(0, 0.5)) = 0.03
        _LightingShadow2Intensity ("Shadow 2 Intensity", Range(0, 2)) = 0.8
        _LightingShadow2Distance ("Shadow 2 Distance", Range(0, 0.5)) = 0.12

        _LightingShadow3Enabled ("Shadow 3 Enabled", Float) = 0
        _LightingShadow3Color ("Shadow 3 Color", Color) = (0, 0, 0, 0.2)
        _LightingShadow3Blur ("Shadow 3 Blur (softness at contact)", Range(0, 0.5)) = 0.04
        _LightingShadow3Intensity ("Shadow 3 Intensity", Range(0, 2)) = 0.6
        _LightingShadow3Distance ("Shadow 3 Distance", Range(0, 0.5)) = 0.15

        // Shadow blur factors
        _LightingShadow1BlurFactor ("Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow2BlurFactor ("Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow3BlurFactor ("Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.5


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

        // Knob shadows (3 shadows for knob only)
        _KnobShadow1Enabled ("Knob Shadow 1 Enabled", Float) = 1
        _KnobShadow1Color ("Knob Shadow 1 Color", Color) = (0, 0, 0, 0.6)
        _KnobShadow1Blur ("Knob Shadow 1 Blur (softness at contact)", Range(0, 3.0)) = 0.01
        _KnobShadow1Intensity ("Knob Shadow 1 Intensity", Range(0, 2)) = 1.2
        _KnobShadow1Distance ("Knob Shadow 1 Distance", Range(0, 0.2)) = 0.02

        _KnobShadow2Enabled ("Knob Shadow 2 Enabled", Float) = 0
        _KnobShadow2Color ("Knob Shadow 2 Color", Color) = (0, 0, 0, 0.4)
        _KnobShadow2Blur ("Knob Shadow 2 Blur (softness at contact)", Range(0, 0.5)) = 0.02
        _KnobShadow2Intensity ("Knob Shadow 2 Intensity", Range(0, 2)) = 0.8
        _KnobShadow2Distance ("Knob Shadow 2 Distance", Range(0, 0.2)) = 0.03

        _KnobShadow3Enabled ("Knob Shadow 3 Enabled", Float) = 0
        _KnobShadow3Color ("Knob Shadow 3 Color", Color) = (0, 0, 0, 0.3)
        _KnobShadow3Blur ("Knob Shadow 3 Blur (softness at contact)", Range(0, 0.5)) = 0.03
        _KnobShadow3Intensity ("Knob Shadow 3 Intensity", Range(0, 2)) = 0.6
        _KnobShadow3Distance ("Knob Shadow 3 Distance", Range(0, 0.2)) = 0.04

        // Knob shadow blur factors
        _KnobShadow1BlurFactor ("Knob Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _KnobShadow2BlurFactor ("Knob Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _KnobShadow3BlurFactor ("Knob Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.5

        _KnobShadow1Cast ("Knob Shadow 1 Cast", Range(0, 5)) = 1.0
        _KnobShadow2Cast ("Knob Shadow 2 Cast", Range(0, 5)) = 1.0
        _KnobShadow3Cast ("Knob Shadow 3 Cast", Range(0, 5)) = 1.0

        // KnobEdge indent effect (around base shape, under the knob)
        _KnobEdgeEnabled ("Knob Edge Enabled", Float) = 0
        _KnobEdgeColor ("Knob Edge Color", Color) = (0, 0, 0, 0.8)
        _KnobEdgeRenderAlpha ("Knob Edge Render Alpha", Range(0, 1)) = 1
        _KnobEdgeWidth ("Knob Edge Width", Range(0.001, 0.2)) = 0.05
        _KnobEdgeInset ("Knob Edge Inset", Range(-0.1, 0.1)) = 0.0
        _KnobEdgeSoftness ("Knob Edge Softness", Range(0, 2)) = 0.0
        _KnobEdgeIntensity ("Knob Edge Intensity", Range(0, 2)) = 1.0
        _KnobEdgeRenderEmissive ("Knob Edge Render Emissive", Range(0, 1)) = 0

        _KnobEdgeGradientEnabled ("Knob Edge Gradient Enabled", Float) = 0
        [Enum(GradientType)] _KnobEdgeGradientType ("Knob Edge Gradient Type", Int) = 0
        _KnobEdgeGradientColorA ("Knob Edge Gradient Color A", Color) = (1, 0, 0, 1)
        _KnobEdgeGradientColorB ("Knob Edge Gradient Color B", Color) = (0, 1, 0, 1)
        _KnobEdgeGradientColorC ("Knob Edge Gradient Color C", Color) = (0, 0, 1, 1)
        _KnobEdgeGradientColorD ("Knob Edge Gradient Color D", Color) = (1, 1, 0, 1)
        _KnobEdgeGradientDirection ("Knob Edge Gradient Direction", Vector) = (1, 0, 0, 0)
        _KnobEdgeGradientSpeed ("Knob Edge Gradient Speed", Float) = 1.0
        _KnobEdgeGradientScale ("Knob Edge Gradient Scale", Range(0.1, 5)) = 1.0
        _KnobEdgeGradientOffset ("Knob Edge Gradient Offset", Range(-2, 2)) = 0.0
        _KnobEdgeGlobalBlend ("Knob Edge Global Blend", Range(0, 1)) = 0.0
        _KnobEdgeGlobalIntensity ("Knob Edge Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _KnobEdgeGradientColorUsed ("Knob Edge Gradient Color Used", Range(2, 4)) = 4

        // Knob face nub — orbits tilted face center, foreshortened with view tilt
        _KnobNubEnabled ("Knob Nub Enabled", Float) = 0
        _KnobNubColor ("Knob Nub Color", Color) = (1, 1, 1, 1)
        _KnobNubRenderAlpha ("Knob Nub Render Alpha", Range(0, 1)) = 1.0
        _KnobNubSize ("Knob Nub Size", Range(0.005, 0.5)) = 0.08
        _KnobNubDistance ("Knob Nub Distance", Range(0, 1)) = 0.5
        [Enum(KnobShapeType)] _KnobNubShapeType ("Knob Nub Shape Type", Int) = 0
        _KnobNubShapeScale ("Knob Nub Shape Scale", Range(1, 20)) = 6
        _KnobNubShapeRotation ("Knob Nub Shape Rotation", Range(-180, 180)) = 0
        _KnobNubShapeParam1 ("Knob Nub Shape Param 1", Range(0, 1)) = 0.5
        _KnobNubShapeParam2 ("Knob Nub Shape Param 2", Range(0, 1)) = 0.5
        _KnobNubShapeParam3 ("Knob Nub Shape Param 3", Range(0, 1)) = 0.5
        _KnobNubBevelEnabled ("Knob Nub Bevel Enabled", Float) = 0
        _KnobNubBevelDepth ("Knob Nub Bevel Depth", Range(-1.0, 1.0)) = 0.5
        _KnobNubBevelSmoothness ("Knob Nub Bevel Smoothness", Range(0.001, 0.2)) = 0.02
        _KnobNubBevelDistance ("Knob Nub Bevel Distance", Range(0.001, 1.0)) = 0.1
        _KnobNubFaceSmoothness ("Knob Nub Face Smoothness", Range(-1.0, 1.0)) = 0.0

        // Nub component (rotatable indicator/pointer)
        _NubEnabled ("Nub Enabled", Float) = 0
        _NubColor ("Nub Color", Color) = (1, 1, 1, 1)
        _NubRenderAlpha ("Nub Render Alpha", Range(0,1)) = 1
        _NubRenderEmissive ("Nub Render Emissive", Range(0, 1)) = 0
        _NubDistance ("Nub Distance", Range(0, 1)) = 0.4
        _NubRotation ("Nub Rotation", Range(-180, 180)) = 0
        [Enum(KnobShapeType)] _NubShapeType ("Nub Shape Type", Int) = 0
        _NubSizeWidth ("Nub Size Width", Range(0.01, 2.5)) = 0.1
        _NubSizeHeight ("Nub Size Height", Range(0.01, 2.5)) = 0.05
        _NubRounding ("Nub Rounding", Range(0, 0.1)) = 0.01
        _NubShapeParam1 ("Nub Shape Param 1", Range(0, 1)) = 0.5
        _NubShapeParam2 ("Nub Shape Param 2", Range(0, 1)) = 0.5
        _NubShapeParam3 ("Nub Shape Param 3", Range(0, 1)) = 0.5
        _NubShapeRotation ("Nub Shape Rotation", Range(-180, 180)) = 0
        _NubBevelEnabled ("Nub Bevel Enabled", Float) = 0
        _NubBevelDepth ("Nub Bevel Depth", Range(0, 1.0)) = 0.02
        _NubBevelSmoothness ("Nub Bevel Smoothness", Range(0, 1)) = 0.5
        _NubBevelDistance ("Nub Bevel Distance", Range(0, 1.0)) = 0.02
        _NubFaceSmoothness ("Nub Face Smoothness", Range(-1, 1)) = 0

        // Nub bevel pattern
        _NubBevelPatternEnabled ("Nub Bevel Pattern Enabled", Float) = 0
        [Enum(PatternType)] _NubBevelPatternType ("Nub Bevel Pattern Type", Int) = 0
        _NubBevelPatternScale ("Nub Bevel Pattern Scale", Range(1, 100)) = 20
        _NubBevelPatternIntensity ("Nub Bevel Pattern Intensity", Range(0, 1)) = 0.3
        _NubBevelPatternContrast ("Nub Bevel Pattern Contrast", Range(0.1, 5)) = 1.5
        _NubBevelPatternSpecularEffect ("Nub Bevel Pattern Specular Effect", Range(0, 2)) = 1.0
        _NubBevelPatternRoughnessEffect ("Nub Bevel Pattern Roughness Effect", Range(0, 2)) = 0.3
        _NubBevelPatternParam1 ("Nub Bevel Pattern Detail", Range(0, 1)) = 0.5
        _NubBevelPatternParam2 ("Nub Bevel Pattern Distortion", Range(0, 1)) = 0.5
        _NubBevelPatternParam3 ("Nub Bevel Pattern Blend", Range(0, 1)) = 0.5

        // Nub bevel pattern color
        _NubBevelPatternColorEnabled ("Nub Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _NubBevelPatternColorType ("Nub Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _NubBevelPatternColorMode ("Nub Bevel Pattern Color Mode", Int) = 1
        [IntRange] _NubBevelPatternColorUsed ("Nub Bevel Pattern Color Used", Range(2, 4)) = 2
        _NubBevelPatternColorA ("Nub Bevel Pattern Color A", Color) = (1,1,1,1)
        _NubBevelPatternColorB ("Nub Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _NubBevelPatternColorC ("Nub Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _NubBevelPatternColorD ("Nub Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Nub bevel gradient
        _NubBevelGradientEnabled ("Nub Bevel Gradient Enabled", Float) = 0
        [Enum(GradientType)] _NubBevelGradientType ("Nub Bevel Gradient Type", Int) = 1
        _NubBevelGradientColorA ("Nub Bevel Gradient Color A", Color) = (1, 1, 1, 1)
        _NubBevelGradientColorB ("Nub Bevel Gradient Color B", Color) = (0.5, 0.5, 0.5, 1)
        _NubBevelGradientColorC ("Nub Bevel Gradient Color C", Color) = (0.3, 0.3, 0.3, 1)
        _NubBevelGradientColorD ("Nub Bevel Gradient Color D", Color) = (0.1, 0.1, 0.1, 1)
        _NubBevelGradientDirection ("Nub Bevel Gradient Direction", Vector) = (1, 0, 0, 0)
        _NubBevelGradientSpeed ("Nub Bevel Gradient Speed", Float) = 1.0
        _NubBevelGradientScale ("Nub Bevel Gradient Scale", Range(0.1, 5)) = 1.0
        _NubBevelGradientOffset ("Nub Bevel Gradient Offset", Range(-2, 2)) = 0.0
        [IntRange] _NubBevelGradientColorUsed ("Nub Bevel Gradient Color Used", Range(2, 4)) = 4

        // Nub rim bevel
        _NubRimEnabled ("Nub Rim Bevel Enabled", Float) = 0
        _NubRimDepth ("Nub Rim Bevel Depth", Range(-0.5, 0.5)) = 0.1
        _NubRimWidth ("Nub Rim Bevel Width", Range(0.001, 0.1)) = 0.02
        _NubRimSmoothness ("Nub Rim Bevel Smoothness", Range(0.001, 0.1)) = 0.01
        _NubPatternEnabled ("Nub Pattern Enabled", Float) = 0
        [Enum(PatternType)] _NubPatternType ("Nub Pattern Type", Int) = 0
        _NubPatternScale ("Nub Pattern Scale", Range(0.1, 10)) = 1
        _NubPatternIntensity ("Nub Pattern Intensity", Range(0, 2)) = 1
        _NubPatternContrast ("Nub Pattern Contrast", Range(0, 2)) = 1
        _NubPatternSpecularEffect ("Nub Pattern Specular Effect", Range(0, 1)) = 0.5
        _NubPatternRoughnessEffect ("Nub Pattern Roughness Effect", Range(0, 1)) = 0.5
        _NubPatternRotateEnabled ("Nub Pattern Rotate Enabled", Range(0, 1)) = 1
        _NubPatternModEnabled ("Nub Pattern Mod Enabled", Float) = 0
        _NubPatternModAmount ("Nub Pattern Mod Amount", Range(0, 90)) = 20
        _NubPatternModFrequency ("Nub Pattern Mod Frequency", Range(0.1, 10)) = 1
        _NubPatternOffset ("Nub Pattern Offset", Range(-180, 180)) = 0
        _NubPatternParam1 ("Nub Pattern Detail", Range(0, 1)) = 0.5
        _NubPatternParam2 ("Nub Pattern Distortion", Range(0, 1)) = 0.5
        _NubPatternParam3 ("Nub Pattern Blend", Range(0, 1)) = 0.5

        // Nub pattern color
        _NubPatternColorEnabled ("Nub Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _NubPatternColorType ("Nub Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _NubPatternColorMode ("Nub Pattern Color Mode", Int) = 1
        [IntRange] _NubPatternColorUsed ("Nub Pattern Color Used", Range(2, 4)) = 2
        _NubPatternColorA ("Nub Pattern Color A", Color) = (1,1,1,1)
        _NubPatternColorB ("Nub Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _NubPatternColorC ("Nub Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _NubPatternColorD ("Nub Pattern Color D", Color) = (0.1,0.1,0.1,1)

        // Nub gradient properties
        _NubGradientEnabled ("Nub Gradient Enabled", Float) = 0
        [Enum(GradientType)] _NubGradientType ("Nub Gradient Type", Int) = 0
        _NubGradientColorA ("Nub Gradient Color A", Color) = (1, 0, 0, 1)
        _NubGradientColorB ("Nub Gradient Color B", Color) = (0, 1, 0, 1)
        _NubGradientColorC ("Nub Gradient Color C", Color) = (0, 0, 1, 1)
        _NubGradientColorD ("Nub Gradient Color D", Color) = (1, 1, 0, 1)
        _NubGradientDirection ("Nub Gradient Direction", Vector) = (1, 0, 0, 0)
        _NubGradientSpeed ("Nub Gradient Speed", Range(0, 5)) = 1
        _NubGradientScale ("Nub Gradient Scale", Range(0.1, 10)) = 1
        _NubGradientOffset ("Nub Gradient Offset", Range(0, 1)) = 0
        _NubGlobalBlend ("Nub Global Blend", Range(0, 1)) = 0.0
        _NubGlobalIntensity ("Nub Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _NubGradientColorUsed ("Nub Gradient Color Used", Range(2, 4)) = 4

        // Nub edge indent effect (inner edge shadow on nub)
        _NubEdgeEnabled ("Nub Edge Indent Enabled", Float) = 0
        _NubEdgeColor ("Nub Edge Indent Color", Color) = (0, 0, 0, 0.8)
        _NubEdgeRenderAlpha ("Nub Edge Render Alpha", Range(0, 1)) = 1
        _NubEdgeWidth ("Nub Edge Indent Width", Range(0.001, 0.2)) = 0.05
        _NubEdgeSoftness ("Nub Edge Indent Softness", Range(0, 2)) = 0.0
        _NubEdgeIntensity ("Nub Edge Indent Intensity", Range(0, 2)) = 1.0
        _NubEdgeRenderEmissive ("Nub Edge Render Emissive", Range(0, 1)) = 0

        // Nub edge gradient properties
        _NubEdgeGradientEnabled ("Nub Edge Gradient Enabled", Float) = 0
        [Enum(GradientType)] _NubEdgeGradientType ("Nub Edge Gradient Type", Int) = 0
        _NubEdgeGradientColorA ("Nub Edge Gradient Color A", Color) = (1, 0, 0, 1)
        _NubEdgeGradientColorB ("Nub Edge Gradient Color B", Color) = (0, 1, 0, 1)
        _NubEdgeGradientColorC ("Nub Edge Gradient Color C", Color) = (0, 0, 1, 1)
        _NubEdgeGradientColorD ("Nub Edge Gradient Color D", Color) = (1, 1, 0, 1)
        _NubEdgeGradientDirection ("Nub Edge Gradient Direction", Vector) = (1, 0, 0, 0)
        _NubEdgeGradientSpeed ("Nub Edge Gradient Speed", Float) = 1.0
        _NubEdgeGradientScale ("Nub Edge Gradient Scale", Range(0.1, 5)) = 1.0
        _NubEdgeGradientOffset ("Nub Edge Gradient Offset", Range(-2, 2)) = 0.0
        _NubEdgeGlobalBlend ("Nub Edge Global Blend", Range(0, 1)) = 0.0
        _NubEdgeGlobalIntensity ("Nub Edge Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _NubEdgeGradientColorUsed ("Nub Edge Gradient Color Used", Range(2, 4)) = 4

        // Edge indent effect (hole appearance)
        _EdgeEnabled ("Edge Indent Enabled", Float) = 1
        _EdgeColor ("Edge Indent Color", Color) = (0, 0, 0, 0.8)
        _EdgeRenderAlpha ("Edge Render Alpha", Range(0, 1)) = 1
        _EdgeWidth ("Edge Indent Width", Range(0.001, 0.2)) = 0.05
        // Moves the band's INNER boundary — positive starts the recess inside the widget's
        // own outline so its edge sits over the darkest part. Same knob the button has.
        _EdgeInset ("Edge Inset", Range(-0.1, 0.1)) = 0.0
        _EdgeSoftness ("Edge Indent Softness", Range(0, 2)) = 0.0
        _EdgeIntensity ("Edge Indent Intensity", Range(0, 2)) = 1.0
        _EdgeRenderEmissive ("Edge Render Emissive", Range(0, 1)) = 0

        // Edge gradient properties
        _EdgeGradientEnabled ("Edge Gradient Enabled", Float) = 0
        [Enum(GradientType)] _EdgeGradientType ("Edge Gradient Type", Int) = 0
        _EdgeGradientColorA ("Edge Gradient Color A", Color) = (1, 0, 0, 1)
        _EdgeGradientColorB ("Edge Gradient Color B", Color) = (0, 1, 0, 1)
        _EdgeGradientColorC ("Edge Gradient Color C", Color) = (0, 0, 1, 1)
        _EdgeGradientColorD ("Edge Gradient Color D", Color) = (1, 1, 0, 1)
        _EdgeGradientDirection ("Edge Gradient Direction", Vector) = (1, 0, 0, 0)
        _EdgeGradientSpeed ("Edge Gradient Speed", Float) = 1.0
        _EdgeGradientScale ("Edge Gradient Scale", Range(0.1, 5)) = 1.0
        _EdgeGradientOffset ("Edge Gradient Offset", Range(-2, 2)) = 0.0
        _EdgeGlobalBlend ("Edge Global Blend", Range(0, 1)) = 0.0
        _EdgeGlobalIntensity ("Edge Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _EdgeGradientColorUsed ("Edge Gradient Color Used", Range(2, 4)) = 4

        // Scale mark system (tick marks, dots, and arc segments)
        // Outer decorative rings (up to 3)
        _OuterRing1Enabled ("Outer Ring 1 Enabled", Float) = 0
        _OuterRing1Radius ("Outer Ring 1 Radius", Range(0.5, 2.0)) = 1.1
        _OuterRing1Thickness ("Outer Ring 1 Thickness", Range(0.001, 0.2)) = 0.02
        _OuterRing1Color ("Outer Ring 1 Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _OuterRing1AngleStart ("Outer Ring 1 Angle Start", Float) = 0
        _OuterRing1AngleRange ("Outer Ring 1 Angle Range", Float) = 360
        [Enum(OuterRingStyle)] _OuterRing1Style ("Outer Ring 1 Style", Int) = 0
        _OuterRing1RenderAlpha ("Outer Ring 1 Render Alpha", Range(0, 1)) = 1
        _OuterRing1RenderEmissive ("Outer Ring 1 Render Emissive", Range(0, 1)) = 0

        _OuterRing2Enabled ("Outer Ring 2 Enabled", Float) = 0
        _OuterRing2Radius ("Outer Ring 2 Radius", Range(0.5, 2.0)) = 1.15
        _OuterRing2Thickness ("Outer Ring 2 Thickness", Range(0.001, 0.2)) = 0.02
        _OuterRing2Color ("Outer Ring 2 Color", Color) = (0.4, 0.4, 0.4, 0.5)
        _OuterRing2AngleStart ("Outer Ring 2 Angle Start", Float) = 0
        _OuterRing2AngleRange ("Outer Ring 2 Angle Range", Float) = 360
        [Enum(OuterRingStyle)] _OuterRing2Style ("Outer Ring 2 Style", Int) = 0
        _OuterRing2RenderAlpha ("Outer Ring 2 Render Alpha", Range(0, 1)) = 1
        _OuterRing2RenderEmissive ("Outer Ring 2 Render Emissive", Range(0, 1)) = 0

        _OuterRing3Enabled ("Outer Ring 3 Enabled", Float) = 0
        _OuterRing3Radius ("Outer Ring 3 Radius", Range(0.5, 2.0)) = 1.2
        _OuterRing3Thickness ("Outer Ring 3 Thickness", Range(0.001, 0.2)) = 0.02
        _OuterRing3Color ("Outer Ring 3 Color", Color) = (0.3, 0.3, 0.3, 0.5)
        _OuterRing3AngleStart ("Outer Ring 3 Angle Start", Float) = 0
        _OuterRing3AngleRange ("Outer Ring 3 Angle Range", Float) = 360
        [Enum(OuterRingStyle)] _OuterRing3Style ("Outer Ring 3 Style", Int) = 0
        _OuterRing3RenderAlpha ("Outer Ring 3 Render Alpha", Range(0, 1)) = 1
        _OuterRing3RenderEmissive ("Outer Ring 3 Render Emissive", Range(0, 1)) = 0

        // Scale marks and major ticks (rendered together)
        _OuterMarksEnabled ("Scale Marks Enabled", Float) = 0
        [Enum(OuterMarksType)] _OuterMarksType ("Scale Mark Type", Int) = 0
        _OuterMarksCount ("Scale Mark Count", Range(2, 120)) = 11
        _OuterMarksAngleStart ("Scale Mark Start Angle", Float) = 0  // Relative to knob start angle or absolute
        _OuterMarksAngleRange ("Scale Mark Angle Range", Float) = 270  // Total range covered by marks

        // Scale mark appearance
        _OuterMarksColorFilled ("Scale Mark Filled Color", Color) = (0.2, 0.8, 0.2, 1)  // Color when value >= mark position
        _OuterMarksColorUnfilled ("Scale Mark Unfilled Color", Color) = (0.8, 0.8, 0.8, 1)  // Color when value < mark position
        _OuterMarksRadius ("Scale Mark Radius", Range(0.1, 1.5)) = 0.9  // Distance from center (relative to line outer radius)
        _OuterMarksLength ("Scale Mark Length", Range(0.01, 0.5)) = 0.05
        _OuterMarksThickness ("Scale Mark Thickness", Range(0.001, 0.05)) = 0.005
        _OuterMarksRounding ("Scale Mark Rounding", Range(0, 1)) = 1  // 0=sharp, 1=rounded ends
        _OuterMarksRenderAlpha ("Scale Marks Render Alpha", Range(0, 1)) = 1
        _OuterMarksRenderEmissive ("Scale Marks Render Emissive", Range(0, 1)) = 0

        // Major/minor tick system
        _OuterMarksMajorEnabled ("Major Tick Enabled", Float) = 1
        _OuterMarksMajorInterval ("Major Tick Interval", Range(1, 20)) = 5  // Every Nth mark is major
        _OuterMarksMajorLengthMultiplier ("Major Tick Length Multiplier", Range(1, 3)) = 1.5
        _OuterMarksMajorThicknessMultiplier ("Major Tick Thickness Multiplier", Range(1, 3)) = 1.5
        _OuterMarksMajorColorFilled ("Major Tick Filled Color", Color) = (0.3, 1, 0.3, 1)  // Color when value >= tick position
        _OuterMarksMajorColorUnfilled ("Major Tick Unfilled Color", Color) = (1, 1, 1, 1)  // Color when value < tick position

        // Arc segment mode (alternative to line ticks)
        _OuterMarksArcGapSize ("Scale Arc Gap Size", Range(0.001, 0.2)) = 0.02  // Gap between arc segments
        _OuterMarksArcThickness ("Scale Arc Thickness", Range(0.01, 0.3)) = 0.08

        // Glow/aura effects
        _LineSublineGlowEnabled ("Line Subline Filled Glow Enabled", Float) = 0
        _LineSublineGlowColor ("Line Subline Filled Glow Color", Color) = (0.3, 0.6, 1.0, 0.5)
        _LineSublineGlowWidth ("Line Subline Filled Glow Width", Range(0.001, 0.5)) = 0.02
        _LineSublineGlowSoftness ("Line Subline Filled Glow Softness", Range(0, 1.0)) = 0.05
        _LineSublineGlowIntensity ("Line Subline Filled Glow Intensity", Range(0, 2)) = 1.0
        _LineSublineGlowRenderAlpha ("Line Subline Glow Render Alpha", Range(0, 1)) = 1
        _LineSublineGlowRenderEmissive ("Line Subline Glow Render Emissive", Range(0, 1)) = 0

        // Cut-in border
        _BorderEnabled ("Border Enabled", Float) = 1
        _BorderColor ("Border Color", Color) = (0, 0, 0, 0.8)
        _BorderRenderAlpha ("Border Render Alpha", Range(0, 1)) = 1
        _BorderWidth ("Border Width", Range(0.001, 0.1)) = 0.02
        _BorderSoftness ("Border Softness", Range(0, 0.5)) = 0.05
        _BorderIntensity ("Border Intensity", Range(0, 2)) = 1.0
        _BorderRenderEmissive ("Border Render Emissive", Range(0, 1)) = 0

        // Border gradient properties
        _BorderGradientEnabled ("Border Gradient Enabled", Float) = 0
        [Enum(GradientType)] _BorderGradientType ("Border Gradient Type", Int) = 0
        _BorderGradientColorA ("Border Gradient Color A", Color) = (1, 0, 0, 1)
        _BorderGradientColorB ("Border Gradient Color B", Color) = (0, 1, 0, 1)
        _BorderGradientColorC ("Border Gradient Color C", Color) = (0, 0, 1, 1)
        _BorderGradientColorD ("Border Gradient Color D", Color) = (1, 1, 0, 1)
        _BorderGradientDirection ("Border Gradient Direction", Vector) = (1, 0, 0, 0)
        _BorderGradientSpeed ("Border Gradient Speed", Float) = 1.0
        _BorderGradientScale ("Border Gradient Scale", Range(0.1, 5)) = 1.0
        _BorderGradientOffset ("Border Gradient Offset", Range(-2, 2)) = 0.0
        _BorderGlobalBlend ("Border Global Blend", Range(0, 1)) = 0.0
        _BorderGlobalIntensity ("Border Global Intensity", Range(0, 2)) = 1.0
        [IntRange] _BorderGradientColorUsed ("Border Gradient Color Used", Range(2, 4)) = 4

        // Common lighting
        _LightingAmbient ("Ambient Intensity", Range(0, 1)) = 0.2
        [ToggleUI] _LightingUnlit ("Unlit (skip lighting)", Float) = 0

        // Text Layout System (for ShaderTextManager + ITextLayoutProvider)
        // These parameters don't render text in shader - they drive C# TMP positioning
        _TextEnabled ("Text Enabled", Float) = 0
        _TextCount ("Text Count", Range(0, 16)) = 12
        _TextRadius ("Text Radius", Float) = 180
        _TextAngleStart ("Text Angle Start", Float) = 0
        _TextAngleRange ("Text Angle Range", Float) = 330
        _TextSize ("Text Font Size", Float) = 16
        _TextColor ("Text Color", Color) = (1, 1, 1, 1)
        _TextAlignment ("Text Alignment", Range(0, 2)) = 1  // 0=Left, 1=Center, 2=Right

        // Text rotation options
        _TextRotateWithKnob ("Text Rotate With Knob", Float) = 0
        _TextFollowAngle ("Text Follow Angle", Float) = 0
        _TextForceUpright ("Text Force Upright", Float) = 1

        // Text content IDs (reference textTable dictionary in C#)
        _TextId0 ("Text ID 0", Float) = 0
        _TextId1 ("Text ID 1", Float) = 1
        _TextId2 ("Text ID 2", Float) = 2
        _TextId3 ("Text ID 3", Float) = 3
        _TextId4 ("Text ID 4", Float) = 4
        _TextId5 ("Text ID 5", Float) = 5
        _TextId6 ("Text ID 6", Float) = 6
        _TextId7 ("Text ID 7", Float) = 7
        _TextId8 ("Text ID 8", Float) = 8
        _TextId9 ("Text ID 9", Float) = 9
        _TextId10 ("Text ID 10", Float) = 10
        _TextId11 ("Text ID 11", Float) = 11
        _TextId12 ("Text ID 12", Float) = 12
        _TextId13 ("Text ID 13", Float) = 13
        _TextId14 ("Text ID 14", Float) = 14
        _TextId15 ("Text ID 15", Float) = 15

        // Shadow pass: 0 = widget quad (renders everything EXCEPT shadows — they'd clip at
        // this quad's edge); 1 = shadow quad (renders ONLY the shadows, on a backing quad
        // _ShadowUvExpand× the widget's size — see MaterialStateUiControls/WidgetShadowQuad.cs).
        // Same shader both ways, so the shadow math/appearance is IDENTICAL to the original.
        _ShadowPassMode ("Shadow Pass Mode (0=widget, 1=shadow quad)", Float) = 0
        _ShadowUvExpand ("Shadow Quad UV Expand", Float) = 1

        // Unity UI
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
        Blend One OneMinusSrcAlpha // Premultiplied alpha - enables both normal blending and additive emissive in a single pass

        Pass
        {
            Name "Main"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2  // skip Unity fog variants (UI doesn't need them)
            #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON  // skip lighting variants (UI doesn't need them)


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

            #include "CG/SDF/SDFKnobUniforms.cginc"

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

            #include "CG/SDF/SDFKnobLayers.cginc"

            // 2D cast knob shadow: hull sweep between base shape and face shape
            // Projects the knob silhouette along the light direction using bevel depth as height.
            // When castMul is 0 or pseudoHeight is 0, falls back to basic knob shadow.
            float calculate2DCastKnobShadow(
                float2 uv, float2 pos, float3 lightDir,
                float blur, float dist, float blurFac, float castMul,
                float knobAngle, float knobRadius, float faceInset, float pseudoHeight)
            {
                float2 ld2 = normalize(lightDir.xy);
                float2 sPos = (uv - float2(0.5, 0.5) - ld2 * dist) * 2.0;

                // Base shape SDF at shadow position
                float2 sRot = rotate2D(sPos, knobAngle);
                float sD = getKnobSDF(
                    rotate2D(sRot, -_KnobShapeRotation * (PI / 180.0)),
                    knobRadius, _KnobShapeType, _KnobShapeScale,
                    _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3,
                    _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6);

                // Penumbra half-width AT THE CONTACT POINT — the skin's own softness, in
                // the same relative-to-occluder unit every other shadow in the project uses.
                float penHalf  = UI_SHADOW_CONTACT_BLUR(blur, knobRadius);
                float umbraMul = 1.0;

                // Cast: hull sweep from base to face tip projected along light
                if (castMul > 0.001 && pseudoHeight > 0.001) {
                    // Tip shadow falls further in the light's travel direction from the object.
                    // Since sPos is already offset by -ld2*dist, we push the query position
                    // back toward the object (-ld2) so the shadow extends further out.
                    float ps = pseudoHeight * castMul;
                    float2 topOff = -ld2 * ps;

                    // Face radius (smaller top of beveled shape)
                    float faceR = (_KnobFaceShapeEnabled > 0.5)
                        ? knobRadius * saturate(_KnobFaceShapeSize)
                        : max(0.001, knobRadius - faceInset);

                    // CONTACT HARDENING: t is where along the throw this pixel sits, 0 at
                    // the foot of the knob and 1 at the projected tip, so the penumbra opens
                    // up and the umbra dissolves with distance from the contact line rather
                    // than one flat softness being smeared across the whole shadow.
                    float castLen = length(topOff);
                    float segLen2 = dot(topOff, topOff);
                    float t = saturate(-dot(sPos, topOff) / max(0.0001, segLen2));
                    float2 fall = UIShadowPenumbra(castLen * t, knobRadius, blurFac);
                    penHalf    += fall.x;
                    umbraMul    = fall.y;

                    // The hull, swept. For two convex sets the convex hull is EXACTLY the
                    // union over s in [0,1] of their linear interpolation, so a uniform sweep
                    // with a running min IS the hull. One closest-point sample min'd against
                    // the tip's own footprint (what was here) is only correct when the swept
                    // shape does not change size; this tapers to faceR, and the two fields
                    // crossed over at different points around the shape and notched it.
                    // Dynamic loop: ONE getKnobSDF compiled, a handful of iterations run —
                    // against the three that used to be unrolled here.
                    int   hullN = UIShadowHullSamples(castLen, knobRadius);
                    float invN  = 1.0 / (float)max(hullN - 1, 1);
                    UNITY_LOOP for (int hs = 1; hs < hullN; hs++) {
                        float  sPar  = (float)hs * invN;
                        float2 sPosS = sPos + topOff * sPar;
                        float2 sRotS = rotate2D(sPosS, knobAngle);
                        float  hullR = lerp(knobRadius, faceR, sPar);
                        float  dS;
                        if (_KnobFaceShapeEnabled > 0.5 && sPar > 0.5) {
                            dS = getKnobSDF(
                                rotate2D(sRotS, -_KnobFaceShapeRotation * (PI / 180.0)),
                                hullR, _KnobFaceShapeType, _KnobFaceShapeScale,
                                _KnobFaceShapeParam1, _KnobFaceShapeParam2, _KnobFaceShapeParam3,
                                _KnobFaceShapeParam4, _KnobFaceShapeParam5, _KnobFaceShapeParam6,
                                _KnobFaceShapeTexLayer, _KnobFaceShapeTexScale);
                        } else {
                            dS = getKnobSDF(
                                rotate2D(sRotS, -_KnobShapeRotation * (PI / 180.0)),
                                hullR, _KnobShapeType, _KnobShapeScale,
                                _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3,
                                _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6);
                        }
                        sD = min(sD, dS);
                    }
                }

                return UIShadowEdgeAlpha(sD, penHalf, 0.0) * umbraMul;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                // Shadow quad: remap uv into the widget's own uv space (quad is
                // _ShadowUvExpand× the widget, centered) so all SDF math is unchanged and
                // shadows can extend past where the widget quad would end.
                if (_ShadowPassMode > 0.5) uv = (uv - 0.5) * _ShadowUvExpand + 0.5;
                float2 center = float2(0.5, 0.5);
                float2 pos = (uv - center) * 2.0; // Convert to [-1,1] range

                float distFromCenter = length(pos);

                // Calculate arc parameters - all in [-1,1] range for arc calculations
                float fillRadius = _LineRadius; // Fill meets the line exactly - no gap

                // Calculate extended line width to cover value areas
                float valueThickness = _LineWidth * _LineSublineThickness;
                float extendedLineWidth = max(_LineWidth, valueThickness + 0.02) + 0.04;
                float lineOuterRadius = _LineRadius + extendedLineWidth;
                float currentAngleRange = _AngleRange * _Value;

                // Create lights from properties (global override: direction from 2D UI positions)
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
                float3 emissiveAccum = float3(0, 0, 0); // Accumulated additive/emissive contribution (premultiplied alpha)
                float time = _Time.y;

                // Render edge indent effect first (behind everything)
                // (skipped on the shadow quad — it renders shadows only)
                if (_EdgeEnabled > 0.5 && _ShadowPassMode < 0.5) {
                    // Compute edge base color with gradient and global
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

                    float indentAlpha = calculateEdgeIndent(uv, _EdgeWidth, _EdgeSoftness, _EdgeInset, _EdgeFalloff);
                    if (indentAlpha > 0.001) {
                        float edgeMask = indentAlpha * _EdgeIntensity; // Geometric mask only
                        compositeOver(finalColor, edgeBaseColor, edgeMask * _EdgeRenderAlpha);
                        emissiveAccum += edgeBaseColor * edgeMask * _EdgeRenderEmissive;
                    }
                }

                // SHADOW QUAD ONLY: exact original shadow rendering (external + knob cast),
                // unchanged — it just runs on the expanded backing quad (_ShadowPassMode=1,
                // driven by WidgetShadowQuad) instead of the widget's own quad, so it can
                // extend without being clipped. The widget quad (_ShadowPassMode=0) skips this.
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
                        float shadowAlpha = calculateExternalShadow(uv, lightDir1, _LightingShadow1Blur, _LightingShadow1Distance, _LightingShadow1BlurFactor);
                        if (shadowAlpha > 0.001) {
                            compositeOver(castShadow, _LightingShadow1Color.rgb, _LightingShadow1Color.a * shadowAlpha * _LightingShadow1Intensity);
                        }
                    }
                    if (_LightingShadow2Enabled > 0.5) {
                        float shadowAlpha = calculateExternalShadow(uv, lightDir2, _LightingShadow2Blur, _LightingShadow2Distance, _LightingShadow2BlurFactor);
                        if (shadowAlpha > 0.001) {
                            compositeOver(castShadow, _LightingShadow2Color.rgb, _LightingShadow2Color.a * shadowAlpha * _LightingShadow2Intensity);
                        }
                    }
                    if (_LightingShadow3Enabled > 0.5) {
                        float shadowAlpha = calculateExternalShadow(uv, lightDir3, _LightingShadow3Blur, _LightingShadow3Distance, _LightingShadow3BlurFactor);
                        if (shadowAlpha > 0.001) {
                            compositeOver(castShadow, _LightingShadow3Color.rgb, _LightingShadow3Color.a * shadowAlpha * _LightingShadow3Intensity);
                        }
                    }

                    // Knob cast shadows (hull sweep between base and face). The geometry
                    // locals mirror the knob body section below — KEEP IN SYNC with it.
                    if (_KnobEnabled > 0.5) {
                        float knobRadius = _LineRadius * _KnobSize;
                        float bevelDist = (_KnobBevelEnabled > 0.5) ? _KnobBevelDistance : 0.0;
                        float bevelDepthRaw = (_KnobBevelEnabled > 0.5) ? abs(_KnobBevelDepth) : 0.0;
                        float pseudoHeight = knobRadius * lerp(0.05, 0.5, bevelDepthRaw);
                        float knobAngleForShadow = (_AngleStart + _AngleRange * _Value + _KnobRotation) * (PI / 180.0);
                        float rimWidth = (_KnobRimEnabled > 0.5) ? _KnobRimWidth : 0.0;
                        float faceInset = rimWidth + bevelDist;

                        if (_KnobShadow1Enabled > 0.5) {
                            float shadowAlpha = calculate2DCastKnobShadow(uv, pos, lightDir1,
                                _KnobShadow1Blur, _KnobShadow1Distance, _KnobShadow1BlurFactor, _KnobShadow1Cast,
                                knobAngleForShadow, knobRadius, faceInset, pseudoHeight);
                            if (shadowAlpha > 0.001) {
                                compositeOver(castShadow, _KnobShadow1Color.rgb, _KnobShadow1Color.a * shadowAlpha * _KnobShadow1Intensity);
                            }
                        }
                        if (_KnobShadow2Enabled > 0.5) {
                            float shadowAlpha = calculate2DCastKnobShadow(uv, pos, lightDir2,
                                _KnobShadow2Blur, _KnobShadow2Distance, _KnobShadow2BlurFactor, _KnobShadow2Cast,
                                knobAngleForShadow, knobRadius, faceInset, pseudoHeight);
                            if (shadowAlpha > 0.001) {
                                compositeOver(castShadow, _KnobShadow2Color.rgb, _KnobShadow2Color.a * shadowAlpha * _KnobShadow2Intensity);
                            }
                        }
                        if (_KnobShadow3Enabled > 0.5) {
                            float shadowAlpha = calculate2DCastKnobShadow(uv, pos, lightDir3,
                                _KnobShadow3Blur, _KnobShadow3Distance, _KnobShadow3BlurFactor, _KnobShadow3Cast,
                                knobAngleForShadow, knobRadius, faceInset, pseudoHeight);
                            if (shadowAlpha > 0.001) {
                                compositeOver(castShadow, _KnobShadow3Color.rgb, _KnobShadow3Color.a * shadowAlpha * _KnobShadow3Intensity);
                            }
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

                // Render outer decorative rings (after edge indent and shadows)
                finalColor = renderOuterRing(pos, finalColor, _OuterRing1Enabled, _OuterRing1Radius,
                                            _OuterRing1Thickness, _OuterRing1Color, _OuterRing1AngleStart,
                                            _OuterRing1AngleRange, _OuterRing1Style, _OuterRing1RenderAlpha, _OuterRing1RenderEmissive, emissiveAccum);
                finalColor = renderOuterRing(pos, finalColor, _OuterRing2Enabled, _OuterRing2Radius,
                                            _OuterRing2Thickness, _OuterRing2Color, _OuterRing2AngleStart,
                                            _OuterRing2AngleRange, _OuterRing2Style, _OuterRing2RenderAlpha, _OuterRing2RenderEmissive, emissiveAccum);
                finalColor = renderOuterRing(pos, finalColor, _OuterRing3Enabled, _OuterRing3Radius,
                                            _OuterRing3Thickness, _OuterRing3Color, _OuterRing3AngleStart,
                                            _OuterRing3AngleRange, _OuterRing3Style, _OuterRing3RenderAlpha, _OuterRing3RenderEmissive, emissiveAccum);

                // Render scale marks and major ticks (after outer rings, ON TOP, before main components)
                finalColor = renderScaleMarks(pos, finalColor, emissiveAccum);

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

                // TRUE unified knob rendering with SDF antialiasing and pattern/lighting system
                if (distFromCenter <= lineOuterRadius) {
                    // Calculate SDF distances for geometry
                    float fillDist = distFromCenter - _LineRadius;

                    // Use the proper ArcSDF for line distance calculation
                    float lineDist = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, _AngleStart, _AngleRange, _LineRoundedEnabled);

                    // Compute a clean, consistent AA width from the radial distance gradient.
                    // fwidth(distFromCenter) is smooth and branch-free everywhere, unlike
                    // fwidth(ArcSDF) which has internal branching that can produce incorrect
                    // screen-space derivatives when adjacent pixels in a 2x2 quad hit different
                    // code paths (angular clipping, rounded-end caps).
                    float fillAA = fwidth(fillDist) * 0.75; // == fwidth(distFromCenter) * 0.75

                    // Get antialiased masks
                    float fillMask = smoothstep(fillAA, -fillAA, fillDist);

                    // Line rendering needs to be segmented like value components to get proper rounded ends
                    float lineMask = 0.0;
                    if (_LineEnabled > 0.5) {
                        // Line segment where value filled would be - with rounded ends
                        if (currentAngleRange > 0.0) {
                            float filledSegmentDist = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, _AngleStart, currentAngleRange, _LineRoundedEnabled);
                            lineMask = max(lineMask, smoothstep(fillAA, -fillAA, filledSegmentDist));
                        }

                        // Line segment where value unfilled would be - with rounded ends
                        float unfilledStart = _AngleStart + currentAngleRange;
                        float unfilledRange = _AngleRange - currentAngleRange;
                        if (unfilledRange > 0.0) {
                            float unfilledSegmentDist = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, unfilledStart, unfilledRange, _LineRoundedEnabled);
                            lineMask = max(lineMask, smoothstep(fillAA, -fillAA, unfilledSegmentDist));
                        }
                    }

                    // Render fill area with full pattern and lighting support
                    if (_FillEnabled > 0.5 && fillMask > 0.001) {
                        // Create fill component
                    UIComponent fillComponent = CreateUIComponent(
                        _FillColor, _FillRenderAlpha,
                        _FillBevelDepth, _FillBevelSmoothness, _FillBevelDistance, _FillFaceSmoothness,
                        _FillGradientColorA, _FillGradientColorB, _FillGradientColorC, _FillGradientColorD,
                        _FillGradientDirection, _FillGradientSpeed, _FillGradientScale, _FillGradientOffset,
                        _FillGlobalBlend, _FillGlobalIntensity, _FillGradientType,
                        _FillPatternType, _FillPatternScale, _FillPatternIntensity, _FillPatternContrast,
                        _FillPatternSpecularEffect, _FillPatternRoughnessEffect, _FillPatternRotateEnabled,
                        _FillPatternModEnabled, _FillPatternModAmount, _FillPatternModFrequency, _FillPatternOffset,
                        _FillPatternParam1, _FillPatternParam2, _FillPatternParam3,
                        _FillGradientEnabled, _FillPatternEnabled,
                        _FillPatternColorEnabled, _FillPatternColorMode,
                        _FillPatternColorType, _FillPatternColorUsed,
                        _FillPatternColorA, _FillPatternColorB, _FillPatternColorC, _FillPatternColorD
                    );                        // Start with base color
                        float3 baseColor = fillComponent.color.rgb;

                        // Apply gradient if enabled
                        if (fillComponent.gradientEnabled > 0.5) {
                            float4 gradientColor = CalculateGradient(uv, fillComponent.gradientColorA, fillComponent.gradientColorB,
                                                                   fillComponent.gradientColorC, fillComponent.gradientColorD,
                                                                   fillComponent.gradientDirection, fillComponent.gradientType,
                                                                   fillComponent.gradientSpeed, fillComponent.gradientScale,
                                                                   fillComponent.gradientOffset, time, _FillGradientColorUsed);
                            baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                        }

                        // Apply global effects if enabled
                        if (fillComponent.globalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            baseColor = lerp(baseColor, globalColor.rgb, fillComponent.globalBlend * fillComponent.globalIntensity);
                        }

                        // Apply material pattern and get lighting modifiers (fill should NOT rotate)
                        float specularMod;
                        float2 normalOffset;
                        float3 mainPatternedColor = ApplyMaterialPattern(baseColor, uv, fillComponent, 0.0, 0.0,
                                                                       specularMod, normalOffset);

                        // Calculate fill bevel normal - use UILighting.cginc function with proper radius
                        // Check if bevel is enabled, if not use flat bevel depth
                        float effectiveFillBevelDepth = (_FillBevelEnabled > 0.5) ? fillComponent.bevelDepth : 0.0;
                        float3 normal = CalculateCircleBevelNormal(uv, _LineRadius, effectiveFillBevelDepth,
                                                                 fillComponent.bevelDistance, fillComponent.bevelSmoothness, fillComponent.fillFaceSmoothness);

                        // Apply enhanced bevel rendering with pattern and gradient support
                        // Pass both clean base color and main patterned color so bevel can properly blend between them
                        // Compute fill world-space SDF (circle) so bevel pattern zone matches the fill edge exactly
                        float2 fillSamplePos = (uv - 0.5) * 2.0;
                        float fillShapeDist = length(fillSamplePos) - _LineRadius;
                        BevelRenderResult bevelResult = RenderBevelWithPatternAndGradient(
                            uv, baseColor, mainPatternedColor, normal, _LineRadius,
                            fillShapeDist,
                            effectiveFillBevelDepth, fillComponent.bevelDistance, fillComponent.bevelSmoothness,
                            _FillBevelPatternEnabled, _FillBevelPatternType, _FillBevelPatternScale, _FillBevelPatternIntensity,
                            _FillBevelPatternContrast, _FillBevelPatternSpecularEffect, _FillBevelPatternRoughnessEffect,
                            _FillBevelGradientEnabled, _FillBevelGradientType, _FillBevelGradientColorA, _FillBevelGradientColorB,
                            _FillBevelGradientColorC, _FillBevelGradientColorD, _FillBevelGradientDirection,
                            _FillBevelGradientSpeed, _FillBevelGradientScale, _FillBevelGradientOffset,
                            _FillBevelPatternParam1, _FillBevelPatternParam2, _FillBevelPatternParam3,
                            _FillBevelGradientColorUsed,
                            _FillBevelPatternColorEnabled, _FillBevelPatternColorMode,
                            _FillBevelPatternColorType, _FillBevelPatternColorUsed,
                            _FillBevelPatternColorA, _FillBevelPatternColorB,
                            _FillBevelPatternColorC, _FillBevelPatternColorD,
                            0.0, 0.0, time, light1, light2, light3
                        );

                        // Calculate fill SDF for rim bevel (Fill is circular)
                        float2 center = float2(0.5, 0.5);
                        float2 toCenter = center - uv;
                        float distFromCenter = length(toCenter);
                        float radiusInUVSpace = _LineRadius * 0.5;
                        float fillDist = distFromCenter - radiusInUVSpace;

                        // Apply rim bevel if enabled (use SDF-based rim bevel for proper shape following)
                        RimResult rimBevelResult = CalculateRimFromSDF(
                            uv, bevelResult.litColor, bevelResult.normal, fillDist,
                            _FillRimEnabled, _FillRimDepth, _FillRimWidth, _FillRimSmoothness,
                            light1, light2, light3
                        );

                        // Apply lighting to the final result (with rim bevel applied)
                        float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                        light1, light2, light3);

                        compositeOver(finalColor, litColor, fillMask * fillComponent.alpha);
                        emissiveAccum += baseColor * fillMask * _FillRenderEmissive;
                    }

                    // Render line area BEFORE value components so value components show on top
                    if (_LineEnabled > 0.5 && lineMask > 0.001) {
                        // Temporarily disable value component cutout to test basic functionality
                        float adjustedLineMask = lineMask; // No cutout for now

                        if (adjustedLineMask > 0.001) {
                            // Create line component
                            UIComponent lineComponent = CreateUIComponent(
                                _LineColor, _LineRenderAlpha,
                            _LineBevelDepth, _LineBevelSmoothness, _LineBevelDistance, _LineFaceSmoothness,
                            _LineGradientColorA, _LineGradientColorB, _LineGradientColorC, _LineGradientColorD,
                            _LineGradientDirection, _LineGradientSpeed, _LineGradientScale, _LineGradientOffset,
                            _LineGlobalBlend, _LineGlobalIntensity, _LineGradientType,
                            _LinePatternType, _LinePatternScale, _LinePatternIntensity, _LinePatternContrast,
                            _LinePatternSpecularEffect, _LinePatternRoughnessEffect, _LinePatternRotateEnabled,
                            _LinePatternModEnabled, _LinePatternModAmount, _LinePatternModFrequency, _LinePatternOffset,
                            _LinePatternParam1, _LinePatternParam2, _LinePatternParam3,
                            _LineGradientEnabled, _LinePatternEnabled,
                            _LinePatternColorEnabled, _LinePatternColorMode,
                            _LinePatternColorType, _LinePatternColorUsed,
                            _LinePatternColorA, _LinePatternColorB, _LinePatternColorC, _LinePatternColorD
                        );                            // Start with base color
                            float3 baseColor = lineComponent.color.rgb;

                            // Apply gradient if enabled
                            if (lineComponent.gradientEnabled > 0.5) {
                                float4 gradientColor = CalculateGradient(uv, lineComponent.gradientColorA, lineComponent.gradientColorB,
                                                                       lineComponent.gradientColorC, lineComponent.gradientColorD,
                                                                       lineComponent.gradientDirection, lineComponent.gradientType,
                                                                       lineComponent.gradientSpeed, lineComponent.gradientScale,
                                                                       lineComponent.gradientOffset, time, _LineGradientColorUsed);
                                baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                            }

                            // Apply global effects if enabled
                            if (lineComponent.globalBlend > 0.0) {
                                float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                                baseColor = lerp(baseColor, globalColor.rgb, lineComponent.globalBlend * lineComponent.globalIntensity);
                            }

                            // Apply material pattern and get lighting modifiers
                            float specularMod;
                            float2 normalOffset;
                            float3 patternedColor = ApplyMaterialPattern(baseColor, uv, lineComponent, _Value, _AngleRange,
                                                                       specularMod, normalOffset);

                            // Calculate line bevel normal (arc geometry including rounded ends)
                            float effectiveLineBevelDepth = (_LineBevelEnabled > 0.5) ? lineComponent.bevelDepth : 0.0;
                            float3 normal = CalculateArcBevelNormal(uv, _LineRadius + _LineWidth * 0.5, _LineWidth, _AngleStart, _AngleRange,
                                                                  effectiveLineBevelDepth, lineComponent.bevelDistance, lineComponent.bevelSmoothness, lineComponent.fillFaceSmoothness);

                            // Apply rim bevel if enabled (use SDF-based rim bevel for proper arc shape following)
                            RimResult rimBevelResult = CalculateRimFromSDF(
                                uv, patternedColor, normal, lineDist,
                                _LineRimEnabled, _LineRimDepth, _LineRimWidth, _LineRimSmoothness,
                                light1, light2, light3
                            );

                            // Apply lighting to the final result (with rim bevel applied)
                            float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                            light1, light2, light3);

                            compositeOver(finalColor, litColor, adjustedLineMask * lineComponent.alpha);
                            emissiveAccum += baseColor * adjustedLineMask * _LineRenderEmissive;
                        }
                    }

                    // Value components with SDF antialiasing and pattern/lighting support (RENDER ON TOP OF LINE)
                    float lineCenterRadius = _LineRadius + _LineWidth * 0.5;
                    float valueInnerRadius = lineCenterRadius - valueThickness * 0.5;
                    float valueOuterRadius = lineCenterRadius + valueThickness * 0.5;

                    // Value components with ArcSDF for proper rounded ends
                    {
                        // Render Value Unfilled FIRST (background)
                        if (_LineEnabled > 0.5 && _LineSublineUnfilledEnabled > 0.5) {
                            float unfilledStart = _AngleStart + currentAngleRange;
                            float unfilledRange = _AngleRange - currentAngleRange;
                            if (unfilledRange > 0.001) {
                                float unfilledDist = ArcSDF(pos, lineCenterRadius, valueThickness, unfilledStart, unfilledRange, _LineRoundedEnabled);
                                float unfilledMask = smoothstep(fillAA, -fillAA, unfilledDist);

                                if (unfilledMask > 0.001) {
                                    // Create unfilled component
                                    UIComponent unfilledComponent = CreateUIComponent(
                                        _LineSublineUnfilledColor, _LineSublineUnfilledRenderAlpha,
                                        _LineSublineUnfilledBevelDepth, _LineSublineUnfilledBevelSmoothness, _LineSublineUnfilledBevelDistance, _LineSublineUnfilledFaceSmoothness,
                                        _LineSublineUnfilledGradientColorA, _LineSublineUnfilledGradientColorB, _LineSublineUnfilledGradientColorC, _LineSublineUnfilledGradientColorD,
                                        _LineSublineUnfilledGradientDirection, _LineSublineUnfilledGradientSpeed, _LineSublineUnfilledGradientScale, _LineSublineUnfilledGradientOffset,
                                        _LineSublineUnfilledGlobalBlend, _LineSublineUnfilledGlobalIntensity, _LineSublineUnfilledGradientType,
                                        _LineSublineUnfilledPatternType, _LineSublineUnfilledPatternScale, _LineSublineUnfilledPatternIntensity, _LineSublineUnfilledPatternContrast,
                                        _LineSublineUnfilledPatternSpecularEffect, _LineSublineUnfilledPatternRoughnessEffect, _LineSublineUnfilledPatternRotateEnabled,
                                        _LineSublineUnfilledPatternModEnabled, _LineSublineUnfilledPatternModAmount, _LineSublineUnfilledPatternModFrequency, _LineSublineUnfilledPatternOffset,
                                        _LineSublineUnfilledPatternParam1, _LineSublineUnfilledPatternParam2, _LineSublineUnfilledPatternParam3,
                                        _LineSublineUnfilledGradientEnabled, _LineSublineUnfilledPatternEnabled,
                                        _LineSublineUnfilledPatternColorEnabled, _LineSublineUnfilledPatternColorMode,
                                        _LineSublineUnfilledPatternColorType, _LineSublineUnfilledPatternColorUsed,
                                        _LineSublineUnfilledPatternColorA, _LineSublineUnfilledPatternColorB, _LineSublineUnfilledPatternColorC, _LineSublineUnfilledPatternColorD
                                    );
                                    // Start with base color
                                    float3 baseColor = unfilledComponent.color.rgb;

                                    // Apply gradient if enabled
                                    if (unfilledComponent.gradientEnabled > 0.5) {
                                        float4 gradientColor = CalculateGradient(uv, unfilledComponent.gradientColorA, unfilledComponent.gradientColorB,
                                                                               unfilledComponent.gradientColorC, unfilledComponent.gradientColorD,
                                                                               unfilledComponent.gradientDirection, unfilledComponent.gradientType,
                                                                               unfilledComponent.gradientSpeed, unfilledComponent.gradientScale,
                                                                               unfilledComponent.gradientOffset, time, _LineSublineUnfilledGradientColorUsed);
                                        baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                                    }

                                    // Apply global effects if enabled
                                    if (unfilledComponent.globalBlend > 0.0) {
                                        float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                                        baseColor = lerp(baseColor, globalColor.rgb, unfilledComponent.globalBlend * unfilledComponent.globalIntensity);
                                    }

                                    // Apply material pattern and get lighting modifiers
                                    float specularMod;
                                    float2 normalOffset;
                                    float3 patternedColor = ApplyMaterialPattern(baseColor, uv, unfilledComponent, _Value, _AngleRange,
                                                                               specularMod, normalOffset);

                                    // Calculate value bevel normal (ring geometry) - radii already in world space
                                    float effectiveUnfilledBevelDepth = (_LineSublineUnfilledBevelEnabled > 0.5) ? unfilledComponent.bevelDepth : 0.0;
                                    float3 normal = CalculateRingBevelNormal(uv, valueInnerRadius, valueOuterRadius, effectiveUnfilledBevelDepth,
                                                                           unfilledComponent.bevelDistance, unfilledComponent.bevelSmoothness, unfilledComponent.fillFaceSmoothness);

                                    // Apply rim bevel if enabled (use arc SDF distance for proper rounded-end shape)
                                    RimResult rimBevelResult = CalculateRimFromSDF(
                                        uv, patternedColor, normal, unfilledDist,
                                        _LineSublineUnfilledRimEnabled, _LineSublineUnfilledRimDepth, _LineSublineUnfilledRimWidth, _LineSublineUnfilledRimSmoothness,
                                        light1, light2, light3
                                    );

                                    // Apply lighting to the final result (with rim bevel applied)
                                    float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                                    light1, light2, light3);

                                    compositeOver(finalColor, litColor, unfilledComponent.alpha * unfilledMask);
                                    emissiveAccum += baseColor * unfilledMask * _LineSublineUnfilledRenderEmissive;
                                }
                            }
                        }

                        // Render Value Filled ON TOP (foreground)
                        if (_LineEnabled > 0.5 && _LineSublineFilledEnabled > 0.5) {
                            if (currentAngleRange > 0.001) {
                                float filledDist = ArcSDF(pos, lineCenterRadius, valueThickness, _AngleStart, currentAngleRange, _LineRoundedEnabled);
                                float filledMask = smoothstep(fillAA, -fillAA, filledDist);

                                if (filledMask > 0.001) {
                                    // Create filled component
                                    UIComponent filledComponent = CreateUIComponent(
                                        _LineSublineFilledColor, _LineSublineFilledRenderAlpha,
                                        _LineSublineFilledBevelDepth, _LineSublineFilledBevelSmoothness, _LineSublineFilledBevelDistance, _LineSublineFilledFaceSmoothness,
                                        _LineSublineFilledGradientColorA, _LineSublineFilledGradientColorB, _LineSublineFilledGradientColorC, _LineSublineFilledGradientColorD,
                                        _LineSublineFilledGradientDirection, _LineSublineFilledGradientSpeed, _LineSublineFilledGradientScale, _LineSublineFilledGradientOffset,
                                        _LineSublineFilledGlobalBlend, _LineSublineFilledGlobalIntensity, _LineSublineFilledGradientType,
                                        _LineSublineFilledPatternType, _LineSublineFilledPatternScale, _LineSublineFilledPatternIntensity, _LineSublineFilledPatternContrast,
                                        _LineSublineFilledPatternSpecularEffect, _LineSublineFilledPatternRoughnessEffect, _LineSublineFilledPatternRotateEnabled,
                                        _LineSublineFilledPatternModEnabled, _LineSublineFilledPatternModAmount, _LineSublineFilledPatternModFrequency, _LineSublineFilledPatternOffset,
                                        _LineSublineFilledPatternParam1, _LineSublineFilledPatternParam2, _LineSublineFilledPatternParam3,
                                        _LineSublineFilledGradientEnabled, _LineSublineFilledPatternEnabled,
                                        _LineSublineFilledPatternColorEnabled, _LineSublineFilledPatternColorMode,
                                        _LineSublineFilledPatternColorType, _LineSublineFilledPatternColorUsed,
                                        _LineSublineFilledPatternColorA, _LineSublineFilledPatternColorB, _LineSublineFilledPatternColorC, _LineSublineFilledPatternColorD
                                    );
                                    // Start with base color
                                    float3 baseColor = filledComponent.color.rgb;

                                    // Apply gradient if enabled
                                    if (filledComponent.gradientEnabled > 0.5) {
                                        float4 gradientColor = CalculateGradient(uv, filledComponent.gradientColorA, filledComponent.gradientColorB,
                                                                               filledComponent.gradientColorC, filledComponent.gradientColorD,
                                                                               filledComponent.gradientDirection, filledComponent.gradientType,
                                                                               filledComponent.gradientSpeed, filledComponent.gradientScale,
                                                                               filledComponent.gradientOffset, time, _LineSublineFilledGradientColorUsed);
                                        baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                                    }

                                    // Apply global effects if enabled
                                    if (filledComponent.globalBlend > 0.0) {
                                        float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                                        baseColor = lerp(baseColor, globalColor.rgb, filledComponent.globalBlend * filledComponent.globalIntensity);
                                    }

                                    // Apply material pattern and get lighting modifiers
                                    float specularMod;
                                    float2 normalOffset;
                                    float3 patternedColor = ApplyMaterialPattern(baseColor, uv, filledComponent, _Value, _AngleRange,
                                                                               specularMod, normalOffset);

                                    // Calculate value bevel normal (ring geometry) - radii already in world space
                                    float effectiveFilledBevelDepth = (_LineSublineFilledBevelEnabled > 0.5) ? filledComponent.bevelDepth : 0.0;
                                    float3 normal = CalculateRingBevelNormal(uv, valueInnerRadius, valueOuterRadius, effectiveFilledBevelDepth,
                                                                           filledComponent.bevelDistance, filledComponent.bevelSmoothness, filledComponent.fillFaceSmoothness);

                                    // Apply rim bevel if enabled (use arc SDF distance for proper rounded-end shape)
                                    RimResult rimBevelResult = CalculateRimFromSDF(
                                        uv, patternedColor, normal, filledDist,
                                        _LineSublineFilledRimEnabled, _LineSublineFilledRimDepth, _LineSublineFilledRimWidth, _LineSublineFilledRimSmoothness,
                                        light1, light2, light3
                                    );

                                    // Apply lighting to the final result (with rim bevel applied)
                                    float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                                    light1, light2, light3);

                                    compositeOver(finalColor, litColor, filledComponent.alpha * filledMask);
                                    emissiveAccum += baseColor * filledMask * _LineSublineFilledRenderEmissive;
                                }

                                // Render glow effect for value filled component (outer glow only)
                                // Uses the same ArcSDF distance to create a proper glow extending from the shape's outer edge
                                // This must be rendered OUTSIDE the filledMask check so it can render beyond the shape
                                if (_LineSublineGlowEnabled > 0.5) {
                                    finalColor = renderGlow(pos, finalColor, _LineSublineGlowEnabled, filledDist,
                                                          _LineSublineGlowColor, _LineSublineGlowWidth, _LineSublineGlowSoftness, _LineSublineGlowIntensity,
                                                          _LineSublineGlowRenderAlpha, _LineSublineGlowRenderEmissive, emissiveAccum);
                                }
                            }
                        }
                    }
                }

                // Render rotatable knob component (on top of everything)
                if (_KnobEnabled > 0.5) {
                    float knobRadius = _LineRadius * _KnobSize;

                    // Compute knob bevel "height" for cast shadows and edge
                    float bevelDist = (_KnobBevelEnabled > 0.5) ? _KnobBevelDistance : 0.0;
                    float bevelDepthRaw = (_KnobBevelEnabled > 0.5) ? abs(_KnobBevelDepth) : 0.0;
                    float pseudoHeight = knobRadius * lerp(0.05, 0.5, bevelDepthRaw);
                    float knobAngleForShadow = (_AngleStart + _AngleRange * _Value + _KnobRotation) * (PI / 180.0);
                    float rimWidth = (_KnobRimEnabled > 0.5) ? _KnobRimWidth : 0.0;
                    float faceInset = rimWidth + bevelDist;

                    // Knob shadows (_KnobShadow1/2/3) render in the shadow-pass block near the
                    // top of this function (on the expanded backing quad), not here — the
                    // geometry locals above are mirrored there; KEEP them IN SYNC.

                    // KnobEdge — indent around knob base shape, rendered under knob
                    if (_KnobEdgeEnabled > 0.5) {
                        // In 2D mode, evaluate the knob shape SDF directly (no tilt transform)
                        float2 knobEdgePos = rotate2D(pos, knobAngleForShadow);
                        float knobEdgeSDF = getKnobSDF(
                            rotate2D(knobEdgePos, -_KnobShapeRotation * (PI / 180.0)),
                            knobRadius, _KnobShapeType, _KnobShapeScale,
                            _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3,
                            _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6);
                        float distToKnob = max(0.0, knobEdgeSDF + _KnobEdgeInset);
                        if (distToKnob <= _KnobEdgeWidth) {
                            float3 knobEdgeBaseColor = _KnobEdgeColor.rgb;
                            if (_KnobEdgeGradientEnabled > 0.5) {
                                float4 gradientColor = CalculateGradient(uv, _KnobEdgeGradientColorA, _KnobEdgeGradientColorB,
                                                                        _KnobEdgeGradientColorC, _KnobEdgeGradientColorD,
                                                                        _KnobEdgeGradientDirection, _KnobEdgeGradientType,
                                                                        _KnobEdgeGradientSpeed, _KnobEdgeGradientScale,
                                                                        _KnobEdgeGradientOffset, time, _KnobEdgeGradientColorUsed);
                                knobEdgeBaseColor = lerp(knobEdgeBaseColor, gradientColor.rgb, gradientColor.a);
                            }
                            if (_KnobEdgeGlobalBlend > 0.0) {
                                float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                                knobEdgeBaseColor = lerp(knobEdgeBaseColor, globalColor.rgb, _KnobEdgeGlobalBlend * _KnobEdgeGlobalIntensity);
                            }
                            float baseGradient = 1.0 - (distToKnob / _KnobEdgeWidth);
                            float edgeAA = fwidth(distToKnob) * 0.75;
                            if (_KnobEdgeSoftness > 0.001) {
                                float softnessCurve = pow(_KnobEdgeSoftness / 2.0, 1.5);
                                float edgePower = lerp(0.8, 4.0, softnessCurve);
                                baseGradient = pow(max(0.0, baseGradient), edgePower);
                            } else {
                                baseGradient = 1.0 - smoothstep(_KnobEdgeWidth - edgeAA, _KnobEdgeWidth + edgeAA, distToKnob);
                            }
                            baseGradient = sin(baseGradient * PI * 0.5);
                            if (baseGradient > 0.001) {
                                float knobEdgeMask = baseGradient * _KnobEdgeIntensity;
                                compositeOver(finalColor, knobEdgeBaseColor, knobEdgeMask * _KnobEdgeRenderAlpha);
                                emissiveAccum += knobEdgeBaseColor * knobEdgeMask * _KnobEdgeRenderEmissive;
                            }
                        }
                    }

                    // Calculate knob rotation based on value + optional per-shape offset
                    float knobAngle = knobAngleForShadow;

                    // Rotate position for knob calculation
                    float2 rotatedPos = rotate2D(pos, knobAngle);

                    // --- ViewTilt: fake-isometric 3D frustum simulation ---
                    // Physical model (cross-section when tilted):
                    //   RIM ────┐                         ┌──── RIM
                    //           │  bevel zone              │
                    //           └───── FACE (smaller) ─────┘
                    //
                    // Outer shape → rim → bevel → face cap.
                    // bevelDist and rimWidth already computed above for cast shadows

                    // --- Evaluate face SDF relative to a center position ---
                    // Negate shape rotation to match RM's XZ coordinate convention (Y is negated in 3D space)
                    #define EVAL_FACE_SDF(centerPos) ( \
                        getKnobSDF( \
                            rotate2D(rotate2D((centerPos), knobAngle), -_KnobShapeRotation * (PI / 180.0)), \
                            knobRadius, _KnobShapeType, _KnobShapeScale, \
                            _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3, \
                            _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6))

                    // --- Inner face SDF: explicit face shape, or outer inset by rimWidth + bevelDist ---
                    #define EVAL_FACE_INNER_SDF(centerPos) ( \
                        (_KnobFaceShapeEnabled > 0.5) ? \
                        (getKnobSDF( \
                            rotate2D(rotate2D((centerPos), knobAngle), -_KnobFaceShapeRotation * (PI / 180.0)), \
                            knobRadius * max(0.01, _KnobFaceShapeSize), _KnobFaceShapeType, _KnobFaceShapeScale, \
                            _KnobFaceShapeParam1, _KnobFaceShapeParam2, _KnobFaceShapeParam3, \
                            _KnobFaceShapeParam4, _KnobFaceShapeParam5, _KnobFaceShapeParam6, \
                            _KnobFaceShapeTexLayer, _KnobFaceShapeTexScale) \
                            + bevelDist) \
                        : (EVAL_FACE_SDF(centerPos) + (rimWidth + bevelDist)))

                    // --- SDF evaluation ---
                    float faceOuterDist = EVAL_FACE_SDF(pos);
                    float topFaceDist = EVAL_FACE_INNER_SDF(pos);

                    // When face shape is enabled, the face may extend beyond the base shape.
                    // Use the union (min) so the face shape can override the base silhouette.
                    float knobDist;
                    if (_KnobFaceShapeEnabled > 0.5) {
                        float rawFaceDist = topFaceDist - bevelDist;
                        knobDist = min(faceOuterDist, rawFaceDist);
                    } else {
                        knobDist = faceOuterDist;
                    }

                    #undef EVAL_FACE_SDF
                    #undef EVAL_FACE_INNER_SDF

                    float knobAA   = fwidth(knobDist) * 0.75;
                    float knobMask = smoothstep(knobAA, -knobAA, knobDist);

                    float faceMask = knobMask;

                    if (knobMask > 0.001) {
                        UIComponent knobComponent = CreateUIComponent(
                            _KnobColor, _KnobRenderAlpha,
                            _KnobBevelDepth, _KnobBevelSmoothness, _KnobBevelDistance, _KnobFaceSmoothness,
                            _KnobGradientColorA, _KnobGradientColorB, _KnobGradientColorC, _KnobGradientColorD,
                            _KnobGradientDirection, _KnobGradientSpeed, _KnobGradientScale, _KnobGradientOffset,
                            _KnobGlobalBlend, _KnobGlobalIntensity, _KnobGradientType,
                            _KnobPatternType, _KnobPatternScale, _KnobPatternIntensity, _KnobPatternContrast,
                            _KnobPatternSpecularEffect, _KnobPatternRoughnessEffect, _KnobPatternRotateEnabled,
                            _KnobPatternModEnabled, _KnobPatternModAmount, _KnobPatternModFrequency, _KnobPatternOffset,
                            _KnobPatternParam1, _KnobPatternParam2, _KnobPatternParam3,
                            _KnobGradientEnabled, _KnobPatternEnabled,
                            _KnobPatternColorEnabled, _KnobPatternColorMode,
                            _KnobPatternColorType, _KnobPatternColorUsed,
                            _KnobPatternColorA, _KnobPatternColorB, _KnobPatternColorC, _KnobPatternColorD
                        );

                        // Face UV for pattern/gradient
                        float2 faceUV = pos + float2(0.5, 0.5);

                        float3 baseColor = knobComponent.color.rgb;
                        if (knobComponent.gradientEnabled > 0.5) {
                            float4 gradientColor = CalculateGradient(faceUV, knobComponent.gradientColorA, knobComponent.gradientColorB,
                                                                   knobComponent.gradientColorC, knobComponent.gradientColorD,
                                                                   knobComponent.gradientDirection, knobComponent.gradientType,
                                                                   knobComponent.gradientSpeed, knobComponent.gradientScale,
                                                                   knobComponent.gradientOffset, time, _KnobGradientColorUsed);
                            baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                        }
                        if (knobComponent.globalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            baseColor = lerp(baseColor, globalColor.rgb, knobComponent.globalBlend * knobComponent.globalIntensity);
                        }

                        // ======= Face =======
                        UNITY_BRANCH if (faceMask > 0.001) {
                            float specularMod;
                            float2 normalOffset;
                            float3 mainPatternedColor = ApplyMaterialPattern(baseColor, faceUV, knobComponent,
                                                                             _Value, _AngleRange, specularMod, normalOffset);

                            float effectiveBevelDepth = (_KnobBevelEnabled > 0.5) ? knobComponent.bevelDepth : 0.0;
                            float effectiveBevelDist  = knobComponent.bevelDistance;
                            float effectiveFaceSmoothness = knobComponent.fillFaceSmoothness;

                            // Map bevelDepth to match RM shader's 3D bevel angle.
                            // RM computes: bevelHeight = knobRadius * lerp(0.05, 1.0, |depth|)
                            //              angle = atan2(bevelHeight, bevelDist)
                            // The 2D CalculateShapeBevelNormal needs a totalDepth value that,
                            // after its normal construction (xy=totalDepth, z=1-totalDepth*0.5),
                            // produces the same bevel angle. Solving: totalDepth = tanB / (1 + tanB*0.5)
                            if (abs(effectiveBevelDepth) > 0.0001) {
                                float depthSign = sign(effectiveBevelDepth);
                                float bevelHeightRM = knobRadius * lerp(0.05, 1.0, abs(effectiveBevelDepth));
                                float bevelDistRM = max(0.0001, effectiveBevelDist);
                                float tanB = bevelHeightRM / bevelDistRM;
                                effectiveBevelDepth = depthSign * tanB / (1.0 + tanB * 0.5);
                            }

                            // Bevel SDF: drives the bevel normal direction and strength.
                            float bevelSDF = topFaceDist;
                            float inProtrusion = 0.0; // track protrusion zone for rim/edge suppression
                            if (_KnobFaceShapeEnabled > 0.5) {
                                // protrusionBlend: 0 inside base shape, 1 in protrusion.
                                float protrusionBlend = smoothstep(-effectiveBevelDist * 0.3, effectiveBevelDist * 0.3, faceOuterDist);
                                if (faceOuterDist >= 0.0) {
                                    // Protrusion zone: face extends past base shape.
                                    // Full bevel from the face shape edge — keeps the 3D rounded look.
                                    // Rim and edge are suppressed separately (they sit on the base, not the overhang).
                                    bevelSDF = topFaceDist;
                                    inProtrusion = protrusionBlend;
                                } else if (topFaceDist > 0.0) {
                                    // Wall zone: between base rim and face boundary.
                                    // The face sits above the base, so the face's bevel takes priority
                                    // whenever we're within its bevel reach. Only fall back to the base
                                    // rim boundary when the face boundary is too far away to contribute.
                                    float faceBevelReach = effectiveBevelDist + knobComponent.bevelSmoothness;
                                    if (topFaceDist > faceBevelReach) {
                                        // Beyond face bevel reach — use base rim boundary
                                        float rimBoundaryDist = faceOuterDist + rimWidth;
                                        bevelSDF = rimBoundaryDist;
                                    }
                                    // else: within face bevel reach — keep bevelSDF = topFaceDist
                                }
                            }

                            float3 faceNormal = CalculateShapeBevelNormal(bevelSDF, effectiveBevelDepth,
                                                   effectiveBevelDist, knobComponent.bevelSmoothness, effectiveFaceSmoothness,
                                                   _KnobBevelProfileType, _KnobBevelProfileSharpness);

                            // Extend bevel shading across the full wall when face shape is enabled.
                            // The bevel zone may not span the entire wall between face and outer edge.
                            // In the gap, add a gentle inward normal tilt so the lighting naturally
                            // darkens the shadow side all the way to the knob edge.
                            if (_KnobFaceShapeEnabled > 0.5 && topFaceDist > 0.0 && faceOuterDist < 0.0) {
                                float approxBevelFactor = smoothstep(effectiveBevelDist,
                                    max(0.0001, effectiveBevelDist - knobComponent.bevelSmoothness), abs(bevelSDF));
                                float gapFactor = 1.0 - approxBevelFactor;
                                if (gapFactor > 0.001) {
                                    // Inward direction from base shape gradient (same ddx/ddy space as bevel)
                                    float2 wallGrad = float2(ddx(faceOuterDist), ddy(faceOuterDist));
                                    float wallGradLen = length(wallGrad);
                                    if (wallGradLen > 0.0001) {
                                        float2 inwardDir = -wallGrad / wallGradLen;
                                        float wallTilt = gapFactor * abs(effectiveBevelDepth) * 0.35;
                                        faceNormal = normalize(faceNormal + float3(inwardDir * wallTilt, 0));
                                    }
                                }
                            }

                            BevelRenderResult bevelResult = RenderBevelWithPatternAndGradient(
                                faceUV, baseColor, mainPatternedColor, faceNormal, knobRadius,
                                bevelSDF,
                                effectiveBevelDepth, effectiveBevelDist, knobComponent.bevelSmoothness,
                                _KnobBevelPatternEnabled, _KnobBevelPatternType, _KnobBevelPatternScale,
                                _KnobBevelPatternIntensity, _KnobBevelPatternContrast,
                                _KnobBevelPatternSpecularEffect, _KnobBevelPatternRoughnessEffect,
                                _KnobBevelGradientEnabled, _KnobBevelGradientType,
                                _KnobBevelGradientColorA, _KnobBevelGradientColorB,
                                _KnobBevelGradientColorC, _KnobBevelGradientColorD, _KnobBevelGradientDirection,
                                _KnobBevelGradientSpeed, _KnobBevelGradientScale, _KnobBevelGradientOffset,
                                _KnobBevelPatternParam1, _KnobBevelPatternParam2, _KnobBevelPatternParam3,
                                _KnobBevelGradientColorUsed,
                                _KnobBevelPatternColorEnabled, _KnobBevelPatternColorMode,
                                _KnobBevelPatternColorType, _KnobBevelPatternColorUsed,
                                _KnobBevelPatternColorA, _KnobBevelPatternColorB,
                                _KnobBevelPatternColorC, _KnobBevelPatternColorD,
                                _Value, _AngleRange, time, light1, light2, light3
                            );

                            // Rim follows the base shape edge only — not the protruding face.
                            // The rim sits on the ground plane (base shape), so it should not
                            // wrap around the overhanging face shape.
                            // Push rimSDF deep negative when inside the face shape so the rim
                            // cannot appear on the face surface even where it crosses the base boundary.
                            float rimStrength = _KnobRimEnabled;
                            float rimSDF = knobDist;
                            if (_KnobFaceShapeEnabled > 0.5 && topFaceDist <= 0.0) {
                                // On the face surface — suppress rim entirely
                                rimSDF = -1.0;
                            }
                            RimResult rimBevelResult = CalculateRimFromSDF(
                                faceUV, bevelResult.litColor, bevelResult.normal, rimSDF,
                                rimStrength, _KnobRimDepth, _KnobRimWidth, _KnobRimSmoothness,
                                light1, light2, light3
                            );

                            float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor,
                                                              _LightingAmbient, specularMod, normalOffset,
                                                              light1, light2, light3);

                            // Self-shadow: bevel wall casts shadow onto the rim/wall zone.
                            // Port of SDFKnobRM's SURFACE_RIM self-shadow to 2D.
                            // The bevel wall rises from the rim shelf upward to the face.
                            // On the side where a light points outward from center, the wall
                            // can occlude the light if its elevation is below the wall angle.
                            // In 2D (no tilt): face plane = screen XY, light.z = elevation.
                            float wallZone = smoothstep(-knobAA, knobAA, topFaceDist);
                            if (wallZone > 0.001 && bevelDepthRaw > 0.01) {
                                // Radial direction from knob center (matching RM's p.xz/|p.xz|)
                                float rl = length(pos);
                                float2 outDir2D = (rl > 0.0001) ? (pos / rl) : float2(1, 0);

                                float bevelH = knobRadius * lerp(0.05, 1.0, bevelDepthRaw);
                                float wallTanAngle = bevelH / max(0.001, faceInset);

                                // Per-light occlusion (2D simplification of RM's 3D transform:
                                // with no tilt, lKnob.xz = -lightDir.xy, lKnob.y = lightDir.z)
                                #define RIM_SELF_SHADOW(lightEnabled, lightDir, factor) \
                                if (lightEnabled) { \
                                    float3 tl = UIToLightVector(lightDir); \
                                    float2 lxy = tl.xy; \
                                    float lHorizLen = length(lxy); \
                                    float2 lDir = (lHorizLen > 0.0001) ? (lxy / lHorizLen) : float2(0, 0); \
                                    float shadowSide = saturate(dot(outDir2D, lDir)); \
                                    float lightTan = tl.z / max(0.001, lHorizLen); \
                                    float occluded = saturate(1.0 - lightTan / max(0.001, wallTanAngle)); \
                                    factor = min(factor, 1.0 - shadowSide * occluded); \
                                }
                                float selfShadow = 1.0;
                                RIM_SELF_SHADOW(light1.enabled, light1.direction, selfShadow)
                                RIM_SELF_SHADOW(light2.enabled, light2.direction, selfShadow)
                                RIM_SELF_SHADOW(light3.enabled, light3.direction, selfShadow)
                                #undef RIM_SELF_SHADOW

                                litColor *= lerp(1.0, selfShadow, 0.85 * wallZone);
                            }

                            compositeOver(finalColor, litColor, faceMask * knobComponent.alpha);
                            emissiveAccum += baseColor * faceMask * _KnobRenderEmissive;
                        }
                    }
                }

                // Render rotatable nub component (on top of knob)
                if (_NubEnabled > 0.5) {
                    // Calculate nub position using the EXACT SAME coordinate system as the value components
                    // This matches the ArcSDF conversion logic used by value filled/unfilled
                    float uiAngle = _AngleStart + _AngleRange * _Value + _NubRotation;

                    // Normalize the angle to [0, 360) range
                    float normalizedAngle = fmod(uiAngle + 360.0, 360.0);

                    // Convert UI angle to atan2 coordinates using the SAME logic as ArcSDF
                    float atan2Angle;
                    if (normalizedAngle <= 180.0) {
                        atan2Angle = 180.0 - normalizedAngle;
                    } else {
                        atan2Angle = 540.0 - normalizedAngle;
                    }
                    if (atan2Angle >= 360.0) atan2Angle -= 360.0;

                    // Convert to radians and calculate position
                    float mathAngle = atan2Angle * (PI / 180.0);
                    float2 nubCenter = float2(cos(mathAngle), sin(mathAngle)) * _NubDistance;

                    // Position relative to nub center
                    float2 nubPos = pos - nubCenter;

                    // Rotate the nub to point radially outward from center
                    // This orients the nub correctly (e.g., triangle pointing outward)
                    float2 orientedNubPos = rotate2D(nubPos, -mathAngle);
                    if (_NubShapeRotation != 0.0)
                        orientedNubPos = rotate2D(orientedNubPos, _NubShapeRotation * (PI / 180.0));

                    // Calculate nub SDF using oriented position
                    float nubDist = getNubSDF(orientedNubPos, _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);
                    float nubAA = fwidth(nubDist) * 0.75;
                    float nubMask = smoothstep(nubAA, -nubAA, nubDist);

                    // Nub edge indent - renders BEFORE the nub, just outside its boundary (like _Edge for other components)
                    if (_NubEdgeEnabled > 0.5) {
                        float3 nubEdgeBaseColor = _NubEdgeColor.rgb;
                        if (_NubEdgeGradientEnabled > 0.5) {
                            float2 nubUV = (nubCenter * 0.5 + 0.5);
                            float4 nubEdgeGradColor = CalculateGradient(nubUV,
                                _NubEdgeGradientColorA, _NubEdgeGradientColorB,
                                _NubEdgeGradientColorC, _NubEdgeGradientColorD,
                                _NubEdgeGradientDirection, _NubEdgeGradientType,
                                _NubEdgeGradientSpeed, _NubEdgeGradientScale,
                                _NubEdgeGradientOffset, time, _NubEdgeGradientColorUsed);
                            nubEdgeBaseColor = lerp(nubEdgeBaseColor, nubEdgeGradColor.rgb, nubEdgeGradColor.a);
                        }
                        if (_NubEdgeGlobalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            nubEdgeBaseColor = lerp(nubEdgeBaseColor, globalColor.rgb, _NubEdgeGlobalBlend * _NubEdgeGlobalIntensity);
                        }
                        // distToNub: 0 at nub boundary, positive outside - exactly like distToGeometry in calculateEdgeIndent
                        float distToNub = max(0.0, nubDist);
                        if (distToNub <= _NubEdgeWidth) {
                            float baseGradient = 1.0 - (distToNub / _NubEdgeWidth);
                            float edgeAA = fwidth(distToNub) * 0.75;
                            if (_NubEdgeSoftness > 0.001) {
                                float softnessCurve = pow(_NubEdgeSoftness / 2.0, 1.5);
                                float edgePower = lerp(0.8, 4.0, softnessCurve);
                                baseGradient = pow(max(0.0, baseGradient), edgePower);
                            } else {
                                baseGradient = 1.0 - smoothstep(_NubEdgeWidth - edgeAA, _NubEdgeWidth + edgeAA, distToNub);
                            }
                            baseGradient = sin(baseGradient * PI * 0.5);
                            if (baseGradient > 0.001) {
                                compositeOver(finalColor, nubEdgeBaseColor, baseGradient * _NubEdgeIntensity * _NubEdgeRenderAlpha);
                                emissiveAccum += nubEdgeBaseColor * baseGradient * _NubEdgeIntensity * _NubEdgeRenderEmissive;
                            }
                        }
                    }

                    if (nubMask > 0.001) {
                        // Create nub component
                        UIComponent nubComponent = CreateUIComponent(
                            _NubColor, _NubRenderAlpha,
                            _NubBevelDepth, _NubBevelSmoothness, _NubBevelDistance, _NubFaceSmoothness,
                            _NubGradientColorA, _NubGradientColorB, _NubGradientColorC, _NubGradientColorD,
                            _NubGradientDirection, _NubGradientSpeed, _NubGradientScale, _NubGradientOffset,
                            _NubGlobalBlend, _NubGlobalIntensity, _NubGradientType,
                            _NubPatternType, _NubPatternScale, _NubPatternIntensity, _NubPatternContrast,
                            _NubPatternSpecularEffect, _NubPatternRoughnessEffect, _NubPatternRotateEnabled,
                            _NubPatternModEnabled, _NubPatternModAmount, _NubPatternModFrequency, _NubPatternOffset,
                            _NubPatternParam1, _NubPatternParam2, _NubPatternParam3,
                            _NubGradientEnabled, _NubPatternEnabled,
                            _NubPatternColorEnabled, _NubPatternColorMode,
                            _NubPatternColorType, _NubPatternColorUsed,
                            _NubPatternColorA, _NubPatternColorB, _NubPatternColorC, _NubPatternColorD
                        );

                        // Start with base color
                        float3 baseColor = nubComponent.color.rgb;                        // Apply gradient if enabled (use UV relative to nub center for gradients)
                        if (nubComponent.gradientEnabled > 0.5) {
                            float2 nubUV = (nubCenter * 0.5 + 0.5); // Convert nub center to UV space
                            float4 gradientColor = CalculateGradient(nubUV, nubComponent.gradientColorA, nubComponent.gradientColorB,
                                                                   nubComponent.gradientColorC, nubComponent.gradientColorD,
                                                                   nubComponent.gradientDirection, nubComponent.gradientType,
                                                                   nubComponent.gradientSpeed, nubComponent.gradientScale,
                                                                   nubComponent.gradientOffset, time, _NubGradientColorUsed);
                            baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                        }

                        // Apply global effects if enabled
                        if (nubComponent.globalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            baseColor = lerp(baseColor, globalColor.rgb, nubComponent.globalBlend * nubComponent.globalIntensity);
                        }

                        // Apply material pattern and get lighting modifiers (use original UV for patterns)
                        float specularMod;
                        float2 normalOffset;
                        float3 patternedColor = ApplyMaterialPattern(baseColor, uv, nubComponent, _Value, _AngleRange,
                                                                   specularMod, normalOffset);

                        // Rotate normalOffset back to world space so pattern specular doesn't rotate with nub
                        normalOffset = rotate2D(normalOffset, mathAngle);

                        // Calculate nub bevel normal (use local nub coordinates for proper bevel)
                        // For proper scaling, we need to use the same size calculation as getNubSDF
                        float nubSize;
                        if (_NubShapeType == 0) { // Circle
                            nubSize = min(_NubSizeWidth, _NubSizeHeight); // Use minimum for circles
                        } else { // Other shapes
                            nubSize = max(_NubSizeWidth, _NubSizeHeight); // Use maximum for rectangles/other shapes
                        }

                        // Calculate bevel normal using the actual SDF distance field
                        // This makes the bevel follow the shape (triangle, rectangle, etc) instead of always being circular
                        float bevelEpsilon = 0.001;
                        float centerDist = getNubSDF(orientedNubPos, _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);
                        float distX = getNubSDF(orientedNubPos + float2(bevelEpsilon, 0), _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);
                        float distY = getNubSDF(orientedNubPos + float2(0, bevelEpsilon), _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);

                        // Calculate gradient of the SDF
                        float2 sdfGradient = float2(distX - centerDist, distY - centerDist) / bevelEpsilon;

                        // Normalize the gradient to get the surface direction
                        sdfGradient = normalize(sdfGradient);

                        // Calculate bevel depth based on distance from edge
                        float edgeDistance = abs(centerDist);
                        float bevelFactor = smoothstep(nubComponent.bevelDistance, nubComponent.bevelDistance - nubComponent.bevelSmoothness, edgeDistance);

                        // Check if bevel is enabled
                        float effectiveNubBevelDepth = (_NubBevelEnabled > 0.5) ? nubComponent.bevelDepth : 0.0;

                        // Create normal that follows the shape (in local nub space)
                        float2 localNormal2D = float2(
                            sdfGradient.x * effectiveNubBevelDepth * (1.0 - bevelFactor),
                            sdfGradient.y * effectiveNubBevelDepth * (1.0 - bevelFactor)
                        );

                        // Rotate the 2D normal back to world space so lighting doesn't rotate with the nub
                        float2 worldNormal2D = rotate2D(localNormal2D, mathAngle);

                        // Create final 3D normal in world space
                        float3 normal = normalize(float3(worldNormal2D.x, worldNormal2D.y, 1.0));

                        // Apply rim bevel if enabled (use SDF-based rim bevel for proper shape following)
                        // The nub is counter-rotated to stay upright, so use the UN-rotated normal for lighting
                        RimResult rimBevelResult = CalculateRimFromSDF(
                            uv, patternedColor, normal, nubDist,
                            _NubRimEnabled, _NubRimDepth, _NubRimWidth, _NubRimSmoothness,
                            light1, light2, light3
                        );

                        // Apply final lighting pass (rim bevel already lit edges, this lights the face and adds pattern specular)
                        float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                            light1, light2, light3);

                        compositeOver(finalColor, litColor, nubMask * nubComponent.alpha);
                        emissiveAccum += baseColor * nubMask * _NubRenderEmissive;
                    }
                }

                // Render KnobNub — nub orbiting the knob face center
                if (_KnobEnabled > 0.5 && _KnobNubEnabled > 0.5) {
                    float knubRadius  = _LineRadius * _KnobSize;

                    // Convert value to atan2 angle (same convention as _NubEnabled)
                    // _KnobRotation offsets the orbit so KnobNub follows the knob body rotation
                    float uiAngleKN      = _AngleStart + _AngleRange * _Value + _KnobRotation;
                    float normAngleKN    = fmod(uiAngleKN + 360.0, 360.0);
                    float a2KN           = (normAngleKN <= 180.0) ? (180.0 - normAngleKN) : (540.0 - normAngleKN);
                    if (a2KN >= 360.0) a2KN -= 360.0;
                    float mathAngleKN    = a2KN * (PI / 180.0);

                    float2 knobNubCenter = float2(cos(mathAngleKN), sin(mathAngleKN)) * (_KnobNubDistance * knubRadius);

                    // Evaluate nub SDF (oriented to point radially outward)
                    float2 nubLocalPos = rotate2D(pos - knobNubCenter, -mathAngleKN);
                    if (_KnobNubShapeRotation != 0.0)
                        nubLocalPos = rotate2D(nubLocalPos, _KnobNubShapeRotation * (PI / 180.0));
                    float knobNubDist   = getKnobSDF(nubLocalPos, _KnobNubSize, _KnobNubShapeType, _KnobNubShapeScale,
                                                    _KnobNubShapeParam1, _KnobNubShapeParam2, _KnobNubShapeParam3,
                                                    0.5, 0.5, 0.5);
                    float knobNubAA   = fwidth(knobNubDist) * 0.75;
                    float knobNubMask = smoothstep(knobNubAA, -knobNubAA, knobNubDist);

                    if (knobNubMask > 0.001) {
                        float3 nubBaseColor = _KnobNubColor.rgb;
                        float  effBevelDepth = (_KnobNubBevelEnabled > 0.5) ? _KnobNubBevelDepth : 0.0;
                        float3 nubNormal = CalculateShapeBevelNormal(knobNubDist, effBevelDepth,
                                              _KnobNubBevelDistance, _KnobNubBevelSmoothness, _KnobNubFaceSmoothness, 0, 0.5);
                        float3 litColor = ApplyUILighting(nubNormal, nubBaseColor, _LightingAmbient, 1.0, float2(0, 0),
                                              light1, light2, light3);
                        compositeOver(finalColor, litColor, knobNubMask * _KnobNubRenderAlpha);
                    }
                }

                // Render cut-in border effect (on top of everything but behind UI)
                if (_BorderEnabled > 0.5) {
                    // Compute border base color with gradient and global
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
                    float4 borderResult = calculateBorder(uv, borderBaseColor, _BorderWidth, _BorderSoftness, borderTerritory, _BorderInset, _BorderFalloff);
                    float borderMask = borderResult.a * _BorderIntensity; // Apply intensity

                    // Scale territory clearing by how much the border actually contributes.
                    // If both alpha and emissive are 0, don't clear anything.
                    float borderPresence = max(_BorderRenderAlpha, _BorderRenderEmissive);
                    float effectiveTerritory = borderTerritory * borderPresence;
                    if (effectiveTerritory > 0.001) {
                        float clearFactor = 1.0 - effectiveTerritory;
                        finalColor.rgb *= clearFactor;
                        finalColor.a *= clearFactor;
                        emissiveAccum *= clearFactor;
                    }

                    if (borderMask > 0.001) {
                        compositeOver(finalColor, borderResult.rgb, borderMask * _BorderRenderAlpha);
                        emissiveAccum += borderResult.rgb * borderMask * _BorderRenderEmissive;
                    }
                }

                // Apply UI clipping (scale premultiplied RGB and alpha together)
                #ifdef UNITY_UI_CLIP_RECT
                float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                finalColor *= clipMask;
                emissiveAccum *= clipMask;
                #endif

                // Multiply by vertex color
                finalColor *= IN.color;
                emissiveAccum *= IN.color.rgb;

                // Premultiplied alpha output with purely additive emissive
                // compositeOver already produces premultiplied RGB, so don't multiply by alpha again.
                // Emissive is purely additive: it adds light without claiming alpha coverage.
                // With Blend One OneMinusSrcAlpha and alpha=0, emissive just adds on top of background.
                // Receive shadows cast by every OTHER widget and panel. This knob's own
                // contribution is not in the buffer at its own pixels — the shadow pass punched
                // its silhouette out — so this is other people's shadows only.
                // BEFORE the emissive add: an emissive Value arc is its own light source.
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
