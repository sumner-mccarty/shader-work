#ifndef SDF_KNOB_DSHAFT_INCLUDED
#define SDF_KNOB_DSHAFT_INCLUDED

// 3: D-shaft — circle with a flat chord cut from one side
// param1=flat cut depth, param2=rounding, param3=corner rounding
float DShaftSDF(float2 p, float radius, float cutDepth, float rounding, float cornerRound)
{
    float circleDist = CircleSDF(p, radius);
    float cutY = radius * (1.0 - saturate(cutDepth) * 1.5);
    float cutDist = cutY - p.y;
    float base = max(circleDist, -cutDist) - rounding * radius * 0.2;
    if (cornerRound > 0.001) {
        float cr = cornerRound * radius * 0.18;
        base = base - cr * saturate(-base / (cr + 0.0001)) * saturate(-base / (cr + 0.0001));
    }
    return base;
}

#endif
