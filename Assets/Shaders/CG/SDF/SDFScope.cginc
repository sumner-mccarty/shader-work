// ============================================================================
// SDFScope.cginc — pure functions for the mixer "scope" displays (MixerDisplays.md)
// ============================================================================
// One reusable library backing SDFScope.shader. Every mixer device screen is a
// curve y=f(x) or a small set of impulses computed FROM the effect's own
// parameters, so turning a knob reshapes the picture. No uniforms, no state —
// each function takes what it needs, matching the CG/Core + CG/SDF architecture
// (same shape as SDFRhythmTrack.cginc).
//
// COORDINATE SPACE:
//   uv   quad space, (0,0) bottom-left .. (1,1) top-right.
//   x    horizontal 0..1 (time / input / log-frequency, per mode).
//   y    vertical   0..1, 0 = bottom, 1 = top. scEval returns y in 0..1.
//
// _Mode → what the screen draws, and what _P0.._P2 mean (the shader forwards
// them here as pa=_P0, pb=_P1):
//   0 ENVELOPE (ADSR)     pa=(attack,decay,sustain,release)
//   1 FREQ RESPONSE       pa=(hpCut,midFreq,lpCut,midGain) pb=(hpRes,lpRes,midQ,0)
//   2 COMP TRANSFER       pa=(threshold,makeup,0,0)   (∞:1 limiter — no ratio)
//   3 DIST TRANSFER       pa=(level,0,0,0)            (tanh soft→hard clip)
//   4 LFO (chorus)        pa=(rate,depth,phase,0)   voice arg = per-voice phase
//   5 COMB (flange)       pa=(depth,sweepPhase,0,0)
//   6 TAPS (echo)         pa=(delay,decay,mix,maxch)  (real-time tap train — special, in SDFScope.shader)
//   7 DECAY (reverb)      pa=(decay,density,phase,0) (exp tail area — special)
//   8 SPECTRUM backdrop   pa=(animPhase,0,0,0)       (analyzer stand-in — special)
// ============================================================================

#ifndef SDF_SCOPE_INCLUDED
#define SDF_SCOPE_INCLUDED

// ── anti-aliased primitives ──────────────────────────────────────────────────

// AA fill from a signed distance (1 inside, 0 outside, screen-width edge).
inline float scFill(float d)
{
    float aa = max(fwidth(d), 1e-5);
    return smoothstep(aa, -aa, d);
}

// AA line mask from a distance to the curve and a half-thickness (same units).
inline float scLine(float d, float halfThick)
{
    float aa = max(fwidth(d), 1e-5);
    return smoothstep(halfThick + aa, halfThick - aa, abs(d));
}

// Same, but with an explicit AA width — safe inside dynamic loops where fwidth
// (a gradient instruction) must be avoided.
inline float scLineAA(float d, float halfThick, float aa)
{
    return smoothstep(halfThick + aa, halfThick - aa, abs(d));
}

// Soft glow outside an SDF surface (1 at d=0, fading over `falloff`).
//
// This was exp(-|d|/falloff), and that `|d|` is where the hard-edged glow came from: the absolute
// value puts a CUSP at d = 0 — the slope flips sign across the curve — right where the glow is
// brightest, so the additive composite clipped along it and a bloom that should be smooth resolved
// into a flat core with a visible rim. A gaussian has zero slope at the centre instead, so the core
// rolls over rather than creasing; the second, much wider lobe carries a low-amplitude skirt far
// enough out that the halo never terminates at a visible boundary either.
inline float scGlow(float d, float falloff)
{
    float t = d / max(falloff, 1e-4);
    return exp(-t * t) * 0.74 + exp(-t * t * 0.09) * 0.26;
}

