// SDFPillShapes.cginc
// SDF shape functions for the Pill / iOS-style slide toggle.
// Provides getToggleBodySDF / getToggleTrackSDF entry points directly —
// no _ToggleType dispatch needed.
//
// Must be included AFTER SDFTogglePillDefs.cginc so that _ToggleParam* macros,
// _Value and _StateCount uniforms are already declared.
// Sets SDF_TOGGLE_SHAPES_INCLUDED so SDFToggleLayers.cginc skips the monolithic
// SDFToggleShapes.cginc dispatcher (which is only needed by legacy shaders).
//
// _ToggleParam* slot assignments (from SDFTogglePillDefs.cginc):
//   _ToggleParam1 = _TrackHeight       — track height as fraction of halfH (0.25–0.90)
//   _ToggleParam2 = _HandlePadding     — gap between ball edge and track wall
//   _ToggleParam3 = _TrackCornerRadius — 0=rectangular track, 1=full-capsule
//   _ToggleParam4 = _HandleFlatten     — 0=circular ball, 1=squished oval along travel
//   _ToggleParam5 = _TrackInsetDepth   — visual inset depth (consumed by RenderCore, not here)

#ifndef SDF_PILL_SHAPES_INCLUDED
#define SDF_PILL_SHAPES_INCLUDED

// Signals SDFToggleLayers.cginc that getToggleBodySDF / getToggleTrackSDF
// are already defined here. Future per-type shapes cgincs should do the same.
#define SDF_TOGGLE_SHAPES_INCLUDED
#define SDF_TOGGLE_PERTYPE_SHAPES_INCLUDED

// ============================================================================
// Track — pill-shaped groove
// ============================================================================
float getPillTrackSDF(float2 p, float halfW, float halfH)
{
    float trackHH = halfH * lerp(0.25, 0.90, _ToggleParam1);
    float cornerR = trackHH * saturate(_ToggleParam3);  // 1.0 = perfect capsule
    return RoundedRectSDF(p, float2(halfW, trackHH), cornerR);
}

// ============================================================================
// Handle (ball) — slides left/right along the track
// ============================================================================
float getPillBodySDF(float2 p, float halfW, float halfH)
{
    float trackHH  = halfH * lerp(0.25, 0.90, _ToggleParam1);
    float padding  = trackHH * lerp(0.04, 0.30, _ToggleParam2);
    float ballR    = trackHH - padding;
    float travelHW = halfW - ballR - padding;

    // Discrete snapping for multi-state toggles (StateCount >= 2)
    float t = saturate(_Value);
    if (_StateCount >= 2)
        t = floor(t * float(_StateCount - 1) + 0.5) / float(_StateCount - 1);

    float ballX   = lerp(-travelHW, travelHW, t);
    float2 ballPos = p - float2(ballX, 0);

    // Optional oval flattening along travel axis (0=circle, 1=squished oval)
    float flatten = lerp(1.0, 0.75, _ToggleParam4);
    ballPos.x /= max(0.01, flatten);
    float ballDist = CircleSDF(ballPos, ballR);
    if (abs(1.0 - flatten) > 0.01)
        ballDist *= flatten;    // approximate SDF rescale

    return ballDist;
}

// ============================================================================
// Entry points consumed by SDFToggleLayers / SDFToggleRenderCore
// ============================================================================
float getToggleBodySDF(float2 p, float halfW, float halfH)
{
    return getPillBodySDF(p, halfW, halfH);
}

float getToggleTrackSDF(float2 p, float halfW, float halfH)
{
    return getPillTrackSDF(p, halfW, halfH);
}

#endif // SDF_PILL_SHAPES_INCLUDED
