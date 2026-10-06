// SDFTogglePillDefs.cginc
// Named uniforms for the Pill / iOS-style slide toggle.
//
// Architecture:
//   1. Declare Track geometry shape params (_TrackHeight, _TrackCornerRadius, _TrackInsetDepth)
//   2. Declare Handle (ball) geometry shape params (_HandlePadding, _HandleFlatten)
//   3. Map named params onto _ToggleParam1-5 slots consumed by SDFPillShapes.cginc
//   4. Declare full Handle material uniforms (_Handle*)
//   5. Declare full Handle Face material uniforms (_HandleFace*)
//   6. Bridge macros: _Toggle* → _Handle*, _ToggleFace* → _HandleFace*
//      (SDFToggleRenderCore.cginc uses _Toggle* names; macros redirect them here)
//
// Include AFTER SDFToggleSharedUniforms.cginc, BEFORE SDFPillShapes.cginc.

#ifndef SDFTOGGLE_PILL_DEFS_INCLUDED
#define SDFTOGGLE_PILL_DEFS_INCLUDED

// ============================================================================
// Track geometry shape params
// ============================================================================
float _TrackHeight;        // fraction of widget height for the groove
float _TrackCornerRadius;  // 0=rect, 1=full-pill round
float _TrackInsetDepth;    // visual depth of track inset (drives bevel depth)

// ============================================================================
// Handle geometry shape params
// ============================================================================
float _HandlePadding;  // gap between ball edge and track inner wall
float _HandleFlatten;  // ball squash: 0=sphere, 1=flat disc

// Map onto _ToggleParam slots consumed by SDFPillShapes.cginc
#define _ToggleParam1 _TrackHeight
#define _ToggleParam2 _HandlePadding
#define _ToggleParam3 _TrackCornerRadius
#define _ToggleParam4 _HandleFlatten
#define _ToggleParam5 _TrackInsetDepth
#define _ToggleParam6 0.0

// ============================================================================
// Handle material uniforms  (these are the per-type semantic names that the
// .shader file exposes; bridge macros below redirect _Toggle* to these)
// ============================================================================
float  _HandleEnabled;
float4 _HandleColor;
float  _HandleRenderAlpha;
float  _HandleRenderEmissive;

float _HandleBevelEnabled;
float _HandleBevelDepth;
float _HandleBevelSmoothness;
float _HandleBevelDistance;
float _HandleFaceSmoothness;
float _HandleBevelProfileType;
float _HandleBevelProfileSharpness;

float _HandleBevelPatternEnabled;
float _HandleBevelPatternType;
float _HandleBevelPatternScale;
float _HandleBevelPatternIntensity;
float _HandleBevelPatternContrast;
float _HandleBevelPatternSpecularEffect;
float _HandleBevelPatternRoughnessEffect;
float _HandleBevelPatternParam1;
float _HandleBevelPatternParam2;
float _HandleBevelPatternParam3;

float  _HandleBevelPatternColorEnabled;
int    _HandleBevelPatternColorType;
int    _HandleBevelPatternColorMode;
int    _HandleBevelPatternColorUsed;
float4 _HandleBevelPatternColorA;
float4 _HandleBevelPatternColorB;
float4 _HandleBevelPatternColorC;
float4 _HandleBevelPatternColorD;

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

float _HandleRimEnabled;
float _HandleRimDepth;
float _HandleRimWidth;
float _HandleRimSmoothness;

float _HandlePatternEnabled;
float _HandlePatternType;
float _HandlePatternScale;
float _HandlePatternIntensity;
float _HandlePatternContrast;
float _HandlePatternSpecularEffect;
float _HandlePatternRoughnessEffect;
float _HandlePatternRotateEnabled;
float _HandlePatternModEnabled;
float _HandlePatternModAmount;
float _HandlePatternModFrequency;
float _HandlePatternOffset;
float _HandlePatternParam1;
float _HandlePatternParam2;
float _HandlePatternParam3;

