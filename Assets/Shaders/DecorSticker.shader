// ============================================================================
// DecorSticker.shader — a die-cut vinyl sticker pressed onto a panel's faceplate (Docs/Decor.md §2.2)
// ============================================================================
// Square quad, uv 0..1 = the sticker's bounds in its own (rotated, scaled) frame; picture centred, -1..1.
// Writes the four decor targets (UIDecorPaint.cginc). The sticker is ALBEDO + RELIEF: the plate's lamps shade
// it, the resolve pass drops its edge shadow toward the key lamp, and the finish (gloss vinyl, holo foil,
// chrome, glitter, matte paper) is the plate shader's job (_DecorMat) — so a holo sticker shimmers when the
// lamp moves, like a real one.
//
// ART. Either
//   * a slice of the sticker atlas _StickerArt (Texture2DArray, Resources/Decor/Stickers.png, made by
//     Tools/decor_stickers.py): RGBA = FOUR colour layers, each channel a signed distance field
//     (0.5 = the edge, _ArtSpread = the art-uv distance 0..1 spans). Layers paint in order R, G, B, A with
//     colours _C0.._C3, so every sticker is recolourable; the die cut follows the union of the layers; or
//   * a procedural _Shape (circle, square, star, shield, bolt, heart, burst, bubble, badge, hexagon, diamond,
//     pill, arrow, cloud) with a two-colour print (_C0 → _C1) and a keyline (_C2).
// Then: a vinyl margin (_Border) round the die cut, an ink outline round the art (_Ink, _InkColor), paper
// grain (_Paper), blister bubbles in the relief (_Bubbles), and a corner peeled back (_Peel, _PeelAngle)
// showing the paper backing, lifted high enough to cast its own shadow.
// Derivatives once, at the top; texture reads are LOD 0.
// ============================================================================

