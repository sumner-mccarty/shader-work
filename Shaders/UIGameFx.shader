// ============================================================================
// UIGameFx.shader — additive blending for the screen-wide game FX layer
// ============================================================================
// The one thing UI/Default cannot do: ADD light instead of covering what is
// behind it. A spark drawn with alpha blending over a starfield is a grey
// smudge that gets darker as it fades; the same spark added is light leaving
// the screen, which is the whole look the play mode is after.
//
// Deliberately minimal. No _ClipRect, no stencil, no SDF: the FX layer lives
// ABOVE the panel workspace and is never inside a mask (that is the entire
// reason it exists — see GameFx.cs), and every particle is a soft procedural
// sprite, so there is nothing here to clip or shape.
// ============================================================================

Shader "UI/GameFx"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        ColorMask [_ColorMask]
        // Additive, scaled by the vertex/tint alpha — so a particle still FADES
        // by driving its Image colour's alpha, exactly like every other UI fade
        // in the app, while never darkening the sky underneath it.
        Blend SrcAlpha One

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, IN.texcoord) * IN.color;
                // The sprite's own alpha shapes the particle; the vertex alpha fades it. Folded
                // into alpha rather than rgb so one Blend covers both.
                //
                // 1.5, not 2. Squaring is the natural-looking fade, but it also throws away most
                // of the particle's brightness for most of its life — over a bright sky the
                // sparks were washed-out smudges rather than light. This keeps the shape of the
                // curve and gets the energy back.
                c.a = pow(c.a, 1.5) * 1.35;
                return c;
            }
            ENDCG
        }
    }
}
