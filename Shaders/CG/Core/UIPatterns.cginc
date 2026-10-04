#ifndef UI_PATTERNS_INCLUDED
#define UI_PATTERNS_INCLUDED

#include "UIMath.cginc"
#include "UIComponents.cginc"

// ============================================================================
// UIPatterns.cginc — Procedural Material Pattern Library
// ============================================================================
// 20 pattern types organized into 5 categories. Each pattern uses:
//   - patternScale:     Overall scale of the pattern
//   - patternIntensity: How strongly the pattern affects color
//   - patternContrast:  Gamma curve on the pattern value
//   - patternParam1:    Detail / density control (pattern-specific)
//   - patternParam2:    Distortion / variation (pattern-specific)
//   - patternParam3:    Blend / secondary feature (pattern-specific)
//   - patternSpecularEffect:   How much pattern modulates specular
//   - patternRoughnessEffect:  How much pattern drives bump normals
//
// All patterns are pure procedural — no textures required.
// ============================================================================

// Pattern type constants — keep in sync with ShaderConstants.cs PatternType enum
// Surface materials (0-4)
#define PATTERN_PLASTIC         0
#define PATTERN_METAL           1
#define PATTERN_RADIAL_BRUSHED  2
#define PATTERN_CARBON_FIBER    3
#define PATTERN_LEATHER         4

// Brushed finishes (5-6)
#define PATTERN_BRUSHED_CROSS   5
#define PATTERN_SATIN           6

// Mineral / fabric (7-10)
#define PATTERN_CONCRETE        7
#define PATTERN_FABRIC          8
#define PATTERN_PAPER           9
#define PATTERN_FROSTED         10

// Geometric (11-14)
#define PATTERN_DIAMOND_PLATE   11
#define PATTERN_KNURLED         12
#define PATTERN_HEX_GRID        13
#define PATTERN_PERFORATED      14

// Organic (15-17)
#define PATTERN_WOOD_GRAIN      15
#define PATTERN_MARBLE          16
#define PATTERN_CERAMIC         17

// Special (18-19)
#define PATTERN_CIRCUIT         18
#define PATTERN_NOISE_ORGANIC   19

// Pattern color types — defines how the A-D color palette is indexed per pixel.
// Keep in sync with PatternColorType enum in ShaderConstants.cs.
// Named color type constants — values start at 0, no invalid gap
#define PATTERN_COLORTYPE_GRADIENT  0   // signed range [-1,+1] → palette: negative=A, zero=mid, positive=D
#define PATTERN_COLORTYPE_FEATURE   1   // feature strength → palette: flat surface=A, peak feature=D
#define PATTERN_COLORTYPE_ZONES     2   // repeating palette cycles — distinct coloring per feature instance
#define PATTERN_COLORTYPE_BANDS     3   // sine-wave banding — good for rings, veins, layered patterns
// Numeric aliases for backward compatibility
#define PATTERN_COLORTYPE_1  PATTERN_COLORTYPE_GRADIENT
#define PATTERN_COLORTYPE_2  PATTERN_COLORTYPE_FEATURE
#define PATTERN_COLORTYPE_3  PATTERN_COLORTYPE_ZONES
#define PATTERN_COLORTYPE_4  PATTERN_COLORTYPE_BANDS

// ============================================================================
// Individual pattern sampling functions
// ============================================================================
// Each returns a float value roughly centered around 0.
// Parameters:
//   pos:    rotated position relative to center ([-0.5, 0.5] range)
//   center: UV center (0.5, 0.5)
//   scale:  patternScale
//   p1/p2/p3: patternParam1/2/3 (each in [0, 1] range)

// --- 1: Plastic — smooth surface with subtle noise imperfections ---
float SamplePlastic(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls octave detail (1-4 octaves)
    int octaves = clamp((int)(p1 * 3.0) + 1, 1, 4);
    float val = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < octaves; i++)
    {
        val += noise(uv * freq) * amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    
    // p2 controls surface warp/distortion
    if (p2 > 0.01)
    {
        float2 warped = DomainWarp(uv, p2 * 0.3, scale * 0.5);
        val = lerp(val, noise(warped) * 0.5 + noise(warped * 2.0) * 0.25, p2);
    }
    
    // p3 adds metallic flake sparkle
    if (p3 > 0.01)
    {
        float flake = noise(uv * scale * 3.0);
        flake = pow(abs(flake), 3.0) * 2.0;
        val += flake * p3 * 0.4;
    }
    
    return val - 0.5;
}

