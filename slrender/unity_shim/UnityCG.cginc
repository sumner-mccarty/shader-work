// slrender — stand-in for Unity's UnityCG.cginc (written from scratch; not Unity's file).
// Covers the helpers UI / full-quad shaders use. Add to it when a shader needs more — a DXC
// "undeclared identifier" error from `python -m slrender compile` names exactly what is missing.
#ifndef SLR_UNITY_CG_INCLUDED
#define SLR_UNITY_CG_INCLUDED

#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"

#define UNITY_PI         3.14159265359f
#define UNITY_TWO_PI     6.28318530718f
#define UNITY_FOUR_PI    12.56637061436f
#define UNITY_INV_PI     0.31830988618f
#define UNITY_INV_TWO_PI 0.15915494309f
#define UNITY_HALF_PI    1.57079632679f

struct appdata_base     { float4 vertex : POSITION; float3 normal : NORMAL; float4 texcoord : TEXCOORD0; };
struct appdata_tan      { float4 vertex : POSITION; float4 tangent : TANGENT; float3 normal : NORMAL; float4 texcoord : TEXCOORD0; };
struct appdata_full     { float4 vertex : POSITION; float4 tangent : TANGENT; float3 normal : NORMAL;
                          float4 texcoord : TEXCOORD0; float4 texcoord1 : TEXCOORD1; float4 texcoord2 : TEXCOORD2;
                          float4 texcoord3 : TEXCOORD3; float4 color : COLOR; };
struct appdata_img      { float4 vertex : POSITION; float2 texcoord : TEXCOORD0; };
struct v2f_img          { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };

#define TRANSFORM_TEX(tex, name) (tex.xy * name##_ST.xy + name##_ST.zw)

inline float3 UnityObjectToViewPos(float3 pos)
{
    return mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(pos, 1.0))).xyz;
}

inline float4 ComputeNonStereoScreenPos(float4 pos)
{
    float4 o = pos * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = pos.zw;
    return o;
}
inline float4 ComputeScreenPos(float4 pos) { return ComputeNonStereoScreenPos(pos); }
inline float4 ComputeGrabScreenPos(float4 pos)
{
    float4 o = pos * 0.5f;
    o.xy = float2(o.x, o.y) + o.w;
    o.zw = pos.zw;
    return o;
}

v2f_img vert_img(appdata_img v)
{
    v2f_img o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    return o;
}

inline float GammaToLinearSpaceExact(float value)
{
    if (value <= 0.04045F) return value / 12.92F;
    else if (value < 1.0F) return pow((value + 0.055F) / 1.055F, 2.4F);
    else return pow(value, 2.2F);
}
inline float3 GammaToLinearSpace(float3 c)
{
    return c * (c * (c * 0.305306011h + 0.682171111h) + 0.012522878h);
}
inline float LinearToGammaSpaceExact(float value)
{
    if (value <= 0.0F) return 0.0F;
    else if (value <= 0.0031308F) return 12.92F * value;
    else if (value < 1.0F) return 1.055F * pow(value, 0.4166667F) - 0.055F;
    else return pow(value, 0.45454545F);
}
inline float3 LinearToGammaSpace(float3 c)
{
    c = max(c, float3(0, 0, 0));
    return max(1.055h * pow(c, 0.416666667h) - 0.055h, 0.h);
}
inline float Luminance(float3 rgb) { return dot(rgb, float3(0.22, 0.707, 0.071)); }

// Gamma colour space (the project setting this renderer models).
#define unity_ColorSpaceGrey        float4(0.5, 0.5, 0.5, 0.5)
#define unity_ColorSpaceDouble      float4(2.0, 2.0, 2.0, 2.0)
#define unity_ColorSpaceLuminance   float4(0.22, 0.707, 0.071, 0.0)

#endif // SLR_UNITY_CG_INCLUDED
