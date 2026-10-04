// SDFKnobUniforms.cginc
// Shared uniform declarations for SDFKnob and SDFKnobRM shaders.
// Include AFTER UnityCG.cginc, UnityUI.cginc, and core .cginc files.

#ifndef SDFKNOB_UNIFORMS_INCLUDED
#define SDFKNOB_UNIFORMS_INCLUDED

// Properties
sampler2D _MainTex;

// Fill properties
float _FillEnabled;
float4 _FillColor;
float _FillRenderAlpha;
float _FillRenderEmissive;
float _FillBevelEnabled;
float _FillBevelDepth;
float _FillBevelSmoothness;
float _FillBevelDistance;
float _FillFaceSmoothness;

// Fill bevel pattern properties
float _FillBevelPatternEnabled;
float _FillBevelPatternType;
float _FillBevelPatternScale;
float _FillBevelPatternIntensity;
float _FillBevelPatternContrast;
float _FillBevelPatternSpecularEffect;
float _FillBevelPatternRoughnessEffect;
float _FillBevelPatternParam1;
float _FillBevelPatternParam2;
float _FillBevelPatternParam3;

// Fill bevel pattern color properties
float _FillBevelPatternColorEnabled;
int _FillBevelPatternColorType;
int _FillBevelPatternColorMode;
int _FillBevelPatternColorUsed;
float4 _FillBevelPatternColorA;
float4 _FillBevelPatternColorB;
float4 _FillBevelPatternColorC;
float4 _FillBevelPatternColorD;

// Fill bevel gradient properties
float _FillBevelGradientEnabled;
int _FillBevelGradientType;
float4 _FillBevelGradientColorA;
float4 _FillBevelGradientColorB;
float4 _FillBevelGradientColorC;
float4 _FillBevelGradientColorD;
float2 _FillBevelGradientDirection;
float _FillBevelGradientSpeed;
float _FillBevelGradientScale;
float _FillBevelGradientOffset;
int _FillBevelGradientColorUsed;

float _FillRimEnabled;
float _FillRimDepth;
float _FillRimWidth;
float _FillRimSmoothness;

// Fill pattern properties
float _FillPatternEnabled;
float _FillPatternType;
float _FillPatternScale;
float _FillPatternIntensity;
float _FillPatternContrast;
float _FillPatternSpecularEffect;
float _FillPatternRoughnessEffect;
float _FillPatternRotateEnabled;
float _FillPatternModEnabled;
float _FillPatternModAmount;
float _FillPatternModFrequency;
float _FillPatternOffset;
float _FillPatternParam1;
float _FillPatternParam2;
float _FillPatternParam3;

// Fill pattern color properties
float _FillPatternColorEnabled;
int _FillPatternColorType;
int _FillPatternColorMode;
int _FillPatternColorUsed;
float4 _FillPatternColorA;
float4 _FillPatternColorB;
float4 _FillPatternColorC;
float4 _FillPatternColorD;

// Fill gradient properties
float _FillGradientEnabled;
int _FillGradientType;
float4 _FillGradientColorA;
float4 _FillGradientColorB;
float4 _FillGradientColorC;
float4 _FillGradientColorD;
float2 _FillGradientDirection;
float _FillGradientSpeed;
float _FillGradientScale;
float _FillGradientOffset;
float _FillGlobalBlend;
float _FillGlobalIntensity;
int _FillGradientColorUsed;

// Line properties
float _LineEnabled;
float4 _LineColor;
float _LineRenderAlpha;
float _LineRenderEmissive;
float _LineBevelEnabled;
float _LineBevelDepth;
float _LineBevelSmoothness;
float _LineBevelDistance;
float _LineFaceSmoothness;

// Line bevel pattern properties
float _LineBevelPatternEnabled;
float _LineBevelPatternType;
float _LineBevelPatternScale;
float _LineBevelPatternIntensity;
float _LineBevelPatternContrast;
float _LineBevelPatternSpecularEffect;
float _LineBevelPatternRoughnessEffect;
float _LineBevelPatternParam1;
float _LineBevelPatternParam2;
float _LineBevelPatternParam3;

// Line bevel pattern color properties
float _LineBevelPatternColorEnabled;
int _LineBevelPatternColorType;
int _LineBevelPatternColorMode;
int _LineBevelPatternColorUsed;
float4 _LineBevelPatternColorA;
float4 _LineBevelPatternColorB;
float4 _LineBevelPatternColorC;
float4 _LineBevelPatternColorD;