// --- 2: Metal — anisotropic linear brushed finish ---
float SampleMetal(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls grain direction (0=horizontal, 0.5=diagonal, 1=vertical)
    float dirAngle = p1 * 3.14159265;
    float2 dir = float2(cos(dirAngle), sin(dirAngle));
    float2 perp = float2(-dir.y, dir.x);
    
    // Strong anisotropy along grain direction
    // p2 controls anisotropy ratio (how stretched the noise is)
    float aniso = lerp(0.05, 0.3, p2);
    float2 anisoUV = float2(dot(uv, dir), dot(uv, perp) * aniso);
    
    float val = noise(anisoUV) * 0.7 + noise(anisoUV * 2.0) * 0.3;
    
    // p3 adds random streak variation
    if (p3 > 0.01)
    {
        float streak = noise(float2(dot(uv, dir) * 4.0, dot(uv, perp) * 0.05));
        val = lerp(val, streak, p3 * 0.5);
    }
    
    return val - 0.5;
}

// --- 3: Radial Brushed — angular stripes emanating from center ---
float SampleRadialBrushed(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float angle = atan2(pos.y, pos.x);
    float dist = length(pos);
    
    float normalizedAngle = angle / (2.0 * 3.14159265);
    
    // p1 refines groove count multiplier
    float grooveMul = lerp(0.5, 2.0, p1);
    float scaledAngle = frac(normalizedAngle * scale * grooveMul);
    float radialPattern = sin(scaledAngle * 2.0 * 3.14159265) * 0.5 + 0.5;
    
    // p2 adds noise irregularity to the grooves
    float2 noiseUV = float2(scaledAngle * 10.0, dist * scale);
    float brushNoise = noise(noiseUV) * lerp(0.1, 0.5, p2);
    
    // p3 adds concentric ring emphasis
    float rings = sin(dist * scale * lerp(5.0, 30.0, p3)) * 0.5 + 0.5;
    float ringBlend = p3 * 0.3;
    
    return (radialPattern + brushNoise + rings * ringBlend) - 0.5;
}

// --- 4: Carbon Fiber — woven interlocking pattern ---
float SampleCarbonFiber(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls weave tightness (period size)
    float weaveScale = lerp(2.0, 8.0, p1);
    float2 wuv = uv * weaveScale;
    
    // Two perpendicular fiber directions
    float fiber1 = sin(wuv.x * 6.28318) * 0.5 + 0.5;
    float fiber2 = sin(wuv.y * 6.28318) * 0.5 + 0.5;
    
    // Checkerboard weave: alternate which fiber is on top
    float checker = step(0.5, frac(wuv.x * 0.5)) * step(0.5, frac(wuv.y * 0.5));
    checker += (1.0 - step(0.5, frac(wuv.x * 0.5))) * (1.0 - step(0.5, frac(wuv.y * 0.5)));
    
    float weave = lerp(fiber1, fiber2, checker);
    
    // p2 controls depth/contrast of the weave crossings
    weave = lerp(0.5, weave, lerp(0.5, 1.0, p2));
    
    // p3 adds glossy clear-coat effect (smooths the pattern)
    if (p3 > 0.01)
    {
        float smooth_coat = noise((pos + center) * scale * 0.5) * 0.5 + 0.5;
        weave = lerp(weave, smooth_coat * 0.3 + 0.35, p3 * 0.4);
    }
    
    return weave - 0.5;
}

// --- 5: Leather — organic grain with pores ---
float SampleLeather(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // Base leather grain from Voronoi cells
    // p1 controls pore density
    float cellScale = lerp(3.0, 12.0, p1);
    float2 v = VoronoiNoise(uv * cellScale);
    float grain = v.x;
    
    // p2 warps the grain for more organic look
    if (p2 > 0.01)
    {
        float2 warped = DomainWarp(uv * cellScale, p2 * 0.5, 2.0);
        float2 vw = VoronoiNoise(warped);
        grain = lerp(grain, vw.x, p2);
    }
    
    // Add subtle noise for fine surface detail
    float fine = noise(uv * scale * 2.0) * 0.15;
    
    // p3 adds deep cracks along cell boundaries
    float edge = VoronoiEdge(uv * cellScale);
    float cracks = smoothstep(0.1, 0.0, edge) * p3;
    
    return (grain + fine - cracks * 0.3) - 0.5;
}