float  _HandlePatternColorEnabled;
int    _HandlePatternColorType;
int    _HandlePatternColorMode;
int    _HandlePatternColorUsed;
float4 _HandlePatternColorA;
float4 _HandlePatternColorB;
float4 _HandlePatternColorC;
float4 _HandlePatternColorD;

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
// Handle Face material uniforms
// ============================================================================
float  _HandleFaceEnabled;
float4 _HandleFaceColor;
float  _HandleFaceRenderAlpha;
float  _HandleFaceRenderEmissive;
float  _HandleFaceSize;

float  _HandleFaceGradientEnabled;
int    _HandleFaceGradientType;
float4 _HandleFaceGradientColorA;
float4 _HandleFaceGradientColorB;
float4 _HandleFaceGradientColorC;
float4 _HandleFaceGradientColorD;
float2 _HandleFaceGradientDirection;
float  _HandleFaceGradientSpeed;
float  _HandleFaceGradientScale;
float  _HandleFaceGradientOffset;
int    _HandleFaceGradientColorUsed;

// ============================================================================
// Bridge macros — redirect SDFToggleRenderCore's _Toggle* references to
// the semantically-named _Handle* uniforms declared above.
// SharedUniforms still declares float _ToggleEnabled etc. (used by other
// per-type shaders), but for Pill those are unbound / unused — only the
// _Handle* uniforms are bound by the material.
// ============================================================================

// _TogglePadding: no property exposed — handle body fills the track area
#define _TogglePadding 0.0

// Toggle body → Handle
#define _ToggleEnabled                   _HandleEnabled
#define _ToggleColor                     _HandleColor
#define _ToggleRenderAlpha               _HandleRenderAlpha
#define _ToggleRenderEmissive            _HandleRenderEmissive
#define _ToggleBevelEnabled              _HandleBevelEnabled
#define _ToggleBevelDepth                _HandleBevelDepth
#define _ToggleBevelSmoothness           _HandleBevelSmoothness
#define _ToggleBevelDistance             _HandleBevelDistance
#define _ToggleFaceSmoothness            _HandleFaceSmoothness
#define _ToggleBevelProfileType          _HandleBevelProfileType
#define _ToggleBevelProfileSharpness     _HandleBevelProfileSharpness
#define _ToggleBevelPatternEnabled       _HandleBevelPatternEnabled
#define _ToggleBevelPatternType          _HandleBevelPatternType
#define _ToggleBevelPatternScale         _HandleBevelPatternScale
#define _ToggleBevelPatternIntensity     _HandleBevelPatternIntensity
#define _ToggleBevelPatternContrast      _HandleBevelPatternContrast
#define _ToggleBevelPatternSpecularEffect  _HandleBevelPatternSpecularEffect
#define _ToggleBevelPatternRoughnessEffect _HandleBevelPatternRoughnessEffect
#define _ToggleBevelPatternParam1        _HandleBevelPatternParam1
#define _ToggleBevelPatternParam2        _HandleBevelPatternParam2
#define _ToggleBevelPatternParam3        _HandleBevelPatternParam3
#define _ToggleBevelPatternColorEnabled  _HandleBevelPatternColorEnabled
#define _ToggleBevelPatternColorType     _HandleBevelPatternColorType
#define _ToggleBevelPatternColorMode     _HandleBevelPatternColorMode
#define _ToggleBevelPatternColorUsed     _HandleBevelPatternColorUsed
#define _ToggleBevelPatternColorA        _HandleBevelPatternColorA
#define _ToggleBevelPatternColorB        _HandleBevelPatternColorB
#define _ToggleBevelPatternColorC        _HandleBevelPatternColorC
#define _ToggleBevelPatternColorD        _HandleBevelPatternColorD
#define _ToggleBevelGradientEnabled      _HandleBevelGradientEnabled
#define _ToggleBevelGradientType         _HandleBevelGradientType
#define _ToggleBevelGradientColorA       _HandleBevelGradientColorA
#define _ToggleBevelGradientColorB       _HandleBevelGradientColorB
#define _ToggleBevelGradientColorC       _HandleBevelGradientColorC
#define _ToggleBevelGradientColorD       _HandleBevelGradientColorD
#define _ToggleBevelGradientDirection    _HandleBevelGradientDirection
#define _ToggleBevelGradientSpeed        _HandleBevelGradientSpeed
#define _ToggleBevelGradientScale        _HandleBevelGradientScale
#define _ToggleBevelGradientOffset       _HandleBevelGradientOffset
#define _ToggleBevelGradientColorUsed    _HandleBevelGradientColorUsed
#define _ToggleRimEnabled                _HandleRimEnabled
#define _ToggleRimDepth                  _HandleRimDepth
#define _ToggleRimWidth                  _HandleRimWidth
#define _ToggleRimSmoothness             _HandleRimSmoothness
#define _TogglePatternEnabled            _HandlePatternEnabled
#define _TogglePatternType               _HandlePatternType
#define _TogglePatternScale              _HandlePatternScale
#define _TogglePatternIntensity          _HandlePatternIntensity
#define _TogglePatternContrast           _HandlePatternContrast
#define _TogglePatternSpecularEffect     _HandlePatternSpecularEffect
#define _TogglePatternRoughnessEffect    _HandlePatternRoughnessEffect
#define _TogglePatternRotateEnabled      _HandlePatternRotateEnabled
#define _TogglePatternModEnabled         _HandlePatternModEnabled
#define _TogglePatternModAmount          _HandlePatternModAmount
#define _TogglePatternModFrequency       _HandlePatternModFrequency
#define _TogglePatternOffset             _HandlePatternOffset
#define _TogglePatternParam1             _HandlePatternParam1
#define _TogglePatternParam2             _HandlePatternParam2
#define _TogglePatternParam3             _HandlePatternParam3
#define _TogglePatternColorEnabled       _HandlePatternColorEnabled
#define _TogglePatternColorType          _HandlePatternColorType
#define _TogglePatternColorMode          _HandlePatternColorMode
#define _TogglePatternColorUsed          _HandlePatternColorUsed
#define _TogglePatternColorA             _HandlePatternColorA
#define _TogglePatternColorB             _HandlePatternColorB
#define _TogglePatternColorC             _HandlePatternColorC
#define _TogglePatternColorD             _HandlePatternColorD
#define _ToggleGradientEnabled           _HandleGradientEnabled
#define _ToggleGradientType              _HandleGradientType
#define _ToggleGradientColorA            _HandleGradientColorA
#define _ToggleGradientColorB            _HandleGradientColorB
#define _ToggleGradientColorC            _HandleGradientColorC
#define _ToggleGradientColorD            _HandleGradientColorD
#define _ToggleGradientDirection         _HandleGradientDirection
#define _ToggleGradientSpeed             _HandleGradientSpeed
#define _ToggleGradientScale             _HandleGradientScale
#define _ToggleGradientOffset            _HandleGradientOffset
#define _ToggleGlobalBlend               _HandleGlobalBlend
#define _ToggleGlobalIntensity           _HandleGlobalIntensity
#define _ToggleGradientColorUsed         _HandleGradientColorUsed

