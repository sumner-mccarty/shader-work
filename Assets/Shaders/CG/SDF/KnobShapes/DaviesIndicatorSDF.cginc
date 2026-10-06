#ifndef SDF_KNOB_DAVIESINDICATOR_INCLUDED
#define SDF_KNOB_DAVIESINDICATOR_INCLUDED

// 14: DaviesIndicator — round disc with a machined indicator slot
// param1=slotLength, param2=slotWidth, param3=slotCornerRounding
float DaviesIndicatorSDF(float2 p, float radius, float slotLen, float slotWidth, float slotRound)
{
    float base = CircleSDF(p, radius);
    float sl   = radius * lerp(0.25, 0.72, slotLen);
    float sw   = lerp(0.015, 0.08, slotWidth) * radius;
    float rnd  = lerp(0.0, sw * 0.5, slotRound);
    float2 slotCtr = float2(0.0, -sl * 0.5);
    float slotDist = RoundedRectSDF(p - slotCtr, float2(sw, sl * 0.5), rnd);
    return max(base, -slotDist);
}

#endif
