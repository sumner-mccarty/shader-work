// SDFKnobShapes.cginc
// Knob shape dispatcher — includes individual shape files from KnobShapes/.
//
// Shape groups:
//   BASIC (0-7):     Circle, GripNubs, Polygon, DShaft, Star, Squircle, Fluted, Cross
//   EXTENDED (8-15): ChickenHead, Arrow, Gear, Skirted, OvalPointer, MushroomCap, DaviesIndicator, ColletKnob
//   SPECIALTY (16-21): RingPointer, BlobStar, CapScrew, TaperDisc, FaderCap, FaderCapWide
//   TEXTURE (100):   Texture2DArray sampling
//
// All shapes compile unconditionally — no shader_feature keywords needed.

#ifndef SDF_KNOB_SHAPES_INCLUDED
#define SDF_KNOB_SHAPES_INCLUDED

// Roundness uniform consumed by getKnobSDF.
uniform float _KnobRoundness;

// Texture SDF support
#include "SDFTextures.cginc"
uniform float  _KnobShapeTexLayer;
uniform float2 _KnobShapeTexScale;
// _SDFShapeTexSpread is declared in SDFTextures.cginc, next to the array it describes.

// --- Basic shapes (0-7) ---
// Cases 0 (Circle), 4 (Star), 7 (Cross) use SDFPrimitives directly — no separate file needed.
#include "KnobShapes/GripNubsSDF.cginc"      // case 1
#include "KnobShapes/PolygonSDF.cginc"        // case 2  (also used by ColletKnob)
#include "KnobShapes/DShaftSDF.cginc"         // case 3
#include "KnobShapes/SquircleSDF.cginc"       // case 5
#include "KnobShapes/FlutedSDF.cginc"         // case 6

// --- Extended shapes (8-15) ---
#include "KnobShapes/ChickenHeadSDF.cginc"    // case 8
#include "KnobShapes/ArrowKnobSDF.cginc"      // case 9
#include "KnobShapes/GearKnobSDF.cginc"       // case 10
#include "KnobShapes/SkirtedKnobSDF.cginc"    // case 11
#include "KnobShapes/OvalPointerSDF.cginc"     // case 12
#include "KnobShapes/MushroomCapSDF.cginc"     // case 13
#include "KnobShapes/DaviesIndicatorSDF.cginc" // case 14
#include "KnobShapes/ColletKnobSDF.cginc"      // case 15

// --- Specialty shapes (16-21) ---
#include "KnobShapes/RingPointerSDF.cginc"    // case 16
#include "KnobShapes/BlobStarSDF.cginc"       // case 17
#include "KnobShapes/CapScrewSDF.cginc"       // case 18
#include "KnobShapes/TaperDiscSDF.cginc"      // case 19
#include "KnobShapes/FaderCapSDF.cginc"       // case 20
#include "KnobShapes/FaderCapWideSDF.cginc"   // case 21

// ===================================================================
// getKnobSDF — dispatch to shape SDF based on shapeType integer.
// ===================================================================
float getKnobSDF(float2 p, float radius, float shapeType, float shapeScale,
                 float param1, float param2, float param3,
                 float param4, float param5, float param6,
                 float texLayer = -2, float2 texScale = float2(0, 0))
{
    int shape = (int)shapeType;
    float rawSDF;
    [forcecase]
    switch (shape) {
        // --- Basic (always available) ---
        case 0:  rawSDF = CircleSDF(p, radius); break;
        case 1:  rawSDF = gripNubsSDF(p, radius, max(2, (int)shapeScale), param2, param1, param3); break;
        case 2:  rawSDF = PolygonSDF(p, radius, shapeScale, param1, param2, param3); break;
        case 3:  rawSDF = DShaftSDF(p, radius, param1, param2, param3); break;
        case 4:  { int pts = max(3, (int)shapeScale); float inner = lerp(0.3, 0.8, param1);
                   rawSDF = StarSDF(p, radius, pts, lerp(2.0, float(pts) - 0.01, inner)) - param2 * 0.02; break; }
        case 5:  rawSDF = SquircleSDF(p, radius, param1, param2); break;
        case 6:  rawSDF = FlutedSDF(p, radius, shapeScale, param1, param2, param3); break;
        case 7:  rawSDF = CrossSDF(p, float2(radius * lerp(0.1, 0.9, param1),
                                              radius * lerp(0.3, 1.0, param2)), param3 * 0.02); break;
        // --- Extended (8-15) ---
        case 8:  rawSDF = ChickenHeadSDF(p, radius, param1, param2, param3); break;
        case 9:  rawSDF = ArrowKnobSDF(p, radius, param1, param2, param3); break;
        case 10: rawSDF = GearKnobSDF(p, radius, shapeScale, param1, param2, param3); break;
        case 11: rawSDF = SkirtedKnobSDF(p, radius, param1, param2, param3); break;
        case 12: rawSDF = OvalPointerSDF(p, radius, param1, param2, param3); break;
        case 13: rawSDF = MushroomCapSDF(p, radius, param1, param2, param3); break;
        case 14: rawSDF = DaviesIndicatorSDF(p, radius, param1, param2, param3); break;
        case 15: rawSDF = ColletKnobSDF(p, radius, shapeScale, param1, param2, param3); break;
        // --- Specialty (16-21) ---
        case 16: rawSDF = RingPointerSDF(p, radius, param1, param2, param3); break;
        case 17: rawSDF = BlobStarSDF(p, radius, shapeScale, param1, param2, param3); break;
        case 18: rawSDF = CapScrewSDF(p, radius, param1, param2, param3); break;
        case 19: rawSDF = TaperDiscSDF(p, radius, param1, param2, param3); break;
        case 20: rawSDF = FaderCapSDF(p, radius, param1, param2, param3); break;
        case 21: rawSDF = FaderCapWideSDF(p, radius, param1, param2, param3); break;
        // --- Texture (100) ---
        case 100: {
            int   tl = (int)((texLayer > -1.5) ? texLayer : _KnobShapeTexLayer);
            float2 ts = (texScale.x + texScale.y > 0.001) ? texScale : _KnobShapeTexScale;
            float2 texUV = (p / radius) * ts * 0.5 + 0.5;
            // sampleTextureSDF returns signedDist_norm / spread.  Multiply by
            // spread / texScale to restore unit-gradient SDF in p-space so bevel
            // geometry and extrusion insets behave identically to parametric shapes.
            float tsScalar   = max(max(abs(ts.x), abs(ts.y)), 0.001);
            float spreadCorr = max(_SDFShapeTexSpread, 0.001);
            rawSDF = sampleTextureSDF(texUV, tl) * (spreadCorr / tsScalar) * radius;
            break; }
        default: rawSDF = CircleSDF(p, radius); break;
    }
    float roundAmt = min(_KnobRoundness * radius * 0.15, radius * 0.4);
    return rawSDF - roundAmt;
}

#endif // SDF_KNOB_SHAPES_INCLUDED
