#ifndef SDF_KNOB_GEAR_INCLUDED
#define SDF_KNOB_GEAR_INCLUDED

// 10: Gear — disc with sinusoidal teeth around perimeter
// shapeScale=tooth count. param1=toothHeight, param2=rootRounding, param3=toothWidth
float GearKnobSDF(float2 p, float radius, float count, float toothH, float rootRound, float toothW)
{
    float n       = max(4.0, count);
    float angle   = atan2(p.y, p.x);
    float step    = (2.0 * PI) / n;
    float local   = fmod(angle + PI + step * 0.5, step) - step * 0.5;
    float toothHt = radius * lerp(0.04, 0.24, toothH);
    float halfW   = step * lerp(0.15, 0.65, toothW) * 0.5;
    float inTooth = smoothstep(halfW, halfW - 0.015, abs(local));
    float rootR   = toothHt * lerp(0.0, 0.85, rootRound);
    float modR    = lerp(radius - toothHt + rootR, radius + toothHt * 0.25, inTooth);
    return length(p) - modR;
}

#endif
