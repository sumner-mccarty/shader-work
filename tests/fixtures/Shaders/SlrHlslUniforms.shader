// slrender test fixture: HLSLPROGRAM (no implicit Unity includes), modern Texture2D/SamplerState,
// a user cbuffer, a float4x4, a float4 array, and premultiplied blending.
Shader "Slr/HlslUniforms"
{
    Properties
    {
        _Gain ("Gain", Range(0, 2)) = 1
    }
    SubShader
    {
        Blend One OneMinusSrcAlpha
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4x4 _UvXform;          // applied as mul(_UvXform, float4(uv, 0, 1))
            float4 _Quad[4];            // colour per uv quadrant: 0=BL 1=BR 2=TL 3=TR
            cbuffer SlrParams { float _Gain; float _Alpha; };

            struct a2v { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
            struct v2f { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = float4(v.vertex.xy * 2.0 - 1.0, 0.0, 1.0);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = mul(_UvXform, float4(i.uv, 0, 1)).xy;
                int q = (uv.x > 0.5 ? 1 : 0) + (uv.y > 0.5 ? 2 : 0);
                float4 c = _Quad[q] * _Gain;
                c.a = _Alpha;
                c.rgb *= c.a;   // premultiplied
                return c;
            }
            ENDHLSL
        }
    }
}