// Line bevel gradient properties
float _LineBevelGradientEnabled;
int _LineBevelGradientType;
float4 _LineBevelGradientColorA;
float4 _LineBevelGradientColorB;
float4 _LineBevelGradientColorC;
float4 _LineBevelGradientColorD;
float2 _LineBevelGradientDirection;
float _LineBevelGradientSpeed;
float _LineBevelGradientScale;
float _LineBevelGradientOffset;
int _LineBevelGradientColorUsed;

float _LineRimEnabled;
float _LineRimDepth;
float _LineRimWidth;
float _LineRimSmoothness;

// Line pattern properties
float _LinePatternEnabled;
float _LinePatternType;
float _LinePatternScale;
float _LinePatternIntensity;
float _LinePatternContrast;
float _LinePatternSpecularEffect;
float _LinePatternRoughnessEffect;
float _LinePatternRotateEnabled;
float _LinePatternModEnabled;
float _LinePatternModAmount;
float _LinePatternModFrequency;
float _LinePatternOffset;
float _LinePatternParam1;
float _LinePatternParam2;
float _LinePatternParam3;

// Line pattern color properties
float _LinePatternColorEnabled;
int _LinePatternColorType;
int _LinePatternColorMode;
int _LinePatternColorUsed;
float4 _LinePatternColorA;
float4 _LinePatternColorB;
float4 _LinePatternColorC;
float4 _LinePatternColorD;

// Line gradient properties
float _LineGradientEnabled;
int _LineGradientType;
float4 _LineGradientColorA;
float4 _LineGradientColorB;
float4 _LineGradientColorC;
float4 _LineGradientColorD;
float2 _LineGradientDirection;
float _LineGradientSpeed;
float _LineGradientScale;
float _LineGradientOffset;
float _LineGlobalBlend;
float _LineGlobalIntensity;
int _LineGradientColorUsed;

// Value component properties
float _LineSublineFilledEnabled;
float4 _LineSublineFilledColor;
float _LineSublineFilledRenderAlpha;
float _LineSublineFilledRenderEmissive;
float _LineSublineFilledBevelEnabled;
float _LineSublineFilledBevelDepth;
float _LineSublineFilledBevelSmoothness;
float _LineSublineFilledBevelDistance;
float _LineSublineFilledFaceSmoothness;

// Value filled bevel pattern properties
float _LineSublineFilledBevelPatternEnabled;
float _LineSublineFilledBevelPatternType;
float _LineSublineFilledBevelPatternScale;
float _LineSublineFilledBevelPatternIntensity;
float _LineSublineFilledBevelPatternContrast;
float _LineSublineFilledBevelPatternSpecularEffect;
float _LineSublineFilledBevelPatternRoughnessEffect;
float _LineSublineFilledBevelPatternParam1;
float _LineSublineFilledBevelPatternParam2;
float _LineSublineFilledBevelPatternParam3;

// Line subline filled bevel pattern color properties
float _LineSublineFilledBevelPatternColorEnabled;
int _LineSublineFilledBevelPatternColorType;
int _LineSublineFilledBevelPatternColorMode;
int _LineSublineFilledBevelPatternColorUsed;
float4 _LineSublineFilledBevelPatternColorA;
float4 _LineSublineFilledBevelPatternColorB;
float4 _LineSublineFilledBevelPatternColorC;
float4 _LineSublineFilledBevelPatternColorD;

// Value filled bevel gradient properties
float _LineSublineFilledBevelGradientEnabled;
int _LineSublineFilledBevelGradientType;
float4 _LineSublineFilledBevelGradientColorA;
float4 _LineSublineFilledBevelGradientColorB;
float4 _LineSublineFilledBevelGradientColorC;
float4 _LineSublineFilledBevelGradientColorD;
float2 _LineSublineFilledBevelGradientDirection;
float _LineSublineFilledBevelGradientSpeed;
float _LineSublineFilledBevelGradientScale;
float _LineSublineFilledBevelGradientOffset;
int _LineSublineFilledBevelGradientColorUsed;

float _LineSublineFilledRimEnabled;
float _LineSublineFilledRimDepth;
float _LineSublineFilledRimWidth;
float _LineSublineFilledRimSmoothness;

