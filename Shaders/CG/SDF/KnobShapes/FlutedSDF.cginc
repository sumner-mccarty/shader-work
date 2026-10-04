#ifndef SDF_KNOB_FLUTED_INCLUDED
#define SDF_KNOB_FLUTED_INCLUDED

// 6: Fluted cylinder — sinusoidal ridges around circumference
// param3=phaseOffset shifts the flute pattern angularly (0=no shift, 1=one full flute period)
float FlutedSDF(float2 p, float radius, float count, float depth, float sharpness, float phaseOffset)
{
    float n = max(2.0, count);
    float angle = atan2(p.y, p.x);
    float phase = phaseOffset * (2.0 * PI / n);
    float wave = cos(angle * n + phase);
    float profile = (sharpness < 0.01) ? (wave * 0.5 + 0.5)
        : pow(saturate(wave * 0.5 + 0.5), max(0.1, 1.0 + sharpness * 4.0));
    float modRadius = radius - profile * depth * radius * 0.4;
    return length(p) - modRadius;
}

#endif
