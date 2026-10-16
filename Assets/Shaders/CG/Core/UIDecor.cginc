#ifndef UI_DECOR_INCLUDED
#define UI_DECOR_INCLUDED

// ============================================================================
// UIDecor.cginc — faceplate decor (paint, stickers, wraps) sampled INSIDE a plate (Docs/Decor.md §2.4).
// ============================================================================
// A decorated panel owns three textures, rendered by DecorSurface.cs only when its decor changes:
//   _DecorTex     premultiplied paint colour, a = coverage
//   _DecorSurfTex (normal.x, normal.y) * 0.5 + 0.5 of the paint/vinyl relief, gloss, metal
//   _DecorFxTex   holo, glitter, emissive, cast shadow (height-field shadow toward the key lamp + contact AO)
// and maps canvas space onto them with an affine (_DecorMapU/_DecorMapV: uv = dot(float3(p, 1), M.xyz)),
// so a plate rotated or nested anywhere in the group still lands on the right texel.
//
// The plate shader calls, in order:
//     UIDecorSample(IN.worldPosition.xy, ds)          once, early in the face section (no-op when disabled)
//     UIDecorAlbedo(ds, albedo)                      paint replaces the plate's colour BEFORE lighting
//     UIDecorNormal(ds, n)                           paint relief tilts the plate's normal
//     UIDecorSpecular(ds, specularMod)               gloss of the paint, not the metal under it
//     UIDecorFinish(ds, lit, n, L)                   metal / holo / glitter on the lit colour
//     UIDecorShadow(ds, lit)                         cast shadow of raised items (also off the paint)
// Everything is gated by _DecorEnabled, a per-material uniform — a uniform branch, free on an
// undecorated plate. No derivatives inside the branches (none are taken at all).
// ============================================================================

sampler2D _DecorTex;
sampler2D _DecorSurfTex;
sampler2D _DecorFxTex;
float     _DecorEnabled;
float4    _DecorMapU;      // uv.x = dot(float3(canvasPos, 1), _DecorMapU.xyz)
float4    _DecorMapV;      // uv.y = dot(float3(canvasPos, 1), _DecorMapV.xyz)

struct UIDecorSampleData
{
    float4 albedo;     // premultiplied
    float  cov;
    float2 nrm;        // relief normal xy (z implied)
    float  gloss, metal, holo, glitter, emissive, shadow;
    float2 uv;
};

void UIDecorClear(out UIDecorSampleData ds)
{
    ds.albedo = float4(0, 0, 0, 0);
    ds.cov = 0;
    ds.nrm = float2(0, 0);
    ds.gloss = 0; ds.metal = 0; ds.holo = 0; ds.glitter = 0; ds.emissive = 0; ds.shadow = 0;
    ds.uv = float2(0, 0);
}

void UIDecorSample(float2 canvasPos, out UIDecorSampleData ds)
{
    UIDecorClear(ds);
    if (_DecorEnabled < 0.5) return;
    float2 uv = float2(dot(float3(canvasPos, 1.0), _DecorMapU.xyz), dot(float3(canvasPos, 1.0), _DecorMapV.xyz));
    float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
    ds.uv = uv;
    float4 a = tex2Dlod(_DecorTex, float4(uv, 0, 0)) * inside;
    float4 s = tex2Dlod(_DecorSurfTex, float4(uv, 0, 0));
    float4 f = tex2Dlod(_DecorFxTex, float4(uv, 0, 0)) * inside;
    ds.albedo = a;
    ds.cov = a.a;
    ds.nrm = (s.xy * 2.0 - 1.0) * inside;
    ds.gloss = s.z;
    ds.metal = s.w;
    ds.holo = f.x;
    ds.glitter = f.y;
    ds.emissive = f.z;
    ds.shadow = f.w;
}

// TRIM: cut the decor away (keep = 0) around hardware that goes through the plate AFTER it was decorated —
// the screw heads (SDFPanel §4). Every term scales, so the cut is exactly bare plate; `lip` darkens a thin band
// just outside the cut, the shadow of the vinyl's cut edge falling onto the bare ring.
void UIDecorTrim(inout UIDecorSampleData ds, float keep, float lip)
{
    keep = saturate(keep);
    float covBefore = ds.cov;
    ds.albedo *= keep;
    ds.cov *= keep;
    ds.nrm *= keep;
    ds.holo *= keep;
    ds.glitter *= keep;
    ds.emissive *= keep;
    ds.shadow = saturate(ds.shadow + lip * 0.45 * covBefore * (1.0 - keep * 0.6));
}

// Paint over the plate's own colour (premultiplied over).
float3 UIDecorAlbedo(UIDecorSampleData ds, float3 albedo)
{
    return albedo * (1.0 - ds.cov) + ds.albedo.rgb;
}

