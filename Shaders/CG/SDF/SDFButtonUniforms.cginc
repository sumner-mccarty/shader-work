// SDFButtonUniforms.cginc
// Shared uniform declarations for SDFButton and SDFButtonRM shaders.
// Include AFTER UnityCG.cginc, UnityUI.cginc, and core .cginc files.
//
// Components:
// 1. Button - Main button shape (full material system)
// 2. Face   - Optional inner face shape for stacked/inset appearance
// 3. Icon   - Optional indicator on button face (uses nub shapes)
// 4. Edge   - Recessed indent around button
// 5. Border - Cut-in border at canvas edge
// 6. Shadow - External shadows (3-light system)

#ifndef SDFBUTTON_UNIFORMS_INCLUDED
#define SDFBUTTON_UNIFORMS_INCLUDED

// Properties
sampler2D _MainTex;

// ============================================================================
// Button properties (main button shape)
// ============================================================================
float _ButtonEnabled;
float4 _ButtonColor;
float _ButtonRenderAlpha;
float _ButtonRenderEmissive;

// Button shape
float _ButtonShapeType;
float _ButtonShapeParam1;
float _ButtonShapeParam2;
float _ButtonShapeParam3;
float _ButtonShapeRotation;
float _ButtonPadding; // equi-pixel margin per side (0=edge-to-edge, higher=more inset)
// _ButtonShapeTexLayer / _ButtonShapeTexScale declared in SDFButtonShapes.cginc

// Button bevel
float _ButtonBevelEnabled;
float _ButtonBevelDepth;
float _ButtonBevelSmoothness;
float _ButtonBevelDistance;
float _ButtonFaceSmoothness;
float _ButtonBevelProfileType;
float _ButtonBevelProfileSharpness;

// Button bevel pattern
float _ButtonBevelPatternEnabled;
float _ButtonBevelPatternType;
float _ButtonBevelPatternScale;
float _ButtonBevelPatternIntensity;
float _ButtonBevelPatternContrast;
float _ButtonBevelPatternSpecularEffect;
float _ButtonBevelPatternRoughnessEffect;
float _ButtonBevelPatternParam1;
float _ButtonBevelPatternParam2;
float _ButtonBevelPatternParam3;

// Button bevel pattern color
float _ButtonBevelPatternColorEnabled;
int _ButtonBevelPatternColorType;
int _ButtonBevelPatternColorMode;
int _ButtonBevelPatternColorUsed;
float4 _ButtonBevelPatternColorA;
float4 _ButtonBevelPatternColorB;
float4 _ButtonBevelPatternColorC;
float4 _ButtonBevelPatternColorD;

// Button bevel gradient
float _ButtonBevelGradientEnabled;
int _ButtonBevelGradientType;
float4 _ButtonBevelGradientColorA;
float4 _ButtonBevelGradientColorB;
float4 _ButtonBevelGradientColorC;
float4 _ButtonBevelGradientColorD;
float2 _ButtonBevelGradientDirection;
float _ButtonBevelGradientSpeed;
float _ButtonBevelGradientScale;
float _ButtonBevelGradientOffset;
int _ButtonBevelGradientColorUsed;

// Button rim bevel
float _ButtonRimEnabled;
float _ButtonRimDepth;
float _ButtonRimWidth;
float _ButtonRimSmoothness;

// Button pattern
float _ButtonPatternEnabled;
float _ButtonPatternType;
float _ButtonPatternScale;
float _ButtonPatternIntensity;
float _ButtonPatternContrast;
float _ButtonPatternSpecularEffect;
float _ButtonPatternRoughnessEffect;
float _ButtonPatternRotateEnabled;
float _ButtonPatternModEnabled;
float _ButtonPatternModAmount;
float _ButtonPatternModFrequency;
float _ButtonPatternOffset;
float _ButtonPatternParam1;
float _ButtonPatternParam2;
float _ButtonPatternParam3;

// Button pattern color
float _ButtonPatternColorEnabled;
int _ButtonPatternColorType;
int _ButtonPatternColorMode;
int _ButtonPatternColorUsed;
float4 _ButtonPatternColorA;
float4 _ButtonPatternColorB;
float4 _ButtonPatternColorC;
float4 _ButtonPatternColorD;

