#ifndef SDF_PRIMITIVES_INCLUDED
#define SDF_PRIMITIVES_INCLUDED

#include "../Core/UIMath.cginc"

// ----------------------
// Shape Modifiers
// ----------------------

// Expands a shape outward (positive radius) or inward (negative radius)
inline float OpRound(float sdf, float radius)
{
    return sdf - radius;
}

// ----------------------
// 2D SDF Primitives
// ----------------------

float CircleSDF(float2 p, float r)
{
    return length(p) - r;
}

float RectangleSDF(float2 p, float2 size)
{
    float2 d = abs(p) - size;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Rounded rectangle with uniform corner radius
float RoundedRectSDF(float2 p, float2 size, float r)
{
    float2 d = abs(p) - size + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

float EllipseSDF(float2 p, float2 ab)
{
    p = abs(p);
    if (p.x > p.y)
    {
        p = p.yx;
        ab = ab.yx;
    }
    float l = ab.y * ab.y - ab.x * ab.x;
    float m = ab.x * p.x / l;
    float m2 = m * m;
    float n = ab.y * p.y / l;
    float n2 = n * n;
    float c = (m2 + n2 - 1.0) / 3.0;
    float c3 = c * c * c;
    float q = c3 + m2 * n2 * 2.0;
    float d = c3 + m2 * n2;
    float g = m + m * n2;
    float co;
    if (d < 0.0)
    {
        float h = acos(q / c3) / 3.0;
        float s = cos(h);
        float t = sin(h) * sqrt(3.0);
        float rx = sqrt(-c * (s + t + 2.0) + m2);
        float ry = sqrt(-c * (s - t + 2.0) + m2);
        co = (ry + sign(l) * rx + abs(g) / (rx * ry) - m) / 2.0;
    }
    else
    {
        float h = 2.0 * m * n * sqrt(d);
        float s = sign(q + h) * pow(abs(q + h), 1.0 / 3.0);
        float u = sign(q - h) * pow(abs(q - h), 1.0 / 3.0);
        float rx = -s - u - c * 4.0 + 2.0 * m2;
        float ry = (s - u) * sqrt(3.0);
        float rm = sqrt(rx * rx + ry * ry);
        co = (ry / sqrt(rm - rx) + 2.0 * g / rm - m) / 2.0;
    }
    float2 r = ab * float2(co, sqrt(1.0 - co * co));
    return length(r - p) * sign(p.y - r.y);
}

float TriangleSDF(float2 p, float2 a, float2 b, float2 c)
{
    float2 e0 = b - a;
    float2 e1 = c - b;
    float2 e2 = a - c;
    float2 v0 = p - a;
    float2 v1 = p - b;
    float2 v2 = p - c;

    float2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
    float2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
    float2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);

    float s = sign(e0.x * e2.y - e0.y * e2.x);
    float2 d = min(min(float2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                       float2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                       float2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));

    return -sqrt(d.x) * sign(d.y);
}

// ----------------------
// Advanced SDF Primitives
// ----------------------

// Pie/Sector SDF
inline float PieSDF(float2 p, float2 c, float r)
{
    p.x = abs(p.x);
    float l = length(p) - r;
    float m = length(p - c * clamp(dot(p, c), 0.0, r)); // c=sin/cos of aperture
    return max(l, m * sign(c.y * p.x - c.x * p.y));
}

// Ring SDF — open arc with aperture defined by sin/cos vector n
inline float RingSDF(float2 p, float2 n, float r, float th, float ru)
{
    p.x = abs(p.x);
    float2 t = p;
    p.x = t.x * n.x - t.y * n.y;
    p.y = t.x * n.y + t.y * n.x;
    float ringDist = max(abs(length(t) - r) - th * 0.5, length(float2(p.x, max(0.0, abs(r - p.y) - th * 0.5))) * sign(p.x));
    return OpRound(ringDist, ru);
}

// Cut Disk SDF — disk with a flat chord cut off
inline float CutDiskSDF(float2 p, float r, float h)
{
    float w = sqrt(r * r - h * h); // constant for any given shape
    p.x = abs(p.x);
    float s = max((h - r) * p.x * p.x + w * w * (h + r - 2.0 * p.y), h * p.x - w * p.y);
    return (s < 0.0) ? length(p) - r :
        (p.x < w) ? h - p.y :
        length(p - float2(w, h));
}

float HexagonSDF(float2 p, float r)
{
    const float3 k = float3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= float2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

float PentagonSDF(float2 p, float r)
{
    const float3 k = float3(0.809016994, 0.587785252, 0.726542528);
    p.x = abs(p.x);
    p -= 2.0 * min(dot(float2(-k.x, k.y), p), 0.0) * float2(-k.x, k.y);
    p -= 2.0 * min(dot(float2(k.x, k.y), p), 0.0) * float2(k.x, k.y);
    p -= float2(clamp(p.x, -r * k.z, r * k.z), r);
    return length(p) * sign(p.y);
}

float StarSDF(float2 p, float r, int n, float m)
{
    // Generic star with n points
    float an = PI / float(n);
    float en = PI / m;
    float2 acs = float2(cos(an), sin(an));
    float2 ecs = float2(cos(en), sin(en));
    
    // Add 2*PI before fmod to guarantee non-negative input and avoid negative-fmod artefacts
    // on the left side (negative x half-plane) which caused the original blow-out.
    float bn = fmod(atan2(p.x, p.y) + 2.0 * PI, 2.0 * an) - an;
    p = length(p) * float2(cos(bn), abs(sin(bn)));
    p -= r * acs;
    p += ecs * clamp(-dot(p, ecs), 0.0, r * acs.y / ecs.y);
    return length(p) * sign(p.x);
}

float RhombusSDF(float2 p, float2 b)
{
    p = abs(p);
    float h = clamp((-2.0 * dot(p, b) + dot(b, b)) / dot(b, b), -1.0, 1.0);
    float d = length(p - 0.5 * b * float2(1.0 - h, 1.0 + h));
    return d * sign(p.x * b.y + p.y * b.x - b.x * b.y);
}

float TrapezoidSDF(float2 p, float2 a, float2 b, float ra, float rb)
{
    float rba = rb - ra;
    float baba = dot(b - a, b - a);
    float papa = dot(p - a, p - a);
    float paba = dot(p - a, b - a) / baba;
    float x = sqrt(papa - paba * paba * baba);
    float cax = max(0.0, x - ((paba < 0.5) ? ra : rb));
    float cay = abs(paba - 0.5) - 0.5;
    float k = rba * rba + baba;
    float f = clamp((rba * (x - ra) + paba * baba) / k, 0.0, 1.0);
    float cbx = x - ra - f * rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s * sqrt(min(cax * cax + cay * cay * baba, cbx * cbx + cby * cby * baba));
}

float HeartSDF(float2 p)
{
    p.x = abs(p.x);
    if (p.y + p.x > 1.0)
    {
        return sqrt(dot(p - float2(0.25, 0.75), p - float2(0.25, 0.75))) - sqrt(2.0) / 4.0;
    }
    return sqrt(min(dot(p - float2(0.0, 1.0), p - float2(0.0, 1.0)),
                    dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0)))) * sign(p.x - p.y);
}

