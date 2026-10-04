// SDFPanelUniforms.cginc
// Shared uniform declarations for SDFPanel.shader and SDFPanelRM.shader.
// Include AFTER UnityCG.cginc, UnityUI.cginc, and core .cginc files.
//
// Components:
// 1. Panel      — Main panel shape (full material system)
// 2. Face       — Optional inner face shape for stacked/inset appearance
// 3. InnerFrame — Nested shape composited over the face (replaces Icon)
// 4. Edge       — Recessed indent around the panel quad
// 5. Border     — Cut-in border at canvas edge
// 6. Shadow     — 3 external cast shadows + 3 panel body shadows

#ifndef SDFPANEL_UNIFORMS_INCLUDED
#define SDFPANEL_UNIFORMS_INCLUDED

sampler2D _MainTex;

// ============================================================================
// Panel properties (main panel shape)
// ============================================================================
float  _PanelEnabled;
float4 _PanelColor;
float  _PanelRenderAlpha;
float  _PanelRenderEmissive;

// Panel shape
float  _PanelShapeType;
float  _PanelShapeParam1;
float  _PanelShapeParam2;
float  _PanelShapeParam3;
float  _PanelShapeRotation;
float  _PanelPadding;
// _PanelBodyRoundness / _PanelBodyShapeTexLayer / _PanelBodyShapeTexScale → SDFPanelShapes.cginc

// Panel bevel
float  _PanelBevelEnabled;
float  _PanelBevelDepth;
float  _PanelBevelSmoothness;
float  _PanelBevelDistance;
float  _PanelFaceSmoothness;
float  _PanelBevelProfileType;
float  _PanelBevelProfileSharpness;

// Panel bevel pattern
float  _PanelBevelPatternEnabled;
float  _PanelBevelPatternType;
float  _PanelBevelPatternScale;
float  _PanelBevelPatternIntensity;
float  _PanelBevelPatternContrast;
float  _PanelBevelPatternSpecularEffect;
float  _PanelBevelPatternRoughnessEffect;
float  _PanelBevelPatternParam1;
float  _PanelBevelPatternParam2;
float  _PanelBevelPatternParam3;

// Panel bevel pattern color
float  _PanelBevelPatternColorEnabled;
int    _PanelBevelPatternColorType;
int    _PanelBevelPatternColorMode;
int    _PanelBevelPatternColorUsed;
float4 _PanelBevelPatternColorA;
float4 _PanelBevelPatternColorB;
float4 _PanelBevelPatternColorC;
float4 _PanelBevelPatternColorD;

// Panel bevel gradient
float  _PanelBevelGradientEnabled;
int    _PanelBevelGradientType;
float4 _PanelBevelGradientColorA;
float4 _PanelBevelGradientColorB;
float4 _PanelBevelGradientColorC;
float4 _PanelBevelGradientColorD;
float2 _PanelBevelGradientDirection;
float  _PanelBevelGradientSpeed;
float  _PanelBevelGradientScale;
float  _PanelBevelGradientOffset;
int    _PanelBevelGradientColorUsed;

// Panel rim bevel
float  _PanelRimEnabled;
float  _PanelRimDepth;
float  _PanelRimWidth;
float  _PanelRimSmoothness;

// Panel pattern
float  _PanelPatternEnabled;
float  _PanelPatternType;
float  _PanelPatternScale;
float  _PanelPatternIntensity;
float  _PanelPatternContrast;
float  _PanelPatternSpecularEffect;
float  _PanelPatternRoughnessEffect;
float  _PanelPatternRotateEnabled;
float  _PanelPatternModEnabled;
float  _PanelPatternModAmount;
float  _PanelPatternModFrequency;
float  _PanelPatternOffset;
float  _PanelPatternParam1;
float  _PanelPatternParam2;
float  _PanelPatternParam3;

// Panel pattern color
float  _PanelPatternColorEnabled;
int    _PanelPatternColorType;
int    _PanelPatternColorMode;
int    _PanelPatternColorUsed;
float4 _PanelPatternColorA;
float4 _PanelPatternColorB;
float4 _PanelPatternColorC;
float4 _PanelPatternColorD;

// Panel gradient
float  _PanelGradientEnabled;
int    _PanelGradientType;
float4 _PanelGradientColorA;
float4 _PanelGradientColorB;
float4 _PanelGradientColorC;
float4 _PanelGradientColorD;
float2 _PanelGradientDirection;
float  _PanelGradientSpeed;
float  _PanelGradientScale;
float  _PanelGradientOffset;
float  _PanelGlobalBlend;
float  _PanelGlobalIntensity;
int    _PanelGradientColorUsed;