// A packet of signal running left→right across the picture and wrapping: the "audio going past"
// read. `head` is the leading edge in 0..1, `tail` how far the comet reaches behind it.
//
// It is deliberately ILLUMINATION ONLY. These screens are pictures of what the knobs are set to —
// a filter response, a transfer curve, a tap train — and displacing that geometry to look busy
// would make the display lie about the settings. So the shape stays exactly where the parameters
// put it and only the light travelling along it moves.
inline float scWave(float x, float head, float tail)
{
    float t = max(tail, 1e-3);
    float b = frac(head - x);                 // 0 at the head, → 1 going back
    // The decay behind the head, PLUS a short rise in front of it. Without the second term the
    // packet has a vertical cut at b = 1 → 0, and because the glow skirt is wide that cut shows
    // up as a hard seam running the full height of the display — a new hard edge in the middle of
    // the fix for hard edges. The two terms meet at ~1 on both sides of the wrap, so the packet
    // is continuous all the way round: a leading edge, not a cliff.
    return saturate(exp(-b / t) + exp(-(1.0 - b) / (t * 0.30)));
}

// Two packets half a cycle apart so the picture reads as a stream rather than one object sliding
// around. `amount` should already fold in BOTH engagement and live level — no audio, no ripple.
inline float scRipple(float x, float phase, float amount)
{
    float h = frac(phase);
    return amount * (scWave(x, h, 0.16) + 0.45 * scWave(x, frac(h + 0.5), 0.11));
}

// ── engagement grading ───────────────────────────────────────────────────────
//
// How much the module is actually doing to the sound: 0 = bypassed, or its mix/amount knob is at
// zero. A device that is doing nothing should LOOK like it is doing nothing.
//
// Dimming alone is not enough, because not every screen's signal is BRIGHTER than its field — the
// LCD finish draws a dark curve on a pale one, and dimming that only increases its contrast. So the
// off state desaturates and pulls the signal toward the display's own background: contrast falls
// away in whichever direction that particular screen's contrast happens to run.
inline float3 scEngage(float3 col, float3 bg, float lit)
{
    float3 grey = dot(col, float3(0.299, 0.587, 0.114)).xxx;
    float3 off  = lerp(lerp(col, grey, 0.80), bg, 0.55);
    return lerp(off, col, saturate(lit));
}

// Emissive/glow scale for the same engagement. Never quite zero: an in-circuit module with the mix
// down is still a lit instrument, just an idle one.
inline float scLitGain(float lit) { return 0.20 + 0.80 * saturate(lit); }

// Distance from p to segment a→b (classic).
inline float scSeg(float2 p, float2 a, float2 b)
{
    float2 pa = p - a, ba = b - a;
    float h = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-6));
    return length(pa - ba * h);
}

// Premultiplied "over" and additive compositors.
inline void scOver(inout float4 acc, float3 rgb, float a)
{
    a = saturate(a);
    acc.rgb = acc.rgb * (1.0 - a) + rgb * a;
    acc.a   = acc.a   * (1.0 - a) + a;
}
// Additive light with a SOFT SHOULDER.
//
// `acc.rgb += rgb` stops dead at 1.0, and that clip boundary is a hard edge sitting in the middle
// of what is supposed to be a smooth bloom — the other half of the hard-edged-glow problem (see
// scGlow). Below the knee this is still exact addition; above it the light compresses toward 1
// asymptotically, so a bright core fades into its halo continuously instead of ending at a flat
// white plateau with a rim. The alpha term is weakened for the same reason: a wide faint glow was
// making a wide region of the quad fully opaque.
inline void scAdd(inout float4 acc, float3 rgb)
{
    const float k = 0.70;
    float3 hi = acc.rgb + max(rgb, 0.0);
    acc.rgb = min(hi, k + (1.0 - k) * (1.0 - exp(-max(hi - k, 0.0) / (1.0 - k))));
    acc.a    = saturate(acc.a + max(max(rgb.r, rgb.g), rgb.b) * 0.6);
}

// ── signal evaluators (each returns y in 0..1) ───────────────────────────────

