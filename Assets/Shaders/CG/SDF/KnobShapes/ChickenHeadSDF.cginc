#ifndef SDF_KNOB_CHICKENHEAD_INCLUDED
#define SDF_KNOB_CHICKENHEAD_INCLUDED

// 8: ChickenHead — round body + upward indicator handle (vintage Fender-style)
// param1=handleLength, param2=handleWidth, param3=handle-body blend radius
float ChickenHeadSDF(float2 p, float radius, float handleLen, float handleWidth, float blendR)
{
    float bodyDist = CircleSDF(p, radius * 0.72);
    float hLen  = radius * lerp(0.3, 1.5, handleLen);
    float hWid  = radius * lerp(0.06, 0.42, handleWidth);
    float blend = hWid * lerp(0.05, 0.75, blendR);
    float2 hCtr = float2(0.0, -(radius * 0.36 + hLen * 0.5));
    float handleDist = RoundedRectSDF(p - hCtr, float2(hWid, hLen * 0.5), blend);
    return min(bodyDist, handleDist);
}

#endif
