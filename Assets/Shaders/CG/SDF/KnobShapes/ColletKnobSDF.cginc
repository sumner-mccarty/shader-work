#ifndef SDF_KNOB_COLLET_INCLUDED
#define SDF_KNOB_COLLET_INCLUDED

// 15: ColletKnob — circular knob with polygonal hub feature + optional knurled outer ring
// shapeScale=hub sides, param1=hubRadius, param2=hubDetail, param3=knurling
float ColletKnobSDF(float2 p, float radius, float hubSides, float hubRatio, float hubDetail, float knurling)
{
    float outer = CircleSDF(p, radius);
    float hubR   = radius * lerp(0.08, 0.40, hubRatio);
    float n      = max(3.0, hubSides);
    float hubDist = PolygonSDF(p, hubR, n, 0.0, 0.0, 0.0);
    float hubMask    = saturate(-hubDist / (hubR * 0.2 + 0.0001));
    float hubGroove  = hubMask * hubDetail * hubR * 0.35;
    float shape = outer + hubGroove;
    [branch]
    if (knurling > 0.01) {
        float dist  = length(p);
        float angle = atan2(p.y, p.x);
        float teeth = max(6.0, n * 3.0);
        float wave  = cos(angle * teeth);
        float knurlDepth = knurling * radius * 0.025;
        float knurlZone  = saturate((dist - radius * 0.75) / (radius * 0.25));
        shape -= wave * knurlDepth * knurlZone;
    }
    return shape;
}

#endif