// Value filled pattern properties
float _LineSublineFilledPatternEnabled;
float _LineSublineFilledPatternType;
float _LineSublineFilledPatternScale;
float _LineSublineFilledPatternIntensity;
float _LineSublineFilledPatternContrast;
float _LineSublineFilledPatternSpecularEffect;
float _LineSublineFilledPatternRoughnessEffect;
float _LineSublineFilledPatternRotateEnabled;
float _LineSublineFilledPatternModEnabled;
float _LineSublineFilledPatternModAmount;
float _LineSublineFilledPatternModFrequency;
float _LineSublineFilledPatternOffset;
float _LineSublineFilledPatternParam1;
float _LineSublineFilledPatternParam2;
float _LineSublineFilledPatternParam3;

// Line subline filled pattern color properties
float _LineSublineFilledPatternColorEnabled;
int _LineSublineFilledPatternColorType;
int _LineSublineFilledPatternColorMode;
int _LineSublineFilledPatternColorUsed;
float4 _LineSublineFilledPatternColorA;
float4 _LineSublineFilledPatternColorB;
float4 _LineSublineFilledPatternColorC;
float4 _LineSublineFilledPatternColorD;

// Value filled gradient properties
// Value filled gradient properties
float _LineSublineFilledGradientEnabled;
int _LineSublineFilledGradientType;
float4 _LineSublineFilledGradientColorA;
float4 _LineSublineFilledGradientColorB;
float4 _LineSublineFilledGradientColorC;
float4 _LineSublineFilledGradientColorD;
float2 _LineSublineFilledGradientDirection;
float _LineSublineFilledGradientSpeed;
float _LineSublineFilledGradientScale;
float _LineSublineFilledGradientOffset;
float _LineSublineFilledGlobalBlend;
float _LineSublineFilledGlobalIntensity;
int _LineSublineFilledGradientColorUsed;

float _LineSublineUnfilledEnabled;
float4 _LineSublineUnfilledColor;
float _LineSublineUnfilledRenderAlpha;
float _LineSublineUnfilledRenderEmissive;
float _LineSublineUnfilledBevelEnabled;
float _LineSublineUnfilledBevelDepth;
float _LineSublineUnfilledBevelSmoothness;
float _LineSublineUnfilledBevelDistance;
float _LineSublineUnfilledFaceSmoothness;

// Value unfilled bevel pattern properties
float _LineSublineUnfilledBevelPatternEnabled;
float _LineSublineUnfilledBevelPatternType;
float _LineSublineUnfilledBevelPatternScale;
float _LineSublineUnfilledBevelPatternIntensity;
float _LineSublineUnfilledBevelPatternContrast;
float _LineSublineUnfilledBevelPatternSpecularEffect;
float _LineSublineUnfilledBevelPatternRoughnessEffect;
float _LineSublineUnfilledBevelPatternParam1;
float _LineSublineUnfilledBevelPatternParam2;
float _LineSublineUnfilledBevelPatternParam3;

// Line subline unfilled bevel pattern color properties
float _LineSublineUnfilledBevelPatternColorEnabled;
int _LineSublineUnfilledBevelPatternColorType;
int _LineSublineUnfilledBevelPatternColorMode;
int _LineSublineUnfilledBevelPatternColorUsed;
float4 _LineSublineUnfilledBevelPatternColorA;
float4 _LineSublineUnfilledBevelPatternColorB;
float4 _LineSublineUnfilledBevelPatternColorC;
float4 _LineSublineUnfilledBevelPatternColorD;

// Value unfilled bevel gradient properties
float _LineSublineUnfilledBevelGradientEnabled;
int _LineSublineUnfilledBevelGradientType;
float4 _LineSublineUnfilledBevelGradientColorA;
float4 _LineSublineUnfilledBevelGradientColorB;
float4 _LineSublineUnfilledBevelGradientColorC;
float4 _LineSublineUnfilledBevelGradientColorD;
float2 _LineSublineUnfilledBevelGradientDirection;
float _LineSublineUnfilledBevelGradientSpeed;
float _LineSublineUnfilledBevelGradientScale;
float _LineSublineUnfilledBevelGradientOffset;
int _LineSublineUnfilledBevelGradientColorUsed;

float _LineSublineUnfilledRimEnabled;
float _LineSublineUnfilledRimDepth;
float _LineSublineUnfilledRimWidth;
float _LineSublineUnfilledRimSmoothness;

