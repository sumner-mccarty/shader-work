// slrender — stand-in for Unity's UnityUI.cginc (written from scratch).
#ifndef SLR_UNITY_UI_INCLUDED
#define SLR_UNITY_UI_INCLUDED

inline float UnityGet2DClipping(in float2 position, in float4 clipRect)
{
    float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
    return inside.x * inside.y;
}

inline fixed4 UnityGetUIDiffuseColor(in float2 position, in sampler2D mainTexture, in sampler2D alphaTexture,
                                     fixed4 textureSampleAdd)
{
    return tex2D(mainTexture, position) + textureSampleAdd;
}

#endif // SLR_UNITY_UI_INCLUDED
