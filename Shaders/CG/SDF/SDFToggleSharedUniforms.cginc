// SDFToggleSharedUniforms.cginc
// Shared uniform declarations for all per-type SDFToggle shaders (SDFTogglePill, etc.).
// Each per-type shader includes this, then its own shapes cginc (which provides
// getToggleBodySDF / getToggleTrackSDF and sets SDF_TOGGLE_SHAPES_INCLUDED),
// then SDFToggleLayers.cginc, then SDFToggleRenderCore.cginc.
//
// _ToggleParam1-6 are NOT declared here — per-type shapes cgincs use named
// uniforms directly with no generic slot mapping needed.

#ifndef SDFTOGGLE_SHARED_UNIFORMS_INCLUDED
#define SDFTOGGLE_SHARED_UNIFORMS_INCLUDED

#define SDFTOGGLE_UNIFORMS_INCLUDED

sampler2D _MainTex;

// ============================================================================
// 1. Core state
// ============================================================================
float _Value;
int   _StateCount;
float _AnimT;
int   _ToggleType;   // set per-material by per-type shader ([HideInInspector])
// _ToggleParam1-6 are NOT declared here — per-type Defs files provide them

// ============================================================================
// 2. Background (Bg)
// ============================================================================
float  _BgEnabled;
float4 _BgColor;
float  _BgRenderAlpha;
float  _BgRenderEmissive;
float  _BgPadding;
float  _BgRounding;

float _BgBevelEnabled;
float _BgBevelDepth;
float _BgBevelSmoothness;
float _BgBevelDistance;
float _BgFaceSmoothness;
float _BgBevelProfileType;
float _BgBevelProfileSharpness;

float _BgBevelPatternEnabled;
float _BgBevelPatternType;
float _BgBevelPatternScale;
float _BgBevelPatternIntensity;
float _BgBevelPatternContrast;
float _BgBevelPatternSpecularEffect;
float _BgBevelPatternRoughnessEffect;
float _BgBevelPatternParam1;
float _BgBevelPatternParam2;
float _BgBevelPatternParam3;

float _BgBevelPatternColorEnabled;
int   _BgBevelPatternColorType;
int   _BgBevelPatternColorMode;
int   _BgBevelPatternColorUsed;
float4 _BgBevelPatternColorA;
float4 _BgBevelPatternColorB;
float4 _BgBevelPatternColorC;
float4 _BgBevelPatternColorD;

float _BgBevelGradientEnabled;
int   _BgBevelGradientType;
float4 _BgBevelGradientColorA;
float4 _BgBevelGradientColorB;
float4 _BgBevelGradientColorC;
float4 _BgBevelGradientColorD;
float2 _BgBevelGradientDirection;
float  _BgBevelGradientSpeed;
float  _BgBevelGradientScale;
float  _BgBevelGradientOffset;
int    _BgBevelGradientColorUsed;

float _BgRimEnabled;
float _BgRimDepth;
float _BgRimWidth;
float _BgRimSmoothness;

float _BgPatternEnabled;
float _BgPatternType;
float _BgPatternScale;
float _BgPatternIntensity;
float _BgPatternContrast;
float _BgPatternSpecularEffect;
float _BgPatternRoughnessEffect;
float _BgPatternRotateEnabled;
float _BgPatternModEnabled;
float _BgPatternModAmount;
float _BgPatternModFrequency;
float _BgPatternOffset;
float _BgPatternParam1;
float _BgPatternParam2;
float _BgPatternParam3;

float _BgPatternColorEnabled;
int   _BgPatternColorType;
int   _BgPatternColorMode;
int   _BgPatternColorUsed;
float4 _BgPatternColorA;
float4 _BgPatternColorB;
float4 _BgPatternColorC;
float4 _BgPatternColorD;

float  _BgGradientEnabled;
int    _BgGradientType;
float4 _BgGradientColorA;
float4 _BgGradientColorB;
float4 _BgGradientColorC;
float4 _BgGradientColorD;
float2 _BgGradientDirection;
float  _BgGradientSpeed;
float  _BgGradientScale;
float  _BgGradientOffset;
float  _BgGlobalBlend;
float  _BgGlobalIntensity;
int    _BgGradientColorUsed;

