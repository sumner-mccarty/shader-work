#ifndef SDF_KNOB_MUSHROOMCAP_INCLUDED
#define SDF_KNOB_MUSHROOMCAP_INCLUDED

// 13: MushroomCap — wide domed top + narrower stem (vintage guitar-amp knob profile)
// Rotated 90 deg CW: dome faces +x, stem extends -x.
// param1=capOverhang, param2=stemWidth, param3=stemLength
float MushroomCapSDF(float2 p, float radius, float capOvhg, float stemW, float stemLen)
{
    float2 q = float2(p.y, -p.x);
    float capR  = radius * lerp(1.0, 1.65, capOvhg);
    float capCY = radius * 0.32;
    float capDist  = CircleSDF(q + float2(0.0, capCY), capR);
    float capClip  = q.y - (-capCY * 0.6);
    float clippedCap = max(capDist, capClip);
    float sw = radius * lerp(0.08, 0.58, stemW);
    float sl = radius * lerp(0.15, 1.84, stemLen);
    float2 sCtr = float2(0.0, -capCY * 0.6 + sl * 0.5);
    float stemDist = RoundedRectSDF(q - sCtr, float2(sw, sl * 0.5), sw * 0.22);
    return min(clippedCap, stemDist);
}

#endif
