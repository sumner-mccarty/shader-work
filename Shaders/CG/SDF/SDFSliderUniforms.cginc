// SDFSliderUniforms.cginc
// Shared uniform declarations for SDFSlider.shader and SDFSliderRM.shader.
// Include AFTER UnityCG.cginc, UnityUI.cginc, and core .cginc files.
//
// Components:
// 1. Background     — Overall slider background panel (full material system; reuses getPanelBodySDF)
// 2. Track          — Groove/slot channel running the slider length (full material system)
//    2a. ValueFilled   — Filled portion of track from fill origin to handle position
//    2b. ValueUnfilled — Unfilled portion of track from handle to max
// 3. Handle         — Draggable thumb (full material system with bevel, rim, pattern, gradient)
// 4. HandleFace     — Optional inner face shape on the handle
// 5. ScaleMarks     — Optional tick marks along the slider axis
// 6. Edge           — Recessed indent around the slider quad
// 7. Border         — Cut-in border at canvas edge
// 8. Shadow         — 3 external cast shadows + 3 handle body shadows
// 9. Lighting       — 3 directional lights (shared by handle 3D material)

#ifndef SDFSLIDER_UNIFORMS_INCLUDED
#define SDFSLIDER_UNIFORMS_INCLUDED

sampler2D _MainTex;

// ============================================================================
// Global slider state
// ============================================================================
float  _Value;        // normalised value [0,1] — handle position
float  _TrackValueZeroPoint;  // fill origin: 0 = fill from start, 0.5 = fill from centre

// ============================================================================
// Background properties
// ============================================================================
// Note: shape dispatch uses getPanelBodySDF which reads _PanelBodyRoundness,
// _PanelBodyShapeTexLayer, and _PanelBodyShapeTexScale (declared in SDFPanelShapes.cginc).

float  _BgEnabled;
float4 _BgColor;
float  _BgRenderAlpha;
float  _BgRenderEmissive;

// Background shape
float  _BgShapeType;    // PanelBodyShapeType
float  _BgShapeParam1;
float  _BgShapeParam2;
float  _BgShapeParam3;
float  _BgShapeRotation;
float  _BgPadding;      // equi-pixel margin from the quad edge

// Background bevel
float  _BgBevelEnabled;
float  _BgBevelDepth;
float  _BgBevelSmoothness;
float  _BgBevelDistance;
float  _BgFaceSmoothness;
float  _BgBevelProfileType;
float  _BgBevelProfileSharpness;

// Background bevel pattern
float  _BgBevelPatternEnabled;
float  _BgBevelPatternType;
float  _BgBevelPatternScale;
float  _BgBevelPatternIntensity;
float  _BgBevelPatternContrast;
float  _BgBevelPatternSpecularEffect;
float  _BgBevelPatternRoughnessEffect;
float  _BgBevelPatternParam1;
float  _BgBevelPatternParam2;
float  _BgBevelPatternParam3;

// Background bevel pattern color
float  _BgBevelPatternColorEnabled;
int    _BgBevelPatternColorType;
int    _BgBevelPatternColorMode;
int    _BgBevelPatternColorUsed;
float4 _BgBevelPatternColorA;
float4 _BgBevelPatternColorB;
float4 _BgBevelPatternColorC;
float4 _BgBevelPatternColorD;

// Background bevel gradient
float  _BgBevelGradientEnabled;
int    _BgBevelGradientType;
float4 _BgBevelGradientColorA;
float4 _BgBevelGradientColorB;
float4 _BgBevelGradientColorC;
float4 _BgBevelGradientColorD;
float2 _BgBevelGradientDirection;
float  _BgBevelGradientSpeed;
float  _BgBevelGradientScale;
float  _BgBevelGradientOffset;
int    _BgBevelGradientColorUsed;

// Background rim
float  _BgRimEnabled;
float  _BgRimDepth;
float  _BgRimWidth;
float  _BgRimSmoothness;

// Background pattern
float  _BgPatternEnabled;
float  _BgPatternType;
float  _BgPatternScale;
float  _BgPatternIntensity;
float  _BgPatternContrast;
float  _BgPatternSpecularEffect;
float  _BgPatternRoughnessEffect;
float  _BgPatternRotateEnabled;
float  _BgPatternModEnabled;
float  _BgPatternModAmount;
float  _BgPatternModFrequency;
float  _BgPatternOffset;
float  _BgPatternParam1;
float  _BgPatternParam2;
float  _BgPatternParam3;

