#ifndef SDF_KNOB_RINGPOINTER_INCLUDED
#define SDF_KNOB_RINGPOINTER_INCLUDED

// 16: RingPointer — thin ring with solid indicator tab
// Rotated 90 deg CW so tab projects to +x.
// param1=ringThickness, param2=tabWidth, param3=tabLength
float RingPointerSDF(float2 p, float radius, float thickness, float tabW, float tabLen)
{
    float2 q = float2(p.y, -p.x);
    float thick   = lerp(0.03, 0.38, thickness) * radius;
    float innerR  = radius - thick;
    float ringDist = abs(CircleSDF(q, innerR + thick * 0.5)) - thick * 0.5;
    float tw = lerp(0.02, 0.22, tabW)  * radius;
    float tl = lerp(0.08, 0.65, tabLen) * radius;
    float2 tCtr = float2(0.0, -(innerR - tl * 0.3));
    float tabDist = RoundedRectSDF(q - tCtr, float2(tw, tl * 0.5), tw * 0.35);
    float k = radius * 0.05;
    float h = saturate(0.5 + 0.5 * (tabDist - ringDist) / k);
    return lerp(tabDist, ringDist, h) - k * h * (1.0 - h);
}

#endif