// ============================================================================
// Face shape properties (inner face region — grouped with Panel)
// ============================================================================
float  _PanelFaceEnabled;        // 0 = face not rendered (ring/outline mode)
float  _PanelFaceShapeEnabled;   // 1 = face uses its own SDF shape
float  _PanelFaceShapeType;
float  _PanelFaceShapeParam1;
float  _PanelFaceShapeParam2;
float  _PanelFaceShapeParam3;
float  _PanelFaceShapeRotation;
float  _PanelFaceSize;           // fraction of panel size (0.01-1)
float  _PanelFaceShapeTexLayer;
float2 _PanelFaceShapeTexScale;

// ============================================================================
// InnerFrame properties (nested SDF shape composited over the face)
// ============================================================================
float  _InnerFrameEnabled;
float4 _InnerFrameColor;
float  _InnerFrameRenderAlpha;
float  _InnerFrameRenderEmissive;

// InnerFrame shape
float  _InnerFrameShapeEnabled;  // 1 = use own SDF; 0 = inset from body by _InnerFrameSize
float  _InnerFrameShapeType;
float  _InnerFrameShapeParam1;
float  _InnerFrameShapeParam2;
float  _InnerFrameShapeParam3;
float  _InnerFrameShapeRotation;
float  _InnerFrameSize;          // fraction of panel half-extents; lower = larger gap to panel edge
float  _InnerFrameShapeTexLayer;
float2 _InnerFrameShapeTexScale;

// InnerFrame bevel
float  _InnerFrameBevelEnabled;
float  _InnerFrameBevelDepth;
float  _InnerFrameBevelSmoothness;
float  _InnerFrameBevelDistance;
float  _InnerFrameFaceSmoothness;
float  _InnerFrameBevelProfileType;
float  _InnerFrameBevelProfileSharpness;

// InnerFrame bevel pattern
float  _InnerFrameBevelPatternEnabled;
float  _InnerFrameBevelPatternType;
float  _InnerFrameBevelPatternScale;
float  _InnerFrameBevelPatternIntensity;
float  _InnerFrameBevelPatternContrast;
float  _InnerFrameBevelPatternSpecularEffect;
float  _InnerFrameBevelPatternRoughnessEffect;
float  _InnerFrameBevelPatternParam1;
float  _InnerFrameBevelPatternParam2;
float  _InnerFrameBevelPatternParam3;

// InnerFrame bevel pattern color
float  _InnerFrameBevelPatternColorEnabled;
int    _InnerFrameBevelPatternColorType;
int    _InnerFrameBevelPatternColorMode;
int    _InnerFrameBevelPatternColorUsed;
float4 _InnerFrameBevelPatternColorA;
float4 _InnerFrameBevelPatternColorB;
float4 _InnerFrameBevelPatternColorC;
float4 _InnerFrameBevelPatternColorD;

// InnerFrame bevel gradient
float  _InnerFrameBevelGradientEnabled;
int    _InnerFrameBevelGradientType;
float4 _InnerFrameBevelGradientColorA;
float4 _InnerFrameBevelGradientColorB;
float4 _InnerFrameBevelGradientColorC;
float4 _InnerFrameBevelGradientColorD;
float2 _InnerFrameBevelGradientDirection;
float  _InnerFrameBevelGradientSpeed;
float  _InnerFrameBevelGradientScale;
float  _InnerFrameBevelGradientOffset;
int    _InnerFrameBevelGradientColorUsed;

// InnerFrame rim
float  _InnerFrameRimEnabled;
float  _InnerFrameRimDepth;
float  _InnerFrameRimWidth;
float  _InnerFrameRimSmoothness;

// InnerFrame pattern
float  _InnerFramePatternEnabled;
float  _InnerFramePatternType;
float  _InnerFramePatternScale;
float  _InnerFramePatternIntensity;
float  _InnerFramePatternContrast;
float  _InnerFramePatternSpecularEffect;
float  _InnerFramePatternRoughnessEffect;
float  _InnerFramePatternRotateEnabled;
float  _InnerFramePatternModEnabled;
float  _InnerFramePatternModAmount;
float  _InnerFramePatternModFrequency;
float  _InnerFramePatternOffset;
float  _InnerFramePatternParam1;
float  _InnerFramePatternParam2;
float  _InnerFramePatternParam3;

// InnerFrame pattern color
float  _InnerFramePatternColorEnabled;
int    _InnerFramePatternColorType;
int    _InnerFramePatternColorMode;
int    _InnerFramePatternColorUsed;
float4 _InnerFramePatternColorA;
float4 _InnerFramePatternColorB;
float4 _InnerFramePatternColorC;
float4 _InnerFramePatternColorD;

