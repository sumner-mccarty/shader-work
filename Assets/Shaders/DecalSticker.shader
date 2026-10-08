// ============================================================================
// DecalSticker.shader — a die-cut vinyl sticker (sticker layer, Docs/UiDecals.md §4)
// ============================================================================
// One sticker on a UGUI quad (uv 0..1, use a SQUARE quad: the picture is isotropic, centred, -1..1).
// Standard UGUI contract (stencil, _ClipRect, vertex colour tint), Blend SrcAlpha OneMinusSrcAlpha.
//
// Step 1 — shape + die cut:
//   * art = _MainTex alpha read as an SDF-ish mask (0.5 = edge, _SdfSpread = the distance the 0..1 ramp spans),
//     or, with _UseTex off, a procedural _Shape (circle, rounded rect, star, shield, bolt, heart);
//   * a white vinyl margin _Border (uv units) follows the art outline (the die cut = art offset outward),
//     anti-aliased by fwidth; the art is "printed" on it with a keyline and a slight ink step at the edge;
//   * a soft contact shadow (_ShadowOffset / _ShadowSoftness / _ShadowOpacity) is drawn inside the same quad,
//     so leave room: the art fills _ArtSize of the half quad, border and shadow live in the rest.
// Derivatives are taken once, outside every branch; texture reads are tex2Dlod. No reserved HLSL names.
// ============================================================================