// Relief: the paint's height-field normal added to the plate's (bevel, dome) normal.
float3 UIDecorNormal(UIDecorSampleData ds, float3 n)
{
    return normalize(n + float3(ds.nrm, 0.0));
}

// Gloss of the paint where there is paint; the plate's own pattern specular elsewhere.
float UIDecorSpecular(UIDecorSampleData ds, float specularMod)
{
    return lerp(specularMod, lerp(0.15, 2.4, ds.gloss), ds.cov);
}

// Cheap hash for glitter flakes (no textures).
float uiDecorHash(float2 p)
{
    p = frac(p * float2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return frac((p.x + p.y) * p.x);
}

// Finishes that the Blinn-Phong rig cannot give: metal reflection, holographic foil, glitter flakes.
// lit = the plate's lit colour (already carrying the paint as albedo), n = shading normal (screen-up, +z out),
// L = travel direction of the key lamp (lamp → surface), time = _Time.y.
float3 UIDecorFinish(UIDecorSampleData ds, float3 lit, float3 n, float3 L, float time)
{
    if (ds.cov < 0.002) return lit;
    float3 paint = ds.albedo.rgb / max(ds.cov, 1e-3);
    // SDFPanel's shading normals point UPHILL (a raised rim's normal leans inward — UILighting.cginc's sign
    // convention); reflections and glints want the physical normal, which leans the other way.
    n = normalize(float3(-n.xy, max(n.z, 1e-3)));
    float3 toLight = normalize(float3(-L.xy, L.z));
    float3 h = normalize(toLight + float3(0, 0, 1));

    // METAL — a studio reflection tinted by the paint (gold leaf, chrome foil, metallic flake base).
    if (ds.metal > 0.01)
    {
        float3 r = reflect(float3(0, 0, -1), n);
        float e = r.y * 5.0 + r.x * 1.6 + toLight.y * 0.6;
        float sky = smoothstep(-0.7, 0.7, e);
        float3 env = lerp(float3(0.10, 0.10, 0.12), float3(0.92, 0.95, 1.0), sky);
        env += 0.45 * exp(-pow((e - 0.1) / 0.18, 2.0));
        float3 metal = env * lerp(float3(1, 1, 1), paint * 1.25, 0.75) + pow(saturate(dot(n, h)), 60.0) * 0.6;
        lit = lerp(lit, metal, ds.metal * ds.cov);
    }

    // HOLO — rainbow bands that slide with the lamp and the relief, plus a fine diffraction ruling.
    if (ds.holo > 0.01)
    {
        float t = dot(ds.uv, float2(3.1, 2.3)) + dot(toLight.xy, float2(1.3, 0.9)) + (n.x - n.y) * 2.2 + time * 0.05;
        float3 rb = 0.5 + 0.5 * cos(6.28318 * (t + float3(0.0, 0.33, 0.67)));
        float rule = 0.85 + 0.15 * sin(dot(ds.uv, float2(900.0, -700.0)));
        float3 foil = lerp(lit, (lit * 0.55 + rb * 0.75) * rule, 0.85);
        lit = lerp(lit, foil, ds.holo * ds.cov);
    }

    // GLITTER — flakes on a fine grid, each a tiny mirror with its own tilt; it sparkles when its
    // mirror lines up with the lamp. Animated by the lamp, not by time, so a still rack is still.
    if (ds.glitter > 0.01)
    {
        float2 g = ds.uv * float2(520.0, 520.0);
        float2 cell = floor(g);
        float rnd = uiDecorHash(cell);
        float2 tilt = float2(uiDecorHash(cell + 7.1), uiDecorHash(cell + 3.7)) * 2.0 - 1.0;
        float3 fn = normalize(float3(tilt * 0.6, 1.0));
        float spark = pow(saturate(dot(fn, h)), 90.0) * step(0.55, rnd);
        float2 fc = frac(g) - 0.5;
        spark *= saturate(1.0 - dot(fc, fc) * 6.0);
        float3 flakeCol = lerp(float3(1, 1, 1), paint * 1.6, 0.5);
        lit += flakeCol * spark * 2.2 * ds.glitter * ds.cov;
        lit = lerp(lit, lit * (0.9 + 0.2 * rnd), ds.glitter * ds.cov);
    }
    return lit;
}

// Emissive paint (neon, glow): premultiplied colour × emission, added unlit like the plate's own emissive.
float3 UIDecorEmissive(UIDecorSampleData ds)
{
    return ds.albedo.rgb * ds.emissive * 1.6;
}

// Cast shadow of stickers / thick paint onto whatever is below them (plate or lower paint).
float3 UIDecorShadow(UIDecorSampleData ds, float3 c)
{
    return c * (1.0 - ds.shadow);
}

#endif // UI_DECOR_INCLUDED
