#ifndef SDF_KNOB_ARROW_INCLUDED
#define SDF_KNOB_ARROW_INCLUDED

// 9: Arrow — arrowhead + rectangular tail, pointing up (-y direction)
// param1=headWidth, param2=tailWidth, param3=tailLength
float ArrowKnobSDF(float2 p, float radius, float headW, float tailW, float tailLen)
{
    float hw   = radius * lerp(0.28, 0.96, headW);
    float tw   = radius * lerp(0.04, 0.42, tailW);
    float tl   = radius * lerp(0.12, 0.82, tailLen);
    float2 tip = float2(0.0, -radius);
    float2 bL  = float2(-hw,  0.0);
    float2 bR  = float2( hw,  0.0);
    float headDist = TriangleSDF(p, tip, bL, bR);
    float2 tCtr    = float2(0.0, tl * 0.5);
    float tailDist = RectangleSDF(p - tCtr, float2(tw, tl * 0.5));
    float k = radius * 0.08;
    float h = saturate(0.5 + 0.5 * (tailDist - headDist) / k);
    return lerp(tailDist, headDist, h) - k * h * (1.0 - h);
}

#endif
