// slrender — stand-in for Unity's HLSLSupport.cginc.
//
// Written from scratch for the headless renderer (it is NOT Unity's file). Unity implicitly
// includes HLSLSupport + UnityShaderVariables at the top of every CGPROGRAM; slrender does the
// same. Only what a desktop D3D11-class Unity compile provides is modelled: `half`/`fixed` are full
// floats (Unity maps them to float on desktop), and DX9-style samplers are emulated with a
// texture+sampler struct, the same trick Unity itself uses when it compiles with DXC.
#ifndef SLR_HLSL_SUPPORT_INCLUDED
#define SLR_HLSL_SUPPORT_INCLUDED

#define UNITY_COMPILER_DXC 1
#define SHADER_API_DESKTOP 1
#define SHADER_TARGET 50
#define UNITY_VERSION 600083

// ── precision types ─────────────────────────────────────────────────────────
// `half` is left to the compiler, as Unity does: without -enable-16bit-types DXC treats it as a
// 32-bit float, which is what desktop Unity gets. (#defining it would also break code that uses
// `half2` as a variable name — legal HLSL, and SDFRhythmTrack does it.) `fixed` is not an HLSL
// type at all; Unity maps it onto half.
#define fixed    half
#define fixed2   half2
#define fixed3   half3
#define fixed4   half4
#define fixed2x2 half2x2
#define fixed3x3 half3x3
#define fixed4x4 half4x4

// ── flow-control attributes ─────────────────────────────────────────────────
#define UNITY_BRANCH  [branch]
#define UNITY_FLATTEN [flatten]
#define UNITY_UNROLL  [unroll]
#define UNITY_UNROLLX(_x) [unroll(_x)]
#define UNITY_LOOP    [loop]
#define UNITY_FASTOPT

#define UNITY_INITIALIZE_OUTPUT(type, name) name = (type)0;
#define UNITY_NEAR_CLIP_VALUE (-1.0)
#define UNITY_UV_STARTS_AT_TOP 0

// ── instancing / stereo: single-pass, non-instanced ─────────────────────────
#define UNITY_VERTEX_INPUT_INSTANCE_ID
#define UNITY_VERTEX_OUTPUT_STEREO
#define UNITY_SETUP_INSTANCE_ID(v)
#define UNITY_TRANSFER_INSTANCE_ID(v, o)
#define UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)
#define UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i, o)
#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
#define UNITY_INSTANCING_BUFFER_START(n)
#define UNITY_INSTANCING_BUFFER_END(n)
#define UNITY_DEFINE_INSTANCED_PROP(t, n) t n;
#define UNITY_ACCESS_INSTANCED_PROP(buf, n) n

// ── DX9-style samplers (DXC has no sampler2D/tex2D) ─────────────────────────
struct sampler2D   { Texture2D<float4>   t; SamplerState s; };
struct sampler3D   { Texture3D<float4>   t; SamplerState s; };
struct samplerCUBE { TextureCube<float4> t; SamplerState s; };
#define sampler2D_float sampler2D
#define sampler2D_half  sampler2D
#define sampler2D_f     sampler2D
#define sampler2D_h     sampler2D

float4 tex2D(sampler2D x, float2 v)                        { return x.t.Sample(x.s, v); }
float4 tex2D(sampler2D x, float2 v, float2 dx, float2 dy)  { return x.t.SampleGrad(x.s, v, dx, dy); }
float4 tex2Dlod(sampler2D x, float4 v)                     { return x.t.SampleLevel(x.s, v.xy, v.w); }
float4 tex2Dbias(sampler2D x, float4 v)                    { return x.t.SampleBias(x.s, v.xy, v.w); }
float4 tex2Dgrad(sampler2D x, float2 v, float2 dx, float2 dy) { return x.t.SampleGrad(x.s, v, dx, dy); }
float4 tex2Dproj(sampler2D x, float4 v)                    { return x.t.Sample(x.s, v.xy / v.w); }
float4 tex2Dproj(sampler2D x, float3 v)                    { return x.t.Sample(x.s, v.xy / v.z); }
float4 tex3D(sampler3D x, float3 v)                        { return x.t.Sample(x.s, v); }
float4 tex3Dlod(sampler3D x, float4 v)                     { return x.t.SampleLevel(x.s, v.xyz, v.w); }
float4 texCUBE(samplerCUBE x, float3 v)                    { return x.t.Sample(x.s, v); }
float4 texCUBElod(samplerCUBE x, float4 v)                 { return x.t.SampleLevel(x.s, v.xyz, v.w); }

// ── modern texture macros (Unity naming: sampler<Name>) ─────────────────────
#define UNITY_DECLARE_TEX2D(tex)              Texture2D tex; SamplerState sampler##tex
#define UNITY_DECLARE_TEX2D_NOSAMPLER(tex)    Texture2D tex
#define UNITY_SAMPLE_TEX2D(tex, uv)           tex.Sample(sampler##tex, uv)
#define UNITY_SAMPLE_TEX2D_LOD(tex, uv, lod)  tex.SampleLevel(sampler##tex, uv, lod)
#define UNITY_SAMPLE_TEX2D_SAMPLER(tex, samplertex, uv) tex.Sample(sampler##samplertex, uv)
#define UNITY_DECLARE_TEX2DARRAY(tex)         Texture2DArray tex; SamplerState sampler##tex
#define UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(tex) Texture2DArray tex
#define UNITY_SAMPLE_TEX2DARRAY(tex, coord)   tex.Sample(sampler##tex, coord)
#define UNITY_SAMPLE_TEX2DARRAY_LOD(tex, coord, lod) tex.SampleLevel(sampler##tex, coord, lod)
#define UNITY_DECLARE_TEXCUBE(tex)            TextureCube tex; SamplerState sampler##tex
#define UNITY_SAMPLE_TEXCUBE(tex, coord)      tex.Sample(sampler##tex, coord)
#define UNITY_SAMPLE_TEXCUBE_LOD(tex, coord, lod) tex.SampleLevel(sampler##tex, coord, lod)

#endif // SLR_HLSL_SUPPORT_INCLUDED