// --- 6: Brushed Cross — cross-hatched brushed metal ---
float SampleBrushedCross(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls the cross angle (0 = 45deg, 0.5 = 90deg, 1 = shallow)
    float halfAngle = lerp(0.3, 1.57, p1);
    
    // Two directional brush strokes at opposing angles
    float2 dir1 = float2(cos(halfAngle), sin(halfAngle));
    float2 dir2 = float2(cos(-halfAngle), sin(-halfAngle));
    
    float stroke1 = noise(float2(dot(uv, dir1) * 3.0, dot(uv, float2(-dir1.y, dir1.x)) * 0.1));
    float stroke2 = noise(float2(dot(uv, dir2) * 3.0, dot(uv, float2(-dir2.y, dir2.x)) * 0.1));
    
    // p2 adds noise to stroke regularity
    float noiseAmt = p2 * 0.3;
    stroke1 += noise(uv * 5.0) * noiseAmt;
    stroke2 += noise(uv * 5.0 + float2(3.7, 1.2)) * noiseAmt;
    
    // p3 controls balance between the two stroke layers
    float balance = lerp(0.3, 0.7, p3);
    float val = lerp(stroke1, stroke2, balance);
    
    return val - 0.5;
}

// --- 7: Satin — smooth directional sheen ---
float SampleSatin(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls sheen spread (how wide the highlight band is)
    float sheenWidth = lerp(0.5, 3.0, p1);
    float linearVal = dot(uv, float2(1.0, 0.0)) * sheenWidth;
    float sheen = sin(linearVal * 3.14159265) * 0.5 + 0.5;
    
    // Very smooth, low-frequency variations
    float softNoise = noise(uv * 0.5) * 0.5 + noise(uv) * 0.25;
    
    // p2: flow distortion
    if (p2 > 0.01)
    {
        float2 flow = DomainWarp(uv, p2 * 0.15, 1.0);
        float flowSheen = sin(dot(flow, float2(1.0, 0.0)) * sheenWidth * 3.14159265) * 0.5 + 0.5;
        sheen = lerp(sheen, flowSheen, p2 * 0.7);
    }
    
    // p3 adds subtle shimmer sparkle
    float shimmer = 0.0;
    if (p3 > 0.01)
    {
        shimmer = noise(uv * scale * 4.0);
        shimmer = pow(abs(shimmer), 4.0) * p3 * 0.5;
    }
    
    return (sheen * 0.6 + softNoise * 0.4 + shimmer) - 0.5;
}

// --- 8: Concrete — rough mineral surface with aggregate ---
float SampleConcrete(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // Multi-octave rough noise for base surface
    float base = FBMNoise(uv * 2.0, 4, 0.5, 2.0);
    
    // p1 controls aggregate/pebble visibility
    float aggScale = lerp(2.0, 8.0, p1);
    float2 v = VoronoiNoise(uv * aggScale);
    float aggregate = smoothstep(0.3, 0.0, v.x) * p1;
    
    // p2 adds surface cracks
    float cracks = 0.0;
    if (p2 > 0.01)
    {
        float edge = VoronoiEdge(uv * lerp(1.0, 4.0, p2));
        cracks = smoothstep(0.15, 0.0, edge) * p2;
    }
    
    // p3 controls roughness variation (areas of smooth vs rough)
    float roughVar = noise(uv * 0.5) * p3;
    base = lerp(base, base * (1.0 + roughVar), p3);
    
    return (base + aggregate * 0.3 - cracks * 0.4) - 0.5;
}

// --- 9: Fabric / Linen — woven thread texture ---
float SampleFabric(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls thread density
    float threadScale = lerp(5.0, 25.0, p1);
    
    // Horizontal and vertical threads
    float warp = sin(uv.y * threadScale * 6.28318) * 0.5 + 0.5;
    float weft = sin(uv.x * threadScale * 6.28318) * 0.5 + 0.5;
    
    // p2 adds irregularity to thread spacing
    if (p2 > 0.01)
    {
        float jitter = noise(uv * threadScale * 0.5) * p2 * 0.3;
        warp = sin((uv.y + jitter) * threadScale * 6.28318) * 0.5 + 0.5;
        weft = sin((uv.x + jitter) * threadScale * 6.28318) * 0.5 + 0.5;
    }
    
    // Weave pattern: alternate which thread is on top
    float weaveCheck = step(0.5, frac(uv.x * threadScale * 0.5)) + step(0.5, frac(uv.y * threadScale * 0.5));
    weaveCheck = frac(weaveCheck * 0.5);
    float val = lerp(warp * 0.7 + weft * 0.3, warp * 0.3 + weft * 0.7, weaveCheck);
    
    // p3 controls warp/weft emphasis ratio
    val = lerp(val, warp, (p3 - 0.5) * 0.6);
    
    // Fine fiber noise
    val += noise(uv * threadScale * 2.0) * 0.08;
    
    return val - 0.5;
}