Shader "UI/Decor/Sticker"
{
    Properties
    {
        _Color ("Tint (a = opacity)", Color) = (1, 1, 1, 1)
        _ArtSlice ("Atlas slice (-1 = procedural shape)", Float) = -1
        _ArtLayers ("Atlas layers used (1..4)", Float) = 4
        _ArtSpread ("Atlas SDF spread (art uv)", Float) = 0.0625
        _Shape ("Procedural shape", Float) = 2
        _ArtSize ("Art size (fraction of the half quad)", Range(0.3, 0.98)) = 0.86
        _C0 ("Layer 0 / print top", Color) = (0.95, 0.25, 0.35, 1)
        _C1 ("Layer 1 / print bottom", Color) = (0.75, 0.10, 0.30, 1)
        _C2 ("Layer 2 / keyline", Color) = (1, 1, 1, 1)
        _C3 ("Layer 3", Color) = (1, 0.9, 0.2, 1)
        _Ink ("Ink outline", Range(0, 1)) = 0
        _InkColor ("Ink colour", Color) = (0.07, 0.06, 0.08, 1)
        _InkWidth ("Ink width (half quad units)", Range(0, 0.08)) = 0.025
        _Border ("Vinyl border (half quad units)", Range(0, 0.2)) = 0.06
        _BorderColor ("Vinyl colour", Color) = (0.97, 0.97, 0.95, 1)
        _Paper ("Paper grain", Range(0, 1)) = 0
        _Bubbles ("Blister bubbles", Range(0, 1)) = 0
        _Seed ("Seed", Float) = 1
        _Grime ("Grime (wear and dirt)", Range(0, 1)) = 0
        _Peel ("Peeled corner", Range(0, 1)) = 0
        _PeelAngle ("Peeled corner direction (deg, 0 = bottom-right)", Float) = 0
        _DecorMat ("Finish: gloss, metal, holo, glitter", Vector) = (0.8, 0, 0, 0)
        _DecorMat2 ("Finish: emissive, thickness", Vector) = (0, 0.45, 0, 0)
        [NoScaleOffset] _StickerArt ("Sticker atlas", 2DArray) = "" {}
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
        Cull Off ZWrite Off ZTest Always Lighting Off

        Pass
        {
            Name "Paint"
            Blend 0 One OneMinusSrcAlpha
            Blend 1 One OneMinusSrcAlpha
            Blend 2 One OneMinusSrcAlpha
            Blend 3 One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #include "CG/Core/UIDecorPaint.cginc"

            UNITY_DECLARE_TEX2DARRAY(_StickerArt);
            float _ArtSlice, _ArtLayers, _ArtSpread, _Shape, _ArtSize;
            float4 _C0, _C1, _C2, _C3, _InkColor, _BorderColor;
            float _Ink, _InkWidth, _Border, _Paper, _Bubbles, _Seed, _Peel, _PeelAngle, _Grime;

            struct appdata_t { float4 vertex : POSITION; float2 texcoord : TEXCOORD0; };
            struct v2f { float4 vertex : SV_POSITION; float2 texcoord : TEXCOORD0; };

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                return o;
            }

            // ---- procedural shapes (unit space, negative inside) -------------------------------------------
            float sdRoundBox(float2 p, float2 b, float r)
            {
                float2 q = abs(p) - b + r;
                return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
            }
            float sdStarN(float2 p, float r, float n, float m)   // n-point star, m = inner/outer (iq)
            {
                float an = 3.14159265 / n;
                float en = 3.14159265 / m;
                float2 acs = float2(cos(an), sin(an));
                float2 ecs = float2(cos(en), sin(en));
                float bn = fmod(atan2(p.x, p.y) + 6.2831853 * 4.0, 2.0 * an) - an;
                p = length(p) * float2(cos(bn), abs(sin(bn)));
                p -= r * acs;
                p += ecs * clamp(-dot(p, ecs), 0.0, r * acs.y / ecs.y);
                return length(p) * sign(p.x);
            }
            float sdHeart(float2 p)
            {
                p.x = abs(p.x);
                float2 a = p - float2(0.25, 0.75);
                float d1 = length(a) - 0.35355339;
                float2 b = p - 0.5 * max(p.x + p.y, 0.0);
                float2 c = p - float2(0.0, 1.0);
                float d2 = sqrt(min(dot(c, c), dot(b, b))) * sign(p.x - p.y);
                return (p.y + p.x > 1.0) ? d1 : d2;
            }
            float sdSeg(float2 p, float2 a, float2 b)
            {
                float2 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h);
            }
            float sdPoly7(float2 p, float2 v0, float2 v1, float2 v2, float2 v3, float2 v4, float2 v5, float2 v6)
            {
                float2 v[7] = { v0, v1, v2, v3, v4, v5, v6 };
                float d = dot(p - v[0], p - v[0]);
                float s = 1.0;
                [unroll] for (int i = 0; i < 7; i++)
                {
                    int j = (i == 0) ? 6 : i - 1;
                    float2 e = v[j] - v[i];
                    float2 w = p - v[i];
                    float2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
                    d = min(d, dot(b, b));
                    bool3 c = bool3(p.y >= v[i].y, p.y < v[j].y, e.x * w.y > e.y * w.x);
                    if (all(c) || all(!c)) s = -s;
                }
                return s * sqrt(d);
            }
            float sdTri(float2 p, float2 p0, float2 p1, float2 p2)
            {
                float2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;
                float2 v0 = p - p0, v1 = p - p1, v2 = p - p2;
                float2 pq0 = v0 - e0 * saturate(dot(v0, e0) / dot(e0, e0));
                float2 pq1 = v1 - e1 * saturate(dot(v1, e1) / dot(e1, e1));
                float2 pq2 = v2 - e2 * saturate(dot(v2, e2) / dot(e2, e2));
                float sg = sign(e0.x * e2.y - e0.y * e2.x);
                float2 d = min(min(float2(dot(pq0, pq0), sg * (v0.x * e0.y - v0.y * e0.x)),
                                   float2(dot(pq1, pq1), sg * (v1.x * e1.y - v1.y * e1.x))),
                                   float2(dot(pq2, pq2), sg * (v2.x * e2.y - v2.y * e2.x)));
                return -sqrt(d.x) * sign(d.y);
            }
            float sdHex(float2 p, float r)
            {
                const float3 k = float3(-0.866025404, 0.5, 0.577350269);
                p = abs(p);
                p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
                p -= float2(clamp(p.x, -k.z * r, k.z * r), r);
                return length(p) * sign(p.y);
            }

            float shapeDist(float2 q)
            {
                float s = _Shape;
                if (s < 0.5) return length(q) - 0.96;                                         // circle
                if (s < 1.5) return sdRoundBox(q, float2(0.92, 0.92), 0.28);                   // rounded square
                if (s < 2.5) return sdStarN(q + float2(0, 0.06), 1.0, 5.0, 2.6) - 0.06;        // star
                if (s < 3.5)                                                                   // shield
                {
                    float2 sq = q + float2(0.0, 0.08);
                    float bx = sdRoundBox(sq - float2(0.0, 0.12), float2(0.78, 0.92), 0.2);
                    float c1 = length(sq - float2(0.85, 0.95)) - 1.85;
                    float c2 = length(sq - float2(-0.85, 0.95)) - 1.85;
                    return max(bx, max(c1, c2)) - 0.04;
                }
                if (s < 4.5) return sdPoly7(q * 1.02, float2(-0.15, 1.0), float2(0.55, 1.0), float2(0.12, 0.25),
                                            float2(0.5, 0.25), float2(-0.3, -1.0), float2(-0.05, -0.1), float2(-0.5, -0.1)) - 0.06;  // bolt
                if (s < 5.5) return sdHeart((q + float2(0.0, 0.62)) * 0.92) / 0.92 - 0.03;    // heart
                if (s < 6.5) return sdStarN(q, 0.98, 12.0, 4.6) - 0.02;                       // burst
                if (s < 7.5)                                                                   // speech bubble
                {
                    float body = sdRoundBox(q - float2(0, 0.12), float2(0.95, 0.66), 0.42);
                    float tail = sdTri(q, float2(-0.45, -0.3), float2(-0.05, -0.3), float2(-0.66, -0.98)) - 0.03;
                    return min(body, tail);
                }
                if (s < 8.5)                                                                   // scalloped badge
                {
                    float a = atan2(q.y, q.x);
                    return length(q) - (0.88 + 0.07 * cos(a * 16.0));
                }
                if (s < 9.5) return sdHex(float2(q.y, q.x), 0.86) - 0.06;                      // hexagon
                if (s < 10.5) return (abs(q.x) + abs(q.y)) * 0.7071 - 0.68;                    // diamond
                if (s < 11.5) return sdRoundBox(q, float2(0.98, 0.5), 0.5);                    // pill
                if (s < 12.5)                                                                  // arrow
                {
                    float shaft = sdRoundBox(q - float2(-0.25, 0.0), float2(0.6, 0.26), 0.08);
                    float head = sdTri(q, float2(0.2, 0.75), float2(0.98, 0.0), float2(0.2, -0.75));
                    return min(shaft, head - 0.04);
                }
                // cloud
                float c = length(q - float2(-0.45, -0.12)) - 0.42;
                c = min(c, length(q - float2(0.05, 0.18)) - 0.55);
                c = min(c, length(q - float2(0.52, -0.1)) - 0.42);
                c = min(c, sdRoundBox(q - float2(0.03, -0.32), float2(0.86, 0.26), 0.24));
                return c;
            }

            // Art distances in half-quad units for all four layers (big = unused).
            float4 artDist(float2 p)
            {
                float2 q = p / _ArtSize;
                if (_ArtSlice >= -0.5)
                {
                    float2 auv = q * 0.5 + 0.5;
                    float4 t = UNITY_SAMPLE_TEX2DARRAY_LOD(_StickerArt, float3(auv, floor(_ArtSlice + 0.5)), 0);
                    float4 d = (0.5 - t) * (2.0 * _ArtSpread) * 2.0 * _ArtSize;
                    float outside = max(abs(q.x), abs(q.y)) - 1.0;                     // never draw past the slice
                    d = max(d, outside * _ArtSize);
                    float n = clamp(_ArtLayers, 1.0, 4.0);
                    d.y = lerp(1e3, d.y, step(1.5, n));
                    d.z = lerp(1e3, d.z, step(2.5, n));
                    d.w = lerp(1e3, d.w, step(3.5, n));
                    return d;
                }
                float sd = shapeDist(q) * _ArtSize;
                return float4(sd, 1e3, 1e3, 1e3);
            }

            float bubbleH(float2 p)
            {
                float2 q = p * 2.2 + _Seed * 17.3;
                float n = bdNoise(q) * 0.65 + bdNoise(q * 2.1 + 5.0) * 0.35;
                return smoothstep(0.52, 0.8, n);
            }

            // ---- grime: a season on a road case ------------------------------------------------------------
            // One knob (_Grime, 0..1) layers what real vinyl picks up, in the order it happens to it: the die cut
            // frays, the ink wears through at its edges, fine abrasion and a few long scratches cut the clear top,
            // a film of dirt settles (thickest on the rim, patchy, never even), grit gets into it, sun yellows the
            // vinyl, and the surface goes dull wherever it is dirty or scuffed. Everything is a function of the
            // sticker's own frame and _Seed, so one sticker wears the same way at every size and on every machine.
            float2 gRot(float2 q, float a)
            {
                float cs = cos(a), sn = sin(a);
                return float2(cs * q.x - sn * q.y, sn * q.x + cs * q.y);
            }

            // How far the die-cut edge frays (+ = material lost).
            float grimeEdge(float2 p, float g)
            {
                float2 q = p + _Seed * 7.1;
                float wob = bdFbm(q * 7.0, 3.0) - 0.5;                               // the slow ripple of a hand-peeled edge
                float bite = smoothstep(0.64, 0.80, bdFbm(q * 15.0 + 31.0, 2.0));    // the odd nick
                return g * (0.05 * wob + 0.032 * g * bite);
            }

            // Fine abrasion: crowds of hairline streaks in two crossing sets, only where the sticker was rubbed.
            float grimeAbrade(float2 p, float px, float g, float swipe)
            {
                float fy = min(90.0, 0.5 / px);                                      // ~2 px wide on screen, finer on a big surface
                float2 a = gRot(p + _Seed * 3.3, swipe);
                float2 b = gRot(p + _Seed * 5.9, swipe + 1.1);
                float s1 = bdNoise(float2(a.x * 2.2, a.y * fy));
                float s2 = bdNoise(float2(b.x * 2.6, b.y * fy * 0.8));
                float rubbed = smoothstep(0.30, 0.72, bdFbm(p * 1.7 + _Seed * 2.0, 2.0));
                float streak = smoothstep(0.84 - 0.10 * g, 0.97, s1) + 0.7 * smoothstep(0.86 - 0.10 * g, 0.98, s2);
                return saturate(streak) * rubbed * g;
            }

            // Long hairline scratches: one segment per grid cell (and every neighbour's), most following the swipe.
            float grimeScratch(float2 p, float px, float g, float swipe)
            {
                const float cell = 0.6;
                float2 off = float2(_Seed * 1.37, _Seed * 0.73);
                float2 gp = (p + off) / cell;
                float2 ci = floor(gp);
                float cov = 0.0;
                [unroll] for (int j = -1; j <= 1; j++)
                {
                    [unroll] for (int i = -1; i <= 1; i++)
                    {
                        float2 id = ci + float2(i, j);
                        float live = step(bdHash21(id + 3.1), 0.12 + 0.55 * g);
                        float2 r1 = bdHash22(id + 7.7);
                        float2 r2 = bdHash22(id + 19.3);
                        float ang = (r2.x < 0.72) ? swipe + (r2.y - 0.5) * 0.45 : r2.y * 3.14159;
                        float hl = lerp(0.10, 0.46, bdHash21(id + 11.9));             // half length
                        float2 cen = (id + r1) * cell - off;
                        float2 dir = float2(cos(ang), sin(ang));
                        float2 pa = p - cen;
                        float along = dot(pa, dir);
                        float dist = length(pa - dir * clamp(along, -hl, hl));
                        float w = max(0.0035 + 0.004 * r2.y, px * 0.8);
                        float ends = 1.0 - smoothstep(0.55, 1.0, abs(along) / hl);
                        float depth = lerp(0.35, 1.0, r1.y);
                        cov = max(cov, live * (1.0 - smoothstep(0.0, w, dist)) * ends * depth);
                    }
                }
                return cov;
            }

            DecorOut frag(v2f IN)
            {
                float2 uv = IN.texcoord;
                float2 p = uv * 2.0 - 1.0;
                float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);

                float4 dl = artDist(p);
                float dU = min(min(dl.x, dl.y), min(dl.z, dl.w));
                float dCut = dU - _Border;
                float gr = _Grime;
                if (gr > 0.002) dCut += grimeEdge(p, gr);

                // ---- print ----------------------------------------------------------------------------------
                float3 c = _BorderColor.rgb;
                float procedural = step(_ArtSlice, -0.5);
                float3 grad = lerp(_C0.rgb, _C1.rgb, saturate(0.5 - p.y * 0.55 / _ArtSize));
                float c0 = saturate(0.5 - dl.x / px);
                c = lerp(c, lerp(_C0.rgb, grad, procedural), c0);
                c = lerp(c, _C1.rgb, saturate(0.5 - dl.y / px) * (1.0 - procedural));
                c = lerp(c, _C2.rgb, saturate(0.5 - dl.z / px));
                c = lerp(c, _C3.rgb, saturate(0.5 - dl.w / px));
                // procedural keyline: a thin line in _C2 just inside the art edge
                float key = (1.0 - smoothstep(0.0, px * 1.2, abs(dl.x + 0.085 * _ArtSize) - 0.014 * _ArtSize)) * procedural;
                c = lerp(c, _C2.rgb, key * 0.9);
                // ink outline round the whole art
                float iw = _InkWidth;
                float inkCov = (1.0 - smoothstep(-px, px, abs(dU + iw * 0.5) - iw * 0.5)) * _Ink;
                c = lerp(c, _InkColor.rgb, inkCov);
                float printCov = saturate(0.5 - dU / px);
                // paper grain (matte stickers), only where there is print or vinyl
                float g = bdHash21(floor(p * 160.0) + _Seed) - 0.5;
                c *= 1.0 + 0.07 * g * _Paper;

                // ---- grime ---------------------------------------------------------------------------------
                float gDull = 0.0;      // gloss the grime takes off (0..1)
                float gCut = 0.0;       // relief the grime takes off (0..1)
                if (gr > 0.002)
                {
                    float swipe = frac(_Seed * 0.618034) * 3.14159;
                    float inside = max(-dCut, 0.0);
                    float2 q = p + _Seed * 11.0;

                    // the ink wears through to the white vinyl, at its edges and corners first
                    float edge = exp(-abs(dU + 0.02) / 0.07);
                    float wearN = bdFbm(p * 10.0 + _Seed * 1.3 + 5.0, 3.0);
                    float wear = smoothstep(0.64 - 0.14 * gr, 0.82, wearN) * saturate(edge * 1.4 + 0.12) * gr * printCov;
                    c = lerp(c, _BorderColor.rgb * 0.95, wear * 0.9);

                    // sun: the vinyl yellows, the print fades toward grey
                    float age = gr * gr;
                    c *= lerp(float3(1.0, 1.0, 1.0), float3(1.0, 0.94, 0.80), 0.55 * age * (1.0 - 0.6 * printCov));
                    c = lerp(c, dpLum(c).xxx + 0.05, 0.16 * gr * printCov);

                    // the clear top goes cloudy where it was rubbed: dark print turns dusty, light print barely shows it
                    float cloud = smoothstep(0.45, 0.80, bdFbm(p * 2.0 + _Seed * 2.0 + 21.0, 3.0));
                    c = lerp(c, float3(0.80, 0.78, 0.73), cloud * 0.26 * gr * (1.0 - 0.7 * dpLum(c)));

                    // a film of dirt: in blotches, and gathered along the rim, a little at a time
                    float blot = bdFbm(q * 2.4, 4.0);
                    float rim = exp(-inside / (0.04 + 0.03 * gr)) * (0.25 + 1.1 * bdFbm(q * 5.5 + 3.0, 3.0));
                    float dirt = saturate((blot - (0.64 - 0.27 * gr)) * 2.6 + rim * (0.10 + 0.26 * gr)) * (0.30 + 0.65 * gr);
                    c *= lerp(float3(1.0, 1.0, 1.0), float3(0.60, 0.52, 0.41), dirt);
                    c = lerp(c, float3(0.28, 0.24, 0.19), dirt * 0.14);

                    // grit: dark specks that cluster where it is dirty, and a few pale ink chips
                    float cs = max(px * 1.5, 0.0065);
                    float2 gc = floor((p + _Seed) / cs);
                    float cluster = smoothstep(0.42, 0.74, bdFbm(q * 4.0 + 9.0, 2.0));
                    float dark = step(1.0 - 0.05 * gr * (0.04 + 1.6 * cluster * (0.3 + dirt)), bdHash21(gc));
                    float pale = step(1.0 - 0.005 * gr, bdHash21(gc + 41.0));
                    c = lerp(c, c * 0.40, dark * 0.8);
                    c = lerp(c, _BorderColor.rgb * 0.9, pale * 0.7 * printCov);

                    // scratches cut the clear top: pale on dark print, grimy grey on light, and they take the shine
                    float abr = grimeAbrade(p, px, gr, swipe);
                    float scr = grimeScratch(p, px, gr, swipe);
                    float marks = saturate(abr * 0.8 + scr);
                    float lum = dpLum(c);
                    float3 scrCol = lerp(float3(0.93, 0.91, 0.86), float3(0.30, 0.27, 0.22), smoothstep(0.35, 0.85, lum));
                    c = lerp(c, scrCol, marks * 0.62);

                    // fingerprints and rubbing: patches that are dull without being any dirtier
                    float smear = smoothstep(0.50, 0.80, bdFbm(p * 1.5 + _Seed * 4.0 + 13.0, 3.0));
                    gDull = saturate(0.25 * gr + dirt * 0.85 + marks * 0.8 + smear * 0.55 * gr);
                    gCut = saturate(marks * 0.55 + wear * 0.4);
                }

                float bodyA = saturate(0.5 - dCut / px);
                // ink sits proud of the vinyl; bubbles lift the sheet in soft domes
                float relief = (1.0 + 0.10 * printCov + 0.35 * _Bubbles * bubbleH(p)) * (1.0 - 0.45 * gCut);

                // ---- peeled corner --------------------------------------------------------------------------
                float pa = radians(_PeelAngle - 45.0);
                float2 nc = float2(cos(pa), sin(pa));                    // 0 deg → bottom-right
                float s0 = 1.15 - _Peel * 1.0;
                float sp = dot(p, nc);
                float on = step(1e-4, _Peel);
                float lifted = smoothstep(-px, px, sp - s0) * on;
                // the flap: material beyond the fold, reflected back over the sticker and foreshortened by the curl
                float2 pm = p + 2.4 * max(s0 - sp, 0.0) * nc;
                float4 dlf = artDist(pm);
                float dFlap = max(min(min(dlf.x, dlf.y), min(dlf.z, dlf.w)) - _Border, sp - s0);
                float flapA = saturate(0.5 - dFlap / px) * on;
                float u = max(s0 - sp, 0.0);
                float3 back = float3(0.95, 0.94, 0.91) * (0.86 + 0.14 * smoothstep(0.0, 0.18, u));
                back *= 1.0 - 0.10 * smoothstep(0.08, 0.0, u);

                bodyA *= 1.0 - lifted;
                float a = bodyA + flapA * (1.0 - bodyA);
                float3 col = lerp(c, back, flapA);
                float rel = lerp(relief, 2.0 + 9.0 * u, flapA);
                float matMul = lerp(1.0, 0.12, flapA) * (1.0 - 0.85 * gDull);
                return DecorEmitM(col * _Color.rgb, a * _Color.a, rel, 1.0, matMul);
            }
            ENDCG
        }
    }
}
