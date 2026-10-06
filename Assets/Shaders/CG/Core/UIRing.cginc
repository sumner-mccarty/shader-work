#ifndef UI_RING_CGINC
#define UI_RING_CGINC

#include "Constants.cginc"

// =============================================================================
// ONE RING, TWO JOBS — the shared profile behind Edge and Border.
//
// Edge and Border were always the same effect drawn twice: a band that starts at a shape's
// outline and reaches outward, drawn under everything the widget renders. They differed only
// in how the band FALLS OFF, and each had its own hard-coded answer:
//
//   Edge   — a gradient, strongest against the shape and gone by `width`. Reads as a recess:
//            the widget is sitting in a cutout and the faceplate is dark right at the lip.
//   Border — flat across the band, soft only where it terminates. Reads as a drawn ring:
//            a hover/press outline, a glow, a colour the app changes at runtime.
//
// Neither could do the other's job, which is why "give me a dark hole OR a glowing ring" used
// to mean picking the right component rather than setting a value. `falloff` is that value:
// 0 is Border's flat band, 1 is Edge's gradient, and everything between is a real look.
//
//   distOut  signed distance OUTSIDE the shape's outline (>0 outside, <0 inside). Whatever
//            frame the caller measures in, it must be the SAME frame the shape is drawn in —
//            for a tilted RM widget that is the base-plane projection (frag2dBodyPos), not
//            raw screen position, or the ring slides off the shape it is supposed to hug.
//   inset    moves the band's INNER boundary. Positive starts it inside the shape, so the
//            widget's own edge sits over the darkest part of a recess.
//   width    how far the band reaches past that inner boundary.
//   softness how it terminates. On the flat profile this is the fade past `width`; on the
//            graded profile it bends the curve — higher hugs the shape more tightly.
//   aa       one screen pixel in the same units, the floor on every transition.
//   cutInside  1 for a SIGNED field (the usual case) so the band never fills the shape.
//            0 for an UNSIGNED distance-to-boundary field, which has no inside to cut — the
//            knob's Edge measures to the outer edge of everything it draws (arcs, fill rim)
//            and clamps at zero, so cutting there would halve the band at its own peak.
//
// The band is always cut off at its own inner boundary, so it is a RING and never fills the
// shape's interior. That matters for a tilted widget: the body is drawn shifted off its base
// footprint by the view projection, so an Edge that filled its interior would spill out from
// under the body on the near side.
// =============================================================================
float UIRingMask(float distOut, float inset, float width, float softness, float falloff,
                 float aa, float cutInside = 1.0)
{
    float w   = max(width, 1e-5);
    float aaW = max(aa, 1e-6);
    float d   = distOut + inset;            // 0 at the band's inner boundary, grows outward

    // Never inside. This is what makes it a ring.
    float inner = lerp(1.0, smoothstep(-aaW, aaW, d), saturate(cutInside));

    // FLAT: full strength across the band, terminating over `softness` past `width`.
    float flat = 1.0 - smoothstep(w, w + max(softness, aaW), d);

    // GRADED: strongest against the shape, gone by `width`. `softness` bends the curve.
    // The sine at the end is what keeps the peak from reading as a hard line against the
    // widget's own edge — a linear ramp there looks like a stroke, not like a recess.
    float g = saturate(1.0 - d / w);
    float graded = (softness > 0.001)
        ? pow(g, lerp(0.8, 4.0, pow(saturate(softness * 0.5), 1.5)))
        : 1.0 - smoothstep(w - aaW, w + aaW, d);
    graded = sin(graded * (PI * 0.5));

    return inner * lerp(flat, graded, saturate(falloff));
}

#endif // UI_RING_CGINC