// --- 10: Paper — matte granular surface ---
float SamplePaper(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls fiber density
    float fiberScale = lerp(1.0, 4.0, p1);
    float fibers = noise(uv * fiberScale * 3.0) * 0.5 
                 + noise(uv * fiberScale * 6.0) * 0.25 
                 + noise(uv * fiberScale * 12.0) * 0.125;
    
    // Slight directional bias for paper fiber alignment
    float2 biasUV = uv * fiberScale * float2(3.0, 1.5);
    float bias = noise(biasUV) * 0.15;
    fibers += bias;
    
    // p2 adds blotchy water damage / stain marks
    if (p2 > 0.01)
    {
        float blotch = noise(uv * 1.5);
        blotch = smoothstep(0.4, 0.6, blotch) * p2 * 0.3;
        fibers += blotch;
    }
    
    // p3 controls tooth depth (how much surface texture catches light)
    float tooth = noise(uv * scale * 2.0);
    tooth = (tooth - 0.5) * p3 * 0.4;
    
    return (fibers + tooth) - 0.5;
}

// --- 11: Frosted — sandblasted / frosted glass ---
float SampleFrosted(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls crystal/grain size
    float crystalScale = lerp(5.0, 20.0, p1);
    float2 v = VoronoiNoise(uv * crystalScale);
    float crystal = v.x;
    
    // p2 controls diffusion (blend between sharp crystals and soft blur)
    float softNoise = noise(uv * crystalScale * 0.3) * 0.5 + 0.5;
    float val = lerp(crystal, softNoise, p2 * 0.7);
    
    // Add fine granular noise
    val += noise(uv * crystalScale * 2.0) * 0.1;
    
    // p3 controls opacity variation (areas more/less frosted)
    if (p3 > 0.01)
    {
        float opacVar = noise(uv * 2.0);
        opacVar = smoothstep(0.3, 0.7, opacVar);
        val = lerp(val, val * opacVar, p3 * 0.5);
    }
    
    return val - 0.4;
}

// --- 12: Diamond Plate — industrial raised diamond pattern ---
float SampleDiamondPlate(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls diamond spacing
    float spacing = lerp(2.0, 8.0, p1);
    float2 duv = uv * spacing;
    
    // Staggered diamond grid
    float2 cell = floor(duv);
    float2 local = frac(duv) - 0.5;
    
    // Offset every other row
    if (fmod(cell.y, 2.0) > 0.5) local.x -= 0.5;
    
    // Diamond shape using taxicab distance
    float diamond = abs(local.x) + abs(local.y);
    
    // p2 controls raised height (how pronounced the diamonds are)
    float raised = smoothstep(0.5, lerp(0.3, 0.1, p2), diamond);
    
    // p3 controls edge sharpness vs soft transition
    float sharpness = lerp(0.1, 0.01, p3);
    float val = smoothstep(0.5 + sharpness, 0.5 - sharpness, diamond) * 0.7;
    
    // Base plate noise
    val += noise(uv * spacing * 2.0) * 0.05;
    
    return val - 0.3;
}

// --- 13: Knurled — diamond grip pattern (like on metal tools) ---
float SampleKnurled(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls grid density
    float gridScale = lerp(5.0, 25.0, p1);
    
    // Two diagonal grid lines creating diamond intersections
    float d1 = sin((uv.x + uv.y) * gridScale * 3.14159265);
    float d2 = sin((uv.x - uv.y) * gridScale * 3.14159265);
    
    // p2 controls depth of the grooves
    float depth = lerp(0.3, 1.0, p2);
    float knurl = (d1 * d2) * depth;
    
    // p3 controls diamond shape (round vs sharp peaks)
    float shapeBlend = p3;
    float peaks = max(d1, d2) * 0.5 + 0.5;
    float diamonds = (d1 * 0.5 + 0.5) * (d2 * 0.5 + 0.5);
    float val = lerp(diamonds, peaks, shapeBlend);
    
    // Add subtle machining marks
    val += noise(uv * gridScale * 0.5) * 0.05;
    
    return val - 0.5;
}