// Value unfilled pattern properties
float _LineSublineUnfilledPatternEnabled;
float _LineSublineUnfilledPatternType;
float _LineSublineUnfilledPatternScale;
float _LineSublineUnfilledPatternIntensity;
float _LineSublineUnfilledPatternContrast;
float _LineSublineUnfilledPatternSpecularEffect;
float _LineSublineUnfilledPatternRoughnessEffect;
float _LineSublineUnfilledPatternRotateEnabled;
float _LineSublineUnfilledPatternModEnabled;
float _LineSublineUnfilledPatternModAmount;
float _LineSublineUnfilledPatternModFrequency;
float _LineSublineUnfilledPatternOffset;
float _LineSublineUnfilledPatternParam1;
float _LineSublineUnfilledPatternParam2;
float _LineSublineUnfilledPatternParam3;

// Line subline unfilled pattern color properties
float _LineSublineUnfilledPatternColorEnabled;
int _LineSublineUnfilledPatternColorType;
int _LineSublineUnfilledPatternColorMode;
int _LineSublineUnfilledPatternColorUsed;
float4 _LineSublineUnfilledPatternColorA;
float4 _LineSublineUnfilledPatternColorB;
float4 _LineSublineUnfilledPatternColorC;
float4 _LineSublineUnfilledPatternColorD;

// Value unfilled gradient properties
// Value unfilled gradient properties
float _LineSublineUnfilledGradientEnabled;
int _LineSublineUnfilledGradientType;
float4 _LineSublineUnfilledGradientColorA;
float4 _LineSublineUnfilledGradientColorB;
float4 _LineSublineUnfilledGradientColorC;
float4 _LineSublineUnfilledGradientColorD;
float2 _LineSublineUnfilledGradientDirection;
float _LineSublineUnfilledGradientSpeed;
float _LineSublineUnfilledGradientScale;
float _LineSublineUnfilledGradientOffset;
float _LineSublineUnfilledGlobalBlend;
float _LineSublineUnfilledGlobalIntensity;
int _LineSublineUnfilledGradientColorUsed;

float _LineSublineThickness;

// Knob properties
float _KnobEnabled;
float4 _KnobColor;
float _KnobRenderAlpha;
float _KnobRenderEmissive;
float _KnobSize;
float _KnobShapeType;
float _KnobShapeScale;
float _KnobShapeRotation;
float _KnobShapeParam1;
float _KnobShapeParam2;
float _KnobShapeParam3;
float _KnobShapeParam4;
float _KnobShapeParam5;
float _KnobShapeParam6;
// _KnobShapeTexLayer / _KnobShapeTexScale declared in SDFKnobShapes.cginc
// _KnobRoundness is declared in SDFKnobShapes.cginc (shared with SDFKnobRM)
float _KnobRotation;
// Knob face shape uniforms
float _KnobFaceShapeEnabled;
float _KnobFaceShapeType;
float _KnobFaceShapeScale;
float _KnobFaceShapeSize;
float _KnobFaceShapeRotation;
float _KnobFaceShapeParam1;
float _KnobFaceShapeParam2;
float _KnobFaceShapeParam3;
float _KnobFaceShapeParam4;
float _KnobFaceShapeParam5;
float _KnobFaceShapeParam6;
float _KnobFaceShapeTexLayer;   // Texture array layer (-1 = disabled)
float2 _KnobFaceShapeTexScale;  // UV scale for texture SDF
float _KnobBevelEnabled;
float _KnobBevelDepth;
float _KnobBevelSmoothness;
float _KnobBevelDistance;
float _KnobFaceSmoothness;
int   _KnobBevelProfileType;
float _KnobBevelProfileSharpness;

// Knob bevel pattern properties
float _KnobBevelPatternEnabled;
float _KnobBevelPatternType;
float _KnobBevelPatternScale;
float _KnobBevelPatternIntensity;
float _KnobBevelPatternContrast;
float _KnobBevelPatternSpecularEffect;
float _KnobBevelPatternRoughnessEffect;
float _KnobBevelPatternParam1;
float _KnobBevelPatternParam2;
float _KnobBevelPatternParam3;

// Knob bevel pattern color properties
float _KnobBevelPatternColorEnabled;
int _KnobBevelPatternColorType;
int _KnobBevelPatternColorMode;
int _KnobBevelPatternColorUsed;
float4 _KnobBevelPatternColorA;
float4 _KnobBevelPatternColorB;
float4 _KnobBevelPatternColorC;
float4 _KnobBevelPatternColorD;