float CrossSDF(float2 p, float2 b, float r)
{
    p = abs(p);
    p = (p.y > p.x) ? p.yx : p.xy;
    float2 q = p - b;
    float k = max(q.y, q.x);
    float2 w = (k > 0.0) ? q : float2(b.y - p.x, -k);
    return sign(k) * length(max(w, 0.0)) + r;
}

float ArrowSDF(float2 p, float2 a, float2 b, float w1, float w2)
{
    // Distance to arrow shaft
    float2 ba = b - a;
    float2 pa = p - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float2 q = pa - h * ba;
    float shaft = length(q) - lerp(w1, w2, h);

    // Distance to arrow head
    float2 head = p - b;
    float2 dir = normalize(ba);
    float2 perp = float2(-dir.y, dir.x);
    float headLength = w2 * 2.0;
    float2 tip = b + dir * headLength;
    float arrowHead = TriangleSDF(p, b - perp * w2, b + perp * w2, tip);

    return min(shaft, arrowHead);
}

// ----------------------
// Distance to Mask Utilities
// ----------------------

// Antialiased alpha mask from an SDF distance value.
// aaFactor controls the transition width (default 0.75).
float getSDFAlpha(float sdfDistance, float aaFactor)
{
    float aa = fwidth(sdfDistance) * aaFactor;
    return smoothstep(aa, -aa, sdfDistance);
}

float getSDFAlpha(float sdfDistance)
{
    return getSDFAlpha(sdfDistance, 0.75);
}

// Ring mask from a raw distance-from-center value.
float SmoothRing(float dist, float innerRadius, float outerRadius, float smoothness)
{
    float inner = smoothstep(innerRadius - smoothness, innerRadius + smoothness, dist);
    float outer = 1.0 - smoothstep(outerRadius - smoothness, outerRadius + smoothness, dist);
    return inner * outer;
}