// --- 14: Hex Grid — honeycomb pattern ---
float SampleHexGrid(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls cell size
    float cellSize = lerp(2.0, 10.0, p1);
    float2 huv = uv * cellSize;
    
    // Hex grid math
    float2 r = float2(1.0, 1.73205);       // 1, sqrt(3)
    float2 h = r * 0.5;
    float2 a = fmod(huv, r) - h;
    float2 b = fmod(huv - h, r) - h;
    
    float2 gv = (dot(a, a) < dot(b, b)) ? a : b;
    float hexDist = max(abs(gv.x), abs(gv.y * 0.577350269 + gv.x * 0.5));
    
    // p2 controls border width
    float border = lerp(0.02, 0.15, p2);
    float hexBorder = smoothstep(0.5 - border, 0.5, hexDist);
    
    // p3 controls indent depth (concave vs flat cells)
    float indent = length(gv) * p3;
    
    float val = hexBorder * 0.6 + indent * 0.4;
    
    return val - 0.3;
}

// --- 15: Perforated — regular dot hole pattern ---
float SamplePerforated(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls hole density
    float density = lerp(3.0, 15.0, p1);
    float2 puv = uv * density;
    float2 local = frac(puv) - 0.5;
    
    // p2 controls hole size
    float holeRadius = lerp(0.15, 0.45, p2);
    float dist = length(local);
    
    // p3 controls edge softness
    float edgeSoft = lerp(0.02, 0.15, p3);
    float hole = smoothstep(holeRadius - edgeSoft, holeRadius + edgeSoft, dist);
    
    // Add slight depth to holes
    float depthVal = smoothstep(holeRadius + edgeSoft, 0.0, dist) * 0.3;
    
    // Surface noise on the solid areas
    float surface = noise(uv * density * 0.5) * 0.05 * hole;
    
    float val = hole + surface - depthVal * (1.0 - hole);
    
    return val - 0.5;
}

// --- 16: Wood Grain — natural wood with rings and grain direction ---
float SampleWoodGrain(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls ring spacing
    float ringFreq = lerp(3.0, 15.0, p1);
    
    // Base rings - slight elliptical distortion for natural look
    float2 ringUV = uv * float2(1.0, 0.6);
    float distFromCenter = length(ringUV);
    
    // p2 controls grain wander (how wavy the rings are)
    float wander = noise(uv * 2.0) * p2 * 0.3;
    float rings = sin((distFromCenter + wander) * ringFreq * 6.28318) * 0.5 + 0.5;
    
    // Fine grain lines along x direction
    float fineGrain = noise(uv * float2(0.5, scale * 2.0)) * 0.3;
    
    // p3 controls knot frequency
    float knots = 0.0;
    if (p3 > 0.01)
    {
        float2 knotUV = uv * lerp(1.0, 3.0, p3);
        float knotDist = length(frac(knotUV) - 0.5);
        float knotDensity = noise(uv * 0.5);
        knots = smoothstep(0.3, 0.0, knotDist) * step(0.7, knotDensity) * p3 * 0.5;
        
        // Warp rings around knots
        rings = sin((distFromCenter + wander + knots * 2.0) * ringFreq * 6.28318) * 0.5 + 0.5;
    }
    
    float val = rings * 0.6 + fineGrain * 0.3 + knots * 0.1;
    
    return val - 0.5;
}

// --- 17: Marble — elegant stone with veining ---
float SampleMarble(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls vein scale
    float veinScale = lerp(1.0, 5.0, p1);
    
    // Base marble: directional noise creating vein-like streaks
    float2 veinUV = uv * veinScale;
    
    // p2 controls turbulence amount
    float turb = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    int octaves = 4;
    for (int i = 0; i < octaves; i++)
    {
        turb += noise(veinUV * freq) * amp;
        amp *= lerp(0.4, 0.6, p2);
        freq *= 2.0;
    }
    
    // Create veins using sin with turbulence displacement
    float veins = sin(veinUV.x * 3.0 + turb * lerp(2.0, 8.0, p2));
    
    // p3 controls vein sharpness (thin crisp veins vs soft streaks)
    float sharpness = lerp(1.0, 4.0, p3);
    veins = pow(abs(veins), 1.0 / sharpness) * sign(veins);
    veins = veins * 0.5 + 0.5;
    
    // Soft base variation
    float base = noise(uv * 0.5) * 0.2;
    
    return (veins * 0.7 + base) - 0.5;
}