// Background pattern color
float  _BgPatternColorEnabled;
int    _BgPatternColorType;
int    _BgPatternColorMode;
int    _BgPatternColorUsed;
float4 _BgPatternColorA;
float4 _BgPatternColorB;
float4 _BgPatternColorC;
float4 _BgPatternColorD;

// Background gradient
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
// Track properties (groove / slot channel)
// ============================================================================
float  _TrackEnabled;
float4 _TrackColor;
float  _TrackRenderAlpha;
float  _TrackRenderEmissive;

float  _TrackWidth;         // half-width perpendicular to slider axis (equi-pixel)
float  _TrackCornerRadius;  // corner rounding fraction [0,1]
float  _TrackExtension;     // extra track half-length beyond handle travel end-points [0,0.5]
float  _TrackValuePadding;  // insets fill/unfilled/negFilled regions inside the track [0,0.5]

// Track bevel
float  _TrackBevelEnabled;
float  _TrackBevelDepth;
float  _TrackBevelSmoothness;
float  _TrackBevelDistance;
float  _TrackFaceSmoothness;

// Track pattern
float  _TrackPatternEnabled;
float  _TrackPatternType;
float  _TrackPatternScale;
float  _TrackPatternIntensity;
float  _TrackPatternContrast;
float  _TrackPatternParam1;
float  _TrackPatternParam2;
float  _TrackPatternParam3;

// Track gradient
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
// ValueFilled properties (filled track segment, origin → handle)
// ============================================================================
float  _TrackValueFilledEnabled;
float4 _TrackValueFilledColor;
float  _TrackValueFilledRenderAlpha;
float  _TrackValueFilledRenderEmissive;

float  _TrackValueFilledPatternEnabled;
float  _TrackValueFilledPatternType;
float  _TrackValueFilledPatternScale;
float  _TrackValueFilledPatternIntensity;
float  _TrackValueFilledPatternContrast;
float  _TrackValueFilledPatternParam1;
float  _TrackValueFilledPatternParam2;
float  _TrackValueFilledPatternParam3;

float  _TrackValueFilledGradientEnabled;
int    _TrackValueFilledGradientType;
float4 _TrackValueFilledGradientColorA;
float4 _TrackValueFilledGradientColorB;
float4 _TrackValueFilledGradientColorC;
float4 _TrackValueFilledGradientColorD;
float2 _TrackValueFilledGradientDirection;
float  _TrackValueFilledGradientSpeed;
float  _TrackValueFilledGradientScale;
float  _TrackValueFilledGradientOffset;
float  _TrackValueFilledGlobalBlend;
float  _TrackValueFilledGlobalIntensity;
int    _TrackValueFilledGradientColorUsed;

// ============================================================================
// ValueUnfilled properties (unfilled track segment, handle → max)
// ============================================================================
float  _TrackValueUnfilledEnabled;
float4 _TrackValueUnfilledColor;
float  _TrackValueUnfilledRenderAlpha;
float  _TrackValueUnfilledRenderEmissive;

float  _TrackValueUnfilledPatternEnabled;
float  _TrackValueUnfilledPatternType;
float  _TrackValueUnfilledPatternScale;
float  _TrackValueUnfilledPatternIntensity;
float  _TrackValueUnfilledPatternContrast;
float  _TrackValueUnfilledPatternParam1;
float  _TrackValueUnfilledPatternParam2;
float  _TrackValueUnfilledPatternParam3;

float  _TrackValueUnfilledGradientEnabled;
int    _TrackValueUnfilledGradientType;
float4 _TrackValueUnfilledGradientColorA;
float4 _TrackValueUnfilledGradientColorB;
float4 _TrackValueUnfilledGradientColorC;
float4 _TrackValueUnfilledGradientColorD;
float2 _TrackValueUnfilledGradientDirection;
float  _TrackValueUnfilledGradientSpeed;
float  _TrackValueUnfilledGradientScale;
float  _TrackValueUnfilledGradientOffset;
float  _TrackValueUnfilledGlobalBlend;
float  _TrackValueUnfilledGlobalIntensity;
int    _TrackValueUnfilledGradientColorUsed;

// ============================================================================
// ValueNegative properties (negative fill: handle → fill-origin when value < zero point)
// ============================================================================
float  _TrackValueNegativeEnabled;
float4 _TrackValueNegativeColor;
float  _TrackValueNegativeRenderAlpha;
float  _TrackValueNegativeRenderEmissive;

