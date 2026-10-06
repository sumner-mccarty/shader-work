#ifndef SDF_KNOB_GRIPNUBS_INCLUDED
#define SDF_KNOB_GRIPNUBS_INCLUDED

// 1: GripNubs — ridged cylinder edge
// numNubs=count, depth=nub height [5%-25% of radius], width=angular span [0=narrow, 1=wide], roundness=falloff softness
float gripNubsSDF(float2 p, float radius, int numNubs, float depth, float width, float roundness)
{
    float dist = length(p);
    float angle = atan2(p.y, p.x);
    float angleStep = (2.0 * PI) / max(1, numNubs);
    float localAngle = fmod(angle + PI, angleStep) - angleStep * 0.5;
    float nubDepth = radius * lerp(0.05, 0.25, depth);
    float nubWidth = angleStep * lerp(0.1, 0.5, width);
    float hardFactor = smoothstep(nubWidth, 0.0, abs(localAngle));
    float softFactor = cos(saturate(abs(localAngle) / max(0.0001, nubWidth)) * PI * 0.5);
    float nubFactor = lerp(hardFactor, softFactor, roundness);
    return dist - (radius - nubDepth * nubFactor);
}

#endif
