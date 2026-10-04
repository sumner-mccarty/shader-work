#ifndef SDF_KNOB_BLOBSTAR_INCLUDED
#define SDF_KNOB_BLOBSTAR_INCLUDED

// 17: BlobStar — organic rounded star blended toward a circle
// shapeScale=numPoints, param1=innerRadius, param2=tipRounding, param3=circleBlend
float BlobStarSDF(float2 p, float radius, float pts, float innerRatio, float tipRound, float circleBlend)
{
    int n      = max(3, (int)pts);
    float inner = lerp(0.2, 0.78, innerRatio);
    float star  = StarSDF(p, radius, n, lerp(2.0, (float)n - 0.01, inner));
    float tip   = lerp(0.002, 0.1, tipRound) * radius;
    float soften = star - tip;
    float circ  = CircleSDF(p, radius * lerp(0.4, 0.9, innerRatio));
    float k = radius * 0.15;
    float h = saturate(0.5 + 0.5 * (circ - soften) / max(0.0001, k));
    float sUnion = lerp(circ, soften, h) - k * h * (1.0 - h);
    return lerp(soften, sUnion, circleBlend);
}

#endif