// InnerFrame gradient
float  _InnerFrameGradientEnabled;
int    _InnerFrameGradientType;
float4 _InnerFrameGradientColorA;
float4 _InnerFrameGradientColorB;
float4 _InnerFrameGradientColorC;
float4 _InnerFrameGradientColorD;
float2 _InnerFrameGradientDirection;
float  _InnerFrameGradientSpeed;
float  _InnerFrameGradientScale;
float  _InnerFrameGradientOffset;
float  _InnerFrameGlobalBlend;
float  _InnerFrameGlobalIntensity;
int    _InnerFrameGradientColorUsed;

// ============================================================================
// Edge indent properties (recessed indent around panel)
// ============================================================================
float  _EdgeEnabled;
float4 _EdgeColor;
float  _EdgeRenderAlpha;
float  _EdgeRenderEmissive;
float  _EdgeWidth;
float  _EdgeSoftness;
float  _EdgeIntensity;
float  _EdgeInset;

float  _EdgeGradientEnabled;
int    _EdgeGradientType;
float4 _EdgeGradientColorA;
float4 _EdgeGradientColorB;
float4 _EdgeGradientColorC;
float4 _EdgeGradientColorD;
float2 _EdgeGradientDirection;
float  _EdgeGradientSpeed;
float  _EdgeGradientScale;
float  _EdgeGradientOffset;
float  _EdgeGlobalBlend;
float  _EdgeGlobalIntensity;
int    _EdgeGradientColorUsed;

// ============================================================================
// Border properties (cut-in border at canvas edge)
// ============================================================================
float  _BorderEnabled;
float4 _BorderColor;
float  _BorderRenderAlpha;
float  _BorderRenderEmissive;
float  _BorderWidth;
float  _BorderSoftness;
float  _BorderIntensity;

float  _BorderGradientEnabled;
int    _BorderGradientType;
float4 _BorderGradientColorA;
float4 _BorderGradientColorB;
float4 _BorderGradientColorC;
float4 _BorderGradientColorD;
float2 _BorderGradientDirection;
float  _BorderGradientSpeed;
float  _BorderGradientScale;
float  _BorderGradientOffset;
float  _BorderGlobalBlend;
float  _BorderGlobalIntensity;
int    _BorderGradientColorUsed;

// ============================================================================
// Shadow properties
// ============================================================================

// External shadows (behind panel on background)
float  _LightingShadow1Enabled;
float4 _LightingShadow1Color;
float  _LightingShadow1Blur;
float  _LightingShadow1Distance;
float  _LightingShadow1BlurFactor;
float  _LightingShadow1Intensity;

float  _LightingShadow2Enabled;
float4 _LightingShadow2Color;
float  _LightingShadow2Blur;
float  _LightingShadow2Distance;
float  _LightingShadow2BlurFactor;
float  _LightingShadow2Intensity;

float  _LightingShadow3Enabled;
float4 _LightingShadow3Color;
float  _LightingShadow3Blur;
float  _LightingShadow3Distance;
float  _LightingShadow3BlurFactor;
float  _LightingShadow3Intensity;

// Panel body shadows (cast by the 3D panel shape onto the background behind it)
float  _PanelShadow1Enabled;
float4 _PanelShadow1Color;
float  _PanelShadow1Blur;
float  _PanelShadow1Distance;
float  _PanelShadow1BlurFactor;
float  _PanelShadow1Intensity;
float  _PanelShadow1Cast;

float  _PanelShadow2Enabled;
float4 _PanelShadow2Color;
float  _PanelShadow2Blur;
float  _PanelShadow2Distance;
float  _PanelShadow2BlurFactor;
float  _PanelShadow2Intensity;
float  _PanelShadow2Cast;

float  _PanelShadow3Enabled;
float4 _PanelShadow3Color;
float  _PanelShadow3Blur;
float  _PanelShadow3Distance;
float  _PanelShadow3BlurFactor;
float  _PanelShadow3Intensity;
float  _PanelShadow3Cast;

// ============================================================================
// Lighting properties (3 directional lights)
// ============================================================================
float  _LightingAmbient;





float4 _Position;
float  _AspectRatio;

float3 _GlobalLightPos1;
float3 _GlobalLightPos2;
float3 _GlobalLightPos3;
float4 _GlobalLightColor1;
float4 _GlobalLightColor2;
float4 _GlobalLightColor3;
float4 _GlobalLightFx1;
float4 _GlobalLightFx2;
float4 _GlobalLightFx3;

float  _Value;

float  _Stencil;
float  _StencilComp;
float  _StencilOp;
float  _StencilReadMask;
float  _StencilWriteMask;
float  _ColorMask;
float4 _ClipRect;

#endif // SDFPANEL_UNIFORMS_INCLUDED