// Filled circle mask from a raw distance-from-center value.
float SmoothCircle(float dist, float radius, float smoothness)
{
    return 1.0 - smoothstep(radius - smoothness, radius + smoothness, dist);
}

// ----------------------
// Arc SDF — UI angle convention
// ----------------------
// p            : position in [-1,1] space, centered on (0,0)
// radius       : center-line radius of the arc
// thickness    : total width of the arc band
// startAngle   : start in degrees, UI convention (0 = top, CW positive)
// angleRange   : sweep in degrees
// roundedEnabled : > 0.5 enables rounded end caps
float ArcSDF(float2 p, float radius, float thickness, float startAngle, float angleRange, float roundedEnabled)
{
    // Distance from center
    float distFromCenter = length(p);
    
    // Ring SDF (distance to ring thickness)
    float ringDist = abs(distFromCenter - radius) - thickness * 0.5;
    
    // Calculate the angle of current point in atan2 coordinates
    float rawAngle = degrees(atan2(p.y, p.x));
    if (rawAngle < 0.0) rawAngle += 360.0;
    
    // Normalize start angle to [0, 360) range first
    float normalizedStartAngle = fmod(startAngle + 360.0, 360.0);
    
    // Calculate end angle in USER space
    float userEndAngle = normalizedStartAngle + angleRange;
    if (userEndAngle >= 360.0) userEndAngle -= 360.0;
    
    // Convert start angle to atan2 coordinates
    float atan2StartAngle;
    if (normalizedStartAngle <= 180.0) {
        atan2StartAngle = 180.0 - normalizedStartAngle;
    } else {
        atan2StartAngle = 540.0 - normalizedStartAngle;
    }
    if (atan2StartAngle >= 360.0) atan2StartAngle -= 360.0;
    
    // Convert end angle to atan2 coordinates using same logic
    float atan2EndAngle;
    if (userEndAngle <= 180.0) {
        atan2EndAngle = 180.0 - userEndAngle;
    } else {
        atan2EndAngle = 540.0 - userEndAngle;
    }
    if (atan2EndAngle >= 360.0) atan2EndAngle -= 360.0;
    
    // Check if point is within the angular range
    bool inAngularRange = false;
    
    if (angleRange >= 360.0) {
        inAngularRange = true;
    } else {
        float userCurrentAngle;
        if (rawAngle >= 0.0 && rawAngle <= 180.0) {
            userCurrentAngle = 180.0 - rawAngle;
        } else {
            userCurrentAngle = 540.0 - rawAngle;
        }
        if (userCurrentAngle >= 360.0) userCurrentAngle -= 360.0;
        if (userCurrentAngle < 0.0) userCurrentAngle += 360.0;
        
        float endAngle = normalizedStartAngle + angleRange;
        if (endAngle >= 360.0) endAngle -= 360.0;
        
        float angleDiff = userCurrentAngle - normalizedStartAngle;
        if (angleDiff < 0.0) angleDiff += 360.0;
        
        inAngularRange = (angleDiff <= angleRange);
    }
    
    if (!inAngularRange) {
        float distToStart = abs(rawAngle - atan2StartAngle);
        float distToEnd = abs(rawAngle - atan2EndAngle);
        
        if (distToStart > 180.0) distToStart = 360.0 - distToStart;
        if (distToEnd > 180.0) distToEnd = 360.0 - distToEnd;
        
        float angularDist = min(distToStart, distToEnd) * (PI / 180.0) * distFromCenter;
        ringDist = max(ringDist, angularDist);
    }
    
    // Rounded ends implementation
    if (roundedEnabled > 0.5) {
        float startRad = radians(atan2StartAngle);
        float endRad = radians(atan2EndAngle);
        
        float2 startPos = float2(cos(startRad), sin(startRad)) * radius;
        float2 endPos = float2(cos(endRad), sin(endRad)) * radius;
        
        float capRadius = thickness * 0.5;
        float startCapDist = length(p - startPos) - capRadius;
        float endCapDist = length(p - endPos) - capRadius;
        
        float k = 0.001;
        
        float h1 = max(k - abs(ringDist - startCapDist), 0.0);
        if (h1 > 0.0) {
            h1 /= k;
            ringDist = min(ringDist, startCapDist) - h1 * h1 * k * 0.25;
        } else {
            ringDist = min(ringDist, startCapDist);
        }
        
        float h2 = max(k - abs(ringDist - endCapDist), 0.0);
        if (h2 > 0.0) {
            h2 /= k;
            ringDist = min(ringDist, endCapDist) - h2 * h2 * k * 0.25;
        } else {
            ringDist = min(ringDist, endCapDist);
        }
    }
    
    return ringDist;
}

#endif