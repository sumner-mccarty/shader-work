// slrender test fixture: CG program, legacy sampler2D, Properties defaults, keywords, blend Off.
Shader "Slr/TexIdentity"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _Mode ("Mode", Int) = 0
    }
    SubShader
    {
        Cull Off ZWrite Off
        Blend Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ SLR_RED_ON
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Tint;
            int _Mode;

            struct v2f { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv) * _Tint;
                if (_Mode == 1) c = fixed4(i.uv, 0, 1);                 // uv probe
                if (_Mode == 2) c = fixed4(ddx(i.uv.x) * 64, ddy(i.uv.y) * 64, 0, 1);  // derivative sign probe
            #ifdef SLR_RED_ON
                c.rgb = float3(1, 0, 0);
            #endif
                return c;
            }
            ENDCG
        }
    }
}