// Button gradient
float _ButtonGradientEnabled;
int _ButtonGradientType;
float4 _ButtonGradientColorA;
float4 _ButtonGradientColorB;
float4 _ButtonGradientColorC;
float4 _ButtonGradientColorD;
float2 _ButtonGradientDirection;
float _ButtonGradientSpeed;
float _ButtonGradientScale;
float _ButtonGradientOffset;
float _ButtonGlobalBlend;
float _ButtonGlobalIntensity;
int _ButtonGradientColorUsed;

// ============================================================================
// Face shape properties (inner face region — grouped with Button)
// ============================================================================
float _ButtonFaceEnabled;       // 0 = face area not rendered (ring/outline mode)
float _ButtonFaceShapeEnabled;  // 1 = face uses its own SDF shape
float _ButtonFaceShapeType;
float _ButtonFaceShapeParam1;
float _ButtonFaceShapeParam2;
float _ButtonFaceShapeParam3;
float _ButtonFaceShapeRotation;
float _ButtonFaceSize;          // fraction of button size (0.01-1), lower = wider bevel wall
float _ButtonFaceShapeTexLayer; // Texture array layer (-1 = disabled)
float2 _ButtonFaceShapeTexScale; // UV scale for texture SDF

// ============================================================================
// Icon properties (indicator on button face — uses nub shapes)
// ============================================================================
float _IconEnabled;
float4 _IconColor;
float _IconRenderAlpha;
float _IconRenderEmissive;
float _IconShapeType;
float _IconWidth;
float _IconHeight;
float _IconShapeParam1;
float _IconShapeParam2;
float _IconShapeParam3;
float _IconShapeRotation;
float2 _IconOffset;  // offset from center
// _IconShapeTexLayer / _IconShapeTexScale declared in SDFButtonLayers.cginc

// Icon bevel
float _IconBevelEnabled;
float _IconBevelDepth;
float _IconBevelSmoothness;
float _IconBevelDistance;
float _IconFaceSmoothness;

// Icon pattern
float _IconPatternEnabled;
float _IconPatternType;
float _IconPatternScale;
float _IconPatternIntensity;
float _IconPatternContrast;
float _IconPatternSpecularEffect;
float _IconPatternRoughnessEffect;
float _IconPatternRotateEnabled;
float _IconPatternModEnabled;
float _IconPatternModAmount;
float _IconPatternModFrequency;
float _IconPatternOffset;
float _IconPatternParam1;
float _IconPatternParam2;
float _IconPatternParam3;

// Icon pattern color
float _IconPatternColorEnabled;
int _IconPatternColorType;
int _IconPatternColorMode;
int _IconPatternColorUsed;
float4 _IconPatternColorA;
float4 _IconPatternColorB;
float4 _IconPatternColorC;
float4 _IconPatternColorD;

// Icon gradient
float _IconGradientEnabled;
int _IconGradientType;
float4 _IconGradientColorA;
float4 _IconGradientColorB;
float4 _IconGradientColorC;
float4 _IconGradientColorD;
float2 _IconGradientDirection;
float _IconGradientSpeed;
float _IconGradientScale;
float _IconGradientOffset;
float _IconGlobalBlend;
float _IconGlobalIntensity;
int _IconGradientColorUsed;

// Icon rim bevel
float _IconRimEnabled;
float _IconRimDepth;
float _IconRimWidth;
float _IconRimSmoothness;

// ============================================================================
// Edge indent properties (recessed indent around button)
// ============================================================================
float _EdgeEnabled;
float4 _EdgeColor;
float _EdgeRenderAlpha;
float _EdgeRenderEmissive;
float _EdgeWidth;
float _EdgeSoftness;
float _EdgeIntensity;
float _EdgeInset;  // how far from button edge the indent starts

