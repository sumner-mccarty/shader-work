// ============================================================================
// SDFDigits.cginc — numerals as signed distance fields
// ============================================================================
// Pure functions, no uniforms, no state (CG/Core + CG/SDF architecture).
//
// WHY A SEVEN-SEGMENT NUMERAL rather than a glyph sampled out of the app's SDF
// atlas: the numbers these draw are stamped on things that are ALREADY being
// raymarched or perspective-projected — a note flying down the highway, a plate
// on a moving control — so the digit has to survive arbitrary minification and
// arbitrary anisotropy without a mip chain, and it has to cost one distance
// evaluation rather than a texture fetch per pixel. A field built from six
// rounded bars is exact at every size, has no atlas to keep in step with a
// themepack, and reads at a distance because a segment display is the most
// legible numeral shape ever designed for exactly that problem.
//
// It also happens to be the app's own idiom: every readout in the rack is a
// seven-segment face (LedReadout), so a numeral drawn this way belongs to the
// same machine rather than looking like UI text pasted over the game.
//
// COORDINATES. Every function takes p in NORMALIZED digit space: (0,0) at the
// centre of the numeral, x in -1..+1 across its width, y in -1..+1 across its
// height. Scale into that space before calling, and the returned distance is in
// those same units — divide by your scale to get back to yours if you need a
// real-world width for antialiasing.
// ============================================================================

#ifndef SDF_DIGITS_INCLUDED
#define SDF_DIGITS_INCLUDED

// A rounded bar. Kept local so this file has no include order to get wrong.
inline float sdgBar(float2 p, float2 halfSize, float r)
{
    float2 q = abs(p) - (halfSize - r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// ── the seven segments ──────────────────────────────────────────────────────
//
//      aaaa          Segment order matches the century-old convention so the
//     f    b         per-digit masks below can be read against any datasheet:
//     f    b         bit 0 = a (top), 1 = b (upper right), 2 = c (lower right),
//      gggg          3 = d (bottom), 4 = e (lower left), 5 = f (upper left),
//     e    c         6 = g (middle).
//     e    c
//      dddd
//
// `bar` is the half-thickness of a stroke in digit space; 0.16 is the weight
// that reads cleanly from a gem's distance without the counters closing up.

inline float sdgSegments(float2 p, int mask, float bar)
{
    // Segment ends stop short of the corners by one stroke so the joints read as
    // mitred rather than as a blob, exactly as a real display's do.
    float xh = 0.62 - bar;      // half-length of a horizontal segment
    float yh = 0.46 - bar;      // half-length of a vertical segment
    float yo = 0.50;            // vertical offset of the upper/lower segments
    float r  = bar * 0.55;      // cap rounding

    float d = 1e6;
    if (mask & 1)   d = min(d, sdgBar(p - float2(0.0,  1.00), float2(xh, bar), r)); // a
    if (mask & 2)   d = min(d, sdgBar(p - float2( 0.62, yo),  float2(bar, yh), r)); // b
    if (mask & 4)   d = min(d, sdgBar(p - float2( 0.62,-yo),  float2(bar, yh), r)); // c
    if (mask & 8)   d = min(d, sdgBar(p - float2(0.0, -1.00), float2(xh, bar), r)); // d
    if (mask & 16)  d = min(d, sdgBar(p - float2(-0.62,-yo),  float2(bar, yh), r)); // e
    if (mask & 32)  d = min(d, sdgBar(p - float2(-0.62, yo),  float2(bar, yh), r)); // f
    if (mask & 64)  d = min(d, sdgBar(p, float2(xh, bar), r));                      // g
    return d;
}

/// <summary>Segment mask for one decimal digit. Anything out of range draws nothing.</summary>
inline int sdgMaskFor(int digit)
{
    if (digit == 0) return 63;   // a b c d e f
    if (digit == 1) return 6;    //   b c
    if (digit == 2) return 91;   // a b   d e   g
    if (digit == 3) return 79;   // a b c d     g
    if (digit == 4) return 102;  //   b c   e f g   (the classic open-top 4)
    if (digit == 5) return 109;  // a   c d   f g
    if (digit == 6) return 125;  // a   c d e f g
    if (digit == 7) return 7;    // a b c
    if (digit == 8) return 127;  // all
    if (digit == 9) return 111;  // a b c d   f g
    return 0;
}

/// <summary>
/// One digit, centred on the origin of normalized digit space.
///
/// A DIGIT IS DRAWN NARROWER THAN ITS BOX because a numeral is taller than it is
/// wide; the caller's box stays square-ish (it is a plate, or a pad) and the
/// numeral is fitted inside it rather than stretched to it, which is what stops
/// a "1" from looking like a different weight to a "4".
/// </summary>
inline float sdgDigit(float2 p, int digit, float bar)
{
    float x = p.x / 0.78;
    // A seven-segment 1 is drawn on the RIGHT of its cell, which is correct on a multi-digit
    // display (the digits stay on their pitch) and wrong on a badge carrying a single numeral,
    // where it reads as a 1 that has drifted. Centred here, and only here.
    if (digit == 1) x += 0.62;
    return sdgSegments(float2(x, p.y), sdgMaskFor(digit), bar);
}

inline float sdgDigit(float2 p, int digit)
{
    return sdgDigit(p, digit, 0.16);
}

// ── typographic numerals ────────────────────────────────────────────────────
//
// THE SEGMENT FACE HAS ONE NUMERAL IT CANNOT DRAW ALONE: a seven-segment "1" is two short
// vertical bars with the mitre gap between them, and on its own on a small badge that is a
// COLON — the note markers on the highway read ":" rather than 1, 2, 3 (user, 2026-09-26). On
// a rack readout the neighbouring digits and the glass give the context that makes it a 1; a
// lone numeral on a moving note has none. So a badge carrying ONE number uses these: drawn
// strokes and arcs, a "1" with its flag and foot, a curved "2", a two-bowl "3", an open "4".
// Same normalized digit space and same contract as sdgDigit — distance in digit units, `bar`
// is the stroke's half-thickness — so a caller swaps one call for the other. Only 1–4 exist
// (the pad rows); anything else falls back to the segments.

// Distance to the segment a–b.
inline float sdgStroke(float2 p, float2 a, float2 b)
{
    float2 pa = p - a, ba = b - a;
    float h = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-6));
    return length(pa - ba * h);
}

