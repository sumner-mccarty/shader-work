#ifndef SDF_KNOB_FADERCAP_INCLUDED
#define SDF_KNOB_FADERCAP_INCLUDED

// 20: FaderCap — rounded-rect with a milled central groove
// param1=aspect ratio, param2=groove depth, param3=corner rounding
float FaderCapSDF(float2 p, float radius, float param1, float param2, float param3)
{
    float2 halfExt = float2(radius * lerp(0.5, 1.5, param1), radius);
    float cornerR  = param3 * radius * 0.25;
    float boxDist  = RoundedRectSDF(p, halfExt, cornerR);
    float grooveH    = radius * 0.08;
    float grooveHalf = param2 * radius * 0.5;
    float grooveDist = max(abs(p.y) - grooveH, abs(p.x) - grooveHalf);
    return max(boxDist, -grooveDist);
}

#endif
