#ifndef SDF_KNOB_POLYGON_INCLUDED
#define SDF_KNOB_POLYGON_INCLUDED

// 2: Regular polygon SDF (n sides)
// rounding=corner radius [0-1 of radius], edgeArc=mid-edge arc magnitude, arcDir=0 outward / 1 inward
float PolygonSDF(float2 p, float radius, float sides, float rounding, float edgeArc, float arcDir)
{
    float n = max(3.0, sides);
    float an = PI / n;
    float bn = fmod(atan2(p.x, p.y) + 2.0 * PI, 2.0 * an) - an;
    float2 q = length(p) * float2(cos(bn), abs(sin(bn)));
    float2 acs = float2(cos(an), sin(an)) * radius;
    float2 delta = q - acs;
    delta.y += clamp(-delta.y, 0.0, acs.y);
    float d = length(delta) * sign(delta.x);
    [branch]
    if (edgeArc > 0.001) {
        float edgePhase = saturate(1.0 - abs(bn) / an);
        float arcBump   = edgeArc * radius * 0.15 * edgePhase * edgePhase;
        float arcSign   = (arcDir > 0.5) ? 1.0 : -1.0;
        d -= arcSign * arcBump;
    }
    return d - rounding * radius * 0.15;
}

#endif
