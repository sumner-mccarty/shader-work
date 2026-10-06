#ifndef SDF_KNOB_SQUIRCLE_INCLUDED
#define SDF_KNOB_SQUIRCLE_INCLUDED

// 5: Squircle (superellipse) — param1=squareness (0=circle, 1=square), param2=x-squeeze
float SquircleSDF(float2 p, float radius, float squareness, float xSqueeze)
{
    float n = lerp(2.0, 20.0, saturate(squareness));
    float px_scale = lerp(1.0, 0.6, saturate(xSqueeze));
    float px = pow(abs(p.x / (radius * px_scale)), n) + pow(abs(p.y / radius), n);
    return (pow(max(0.0001, px), 1.0 / n) - 1.0) * radius;
}

#endif