// RAW ADSR amplitude 0..1 at time x (MixerDisplays.md). attack ramps 0→peak, decay
// falls from peak to sustain, plateau, release tails to 0. The breakpoint widths go
// to ZERO at knob 0, so attack=0 rises vertically at the left edge and release=0
// drops vertically at the right edge (user items 3.3/3.4). `peak` (ENV7's "PK" knob,
// carried on _P1.x — attack height, user item 7 of the ENV7 pass) defaults to 1.0 for
// the classic full-height ramp. Used both for the mirrored waveform carrier and,
// padded, for the outline.
// p = (attackFrac, decayFrac, sustainLevel, releaseFrac) — the A/D/R widths are FRACTIONS OF THE
// DISPLAYED DURATION, computed by MixerPanel from the envelope's real SECONDS divided by the
// trimmed clip's real playback duration. That makes the drawn envelope line up exactly with the
// audio the sampler applies (previously the display used its own arbitrary 0.30/0.26/0.34 width
// mapping, so the picture cut long before/after the sound actually did). Widths of 0 give the
// vertical rise/fall at the edges.
inline float scEnvAmp(float x, float4 p, float peak)
{
    float pk = saturate(peak);
    float fA = saturate(p.x);            // attack ends here
    float fD = saturate(fA + p.y);       // decay ends here
    float sL = saturate(p.z);            // sustain level
    float rW = saturate(p.w);            // release width
    float fS = max(fD, 1.0 - rW);        // release starts here
    float amp;
    if (x < fA)      amp = (x / max(fA, 1e-5)) * pk;
    else if (x < fD) amp = pk - (pk - sL) * (x - fA) / max(fD - fA, 1e-5);
    else if (x < fS) amp = sL;
    else             amp = max(0.0, sL * (1.0 - (x - fS) / max(1.0 - fS, 1e-5)));
    return saturate(amp);
}

// Envelope OUTLINE y, padded into 0.08..0.92 (bottom-anchored) for scEval/handles.
// (Currently unreachable in SDFScope.shader — mode 0 is special-cased directly with
// its own mirrored-waveform rendering — kept for API completeness / future reuse.)
inline float scEnvelope(float x, float4 p)
{
    return 0.08 + scEnvAmp(x, p, 1.0) * 0.84;
}

// Composite HP + peaking-EQ + LP response. x is the log-freq axis (0=20Hz,1=20kHz);
// corner/centre knob positions live on the same axis. pb = (hpRes, lpRes, midQ, 0),
// all 0..1. Returns y around 0.5 (0 dB), +/- up to ~18 dB mapped into the frame.
// Resonance (pb.x/pb.y) adds a peak right at each corner so the res knobs reshape
// the curve (user item 7.3); midQ (pb.z) narrows the EQ bell.
inline float scFreqResp(float x, float4 pa, float4 pb)
{
    float hpX = pa.x, midX = pa.y, lpX = pa.z;
    float hpRes = pb.x, lpRes = pb.y;
    float midDb = (pa.w - 0.5) * 24.0;          // -12..+12 dB
    float bw = 0.02 + (1.0 - pb.z) * 0.13;       // bell width from Q

    // RESONANCE primarily steepens the ROLLOFF — turning it up swings the cut toward vertical,
    // which is the useful, readable thing to see. (A real resonant filter also lifts a peak right
    // at the corner, so a restrained bump is kept for honesty rather than the tall spike this
    // used to draw; Unity exposes Resonance, not a slope order, so the peak IS part of the truth.)
    float hpSlope = 60.0 + hpRes * 200.0;
    float lpSlope = 60.0 + lpRes * 200.0;
    float hpDb = -clamp((hpX - x) * hpSlope, 0.0, 36.0);
    float lpDb = -clamp((x - lpX) * lpSlope, 0.0, 36.0);

    float e = (x - midX) / bw;
    float bell = midDb * exp(-e * e);
    float hpPk = hpRes * 5.0 * exp(-pow((x - hpX) / 0.02, 2.0));
    float lpPk = lpRes * 5.0 * exp(-pow((x - lpX) / 0.02, 2.0));

    float db = clamp(hpDb + lpDb + bell + hpPk + lpPk, -36.0, 18.0);
    return saturate(0.5 + db / 18.0 * 0.42);
}

