// SDFKnobRM.shader
// Full standalone 3D-raymarch UI knob shader.
// All surrounding layers (fill, line, value arcs, nub, border, rings, marks,
// edge indent, shadows) are IDENTICAL to SDFKnob.shader — shared via .cginc.
// The ONLY difference: knob body uses 3D sphere-march extrusion with perspective
// FOV instead of 2D SDF flat rendering.
//
// Blend: premultiplied alpha (One OneMinusSrcAlpha) — matches SDFKnob.shader.

Shader "UI/SDFKnobRM"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

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

        // RM-specific: View tilt (3D perspective)
        _ViewTilt  ("View Tilt",  Range(0, 10)) = 0
        _ViewAngle ("View Angle", Range(-180, 180)) = 0
        _ViewFOV   ("View FOV",   Range(0, 1)) = 0
        _ViewShift ("View Shift", Range(-5, 5)) = 0

        // Scene camera (§4.16 B) — a BOUNDED add-on to the authored view above. The app
        // publishes one eye point for the screen (_GlobalViewCam); these are the most it
        // may move THIS material. 0 = ignore the camera entirely.
        _ViewCamEnabled ("View Cam Enabled", Float) = 1
        _ViewCamShift ("View Cam Max Shift +/-", Range(0, 5)) = 0.6
        _ViewCamTilt ("View Cam Max Tilt +/-", Range(0, 10)) = 0.8
        // Value-driven view shift/tilt: lerp(Min,Max,_Value) added to the static
        // value above when the matching Enabled flag is set. Mirrors SDFSliderRM
        // so a knob can lean/tilt as it turns (e.g. shift Min/Max = -0.2/0.2).
        _ViewValueShiftEnabled ("View Value Shift Enabled", Float) = 0
        _ViewValueShiftMin ("View Value Shift Min", Range(-5, 5)) = 0
        _ViewValueShiftMax ("View Value Shift Max", Range(-5, 5)) = 0
        _ViewValueTiltEnabled ("View Value Tilt Enabled", Float) = 0
        _ViewValueTiltMin ("View Value Tilt Min", Range(-10, 10)) = 0
        _ViewValueTiltMax ("View Value Tilt Max", Range(-10, 10)) = 0

        // Shadow pass: 0 = widget quad (renders everything EXCEPT shadows — they'd clip at
        // this quad's edge); 1 = shadow quad (renders ONLY the shadows, on a backing quad
        // _ShadowUvExpand× the widget's size — see MaterialStateUiControls/WidgetShadowQuad.cs).
        // Same shader both ways, so the shadow math/appearance is IDENTICAL to the original.
        _ShadowPassMode ("Shadow Pass Mode (0=widget, 1=shadow quad)", Float) = 0
        _ShadowUvExpand ("Shadow Quad UV Expand", Float) = 1

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

        _LineSublineFilledBevelPatternColorEnabled ("Line Subline Filled Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineFilledBevelPatternColorType ("Line Subline Filled Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineFilledBevelPatternColorMode ("Line Subline Filled Bevel Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineFilledBevelPatternColorUsed ("Line Subline Filled Bevel Pattern Color Used", Range(2, 4)) = 2
        _LineSublineFilledBevelPatternColorA ("Line Subline Filled Bevel Pattern Color A", Color) = (1,1,1,1)
        _LineSublineFilledBevelPatternColorB ("Line Subline Filled Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineFilledBevelPatternColorC ("Line Subline Filled Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineFilledBevelPatternColorD ("Line Subline Filled Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

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

        _LineSublineFilledPatternColorEnabled ("Line Subline Filled Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineFilledPatternColorType ("Line Subline Filled Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineFilledPatternColorMode ("Line Subline Filled Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineFilledPatternColorUsed ("Line Subline Filled Pattern Color Used", Range(2, 4)) = 2
        _LineSublineFilledPatternColorA ("Line Subline Filled Pattern Color A", Color) = (1,1,1,1)
        _LineSublineFilledPatternColorB ("Line Subline Filled Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineFilledPatternColorC ("Line Subline Filled Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineFilledPatternColorD ("Line Subline Filled Pattern Color D", Color) = (0.1,0.1,0.1,1)

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

        _LineSublineUnfilledBevelPatternColorEnabled ("Line Subline Unfilled Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineUnfilledBevelPatternColorType ("Line Subline Unfilled Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineUnfilledBevelPatternColorMode ("Line Subline Unfilled Bevel Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineUnfilledBevelPatternColorUsed ("Line Subline Unfilled Bevel Pattern Color Used", Range(2, 4)) = 2
        _LineSublineUnfilledBevelPatternColorA ("Line Subline Unfilled Bevel Pattern Color A", Color) = (1,1,1,1)
        _LineSublineUnfilledBevelPatternColorB ("Line Subline Unfilled Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineUnfilledBevelPatternColorC ("Line Subline Unfilled Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineUnfilledBevelPatternColorD ("Line Subline Unfilled Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

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

        _LineSublineUnfilledPatternColorEnabled ("Line Subline Unfilled Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _LineSublineUnfilledPatternColorType ("Line Subline Unfilled Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _LineSublineUnfilledPatternColorMode ("Line Subline Unfilled Pattern Color Mode", Int) = 1
        [IntRange] _LineSublineUnfilledPatternColorUsed ("Line Subline Unfilled Pattern Color Used", Range(2, 4)) = 2
        _LineSublineUnfilledPatternColorA ("Line Subline Unfilled Pattern Color A", Color) = (1,1,1,1)
        _LineSublineUnfilledPatternColorB ("Line Subline Unfilled Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _LineSublineUnfilledPatternColorC ("Line Subline Unfilled Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _LineSublineUnfilledPatternColorD ("Line Subline Unfilled Pattern Color D", Color) = (0.1,0.1,0.1,1)

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

        // Lighting



        // Global light overrides
        _Position ("UI Position", Vector) = (0, 0, 0, 0)

        // Knob component (rotates with value)
        _KnobEnabled ("Knob Enabled", Float) = 1
        _KnobColor ("Knob Color", Color) = (0.9, 0.9, 0.9, 1.0)
        _KnobRenderAlpha ("Knob Render Alpha", Range(0, 1)) = 1.0
        _KnobRenderEmissive ("Knob Render Emissive", Range(0, 1)) = 0
        _KnobSize ("Knob Size", Range(0.1, 1.0)) = 0.8
        [Enum(KnobShapeType)] _KnobShapeType ("Knob Shape Type", Int) = 0
        _KnobShapeScale ("Knob Shape Scale", Range(1, 20)) = 6
        _KnobShapeRotation ("Knob Shape Rotation", Range(-180, 180)) = 0
        _KnobShapeParam1 ("Knob Shape Param 1", Range(0, 1)) = 0.5
        _KnobShapeParam2 ("Knob Shape Param 2", Range(0, 1)) = 0.5
        _KnobShapeParam3 ("Knob Shape Param 3", Range(0, 1)) = 0.5
        _KnobShapeParam4 ("Knob Shape Param 4", Range(0, 1)) = 0.5
        _KnobShapeParam5 ("Knob Shape Param 5", Range(0, 1)) = 0.5
        _KnobShapeParam6 ("Knob Shape Param 6", Range(0, 1)) = 0.5
        _KnobRoundness ("Knob Shape Roundness", Range(0, 1)) = 0
        _KnobShapeTexLayer ("Knob Shape Tex Layer", Float) = -1
        _KnobShapeTexScale ("Knob Shape Tex Scale", Vector) = (1, 1, 0, 0)
        _KnobRotation ("Knob Rotation", Range(-180, 180)) = 0

        // Knob face shape
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

        // RM-specific: 3D lip extrusion
        _KnobLipHeight ("Lip Height", Range(0, 1)) = 0.08

        // Knob bevel
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

        // External shadow system (3 shadows driven by light positions)
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

        _LightingShadow1BlurFactor ("Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow2BlurFactor ("Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _LightingShadow3BlurFactor ("Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.5


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

        _KnobShadow1BlurFactor ("Knob Shadow 1 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _KnobShadow2BlurFactor ("Knob Shadow 2 Blur Factor (softens with distance)", Range(0, 1)) = 0.5
        _KnobShadow3BlurFactor ("Knob Shadow 3 Blur Factor (softens with distance)", Range(0, 1)) = 0.5

        _KnobShadow1Cast ("Knob Shadow 1 Cast", Range(0, 5)) = 1.0
        _KnobShadow2Cast ("Knob Shadow 2 Cast", Range(0, 5)) = 1.0
        _KnobShadow3Cast ("Knob Shadow 3 Cast", Range(0, 5)) = 1.0

        // Caps how far the cast throw can push the shadow, in units of this quad's own
        // half-size (1.0 = reaches exactly to the quad edge, 2.0 = twice that, matching
        // WidgetShadowQuad's default 2x backing-quad expansion). Without this, a grazing
        // light (lKy -> 0) sends `ps = totalHeight*cast/lKy` toward an unbounded throw —
        // the shadow doesn't keep growing, it degrades: the closest-point sweep parameter
        // collapses toward 0 for every on-screen pixel once the throw is much larger than
        // the knob's own radius, so the swept "connector" shrinks back down to look like
        // just the base footprint again even though the throw kept growing. See the same
        // fix on SDFButtonRM for the full writeup.
        _KnobShadow1MaxCast ("Knob Shadow 1 Max Cast Distance", Range(0.25, 10)) = 2.0
        _KnobShadow2MaxCast ("Knob Shadow 2 Max Cast Distance", Range(0.25, 10)) = 2.0
        _KnobShadow3MaxCast ("Knob Shadow 3 Max Cast Distance", Range(0.25, 10)) = 2.0

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

        // KnobNub
        _KnobNubEnabled ("Knob Nub Enabled", Float) = 0
        _KnobNubColor ("Knob Nub Color", Color) = (1, 1, 1, 1)
        _KnobNubRenderAlpha ("Knob Nub Render Alpha", Range(0, 1)) = 1.0
        _KnobNubSize ("Knob Nub Size", Range(0.005, 0.5)) = 0.08
        _KnobNubDistance ("Knob Nub Distance", Range(0, 2)) = 0.5
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

        _NubBevelPatternColorEnabled ("Nub Bevel Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _NubBevelPatternColorType ("Nub Bevel Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _NubBevelPatternColorMode ("Nub Bevel Pattern Color Mode", Int) = 1
        [IntRange] _NubBevelPatternColorUsed ("Nub Bevel Pattern Color Used", Range(2, 4)) = 2
        _NubBevelPatternColorA ("Nub Bevel Pattern Color A", Color) = (1,1,1,1)
        _NubBevelPatternColorB ("Nub Bevel Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _NubBevelPatternColorC ("Nub Bevel Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _NubBevelPatternColorD ("Nub Bevel Pattern Color D", Color) = (0.1,0.1,0.1,1)

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

        _NubPatternColorEnabled ("Nub Pattern Color Enabled", Float) = 0
        [Enum(PatternColorType)] _NubPatternColorType ("Nub Pattern Color Type", Int) = 2
        [Enum(PatternColorMode)] _NubPatternColorMode ("Nub Pattern Color Mode", Int) = 1
        [IntRange] _NubPatternColorUsed ("Nub Pattern Color Used", Range(2, 4)) = 2
        _NubPatternColorA ("Nub Pattern Color A", Color) = (1,1,1,1)
        _NubPatternColorB ("Nub Pattern Color B", Color) = (0.5,0.5,0.5,1)
        _NubPatternColorC ("Nub Pattern Color C", Color) = (0.3,0.3,0.3,1)
        _NubPatternColorD ("Nub Pattern Color D", Color) = (0.1,0.1,0.1,1)

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

        // Nub edge indent
        _NubEdgeEnabled ("Nub Edge Indent Enabled", Float) = 0
        _NubEdgeColor ("Nub Edge Indent Color", Color) = (0, 0, 0, 0.8)
        _NubEdgeRenderAlpha ("Nub Edge Render Alpha", Range(0, 1)) = 1
        _NubEdgeWidth ("Nub Edge Indent Width", Range(0.001, 0.2)) = 0.05
        _NubEdgeSoftness ("Nub Edge Indent Softness", Range(0, 2)) = 0.0
        _NubEdgeIntensity ("Nub Edge Indent Intensity", Range(0, 2)) = 1.0
        _NubEdgeRenderEmissive ("Nub Edge Render Emissive", Range(0, 1)) = 0

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

        // Edge indent effect
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

        // Outer decorative rings
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

        // Scale marks
        _OuterMarksEnabled ("Scale Marks Enabled", Float) = 0
        [Enum(OuterMarksType)] _OuterMarksType ("Scale Mark Type", Int) = 0
        _OuterMarksCount ("Scale Mark Count", Range(2, 120)) = 11
        _OuterMarksAngleStart ("Scale Mark Start Angle", Float) = 0
        _OuterMarksAngleRange ("Scale Mark Angle Range", Float) = 270
        _OuterMarksColorFilled ("Scale Mark Filled Color", Color) = (0.2, 0.8, 0.2, 1)
        _OuterMarksColorUnfilled ("Scale Mark Unfilled Color", Color) = (0.8, 0.8, 0.8, 1)
        _OuterMarksRadius ("Scale Mark Radius", Range(0.1, 1.5)) = 0.9
        _OuterMarksLength ("Scale Mark Length", Range(0.01, 0.5)) = 0.05
        _OuterMarksThickness ("Scale Mark Thickness", Range(0.001, 0.05)) = 0.005
        _OuterMarksRounding ("Scale Mark Rounding", Range(0, 1)) = 1
        _OuterMarksRenderAlpha ("Scale Marks Render Alpha", Range(0, 1)) = 1
        _OuterMarksRenderEmissive ("Scale Marks Render Emissive", Range(0, 1)) = 0

        _OuterMarksMajorEnabled ("Major Tick Enabled", Float) = 1
        _OuterMarksMajorInterval ("Major Tick Interval", Range(1, 20)) = 5
        _OuterMarksMajorLengthMultiplier ("Major Tick Length Multiplier", Range(1, 3)) = 1.5
        _OuterMarksMajorThicknessMultiplier ("Major Tick Thickness Multiplier", Range(1, 3)) = 1.5
        _OuterMarksMajorColorFilled ("Major Tick Filled Color", Color) = (0.3, 1, 0.3, 1)
        _OuterMarksMajorColorUnfilled ("Major Tick Unfilled Color", Color) = (1, 1, 1, 1)

        _OuterMarksArcGapSize ("Scale Arc Gap Size", Range(0.001, 0.2)) = 0.02
        _OuterMarksArcThickness ("Scale Arc Thickness", Range(0.01, 0.3)) = 0.08

        // Glow
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
        _TextEnabled ("Text Enabled", Float) = 0
        _TextCount ("Text Count", Range(0, 16)) = 12
        _TextRadius ("Text Radius", Float) = 180
        _TextAngleStart ("Text Angle Start", Float) = 0
        _TextAngleRange ("Text Angle Range", Float) = 330
        _TextSize ("Text Font Size", Float) = 16
        _TextColor ("Text Color", Color) = (1, 1, 1, 1)
        _TextAlignment ("Text Alignment", Range(0, 2)) = 1
        _TextRotateWithKnob ("Text Rotate With Knob", Float) = 0
        _TextFollowAngle ("Text Follow Angle", Float) = 0
        _TextForceUpright ("Text Force Upright", Float) = 1
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

        // Unity UI
        // Materials v2 (CG/Core/UIMaterials.cginc): matcap reflection + backdrop glass on the Knob body.
        _KnobMatcapEnabled ("Knob Matcap Enabled", Float) = 0
        _KnobMatcapLayer ("Knob Matcap Layer (UiMaterials/catalog.json)", Float) = 0
        _KnobMatcapStrength ("Knob Matcap Strength", Range(0, 1)) = 1
        _KnobMatcapMode ("Knob Matcap Mode (0 metal, 1 coat, 2 tint)", Float) = 0
        _KnobGlassEnabled ("Knob Glass Enabled", Float) = 0
        _KnobGlassStrength ("Knob Glass Strength", Range(0, 1)) = 0.85
        _KnobGlassRefract ("Knob Glass Refraction", Range(0, 0.2)) = 0.03
        _KnobGlassBlur ("Knob Glass Blur (mip)", Range(0, 8)) = 3
        _KnobGlassTint ("Knob Glass Tint", Color) = (1, 1, 1, 1)
        _KnobGlassRim ("Knob Glass Rim", Range(0, 2)) = 0.6
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
            Name "Raymarch"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON

            // === DEV COMPILE TOGGLES — comment out to skip compilation ===
            #define COMPILE_EDGE_SHADOWS_RINGS_MARKS
            #define COMPILE_FILL_LINE_VALUE
            #define COMPILE_BORDER
            #define COMPILE_KNOB
            #define COMPILE_KNOBNUB
            #define COMPILE_NUB

            // Per-material unlit switch — see UI_LIGHTING_UNLIT in CG/Core/UILighting.cginc.
            float _LightingUnlit;
            #define UI_LIGHTING_UNLIT _LightingUnlit
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #include "CG/SDF/SDFPrimitives.cginc"
            #include "CG/SDF/SDFOperations.cginc"
            #include "CG/Core/Constants.cginc"
            #include "CG/SDF/SDFKnobShapes.cginc"
            #include "CG/Core/UIMath.cginc"
            #include "CG/Core/UIComponents.cginc"
            #include "CG/Core/UIPatterns.cginc"
            #include "CG/Core/UILighting.cginc"
            #include "CG/Core/UIMaterials.cginc"
            UI_MATERIAL_V2_UNIFORMS(Knob)
            #include "CG/Core/UIViewCamera.cginc"
            #include "CG/Core/UIRenderer.cginc"
            #include "CG/Core/UIGradients.cginc"
            #include "CG/SDF/SDF3DExtrusion.cginc"
            #include "CG/SDF/SDFKnobUniforms.cginc"

            // RM-specific uniforms (not in shared SDFKnobUniforms.cginc)
            float _ViewTilt;
            float _ViewAngle;
            float _ViewFOV;
            float _ViewShift;
            float _ViewCamEnabled;
            float _ViewCamShift;
            float _ViewCamTilt;
            float _ViewValueShiftEnabled;
            float _ViewValueShiftMin;
            float _ViewValueShiftMax;
            float _ViewValueTiltEnabled;
            float _ViewValueTiltMin;
            float _ViewValueTiltMax;
            float _ReceiveSceneShadows;
            float _EdgeFalloff;
            float _BorderInset;
            float _BorderFalloff;
            float _ShadowPassMode;
            float _ShadowUvExpand;
            float _KnobLipHeight;
            float _KnobShadow1MaxCast;
            float _KnobShadow2MaxCast;
            float _KnobShadow3MaxCast;

            // ---- Vertex ----
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

#if defined(COMPILE_KNOB)
            // ---- RM Shape SDF wrapper (takes knobRadius as parameter) ----
            float evalKnobSDF(float2 p, float knobR) {
                float2 pRot = rotate2D(-p, -_KnobShapeRotation * (PI / 180.0));
                return getKnobSDF(pRot, knobR, _KnobShapeType, _KnobShapeScale,
                    _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3,
                    _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6);
            }

            // ---- RM Face (inner) SDF ----
            float computeFaceSDF(float2 p, float baseSDF, float faceInsetVal, float bevelDistVal, float knobR) {
                UNITY_BRANCH
                if (_KnobFaceShapeEnabled > 0.5) {
                    float faceR = knobR * saturate(_KnobFaceShapeSize);
                    float2 pRot = rotate2D(-p, -_KnobFaceShapeRotation * (PI / 180.0));
                    float faceShapeSDF = getKnobSDF(pRot, faceR, _KnobFaceShapeType, _KnobFaceShapeScale,
                        _KnobFaceShapeParam1, _KnobFaceShapeParam2, _KnobFaceShapeParam3,
                        _KnobFaceShapeParam4, _KnobFaceShapeParam5, _KnobFaceShapeParam6,
                        _KnobFaceShapeTexLayer, _KnobFaceShapeTexScale);
                    return faceShapeSDF + bevelDistVal;
                }
                return baseSDF + faceInsetVal;
            }

#endif // COMPILE_KNOB

#if defined(COMPILE_FILL_LINE_VALUE)
            // ---- Extracted: Fill / Line / Value rendering ----
            void renderFillLineValue(
                float2 uv, float2 pos, float2 worldPosXY,
                float distFromCenter, float lineOuterRadius,
                float currentAngleRange, float valueThickness,
                float time, UILight light1, UILight light2, UILight light3,
                inout float4 finalColor, inout float3 emissiveAccum)
            {
                if (distFromCenter <= lineOuterRadius) {
                    float fillDist = distFromCenter - _LineRadius;
                    float lineDist = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, _AngleStart, _AngleRange, _LineRoundedEnabled);
                    float fillAA = fwidth(fillDist) * 0.75;
                    float fillMask = smoothstep(fillAA, -fillAA, fillDist);

                    float lineMask = 0.0;
                    if (_LineEnabled > 0.5) {
                        if (currentAngleRange > 0.0) {
                            float filledSegmentDist = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, _AngleStart, currentAngleRange, _LineRoundedEnabled);
                            lineMask = max(lineMask, smoothstep(fillAA, -fillAA, filledSegmentDist));
                        }
                        float unfilledStart = _AngleStart + currentAngleRange;
                        float unfilledRange = _AngleRange - currentAngleRange;
                        if (unfilledRange > 0.0) {
                            float unfilledSegmentDist = ArcSDF(pos, _LineRadius + _LineWidth * 0.5, _LineWidth, unfilledStart, unfilledRange, _LineRoundedEnabled);
                            lineMask = max(lineMask, smoothstep(fillAA, -fillAA, unfilledSegmentDist));
                        }
                    }

                    // ---- Fill ----
                    if (_FillEnabled > 0.5 && fillMask > 0.001) {
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
                        );
                        float3 baseColor = fillComponent.color.rgb;
                        if (fillComponent.gradientEnabled > 0.5) {
                            float4 gradientColor = CalculateGradient(uv, fillComponent.gradientColorA, fillComponent.gradientColorB,
                                                                   fillComponent.gradientColorC, fillComponent.gradientColorD,
                                                                   fillComponent.gradientDirection, fillComponent.gradientType,
                                                                   fillComponent.gradientSpeed, fillComponent.gradientScale,
                                                                   fillComponent.gradientOffset, time, _FillGradientColorUsed);
                            baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                        }
                        if (fillComponent.globalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(worldPosXY, time);
                            baseColor = lerp(baseColor, globalColor.rgb, fillComponent.globalBlend * fillComponent.globalIntensity);
                        }
                        float specularMod;
                        float2 normalOffset;
                        float3 mainPatternedColor = ApplyMaterialPattern(baseColor, uv, fillComponent, 0.0, 0.0,
                                                                       specularMod, normalOffset);
                        float effectiveFillBevelDepth = (_FillBevelEnabled > 0.5) ? fillComponent.bevelDepth : 0.0;
                        float3 normal = CalculateCircleBevelNormal(uv, _LineRadius, effectiveFillBevelDepth,
                                                                 fillComponent.bevelDistance, fillComponent.bevelSmoothness, fillComponent.fillFaceSmoothness);
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
                        float2 center2 = float2(0.5, 0.5);
                        float2 toCenter = center2 - uv;
                        float distFromCenter2 = length(toCenter);
                        float radiusInUVSpace = _LineRadius * 0.5;
                        float fillDist2 = distFromCenter2 - radiusInUVSpace;
                        RimResult rimBevelResult = CalculateRimFromSDF(
                            uv, bevelResult.litColor, bevelResult.normal, fillDist2,
                            _FillRimEnabled, _FillRimDepth, _FillRimWidth, _FillRimSmoothness,
                            light1, light2, light3
                        );
                        float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                        light1, light2, light3);
                        compositeOver(finalColor, litColor, fillMask * fillComponent.alpha);
                        emissiveAccum += baseColor * fillMask * _FillRenderEmissive;
                    }

                    // ---- Line ----
                    if (_LineEnabled > 0.5 && lineMask > 0.001) {
                        float adjustedLineMask = lineMask;
                        if (adjustedLineMask > 0.001) {
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
                            );
                            float3 baseColor = lineComponent.color.rgb;
                            if (lineComponent.gradientEnabled > 0.5) {
                                float4 gradientColor = CalculateGradient(uv, lineComponent.gradientColorA, lineComponent.gradientColorB,
                                                                       lineComponent.gradientColorC, lineComponent.gradientColorD,
                                                                       lineComponent.gradientDirection, lineComponent.gradientType,
                                                                       lineComponent.gradientSpeed, lineComponent.gradientScale,
                                                                       lineComponent.gradientOffset, time, _LineGradientColorUsed);
                                baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                            }
                            if (lineComponent.globalBlend > 0.0) {
                                float4 globalColor = CalculateGlobalGradient(worldPosXY, time);
                                baseColor = lerp(baseColor, globalColor.rgb, lineComponent.globalBlend * lineComponent.globalIntensity);
                            }
                            float specularMod;
                            float2 normalOffset;
                            float3 patternedColor = ApplyMaterialPattern(baseColor, uv, lineComponent, _Value, _AngleRange,
                                                                       specularMod, normalOffset);
                            float effectiveLineBevelDepth = (_LineBevelEnabled > 0.5) ? lineComponent.bevelDepth : 0.0;
                            float3 normal = CalculateArcBevelNormal(uv, _LineRadius + _LineWidth * 0.5, _LineWidth, _AngleStart, _AngleRange,
                                                                  effectiveLineBevelDepth, lineComponent.bevelDistance, lineComponent.bevelSmoothness, lineComponent.fillFaceSmoothness);
                            RimResult rimBevelResult = CalculateRimFromSDF(
                                uv, patternedColor, normal, lineDist,
                                _LineRimEnabled, _LineRimDepth, _LineRimWidth, _LineRimSmoothness,
                                light1, light2, light3
                            );
                            float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                            light1, light2, light3);
                            compositeOver(finalColor, litColor, adjustedLineMask * lineComponent.alpha);
                            emissiveAccum += baseColor * adjustedLineMask * _LineRenderEmissive;
                        }
                    }

                    // ---- Value components ----
                    float lineCenterRadius = _LineRadius + _LineWidth * 0.5;
                    float valueInnerRadius = lineCenterRadius - valueThickness * 0.5;
                    float valueOuterRadius = lineCenterRadius + valueThickness * 0.5;
                    {
                        // Value Unfilled
                        if (_LineEnabled > 0.5 && _LineSublineUnfilledEnabled > 0.5) {
                            float unfilledStart = _AngleStart + currentAngleRange;
                            float unfilledRange = _AngleRange - currentAngleRange;
                            if (unfilledRange > 0.001) {
                                float unfilledDist = ArcSDF(pos, lineCenterRadius, valueThickness, unfilledStart, unfilledRange, _LineRoundedEnabled);
                                float unfilledMask = smoothstep(fillAA, -fillAA, unfilledDist);
                                if (unfilledMask > 0.001) {
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
                                    float3 baseColor = unfilledComponent.color.rgb;
                                    if (unfilledComponent.gradientEnabled > 0.5) {
                                        float4 gradientColor = CalculateGradient(uv, unfilledComponent.gradientColorA, unfilledComponent.gradientColorB,
                                                                               unfilledComponent.gradientColorC, unfilledComponent.gradientColorD,
                                                                               unfilledComponent.gradientDirection, unfilledComponent.gradientType,
                                                                               unfilledComponent.gradientSpeed, unfilledComponent.gradientScale,
                                                                               unfilledComponent.gradientOffset, time, _LineSublineUnfilledGradientColorUsed);
                                        baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                                    }
                                    if (unfilledComponent.globalBlend > 0.0) {
                                        float4 globalColor = CalculateGlobalGradient(worldPosXY, time);
                                        baseColor = lerp(baseColor, globalColor.rgb, unfilledComponent.globalBlend * unfilledComponent.globalIntensity);
                                    }
                                    float specularMod;
                                    float2 normalOffset;
                                    float3 patternedColor = ApplyMaterialPattern(baseColor, uv, unfilledComponent, _Value, _AngleRange,
                                                                               specularMod, normalOffset);
                                    float effectiveUnfilledBevelDepth = (_LineSublineUnfilledBevelEnabled > 0.5) ? unfilledComponent.bevelDepth : 0.0;
                                    float3 normal = CalculateRingBevelNormal(uv, valueInnerRadius, valueOuterRadius, effectiveUnfilledBevelDepth,
                                                                           unfilledComponent.bevelDistance, unfilledComponent.bevelSmoothness, unfilledComponent.fillFaceSmoothness);
                                    RimResult rimBevelResult = CalculateRimFromSDF(
                                        uv, patternedColor, normal, unfilledDist,
                                        _LineSublineUnfilledRimEnabled, _LineSublineUnfilledRimDepth, _LineSublineUnfilledRimWidth, _LineSublineUnfilledRimSmoothness,
                                        light1, light2, light3
                                    );
                                    float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                                    light1, light2, light3);
                                    compositeOver(finalColor, litColor, unfilledComponent.alpha * unfilledMask);
                                    emissiveAccum += baseColor * unfilledMask * _LineSublineUnfilledRenderEmissive;
                                }
                            }
                        }

                        // Value Filled
                        if (_LineEnabled > 0.5 && _LineSublineFilledEnabled > 0.5) {
                            if (currentAngleRange > 0.001) {
                                float filledDist = ArcSDF(pos, lineCenterRadius, valueThickness, _AngleStart, currentAngleRange, _LineRoundedEnabled);
                                float filledMask = smoothstep(fillAA, -fillAA, filledDist);
                                if (filledMask > 0.001) {
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
                                    float3 baseColor = filledComponent.color.rgb;
                                    if (filledComponent.gradientEnabled > 0.5) {
                                        float4 gradientColor = CalculateGradient(uv, filledComponent.gradientColorA, filledComponent.gradientColorB,
                                                                               filledComponent.gradientColorC, filledComponent.gradientColorD,
                                                                               filledComponent.gradientDirection, filledComponent.gradientType,
                                                                               filledComponent.gradientSpeed, filledComponent.gradientScale,
                                                                               filledComponent.gradientOffset, time, _LineSublineFilledGradientColorUsed);
                                        baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                                    }
                                    if (filledComponent.globalBlend > 0.0) {
                                        float4 globalColor = CalculateGlobalGradient(worldPosXY, time);
                                        baseColor = lerp(baseColor, globalColor.rgb, filledComponent.globalBlend * filledComponent.globalIntensity);
                                    }
                                    float specularMod;
                                    float2 normalOffset;
                                    float3 patternedColor = ApplyMaterialPattern(baseColor, uv, filledComponent, _Value, _AngleRange,
                                                                               specularMod, normalOffset);
                                    float effectiveFilledBevelDepth = (_LineSublineFilledBevelEnabled > 0.5) ? filledComponent.bevelDepth : 0.0;
                                    float3 normal = CalculateRingBevelNormal(uv, valueInnerRadius, valueOuterRadius, effectiveFilledBevelDepth,
                                                                           filledComponent.bevelDistance, filledComponent.bevelSmoothness, filledComponent.fillFaceSmoothness);
                                    RimResult rimBevelResult = CalculateRimFromSDF(
                                        uv, patternedColor, normal, filledDist,
                                        _LineSublineFilledRimEnabled, _LineSublineFilledRimDepth, _LineSublineFilledRimWidth, _LineSublineFilledRimSmoothness,
                                        light1, light2, light3
                                    );
                                    float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                                    light1, light2, light3);
                                    compositeOver(finalColor, litColor, filledComponent.alpha * filledMask);
                                    emissiveAccum += baseColor * filledMask * _LineSublineFilledRenderEmissive;
                                }
                                if (_LineSublineGlowEnabled > 0.5) {
                                    finalColor = renderGlow(pos, finalColor, _LineSublineGlowEnabled, filledDist,
                                                          _LineSublineGlowColor, _LineSublineGlowWidth, _LineSublineGlowSoftness, _LineSublineGlowIntensity,
                                                          _LineSublineGlowRenderAlpha, _LineSublineGlowRenderEmissive, emissiveAccum);
                                }
                            }
                        }
                    }
                }
            }

#endif // COMPILE_FILL_LINE_VALUE

#if defined(COMPILE_KNOB)
            // ================================================================
            // knobScreenToBase — a screen point, on the knob's BASE PLANE.
            //
            // The same projection renderRaymarchKnob's camera uses, so a cast shadow lands
            // where the body's foot actually is once _ViewShift / _ViewFOV move it. The sweep
            // used an orthographic stand-in before, which ignores both and drifts the shadow
            // off the knob that cast it. Result is PRE-rotation: callers rotate by knobAngle.
            // ================================================================
            float2 knobScreenToBase(float2 sPos, float2 tiltDir, float2 tiltNormDir,
                                    float cosT, float sinT, float knobRadius)
            {
                float sa = dot(sPos, tiltNormDir);
                float sl = dot(sPos, tiltDir);
                if (_ViewFOV > 0.001) {
                    float focD = knobRadius / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                    // FLOOR THE DIVIDE RELATIVE TO THE CAMERA DISTANCE, not at an absolute
                    // epsilon. W = focD*cosT - sl*sinT passes through zero at this projection's
                    // horizon, and on the 2x backing quad `sl` reaches far enough to get there
                    // for a wide _ViewFOV. An absolute floor lets the term explode just short of
                    // it — that singularity is what made an earlier pinhole shadow crease and
                    // blow up. A relative floor caps the perspective stretch at 4x instead,
                    // which no UI needs to exceed.
                    float base = focD * cosT;
                    float W    = max(base - sl * sinT, base * 0.25);
                    return float2((sa * base - UI_VIEW_SHIFT * sl * sinT) / W, -focD * sl / W);
                }
                return float2(sa, -sl / max(0.001, cosT));
            }

            // ---- Knob shadow SDF: computes shadow alpha for one light ----
            float computeRMKnobShadowAlpha(
                float2 uv, float3 lightDir,
                float blur, float dist, float blurFac, float castMul, float maxCast,
                float2 tiltDir, float2 tiltNormDir, float cosTpre, float sinTpre,
                float knobAngle, float knobRadius, float faceInset, float totalHeight,
                float aaUnit)
            {
                // _ViewTilt 10 is a full 90 degrees, where cos(tilt) is 0: every `/cosT`
                // blows up and `sDist = sD*cosT` collapses to 0 for every pixel, so the edge
                // test reads "just inside the shadow" across the whole backing quad. Past
                // ~81 degrees the face is edge-on and its shadow is meaningless anyway.
                float cosTsafe = max(0.15, cosTpre);
                float2 ld2   = normalize(lightDir.xy);
                float2 sPos  = (uv - float2(0.5, 0.5) - ld2 * dist) * 2.0;
                // Base footprint in knob XZ. Everything below works in BASE-PLANE coordinates
                // — the plane the shadow actually falls on, projected the way the body is
                // drawn. See knobScreenToBase.
                float2 base0 = knobScreenToBase(sPos, tiltDir, tiltNormDir, cosTsafe, sinTpre, knobRadius);
                float2 kxz   = rotate2D(base0, knobAngle);
                float  sD    = getKnobSDF(
                    rotate2D(-kxz, -_KnobShapeRotation * (PI / 180.0)),
                    knobRadius, _KnobShapeType, _KnobShapeScale,
                    _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3,
                    _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6);
                // Transform light into knob 3D tilt frame
                // Raymarched paths rotate the light into the widget's tilted 3D frame and use xy
                // and z TOGETHER, so they need a coherent vector — see UIToLightVector.
                float3 toLight = UIToLightVector(lightDir);
                float  la    = dot(toLight.xy, tiltNormDir);
                float  lb    = dot(toLight.xy, tiltDir);
                float  lZ    = toLight.z;
                // lKy is "how far above the TILTED FACE's plane the lamp sits", and it goes
                // NEGATIVE whenever the lamp drops below that plane — which is not exotic, it
                // is simply any knob sitting higher on screen than the lamp, or the lamp swung
                // far enough out on its orbit.
                //
                // Gating the whole hull sweep on it (`lKy > 0.001 && ...`) meant crossing zero
                // did not lengthen the shadow, it DELETED it: the cast collapsed to the base
                // footprint, which the knob's own body covers, so the shadow snapped away
                // entirely for a small light move. That is the jarring pop.
                //
                // Letting the sign through is worse still — ps flips, topOff flips, and the
                // shadow is thrown onto the SAME side as the lamp. A positive floor is the
                // right answer: below the face plane the top face stops being the silhouette
                // but the solid still blocks light, so the throw saturates long and the
                // penumbra falloff below fades it out naturally.
                float  lKyRaw = lb * sinTpre + lZ * cosTpre;
                float  lKy    = max(lKyRaw, 0.08);
                // Penumbra half-width AT THE CONTACT POINT — the skin's own softness, in the
                // same relative-to-occluder unit the button uses, so the two shaders finally
                // mean the same thing by the same authored number. This used to be
                // shadowEdgeAlpha's raw `blur` as a full band width, against the button's
                // `blur * 0.05`: a 20x disagreement, and most of why a knob's shadow read as a
                // soft cloud while a button's read as a hard slab.
                float penHalf  = UI_SHADOW_CONTACT_BLUR(blur, knobRadius);
                float umbraMul = 1.0;
                // Hull sweep + face projection
                if (castMul > 0.001) {
                    float  lKx   = la;
                    float  lKz   = -lb * cosTsafe + lZ * sinTpre;
                    float  faceR = (_KnobFaceShapeEnabled > 0.5)
                        ? knobRadius * saturate(_KnobFaceShapeSize)
                        : max(0.001, knobRadius - faceInset);
                    float  ps    = totalHeight * castMul / lKy;
                    // topOff points TOWARD the lamp: it is added to the SAMPLE position, which
                    // shifts the drawn shadow by -topOff, i.e. AWAY from the lamp. Same convention
                    // as the 2D paths' `topOff = -ld2 * ps`. Signs are inverted from lKx/lKz
                    // because those come from the to-light vector, which points at the lamp.
                    // The throw, as a BASE-PLANE vector — which is what it always was; the
                    // screen-space form this replaces was exactly this pair pushed back through
                    // the orthographic map, which is why that map could not be swapped for a
                    // perspective one without moving the sweep here first.
                    float2 topOff = float2(lKx * ps, lKz * ps);

                    // Cap the throw at maxCast quad-half-sizes: a grazing light (lKy -> 0) sends
                    // `ps` toward an unbounded throw, and past a certain length that doesn't make
                    // the shadow longer, it makes the SWEEP break down — the closest-point-on-
                    // segment parameter below (`t`) is `-dot(sPos,topOff)/|topOff|^2`, which
                    // collapses toward 0 for every on-screen sPos once |topOff| is much bigger
                    // than the knob's own radius. t->0 everywhere means the hull-blend term
                    // (sDH) stops tracking the tip and reads as just the base footprint again —
                    // the shadow looks like it snapped back small even though the throw kept
                    // growing. Holding the throw at a sane multiple of the knob's own size keeps
                    // that projection well-conditioned, so it grows outward and then holds at the
                    // cap instead of degrading past it.
                    // The backing quad is finite (_ShadowUvExpand x the knob), so a throw that
                    // reaches its edge used to be guillotined with a straight line. Bound the cap
                    // by the quad's own reach, and let the PENUMBRA FALLOFF (see
                    // UIShadowDistanceFalloff) do the visual work: a shadow thrown this far is
                    // faint and very soft, so it fades out instead of being cut off.
                    // Fixed, NOT _ShadowUvExpand — that uniform differs between a widget's own
                    // material (1) and its backing quad's copy (2), which would give the two
                    // passes different cast lengths. 2.0 is WidgetShadowQuad's shipped expansion.
                    float quadReach = 2.0;
                    float capLimit  = min(maxCast, quadReach * 0.95);

                    float rawCastLen = length(topOff);
                    if (rawCastLen > capLimit) {
                        topOff    *= capLimit / max(0.0001, rawCastLen);
                        rawCastLen = capLimit;
                    }

                    // CONTACT HARDENING. `t` is where along the throw this pixel sits: 0 at the
                    // foot of the knob, 1 out at the projected tip. The penumbra opens up with
                    // it and the umbra dissolves with it, so one shadow is sharp and dark where
                    // it meets the knob and broad and faint at its far end. Evaluating the
                    // falloff once per WIDGET, as this did, gives every pixel of the shadow the
                    // same softness — a flat card, hovering.
                    float segLen2 = dot(topOff, topOff);
                    float t = saturate(-dot(base0, topOff) / max(0.0001, segLen2));
                    float2 fall = UIShadowPenumbra(rawCastLen * t, knobRadius, blurFac);
                    penHalf    += fall.x;
                    umbraMul    = fall.y;
                    // The hull, swept in the tilt frame. The cast silhouette is the convex
                    // hull of the base footprint and the projected face, and for two convex
                    // sets that hull is EXACTLY the union over s in [0,1] of their linear
                    // interpolation — so a uniform sweep with a running min IS the hull.
                    //
                    // What was here instead evaluated the shape at ONE closest-point-on-segment
                    // parameter and min'd it against the tip's own footprint. That estimate is
                    // only correct when the swept shape does not change size, and the sweep
                    // tapers to the face radius, so the two fields crossed over early on one
                    // side and late on the other and bit a visible notch out of the shadow.
                    //
                    // DYNAMIC loop: the compiler emits ONE getKnobSDF for the whole sweep
                    // instead of unrolling it. That matters more here than anywhere — this
                    // shader's fragment program has hit the HLSL compiler's time limit before,
                    // and getKnobSDF is a 23-case switch. The old code unrolled 3 of them per
                    // slot; this compiles 1 and runs it a few times.
                    int   hullN = UIShadowHullSamples(rawCastLen, knobRadius);
                    float invN  = 1.0 / (float)max(hullN - 1, 1);
                    UNITY_LOOP for (int hs = 1; hs < hullN; hs++) {
                        float  s     = (float)hs * invN;
                        float2 kxzS  = rotate2D(base0 + topOff * s, knobAngle);
                        float  hullR = lerp(knobRadius, faceR, s);
                        float  dS;
                        if (_KnobFaceShapeEnabled > 0.5 && s > 0.5) {
                            dS = getKnobSDF(rotate2D(-kxzS, -_KnobFaceShapeRotation * (PI / 180.0)),
                                hullR, _KnobFaceShapeType, _KnobFaceShapeScale,
                                _KnobFaceShapeParam1, _KnobFaceShapeParam2, _KnobFaceShapeParam3,
                                _KnobFaceShapeParam4, _KnobFaceShapeParam5, _KnobFaceShapeParam6,
                                _KnobFaceShapeTexLayer, _KnobFaceShapeTexScale);
                        } else {
                            dS = getKnobSDF(rotate2D(-kxzS, -_KnobShapeRotation * (PI / 180.0)),
                                hullR, _KnobShapeType, _KnobShapeScale,
                                _KnobShapeParam1, _KnobShapeParam2, _KnobShapeParam3,
                                _KnobShapeParam4, _KnobShapeParam5, _KnobShapeParam6);
                        }
                        sD = min(sD, dS);
                    }
                }
                // Anisotropic tilt-frame -> screen conversion. The frame stretches its second
                // axis by 1/cosT, so a single `sD * cosT` is right along tiltDir and wrong by
                // 1/cosT across it — which spreads the blur band sideways at high tilt until the
                // taper from body to face is swamped. Identity at cosT = 1.
                // Applied ONCE, on the finished hull. Converting each swept sample separately
                // scales fields that are then min'd together by a direction-dependent factor,
                // which creases the result into visible rays along the shadow's flanks.
                float2 nb    = normalize(kxz + float2(1e-6, 1e-6));
                float  sDist = sD * length(float2(nb.x, nb.y * cosTsafe));
                float  alpha = UIShadowEdgeAlpha(sDist, penHalf, aaUnit) * umbraMul;

                // Dissolve into the backing quad's own rim so nothing ever ends in a straight
                // cut. `uv` is already remapped into knob space, so this is 0 at the centre and
                // 1 at the quad edge.
                if (_ShadowPassMode > 0.5) {
                    float2 qEdge = abs(uv - 0.5) * 2.0 / max(_ShadowUvExpand, 1.0);
                    alpha *= 1.0 - smoothstep(0.82, 1.0, max(qEdge.x, qEdge.y));
                }
                return alpha;
            }

            // ---- One shadow slot's uniforms, selected by index --------------------
            // The three _KnobShadowN* sets are the same parameters three times over, one per
            // rig lamp. Selecting them here lets both shadow passes run ONE loop instead of
            // three call sites, which is the difference between compiling getKnobSDF's shape
            // switch once and compiling it three times — and this fragment program is the one
            // that has actually hit the HLSL compiler's time limit.
            struct KnobShadowSlot {
                float  enabled;
                float  blur, dist, blurFac, castMul, maxCast, intensity;
                float3 color;
                float  colorA;
                float3 lightDir;
            };

            KnobShadowSlot knobShadowSlot(int i, float3 l1, float3 l2, float3 l3)
            {
                KnobShadowSlot s;
                s.enabled   = (i == 0) ? _KnobShadow1Enabled   : (i == 1) ? _KnobShadow2Enabled   : _KnobShadow3Enabled;
                s.blur      = (i == 0) ? _KnobShadow1Blur      : (i == 1) ? _KnobShadow2Blur      : _KnobShadow3Blur;
                s.dist      = (i == 0) ? _KnobShadow1Distance  : (i == 1) ? _KnobShadow2Distance  : _KnobShadow3Distance;
                s.blurFac   = (i == 0) ? _KnobShadow1BlurFactor: (i == 1) ? _KnobShadow2BlurFactor: _KnobShadow3BlurFactor;
                s.castMul   = (i == 0) ? _KnobShadow1Cast      : (i == 1) ? _KnobShadow2Cast      : _KnobShadow3Cast;
                s.maxCast   = (i == 0) ? _KnobShadow1MaxCast   : (i == 1) ? _KnobShadow2MaxCast   : _KnobShadow3MaxCast;
                s.intensity = (i == 0) ? _KnobShadow1Intensity : (i == 1) ? _KnobShadow2Intensity : _KnobShadow3Intensity;
                s.color     = (i == 0) ? _KnobShadow1Color.rgb : (i == 1) ? _KnobShadow2Color.rgb : _KnobShadow3Color.rgb;
                s.colorA    = (i == 0) ? _KnobShadow1Color.a   : (i == 1) ? _KnobShadow2Color.a   : _KnobShadow3Color.a;
                s.lightDir  = (i == 0) ? l1 : (i == 1) ? l2 : l3;
                return s;
            }

            // ---- Extracted: 3D Raymarch Knob rendering ----
            void renderRaymarchKnob(
                float2 uv, float2 pos,
                float time, UILight light1, UILight light2, UILight light3,
                inout float4 finalColor, inout float3 emissiveAccum)
            {
                if (_KnobEnabled > 0.5) {
                    float knobRadius = _LineRadius * _KnobSize;
                    float knobAngle = (_AngleStart + _AngleRange * _Value + _KnobRotation) * (PI / 180.0);

                    // Tilt setup (before shadows so they can use it).
                    // Value-driven shift/tilt mirror SDFSliderRM: lerp(Min,Max,_Value)
                    // is added to the static param so the knob can lean/tilt as it turns.
                    float effectiveTilt = UI_VIEW_TILT + (_ViewValueTiltEnabled > 0.5
                        ? lerp(_ViewValueTiltMin, _ViewValueTiltMax, _Value) : 0.0);
                    float viewShiftEffective = UI_VIEW_SHIFT + (_ViewValueShiftEnabled > 0.5
                        ? lerp(_ViewValueShiftMin, _ViewValueShiftMax, _Value) : 0.0);
                    float tiltRad = (_ViewAngle + 90.0) * (PI / 180.0);
                    float2 tiltDir     = float2(cos(tiltRad), sin(tiltRad));
                    float2 tiltNormDir = float2(-tiltDir.y, tiltDir.x);
                    float tiltNorm     = saturate(effectiveTilt / 10.0);
                    float tiltAnglePre = tiltNorm * (PI * 0.5);
                    float cosTpre = cos(tiltAnglePre);
                    float sinTpre = sin(tiltAnglePre);

                    // Geometry params — hoisted here so shadows can use totalHeight / faceInset.
                    float bevelDist     = (_KnobBevelEnabled > 0.5) ? _KnobBevelDistance : 0.0;
                    float bevelDepthRaw = (_KnobBevelEnabled > 0.5) ? abs(_KnobBevelDepth) : 0.0;
                    float bevelHeight   = knobRadius * lerp(0.05, 1.0, bevelDepthRaw);
                    float lipHeight     = knobRadius * _KnobLipHeight;
                    float rimWidth      = (_KnobRimEnabled > 0.5) ? _KnobRimWidth : 0.0;
                    float totalHeight   = lipHeight + bevelHeight;
                    float faceInset     = rimWidth + bevelDist;

                    // Knob shadows (_KnobShadow1/2/3) render in the frag's shadow-pass block
                    // (_ShadowPassMode=1, on the expanded backing quad driven by
                    // WidgetShadowQuad), not here — that block mirrors the tilt/geometry
                    // locals above (KEEP IN SYNC), so the look is identical, it just can't
                    // clip at this quad's edge.

                    // ---- 3D Raymarch knob body ----

                    // Ray setup (reuse tilt values computed above)
                    float cosT = cosTpre;
                    float sinT = sinTpre;
                    float screenAcross = dot(pos, tiltNormDir);
                    float screenAlong  = dot(pos, tiltDir);
                    float3 orthoDir = float3(0.0, -cosT, -sinT);
                    float boundRadius = knobRadius * 1.2 + totalHeight;
                    float startDist = boundRadius + knobRadius * 0.5;
                    float3 knobPlanePoint = float3(screenAcross, screenAlong * sinT, -screenAlong * cosT);

                    // FOV
                    float3 rayDir;
                    float3 rayOrigin;
                    if (_ViewFOV > 0.001) {
                        // focalDist = 1/tan(halfFOV): 0.5→45°, 0.667→60°, 0.889→80°, 1→90°
                        float focalDist = 1.0 / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                        float3 camPos = float3(viewShiftEffective, focalDist * cosT, focalDist * sinT);
                        rayDir = normalize(knobPlanePoint - camPos);
                        rayOrigin = knobPlanePoint - rayDir * startDist;
                    } else {
                        rayDir = orthoDir;
                        rayOrigin = float3(
                            screenAcross,
                            screenAlong * sinT + startDist * cosT,
                            -screenAlong * cosT + startDist * sinT
                        );
                    }

                    // Rotate ray into knob's local frame for _Value rotation
                    rayOrigin.xz = rotate2D(rayOrigin.xz, knobAngle);
                    rayDir.xz    = rotate2D(rayDir.xz,    knobAngle);

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
                            ExtrusionParams extParams;
                            extParams.knobRadius  = knobRadius;
                            extParams.lipHeight   = lipHeight;
                            extParams.rimWidth    = rimWidth;
                            extParams.bevelHeight = bevelHeight;
                            extParams.bevelDist   = bevelDist;
                            extParams.totalHeight = totalHeight;
                            extParams.hasFaceShape = (_KnobFaceShapeEnabled > 0.5) ? 1 : 0;
                            extParams.filletRadius = bevelHeight * _KnobBevelSmoothness * 0.4;

                            // Sphere-march
                            float t = tStart;
                            float3 p = rayOrigin + t * rayDir;
                            float marchEps = knobRadius * 0.001;
                            float hitBaseSDF = 0.0;
                            bool hitFound = false;

                            UNITY_LOOP for (int i = 0; i < 64; i++) {
                                float baseSDF_m = evalKnobSDF(p.xz, knobRadius);
                                float faceSDF_m = computeFaceSDF(p.xz, baseSDF_m, faceInset, bevelDist, knobRadius);
                                float d = sdfExtrusion3D(p, baseSDF_m, faceSDF_m, extParams);
                                if (d < marchEps) {
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
                                float surfaceEps = knobRadius * 0.005;
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
                                // NO LIP = NO LIP SURFACE (2026-09-13). With _KnobLipHeight 0 the bevel
                                // wall meets the base plane at the footprint radius, and grazing rays
                                // land isolated hits there that classify as LIP/RIM (normal straight
                                // up, lit near-white) — a scatter of pale dots round the cap. There is
                                // no lip to draw, so those hits get no coverage. Skins with a real lip
                                // are untouched.
                                bool noLipSeam = (lipHeight <= lipEps) && (hitSurface != SURFACE_FACE) && (hitSurface != SURFACE_WALL);
                                float surfaceTint = (hitSurface == SURFACE_WALL) ? 0.9 :
                                                    (hitSurface == SURFACE_RIM)  ? 1.0 :
                                                    (hitSurface == SURFACE_LIP)  ? 0.75 : 1.0;

                                // Analytical surface normals
                                // wallGradN: raw 2D SDF gradient on SURFACE_WALL, used by topology gradient types.
                                float2 wallGradN = float2(1, 0);
                                float3 hitNormal;
                                {
                                    float eps2d = max(0.0005, knobRadius * 0.004);
                                    float bdx   = evalKnobSDF(p.xz + float2(eps2d, 0), knobRadius);
                                    float bdz   = evalKnobSDF(p.xz + float2(0, eps2d), knobRadius);
                                    float2 grad2D = float2(bdx - hitBaseSDF, bdz - hitBaseSDF);
                                    float  gLen   = length(grad2D);
                                    float2 gradN  = (gLen > 0.0001) ? (grad2D / gLen) : float2(1, 0);

                                    if (hitSurface == SURFACE_FACE || hitSurface == SURFACE_RIM) {
                                        hitNormal = float3(0, 1, 0);
                                    } else if (hitSurface == SURFACE_LIP) {
                                        hitNormal = normalize(float3(gradN.x, 0.6, gradN.y));
                                    } else {
                                        wallGradN = gradN;  // capture for BevelDepth / BevelWalls
                                        float bevelAngleRM = atan2(bevelHeight, max(0.0001, bevelDist));
                                        float sinB = sin(bevelAngleRM);
                                        float cosB = cos(bevelAngleRM);
                                        float3 wallNorm = normalize(float3(gradN.x * sinB, cosB, gradN.y * sinB));
                                        UNITY_BRANCH if (_KnobBevelSmoothness > 0.001) {
                                            float filletR = bevelHeight * _KnobBevelSmoothness * 0.4;
                                            float edgeT   = saturate((y - (totalHeight - filletR)) / max(filletR, 0.0001));
                                            hitNormal = normalize(lerp(wallNorm, float3(0, 1, 0), smoothstep(0.0, 1.0, edgeT)));
                                        } else {
                                            hitNormal = wallNorm;
                                        }
                                    }
                                }

                                // Face dome/bowl perturbation
                                UNITY_BRANCH if (hitSurface == SURFACE_FACE && abs(_KnobFaceSmoothness) > 0.001) {
                                    float2 xz = p.xz;
                                    float r = length(xz);
                                    float faceRadius = (_KnobFaceShapeEnabled > 0.5)
                                        ? max(0.001, knobRadius * _KnobFaceShapeSize)
                                        : max(0.001, knobRadius - faceInset);
                                    float radialT = saturate(r / faceRadius);
                                    float2 radialDir2D = (r > 0.0001) ? (xz / r) : float2(0, 0);
                                    float domeStrength = _KnobFaceSmoothness * radialT;
                                    float3 domeDir = float3(radialDir2D.x * domeStrength, 0, radialDir2D.y * domeStrength);
                                    hitNormal = normalize(hitNormal + domeDir);
                                }

                                // Rotate normal back from knob local frame
                                hitNormal.xz = rotate2D(hitNormal.xz, -knobAngle);

                                // Map normal to screen space.
                                // Negate xy to match the 2D bevel convention (inward-pointing)
                                // used by CalculateCircleBevelNormal / CalculateShapeBevelNormal,
                                // which pairs with lightDirection being the light travel direction.
                                float3 screenNormal3D = normalToScreenSpace(hitNormal, sinT, cosT);
                                float2 screenNorm2D   = screenNormal3D.x * tiltNormDir + screenNormal3D.y * tiltDir;
                                float3 lightNormal    = normalize(float3(-screenNorm2D, max(0.0, screenNormal3D.z)));

                                // Silhouette AA
                                float outerAA   = fwidth(hitBaseSDF) * 0.75;
                                float outerMask;
                                if (hitSurface == SURFACE_FACE && _KnobFaceShapeEnabled > 0.5) {
                                    // Face shape may extend past the base knob footprint.
                                    // Use the face shape SDF directly for AA masking.
                                    float faceR = knobRadius * saturate(_KnobFaceShapeSize);
                                    float2 pRotFace = rotate2D(-p.xz, -_KnobFaceShapeRotation * (PI / 180.0));
                                    float faceShapeDist = getKnobSDF(pRotFace, faceR,
                                        _KnobFaceShapeType, _KnobFaceShapeScale,
                                        _KnobFaceShapeParam1, _KnobFaceShapeParam2, _KnobFaceShapeParam3,
                                        _KnobFaceShapeParam4, _KnobFaceShapeParam5, _KnobFaceShapeParam6,
                                        _KnobFaceShapeTexLayer, _KnobFaceShapeTexScale);
                                    float faceAA = fwidth(faceShapeDist) * 0.75;
                                    outerMask = smoothstep(faceAA, -faceAA, faceShapeDist);
                                } else {
                                    outerMask = (hitSurface == SURFACE_FACE)
                                              ? smoothstep(outerAA, -outerAA, hitBaseSDF)
                                              : (noLipSeam ? 0.0 : 1.0);
                                }

                                float3 knobBaseColor = _KnobColor.rgb;
                                float knobSpecularMod = 1.0;
                                float2 knobNormalOffset = float2(0.0, 0.0);

                                // UV for pattern/gradient: un-rotate hit position
                                float2 screenXZ = rotate2D(p.xz, -knobAngle);
                                float2 faceUV = screenXZ + float2(0.5, 0.5);

                                // Apply gradient
                                UNITY_BRANCH if (_KnobGradientEnabled > 0.5) {
                                    float4 gradientColor = CalculateGradient(faceUV,
                                        _KnobGradientColorA, _KnobGradientColorB,
                                        _KnobGradientColorC, _KnobGradientColorD,
                                        _KnobGradientDirection, _KnobGradientType,
                                        _KnobGradientSpeed, _KnobGradientScale,
                                        _KnobGradientOffset, time, _KnobGradientColorUsed);
                                    knobBaseColor = lerp(knobBaseColor, gradientColor.rgb, gradientColor.a);
                                }

                                float3 surfaceBaseColor = knobBaseColor * surfaceTint;

                                // Face pattern
                                UNITY_BRANCH if (hitSurface == SURFACE_FACE && _KnobPatternEnabled > 0.5) {
                                    UIComponent faceComp = CreateUIComponent(
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
                                    surfaceBaseColor = ApplyMaterialPattern(knobBaseColor, faceUV, faceComp,
                                        _Value, _AngleRange, knobSpecularMod, knobNormalOffset);
                                }

                                // Wall pattern/gradient
                                UNITY_BRANCH if (hitSurface == SURFACE_WALL) {
                                    float3 bevelColor = surfaceBaseColor;
                                    UNITY_BRANCH if (_KnobBevelGradientEnabled > 0.5) {
                                        int bgt = (int)_KnobBevelGradientType;
                                        if (bgt >= 5) {
                                            // ── Normal-based bevel gradient (RM-only) ─────────────────────
                                            // normalDot = dot(surface normal, outward radial direction)
                                            //   +1 : surface faces directly outward  → outer perimeter wall
                                            //    0 : surface faces sideways          → slit side walls
                                            //   -1 : surface faces directly inward   → slit back walls
                                            float2 pXZNorm  = (length(p.xz) > 0.0001) ? normalize(p.xz) : float2(0, 1);
                                            float  normalDot = dot(wallGradN, pXZNorm);

                                            if (bgt == 5) {
                                                // BevelDepth: smooth A→D ramp across normalDot.
                                                // A = outer wall (normalDot≈1), D = groove/slit back (normalDot≈0 or less).
                                                // scale: range multiplier — 1=maps [0,1] normalDot to full A→D span;
                                                //        2=only the top half of normalDot fills all stops.
                                                // offset: shift (positive pushes toward D, negative toward A).
                                                float t = saturate((1.0 - normalDot) * max(0.001, _KnobBevelGradientScale)
                                                                   + _KnobBevelGradientOffset);
                                                // Direct piecewise lerp — bypasses InterpolateGradientColors'
                                                // triangle-wave distortion so the ramp is always linear A→D.
                                                int   nc = (int)_KnobBevelGradientColorUsed;
                                                float ts = t * float(max(1, nc - 1));
                                                float4 bevelRamp;
                                                if (nc <= 2) {
                                                    bevelRamp = lerp(_KnobBevelGradientColorA, _KnobBevelGradientColorB, ts);
                                                } else if (nc == 3) {
                                                    bevelRamp = (ts < 1.0)
                                                        ? lerp(_KnobBevelGradientColorA, _KnobBevelGradientColorB, ts)
                                                        : lerp(_KnobBevelGradientColorB, _KnobBevelGradientColorC, ts - 1.0);
                                                } else {
                                                    if      (ts < 1.0) bevelRamp = lerp(_KnobBevelGradientColorA, _KnobBevelGradientColorB, ts);
                                                    else if (ts < 2.0) bevelRamp = lerp(_KnobBevelGradientColorB, _KnobBevelGradientColorC, ts - 1.0);
                                                    else               bevelRamp = lerp(_KnobBevelGradientColorC, _KnobBevelGradientColorD, ts - 2.0);
                                                }
                                                bevelColor = bevelRamp.rgb;
                                            } else { // bgt == 6: BevelWalls
                                                // Uses normalDot (radial component) AND tangentialMag (tangential
                                                // component of the surface normal) as two independent signals:
                                                //   tangentialMag high  → surface faces sideways  = ridge/slit SIDES (B, C)
                                                //   tangentialMag low + normalDot high → outer wall (A)
                                                //   tangentialMag low + normalDot low  → groove back (D)
                                                // This correctly discriminates all zones on smooth shapes (fluted,
                                                // sinusoidal) where normalDot never goes negative, as well as slot
                                                // shapes (CapScrew, DaviesIndicator) where it does.
                                                // scale: transition sharpness (1=soft, 5=sharp edges)
                                                // offset (±2): shifts the outer vs groove normalDot threshold
                                                float2 tangentDir    = float2(-pXZNorm.y, pXZNorm.x);
                                                float  tangentialMag = abs(dot(wallGradN, tangentDir));
                                                float  sharpK  = 0.09 / max(0.3, _KnobBevelGradientScale);
                                                float  outerTh = 0.65 + _KnobBevelGradientOffset * 0.15;

                                                // 4-zone partition — by construction wA+wB+wC+wD == 1,
                                                // no explicit normalization pass needed.
                                                float isSide  = smoothstep(0.45 - sharpK, 0.45 + sharpK, tangentialMag);
                                                float isOuter = smoothstep(outerTh - sharpK, outerTh + sharpK, normalDot);
                                                float bcSplit = smoothstep(-sharpK, sharpK, normalDot);
                                                float wA = (1.0 - isSide) * isOuter;          // outer wall
                                                float wD = (1.0 - isSide) * (1.0 - isOuter); // groove/slit back
                                                float wB = isSide * bcSplit;                   // side, outward-leaning
                                                float wC = isSide * (1.0 - bcSplit);           // side, inward-leaning

                                                int numBG = (int)_KnobBevelGradientColorUsed;
                                                if (numBG >= 4) {
                                                    bevelColor = wA * _KnobBevelGradientColorA.rgb
                                                               + wB * _KnobBevelGradientColorB.rgb
                                                               + wC * _KnobBevelGradientColorC.rgb
                                                               + wD * _KnobBevelGradientColorD.rgb;
                                                } else if (numBG == 3) {
                                                    // B+C merge into one "slit side" color
                                                    bevelColor = wA        * _KnobBevelGradientColorA.rgb
                                                               + (wB + wC) * _KnobBevelGradientColorB.rgb
                                                               + wD        * _KnobBevelGradientColorC.rgb;
                                                } else {
                                                    // 2 colors: A=outer wall, B=everything else
                                                    bevelColor = wA         * _KnobBevelGradientColorA.rgb
                                                               + (wB+wC+wD) * _KnobBevelGradientColorB.rgb;
                                                }
                                            }
                                        } else {
                                            // Standard UV-space gradient types (Linear/Radial/Angular/Diamond/Triangle)
                                            float4 bevelGrad = CalculateGradient(faceUV,
                                                _KnobBevelGradientColorA, _KnobBevelGradientColorB,
                                                _KnobBevelGradientColorC, _KnobBevelGradientColorD,
                                                _KnobBevelGradientDirection, _KnobBevelGradientType,
                                                _KnobBevelGradientSpeed, _KnobBevelGradientScale,
                                                _KnobBevelGradientOffset, time, _KnobBevelGradientColorUsed);
                                            bevelColor = bevelGrad.rgb;
                                        }
                                    }
                                    UNITY_BRANCH if (_KnobBevelPatternEnabled > 0.5) {
                                        UIComponent bevelComp = CreateUIComponent(
                                            float4(1,1,1,1), 1.0,
                                            0.0, 0.0, 0.0, 0.0,
                                            float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1), float4(1,1,1,1),
                                            float2(1,0), 1.0, 1.0, 0.0, 0.0, 1.0, 0,
                                            _KnobBevelPatternType, _KnobBevelPatternScale,
                                            _KnobBevelPatternIntensity, _KnobBevelPatternContrast,
                                            _KnobBevelPatternSpecularEffect, _KnobBevelPatternRoughnessEffect,
                                            1.0, 0.0, 0.0, 1.0, 0.0,
                                            _KnobBevelPatternParam1, _KnobBevelPatternParam2, _KnobBevelPatternParam3,
                                            0.0, 1.0,
                                            _KnobBevelPatternColorEnabled, _KnobBevelPatternColorMode,
                                            _KnobBevelPatternColorType, _KnobBevelPatternColorUsed,
                                            _KnobBevelPatternColorA, _KnobBevelPatternColorB,
                                            _KnobBevelPatternColorC, _KnobBevelPatternColorD
                                        );
                                        bevelColor = ApplyMaterialPattern(bevelColor, faceUV, bevelComp,
                                            _Value, _AngleRange, knobSpecularMod, knobNormalOffset);
                                    }
                                    surfaceBaseColor = bevelColor;
                                }

                                // Lighting
                                float3 surfaceColor = ApplyUILighting(lightNormal, surfaceBaseColor,
                                                                      _LightingAmbient, knobSpecularMod, knobNormalOffset,
                                                                      light1, light2, light3);
                                UI_MATERIAL_V2(surfaceColor, surfaceBaseColor, lightNormal, Knob, -1.0)

                                // Self-shadow: bevel wall casts shadow onto rim/lip
                                UNITY_BRANCH
                                if ((hitSurface == SURFACE_RIM || hitSurface == SURFACE_LIP) && bevelHeight > 0.01) {
                                    float rl = length(p.xz);
                                    float2 outDir = (rl > 0.0001) ? (p.xz / rl) : float2(1, 0);
                                    float wallTanAngle = bevelHeight / max(0.001, bevelDist + rimWidth);

                                    // Evaluate per-light occlusion by transforming light
                                    // direction into knob local 3D space
                                    #define SELF_SHADOW_LIGHT(lightEnabled, lightDir, lightIntensity, factor) \
                                    if (lightEnabled) { \
                                        float3 tl = UIToLightVector(lightDir); \
                                        float2 ld = tl.xy; \
                                        float lacross = dot(ld, tiltNormDir); \
                                        float lalong  = dot(ld, tiltDir); \
                                        float lz = tl.z; \
                                        float3 lKnob = float3(lacross, \
                                            lalong * sinT + lz * cosT, \
                                            -lalong * cosT + lz * sinT); \
                                        lKnob.xz = rotate2D(lKnob.xz, knobAngle); \
                                        float lHorizLen = length(lKnob.xz); \
                                        float2 lHoriz = (lHorizLen > 0.0001) ? (lKnob.xz / lHorizLen) : float2(0, 0); \
                                        float shadowSide = saturate(dot(outDir, lHoriz)); \
                                        float lightTan = lKnob.y / max(0.001, lHorizLen); \
                                        float occluded = saturate(1.0 - lightTan / max(0.001, wallTanAngle)); \
                                        factor = min(factor, 1.0 - shadowSide * occluded); \
                                    }
                                    float selfShadow = 1.0;
                                    SELF_SHADOW_LIGHT(light1.enabled, light1.direction, light1.intensity, selfShadow)
                                    SELF_SHADOW_LIGHT(light2.enabled, light2.direction, light2.intensity, selfShadow)
                                    SELF_SHADOW_LIGHT(light3.enabled, light3.direction, light3.intensity, selfShadow)
                                    #undef SELF_SHADOW_LIGHT

                                    surfaceColor *= lerp(1.0, selfShadow, 0.85);
                                }

                                // Composite into layer stack
                                compositeOver(finalColor, surfaceColor, outerMask * _KnobRenderAlpha);
                                emissiveAccum += knobBaseColor * outerMask * _KnobRenderEmissive;
                            }
                        }
                    }
                }
            }

#endif // COMPILE_KNOB

            // ---- Fragment ----
            fixed4 frag(v2f IN) : SV_Target
            {
                UI_SET_SCREEN_UV(IN.screenPos)
                float2 uv = IN.texcoord;
                // Shadow quad: remap uv into the widget's own uv space (quad is
                // _ShadowUvExpand× the widget, centered) so all SDF math is unchanged and
                // shadows can extend past where the widget quad would end.
                if (_ShadowPassMode > 0.5) uv = (uv - 0.5) * _ShadowUvExpand + 0.5;
                float2 center = float2(0.5, 0.5);
                float2 pos = (uv - center) * 2.0;

                // One screen pixel in the units the shadow SDFs work in, taken here in uniform
                // control flow (the self-shadow call site further down sits inside a per-pixel
                // branch where derivatives are undefined). Becomes the floor on a shadow edge's
                // width so a heavily faded distant shadow can never collapse to a 1-pixel step.
                float knobShadowAaUnit = max(fwidth(uv.x), fwidth(uv.y)) * 2.0 * 0.75;

                float distFromCenter = length(pos);

                float fillRadius = _LineRadius;
                float valueThickness = _LineWidth * _LineSublineThickness;
                float extendedLineWidth = max(_LineWidth, valueThickness + 0.02) + 0.04;
                float lineOuterRadius = _LineRadius + extendedLineWidth;
                float currentAngleRange = _AngleRange * _Value;

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

                // ============================================================
                // THE CAST SHADOW — computed ONCE, consumed by BOTH passes.
                //
                // `castShadow` is a premultiplied layer holding everything this knob throws.
                // The backing quad (_ShadowPassMode=1) emits the half that falls OUTSIDE the
                // knob's own quad, into the buffer every other surface reads. The knob's own
                // program keeps the half that falls INSIDE it and applies it over its own
                // siblings — Line, Fill, Value arc, ticks, border — further down. The two
                // halves are exact complements (see UIShadowQuadSplit), so the seam at the quad
                // boundary cannot show, and the knob can then safely READ the buffer for
                // everyone else's shadows without multiplying its own back over its own face.
                //
                // Computing it ONCE rather than once per pass is not tidiness: it halves how
                // many times getKnobSDF's 23-case shape switch is instantiated in this fragment
                // program, and this is the one program in the project that has actually hit the
                // HLSL compiler's time limit.
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

                    // RM knob cast shadows (projected hull sweep). The tilt/geometry locals
                    // mirror renderRaymarchKnob's hoisted setup — KEEP IN SYNC with it.
                    // (computeRMKnobShadowAlpha is only compiled with the knob body.)
#if defined(COMPILE_KNOB)
                    if (_KnobEnabled > 0.5) {
                        float knobRadius = _LineRadius * _KnobSize;
                        float knobAngle = (_AngleStart + _AngleRange * _Value + _KnobRotation) * (PI / 180.0);
                        float effectiveTilt = UI_VIEW_TILT + (_ViewValueTiltEnabled > 0.5
                            ? lerp(_ViewValueTiltMin, _ViewValueTiltMax, _Value) : 0.0);
                        float tiltRad = (_ViewAngle + 90.0) * (PI / 180.0);
                        float2 tiltDir     = float2(cos(tiltRad), sin(tiltRad));
                        float2 tiltNormDir = float2(-tiltDir.y, tiltDir.x);
                        float tiltNorm     = saturate(effectiveTilt / 10.0);
                        float tiltAnglePre = tiltNorm * (PI * 0.5);
                        float cosTpre = cos(tiltAnglePre);
                        float sinTpre = sin(tiltAnglePre);
                        float bevelDist     = (_KnobBevelEnabled > 0.5) ? _KnobBevelDistance : 0.0;
                        float bevelDepthRaw = (_KnobBevelEnabled > 0.5) ? abs(_KnobBevelDepth) : 0.0;
                        float bevelHeight   = knobRadius * lerp(0.05, 1.0, bevelDepthRaw);
                        float lipHeight     = knobRadius * _KnobLipHeight;
                        float rimWidth      = (_KnobRimEnabled > 0.5) ? _KnobRimWidth : 0.0;
                        float totalHeight   = lipHeight + bevelHeight;
                        float faceInset     = rimWidth + bevelDist;

                        UNITY_LOOP for (int si = 0; si < 3; si++) {
                            KnobShadowSlot sl = knobShadowSlot(si, lightDir1, lightDir2, lightDir3);
                            if (sl.enabled < 0.5) continue;
                            float sa = computeRMKnobShadowAlpha(uv, sl.lightDir,
                                sl.blur, sl.dist, sl.blurFac, sl.castMul, sl.maxCast,
                                tiltDir, tiltNormDir, cosTpre, sinTpre, knobAngle, knobRadius,
                                faceInset, totalHeight, knobShadowAaUnit);
                            if (sa > 0.001) compositeOver(castShadow, sl.color, sl.colorA * sa * sl.intensity);
                        }
                    }
#endif // COMPILE_KNOB
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

#if defined(COMPILE_EDGE_SHADOWS_RINGS_MARKS)
                // ============================================================
                // Edge indent (behind everything)
                // ============================================================
                if (_EdgeEnabled > 0.5) {
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
                        float edgeMask = indentAlpha * _EdgeIntensity;
                        compositeOver(finalColor, edgeBaseColor, edgeMask * _EdgeRenderAlpha);
                        emissiveAccum += edgeBaseColor * edgeMask * _EdgeRenderEmissive;
                    }
                }

                // ============================================================
                // External shadows — render in the shadow-pass block at the top of frag
                // (_ShadowPassMode=1, expanded backing quad), not here.
                // ============================================================

                // ============================================================
                // Outer decorative rings
                // ============================================================
                finalColor = renderOuterRing(pos, finalColor, _OuterRing1Enabled, _OuterRing1Radius,
                                            _OuterRing1Thickness, _OuterRing1Color, _OuterRing1AngleStart,
                                            _OuterRing1AngleRange, _OuterRing1Style, _OuterRing1RenderAlpha, _OuterRing1RenderEmissive, emissiveAccum);
                finalColor = renderOuterRing(pos, finalColor, _OuterRing2Enabled, _OuterRing2Radius,
                                            _OuterRing2Thickness, _OuterRing2Color, _OuterRing2AngleStart,
                                            _OuterRing2AngleRange, _OuterRing2Style, _OuterRing2RenderAlpha, _OuterRing2RenderEmissive, emissiveAccum);
                finalColor = renderOuterRing(pos, finalColor, _OuterRing3Enabled, _OuterRing3Radius,
                                            _OuterRing3Thickness, _OuterRing3Color, _OuterRing3AngleStart,
                                            _OuterRing3AngleRange, _OuterRing3Style, _OuterRing3RenderAlpha, _OuterRing3RenderEmissive, emissiveAccum);

                // ============================================================
                // Scale marks
                // ============================================================
                finalColor = renderScaleMarks(pos, finalColor, emissiveAccum);
#endif // COMPILE_EDGE_SHADOWS_RINGS_MARKS

#if defined(COMPILE_FILL_LINE_VALUE)
                // ============================================================
                // Fill / Line / Value (extracted to reduce frag size)
                // ============================================================
                renderFillLineValue(uv, pos, IN.worldPosition.xy,
                    distFromCenter, lineOuterRadius, currentAngleRange, valueThickness,
                    time, light1, light2, light3, finalColor, emissiveAccum);

#endif // COMPILE_FILL_LINE_VALUE

#if defined(COMPILE_NUB)
                // ============================================================
                // Nub (identical to SDFKnob)
                // ============================================================
                if (_NubEnabled > 0.5) {
                    float uiAngle = _AngleStart + _AngleRange * _Value + _NubRotation;
                    float normalizedAngle = fmod(uiAngle + 360.0, 360.0);
                    float atan2Angle;
                    if (normalizedAngle <= 180.0) {
                        atan2Angle = 180.0 - normalizedAngle;
                    } else {
                        atan2Angle = 540.0 - normalizedAngle;
                    }
                    if (atan2Angle >= 360.0) atan2Angle -= 360.0;
                    float mathAngle = atan2Angle * (PI / 180.0);
                    float2 nubCenter = float2(cos(mathAngle), sin(mathAngle)) * _NubDistance;
                    float2 nubPos = pos - nubCenter;
                    float2 orientedNubPos = rotate2D(nubPos, -mathAngle);
                    if (_NubShapeRotation != 0.0)
                        orientedNubPos = rotate2D(orientedNubPos, _NubShapeRotation * (PI / 180.0));
                    float nubDist = getNubSDF(orientedNubPos, _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);
                    float nubAA = fwidth(nubDist) * 0.75;
                    float nubMask = smoothstep(nubAA, -nubAA, nubDist);

                    // Nub edge indent
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
                        float3 baseColor = nubComponent.color.rgb;
                        if (nubComponent.gradientEnabled > 0.5) {
                            float2 nubUV = (nubCenter * 0.5 + 0.5);
                            float4 gradientColor = CalculateGradient(nubUV, nubComponent.gradientColorA, nubComponent.gradientColorB,
                                                                   nubComponent.gradientColorC, nubComponent.gradientColorD,
                                                                   nubComponent.gradientDirection, nubComponent.gradientType,
                                                                   nubComponent.gradientSpeed, nubComponent.gradientScale,
                                                                   nubComponent.gradientOffset, time, _NubGradientColorUsed);
                            baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a);
                        }
                        if (nubComponent.globalBlend > 0.0) {
                            float4 globalColor = CalculateGlobalGradient(IN.worldPosition.xy, time);
                            baseColor = lerp(baseColor, globalColor.rgb, nubComponent.globalBlend * nubComponent.globalIntensity);
                        }
                        float specularMod;
                        float2 normalOffset;
                        float3 patternedColor = ApplyMaterialPattern(baseColor, uv, nubComponent, _Value, _AngleRange,
                                                                   specularMod, normalOffset);
                        normalOffset = rotate2D(normalOffset, mathAngle);
                        float nubSize;
                        if (_NubShapeType == 0) {
                            nubSize = min(_NubSizeWidth, _NubSizeHeight);
                        } else {
                            nubSize = max(_NubSizeWidth, _NubSizeHeight);
                        }
                        float bevelEpsilon = 0.001;
                        float centerDist = getNubSDF(orientedNubPos, _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);
                        float distX = getNubSDF(orientedNubPos + float2(bevelEpsilon, 0), _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);
                        float distY = getNubSDF(orientedNubPos + float2(0, bevelEpsilon), _NubShapeType, _NubSizeWidth, _NubSizeHeight, _NubShapeParam1, _NubShapeParam2, _NubShapeParam3);
                        float2 sdfGradient = float2(distX - centerDist, distY - centerDist) / bevelEpsilon;
                        sdfGradient = normalize(sdfGradient);
                        float edgeDistance = abs(centerDist);
                        float bevelFactor = smoothstep(nubComponent.bevelDistance, nubComponent.bevelDistance - nubComponent.bevelSmoothness, edgeDistance);
                        float effectiveNubBevelDepth = (_NubBevelEnabled > 0.5) ? nubComponent.bevelDepth : 0.0;
                        float2 localNormal2D = float2(
                            sdfGradient.x * effectiveNubBevelDepth * (1.0 - bevelFactor),
                            sdfGradient.y * effectiveNubBevelDepth * (1.0 - bevelFactor)
                        );
                        float2 worldNormal2D = rotate2D(localNormal2D, mathAngle);
                        float3 normal = normalize(float3(worldNormal2D.x, worldNormal2D.y, 1.0));
                        RimResult rimBevelResult = CalculateRimFromSDF(
                            uv, patternedColor, normal, nubDist,
                            _NubRimEnabled, _NubRimDepth, _NubRimWidth, _NubRimSmoothness,
                            light1, light2, light3
                        );
                        float3 litColor = ApplyUILighting(rimBevelResult.normal, rimBevelResult.litColor, _LightingAmbient, specularMod, normalOffset,
                                                            light1, light2, light3);
                        compositeOver(finalColor, litColor, nubMask * nubComponent.alpha);
                        emissiveAccum += baseColor * nubMask * _NubRenderEmissive;
                    }
                }

#endif // COMPILE_NUB

#if defined(COMPILE_BORDER)
                // ============================================================
                // Border — rendered before the knob so the 3D body sits on top
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
                    float4 borderResult = calculateBorder(uv, borderBaseColor, _BorderWidth, _BorderSoftness, borderTerritory, _BorderInset, _BorderFalloff);
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
                        compositeOver(finalColor, borderResult.rgb, borderMask * _BorderRenderAlpha);
                        emissiveAccum += borderResult.rgb * borderMask * _BorderRenderEmissive;
                    }
                }

#endif // COMPILE_BORDER

#if defined(COMPILE_KNOB)
                // ============================================================
                // KnobEdge — indent around knob base shape, rendered under knob
                // ============================================================
                if (_KnobEnabled > 0.5 && _KnobEdgeEnabled > 0.5) {
                    float knobEdgeRadius = _LineRadius * _KnobSize;
                    float knobEdgeAngle = (_AngleStart + _AngleRange * _Value + _KnobRotation) * (PI / 180.0);
                    // Tilt basis (same as renderRaymarchKnob, incl. value-driven tilt)
                    float keEffTilt = UI_VIEW_TILT + (_ViewValueTiltEnabled > 0.5
                        ? lerp(_ViewValueTiltMin, _ViewValueTiltMax, _Value) : 0.0);
                    float keTiltRad = (_ViewAngle + 90.0) * (PI / 180.0);
                    float2 keTiltDir     = float2(cos(keTiltRad), sin(keTiltRad));
                    float2 keTiltNormDir = float2(-keTiltDir.y, keTiltDir.x);
                    float keCosT = cos(saturate(keEffTilt / 10.0) * (PI * 0.5));
                    // Decompose screen pos into tilt basis, un-foreshorten along axis
                    float keAc = dot(pos, keTiltNormDir);
                    float keAl = dot(pos, keTiltDir) / max(0.001, keCosT);
                    // Transform to knob-local XZ (matches shadow convention)
                    float2 knobEdgePos = rotate2D(float2(keAc, -keAl), knobEdgeAngle);
                    float knobEdgeSDF = getKnobSDF(
                        rotate2D(-knobEdgePos, -_KnobShapeRotation * (PI / 180.0)),
                        knobEdgeRadius, _KnobShapeType, _KnobShapeScale,
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

                // ============================================================
                // Self-shadow — the IN-QUAD half of this knob's own cast shadow.
                //
                // The knob body stands above the Line, Fill, Value arc, ticks and border, so it
                // throws a shadow across them. Nothing else in the pipeline can put it there:
                // the shared buffer holds only the OUTSIDE half (see the cast-shadow block at
                // the top of frag), precisely so this knob can read that buffer for its
                // neighbours' shadows without darkening its own face with its own.
                //
                // `castShadow` was already scaled by the in-quad complement up there, so this
                // is just the application. It is the SAME layer the backing quad emits, which
                // is what makes the two halves the same silhouette by construction — there is
                // no second, hand-synced approximation to drift out of step any more.
                //
                // APPLIED EXACTLY ONCE, and BEFORE the 3D body. Both parts matter:
                //   • Once — applying the same darken again after the body draws was tried, to
                //     get the shaft's shadow onto the cap. It produced two shadow densities
                //     (body-covered pixels got one application, sibling pixels two) and put
                //     shadow on top of the caster's own body. Reverted.
                //   • Before the body — so the body's own draw covers its footprint. A knob
                //     must not receive the shadow it is itself casting.
                // ============================================================
                if (castShadow.a > 0.002) {
                    UIApplySelfShadow(finalColor, castShadow.rgb / max(castShadow.a, 1e-4), castShadow.a);
                }

                // ============================================================
                // 3D Raymarch Knob component (extracted to reduce frag size)
                // ============================================================
                renderRaymarchKnob(uv, pos, time, light1, light2, light3,
                    finalColor, emissiveAccum);

#endif // COMPILE_KNOB

#if defined(COMPILE_KNOBNUB)
                // ============================================================
                // KnobNub — tilt-aware: orbits on the tilted face plane
                // ============================================================
                if (_KnobEnabled > 0.5 && _KnobNubEnabled > 0.5) {
                    float knubRadius  = _LineRadius * _KnobSize;
                    float uiAngleKN      = _AngleStart + _AngleRange * _Value + _KnobRotation;
                    float normAngleKN    = fmod(uiAngleKN + 360.0, 360.0);
                    float a2KN           = (normAngleKN <= 180.0) ? (180.0 - normAngleKN) : (540.0 - normAngleKN);
                    if (a2KN >= 360.0) a2KN -= 360.0;
                    float mathAngleKN    = a2KN * (PI / 180.0);

                    // Recompute tilt basis (same as renderRaymarchKnob), including the
                    // value-driven shift/tilt so the nub tracks the body's perspective.
                    float _nubEffTilt  = UI_VIEW_TILT + (_ViewValueTiltEnabled > 0.5
                        ? lerp(_ViewValueTiltMin, _ViewValueTiltMax, _Value) : 0.0);
                    float _nubViewShift = UI_VIEW_SHIFT + (_ViewValueShiftEnabled > 0.5
                        ? lerp(_ViewValueShiftMin, _ViewValueShiftMax, _Value) : 0.0);
                    float _nubTiltRad = (_ViewAngle + 90.0) * (PI / 180.0);
                    float2 _nubTiltDir     = float2(cos(_nubTiltRad), sin(_nubTiltRad));
                    float2 _nubTiltNormDir = float2(-_nubTiltDir.y, _nubTiltDir.x);
                    float _nubTiltNorm     = saturate(_nubEffTilt / 10.0);
                    float _nubTiltAngle    = _nubTiltNorm * (PI * 0.5);
                    float _nubCosT = cos(_nubTiltAngle);
                    float _nubSinT = sin(_nubTiltAngle);

                    // Face center height offset in screen space
                    float _nubBevelDist   = (_KnobBevelEnabled > 0.5) ? _KnobBevelDistance : 0.0;
                    float _nubBevelDepth  = (_KnobBevelEnabled > 0.5) ? abs(_KnobBevelDepth) : 0.0;
                    float _nubBevelH      = knubRadius * lerp(0.05, 1.0, _nubBevelDepth);
                    float _nubLipH        = knubRadius * _KnobLipHeight;
                    float _nubTotalH      = _nubLipH + _nubBevelH;

                    // Nub orbits on a circle in knob XZ at the face cap.
                    // In knob local 3D: nubPos3D = (cos(a)*d, totalH, sin(a)*d)
                    // Convert current pixel to face-plane XZ; this keeps nub aligned with
                    // the same shifted perspective camera used by the RM body.
                    float nubOrbitR = _KnobNubDistance * knubRadius;
                    float2 knobNubCircle = float2(cos(mathAngleKN), sin(mathAngleKN)) * nubOrbitR;
                    // Screen basis, IDENTICAL to renderRaymarchKnob's (screenAcross/screenAlong).
                    //
                    // These used to be negated "to match legacy nub orientation". They must not be:
                    // the projection below is the exact ray-plane intersection for the body's own
                    // camera — C = (shift, f·cosT, f·sinT) through K = (sa, sl·sinT, −sl·cosT), solved
                    // for the face cap y = totalHeight — and that derivation gives the denominator
                    // (f·cosT − sl·sinT). Feeding it −sl turns that into (f·cosT + sl·sinT), so the
                    // nub drifted off the face by an amount that grew with tilt and with FOV. The
                    // ortho branch below is likewise the exact solution for the un-negated basis.
                    float nubSA = dot(pos, _nubTiltNormDir);
                    float nubSL = dot(pos, _nubTiltDir);
                    float2 nubFacePos;
                    if (_ViewFOV > 0.001) {
                        // focalDist = 1/tan(halfFOV): 0.5→45°, 0.667→60°, 0.889→80°, 1→90°
                        float _nubFocalDist = 1.0 / max(0.0001, tan(_ViewFOV * (PI * 0.5)));
                        float _nubW = max(0.001, _nubFocalDist * _nubCosT - nubSL * _nubSinT);
                        nubFacePos = float2(
                            (nubSA * (_nubFocalDist * _nubCosT - _nubTotalH) + _nubViewShift * (_nubTotalH - nubSL * _nubSinT)) / _nubW,
                            (_nubTotalH * (nubSL * _nubCosT + _nubFocalDist * _nubSinT) - _nubFocalDist * nubSL) / _nubW
                        );
                    } else {
                        float nubCosSafe = max(0.001, _nubCosT);
                        nubFacePos = float2(nubSA, -nubSL / nubCosSafe + _nubTotalH * _nubSinT / nubCosSafe);
                    }

                    // nubFacePos.x/.y are coefficients along the (_nubTiltNormDir, _nubTiltDir)
                    // basis, not literal screen (x,y) — they must be reconstructed back into
                    // screen space before comparing against knobNubCircle (which IS in screen
                    // space, via cos/sin of mathAngleKN). Using them as a raw Cartesian pair
                    // implicitly rotates the pixel by -(ViewAngle + 180deg), which at the
                    // default ViewAngle=0 flips the nub to the antipodal point on the orbit
                    // (correct rotation with _Value, but 180 degrees off in base position).
                    float2 nubFacePosScreen = nubFacePos.x * _nubTiltNormDir - nubFacePos.y * _nubTiltDir;
                    float2 nubLocalFace = nubFacePosScreen - knobNubCircle;
                    float2 nubLocalPos = rotate2D(nubLocalFace, -mathAngleKN);
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

#endif // COMPILE_KNOBNUB

                // ============================================================
                // Final output
                // ============================================================
                #ifdef UNITY_UI_CLIP_RECT
                float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                finalColor *= clipMask;
                emissiveAccum *= clipMask;
                #endif

                finalColor *= IN.color;
                emissiveAccum *= IN.color.rgb;

                // Receive shadows cast by every OTHER widget and panel.
                //
                // This knob's own contribution is not in the buffer at its own pixels — the
                // shadow pass punched its silhouette out (see the punch-out in the
                // _ShadowPassMode block). So this is other people's shadows only, and the
                // shadow of the module rail above a knob finally lands ON the knob instead of
                // stopping at its edge.
                //
                // BEFORE the emissive add, deliberately: an emissive Value arc is its own
                // light source and is not shadowed by a neighbour standing next to it.
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
