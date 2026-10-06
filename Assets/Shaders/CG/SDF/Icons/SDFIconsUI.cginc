#ifndef SDF_ICONS_UI_INCLUDED
#define SDF_ICONS_UI_INCLUDED

#include "../SDFPrimitives.cginc"
#include "../SDFOperations.cginc"

// Icon IDs for UI elements
#define ICON_HAMBURGER      20
#define ICON_CLOSE          21
#define ICON_INFO           22
#define ICON_SETTINGS       23
#define ICON_DOWNLOAD       24
#define ICON_UPLOAD         25
#define ICON_REFRESH        26
#define ICON_HOME           27
#define ICON_SEARCH         28
#define ICON_PLUS           29
#define ICON_MINUS          30
#define ICON_CHECK          31
#define ICON_ARROW_UP       32
#define ICON_ARROW_DOWN     33
#define ICON_ARROW_LEFT     34
#define ICON_ARROW_RIGHT    35
#define ICON_CARET_UP       36
#define ICON_CARET_DOWN     37
#define ICON_CARET_LEFT     38
#define ICON_CARET_RIGHT    39

// ----------------------
// Navigation and Menu Icons
// ----------------------

float HamburgerIconSDF(float2 p, float size)
{
    size = size * 1.5;
    float line1 = RoundedRectSDF(p - float2(0, size * 0.15), float2(0.25, 0.03) * size, 0.015 * size);
    float line2 = RoundedRectSDF(p, float2(0.25, 0.03) * size, 0.015 * size);
    float line3 = RoundedRectSDF(p - float2(0, -size * 0.15), float2(0.25, 0.03) * size, 0.015 * size);
    return OpUnion(line1, OpUnion(line2, line3));
}

float CloseIconSDF(float2 p, float size)
{
    float line1 = RoundedRectSDF(OpRotate(p, PI * 0.25), float2(0.3, 0.04) * size, 0.02 * size);
    float line2 = RoundedRectSDF(OpRotate(p, -PI * 0.25), float2(0.3, 0.04) * size, 0.02 * size);
    return OpUnion(line1, line2);
}

float InfoIconSDF(float2 p, float size)
{
    float circle = abs(CircleSDF(p, size * 0.35)) - size * 0.03;
    float dotShape = CircleSDF(p - float2(0, size * 0.18), size * 0.04);
    float lineShape = RoundedRectSDF(p - float2(0, -size * 0.08), float2(0.04, 0.15) * size, 0.02 * size);
    float inside = OpUnion(dotShape, lineShape);
    return OpUnion(circle, inside);
}

float SettingsIconSDF(float2 p, float size)
{
    // Gear-like shape using multiple circles and rectangles
    float center = CircleSDF(p, size * 0.15);
    float outer = CircleSDF(p, size * 0.35);
    float ring = OpSubtraction(center, outer);
    
    // Add teeth around the gear
    float teeth = 1000.0;
    for (int i = 0; i < 8; i++)
    {
        float angle = float(i) * PI * 0.25;
        float2 toothPos = float2(cos(angle), sin(angle)) * size * 0.4;
        float tooth = RoundedRectSDF(p - toothPos, float2(0.08, 0.06) * size, 0.02 * size);
        teeth = OpUnion(teeth, tooth);
    }
    
    return OpUnion(ring, teeth);
}

float DownloadIconSDF(float2 p, float size)
{
    size = size * 1.5;
    float2 a = float2(-size * 0.2, -size * 0.1);
    float2 b = float2(size * 0.2, -size * 0.1);
    float2 c = float2(0, size * 0.2);
    float arrow = TriangleSDF(p, a, b, c);
    float shaft = RoundedRectSDF(p - float2(0, -size * 0.25), float2(0.25, 0.03) * size, 0.015 * size);
    return OpUnion(arrow, shaft);
}

float UploadIconSDF(float2 p, float size)
{
    size = size * 1.5;
    float2 a = float2(-size * 0.2, size * 0.1);
    float2 b = float2(size * 0.2, size * 0.1);
    float2 c = float2(0, -size * 0.2);
    float arrow = TriangleSDF(p, a, b, c);
    float shaft = RoundedRectSDF(p - float2(0, size * 0.25), float2(0.25, 0.03) * size, 0.015 * size);
    return OpUnion(arrow, shaft);
}

