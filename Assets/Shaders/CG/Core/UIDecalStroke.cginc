#ifndef UI_DECAL_STROKE_INCLUDED
#define UI_DECAL_STROKE_INCLUDED

// ============================================================================
// UIDecalStroke.cginc — the point scheme + spline distance for DecalSpray / DecalBrush (2026-10-08)
// ============================================================================
// Used ONLY by UI/Decal/Spray and UI/Decal/Brush (the paint-layer generators of Docs/UiDecals.md §3.1).
// NOT included by any widget shader, so no widget compile budget is touched.
//
// THE POINT SCHEME. A stroke is up to six points `_P0.._P5`, each a float4 (x, y, pressure, unused) in the
// decoration's uv (0..1, v up, a square quad), and `_PointCount` (1..6) says how many are live. The path is a
// uniform Catmull-Rom spline THROUGH the points (it touches every one); pressure is interpolated linearly
// along it. One point is a single dab.
//
// dcStroke() returns, for a uv position, the distance to the path, the arc parameter of the nearest point
// (0 at the first point, 1 at the last), the pressure there and which SIDE of the path the position is on
// (+1 left of the direction of travel, -1 right) — the brush needs the signed lateral coordinate. The spline is evaluated as 6 straight pieces
// per span (5 spans = 30 pieces, fixed [unroll], branch-free), which is smooth at any decoration size.
// ============================================================================

float4 _P0, _P1, _P2, _P3, _P4, _P5;
float _PointCount;

float2 dcCR(float2 p0, float2 p1, float2 p2, float2 p3, float t)
{
    float t2 = t * t;
    float t3 = t2 * t;
    return 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3);
}

// Which side of the path a point is on (+1 left of travel). Against the piece's own direction — except at the
// piece's START corner (h = 0), where the point sits in the fan between this piece and the previous one: there
// the piece's own line can put a point on the outside of a bend on the wrong side, so the corner uses the
// average of the two directions (the bisector). Without this, left/right flip in the fan round every bend.
float dcSide(float2 off, float2 dir, float2 prevDir, float h)
{
    float2 t = dir / max(length(dir), 1e-8);
    float2 tp = prevDir / max(length(prevDir), 1e-8);
    float2 tb = (dot(prevDir, prevDir) > 1e-12) ? (t + tp) : t;
    float2 tan = (h <= 1e-4) ? tb : t;
    return (tan.x * off.y - tan.y * off.x) >= 0.0 ? 1.0 : -1.0;
}

void dcStroke(float2 uv, out float dist, out float arc, out float pres, out float side)
{
    float cnt = clamp(_PointCount, 1.0, 6.0);
    // pad the tail with the last live point so every span has four valid neighbours
    float3 last = _P0.xyz;
    last = lerp(last, _P1.xyz, step(1.5, cnt));
    last = lerp(last, _P2.xyz, step(2.5, cnt));
    last = lerp(last, _P3.xyz, step(3.5, cnt));
    last = lerp(last, _P4.xyz, step(4.5, cnt));
    last = lerp(last, _P5.xyz, step(5.5, cnt));
    float3 pt[6];
    pt[0] = _P0.xyz;
    pt[1] = lerp(last, _P1.xyz, step(1.5, cnt));
    pt[2] = lerp(last, _P2.xyz, step(2.5, cnt));
    pt[3] = lerp(last, _P3.xyz, step(3.5, cnt));
    pt[4] = lerp(last, _P4.xyz, step(4.5, cnt));
    pt[5] = lerp(last, _P5.xyz, step(5.5, cnt));

    dist = 1000.0;
    arc = 0.0;
    pres = pt[0].z;
    side = 1.0;
    float spans = max(cnt - 1.0, 1.0);
    float2 prevDir = float2(0.0, 0.0);

    [unroll]
    for (int s = 0; s < 5; s++)
    {
        float3 a = pt[max(s - 1, 0)];
        float3 b = pt[s];
        float3 c = pt[s + 1];
        float3 d = pt[min(s + 2, 5)];
        // span s exists when s < count - 1; span 0 always exists (a lone point is a zero-length span)
        float live = (s == 0) ? 1.0 : step(0.5, cnt - 1.0 - (float)s);
        float2 prev = dcCR(a.xy, b.xy, c.xy, d.xy, 0.0);
        [unroll]
        for (int j = 0; j < 6; j++)
        {
            float t1 = ((float)j + 1.0) / 6.0;
            float2 nxt = dcCR(a.xy, b.xy, c.xy, d.xy, t1);
            float2 pa = uv - prev;
            float2 ba = nxt - prev;
            float h = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-8));
            float dd = length(pa - ba * h);
            float sg = dcSide(pa - ba * h, ba, prevDir, h);
            prevDir = ba;
            float tt = ((float)j + h) / 6.0;                          // 0..1 along this span
            float better = step(dd, dist) * live;
            dist = lerp(dist, dd, better);
            arc = lerp(arc, ((float)s + tt) / spans, better);
            pres = lerp(pres, lerp(b.z, c.z, tt), better);
            side = lerp(side, sg, better);
            prev = nxt;
        }
    }
}

