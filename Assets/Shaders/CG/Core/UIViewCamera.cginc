#ifndef UI_VIEW_CAMERA_CGINC
#define UI_VIEW_CAMERA_CGINC

// ============================================================================
// UIViewCamera.cginc — the scene "eye point" as a BOUNDED ADD-ON to each RM
// shader's authored view (tracker §4.16 B).
// ============================================================================
// The RM shaders already have two view inputs a human tunes by hand:
//
//   _ViewShift / _ViewTilt          — the skin's static view, authored per states.json
//   _ViewValueShift* / _ViewValueTilt* — a value-driven lerp on top (a knob leaning as it turns)
//
// Neither is touched here. The scene camera is a THIRD, strictly-bounded term:
// the app publishes one eye position for the whole screen, and each material
// declares the MOST that eye is allowed to move it.
//
//   _ViewCamEnabled  0/1  — opt this material into the scene camera at all
//   _ViewCamShift    ±max — most the camera may add to / subtract from _ViewShift
//   _ViewCamTilt     ±max — most the camera may add to / subtract from _ViewTilt
//
// So a widget dead-centre gets +0; one at the far left gets its full −_ViewCamShift;
// nothing can ever swing further than the material said it may. Set _ViewCamShift to
// 0 and that material simply ignores the camera, exactly as before this existed.
//
// WHY IT LIVES IN THE SHADER: the previous approach had the app write _ViewShift
// per material each frame, which meant remembering everyone's authored base value and
// racing with whoever else wrote it (state transitions, per-panel parallax). Here the
// app publishes ONE global and every material blends it locally — nothing to cache,
// nothing to race, and a material's authored value is never overwritten.
// ============================================================================

// xy = eye position in the same aspect-scaled normalized screen space as _Position;
// z  = shift gain, w = tilt gain (how fast distance from the eye reaches the max).
float4 _GlobalViewCam;

// Signed −1..1 offset of an object from the eye point, per axis.
// x: negative = left of the eye, positive = right.
// y: negative = below the eye,  positive = above.
float2 UIViewCamFactor(float2 objectPos)
{
    return clamp((objectPos - _GlobalViewCam.xy) * _GlobalViewCam.zw, -1.0, 1.0);
}

// The camera's contribution for this material, already bounded by its own maxima.
// Declaration order doesn't matter for macros — they expand where the uniforms exist.
#define UI_VIEW_CAM_SHIFT ((_ViewCamEnabled > 0.5) ? UIViewCamFactor(_Position.xy).x * _ViewCamShift : 0.0)
#define UI_VIEW_CAM_TILT  ((_ViewCamEnabled > 0.5) ? UIViewCamFactor(_Position.xy).y * _ViewCamTilt  : 0.0)

// Drop-in replacements for the authored base terms. Every RM shader builds its
// effective view from these instead of the raw uniforms, so the camera term rides
// along wherever the base value already went (body, shadows, self-shadow, nub, …).
// _ViewTilt is a MAGNITUDE (its property range is 0..10) — the raymarch doesn't expect a
// negative and would project inside-out. The camera can pull it down toward flat but never
// through it, matching what RmViewParallax already does on the C# side.
#define UI_VIEW_SHIFT (_ViewShift + UI_VIEW_CAM_SHIFT)
#define UI_VIEW_TILT  max(0.0, _ViewTilt + UI_VIEW_CAM_TILT)

#endif // UI_VIEW_CAMERA_CGINC