float RefreshIconSDF(float2 p, float size)
{
    size = size * 1.2;
    float2 pos = p / size;
    
    // Main circular ring
    float outerCircle = CircleSDF(pos, 0.3);
    float innerCircle = CircleSDF(pos, 0.2);
    float ring = OpSubtraction(innerCircle, outerCircle);
    
    // Remove top-left quadrant 
    float topLeftCut = RoundedRectSDF(pos - float2(-0.15, 0.15), float2(0.2, 0.2), 0.05);
    float openRing = OpSubtraction(topLeftCut, ring);
    
    // Arrow head at the end of the arc
    float2 arrowCenter = float2(0.02, 0.235);
    float2 arrowTip = arrowCenter + float2(-0.15, -0.0);
    float2 arrowBack1 = arrowCenter + float2(0.05, -0.1);
    float2 arrowBack2 = arrowCenter + float2(0.05, 0.1);
    float arrowHead = TriangleSDF(pos, arrowTip, arrowBack1, arrowBack2);
    
    return OpUnion(openRing, arrowHead);
}

float HomeIconSDF(float2 p, float size)
{
    // House shape
    float2 roofA = float2(-size * 0.3, 0);
    float2 roofB = float2(size * 0.3, 0);
    float2 roofC = float2(0, size * 0.25);
    float roof = TriangleSDF(p, roofA, roofB, roofC);
    
    float house = RoundedRectSDF(p - float2(0, -size * 0.15), float2(0.25, 0.2) * size, 0.02 * size);
    
    // Door
    float door = RoundedRectSDF(p - float2(0, -size * 0.25), float2(0.06, 0.12) * size, 0.01 * size);
    
    float result = OpUnion(roof, house);
    return OpSubtraction(door, result);
}

float SearchIconSDF(float2 p, float size)
{
    // Magnifying glass
    float lens = abs(CircleSDF(p - float2(-size * 0.1, size * 0.1), size * 0.2)) - size * 0.03;
    
    // Handle
    float2 handleStart = float2(size * 0.05, -size * 0.05);
    float2 handleEnd = float2(size * 0.25, -size * 0.25);
    float2 handleDir = normalize(handleEnd - handleStart);
    float2 toHandle = p - handleStart;
    float handleProj = dot(toHandle, handleDir);
    handleProj = clamp(handleProj, 0.0, length(handleEnd - handleStart));
    float2 handlePoint = handleStart + handleDir * handleProj;
    float handle = length(p - handlePoint) - size * 0.04;
    
    return OpUnion(lens, handle);
}

float PlusIconSDF(float2 p, float size)
{
    float horizontal = RoundedRectSDF(p, float2(0.4, 0.08) * size, 0.04 * size);
    float vertical = RoundedRectSDF(p, float2(0.08, 0.4) * size, 0.04 * size);
    return OpUnion(horizontal, vertical);
}

float MinusIconSDF(float2 p, float size)
{
    return RoundedRectSDF(p, float2(0.4, 0.08) * size, 0.04 * size);
}

float CheckIconSDF(float2 p, float size)
{
    // Check mark using two line segments
    float2 p1 = float2(-size * 0.2, 0);
    float2 p2 = float2(-size * 0.05, -size * 0.15);
    float2 p3 = float2(size * 0.25, size * 0.2);
    
    // First segment of check
    float line1 = length(p - lerp(p1, p2, saturate(dot(p - p1, p2 - p1) / dot(p2 - p1, p2 - p1)))) - size * 0.04;
    
    // Second segment of check  
    float line2 = length(p - lerp(p2, p3, saturate(dot(p - p2, p3 - p2) / dot(p3 - p2, p3 - p2)))) - size * 0.04;
    
    return OpUnion(line1, line2);
}

// ----------------------
// Arrow Icons
// ----------------------

float ArrowUpIconSDF(float2 p, float size)
{
    float2 a = float2(-size * 0.2, 0);
    float2 b = float2(size * 0.2, 0);
    float2 c = float2(0, size * 0.25);
    float head = TriangleSDF(p, a, b, c);
    
    float shaft = RoundedRectSDF(p - float2(0, -size * 0.15), float2(0.04, 0.2) * size, 0.02 * size);
    return OpUnion(head, shaft);
}