// Knob bevel gradient properties
float _KnobBevelGradientEnabled;
int _KnobBevelGradientType;
float4 _KnobBevelGradientColorA;
float4 _KnobBevelGradientColorB;
float4 _KnobBevelGradientColorC;
float4 _KnobBevelGradientColorD;
float2 _KnobBevelGradientDirection;
float _KnobBevelGradientSpeed;
float _KnobBevelGradientScale;
float _KnobBevelGradientOffset;
int _KnobBevelGradientColorUsed;

float _KnobRimEnabled;
float _KnobRimDepth;
float _KnobRimWidth;
float _KnobRimSmoothness;

// Knob pattern properties
float _KnobPatternEnabled;
float _KnobPatternType;
float _KnobPatternScale;
float _KnobPatternIntensity;
float _KnobPatternContrast;
float _KnobPatternSpecularEffect;
float _KnobPatternRoughnessEffect;
float _KnobPatternRotateEnabled;
float _KnobPatternModEnabled;
float _KnobPatternModAmount;
float _KnobPatternModFrequency;
float _KnobPatternOffset;
float _KnobPatternParam1;
float _KnobPatternParam2;
float _KnobPatternParam3;

// Knob pattern color properties
float _KnobPatternColorEnabled;
int _KnobPatternColorType;
int _KnobPatternColorMode;
int _KnobPatternColorUsed;
float4 _KnobPatternColorA;
float4 _KnobPatternColorB;
float4 _KnobPatternColorC;
float4 _KnobPatternColorD;

// Knob gradient properties
float _KnobGradientEnabled;
int _KnobGradientType;
float4 _KnobGradientColorA;
float4 _KnobGradientColorB;
float4 _KnobGradientColorC;
float4 _KnobGradientColorD;
float2 _KnobGradientDirection;
float _KnobGradientSpeed;
float _KnobGradientScale;
float _KnobGradientOffset;
float _KnobGlobalBlend;
float _KnobGlobalIntensity;
int _KnobGradientColorUsed;

// KnobNub properties (face-center nub, tilt-aware orbit)
float _KnobNubEnabled;
float4 _KnobNubColor;
float _KnobNubRenderAlpha;
float _KnobNubSize;
float _KnobNubDistance;
float _KnobNubShapeType;
float _KnobNubShapeScale;
float _KnobNubShapeRotation;
float _KnobNubShapeParam1;
float _KnobNubShapeParam2;
float _KnobNubShapeParam3;
float _KnobNubBevelEnabled;
float _KnobNubBevelDepth;
float _KnobNubBevelSmoothness;
float _KnobNubBevelDistance;
float _KnobNubFaceSmoothness;

// Nub properties
float _NubEnabled;
float4 _NubColor;
float _NubRenderAlpha;
float _NubRenderEmissive;
float _NubDistance;
float _NubRotation;
float _NubShapeType;
float _NubSizeWidth;
float _NubSizeHeight;
float _NubRounding;
float _NubShapeParam1;
float _NubShapeParam2;
float _NubShapeParam3;
float _NubShapeRotation;
float _NubBevelEnabled;
float _NubBevelDepth;
float _NubBevelSmoothness;
float _NubBevelDistance;
float _NubFaceSmoothness;

// Nub bevel pattern properties
float _NubBevelPatternEnabled;
float _NubBevelPatternType;
float _NubBevelPatternScale;
float _NubBevelPatternIntensity;
float _NubBevelPatternContrast;
float _NubBevelPatternSpecularEffect;
float _NubBevelPatternRoughnessEffect;
float _NubBevelPatternParam1;
float _NubBevelPatternParam2;
float _NubBevelPatternParam3;

// Nub bevel pattern color properties
float _NubBevelPatternColorEnabled;
int _NubBevelPatternColorType;
int _NubBevelPatternColorMode;
int _NubBevelPatternColorUsed;
float4 _NubBevelPatternColorA;
float4 _NubBevelPatternColorB;
float4 _NubBevelPatternColorC;
float4 _NubBevelPatternColorD;

// Nub bevel gradient properties
float _NubBevelGradientEnabled;
int _NubBevelGradientType;
float4 _NubBevelGradientColorA;
float4 _NubBevelGradientColorB;
float4 _NubBevelGradientColorC;
float4 _NubBevelGradientColorD;
float2 _NubBevelGradientDirection;
float _NubBevelGradientSpeed;
float _NubBevelGradientScale;
float _NubBevelGradientOffset;
int _NubBevelGradientColorUsed;