Shader "UI/Decal/Sticker"
{
    Properties
    {
        [PerRendererData] _MainTex ("Art mask / sprite (alpha = SDF-ish, rgb = print)", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Art)]
        [Toggle] _UseTex ("Use _MainTex as the art (else procedural _Shape)", Float) = 0
        [Enum(Circle,0,RoundedRect,1,Star,2,Shield,3,Bolt,4,Heart,5)] _Shape ("Procedural shape", Float) = 2
        _SdfSpread ("Texture SDF spread (uv: alpha 0..1 spans this)", Range(0.02, 0.5)) = 0.12
        _ArtSize ("Art size (fraction of the half quad)", Range(0.3, 0.9)) = 0.6
        _ArtColor ("Print colour A (top)", Color) = (0.95, 0.25, 0.35, 1)
        _ArtColor2 ("Print colour B (bottom)", Color) = (0.75, 0.1, 0.3, 1)
        _InkColor ("Keyline / ink colour", Color) = (1, 1, 1, 1)
        _Keyline ("Keyline strength", Range(0, 1)) = 0.8

        [Header(Die cut)]
        _Border ("White vinyl border (uv)", Range(0, 0.15)) = 0.04
        _BorderColor ("Vinyl colour", Color) = (0.97, 0.97, 0.95, 1)

        [Header(Contact shadow)]
        _ShadowOffset ("Shadow offset (uv)", Vector) = (0.012, -0.022, 0, 0)
        _ShadowSoftness ("Shadow softness (uv)", Range(0.002, 0.15)) = 0.03
        _ShadowOpacity ("Shadow opacity", Range(0, 1)) = 0.45

        [Header(Finish)]
        [Enum(Matte,0,Gloss,1,Holo,2,Chrome,3)] _Finish ("Finish", Float) = 1
        _Sheen ("Sheen strength", Range(0, 1)) = 0.6
        _LightDir ("Light direction (xyz, towards the light; x,y move the sheen)", Vector) = (-0.45, 0.55, 0.7, 0)
        _Curve ("Sheet bow (how much the surface tilts away from centre)", Range(0, 0.8)) = 0.3
        _Shininess ("Spec lobe tightness", Range(4, 200)) = 50
        _HoloScale ("Holo band density", Range(0.5, 6)) = 2.2

        [Header(Physical touches)]
        _Peel ("Peeled corner (bottom-right) 0..1", Range(0, 1)) = 0
        _PeelShadow ("Peel shadow strength", Range(0, 1)) = 0.5
        _Bubbles ("Surface bubbles (affect the sheen only)", Range(0, 1)) = 0
        _BubbleScale ("Bubble scale (features across the quad)", Range(1, 8)) = 3
        _BubbleSeed ("Bubble seed", Float) = 1

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
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            float4 _ClipRect;
            float _UseTex, _Shape, _SdfSpread, _ArtSize;
            float4 _ArtColor, _ArtColor2, _InkColor;
            float _Keyline;
            float _Border;
            float4 _BorderColor;
            float4 _ShadowOffset;
            float _ShadowSoftness, _ShadowOpacity;
            float _Finish, _Sheen, _Curve, _Shininess, _HoloScale;
            float4 _LightDir;
            float _Peel, _PeelShadow, _Bubbles, _BubbleScale, _BubbleSeed;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            // ---- procedural art SDFs (negative inside), unit space, roughly -1..1 ------------------------------
            float dot2(float2 v) { return dot(v, v); }

            float sdRoundBox(float2 p, float2 b, float r)
            {
                float2 q = abs(p) - b + r;
                return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
            }

            float sdStar5(float2 p, float r, float rf)
            {
                const float2 k1 = float2(0.809016994375, -0.587785252292);
                const float2 k2 = float2(-0.809016994375, -0.587785252292);
                p.x = abs(p.x);
                p -= 2.0 * max(dot(k1, p), 0.0) * k1;
                p -= 2.0 * max(dot(k2, p), 0.0) * k2;
                p.x = abs(p.x);
                p.y -= r;
                float2 ba = rf * float2(0.587785252292, 0.809016994375) - float2(0.0, 1.0);
                float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
                return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
            }

            float sdHeart(float2 p)
            {
                p.x = abs(p.x);
                float d1 = sqrt(dot2(p - float2(0.25, 0.75))) - 0.35355339;
                float d2 = sqrt(min(dot2(p - float2(0.0, 1.0)), dot2(p - 0.5 * max(p.x + p.y, 0.0))))
                           * sign(p.x - p.y);
                return (p.y + p.x > 1.0) ? d1 : d2;
            }

            float sdBolt(float2 p)
            {
                float2 v[7];
                v[0] = float2(-0.15, 1.0);  v[1] = float2(0.55, 1.0);   v[2] = float2(0.12, 0.25);
                v[3] = float2(0.5, 0.25);   v[4] = float2(-0.3, -1.0);  v[5] = float2(-0.05, -0.1);
                v[6] = float2(-0.5, -0.1);
                float d = dot(p - v[0], p - v[0]);
                float s = 1.0;
                [unroll]
                for (int i = 0; i < 7; i++)
                {
                    int j = (i == 0) ? 6 : i - 1;
                    float2 e = v[j] - v[i];
                    float2 w = p - v[i];
                    float2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
                    d = min(d, dot(b, b));
                    bool3 c = bool3(p.y >= v[i].y, p.y < v[j].y, e.x * w.y > e.y * w.x);
                    if (all(c) || all(!c)) s = -s;
                }
                return s * sqrt(d) - 0.07;                       // rounded corners
            }

            // art distance in QUAD-HALF units (p = uv*2-1): negative inside the art
            float artDist(float2 p, float2 uv)
            {
                float2 q = p / _ArtSize;
                float d;
                if (_Shape < 0.5)      d = length(q) - 0.95;
                else if (_Shape < 1.5) d = sdRoundBox(q, float2(0.9, 0.9), 0.3);
                else if (_Shape < 2.5) d = sdStar5(q + float2(0.0, 0.05), 1.0, 0.42) - 0.08;
                else if (_Shape < 3.5)
                {
                    float2 s = q + float2(0.0, 0.1);
                    float bx = sdRoundBox(s - float2(0.0, 0.1), float2(0.8, 1.0), 0.22);
                    float c1 = length(s - float2(0.8, 0.9)) - 1.8;
                    float c2 = length(s - float2(-0.8, 0.9)) - 1.8;
                    d = max(bx, max(c1, c2)) - 0.05;
                }
                else if (_Shape < 4.5) d = sdBolt(q * 1.02);
                else                   d = sdHeart((q + float2(0.0, 0.58)) * 0.95) / 0.95 - 0.04;
                d *= _ArtSize;
                // texture art: alpha 0.5 = edge; outside the spread it clamps, so keep _Border within _SdfSpread
                float a = tex2Dlod(_MainTex, float4(uv, 0, 0)).a;
                float dt = (0.5 - a) * _SdfSpread * 2.0;
                return lerp(d, dt, step(0.5, _UseTex));
            }

            float hash21(float2 q)
            {
                q = frac(q * float2(123.34, 456.21));
                q += dot(q, q + 45.32);
                return frac(q.x * q.y);
            }

            float lum(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

            // Finishes. n = surface normal (bowed sheet), L = light, p = quad position, base = flat print colour,
            // pr = 0 on the white vinyl border, 1 on the print.
            float3 finish(float3 base, float3 n, float3 L, float2 p, float pr)
            {
                float3 c = base;
                float3 hv = normalize(L + float3(0.0, 0.0, 1.0));
                float ndh = saturate(dot(n, hv));
                float2 ax = normalize(float2(0.8, 0.6));
                float2 ay = float2(-ax.y, ax.x);
                if (_Finish < 0.5)
                {
                    // matte paper: fibre grain + a very soft diffuse roll-off, no highlight
                    float g = hash21(floor(p * 220.0)) - 0.5;
                    c *= 1.0 + 0.05 * g + _Sheen * 0.14 * (saturate(dot(n, L)) - 0.75);
                }
                else if (_Finish < 1.5)
                {
                    // gloss vinyl: clear coat deepens the colour, a moving sheen band + a spec lobe sit on top
                    float t = dot(p, ax) - dot(L.xy, ax) * 2.2;
                    float band = exp(-pow(t / 0.16, 2.0)) + 0.45 * exp(-pow((t - 0.42) / 0.07, 2.0));
                    float spec = pow(ndh, _Shininess);
                    c = lerp(c, c * c * 1.15, 0.25 * _Sheen * pr);
                    c += _Sheen * (0.30 * band + 0.55 * spec);
                }
                else if (_Finish < 2.5)
                {
                    // holo foil: rainbow bands along a diagonal that slide with the light, fine diffraction ruling
                    float h = dot(p, ax) * _HoloScale + dot(L.xy, float2(0.9, 0.6)) * 1.4 + (n.x + n.y) * 0.8;
                    float3 rb = 0.5 + 0.5 * cos(6.28318 * (h + float3(0.0, 0.33, 0.67)));
                    float rule = 0.5 + 0.5 * sin(dot(p, ay) * 90.0 + h * 6.0);
                    rb *= 0.82 + 0.18 * rule;
                    float k = _Sheen * lerp(0.4, 0.6, pr);
                    float3 foil = c * (0.6 + 0.6 * rb) + rb * 0.16;
                    c = lerp(c, foil, k);
                    c += _Sheen * 0.35 * pow(ndh, _Shininess);
                }
                else
                {
                    // chrome: mirror reflecting a horizon-banded studio; the print only tints / modulates it
                    float3 rv = reflect(float3(0.0, 0.0, -1.0), n);
                    float e = rv.y * 6.0 + rv.x * 2.5 + L.y * 0.8 + L.x * 0.4;
                    float sky = smoothstep(-0.6, 0.6, e) * 0.75 + 0.25 * smoothstep(-0.05, 0.05, e);
                    float3 env = lerp(float3(0.16, 0.14, 0.17), float3(0.88, 0.94, 1.0), sky);
                    env += float3(0.25, 0.3, 0.38) * exp(-pow((e - 1.2) / 0.3, 2.0));          // soft box
                    env += 0.35 * exp(-pow(e / 0.07, 2.0));                                      // horizon glint
                    float3 metal = env * (0.7 + 0.7 * lerp(1.0, lum(base), pr)) * lerp(float3(1, 1, 1), base * 1.5, 0.55 * pr);
                    metal += pow(ndh, _Shininess * 2.0) * 0.8;
                    c = lerp(c, metal, saturate(0.35 + _Sheen * 0.65));
                }
                return c;
            }

            float vnoise(float2 q)
            {
                float2 i = floor(q), f = frac(q);
                f = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(hash21(i), hash21(i + float2(1, 0)), f.x),
                            lerp(hash21(i + float2(0, 1)), hash21(i + float2(1, 1)), f.x), f.y);
            }

            // blister height field: low-frequency noise pushed into soft domes
            float bubbleH(float2 p)
            {
                float2 q = p * _BubbleScale * 0.5 + _BubbleSeed * 17.3;
                float n = vnoise(q) * 0.65 + vnoise(q * 2.1 + 5.0) * 0.35;
                return smoothstep(0.5, 0.78, n);
            }

            // flap: the lifted corner, folded back over the sticker (foreshortened by the curl) about the fold line s = s0
            float flapDist(float2 q, float s0, float2 nc, float bw)
            {
                float s = dot(q, nc);
                float2 pm = q + 2.4 * max(s0 - s, 0.0) * nc;      // where this flap point sat before it was lifted
                float d = artDist(pm, pm * 0.5 + 0.5) - bw;
                return max(d, s - s0);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float2 p = uv * 2.0 - 1.0;
                float px = max(fwidth(p.x), fwidth(p.y));            // one pixel in p units (all derivatives here)
                float aa = max(px, 1e-4);

                float bw = _Border * 2.0;
                float dArt = artDist(p, uv);
                float dCut = dArt - bw;                              // die cut outline

                // contact shadow: the die-cut silhouette shifted, then blurred
                float2 so = _ShadowOffset.xy;
                float dSh = artDist(p - so * 2.0, uv - so) - bw;
                float sh = (1.0 - smoothstep(-_ShadowSoftness * 2.0, _ShadowSoftness * 2.0, dSh)) * _ShadowOpacity;

                // ---- print ----
                float3 ink = lerp(_ArtColor.rgb, _ArtColor2.rgb, saturate(0.5 - p.y * 0.55 / _ArtSize));
                float4 tx = tex2Dlod(_MainTex, float4(uv, 0, 0));
                ink = lerp(ink, tx.rgb * ink, step(0.5, _UseTex));
                float key = smoothstep(aa, 0.0, abs(dArt + 0.075 * _ArtSize) - 0.012 * _ArtSize) * _Keyline;
                ink = lerp(ink, _InkColor.rgb, key);
                // ink sits slightly proud: dark hairline where the print meets the white vinyl
                float step_ = smoothstep(2.0 * aa, 0.0, abs(dArt)) * 0.12;
                float printCov = saturate(0.5 - dArt / aa);          // 1 inside the art
                float3 vinyl = _BorderColor.rgb;
                // vinyl edge bevel: a faint light/dark lip on the outer rim
                float rim = smoothstep(3.0 * aa, 0.0, -dCut);
                vinyl *= 1.0 - 0.06 * rim;
                float3 body = lerp(vinyl, ink, printCov) * (1.0 - step_ * (1.0 - printCov));
                float bodyA = saturate(0.5 - dCut / aa);

                // ---- finish ----
                float3 Ld = normalize(_LightDir.xyz + float3(0.0, 0.0, 1e-3));
                float2 bn = float2(0.0, 0.0);
                {
                    float e = 0.03;
                    float h0 = bubbleH(p);
                    bn = float2(bubbleH(p + float2(e, 0.0)) - h0, bubbleH(p + float2(0.0, e)) - h0) / e;
                    bn *= -_Bubbles * 0.14;
                }
                float3 nrm = normalize(float3(-p * _Curve + bn, 1.0));
                body = saturate(finish(body, nrm, Ld, p, printCov));

                // ---- peeled corner ----
                float2 nc = float2(0.70711, -0.70711);
                float s0 = 1.0 - _Peel * 0.9;
                float sp = dot(p, nc);
                float lifted = smoothstep(-aa, aa, sp - s0) * step(1e-4, _Peel);   // 1 beyond the fold
                float dFlap = flapDist(p, s0, nc, bw);
                float flapA = saturate(0.5 - dFlap / aa) * step(1e-4, _Peel);
                float fShadow = (1.0 - smoothstep(-0.02, 0.05, flapDist(p - so * 3.0, s0, nc, bw)))
                                * _PeelShadow * step(1e-4, _Peel);
                float u = max(s0 - sp, 0.0);                          // distance along the flap from the fold
                float3 back = float3(0.95, 0.94, 0.91) * (0.80 + 0.2 * smoothstep(0.0, 0.18, u));
                back += 0.10 * exp(-pow((u - 0.07) / 0.035, 2.0)) * (0.4 + _Sheen);   // curl highlight
                back *= 1.0 - 0.10 * smoothstep(0.08, 0.0, u);                          // crease
                float bodyKeep = 1.0 - lifted;
                bodyA *= bodyKeep;
                sh *= lerp(1.0, bodyKeep, 0.8);

                // ---- composite: shadow, sticker, flap shadow, flap (premultiplied accumulate) ----
                float3 shRgb = float3(0.0, 0.0, 0.02);
                float outA = bodyA + sh * (1.0 - bodyA);
                float3 outC = body * bodyA + shRgb * sh * (1.0 - bodyA);
                float fs = fShadow * (1.0 - flapA);
                outC = outC * (1.0 - fs);                                  // darken what is underneath
                outA = outA + fs * (1.0 - outA);
                outC = outC * (1.0 - flapA) + back * flapA;
                outA = outA * (1.0 - flapA) + flapA;
                float3 rgb = outC / max(outA, 1e-4);

                fixed4 c = fixed4(rgb, outA) * IN.color;

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
