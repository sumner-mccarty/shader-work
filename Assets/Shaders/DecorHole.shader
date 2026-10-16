// ============================================================================
// DecorHole.shader — the faceplate's apertures, cut out of the decor
// ============================================================================
// Decor is painted as if the faceplate were OFF the unit (Docs/Decor.md §2.5): every key, knob, pad, lamp and
// screen comes through a hole in the plate, so paint and vinyl stop at the hole's edge — trimmed, with a knife
// margin of bare plate around the part. One rounded box (or circle: radius = half the shorter side) per
// mounted part, ERASED from all four decor targets after the items are drawn. The height target loses the
// vinyl inside the cut, so the resolve gives the cut its edge: a lit lip on the lamp side, a cast shadow and
// contact darkening on the other — the cut reads as a thickness of sticker, not a mask.
//
// Geometry: DecorRenderer's centred unit quad scaled to the hole's bounding box (_Quad = half extents) and
// rotated with the part; _Half = the cut's half size, _Radius = its corner radius (all canvas units).
// ============================================================================

Shader "UI/Decor/Hole"
{
    Properties
    {
        _Half ("Half size", Vector) = (10, 10, 0, 0)
        _Radius ("Corner radius", Float) = 2
        _Quad ("Quad half extents", Vector) = (12, 12, 0, 0)
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        Cull Off ZWrite Off ZTest Always Lighting Off

        Pass
        {
            Name "Cut"
            Blend Zero OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #include "CG/Core/UIDecorPaint.cginc"

            float4 _Half;
            float _Radius;
            float4 _Quad;

            struct appdata { float4 vertex : POSITION; };
            struct v2f { float4 pos : SV_POSITION; float2 p : TEXCOORD0; };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.p = v.vertex.xy * 2.0 * _Quad.xy;     // unit quad (-0.5..0.5) → canvas units about the centre
                return o;
            }

            DecorOut frag(v2f i)
            {
                float r = min(_Radius, min(_Half.x, _Half.y));
                float2 q = abs(i.p) - (_Half.xy - r);
                float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
                float aa = max(fwidth(d), 1e-3);
                return DecorErase(saturate(0.5 - d / aa));
            }
            ENDCG
        }
    }
}
