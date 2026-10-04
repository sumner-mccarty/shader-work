// ============================================================================
// SDFWaveform.cginc — pure functions for the GPU waveform display
// ============================================================================
// Library for SDFWaveform.shader (tracker §1.6). No uniforms, no state — every
// function takes everything it needs as parameters, matching the CG/Core +
// CG/SDF architecture.
//
// DATA CONTRACT (baked by WaveformGpuData.Bake):
//   waveTex — RGBAHalf, COLS × LEVELS, point filter, clamp. Row L is peak-
//     pyramid level L (COLS >> L valid texels; the tail repeats the last value):
//       R = min (remapped -1..1 → 0..1)   G = max (same remap)
//       B = RMS 0..1                      A = spectral centroid 0..1
//   freqTex — RGBAHalf, COLS × 1: R/G/B = low/mid/high band energy, A = onset.
//
// COORDINATES:
//   t   clip-normalized time 0..1 (the whole clip). The visible window is
//       [viewStart, viewEnd]; u maps linearly across it.
//   sy  signal space, -1..+1 vertically inside the quad (baseline at 0).
//   All SDF distances are converted to PIXELS before AA so edges stay
//   screen-crisp at any panel size (same rule as the rest of the library).
//
// LOD RULE (the DAW peak-pyramid technique): pick the pyramid level whose
// column span is closest to one on-screen pixel. Zoomed out, a coarser row
// already holds the true min/max over its span, so peaks never alias or thin;
// zoomed in, the base row is linearly interpolated so columns don't blockify.
// ============================================================================

#ifndef SDF_WAVEFORM_INCLUDED
#define SDF_WAVEFORM_INCLUDED

// ── compositing (premultiplied accumulate, matching the library style) ──────

inline void wvOver(inout float4 acc, float3 rgb, float a)
{
    acc.rgb = acc.rgb * (1.0 - a) + rgb * a;
    acc.a = acc.a * (1.0 - a) + a;
}

inline void wvAdd(inout float4 acc, float3 rgb)
{
    acc.rgb += rgb;
}

// Anti-aliased fill from a distance already expressed in pixels.
inline float wvFillPx(float dPx)
{
    return smoothstep(0.75, -0.75, dPx);
}

// Soft exponential glow (0 far, 1 at surface), pixel-space falloff.
inline float wvGlowPx(float dPx, float falloffPx)
{
    return exp(-max(dPx, 0.0) / max(falloffPx, 1e-3));
}

// ── data sampling ───────────────────────────────────────────────────────────

// Pyramid level for the current zoom: log2 of data columns per screen pixel,
// clamped into the baked rows. Fractional so callers can blend two rows.
inline float wvLodLevel(float viewSpan, float cols, float levels, float quadWidthPx)
{
    float colsPerPx = viewSpan * cols / max(quadWidthPx, 1.0);
    return clamp(log2(max(colsPerPx, 1.0)), 0.0, levels - 1.0);
}

// Sample one pyramid row at clip time t with manual linear filtering across
// columns (the texture is point-filtered because rows must never blend into
// each other). Returns (min, max, rms, centroid), min/max still 0..1-encoded.
inline float4 wvSampleRow(sampler2D waveTex, float t, float level,
                          float cols, float levels)
{
    float valid = cols / exp2(level);
    float x = t * valid - 0.5;
    float x0 = floor(x);
    float f = x - x0;
    float u0 = (clamp(x0, 0.0, valid - 1.0) + 0.5) / cols;
    float u1 = (clamp(x0 + 1.0, 0.0, valid - 1.0) + 0.5) / cols;
    float v = (level + 0.5) / levels;
    float4 s0 = tex2Dlod(waveTex, float4(u0, v, 0, 0));
    float4 s1 = tex2Dlod(waveTex, float4(u1, v, 0, 0));
    return lerp(s0, s1, f);
}

// Full LOD sample: blend the two straddling pyramid rows so zooming animates
// smoothly instead of popping between detail levels.
inline float4 wvSampleWave(sampler2D waveTex, float t, float lod,
                           float cols, float levels)
{
    float l0 = floor(lod);
    float4 a = wvSampleRow(waveTex, t, l0, cols, levels);
    float4 b = wvSampleRow(waveTex, t, min(l0 + 1.0, levels - 1.0), cols, levels);
    return lerp(a, b, lod - l0);
}

// Band energies / onset at clip time t (base resolution only — color varies
// slowly, no pyramid needed). Linear filter across columns.
inline float4 wvSampleFreq(sampler2D freqTex, float t, float cols)
{
    float x = t * cols - 0.5;
    float x0 = floor(x);
    float f = x - x0;
    float u0 = (clamp(x0, 0.0, cols - 1.0) + 0.5) / cols;
    float u1 = (clamp(x0 + 1.0, 0.0, cols - 1.0) + 0.5) / cols;
    float4 s0 = tex2Dlod(freqTex, float4(u0, 0.5, 0, 0));
    float4 s1 = tex2Dlod(freqTex, float4(u1, 0.5, 0, 0));
    return lerp(s0, s1, f);
}

// ── coloring ────────────────────────────────────────────────────────────────

// Three-stop centroid gradient: low → mid → high across centroid 0..1.
// NOTE: "centroid" itself is a reserved HLSL keyword — hence "spectralPos".
inline float3 wvCentroidColor(float spectralPos, float3 lowC, float3 midC, float3 highC)
{
    float3 a = lerp(lowC, midC, saturate(spectralPos * 2.0));
    return lerp(a, highC, saturate(spectralPos * 2.0 - 1.0));
}

// Energy-weighted band mix (the Traktor/Serato-style colored waveform): each
// band tints by its share of the column's energy; brightness follows total.
inline float3 wvBandMixColor(float3 bands, float3 lowC, float3 midC, float3 highC)
{
    float total = bands.x + bands.y + bands.z;
    float3 w = bands / max(total, 1e-4);
    float3 c = lowC * w.x + midC * w.y + highC * w.z;
    // Loud columns saturate toward the pure mix, quiet ones dim gently.
    return c * (0.55 + 0.45 * saturate(total));
}

// Mode dispatch: 0 = solid body color, 1 = centroid gradient, 2 = band mix.
inline float3 wvWaveColor(float colorMode, float spectralPos, float3 bands,
                          float3 bodyC, float3 lowC, float3 midC, float3 highC)
{
    if (colorMode < 0.5) return bodyC;
    if (colorMode < 1.5) return wvCentroidColor(spectralPos, lowC, midC, highC);
    return wvBandMixColor(bands, lowC, midC, highC);
}

#endif // SDF_WAVEFORM_INCLUDED
