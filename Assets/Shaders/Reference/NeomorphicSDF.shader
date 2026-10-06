// ============================================================================
// LEGACY SHADER - DEPRECATED - DO NOT USE
// ============================================================================
// This shader has been deprecated and replaced with the new SDFKnob.shader
// architecture that uses pure function libraries.
//
// MIGRATION PATH:
// 1. Use SDFKnob.shader as your reference implementation
// 2. See Reference/LEGACY_SHADERS.md for full migration guide
// 3. Contact team before attempting to use this shader
//
// This is a placeholder to prevent compilation errors. The actual shader
// code has been preserved in Reference/NeomorphicSDF.shader.backup
// ============================================================================

Shader "Hidden/DeprecatedNeomorphicSDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct appdata { float4 vertex : POSITION; };
            struct v2f { float4 vertex : SV_POSITION; };
            
            v2f vert (appdata v) { 
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target {
                // Return magenta to indicate deprecated shader
                return fixed4(1, 0, 1, 1);
            }
            ENDCG
        }
    }
}
