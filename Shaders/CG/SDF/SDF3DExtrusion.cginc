#ifndef SDF_3D_EXTRUSION_CGINC
#define SDF_3D_EXTRUSION_CGINC

// =============================================================================
// SDF3DExtrusion.cginc — 3D SDF Extrusion for 2D→3D knob/button bodies
// =============================================================================
//
// Pure function library (no shader properties, no macros required).
// All 2D SDF values are passed as parameters — the caller evaluates
// its own shape SDF and passes the result.
//
// Physical cross-section (side view, outside→in, bottom→top):
//
//                  ┌─────────┐              face cap (SURFACE_FACE)
//                 /           \             bevel wall (SURFACE_WALL)
//     ┌──────────┘             └──────────┐ rim shelf (SURFACE_RIM)
//     │                                   │ vertical lip (SURFACE_LIP)
// ────┘                                   └──── base
//
// 3D body = union of:
//   Part A: Lip cylinder — base shape extruded from y=0 to y=lipHeight
//   Part B: Tapered body — insets from rimWidth at y=lipHeight to
//                          rimWidth+bevelDist at y=totalHeight
//
// The gap between Part A and Part B at y=lipHeight naturally creates
// the rim shelf (Part A covers outer region, Part B only the inset region).
// =============================================================================

// Surface type constants
#define SURFACE_MISS  0
#define SURFACE_LIP   1
#define SURFACE_RIM   2
#define SURFACE_WALL  3
#define SURFACE_FACE  4

struct ExtrusionParams
{
    float knobRadius;     // outer shape radius
    float lipHeight;      // height of vertical lip at outer edge (~0.03 * knobRadius)
    float rimWidth;       // flat shelf width (_KnobRimWidth), 0 if rim disabled
    float bevelHeight;    // wall height, derived from _BevelDepth
    float bevelDist;      // horizontal inset of face from rim inner edge (_BevelDistance)
    float totalHeight;    // lipHeight + bevelHeight
    int   hasFaceShape;   // 1 if face shape differs from base shape
    float filletRadius;   // top-edge fillet radius (0 = sharp corner between wall and face cap)
};

// ─────────────────────────────────────────────────────────────────────────────
// 3D SDF of the extruded knob body
// ─────────────────────────────────────────────────────────────────────────────
// baseSDF: pre-evaluated 2D SDF of the outer shape at point p.xz
// faceSDF: pre-evaluated 2D SDF of the face shape at point p.xz
//          (includes rimWidth + bevelDist inset already baked in)

float sdfExtrusion3D(float3 p, float baseSDF, float faceSDF, ExtrusionParams params)
{
    float y = p.y;

    // ── Part A: outer lip cylinder  y ∈ [0, lipHeight]
    //    Outer wall is the base shape at full radius.  Clamp to the y-slab.
    float sdA = max(baseSDF, max(-y, y - params.lipHeight));

    // ── Part B: tapered bevel body  y ∈ [lipHeight, totalHeight]
    //    Base of bevel is inset by rimWidth from the outer shape.
    //    The rim shelf is the horizontal gap between Part A top and Part B base:
    //    it is NOT produced by the SDF itself but by the surface classification
    //    (Part B outer wall is smaller than Part A, so there is a clear ledge).
    float bevelH = max(0.0001, params.bevelHeight);
    float t = saturate((y - params.lipHeight) / bevelH);

    float sdB_shape;
    if (params.hasFaceShape > 0)
    {
        float basePart = baseSDF + params.rimWidth;
        sdB_shape = lerp(basePart, faceSDF, t);
    }
    else
    {
        float inset = params.rimWidth + t * params.bevelDist;
        sdB_shape = baseSDF + inset;
    }

    // Clamp Part B to its y-slab.
    float sdB_raw = max(sdB_shape, max(params.lipHeight - y, y - params.totalHeight));

    // Rounded top-edge fillet (wall→face corner).
    float sdB;
    if (params.filletRadius > 0.0001)
    {
        float wa = sdB_shape;              // wall: 0 on surface, + outside
        float fa = y - params.totalHeight; // face: 0 on surface, + above
        float k  = params.filletRadius;
        float h  = max(k - abs(wa - fa), 0.0) / k;
        sdB = max(max(wa, fa) + h * h * k * 0.25, params.lipHeight - y);
    }
    else
    {
        sdB = sdB_raw;
    }

    // Union of the two slabs.  They share the boundary at y=lipHeight where
    // sdA_outer == baseSDF and sdB_base == baseSDF + rimWidth: they only meet
    // at the same XZ position when rimWidth==0, and even then the normals
    // diverge (sdA is bounded above at lipHeight, sdB bounded below there).
    return min(sdA, sdB);
}

// ─────────────────────────────────────────────────────────────────────────────
// Map 3D normal from knob local space to screen-space normal (for lighting)
// ─────────────────────────────────────────────────────────────────────────────
// The existing UILighting expects normals where Z points toward the viewer.
//   knob x → screen across-tilt (unchanged)
//   knob y,z → rotated by tilt angle into screen along-tilt + toward-viewer

float3 normalToScreenSpace(float3 knobNormal, float sinTilt, float cosTilt)
{
    return float3(
        knobNormal.x,
        knobNormal.y * sinTilt - knobNormal.z * cosTilt,
        knobNormal.y * cosTilt + knobNormal.z * sinTilt
    );
}

#endif // SDF_3D_EXTRUSION_CGINC
