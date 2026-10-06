#ifndef UI_GLOBAL_UNIFORMS_INCLUDED
#define UI_GLOBAL_UNIFORMS_INCLUDED

// Screen effects uniforms
uniform int _GlobalEffectMask;
uniform float _GlobalChromaticStrength;
uniform float _GlobalGrainIntensity;
uniform float _GlobalGrainSize;
uniform float _GlobalVignetteIntensity;
uniform float _GlobalVignetteRadius;
uniform float _GlobalVignetteSmooth;
uniform float _GlobalScanlineIntensity;
uniform float _GlobalScanlineCount;
uniform float _GlobalGlitchIntensity;
uniform float _GlobalGlitchFreq;
uniform float _GlobalBrightness;
uniform float _GlobalContrast;
uniform float _GlobalSaturation;
uniform float4 _GlobalColorBalance;
uniform float _GlobalPixelSize;
uniform float2 _GlobalScreenSize;

// Shared cross-widget shadow buffer (UIShadowBufferManager.cs): every shadow-casting widget's
// _ShadowPassMode=1 quad renders into this offscreen texture via a dedicated capture camera, and
// every widget samples it at its own screen position to receive shadows from ANY caster,
// independent of hierarchy/draw order. White = no shadow; casters multiply-darken onto it.
uniform sampler2D _UIShadowBuffer;
// Is that texture actually bound this frame? UIShadowBufferManager sets both together in
// LateUpdate. Nothing binds them in the Material State Designer, in a thumbnail render, or on
// the very first frame before the manager has ticked — and an UNBOUND sampler2D does not read
// as white, it reads as whatever Unity happens to leave in that slot, which for a "multiply
// this in" texture is the difference between "no shadow" and "solid black over everything".
// Guard, don't hope.
uniform float _UIShadowBufferBound;

// Materials v2 (2026-10-06) — bound by UiMaterialLibrary.cs (runtime) and SkinSheet.cs (editor).
// _UIMaterialTexArray: tileable surface textures (pattern type 20, PATTERN_TEXTURE).
// _UIMatcapArray:      lit-sphere reflections (UIMaterials.cginc).
// _UIBackdropTex:      the look's wallpaper, mipmapped, sampled by glass parts at their screen UV.
// The *Bound flags gate every read: an unbound texture is not "neutral", it is whatever is left
// in the slot.
UNITY_DECLARE_TEX2DARRAY(_UIMaterialTexArray);
UNITY_DECLARE_TEX2DARRAY(_UIMatcapArray);
uniform float _UIMaterialLibBound;
uniform sampler2D _UIBackdropTex;
uniform float _UIBackdropBound;
// screen uv → wallpaper uv (scale xy, offset zw): the wallpaper is drawn aspect-FILLED, so a screen
// whose aspect differs from the image sees a centred crop; a negative y scale flips it.
uniform float4 _UIBackdropUV;

// Global gradient uniforms
uniform float _GlobalGradientTime;
uniform int _GlobalGradientType;
uniform float4 _GlobalGradientColorA;
uniform float4 _GlobalGradientColorB;
uniform float4 _GlobalGradientColorC;
uniform float4 _GlobalGradientColorD;
uniform float2 _GlobalGradientDirection;
uniform float _GlobalGradientScale;
uniform float _GlobalGradientOffset;
uniform float _GlobalPulseFreq;
uniform float _GlobalPulseIntensity;
uniform float4 _GlobalWaveParams;

#endif // UI_GLOBAL_UNIFORMS_INCLUDED