float ArrowDownIconSDF(float2 p, float size)
{
    float2 a = float2(-size * 0.2, 0);
    float2 b = float2(size * 0.2, 0);
    float2 c = float2(0, -size * 0.25);
    float head = TriangleSDF(p, a, b, c);
    
    float shaft = RoundedRectSDF(p - float2(0, size * 0.15), float2(0.04, 0.2) * size, 0.02 * size);
    return OpUnion(head, shaft);
}

float ArrowLeftIconSDF(float2 p, float size)
{
    float2 a = float2(0, -size * 0.2);
    float2 b = float2(0, size * 0.2);
    float2 c = float2(-size * 0.25, 0);
    float head = TriangleSDF(p, a, b, c);
    
    float shaft = RoundedRectSDF(p - float2(size * 0.15, 0), float2(0.2, 0.04) * size, 0.02 * size);
    return OpUnion(head, shaft);
}

float ArrowRightIconSDF(float2 p, float size)
{
    float2 a = float2(0, -size * 0.2);
    float2 b = float2(0, size * 0.2);
    float2 c = float2(size * 0.25, 0);
    float head = TriangleSDF(p, a, b, c);
    
    float shaft = RoundedRectSDF(p - float2(-size * 0.15, 0), float2(0.2, 0.04) * size, 0.02 * size);
    return OpUnion(head, shaft);
}

// ----------------------
// Caret Icons (smaller, no shaft)
// ----------------------

float CaretUpIconSDF(float2 p, float size)
{
    float2 a = float2(-size * 0.15, -size * 0.1);
    float2 b = float2(size * 0.15, -size * 0.1);
    float2 c = float2(0, size * 0.15);
    return TriangleSDF(p, a, b, c);
}

float CaretDownIconSDF(float2 p, float size)
{
    float2 a = float2(-size * 0.15, size * 0.1);
    float2 b = float2(size * 0.15, size * 0.1);
    float2 c = float2(0, -size * 0.15);
    return TriangleSDF(p, a, b, c);
}

float CaretLeftIconSDF(float2 p, float size)
{
    float2 a = float2(size * 0.1, -size * 0.15);
    float2 b = float2(size * 0.1, size * 0.15);
    float2 c = float2(-size * 0.15, 0);
    return TriangleSDF(p, a, b, c);
}

float CaretRightIconSDF(float2 p, float size)
{
    float2 a = float2(-size * 0.1, -size * 0.15);
    float2 b = float2(-size * 0.1, size * 0.15);
    float2 c = float2(size * 0.15, 0);
    return TriangleSDF(p, a, b, c);
}

// ----------------------
// Icon Dispatcher for UI Icons
// ----------------------

float GetUIIconSDF(float2 p, int iconType, float size)
{
    switch (iconType)
    {
        case ICON_HAMBURGER:
            return HamburgerIconSDF(p, size);
        case ICON_CLOSE:
            return CloseIconSDF(p, size);
        case ICON_INFO:
            return InfoIconSDF(p, size);
        case ICON_SETTINGS:
            return SettingsIconSDF(p, size);
        case ICON_DOWNLOAD:
            return DownloadIconSDF(p, size);
        case ICON_UPLOAD:
            return UploadIconSDF(p, size);
        case ICON_REFRESH:
            return RefreshIconSDF(p, size);
        case ICON_HOME:
            return HomeIconSDF(p, size);
        case ICON_SEARCH:
            return SearchIconSDF(p, size);
        case ICON_PLUS:
            return PlusIconSDF(p, size);
        case ICON_MINUS:
            return MinusIconSDF(p, size);
        case ICON_CHECK:
            return CheckIconSDF(p, size);
        case ICON_ARROW_UP:
            return ArrowUpIconSDF(p, size);
        case ICON_ARROW_DOWN:
            return ArrowDownIconSDF(p, size);
        case ICON_ARROW_LEFT:
            return ArrowLeftIconSDF(p, size);
        case ICON_ARROW_RIGHT:
            return ArrowRightIconSDF(p, size);
        case ICON_CARET_UP:
            return CaretUpIconSDF(p, size);
        case ICON_CARET_DOWN:
            return CaretDownIconSDF(p, size);
        case ICON_CARET_LEFT:
            return CaretLeftIconSDF(p, size);
        case ICON_CARET_RIGHT:
            return CaretRightIconSDF(p, size);
        default:
            return 1000.0; // No icon
    }
}

#endif