// Edge gradient
float _EdgeGradientEnabled;
int _EdgeGradientType;
float4 _EdgeGradientColorA;
float4 _EdgeGradientColorB;
float4 _EdgeGradientColorC;
float4 _EdgeGradientColorD;
float2 _EdgeGradientDirection;
float _EdgeGradientSpeed;
float _EdgeGradientScale;
float _EdgeGradientOffset;
float _EdgeGlobalBlend;
float _EdgeGlobalIntensity;
int _EdgeGradientColorUsed;

// ============================================================================
// Border properties (cut-in border at canvas edge)
// ============================================================================
float _BorderEnabled;
float4 _BorderColor;
float _BorderRenderAlpha;
float _BorderRenderEmissive;
float _BorderWidth;
float _BorderSoftness;
float _BorderIntensity;

// Border gradient
float _BorderGradientEnabled;
int _BorderGradientType;
float4 _BorderGradientColorA;
float4 _BorderGradientColorB;
float4 _BorderGradientColorC;
float4 _BorderGradientColorD;
float2 _BorderGradientDirection;
float _BorderGradientSpeed;
float _BorderGradientScale;
float _BorderGradientOffset;
float _BorderGlobalBlend;
float _BorderGlobalIntensity;
int _BorderGradientColorUsed;

// ============================================================================
// Shadow properties (3 light-driven shadows)
// ============================================================================

// External shadows (behind button on background)
float _LightingShadow1Enabled;
float4 _LightingShadow1Color;
float _LightingShadow1Blur;
float _LightingShadow1Distance;
float _LightingShadow1BlurFactor;
float _LightingShadow1Intensity;

float _LightingShadow2Enabled;
float4 _LightingShadow2Color;
float _LightingShadow2Blur;
float _LightingShadow2Distance;
float _LightingShadow2BlurFactor;
float _LightingShadow2Intensity;

float _LightingShadow3Enabled;
float4 _LightingShadow3Color;
float _LightingShadow3Blur;
float _LightingShadow3Distance;
float _LightingShadow3BlurFactor;
float _LightingShadow3Intensity;

// Button shadows (cast by the 3D button shape)
float _ButtonShadow1Enabled;
float4 _ButtonShadow1Color;
float _ButtonShadow1Blur;
float _ButtonShadow1Distance;
float _ButtonShadow1BlurFactor;
float _ButtonShadow1Intensity;
float _ButtonShadow1Cast;

float _ButtonShadow2Enabled;
float4 _ButtonShadow2Color;
float _ButtonShadow2Blur;
float _ButtonShadow2Distance;
float _ButtonShadow2BlurFactor;
float _ButtonShadow2Intensity;
float _ButtonShadow2Cast;

float _ButtonShadow3Enabled;
float4 _ButtonShadow3Color;
float _ButtonShadow3Blur;
float _ButtonShadow3Distance;
float _ButtonShadow3BlurFactor;
float _ButtonShadow3Intensity;
float _ButtonShadow3Cast;

// ============================================================================
// Lighting properties (3 directional lights)
// ============================================================================
float _LightingAmbient;




// Per-material toggles: when > 0.5, derive direction from global light position

// UI position of this element (set per-material by UI system)
float4 _Position;

// Aspect ratio override for preview tools that render to a square RT.
// 0 = auto-detect from UV screen-space derivatives (default for UGUI/UIElements).
// >0 = forced W/H ratio (e.g. 2.0 = twice as wide as tall).
float _AspectRatio;

// Global light positions (set via Shader.SetGlobalVector by GlobalLightManager)
float3 _GlobalLightPos1;
float3 _GlobalLightPos2;
float3 _GlobalLightPos3;
float4 _GlobalLightColor1;
float4 _GlobalLightColor2;
float4 _GlobalLightColor3;
float4 _GlobalLightFx1;
float4 _GlobalLightFx2;
float4 _GlobalLightFx3;

// ============================================================================
// Button state
// ============================================================================
float _Value;  // 0-1 pressed state (drives visual depression)

// Stencil (standard Unity UI)
float _Stencil;
float _StencilComp;
float _StencilOp;
float _StencilReadMask;
float _StencilWriteMask;
float _ColorMask;
float4 _ClipRect;

#endif // SDFBUTTON_UNIFORMS_INCLUDED
