#ifndef SDF_KNOB_SKIRTED_INCLUDED
#define SDF_KNOB_SKIRTED_INCLUDED

// 11: SkirtedKnob — circular knob with transparent groove ring separating cap from skirt
// param1=cap radius ratio, param2=groove width, param3=groove width multiplier
float SkirtedKnobSDF(float2 p, float radius, float capRatio, float grooveWidth, float grooveDepth)
{
    float capR   = radius * lerp(0.30, 0.65, capRatio);
    float halfGW = lerp(0.01, 0.05, grooveWidth) * radius * (1.0 + grooveDepth * 2.0);
    float capDist   = CircleSDF(p, capR - halfGW);
    float skirtDist = max(CircleSDF(p, radius), -(CircleSDF(p, capR + halfGW)));
    return min(capDist, skirtDist);
}

#endif