// Limiter transfer: unity slope below threshold, flat above (∞:1 soft knee), lifted
// by makeup. p = (threshold, makeup, attack, release), all 0..1. Attack widens the
// knee (softer bend) and release adds a small recovery dip at the threshold, so the
// two time knobs visibly reshape the curve too (user item 8.1).
inline float scCompTransfer(float x, float4 p)
{
    float thr = p.x, mk = p.y, atk = p.z, rel = p.w;
    float knee = 0.015 + atk * 0.22;                 // attack → softer knee
    float over = x - thr;
    // softplus knee: smoothly bends from unity slope to flat around the threshold.
    float above = 0.5 * (over + sqrt(over * over + knee * knee));
    float y = x - above + mk * 0.35;                 // flat past the (soft) knee
    y -= rel * 0.05 * exp(-pow((x - thr) / 0.12, 2.0)); // release recovery dip
    return saturate(0.06 + y * 0.88);
}

// Distortion transfer: tanh soft→hard clip. x 0..1 → input -1..1 → output -1..1 → y.
inline float scDistTransfer(float x, float4 p)
{
    float k = 1.0 + p.x * 9.0;
    float xin = x * 2.0 - 1.0;
    float yv = tanh(xin * k) / tanh(k);
    return saturate(0.5 + yv * 0.42);
}

// LFO voice: sine of amplitude=depth, cycles=rate, offset by `phase`+`voice`.
inline float scLFO(float x, float4 p, float voice)
{
    float rate = p.x, depth = p.y, phase = p.z;
    float cyc = 1.0 + rate * 3.0;
    return 0.5 + (0.15 + depth * 0.32) * sin(x * cyc * 6.28318 + phase + voice);
}

// Comb magnitude response (flange). p = (rate, depth, mix, 0). The notches get
// TIGHTER toward the right (x²) so the repeats visibly accelerate rather than being
// uniform (user item 10.2 — a flange sweep, not a phaser); rate sets the count.
inline float scComb(float x, float4 p)
{
    float rate = p.x, depth = p.y;
    // Count and acceleration both pulled back (was 3..14 notches at x²). On a 120px-wide module
    // that packed the right-hand third below one notch per pixel, where a curve stops being a
    // curve and aliases into a solid slab — which, with the glow on top, is what made the flange
    // screen a white-green block instead of a sweep. 2..9 at x^1.6 stays resolvable across the
    // whole width at every rate.
    float notches = 2.0 + rate * 7.0;
    float ph = pow(x, 1.6);              // accelerating spacing
    // Amplitude capped so depth=1 still clears the frame (line thickness + glow need headroom).
    return 0.5 + (0.10 + 0.28 * depth) * cos(ph * notches * 6.28318);
}

// Reverb decay envelope (for the filled tail area). x=time, length from decay.
inline float scDecay(float x, float4 p)
{
    float k = 3.0 + p.x * 8.0;
    return 0.06 + exp(-x * 9.0 / k) * 0.86;
}

// Dispatch: y in 0..1 for the curve modes (0-5,7). Special modes handled in-shader.
inline float scEval(int mode, float x, float4 pa, float4 pb, float voice)
{
    if (mode == 0) return scEnvelope(x, pa);
    if (mode == 1) return scFreqResp(x, pa, pb);
    if (mode == 2) return scCompTransfer(x, pa);
    if (mode == 3) return scDistTransfer(x, pa);
    if (mode == 4) return scLFO(x, pa, voice);
    if (mode == 5) return scComb(x, pa);
    if (mode == 7) return scDecay(x, pa);
    return 0.5;
}

// Approx signed distance (in y-units) from the fragment to the curve y=f(x),
// corrected by the local slope so the drawn line keeps constant screen thickness
// on steep sections. Central difference for the slope.
inline float scCurveDist(int mode, float2 uv, float4 pa, float4 pb, float voice)
{
    float h = 0.5 * max(fwidth(uv.x), 1e-4);
    float y0 = scEval(mode, uv.x, pa, pb, voice);
    float yl = scEval(mode, uv.x - h, pa, pb, voice);
    float yr = scEval(mode, uv.x + h, pa, pb, voice);
    float slope = (yr - yl) / max(2.0 * h, 1e-4);
    float dv = uv.y - y0;
    return dv / sqrt(1.0 + slope * slope);
}

// procedural 0..1 hash for the spectrum backdrop stand-in.
inline float scHash(float n) { return frac(sin(n) * 43758.5453); }

#endif // SDF_SCOPE_INCLUDED
