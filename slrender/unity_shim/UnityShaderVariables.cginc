// slrender — stand-in for Unity's UnityShaderVariables.cginc (written from scratch).
//
// The built-in globals a material sees. slrender fills these per draw (see slrender/render.py,
// BUILTIN_GLOBALS): time is frozen at 0 unless a job sets it, the matrices map the 0..1 Blit quad
// onto the target, and _ScreenParams is the target size — the same inputs Graphics.Blit gives.
#ifndef SLR_SHADER_VARIABLES_INCLUDED
#define SLR_SHADER_VARIABLES_INCLUDED

float4 _Time;              // (t/20, t, t*2, t*3)
float4 _SinTime;
float4 _CosTime;
float4 unity_DeltaTime;
float4 _ScreenParams;      // (w, h, 1+1/w, 1+1/h)
float4 _ProjectionParams;  // (1 = not flipped, near, far, 1/far)
float4 _ZBufferParams;
float4 unity_OrthoParams;
float3 _WorldSpaceCameraPos;

float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
float4x4 unity_MatrixV;
float4x4 unity_MatrixVP;
float4x4 glstate_matrix_projection;

float unity_GUIZTestMode;

#define UNITY_MATRIX_M   unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V   unity_MatrixV
#define UNITY_MATRIX_P   glstate_matrix_projection
#define UNITY_MATRIX_VP  unity_MatrixVP
#define UNITY_MATRIX_MVP mul(unity_MatrixVP, unity_ObjectToWorld)
#define UNITY_MATRIX_MV  mul(unity_MatrixV, unity_ObjectToWorld)

// Unity's UnityShaderVariables pulls in UnityShaderUtilities, so these are visible to every
// CGPROGRAM even without UnityCG.cginc (Glow.shader relies on it).
inline float4 UnityObjectToClipPos(in float3 pos)
{
    return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(pos, 1.0)));
}
inline float4 UnityObjectToClipPos(float4 pos) { return UnityObjectToClipPos(pos.xyz); }

#endif // SLR_SHADER_VARIABLES_INCLUDED
