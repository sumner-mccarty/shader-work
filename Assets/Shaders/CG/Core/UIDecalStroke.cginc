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
            float sg = (ba.x * pa.y - ba.y * pa.x) >= 0.0 ? 1.0 : -1.0;
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

#endif // UI_DECAL_STROKE_INCLUDED