// Distance to the arc of radius r about c, counter-clockwise from angle a0 to a1 (radians).
inline float sdgArc(float2 p, float2 c, float r, float a0, float a1)
{
    float2 q = p - c;
    float t = atan2(q.y, q.x) - a0;
    t -= 6.2831853 * floor(t / 6.2831853);
    if (t <= a1 - a0) return abs(length(q) - r);
    float2 e0 = c + r * float2(cos(a0), sin(a0));
    float2 e1 = c + r * float2(cos(a1), sin(a1));
    return min(length(p - e0), length(p - e1));
}

inline float sdgNumeral(float2 p, int digit, float bar)
{
    float2 q = float2(p.x / 0.78, p.y);
    const float DEG = 0.01745329;
    float d = 1e6;
    if (digit == 1)
    {
        d = min(d, sdgStroke(q, float2(0.10, -1.0), float2(0.10, 1.0)));     // stem
        d = min(d, sdgStroke(q, float2(0.10, 1.0), float2(-0.44, 0.60)));    // flag
        d = min(d, sdgStroke(q, float2(-0.42, -1.0), float2(0.62, -1.0)));   // foot
    }
    else if (digit == 2)
    {
        float2 c = float2(0.0, 0.42);
        float r = 0.56;
        float2 e0 = c + r * float2(cos(-40.0 * DEG), sin(-40.0 * DEG));
        d = min(d, sdgArc(q, c, r, -40.0 * DEG, 168.0 * DEG));              // hook
        d = min(d, sdgStroke(q, e0, float2(-0.60, -1.0)));                   // spine
        d = min(d, sdgStroke(q, float2(-0.60, -1.0), float2(0.62, -1.0)));   // base
    }
    else if (digit == 3)
    {
        d = min(d, sdgArc(q, float2(0.0, 0.50), 0.48, -90.0 * DEG, 155.0 * DEG));    // upper bowl
        d = min(d, sdgArc(q, float2(0.0, -0.46), 0.54, -155.0 * DEG, 90.0 * DEG));   // lower bowl
        d = min(d, sdgStroke(q, float2(-0.16, 0.05), float2(0.02, 0.05)));           // waist
    }
    else if (digit == 4)
    {
        d = min(d, sdgStroke(q, float2(0.22, -1.0), float2(0.22, 1.0)));     // stem
        d = min(d, sdgStroke(q, float2(0.22, 1.0), float2(-0.66, -0.30)));   // diagonal
        d = min(d, sdgStroke(q, float2(-0.66, -0.30), float2(0.62, -0.30))); // crossbar
    }
    else
    {
        return sdgDigit(p, digit, bar);
    }
    return d - bar;
}

inline float sdgNumeral(float2 p, int digit)
{
    return sdgNumeral(p, digit, 0.19);
}

#endif // SDF_DIGITS_INCLUDED
