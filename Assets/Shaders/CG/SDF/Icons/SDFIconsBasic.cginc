#ifndef SDF_ICONS_BASIC_INCLUDED
#define SDF_ICONS_BASIC_INCLUDED

#include "../SDFPrimitives.cginc"
#include "../SDFOperations.cginc"

// Icon IDs for basic media controls
#define ICON_PLAY           1
#define ICON_PAUSE          2
#define ICON_STOP           3
#define ICON_RECORD         4
#define ICON_FAST_FORWARD   5
#define ICON_REWIND         6
#define ICON_SKIP_NEXT      7
#define ICON_SKIP_PREVIOUS  8
#define ICON_VOLUME_UP      9
#define ICON_VOLUME_DOWN    10
#define ICON_VOLUME_MUTE    11

// ----------------------
// Media Control Icons
// ----------------------

float PlayIconSDF(float2 p, float size)
{
    size = size * 0.8;
    float2 a = float2(-size * 0.3, -size * 0.4);
    float2 b = float2(-size * 0.3, size * 0.4);
    float2 c = float2(size * 0.4, 0);
    return TriangleSDF(p, a, b, c);
}

float PauseIconSDF(float2 p, float size)
{
    float bar1 = RoundedRectSDF(p - float2(-size * 0.15, 0), float2(0.08, 0.3) * size, 0.02 * size);
    float bar2 = RoundedRectSDF(p - float2(size * 0.15, 0), float2(0.08, 0.3) * size, 0.02 * size);
    return OpUnion(bar1, bar2);
}

float StopIconSDF(float2 p, float size)
{
    return RoundedRectSDF(p, float2(0.3, 0.3) * size, 0.05 * size);
}

float RecordIconSDF(float2 p, float size)
{
    return CircleSDF(p, size * 0.35);
}

float FastForwardIconSDF(float2 p, float size)
{
    size = size * 0.8;
    // Double right-pointing triangles
    float2 a1 = float2(-size * 0.4, -size * 0.3);
    float2 b1 = float2(-size * 0.4, size * 0.3);
    float2 c1 = float2(-size * 0.1, 0);
    float triangle1 = TriangleSDF(p, a1, b1, c1);
    
    float2 a2 = float2(-size * 0.1, -size * 0.3);
    float2 b2 = float2(-size * 0.1, size * 0.3);
    float2 c2 = float2(size * 0.4, 0);
    float triangle2 = TriangleSDF(p, a2, b2, c2);
    
    return OpUnion(triangle1, triangle2);
}

float RewindIconSDF(float2 p, float size)
{
    size = size * 0.8;
    // Double left-pointing triangles
    float2 a1 = float2(size * 0.4, -size * 0.3);
    float2 b1 = float2(size * 0.4, size * 0.3);
    float2 c1 = float2(size * 0.1, 0);
    float triangle1 = TriangleSDF(p, a1, b1, c1);
    
    float2 a2 = float2(size * 0.1, -size * 0.3);
    float2 b2 = float2(size * 0.1, size * 0.3);
    float2 c2 = float2(-size * 0.4, 0);
    float triangle2 = TriangleSDF(p, a2, b2, c2);
    
    return OpUnion(triangle1, triangle2);
}

float SkipNextIconSDF(float2 p, float size)
{
    size = size * 0.8;
    // Triangle with vertical bar
    float2 a = float2(-size * 0.3, -size * 0.3);
    float2 b = float2(-size * 0.3, size * 0.3);
    float2 c = float2(size * 0.2, 0);
    float tri = TriangleSDF(p, a, b, c);
    
    float bar = RoundedRectSDF(p - float2(size * 0.35, 0), float2(0.05, 0.3) * size, 0.025 * size);
    
    return OpUnion(tri, bar);
}

float SkipPreviousIconSDF(float2 p, float size)
{
    size = size * 0.8;
    // Triangle with vertical bar
    float2 a = float2(size * 0.3, -size * 0.3);
    float2 b = float2(size * 0.3, size * 0.3);
    float2 c = float2(-size * 0.2, 0);
    float tri = TriangleSDF(p, a, b, c);
    
    float bar = RoundedRectSDF(p - float2(-size * 0.35, 0), float2(0.05, 0.3) * size, 0.025 * size);
    
    return OpUnion(tri, bar);
}

