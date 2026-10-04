// SDFTextures.cginc
// Texture-based SDF shape sampling for all SDF UI shaders.
// Provides a Texture2DArray path for unlimited custom shapes alongside procedural shapes.
//
// USAGE:
//   Include AFTER SDFPrimitives.cginc and Constants.cginc.
//   The global _SDFShapeTexArray must be bound by SDFShapeTextureManager.cs.
//   If no real textures are needed, a 1x1x1 dummy (R=0.5) is bound automatically.
//
// CONVENTION:
//   Texture stores SDF in R channel, 0..1 range.
//   0.5 = surface boundary, <0.5 = inside, >0.5 = outside.
//   sampleTextureSDF remaps to signed distance: -1..+1.
//
// SAMPLING:
//   Always uses SampleLevel(LOD 0) — correct for SDF data lookups and
//   required inside raymarching loops where screen-space derivatives are invalid.

#ifndef SDF_TEXTURES_INCLUDED
#define SDF_TEXTURES_INCLUDED

// Sample a texture-based SDF shape.
// uv    : texture coordinates in [0,1] range (caller maps local SDF coords to UV)
// layer : texture array layer index; <0 = disabled (returns large positive = "no shape")
// Returns: signed distance where negative = inside, positive = outside, 0 = surface.

// Global texture array — bound by SDFShapeTextureManager.cs or per-material override.
UNITY_DECLARE_TEX2DARRAY(_SDFShapeTexArray);

// The spread the array was baked at, in normalised [-1,1] space; set by C# (SdfAtlas). Lives
// here, beside the array it describes, because every caller of sampleTextureSDF needs it to
// turn the sample back into a distance -- it used to be declared in SDFKnobShapes, where the
// button's copy of that maths could not see it, and duly went without.
uniform float _SDFShapeTexSpread;

float sampleTextureSDF(float2 uv, int layer)
{
    if (layer < 0)
        return 1e5;

    float v = UNITY_SAMPLE_TEX2DARRAY_LOD(_SDFShapeTexArray, float3(uv, (float)layer), 0).r;
    return (v - 0.5) * 2.0;
}

#endif // SDF_TEXTURES_INCLUDED
