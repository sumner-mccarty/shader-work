// ============================================================================
// DecorWrapB.shader — the second sheet of faceplate wraps (Docs/Decor.md §2.2, 2026-10-11)
// ============================================================================
// The same contract as UI/Decor/Wrap (position in canvas units → pattern; _C0 is the background with its alpha as coverage;
// _Scale is the feature size; _Angle turns it; _Seed re-rolls it; relief is small and per mode; the finish comes from
// _DecorMat) — in its own shader so the first sheet's compile time and its patterns stay exactly as they were.
// DecorCatalog.Wrap.Mode >= 100 selects this shader with _Mode = Mode - 100.
//
//  0 Brick wall        5 Paisley          10 Record grooves   15 Sunburst
//  1 Subway tile       6 Argyle           11 Spectrum bars    16 Denim
//  2 Chain-link fence  7 Scales           12 Memphis          17 Scanlines
//  3 Scrawl            8 Tufted leather   13 Concrete         18 Blueprint
//  4 Tie-dye           9 Circuit board    14 Corrugated tin
// ============================================================================

Shader "UI/Decor/WrapB"
{
    Properties
    {
        _Color ("Tint (a = opacity)", Color) = (1, 1, 1, 1)
        _Mode ("Pattern", Float) = 0
        _C0 ("Background (a = coverage)", Color) = (0.12, 0.12, 0.14, 1)
        _C1 ("Colour 1", Color) = (0.95, 0.55, 0.10, 1)
        _C2 ("Colour 2", Color) = (0.08, 0.06, 0.05, 1)
        _C3 ("Colour 3", Color) = (0.96, 0.91, 0.78, 1)
        _Scale ("Feature size (canvas units)", Float) = 60
        _Angle ("Angle (deg)", Float) = 0
        _Seed ("Seed", Float) = 1
        _Size ("Group size (canvas units)", Vector) = (800, 400, 0, 0)
        _DecorMat ("Finish: gloss, metal, holo, glitter", Vector) = (0.5, 0, 0, 0)
        _DecorMat2 ("Finish: emissive, thickness", Vector) = (0, 0.2, 0, 0)
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

            float4 _C0, _C1, _C2, _C3, _Size;
            float _Mode, _Scale, _Angle, _Seed;

            struct appdata_t { float4 vertex : POSITION; };
            struct v2f { float4 vertex : SV_POSITION; float2 P : TEXCOORD0; };

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.P = mul(unity_ObjectToWorld, v.vertex).xy;
                return o;
            }

            float2 rot(float2 p, float a) { float c = cos(a), s = sin(a); return float2(c * p.x - s * p.y, s * p.x + c * p.y); }

            // Layer `col` (a = coverage) over the running premultiplied result.
            void over(inout float4 acc, float3 col, float a)
            {
                a = saturate(a);
                acc.rgb = col * a + acc.rgb * (1.0 - a);
                acc.a = a + acc.a * (1.0 - a);
            }

            // A teardrop: bulb of radius r1 at the origin, point of radius r2 at (0, h) (iq's uneven capsule).
            float sdTear(float2 p, float r1, float r2, float h)
            {
                p.x = abs(p.x);
                float b = (r1 - r2) / h;
                float a = sqrt(1.0 - b * b);
                float k = dot(p, float2(-b, a));
                if (k < 0.0) return length(p) - r1;
                if (k > a * h) return length(p - float2(0.0, h)) - r2;
                return dot(p, float2(a, b)) - r1;
            }

            float sdBox2(float2 p, float2 b)
            {
                float2 d = abs(p) - b;
                return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
            }

            float sdTri(float2 p, float r)
            {
                const float k = 1.7320508;
                p.x = abs(p.x) - r;
                p.y = p.y + r / k;
                if (p.x + k * p.y > 0.0) p = float2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
                p.x -= clamp(p.x, -2.0 * r, 0.0);
                return -length(p) * sign(p.y);
            }

            // The four pattern colours as a cycle (tie-dye).
            float3 pal(float i)
            {
                i = fmod(i + 64.0, 4.0);
                return i < 1.0 ? _C0.rgb : (i < 2.0 ? _C1.rgb : (i < 3.0 ? _C2.rgb : _C3.rgb));
            }

            DecorOut frag(v2f IN)
            {
                float2 P = IN.P;
                float2 fw = fwidth(P);
                float px = max(max(fw.x, fw.y), 1e-3);                // canvas units per pixel
                float sc = max(_Scale, 1.0);
                float2 C = _Size.xy * 0.5;
                float ang = radians(_Angle);
                float2 Q = rot(P - C, -ang) / sc;                     // pattern space: one feature per unit
                float aq = px / sc;                                   // one pixel in pattern units
                float seed = _Seed * 7.31;
                float m = _Mode;

                float4 acc = float4(_C0.rgb * _C0.a, _C0.a);          // background, premultiplied
                float relief = 0.0;

                if (m < 1.5)                                          // 0 brick wall / 1 subway tile
                {
                    float tile = step(0.5, m);
                    float2 q = Q * float2(1.0, 2.0);
                    float row = floor(q.y);
                    float odd = fmod(row + 64.0, 2.0);
                    float2 cid = float2(floor(q.x + 0.5 * odd), row);
                    float2 f = float2(frac(q.x + 0.5 * odd), frac(q.y));
                    float2 dd = min(f, 1.0 - f) * float2(1.0, 0.5);           // pattern units to the nearest mortar line
                    float edge = min(dd.x, dd.y);
                    float mort = lerp(0.05, 0.02, tile);
                    float e = max(aq, 1e-4) * 1.3;
                    float cov = smoothstep(mort, mort + e, edge);
                    float h1 = bdHash21(cid + seed);
                    float h2 = bdHash21(cid * 1.7 + seed);
                    float3 bc = lerp(_C1.rgb, lerp(_C1.rgb, _C2.rgb, h1), 1.0 - tile) * lerp(0.86 + 0.26 * h2, 0.95 + 0.1 * h2, tile);
                    bc *= lerp(0.9 + 0.2 * bdNoise(Q * 26.0 + seed), 0.97 + 0.06 * bdNoise(Q * 40.0 + seed), tile);
                    float soot = smoothstep(0.55, 0.85, bdFbm(Q * 0.9 + seed * 2.0, 3.0));
                    float bevel = smoothstep(mort, mort + 0.07, edge);
                    bc = lerp(bc, _C3.rgb, soot * 0.38 * (1.0 - tile));        // weathering on brick
                    bc *= lerp(1.0, 0.8 + 0.3 * bevel, tile);                  // a glazed bevel on tile
                    float3 grout = _C0.rgb * (0.88 + 0.24 * bdNoise(Q * 20.0 + seed));
                    acc = float4(lerp(grout, bc, cov), 1.0);
                    relief = cov * lerp(0.55, 0.3, tile);
                }
                else if (m < 2.5)                                     // 2 chain-link fence (sits on the bare plate when _C0.a = 0)
                {
                    float2 q = Q * 0.9;
                    float u = (q.x + q.y) * 0.7071;
                    float v = (q.x - q.y) * 0.7071;
                    float ou = u + 0.045 * sin(v * 6.2832);                    // a hint of the wire's kink between crossings
                    float ov = v + 0.045 * sin(u * 6.2832);
                    float w1 = abs(frac(ou) - 0.5);
                    float w2 = abs(frac(ov) - 0.5);
                    float th = 0.055;
                    float e = max(aq * 1.5, 1e-4);
                    float a1 = 1.0 - smoothstep(th, th + e, w1);
                    float a2 = 1.0 - smoothstep(th, th + e, w2);
                    float s1 = sqrt(saturate(1.0 - (w1 / th) * (w1 / th)));
                    float s2 = sqrt(saturate(1.0 - (w2 / th) * (w2 / th)));
                    float sh = max(1.0 - smoothstep(th, th * 3.5, abs(frac(ou - 0.09) - 0.5)),
                                   1.0 - smoothstep(th, th * 3.5, abs(frac(ov - 0.09) - 0.5))) * 0.32;
                    over(acc, float3(0.0, 0.0, 0.0), sh * (1.0 - max(a1, a2)));
                    // which strand passes over at a crossing alternates, like the real weave
                    float flipx = fmod(floor(ou) + floor(ov) + 64.0, 2.0);
                    float3 cA = _C1.rgb * (0.5 + 0.6 * s2);
                    float3 cB = _C1.rgb * (0.5 + 0.6 * s1);
                    if (flipx < 0.5) { over(acc, cA, a2); over(acc, cB, a1); }
                    else { over(acc, cB, a1); over(acc, cA, a2); }
                    relief = max(a1, a2) * 0.7;
                }
                else if (m < 3.5)                                     // 3 scrawl: marker tags, layered and crossing
                {
                    [unroll] for (int k = 0; k < 3; k++)
                    {
                        float fk = (float)k;
                        float2 qk = rot(Q, fk * 1.9 + seed * 0.5) * (0.75 + 0.18 * fk);
                        float row = floor(qk.y * 0.8);
                        float hr = bdHash21(float2(row, seed + fk * 5.0));
                        float hr2 = bdHash21(float2(row + 17.0, seed + fk * 3.0));
                        float hr3 = bdHash21(float2(row + 29.0, seed + fk * 7.0));
                        float fy = frac(qk.y * 0.8);
                        float yc = 0.5 + 0.2 * sin(qk.x * (0.9 + hr * 0.8) + hr * 6.28 + fk) + 0.1 * sin(qk.x * (2.6 + hr2) + hr2 * 9.0);
                        float th = 0.06 + 0.04 * hr2;
                        float d = abs(fy - yc);
                        float e = max(aq * 0.8, 1e-4) * 1.3;
                        float live = step(0.22, hr3);
                        float outline = (1.0 - smoothstep(th + 0.035 - e, th + 0.035 + e, d)) * live;
                        float fill = (1.0 - smoothstep(th - e, th + e, d)) * live;
                        float3 cc = hr < 0.34 ? _C1.rgb : (hr < 0.67 ? _C2.rgb : _C3.rgb);
                        over(acc, float3(0.97, 0.97, 0.95), outline);
                        over(acc, cc, fill);
                        relief = max(relief, outline * 0.4);
                    }
                }
                else if (m < 4.5)                                     // 4 tie-dye: a spiral of dye round the middle
                {
                    float r = length(Q);
                    float a = atan2(Q.y, Q.x);
                    float w = bdFbm(Q * 0.45 + seed, 3.0) - 0.5;
                    float t = r * 1.15 + a * 0.6366 + w * 2.2 + sin(a * 5.0 + r * 1.2) * 0.2;
                    float t4 = t - floor(t / 4.0) * 4.0;
                    float f = frac(t4);
                    float3 c = lerp(pal(floor(t4)), pal(floor(t4) + 1.0), smoothstep(0.1, 0.9, f));
                    c *= 0.9 + 0.2 * bdNoise(Q * 18.0 + seed);
                    c *= 1.0 - 0.07 * pow(abs(sin(a * 7.0 + w * 9.0 + r * 0.8)), 16.0);      // the creases the rubber bands left
                    acc = float4(c, 1.0);
                }
                else if (m < 5.5)                                     // 5 paisley
                {
                    float2 q = Q * 1.2;
                    q.x += 0.5 * fmod(floor(q.y) + 64.0, 2.0);
                    float2 cell = floor(q);
                    float2 f = frac(q) - 0.5;
                    float h = bdHash21(cell + seed);
                    float flip = fmod(cell.y + 64.0, 2.0) > 0.5 ? 3.1416 : 0.0;
                    float2 p = rot(f, (h - 0.5) * 0.9 + flip) + float2(0.0, 0.09);
                    p.x -= 0.55 * p.y * p.y;                                       // curl the tail
                    float d = sdTear(p, 0.15, 0.025, 0.3);
                    float e = max(aq * 1.2, 1e-4);
                    float body = 1.0 - smoothstep(-e, e, d);
                    float inner = (1.0 - smoothstep(0.0, e * 1.6, abs(d + 0.05) - 0.01)) * body;
                    float bulb = 1.0 - smoothstep(0.04 - e, 0.04 + e, length(p));
                    over(acc, _C1.rgb, body);
                    over(acc, _C2.rgb, inner);
                    over(acc, _C3.rgb, bulb);
                    float tiny = 1.0 - smoothstep(0.025 - e, 0.025 + e, length(frac(q * 2.0 + 0.25) - 0.5));
                    over(acc, _C1.rgb, tiny * step(0.5, bdHash21(floor(q * 2.0) + seed)) * (1.0 - body) * 0.8);
                    relief = body * 0.2;
                }
                else if (m < 6.5)                                     // 6 argyle
                {
                    float2 g = float2(Q.x + Q.y, Q.x - Q.y) * 0.5;
                    float2 gi = floor(g);
                    float2 fg = frac(g);
                    float e = max(aq, 1e-4) * 1.3;
                    float dEdge = min(min(fg.x, 1.0 - fg.x), min(fg.y, 1.0 - fg.y));
                    float chk = fmod(gi.x + gi.y + 64.0, 2.0);
                    float3 c = chk < 0.5 ? _C1.rgb : _C2.rgb;
                    c *= 0.9 + 0.1 * sin(Q.x * 90.0) * sin(Q.y * 90.0);               // the knit
                    c = lerp(_C0.rgb, c, smoothstep(0.012, 0.012 + e, dEdge));
                    float pin = max(1.0 - smoothstep(0.006, 0.006 + e, abs(fg.x - 0.5)), 1.0 - smoothstep(0.006, 0.006 + e, abs(fg.y - 0.5)));
                    float dash = step(0.35, frac((g.x + g.y) * 6.0));
                    acc = float4(lerp(c, _C3.rgb, pin * dash * 0.9), 1.0);
                    relief = 0.12;
                }
                else if (m < 7.5)                                     // 7 scales (fish / snake)
                {
                    float jy = floor(Q.y * 2.0);
                    float dsel = 9.0;
                    float hsel = 0.0;
                    float2 dvec = float2(0.0, 0.0);
                    [unroll] for (int k = 0; k <= 1; k++)
                    {
                        float row = jy + (float)k;
                        float odd = fmod(row + 64.0, 2.0);
                        float ci = floor(Q.x - 0.5 * odd);
                        float2 d = float2(Q.x - (ci + 0.5 + 0.5 * odd), Q.y - row * 0.5);
                        float dl = length(d);
                        if (dl < 0.58 && dsel > 8.0) { dsel = dl; hsel = bdHash21(float2(ci, row) + seed); dvec = d; }
                    }
                    float r = dsel / 0.58;
                    float3 s = lerp(_C1.rgb, _C2.rgb, hsel);
                    s *= 0.62 + 0.5 * (1.0 - r) + 0.25 * saturate(-dvec.y * 2.0);
                    s = lerp(s, _C3.rgb, smoothstep(0.55, 0.9, r) * 0.28);
                    s = lerp(s, _C0.rgb * 0.5, smoothstep(0.86, 0.97, r) * 0.85);
                    acc = float4(dsel < 8.0 ? s : _C0.rgb, 1.0);
                    relief = (1.0 - r) * 0.4;
                }
                else if (m < 8.5)                                     // 8 tufted leather: diamond pillows, buttons at the points
                {
                    float2 g = float2(Q.x + Q.y, Q.x - Q.y) * 0.625;
                    float2 f = frac(g);
                    float2 s = sin(f * 3.14159);
                    float2 gd = float2(cos(f.x * 3.14159) * s.y, s.x * cos(f.y * 3.14159));
                    float hgt = s.x * s.y;
                    float3 leather = _C0.rgb * (0.7 + 0.3 * smoothstep(0.0, 0.25, hgt)) * clamp(0.68 + 0.55 * gd.y, 0.3, 1.25);
                    leather *= 0.9 + 0.2 * bdFbm(Q * 14.0 + seed, 2.0);
                    float bd = length(g - round(g));
                    float ee = aq * 0.9;
                    float button = 1.0 - smoothstep(0.11 - ee, 0.11 + ee, bd);
                    float3 c = lerp(leather, _C1.rgb * (0.6 + 0.6 * (1.0 - bd / 0.11)), button);
                    acc = float4(c, 1.0);
                    relief = hgt * 0.5 + button * 0.4;
                }
                else if (m < 9.5)                                     // 9 circuit board
                {
                    float2 q = Q * 1.5;
                    float2 cell = floor(q);
                    float2 f = frac(q);
                    float e = max(aq * 1.5, 1e-4);
                    float lw = 0.045;
                    float hb = bdHash21(cell + seed);
                    float hl = bdHash21(cell + seed + 7.0);
                    float hd = bdHash21(cell + seed + 13.0);
                    float hbUp = bdHash21(cell + float2(0.0, 1.0) + seed);
                    float hlRight = bdHash21(cell + float2(1.0, 0.0) + seed + 7.0);
                    float hT = max(step(0.45, hb) * (1.0 - smoothstep(lw, lw + e, f.y)), step(0.45, hbUp) * (1.0 - smoothstep(lw, lw + e, 1.0 - f.y)));
                    float vT = max(step(0.45, hl) * (1.0 - smoothstep(lw, lw + e, f.x)), step(0.45, hlRight) * (1.0 - smoothstep(lw, lw + e, 1.0 - f.x)));
                    float diag = step(0.9, hd) * (1.0 - smoothstep(lw, lw + e, abs(f.x - f.y) * 0.7071)) * step(0.0, f.x) ;
                    float tr = max(max(hT, vT), diag);
                    float2 vtx = f - round(f);
                    float hv = bdHash21(round(q) + seed + 31.0);
                    float pad = step(0.62, hv) * (1.0 - smoothstep(0.1 - e, 0.1 + e, length(vtx)));
                    float hole = step(0.62, hv) * (1.0 - smoothstep(0.042 - e, 0.042 + e, length(vtx)));
                    float3 c = _C0.rgb * (0.9 + 0.2 * bdFbm(Q * 3.0 + seed, 2.0));
                    c = lerp(c, _C1.rgb, max(tr, pad));
                    c = lerp(c, _C2.rgb, hole);
                    float silk = step(0.93, hb) * (1.0 - smoothstep(0.02, 0.02 + e, abs(f.y - 0.5))) * step(abs(f.x - 0.5), 0.2);
                    c = lerp(c, _C3.rgb, silk);
                    acc = float4(c, 1.0);
                    relief = max(tr, pad) * 0.3;
                }
                else if (m < 10.5)                                    // 10 record grooves: a crate of discs
                {
                    float2 q = Q * 0.9;
                    q.x += 0.5 * fmod(floor(q.y) + 64.0, 2.0);
                    float2 cell = floor(q);
                    float2 d = frac(q) - 0.5;
                    float h = bdHash21(cell + seed);
                    float r = length(d);
                    float a = atan2(d.y, d.x);
                    float e = max(aq * 1.1, 1e-4);
                    float disc = 1.0 - smoothstep(0.46 - e, 0.46 + e, r);
                    float lab = 1.0 - smoothstep(0.15 - e, 0.15 + e, r);
                    float groove = 0.5 + 0.5 * sin(r * 160.0 + h * 6.0);
                    float sheen = pow(abs(cos(a * 2.0 + h * 6.28)), 8.0) * 0.3;
                    float3 vinyl = float3(0.05, 0.05, 0.06) + groove * 0.035 + sheen;
                    float3 lc = h < 0.34 ? _C1.rgb : (h < 0.67 ? _C2.rgb : _C3.rgb);
                    float hole = 1.0 - smoothstep(0.02 - e, 0.02 + e, r);
                    float3 c = lerp(_C0.rgb, vinyl, disc);
                    c = lerp(c, lc, lab);
                    c = lerp(c, _C0.rgb, hole);
                    acc = float4(c, 1.0);
                    relief = disc * 0.3;
                }
                else if (m < 11.5)                                    // 11 spectrum: an equaliser wall
                {
                    float2 q = Q * 5.0;
                    float col = floor(q.x);
                    float2 f = frac(q);
                    float block = floor(q.y / 12.0);
                    float row = floor(q.y - block * 12.0);
                    float lvl = clamp(floor(2.0 + 12.0 * bdFbm(float2(col * 0.23 + block * 3.7, seed), 2.0)), 1.0, 12.0);
                    float on = step(row + 0.5, lvl);
                    float ex = max(aq * 5.0, 1e-4);
                    float cell = smoothstep(0.1, 0.1 + ex, f.x) * (1.0 - smoothstep(0.9 - ex, 0.9, f.x))
                               * smoothstep(0.12, 0.12 + ex, f.y) * (1.0 - smoothstep(0.88 - ex, 0.88, f.y));
                    float3 lit = row < 6.0 ? _C1.rgb : (row < 9.0 ? _C2.rgb : _C3.rgb);
                    float3 c = _C0.rgb;
                    c = lerp(c, lit * 0.16, cell);
                    c = lerp(c, lit, cell * on);
                    acc = float4(c, 1.0);
                    relief = cell * on * 0.3;
                }
                else if (m < 12.5)                                    // 12 Memphis: confetti of bold little shapes
                {
                    float2 q = Q * 1.1;
                    float2 cell = floor(q);
                    float2 f = frac(q) - 0.5;
                    float h = bdHash21(cell + seed);
                    float h2 = bdHash21(cell * 1.7 + seed + 3.0);
                    float2 p = rot(f, h2 * 6.2832) * 0.62;                // 0.62: shapes bold enough to fill their cell
                    float e = max(aq * 0.8, 1e-4);
                    float kind = floor(h * 6.0);
                    float d;
                    if (kind < 1.0) d = length(p) - 0.2;
                    else if (kind < 2.0) d = abs(length(p) - 0.18) - 0.05;
                    else if (kind < 3.0) d = sdTri(p, 0.22);
                    else if (kind < 4.0) d = min(sdBox2(p, float2(0.2, 0.05)), sdBox2(p, float2(0.05, 0.2)));
                    else if (kind < 5.0) d = max(abs(p.y - 0.09 * sin(p.x * 22.0)) - 0.035, abs(p.x) - 0.3);
                    else d = max(abs(p.y) - 0.035, abs(p.x) - 0.3);
                    float k = 1.0 - smoothstep(-e, e, d);
                    float3 cc = h2 < 0.33 ? _C1.rgb : (h2 < 0.66 ? _C2.rgb : _C3.rgb);
                    over(acc, cc, k * step(0.1, bdHash21(cell + seed + 9.0)));
                    // and a sprinkle of tiny dots in the gaps
                    float2 tq = Q * 3.3;
                    float2 tc = floor(tq);
                    float tiny = 1.0 - smoothstep(0.07 - aq * 3.0, 0.07 + aq * 3.0, length(frac(tq) - 0.5 + (bdHash22(tc + seed) - 0.5) * 0.5));
                    over(acc, _C3.rgb, tiny * step(0.8, bdHash21(tc + seed + 4.0)) * (1.0 - k));
                    relief = k * 0.25;
                }
                else if (m < 13.5)                                    // 13 concrete, with formwork seams and tie holes
                {
                    float2 q = Q * 0.5;
                    float n1 = bdFbm(q * 1.2 + seed, 4.0);
                    float n2 = bdNoise(Q * 30.0 + seed);
                    float3 c = _C0.rgb * (0.82 + 0.3 * n1) * (0.94 + 0.1 * n2);
                    c = lerp(c, _C1.rgb, smoothstep(0.62, 0.8, bdFbm(q * 2.3 + seed * 3.0, 3.0)) * 0.5);
                    float2 pc = floor(Q * 4.0);
                    float2 pf = frac(Q * 4.0) - 0.5 + (bdHash22(pc + seed) - 0.5) * 0.5;
                    float pit = (1.0 - smoothstep(0.05, 0.1, length(pf))) * step(0.88, bdHash21(pc + seed));
                    c *= 1.0 - 0.45 * pit;
                    float2 pn = frac(Q * 0.5);
                    float seam = 1.0 - smoothstep(0.012, 0.012 + aq * 1.2, min(min(pn.x, 1.0 - pn.x), min(pn.y, 1.0 - pn.y)) * 2.0);
                    float2 th = abs(pn - 0.5) - 0.25;
                    float hole = 1.0 - smoothstep(0.06, 0.06 + aq * 1.2, length(th) * 2.0);
                    c = lerp(c, c * 0.55, seam);
                    c = lerp(c, c * 0.35, hole);
                    acc = float4(c, 1.0);
                    relief = 0.1 * n2;
                }
                else if (m < 14.5)                                    // 14 corrugated tin, rusting in streaks
                {
                    float ph = Q.x * 6.2832 * 2.5;
                    float s = sin(ph);
                    float cs = cos(ph);
                    float rust = smoothstep(0.55, 0.8, bdFbm(float2(Q.x * 0.5, Q.y * 0.15) + seed, 4.0));
                    float3 metal = _C0.rgb * (0.72 + 0.4 * cs) + 0.07 * pow(saturate(cs), 8.0);
                    float3 c = lerp(metal, _C1.rgb * (0.72 + 0.28 * cs), rust * 0.85);
                    c *= 0.94 + 0.1 * bdNoise(float2(Q.x * 6.0, Q.y * 30.0) + seed);
                    acc = float4(c, 1.0);
                    relief = 0.4 * (0.5 + 0.5 * s);
                }
                else if (m < 15.5)                                    // 15 sunburst
                {
                    float2 d = rot(P - C, -ang);
                    float len = max(length(d), 1.0);
                    float n = 18.0;
                    float t = frac((atan2(d.y, d.x) / 6.2832 + 0.5) * n);
                    float e3 = px / len * n / 6.2832 * 2.6;
                    float tri = abs(t * 2.0 - 1.0);
                    float ray = smoothstep(0.5 - e3, 0.5 + e3, tri);
                    float3 c = lerp(_C0.rgb, _C1.rgb, ray);
                    c *= 1.0 - 0.28 * saturate(len / (0.5 * length(_Size.xy)));
                    float sun = 1.0 - smoothstep(sc * 0.55 - px, sc * 0.55 + px, len);
                    float rim = 1.0 - smoothstep(px, px * 2.5, abs(len - sc * 0.55));
                    c = lerp(c, _C2.rgb, sun);
                    c = lerp(c, _C3.rgb, rim);
                    acc = float4(c, 1.0);
                }
                else if (m < 16.5)                                    // 16 denim (twill) with a topstitch
                {
                    float2 q = Q * 30.0;
                    float2 cell = floor(q);
                    float2 f = frac(q);
                    float weft = step(2.0, fmod(cell.x + cell.y + 64.0, 3.0));
                    float thread = lerp(0.82 + 0.18 * sin(f.x * 3.14159), 0.78 + 0.22 * sin(f.y * 3.14159), weft);
                    float3 c = lerp(_C0.rgb, _C1.rgb, weft) * thread;
                    float fade = smoothstep(0.35, 0.75, bdFbm(Q * 0.6 + seed, 4.0));
                    c = lerp(c, lerp(c, float3(1.0, 1.0, 1.0), 0.35), fade * 0.5);
                    c *= 0.92 + 0.16 * bdNoise(q * 0.5 + seed);
                    float sl = abs(frac(Q.y / 6.0) - 0.5) * 6.0;
                    float stitch = (1.0 - smoothstep(0.045, 0.045 + aq * 1.5, sl)) * step(0.3, frac(Q.x * 1.6));
                    acc = float4(lerp(c, _C2.rgb, stitch), 1.0);
                    relief = thread * 0.25;
                }
                else if (m < 17.5)                                    // 17 CRT scanlines with a rolling bar and a few tears
                {
                    float t = saturate((P.y - C.y) / max(_Size.y, 1.0) + 0.5);
                    float3 c = lerp(_C0.rgb, _C1.rgb, t);
                    float scan = 0.78 + 0.22 * cos(Q.y * 6.2832 * 5.0);
                    float bar = exp(-pow((frac(Q.y * 0.12 + seed * 0.1) - 0.5) * 6.0, 2.0)) * 0.12;
                    float2 vc = (P - C) / max(_Size.xy, 1.0);
                    float vig = 1.0 - 0.9 * dot(vc, vc);
                    float tear = step(0.965, bdHash21(float2(floor(Q.y * 5.0), seed)));
                    c = (c * scan + bar) * vig;
                    c = lerp(c, _C2.rgb, tear * 0.5);
                    acc = float4(c, 1.0);
                }
                else                                                  // 18 blueprint
                {
                    float2 q = Q;
                    float e = max(aq * 1.2, 1e-4);
                    float2 gm = abs(frac(q * 4.0 + 0.5) - 0.5) / 4.0;
                    float2 gM = abs(frac(q + 0.5) - 0.5);
                    float minor = 1.0 - smoothstep(0.004, 0.004 + e, min(gm.x, gm.y));
                    float major = 1.0 - smoothstep(0.008, 0.008 + e * 1.4, min(gM.x, gM.y));
                    float3 c = _C0.rgb * (0.94 + 0.08 * bdFbm(Q * 0.5 + seed, 3.0));
                    c = lerp(c, _C1.rgb, minor * 0.28);
                    c = lerp(c, _C1.rgb, major * 0.6);
                    float2 v = frac(q + 0.5) - 0.5;
                    float cross_ = (1.0 - smoothstep(0.012, 0.012 + e, abs(v.x))) * step(abs(v.y), 0.07)
                                 + (1.0 - smoothstep(0.012, 0.012 + e, abs(v.y))) * step(abs(v.x), 0.07);
                    c = lerp(c, _C2.rgb, saturate(cross_));
                    acc = float4(c, 1.0);
                }

                float a = acc.a;
                float3 rgb = acc.rgb / max(a, 1e-4);
                return DecorEmit(rgb * _Color.rgb, a * _Color.a, relief + 0.25, 1.0);
            }
            ENDCG
        }
    }
}