float  _TrackValueNegativePatternEnabled;
float  _TrackValueNegativePatternType;
float  _TrackValueNegativePatternScale;
float  _TrackValueNegativePatternIntensity;
float  _TrackValueNegativePatternContrast;
float  _TrackValueNegativePatternParam1;
float  _TrackValueNegativePatternParam2;
float  _TrackValueNegativePatternParam3;

float  _TrackValueNegativeGradientEnabled;
int    _TrackValueNegativeGradientType;
float4 _TrackValueNegativeGradientColorA;
float4 _TrackValueNegativeGradientColorB;
float4 _TrackValueNegativeGradientColorC;
float4 _TrackValueNegativeGradientColorD;
float2 _TrackValueNegativeGradientDirection;
float  _TrackValueNegativeGradientSpeed;
float  _TrackValueNegativeGradientScale;
float  _TrackValueNegativeGradientOffset;
float  _TrackValueNegativeGlobalBlend;
float  _TrackValueNegativeGlobalIntensity;
int    _TrackValueNegativeGradientColorUsed;

// ============================================================================
// Handle properties (draggable thumb — full material system)
// ============================================================================
float  _HandleEnabled;
float4 _HandleColor;
float  _HandleRenderAlpha;
float  _HandleRenderEmissive;

// Handle shape
float  _HandleShapeType;    // SliderHandleShapeType
float  _HandleWidth;        // half-width in equi-pixel space (also the axis half-extent used for travel clamping)
float  _HandleHeight;       // half-height in equi-pixel space
float  _HandlePadding;      // extra margin beyond half-width that keeps handle inside quad boundary
float  _HandleShapeParam1;
float  _HandleShapeParam2;
float  _HandleShapeParam3;
float  _HandleShapeRotation;
// _HandleRoundness / _HandleShapeTexLayer / _HandleShapeTexScale → SDFSliderHandleShapes.cginc

// Handle bevel
float  _HandleBevelEnabled;
float  _HandleBevelDepth;
float  _HandleBevelSmoothness;
float  _HandleBevelDistance;
float  _HandleFaceSmoothness;
float  _HandleBevelProfileType;
float  _HandleBevelProfileSharpness;

// Handle bevel pattern
float  _HandleBevelPatternEnabled;
float  _HandleBevelPatternType;
float  _HandleBevelPatternScale;
float  _HandleBevelPatternIntensity;
float  _HandleBevelPatternContrast;
float  _HandleBevelPatternSpecularEffect;
float  _HandleBevelPatternRoughnessEffect;
float  _HandleBevelPatternParam1;
float  _HandleBevelPatternParam2;
float  _HandleBevelPatternParam3;

// Handle bevel pattern color
float  _HandleBevelPatternColorEnabled;
int    _HandleBevelPatternColorType;
int    _HandleBevelPatternColorMode;
int    _HandleBevelPatternColorUsed;
float4 _HandleBevelPatternColorA;
float4 _HandleBevelPatternColorB;
float4 _HandleBevelPatternColorC;
float4 _HandleBevelPatternColorD;

// Handle bevel gradient
float  _HandleBevelGradientEnabled;
int    _HandleBevelGradientType;
float4 _HandleBevelGradientColorA;
float4 _HandleBevelGradientColorB;
float4 _HandleBevelGradientColorC;
float4 _HandleBevelGradientColorD;
float2 _HandleBevelGradientDirection;
float  _HandleBevelGradientSpeed;
float  _HandleBevelGradientScale;
float  _HandleBevelGradientOffset;
int    _HandleBevelGradientColorUsed;

// Handle rim bevel
float  _HandleRimEnabled;
float  _HandleRimDepth;
float  _HandleRimWidth;
float  _HandleRimSmoothness;

// Handle pattern
float  _HandlePatternEnabled;
float  _HandlePatternType;
float  _HandlePatternScale;
float  _HandlePatternIntensity;
float  _HandlePatternContrast;
float  _HandlePatternSpecularEffect;
float  _HandlePatternRoughnessEffect;
float  _HandlePatternRotateEnabled;
float  _HandlePatternModEnabled;
float  _HandlePatternModAmount;
float  _HandlePatternModFrequency;
float  _HandlePatternOffset;
float  _HandlePatternParam1;
float  _HandlePatternParam2;
float  _HandlePatternParam3;