// ============================================================================
// 3. Track
// ============================================================================
float  _TrackEnabled;
float4 _TrackColor;
float  _TrackRenderAlpha;
float  _TrackRenderEmissive;

float _TrackBevelEnabled;
float _TrackBevelDepth;
float _TrackBevelSmoothness;
float _TrackBevelDistance;
float _TrackFaceSmoothness;
float _TrackBevelProfileType;
float _TrackBevelProfileSharpness;

float _TrackPatternEnabled;
float _TrackPatternType;
float _TrackPatternScale;
float _TrackPatternIntensity;
float _TrackPatternContrast;
float _TrackPatternSpecularEffect;
float _TrackPatternRoughnessEffect;
float _TrackPatternParam1;
float _TrackPatternParam2;
float _TrackPatternParam3;

float _TrackPatternColorEnabled;
int   _TrackPatternColorType;
int   _TrackPatternColorMode;
int   _TrackPatternColorUsed;
float4 _TrackPatternColorA;
float4 _TrackPatternColorB;
float4 _TrackPatternColorC;
float4 _TrackPatternColorD;

float  _TrackGradientEnabled;
int    _TrackGradientType;
float4 _TrackGradientColorA;
float4 _TrackGradientColorB;
float4 _TrackGradientColorC;
float4 _TrackGradientColorD;
float2 _TrackGradientDirection;
float  _TrackGradientSpeed;
float  _TrackGradientScale;
float  _TrackGradientOffset;
float  _TrackGlobalBlend;
float  _TrackGlobalIntensity;
int    _TrackGradientColorUsed;

// ============================================================================
// 4. Toggle Body
// ============================================================================
float  _ToggleEnabled;
float4 _ToggleColor;
float  _ToggleRenderAlpha;
float  _ToggleRenderEmissive;
float  _TogglePadding;

float _ToggleBevelEnabled;
float _ToggleBevelDepth;
float _ToggleBevelSmoothness;
float _ToggleBevelDistance;
float _ToggleFaceSmoothness;
float _ToggleBevelProfileType;
float _ToggleBevelProfileSharpness;

float _ToggleBevelPatternEnabled;
float _ToggleBevelPatternType;
float _ToggleBevelPatternScale;
float _ToggleBevelPatternIntensity;
float _ToggleBevelPatternContrast;
float _ToggleBevelPatternSpecularEffect;
float _ToggleBevelPatternRoughnessEffect;
float _ToggleBevelPatternParam1;
float _ToggleBevelPatternParam2;
float _ToggleBevelPatternParam3;

float _ToggleBevelPatternColorEnabled;
int   _ToggleBevelPatternColorType;
int   _ToggleBevelPatternColorMode;
int   _ToggleBevelPatternColorUsed;
float4 _ToggleBevelPatternColorA;
float4 _ToggleBevelPatternColorB;
float4 _ToggleBevelPatternColorC;
float4 _ToggleBevelPatternColorD;

float _ToggleBevelGradientEnabled;
int   _ToggleBevelGradientType;
float4 _ToggleBevelGradientColorA;
float4 _ToggleBevelGradientColorB;
float4 _ToggleBevelGradientColorC;
float4 _ToggleBevelGradientColorD;
float2 _ToggleBevelGradientDirection;
float  _ToggleBevelGradientSpeed;
float  _ToggleBevelGradientScale;
float  _ToggleBevelGradientOffset;
int    _ToggleBevelGradientColorUsed;

float _ToggleRimEnabled;
float _ToggleRimDepth;
float _ToggleRimWidth;
float _ToggleRimSmoothness;