// Toggle face → Handle face
#define _ToggleFaceEnabled               _HandleFaceEnabled
#define _ToggleFaceColor                 _HandleFaceColor
#define _ToggleFaceRenderAlpha           _HandleFaceRenderAlpha
#define _ToggleFaceRenderEmissive        _HandleFaceRenderEmissive
#define _ToggleFaceSize                  _HandleFaceSize
#define _ToggleFaceGradientEnabled       _HandleFaceGradientEnabled
#define _ToggleFaceGradientType          _HandleFaceGradientType
#define _ToggleFaceGradientColorA        _HandleFaceGradientColorA
#define _ToggleFaceGradientColorB        _HandleFaceGradientColorB
#define _ToggleFaceGradientColorC        _HandleFaceGradientColorC
#define _ToggleFaceGradientColorD        _HandleFaceGradientColorD
#define _ToggleFaceGradientDirection     _HandleFaceGradientDirection
#define _ToggleFaceGradientSpeed         _HandleFaceGradientSpeed
#define _ToggleFaceGradientScale         _HandleFaceGradientScale
#define _ToggleFaceGradientOffset        _HandleFaceGradientOffset
#define _ToggleFaceGradientColorUsed     _HandleFaceGradientColorUsed

#endif // SDFTOGGLE_PILL_DEFS_INCLUDED