// --- 18: Ceramic — smooth glazed surface with optional crackle ---
float SampleCeramic(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls glaze thickness (smooth base)
    float glazeSmooth = lerp(0.3, 1.0, p1);
    float base = noise(uv * 0.5) * (1.0 - glazeSmooth) * 0.3;
    
    // p2 controls crackle/crazing amount
    float crackle = 0.0;
    if (p2 > 0.01)
    {
        float crackleScale = lerp(3.0, 10.0, p2);
        float edge = VoronoiEdge(uv * crackleScale);
        crackle = smoothstep(0.1, 0.0, edge) * p2;
    }
    
    // p3 controls gloss variation (some areas more matte than others)
    float glossVar = noise(uv * 2.0);
    glossVar = smoothstep(0.3, 0.7, glossVar) * p3 * 0.2;
    
    float val = base - crackle * 0.3 + glossVar;
    
    return val;
}

// --- 19: Circuit Board — tech-inspired traces and pads ---
float SampleCircuit(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls trace density
    float traceDensity = lerp(3.0, 12.0, p1);
    float2 grid = uv * traceDensity;
    float2 cell = floor(grid);
    float2 local = frac(grid);
    
    // Horizontal and vertical traces (Manhattan-style routing)
    float hTrace = smoothstep(0.08, 0.04, abs(local.y - 0.5));
    float vTrace = smoothstep(0.08, 0.04, abs(local.x - 0.5));
    
    // Use hash to randomly enable/disable traces per cell
    float cellHash = hash(cell);
    hTrace *= step(0.3, cellHash);
    vTrace *= step(0.3, hash(cell + float2(7.3, 2.1)));
    
    float traces = max(hTrace, vTrace);
    
    // p2 controls junction pad frequency
    if (p2 > 0.01)
    {
        float padHash = hash(cell + float2(3.1, 5.7));
        if (padHash > (1.0 - p2 * 0.5))
        {
            float padDist = length(local - 0.5);
            float pad = smoothstep(0.15, 0.1, padDist);
            traces = max(traces, pad);
        }
    }
    
    // p3 adds a second layer offset (double-sided PCB look)
    if (p3 > 0.01)
    {
        float2 layer2 = uv * traceDensity * 0.7 + float2(0.37, 0.61);
        float2 cell2 = floor(layer2);
        float2 local2 = frac(layer2);
        float hTrace2 = smoothstep(0.06, 0.03, abs(local2.y - 0.5)) * step(0.4, hash(cell2 + float2(11.1, 3.3)));
        float vTrace2 = smoothstep(0.06, 0.03, abs(local2.x - 0.5)) * step(0.4, hash(cell2 + float2(1.7, 9.2)));
        traces = max(traces, max(hTrace2, vTrace2) * p3 * 0.6);
    }
    
    // Subtle solder mask noise on non-trace areas
    float maskNoise = noise(uv * traceDensity * 2.0) * 0.05 * (1.0 - traces);
    
    return (traces + maskNoise) - 0.3;
}

// --- 20: Noise Organic — generic FBM turbulence for abstract/organic looks ---
float SampleNoiseOrganic(float2 pos, float2 center, float scale, float p1, float p2, float p3)
{
    float2 uv = (pos + center) * scale;
    
    // p1 controls FBM octaves (1-6)
    int octaves = clamp((int)(p1 * 5.0) + 1, 1, 6);
    
    // p2 controls lacunarity (frequency multiplier per octave)
    float lacunarity = lerp(1.5, 3.0, p2);
    
    // p3 controls persistence (amplitude falloff per octave)
    float persistence = lerp(0.3, 0.7, p3);
    
    float val = FBMNoise(uv, octaves, persistence, lacunarity);
    
    // Normalize roughly to [-0.5, 0.5]
    float maxVal = 0.0;
    float amp = 1.0;
    for (int i = 0; i < octaves; i++)
    {
        maxVal += amp;
        amp *= persistence;
    }
    val = (val / maxVal) - 0.5;
    
    return val;
}