float _TogglePatternEnabled;
float _TogglePatternType;
float _TogglePatternScale;
float _TogglePatternIntensity;
float _TogglePatternContrast;
float _TogglePatternSpecularEffect;
float _TogglePatternRoughnessEffect;
float _TogglePatternRotateEnabled;
float _TogglePatternModEnabled;
float _TogglePatternModAmount;
float _TogglePatternModFrequency;
float _TogglePatternOffset;
float _TogglePatternParam1;
float _TogglePatternParam2;
float _TogglePatternParam3;

float _TogglePatternColorEnabled;
int   _TogglePatternColorType;
int   _TogglePatternColorMode;
int   _TogglePatternColorUsed;
float4 _TogglePatternColorA;
float4 _TogglePatternColorB;
float4 _TogglePatternColorC;
float4 _TogglePatternColorD;

float  _ToggleGradientEnabled;
int    _ToggleGradientType;
float4 _ToggleGradientColorA;
float4 _ToggleGradientColorB;
float4 _ToggleGradientColorC;
float4 _ToggleGradientColorD;
float2 _ToggleGradientDirection;
float  _ToggleGradientSpeed;
float  _ToggleGradientScale;
float  _ToggleGradientOffset;
float  _ToggleGlobalBlend;
float  _ToggleGlobalIntensity;
int    _ToggleGradientColorUsed;

// ============================================================================
// 5. Toggle Face
// ============================================================================
float  _ToggleFaceEnabled;
float4 _ToggleFaceColor;
float  _ToggleFaceRenderAlpha;
float  _ToggleFaceRenderEmissive;
float  _ToggleFaceSize;

float  _ToggleFaceGradientEnabled;
int    _ToggleFaceGradientType;
float4 _ToggleFaceGradientColorA;
float4 _ToggleFaceGradientColorB;
float4 _ToggleFaceGradientColorC;
float4 _ToggleFaceGradientColorD;
float2 _ToggleFaceGradientDirection;
float  _ToggleFaceGradientSpeed;
float  _ToggleFaceGradientScale;
float  _ToggleFaceGradientOffset;
int    _ToggleFaceGradientColorUsed;

// ============================================================================
// 6. LED
// ============================================================================
float  _LedEnabled;
float4 _LedColor;
float  _LedIntensity;
float  _LedGlowRadius;
float  _LedGlowSharpness;
float  _LedSurfaceBlend;
float  _LedRenderEmissive;

// ============================================================================
// 7. Edge indent
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
// 8. Border
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
// 9. Shadows
// ============================================================================
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

float  _ToggleShadow1Enabled;
float4 _ToggleShadow1Color;
float  _ToggleShadow1Blur;
float  _ToggleShadow1Distance;
float  _ToggleShadow1BlurFactor;
float  _ToggleShadow1Intensity;
float  _ToggleShadow1Cast;

float  _ToggleShadow2Enabled;
float4 _ToggleShadow2Color;
float  _ToggleShadow2Blur;
float  _ToggleShadow2Distance;
float  _ToggleShadow2BlurFactor;
float  _ToggleShadow2Intensity;
float  _ToggleShadow2Cast;

float  _ToggleShadow3Enabled;
float4 _ToggleShadow3Color;
float  _ToggleShadow3Blur;
float  _ToggleShadow3Distance;
float  _ToggleShadow3BlurFactor;
float  _ToggleShadow3Intensity;
float  _ToggleShadow3Cast;

// ============================================================================
// 10. Lighting
// ============================================================================
float _LightingAmbient;





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

float _Stencil;
float _StencilComp;
float _StencilOp;
float _StencilReadMask;
float _StencilWriteMask;
float _ColorMask;
float4 _ClipRect;

// Receive shadows cast by other widgets/panels through the shared buffer.
//
// Toggles have always read that buffer unconditionally, which meant AppShell's
// "an overlay must not show the shadows of whatever is behind it" pass could not reach
// them: it writes _ReceiveSceneShadows, and only SDFPanel had the property. A toggle in a
// settings card therefore kept showing shadows cast by the panel underneath the card.
float _ReceiveSceneShadows;

#endif // SDFTOGGLE_SHARED_UNIFORMS_INCLUDED