float _NubRimEnabled;
float _NubRimDepth;
float _NubRimWidth;
float _NubRimSmoothness;

float _NubPatternType;
float _NubPatternScale;
float _NubPatternIntensity;
float _NubPatternContrast;
float _NubPatternSpecularEffect;
float _NubPatternRoughnessEffect;
float _NubPatternRotateEnabled;
float _NubPatternModEnabled;
float _NubPatternModAmount;
float _NubPatternModFrequency;
float _NubPatternOffset;
float _NubPatternParam1;
float _NubPatternParam2;
float _NubPatternParam3;
float _NubPatternEnabled;

// Nub pattern color properties
float _NubPatternColorEnabled;
int _NubPatternColorType;
int _NubPatternColorMode;
int _NubPatternColorUsed;
float4 _NubPatternColorA;
float4 _NubPatternColorB;
float4 _NubPatternColorC;
float4 _NubPatternColorD;

// Nub gradient properties
float _NubGradientEnabled;
int _NubGradientType;
float4 _NubGradientColorA;
float4 _NubGradientColorB;
float4 _NubGradientColorC;
float4 _NubGradientColorD;
float2 _NubGradientDirection;
float _NubGradientSpeed;
float _NubGradientScale;
float _NubGradientOffset;
float _NubGlobalBlend;
float _NubGlobalIntensity;
int _NubGradientColorUsed;

// Nub edge indent properties
float _NubEdgeEnabled;
float4 _NubEdgeColor;
float _NubEdgeRenderAlpha;
float _NubEdgeWidth;
float _NubEdgeSoftness;
float _NubEdgeIntensity;
float _NubEdgeRenderEmissive;

// Nub edge gradient properties
float _NubEdgeGradientEnabled;
int _NubEdgeGradientType;
float4 _NubEdgeGradientColorA;
float4 _NubEdgeGradientColorB;
float4 _NubEdgeGradientColorC;
float4 _NubEdgeGradientColorD;
float2 _NubEdgeGradientDirection;
float _NubEdgeGradientSpeed;
float _NubEdgeGradientScale;
float _NubEdgeGradientOffset;
float _NubEdgeGlobalBlend;
float _NubEdgeGlobalIntensity;
int _NubEdgeGradientColorUsed;

// Shadow properties (3 shadows driven by light positions)
float _LightingShadow1Enabled;
float4 _LightingShadow1Color;
float _LightingShadow1Blur;
float _LightingShadow1Intensity;
float _LightingShadow1Distance;

float _LightingShadow2Enabled;
float4 _LightingShadow2Color;
float _LightingShadow2Blur;
float _LightingShadow2Intensity;
float _LightingShadow2Distance;

float _LightingShadow3Enabled;
float4 _LightingShadow3Color;
float _LightingShadow3Blur;
float _LightingShadow3Intensity;
float _LightingShadow3Distance;

// Shadow blur factors
float _LightingShadow1BlurFactor;
float _LightingShadow2BlurFactor;
float _LightingShadow3BlurFactor;

// Knob shadow properties
float _KnobShadow1Enabled;
float4 _KnobShadow1Color;
float _KnobShadow1Blur;
float _KnobShadow1Intensity;
float _KnobShadow1Distance;

float _KnobShadow2Enabled;
float4 _KnobShadow2Color;
float _KnobShadow2Blur;
float _KnobShadow2Intensity;
float _KnobShadow2Distance;

float _KnobShadow3Enabled;
float4 _KnobShadow3Color;
float _KnobShadow3Blur;
float _KnobShadow3Intensity;
float _KnobShadow3Distance;

// Knob shadow blur factors
float _KnobShadow1BlurFactor;
float _KnobShadow2BlurFactor;
float _KnobShadow3BlurFactor;

// Knob shadow cast multiplier (scales face shape projection distance)
float _KnobShadow1Cast;
float _KnobShadow2Cast;
float _KnobShadow3Cast;

// KnobEdge indent properties
float _KnobEdgeEnabled;
float4 _KnobEdgeColor;
float _KnobEdgeRenderAlpha;
float _KnobEdgeWidth;
float _KnobEdgeInset;
float _KnobEdgeSoftness;
float _KnobEdgeIntensity;
float _KnobEdgeRenderEmissive;

