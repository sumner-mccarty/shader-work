#ifndef SDF_KNOB_TAPERDISC_INCLUDED
#define SDF_KNOB_TAPERDISC_INCLUDED

// 19: TaperDisc — circular disc with one side expanded (asymmetric)
// param1=taperAmount, param2=taperAngle (0-1 = 0-360 deg), param3=edgeRound
float TaperDiscSDF(float2 p, float radius, float taperAmt, float taperAngle, float edgeRound)
{
    float ang    = taperAngle * 2.0 * PI;
    float2 tapDir = float2(sin(ang), -cos(ang));
    float proj   = dot(p, tapDir);
    float expand = lerp(0.0, radius * 0.55, taperAmt);
    float localR = radius + expand * saturate(proj / max(0.001, radius));
    float circ   = length(p) - localR;
    return circ - lerp(0.0, radius * 0.06, edgeRound);
}

#endif