// Handle pattern color
float  _HandlePatternColorEnabled;
int    _HandlePatternColorType;
int    _HandlePatternColorMode;
int    _HandlePatternColorUsed;
float4 _HandlePatternColorA;
float4 _HandlePatternColorB;
float4 _HandlePatternColorC;
float4 _HandlePatternColorD;

// Handle gradient
float  _HandleGradientEnabled;
int    _HandleGradientType;
float4 _HandleGradientColorA;
float4 _HandleGradientColorB;
float4 _HandleGradientColorC;
float4 _HandleGradientColorD;
float2 _HandleGradientDirection;
float  _HandleGradientSpeed;
float  _HandleGradientScale;
float  _HandleGradientOffset;
float  _HandleGlobalBlend;
float  _HandleGlobalIntensity;
int    _HandleGradientColorUsed;

// ============================================================================
// HandleFace properties (optional inner face shape on the handle)
// ============================================================================
float  _HandleFaceEnabled;
float  _HandleFaceShapeEnabled;
float  _HandleFaceShapeType;
float  _HandleFaceShapeParam1;
float  _HandleFaceShapeParam2;
float  _HandleFaceShapeParam3;
float  _HandleFaceShapeRotation;
float  _HandleFaceSize;

float4 _HandleFaceColor;
float  _HandleFaceRenderAlpha;
float  _HandleFaceRenderEmissive;

float  _HandleFacePatternEnabled;
float  _HandleFacePatternType;
float  _HandleFacePatternScale;
float  _HandleFacePatternIntensity;
float  _HandleFacePatternContrast;
float  _HandleFacePatternParam1;
float  _HandleFacePatternParam2;
float  _HandleFacePatternParam3;

float  _HandleFaceGradientEnabled;
int    _HandleFaceGradientType;
float4 _HandleFaceGradientColorA;
float4 _HandleFaceGradientColorB;
float4 _HandleFaceGradientColorC;
float4 _HandleFaceGradientColorD;
float2 _HandleFaceGradientDirection;
float  _HandleFaceGradientScale;
float  _HandleFaceGradientOffset;
float  _HandleFaceGlobalBlend;
float  _HandleFaceGlobalIntensity;
int    _HandleFaceGradientColorUsed;

// ============================================================================
// ScaleMark properties (tick marks along the slider axis)
// ============================================================================
float  _ScaleMarkEnabled;
float4 _ScaleMarkColor;
float  _ScaleMarkRenderAlpha;
float  _ScaleMarkRenderEmissive;
float  _ScaleMarkCount;         // number of tick marks (including end marks)
float  _ScaleMarkWidth;         // half-width of each tick (equi-pixel)
float  _ScaleMarkLength;        // half-length of each tick perpendicular to axis (equi-pixel)
float  _ScaleMarkOffset;        // distance from track centre perpendicular to axis (equi-pixel)
float  _ScaleMarkSoftness;      // AA softness

float  _ScaleMarkGradientEnabled;
int    _ScaleMarkGradientType;
float4 _ScaleMarkGradientColorA;
float4 _ScaleMarkGradientColorB;
float2 _ScaleMarkGradientDirection;
float  _ScaleMarkGradientScale;
float  _ScaleMarkGradientOffset;

// ============================================================================
// Edge indent properties
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
// Border properties
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

// External shadows (behind slider on background)
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

// Handle body shadows (cast by the 3D handle shape)
float  _HandleShadow1Enabled;
float4 _HandleShadow1Color;
float  _HandleShadow1Blur;
float  _HandleShadow1Distance;
float  _HandleShadow1BlurFactor;
float  _HandleShadow1Intensity;
float  _HandleShadow1Cast;

float  _HandleShadow2Enabled;
float4 _HandleShadow2Color;
float  _HandleShadow2Blur;
float  _HandleShadow2Distance;
float  _HandleShadow2BlurFactor;
float  _HandleShadow2Intensity;
float  _HandleShadow2Cast;

float  _HandleShadow3Enabled;
float4 _HandleShadow3Color;
float  _HandleShadow3Blur;
float  _HandleShadow3Distance;
float  _HandleShadow3BlurFactor;
float  _HandleShadow3Intensity;
float  _HandleShadow3Cast;

// ============================================================================
// Lighting properties (3 directional lights — applied to handle material)
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

float  _Stencil;
float  _StencilComp;
float  _StencilOp;
float  _StencilReadMask;
float  _StencilWriteMask;
float  _ColorMask;
float4 _ClipRect;

#endif // SDFSLIDER_UNIFORMS_INCLUDED