// dcStrokeSmooth() — dcStroke() with arc made CONTINUOUS across bends. Where the stroke turns tighter than its
// own width, the nearest piece of the path switches abruptly across a seam through the bend, so `arc` (and all a
// shader derives from it — strand wander, ragged-edge noise) jumps there: notches in the outline and chevron
// seams in the streaks. dist and side stay exact (the outline is the true distance). A seam is where the
// distance-along-the-path has TWO dips (one per leg of the bend), so the nearest piece is paired with the best
// OTHER local minimum of distance, if any, and the two blend 50/50 on the seam, fading back to the nearest within
// `soft` (uv units). A straight or gently curving stroke has a single dip and is returned exactly as dcStroke
// gives it. The blend is symmetric (each side of the seam swaps the roles), so the result is continuous.
void dcStrokeSmooth(float2 uv, float soft, out float dist, out float arc, out float pres, out float side)
{
    float cnt = clamp(_PointCount, 1.0, 6.0);
    float3 last = _P0.xyz;
    last = lerp(last, _P1.xyz, step(1.5, cnt));
    last = lerp(last, _P2.xyz, step(2.5, cnt));
    last = lerp(last, _P3.xyz, step(3.5, cnt));
    last = lerp(last, _P4.xyz, step(4.5, cnt));
    last = lerp(last, _P5.xyz, step(5.5, cnt));
    float3 pt[6];
    pt[0] = _P0.xyz;
    pt[1] = lerp(last, _P1.xyz, step(1.5, cnt));
    pt[2] = lerp(last, _P2.xyz, step(2.5, cnt));
    pt[3] = lerp(last, _P3.xyz, step(3.5, cnt));
    pt[4] = lerp(last, _P4.xyz, step(4.5, cnt));
    pt[5] = lerp(last, _P5.xyz, step(5.5, cnt));
    float spans = max(cnt - 1.0, 1.0);

    // every piece's distance, arc and pressure (dead spans get a huge distance)
    float dA[30], aA[30], pA[30];
    dist = 1000.0; arc = 0.0; pres = pt[0].z; side = 1.0;
    float best = 0.0;
    float2 prevDir = float2(0.0, 0.0);
    [unroll]
    for (int s = 0; s < 5; s++)
    {
        float3 a = pt[max(s - 1, 0)]; float3 b = pt[s]; float3 c = pt[s + 1]; float3 d = pt[min(s + 2, 5)];
        float live = (s == 0) ? 1.0 : step(0.5, cnt - 1.0 - (float)s);
        float2 prev = dcCR(a.xy, b.xy, c.xy, d.xy, 0.0);
        [unroll]
        for (int j = 0; j < 6; j++)
        {
            float2 nxt = dcCR(a.xy, b.xy, c.xy, d.xy, ((float)j + 1.0) / 6.0);
            float2 pa = uv - prev; float2 ba = nxt - prev;
            float h = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-8));
            float dd = lerp(1000.0, length(pa - ba * h), live);
            float sg = dcSide(pa - ba * h, ba, prevDir, h);
            prevDir = ba;
            float tt = ((float)j + h) / 6.0;
            int k = s * 6 + j;
            dA[k] = dd; aA[k] = ((float)s + tt) / spans; pA[k] = lerp(b.z, c.z, tt);
            float better = step(dd, dist);
            dist = lerp(dist, dd, better);
            arc = lerp(arc, aA[k], better);
            pres = lerp(pres, pA[k], better);
            side = lerp(side, sg, better);
            best = lerp(best, (float)k, better);
            prev = nxt;
        }
    }

    // the best OTHER local minimum of distance along the path (a second leg), not adjacent to the nearest
    float dist2 = 1000.0, arc2 = arc, pres2 = pres;
    [unroll]
    for (int i = 0; i < 30; i++)
    {
        float dl = (i > 0) ? dA[max(i - 1, 0)] : 1000.0;
        float dr = (i < 29) ? dA[min(i + 1, 29)] : 1000.0;
        float isMin = step(dA[i], dl) * step(dA[i], dr);
        float far = step(1.5, abs((float)i - best));
        float better = step(dA[i], dist2) * isMin * far;
        dist2 = lerp(dist2, dA[i], better);
        arc2 = lerp(arc2, aA[i], better);
        pres2 = lerp(pres2, pA[i], better);
    }

    float blend = 0.5 * (1.0 - smoothstep(0.0, max(soft, 1e-5), dist2 - dist));
    arc = lerp(arc, arc2, blend);
    pres = lerp(pres, pres2, blend);
}

#endif // UI_DECAL_STROKE_INCLUDED
