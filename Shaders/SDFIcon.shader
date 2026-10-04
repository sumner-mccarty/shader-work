Shader "UI/SDFIcon"
{
    // A UGUI Image that draws a SIGNED DISTANCE FIELD instead of a bitmap.
    //
    // The rack's marks are drawn from primitives in C# (PanelIcons) and that is right for the
    // geometric ones — a play triangle, a chain link, a tray and an arrow are all better as four
    // lines of code than as an asset to keep in sync. It is the wrong tool for anything with a
    // DRAWN line in it: a rubber duck was attempted four times in primitives and came out a blob
    // every time, because the charm of that shape is in curves discs and capsules cannot hold at
    // 30px.
    //
    // So art gets to be art — but not as a plain sprite. A bitmap mask is baked at one size: shrunk
    // to a mixer button its thin parts alias into dashes, blown up on a large panel its edges go
    // soft. The field stores the distance to the nearest edge per texel, so the edge is RECOVERED
    // at draw time (one smoothstep, one texel of screen space wide) and one 128px texture serves a
    // 20px button and a 200px hero mark equally well.
    //
    // Authored by Tools/icon_sdf.py, which writes Assets/Resources/Icons/<name>.png with 0.5 on the
    // edge — the same encoding every SDF text shader uses.
    Properties
    {
        [PerRendererData] _MainTex ("SDF (0.5 = edge)", 2D) = "black" {}
        _Color ("Tint", Color) = (1,1,1,1)

        // Extra softness in FIELD units, on top of the one-pixel screen-space edge. 0 is a hard
        // crisp mark, which is what a UI icon wants; it exists so a caller can deliberately blur
        // one (a shadow, a ghosted "off" state) without a second asset.
        _Softness ("Extra softness", Range(0, 0.5)) = 0

        // Grow or shrink the shape in field units — negative thins it, positive fattens it. Cheap
        // weight adjustment for a mark that reads too light against a dark button.
        _Dilate ("Dilate", Range(-0.3, 0.3)) = 0

        // UGUI mask/stencil plumbing. Required, not decorative: without it an icon inside a
        // RectMask2D or a Mask draws over its own clip.
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "SDFICON"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex        : SV_POSITION;
                fixed4 color         : COLOR;
                float2 texcoord      : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _Softness;
            float _Dilate;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float d = tex2D(_MainTex, IN.texcoord).r;

                // The edge, recovered at whatever size this is being drawn. fwidth is the field's
                // rate of change across ONE SCREEN PIXEL, so the ramp is always about a pixel wide
                // however the icon is scaled — that is the entire trick, and why this beats a
                // bitmap at both ends of the size range. The floor stops a degenerate derivative
                // (a zero-area quad mid-layout) from producing a hard-edged flash.
                float w = max(fwidth(d), 1e-4) + _Softness;
                float alpha = smoothstep(0.5 - _Dilate - w, 0.5 - _Dilate + w, d);

                half4 color = IN.color;
                color.a *= alpha;

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(color.a - 0.001);
                #endif

                return color;
            }
        ENDCG
        }
    }
}