// ============================================================================
// Unified pattern sampling dispatcher
// ============================================================================
float SamplePatternValue(int patternType, float2 pos, float2 center, float scale,
                         float p1, float p2, float p3)
{
    // Pattern types now range from 0-19 (no NONE type; 0 means no pattern)
    // Check should never happen if patternEnabled is checked first, but keep for safety
    [branch]
    switch (patternType)
    {
        case PATTERN_PLASTIC:        return SamplePlastic(pos, center, scale, p1, p2, p3);
        case PATTERN_METAL:          return SampleMetal(pos, center, scale, p1, p2, p3);
        case PATTERN_RADIAL_BRUSHED: return SampleRadialBrushed(pos, center, scale, p1, p2, p3);
        case PATTERN_CARBON_FIBER:   return SampleCarbonFiber(pos, center, scale, p1, p2, p3);
        case PATTERN_LEATHER:        return SampleLeather(pos, center, scale, p1, p2, p3);
        case PATTERN_BRUSHED_CROSS:  return SampleBrushedCross(pos, center, scale, p1, p2, p3);
        case PATTERN_SATIN:          return SampleSatin(pos, center, scale, p1, p2, p3);
        case PATTERN_CONCRETE:       return SampleConcrete(pos, center, scale, p1, p2, p3);
        case PATTERN_FABRIC:         return SampleFabric(pos, center, scale, p1, p2, p3);
        case PATTERN_PAPER:          return SamplePaper(pos, center, scale, p1, p2, p3);
        case PATTERN_FROSTED:        return SampleFrosted(pos, center, scale, p1, p2, p3);
        case PATTERN_DIAMOND_PLATE:  return SampleDiamondPlate(pos, center, scale, p1, p2, p3);
        case PATTERN_KNURLED:        return SampleKnurled(pos, center, scale, p1, p2, p3);
        case PATTERN_HEX_GRID:       return SampleHexGrid(pos, center, scale, p1, p2, p3);
        case PATTERN_PERFORATED:     return SamplePerforated(pos, center, scale, p1, p2, p3);
        case PATTERN_WOOD_GRAIN:     return SampleWoodGrain(pos, center, scale, p1, p2, p3);
        case PATTERN_MARBLE:         return SampleMarble(pos, center, scale, p1, p2, p3);
        case PATTERN_CERAMIC:        return SampleCeramic(pos, center, scale, p1, p2, p3);
        case PATTERN_CIRCUIT:        return SampleCircuit(pos, center, scale, p1, p2, p3);
        case PATTERN_NOISE_ORGANIC:  return SampleNoiseOrganic(pos, center, scale, p1, p2, p3);
        default: return 0.0;
    }
}

// ============================================================================
// Pattern color palette interpolation
// ============================================================================
// Mirrors InterpolateGradientColors from UIGradients.cginc, defined here to
// avoid a circular include (UIGradients.cginc already includes UIPatterns.cginc).
float4 InterpolatePatternColors(float4 c0, float4 c1, float4 c2, float4 c3, float t, int numColors)
{
    // Triangle wave: bounces 0→1→0→1… for seamless tiling
    t = 1.0 - abs(frac(t * 0.5) * 2.0 - 1.0);
    if (numColors <= 2)
    {
        return lerp(c0, c1, smoothstep(0.0, 1.0, t));
    }
    else if (numColors == 3)
    {
        float h = 0.5;
        if (t < h) return lerp(c0, c1, smoothstep(0.0, 1.0, t / h));
        else       return lerp(c1, c2, smoothstep(0.0, 1.0, (t - h) / h));
    }
    else // 4 stops
    {
        float s = 1.0 / 3.0;
        if      (t < s)       return lerp(c0, c1, smoothstep(0.0, 1.0, t / s));
        else if (t < 2.0 * s) return lerp(c1, c2, smoothstep(0.0, 1.0, (t - s) / s));
        else                  return lerp(c2, c3, smoothstep(0.0, 1.0, (t - 2.0 * s) / s));
    }
}

// Map a pixel's pattern value to a palette lookup position [0,1].
// patternValue should have intensity/contrast already applied.
// NOTE: avoid calling SamplePatternValue here — it contains a 20-case switch and
// the HLSL compiler would have to inline it per-call inside another switch, causing
// combinatorial code explosion and extremely long compile times.
float SamplePatternColorPosition(float patternValue, int colorType)
{
    if (colorType == PATTERN_COLORTYPE_1)
    {
        // Signed-range: map [-1,+1] linearly → [0,1]
        return saturate((patternValue + 1.0) * 0.5);
    }
    if (colorType == PATTERN_COLORTYPE_2)
    {
        // Magnitude: flat areas → 0, strong features → 1
        return saturate(abs(patternValue));
    }
    if (colorType == PATTERN_COLORTYPE_3)
    {
        // Feature id: irregular banding — wraps at multiples of e for visible distinct regions
        return frac(abs(patternValue) * 2.718281828);
    }
    // PATTERN_COLORTYPE_4 — layered depth variation via sine banding
    return abs(sin(patternValue * 3.14159265));
}

