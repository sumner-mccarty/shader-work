#ifndef SDF_KNOB_FADERCAPWIDE_INCLUDED
#define SDF_KNOB_FADERCAPWIDE_INCLUDED

// 21: FaderCapWide — wide rounded-rect with two screw holes
// param1=aspect ratio, param2=screw hole radius, param3=corner rounding
float FaderCapWideSDF(float2 p, float radius, float param1, float param2, float param3)
{
    float2 halfExt = float2(radius * lerp(1.0, 2.5, param1), radius * 0.5);
    float cornerR  = param3 * radius * 0.2;
    float boxDist  = RoundedRectSDF(p, halfExt, cornerR);
    float screwR   = param2 * radius * 0.15;
    if (screwR > 0.001) {
        float screwOff = halfExt.x * 0.7;
        float screwL   = CircleSDF(p + float2( screwOff, 0), screwR);
        float screwR2  = CircleSDF(p - float2( screwOff, 0), screwR);
        boxDist = max(boxDist, -min(screwL, screwR2));
    }
    return boxDist;
}

#endif
