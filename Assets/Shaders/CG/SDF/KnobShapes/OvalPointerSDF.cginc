#ifndef SDF_KNOB_OVALPOINTER_INCLUDED
#define SDF_KNOB_OVALPOINTER_INCLUDED

// 12: OvalPointer — upright ellipse with optional flat bottom cut
// param1=aspectRatio (0=circle, 1=tall 2x), param2=flatCut (0=none, 1=strong), param3=tipRounding
float OvalPointerSDF(float2 p, float radius, float aspect, float flatCut, float tipRound)
{
    float2 ab  = float2(radius, radius * lerp(1.0, 2.0, aspect));
    float oval = EllipseSDF(p, ab);
    float cutY = ab.y * lerp(1.5, 0.05, flatCut);
    float cut  = p.y - cutY;
    return max(oval, cut) - tipRound * radius * 0.10;
}

#endif