// ============================================================================
// Main entry point — matches the original ApplyMaterialPattern signature
// ============================================================================
float3 ApplyMaterialPattern(float3 baseColor, float2 uv, UIComponent component, 
                          float currentValue, float angleRange,
                          out float specularMod, out float2 normalOffset)
{
    specularMod = 1.0;
    normalOffset = float2(0.0, 0.0);
    
    // Check if pattern is enabled (patternEnabled flag replaces checking if patternType is not NONE)
    if (component.patternEnabled < 0.5) return baseColor;
    
    int patType = (int)(component.patternType + 0.5);
    
    float2 center = float2(0.5, 0.5);
    float2 pos = uv - center;
    
    // Calculate rotation angle — start with pattern offset
    float rotationAngle = radians(component.patternOffset);
    
    // Apply rotation based on value if enabled
    if (component.patternRotateWithValue > 0.5) {
        rotationAngle += radians(currentValue * angleRange);
    }
    else if (component.patternModWithValue > 0.5) {
        float shimmerAmount = sin(currentValue * 3.14159265359 * 2.0 * component.patternModFrequency) * component.patternModAmount;
        rotationAngle += radians(shimmerAmount);
    }
    
    // Apply rotation
    if (abs(rotationAngle) > 0.001) {
        float cosA = cos(rotationAngle);
        float sinA = sin(rotationAngle);
        pos = float2(
            pos.x * cosA - pos.y * sinA,
            pos.x * sinA + pos.y * cosA
        );
    }
    
    float scale = component.patternScale;
    float p1 = component.patternParam1;
    float p2 = component.patternParam2;
    float p3 = component.patternParam3;
    
    float pattern = SamplePatternValue(patType, pos, center, scale, p1, p2, p3) * component.patternIntensity;
    
    // Use hardware screen-space derivatives for normal computation.
    // The GPU already evaluates adjacent pixels in 2x2 quads, so ddx/ddy
    // are free register reads — no extra SamplePatternValue calls needed.
    normalOffset = float2(-ddx(pattern), -ddy(pattern)) * component.patternRoughnessEffect;
    
    // Counter-rotate normals to keep lighting direction consistent
    float counterAngle = radians(component.patternOffset);
    if (component.patternRotateWithValue > 0.5) {
        counterAngle += radians(currentValue * angleRange);
    }
    else if (component.patternModWithValue > 0.5) {
        float shimmerAmount = sin(currentValue * 3.14159265359 * 2.0 * component.patternModFrequency) * component.patternModAmount;
        counterAngle += radians(shimmerAmount);
    }
    
    if (abs(counterAngle) > 0.001) {
        float cosA = cos(-counterAngle);
        float sinA = sin(-counterAngle);
        normalOffset = float2(
            normalOffset.x * cosA - normalOffset.y * sinA,
            normalOffset.x * sinA + normalOffset.y * cosA
        );
    }
    
    // Apply contrast
    pattern = sign(pattern) * pow(abs(pattern), 1.0 / component.patternContrast);
    
    // Specular modifier
    specularMod = 1.0 + (pattern * component.patternSpecularEffect * 10.0);
    
    // Pattern color compositing — applied when patternColorEnabled is set
    if (component.patternColorEnabled > 0.5)
    {
        float palettePos = SamplePatternColorPosition(pattern, component.patternColorType);
        float3 patternColor = InterpolatePatternColors(
            component.patternColorA, component.patternColorB,
            component.patternColorC, component.patternColorD,
            palettePos, component.patternColorUsed).rgb;

        int blendMode = component.patternColorMode;
        if (blendMode == 0) // Modulate: palette color brightness-modulated by pattern strength
        {
            return patternColor * (1.0 + pattern);
        }
        else if (blendMode == 1) // Lerp: base color blends to palette color at strong features
        {
            return lerp(baseColor, patternColor, saturate(abs(pattern)));
        }
        else if (blendMode == 2) // Additive: palette color added at strong positive features
        {
            return baseColor + patternColor * saturate(pattern);
        }
        else // Multiply: palette color tints / darkens base
        {
            return baseColor * lerp(float3(1, 1, 1), patternColor, saturate(abs(pattern)));
        }
    }

    // Pattern color disabled: original brightness modulation (zero regression)
    return baseColor * (1.0 + pattern);
}

#endif