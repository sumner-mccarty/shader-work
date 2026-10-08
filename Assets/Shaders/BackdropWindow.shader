// ============================================================================
// BackdropWindow.shader — a WINDOW onto a live background field (2026-10-08)
// ============================================================================
// Draws whatever a background FIELD shows at this element's own screen position: a procedural
// Backdrop* shader rendered once per frame into a screen-sized texture by UiBackdropFields (or the
// look's wallpaper). Because every window samples the SAME texture at its SCREEN position, a row of
// cards, a menu and a panel that all name one field show one continuous picture across all of them —
// the cross-component effect — and the field's cost is paid once, not per element.
//
// Shape: a rounded rectangle in the element's own rect (`_RectSize`, set by BackdropFill), with an
// inset, an anti-aliased edge, an optional lens refraction near the edge, a rim light and a top sheen.
// Blur is a mip level of the field texture (the field renders with mips). Standard UGUI contract:
// vertex colour, stencil masks and RectMask2D clipping all work.
//
// Cheap by construction: one texture sample (two with refraction), no loops — nothing like the SDF
// widget shaders' FXC budget, and no widget shader includes it.
// ============================================================================

Shader "UI/BackdropWindow"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Field)]
        _FieldTex ("Field (bound by BackdropFill)", 2D) = "black" {}
        _FieldUV ("Field UV: screen 0..1 -> field (scale xy, offset zw)", Vector) = (1,1,0,0)
        _Opacity ("Opacity", Range(0, 1)) = 1
        _Blur ("Blur (mip level)", Range(0, 8)) = 0
        _Brightness ("Brightness", Range(-0.5, 0.5)) = 0
        _Saturation ("Saturation", Range(0, 2)) = 1

        [Header(Shape)]
        _RectSize ("Rect size (canvas units, set by BackdropFill)", Vector) = (100,100,0,0)
        _Radius ("Corner radius", Float) = 12
        _Inset ("Inset", Float) = 0
        _Softness ("Edge softness (screen px)", Range(0.5, 16)) = 1

        [Header(Glass)]
        _Refract ("Edge refraction (canvas units)", Range(0, 40)) = 0
        _RefractWidth ("Refraction band (canvas units)", Range(1, 80)) = 18
        _Rim ("Rim light", Range(0, 2)) = 0
        _RimWidth ("Rim width (canvas units)", Range(0.5, 24)) = 3
        _RimColor ("Rim colour", Color) = (1,1,1,0.8)
        _Sheen ("Top sheen", Range(0, 1)) = 0

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
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

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
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
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
                float4 screenPos     : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _FieldTex;
            float4 _FieldUV;
            fixed4 _Color;
            float4 _ClipRect;
            float _Opacity, _Blur, _Brightness, _Saturation;
            float4 _RectSize;
            float _Radius, _Inset, _Softness;
            float _Refract, _RefractWidth, _Rim, _RimWidth, _Sheen;
            float4 _RimColor;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.screenPos = ComputeScreenPos(OUT.vertex);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            // Rounded box: signed distance (negative inside), b = half size, r = corner radius.
            float sdRoundBox(float2 p, float2 b, float r)
            {
                float2 q = abs(p) - b + r;
                return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 size = max(_RectSize.xy, 1.0);
                float2 p = (IN.texcoord - 0.5) * size;                      // canvas units, y up
                float2 hb = size * 0.5 - _Inset;
                float r = clamp(_Radius, 0.0, min(hb.x, hb.y));
                float d = sdRoundBox(p, hb, r);

                // one screen pixel in canvas units: the anti-aliasing width and the unit converter
                float px = max(fwidth(p.x), fwidth(p.y));
                float mask = saturate(0.5 - d / max(px * _Softness, 1e-4));

                // outward normal of the box (finite differences of the SDF, exact enough for a lens)
                float e = max(px, 0.5);
                float2 n = float2(sdRoundBox(p + float2(e, 0), hb, r) - sdRoundBox(p - float2(e, 0), hb, r),
                                  sdRoundBox(p + float2(0, e), hb, r) - sdRoundBox(p - float2(0, e), hb, r));
                n = n / max(length(n), 1e-5);

                float2 suv = IN.screenPos.xy / max(IN.screenPos.w, 1e-5);
                // lens: inside the edge band, the picture is pulled from further out (a convex edge bends inward)
                float band = saturate(1.0 + d / max(_RefractWidth, 1e-3));    // 1 at the edge, 0 a band-width in
                float2 bend = n * (_Refract * band * band) / max(px, 1e-5);  // canvas units -> screen pixels
                suv += bend / max(_ScreenParams.xy, 1.0);

                float2 fuv = suv * _FieldUV.xy + _FieldUV.zw;
                float3 col = tex2Dlod(_FieldTex, float4(fuv, 0.0, _Blur)).rgb;

                col += _Brightness;
                float l = dot(col, float3(0.2126, 0.7152, 0.0722));
                col = lerp(float3(l, l, l), col, _Saturation);

                // rim light on the inner edge, brighter where the edge faces up (light from above)
                float rim = saturate(1.0 + d / max(_RimWidth, 1e-3));
                col += _RimColor.rgb * (_Rim * _RimColor.a * rim * rim * (0.55 + 0.45 * n.y));
                // a soft clear-coat sheen over the top of the shape
                col += _Sheen * 0.22 * smoothstep(0.15, 1.0, IN.texcoord.y);

                fixed4 c = fixed4(saturate(col), mask * _Opacity) * IN.color;

                #ifdef UNITY_UI_CLIP_RECT
                c.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif
                #ifdef UNITY_UI_ALPHACLIP
                clip(c.a - 0.001);
                #endif
                return c;
            }
            ENDCG
        }
    }
}