float VolumeUpIconSDF(float2 p, float size)
{
    float2 pos = p / size;
    
    // Speaker cone
    float box = RoundedRectSDF(pos - float2(-0.25, 0), float2(0.08, 0.15), 0.02);
    
    // Trapezoid cone
    float2 conePos = pos - float2(-0.06, 0);
    float leftX = -0.11;
    float rightX = 0.11;
    float topLeft = 0.1;
    float topRight = 0.25;
    float botLeft = -0.1;
    float botRight = -0.25;
    
    float t = saturate((conePos.x - leftX) / (rightX - leftX));
    float topEdge = lerp(topLeft, topRight, t);
    float botEdge = lerp(botLeft, botRight, t);
    
    float cone = max(max(conePos.x - rightX, leftX - conePos.x),
                     max(conePos.y - topEdge, botEdge - conePos.y));
    
    // Sound waves
    float wave1 = abs(CircleSDF(pos - float2(0.1, 0), 0.12)) - 0.01;
    float wave2 = abs(CircleSDF(pos - float2(0.1, 0), 0.24)) - 0.01;
    float wave3 = abs(CircleSDF(pos - float2(0.1, 0), 0.36)) - 0.01;
    
    // Mask waves to right side
    float rightMask = -pos.x + 0.1;
    wave1 = OpIntersection(wave1, rightMask);
    wave2 = OpIntersection(wave2, rightMask);
    wave3 = OpIntersection(wave3, rightMask);
    
    // Angular mask for cone effect
    float2 wavePos = pos - float2(0.05, 0);
    float topAngleMask = dot(wavePos, normalize(float2(-1, 0.6)));
    float botAngleMask = dot(wavePos, normalize(float2(-1, -0.6)));
    
    wave1 = OpIntersection(wave1, OpIntersection(topAngleMask, botAngleMask));
    wave2 = OpIntersection(wave2, OpIntersection(topAngleMask, botAngleMask));
    wave3 = OpIntersection(wave3, OpIntersection(topAngleMask, botAngleMask));
    
    float speaker = OpUnion(box, cone);
    float waves = OpUnion(wave1, OpUnion(wave2, wave3));
    
    return OpUnion(speaker, waves);
}

float VolumeDownIconSDF(float2 p, float size)
{
    float2 pos = p / size;
    
    // Speaker cone (same as volume up)
    float box = RoundedRectSDF(pos - float2(-0.25, 0), float2(0.08, 0.15), 0.02);
    
    float2 conePos = pos - float2(-0.06, 0);
    float leftX = -0.11;
    float rightX = 0.11;
    float topLeft = 0.1;
    float topRight = 0.25;
    float botLeft = -0.1;
    float botRight = -0.25;
    
    float t = saturate((conePos.x - leftX) / (rightX - leftX));
    float topEdge = lerp(topLeft, topRight, t);
    float botEdge = lerp(botLeft, botRight, t);
    
    float cone = max(max(conePos.x - rightX, leftX - conePos.x),
                     max(conePos.y - topEdge, botEdge - conePos.y));
    
    // Only one wave for lower volume
    float wave1 = abs(CircleSDF(pos - float2(0.1, 0), 0.12)) - 0.01;
    
    float rightMask = -pos.x + 0.1;
    wave1 = OpIntersection(wave1, rightMask);
    
    float2 wavePos = pos - float2(0.05, 0);
    float topAngleMask = dot(wavePos, normalize(float2(-1, 0.6)));
    float botAngleMask = dot(wavePos, normalize(float2(-1, -0.6)));
    
    wave1 = OpIntersection(wave1, OpIntersection(topAngleMask, botAngleMask));
    
    float speaker = OpUnion(box, cone);
    
    return OpUnion(speaker, wave1);
}

float VolumeMuteIconSDF(float2 p, float size)
{
    float2 pos = p / size;
    
    // Speaker cone (same as volume icons)
    float box = RoundedRectSDF(pos - float2(-0.25, 0), float2(0.08, 0.15), 0.02);
    
    float2 conePos = pos - float2(-0.06, 0);
    float leftX = -0.11;
    float rightX = 0.11;
    float topLeft = 0.1;
    float topRight = 0.25;
    float botLeft = -0.1;
    float botRight = -0.25;
    
    float t = saturate((conePos.x - leftX) / (rightX - leftX));
    float topEdge = lerp(topLeft, topRight, t);
    float botEdge = lerp(botLeft, botRight, t);
    
    float cone = max(max(conePos.x - rightX, leftX - conePos.x),
                     max(conePos.y - topEdge, botEdge - conePos.y));
    
    float speaker = OpUnion(box, cone);
    
    // X mark for mute
    float line1 = RoundedRectSDF(OpRotate(pos - float2(0.2, 0), PI * 0.25), float2(0.15, 0.02), 0.01);
    float line2 = RoundedRectSDF(OpRotate(pos - float2(0.2, 0), -PI * 0.25), float2(0.15, 0.02), 0.01);
    float xMark = OpUnion(line1, line2);
    
    return OpUnion(speaker, xMark);
}

// ----------------------
// Icon Dispatcher for Basic Icons
// ----------------------

float GetBasicIconSDF(float2 p, int iconType, float size)
{
    switch (iconType)
    {
        case ICON_PLAY:
            return PlayIconSDF(p, size);
        case ICON_PAUSE:
            return PauseIconSDF(p, size);
        case ICON_STOP:
            return StopIconSDF(p, size);
        case ICON_RECORD:
            return RecordIconSDF(p, size);
        case ICON_FAST_FORWARD:
            return FastForwardIconSDF(p, size);
        case ICON_REWIND:
            return RewindIconSDF(p, size);
        case ICON_SKIP_NEXT:
            return SkipNextIconSDF(p, size);
        case ICON_SKIP_PREVIOUS:
            return SkipPreviousIconSDF(p, size);
        case ICON_VOLUME_UP:
            return VolumeUpIconSDF(p, size);
        case ICON_VOLUME_DOWN:
            return VolumeDownIconSDF(p, size);
        case ICON_VOLUME_MUTE:
            return VolumeMuteIconSDF(p, size);
        default:
            return 1000.0; // No icon
    }
}

#endif