float _KnobEdgeGradientEnabled;
int _KnobEdgeGradientType;
float4 _KnobEdgeGradientColorA;
float4 _KnobEdgeGradientColorB;
float4 _KnobEdgeGradientColorC;
float4 _KnobEdgeGradientColorD;
float2 _KnobEdgeGradientDirection;
float _KnobEdgeGradientSpeed;
float _KnobEdgeGradientScale;
float _KnobEdgeGradientOffset;
float _KnobEdgeGlobalBlend;
float _KnobEdgeGlobalIntensity;
int _KnobEdgeGradientColorUsed;

// Edge indent properties
float _EdgeEnabled;
float4 _EdgeColor;
float _EdgeRenderAlpha;
float _EdgeWidth;
float _EdgeInset;  // moves the ring band's inner boundary — see UIRingMask
float _EdgeSoftness;
float _EdgeIntensity;
float _EdgeRenderEmissive;

// Edge gradient properties
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

// Scale mark properties
float _OuterMarksEnabled;
float _OuterMarksType;
float _OuterMarksCount;
float _OuterMarksAngleStart;
float _OuterMarksAngleRange;
float4 _OuterMarksColorFilled;
float4 _OuterMarksColorUnfilled;
float _OuterMarksRadius;
float _OuterMarksLength;
float _OuterMarksThickness;
float _OuterMarksRounding;
float _OuterMarksRenderAlpha;
float _OuterMarksRenderEmissive;
float _OuterMarksMajorEnabled;
float _OuterMarksMajorInterval;
float _OuterMarksMajorLengthMultiplier;
float _OuterMarksMajorThicknessMultiplier;
float4 _OuterMarksMajorColorFilled;
float4 _OuterMarksMajorColorUnfilled;
float _OuterMarksArcGapSize;
float _OuterMarksArcThickness;

// Outer ring properties
float _OuterRing1Enabled;
float _OuterRing1Radius;
float _OuterRing1Thickness;
float4 _OuterRing1Color;
float _OuterRing1AngleStart;
float _OuterRing1AngleRange;
float _OuterRing1Style;
float _OuterRing1RenderAlpha;
float _OuterRing1RenderEmissive;

float _OuterRing2Enabled;
float _OuterRing2Radius;
float _OuterRing2Thickness;
float4 _OuterRing2Color;
float _OuterRing2AngleStart;
float _OuterRing2AngleRange;
float _OuterRing2Style;
float _OuterRing2RenderAlpha;
float _OuterRing2RenderEmissive;

float _OuterRing3Enabled;
float _OuterRing3Radius;
float _OuterRing3Thickness;
float4 _OuterRing3Color;
float _OuterRing3AngleStart;
float _OuterRing3AngleRange;
float _OuterRing3Style;
float _OuterRing3RenderAlpha;
float _OuterRing3RenderEmissive;

// Glow properties
float _LineSublineGlowEnabled;
float4 _LineSublineGlowColor;
float _LineSublineGlowWidth;
float _LineSublineGlowSoftness;
float _LineSublineGlowIntensity;
float _LineSublineGlowRenderAlpha;
float _LineSublineGlowRenderEmissive;

// Border properties
float _BorderEnabled;
float4 _BorderColor;
float _BorderRenderAlpha;
float _BorderWidth;
float _BorderSoftness;
float _BorderIntensity;
float _BorderRenderEmissive;

// Border gradient properties
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

// Geometry
float _LineRadius;
float _LineWidth;
float _AngleStart;
float _AngleRange;
float _Value;
float _LineRoundedEnabled;

// Lights
// ============================================================================
// LIGHTING ARCHITECTURE - Pure Function Pattern
// ============================================================================
// UILighting.cginc provides pure functions that accept all parameters explicitly.
// No properties are declared in the .cginc files (except global uniforms).
//
// REQUIRED: Declare _LightingAmbient here and pass to ApplyUILighting():
//   ApplyUILighting(normal, color, _LightingAmbient, specularMod, ...)
//
// This pattern ensures .cginc files remain reusable across all SDF shaders
// (SDFButton, SDFSlider, SDFToggle, SDFPanel) without hidden dependencies.
// ============================================================================
float _LightingAmbient; // Ambient light intensity (0-1)




// Per-material toggles: when > 0.5, derive direction from global light position

// UI position of this element (set per-material by UI system)
float4 _Position;

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

// Unity UI properties
float4 _ClipRect;

#endif // SDFKNOB_UNIFORMS_INCLUDED
