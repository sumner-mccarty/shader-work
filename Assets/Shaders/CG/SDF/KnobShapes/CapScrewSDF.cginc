#ifndef SDF_KNOB_CAPSCREW_INCLUDED
#define SDF_KNOB_CAPSCREW_INCLUDED

// 18: CapScrew — circle with slot cuts (flat-head or Phillips screw cap)
// param1=slotWidth, param2=slotDepth, param3=Phillips (0=flathead, 1=Phillips cross)
float CapScrewSDF(float2 p, float radius, float slotW, float slotDepth, float phillips)
{
    float base = CircleSDF(p, radius);
    float sw   = lerp(0.04, 0.28, slotW)   * radius;
    float sd   = lerp(0.25, 0.98, slotDepth) * radius;
    float hSlot = RectangleSDF(p, float2(sd, sw));
    float result = max(base, -max(hSlot, -radius * 0.05));
    float vSlot  = RectangleSDF(p, float2(sw, sd));
    result = lerp(result, max(result, -max(vSlot, -radius * 0.05)), step(0.5, phillips));
    return result;
}

#endif
