// ============================================================================
// DecorResolve.shader — the four decor targets → what a decorated plate samples (Docs/Decor.md §2.3)
// ============================================================================
// Fullscreen over one panel's decor RTs (uv 0..1, decor space = uv * _SizeUnits canvas units). Two outputs:
//   SV_Target0 _DecorSurfTex = (relief normal xy * 0.5 + 0.5, gloss, metal)
//   SV_Target1 _DecorFxTex   = (holo, glitter, emissive, cast shadow)
// The relief normal follows SDFPanel's sign convention: xy points UPHILL (a raised rim's normal leans inward,
// see UILighting.cginc), so `faceNormal + relief` lights a sticker edge from the same lamp as the bevel round it.
// The SHADOW is the height field ray-marched toward the key lamp (_Lamp: its position in decor space and its
// height, canvas units) — every sticker edge, tape strip and thick paint ridge drops a soft shadow on what is
// under it in the lamp's direction — plus a little contact occlusion so a sticker reads as ON the plate even
// under an overhead lamp. Material channels are demultiplied (the item targets are premultiplied).
// ============================================================================

Shader "UI/Decor/Resolve"
{
    Properties
    {
        _MatTex ("mat", 2D) = "black" {}
        _FxTex ("fx", 2D) = "black" {}
        _HeightTex ("height", 2D) = "black" {}
        _SizeUnits ("Decor size (canvas units)", Vector) = (800, 400, 0, 0)
        _TexelUnits ("Canvas units per texel", Vector) = (1, 1, 0, 0)
        _HeightUnits ("Canvas units per unit of height", Float) = 4
        _Lamp ("Key lamp (decor xy, height, enabled)", Vector) = (0, 1000, 800, 1)
        _ShadowStrength ("Shadow strength", Range(0, 1)) = 0.6
        _ReliefGain ("Relief normal gain", Range(0, 2)) = 0.7
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always Lighting Off Blend Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #include "UnityCG.cginc"

            sampler2D _MatTex, _FxTex, _HeightTex;
            float4 _SizeUnits, _TexelUnits, _Lamp;
            float _HeightUnits, _ShadowStrength, _ReliefGain;

            struct appdata_t { float4 vertex : POSITION; float2 texcoord : TEXCOORD0; };
            struct v2f { float4 vertex : SV_POSITION; float2 uv : TEXCOORD0; };

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            struct ResolveOut
            {
                float4 surf : SV_Target0;
                float4 fx   : SV_Target1;
            };

            float H(float2 uv) { return tex2Dlod(_HeightTex, float4(uv, 0, 0)).r * _HeightUnits; }

            ResolveOut frag(v2f i)
            {
                float2 uv = i.uv;
                float2 tx = _TexelUnits.xy / max(_SizeUnits.xy, 1.0);    // one texel in uv
                float2 tu = _TexelUnits.xy;                              // one texel in canvas units

                // Sobel on the height field → uphill gradient (canvas units of height per canvas unit).
                float h00 = H(uv + tx * float2(-1, -1)), h10 = H(uv + tx * float2(0, -1)), h20 = H(uv + tx * float2(1, -1));
                float h01 = H(uv + tx * float2(-1, 0)),  h11 = H(uv),                       h21 = H(uv + tx * float2(1, 0));
                float h02 = H(uv + tx * float2(-1, 1)),  h12 = H(uv + tx * float2(0, 1)),  h22 = H(uv + tx * float2(1, 1));
                float gx = ((h20 + 2.0 * h21 + h22) - (h00 + 2.0 * h01 + h02)) / (8.0 * tu.x);
                float gy = ((h02 + 2.0 * h12 + h22) - (h00 + 2.0 * h10 + h20)) / (8.0 * tu.y);
                float2 g = float2(gx, gy) * _ReliefGain;
                float gl = length(g);
                g *= min(1.0, 1.1 / max(gl, 1e-4));                    // cap the tilt (~48°)

                float4 m = tex2Dlod(_MatTex, float4(uv, 0, 0));
                float4 f = tex2Dlod(_FxTex, float4(uv, 0, 0));
                float inv = 1.0 / max(m.a, 1e-3);
                float invF = 1.0 / max(f.a, 1e-3);

                // Cast shadow: march toward the lamp; any point higher than the ray from here occludes it.
                float2 P = uv * _SizeUnits.xy;
                float2 toL = _Lamp.xy - P;
                float dist = max(length(toL), 1.0);
                float2 dir = toL / dist;
                float slope = max(_Lamp.z, 1.0) / dist;                  // rise of the light ray per unit
                float occ = 0.0;
                float stepU = max(tu.x, tu.y) * 1.25;
                [unroll] for (int k = 1; k <= 10; k++)
                {
                    float t = stepU * k;
                    float hq = H(uv + dir * t / _SizeUnits.xy);
                    occ = max(occ, saturate((hq - h11 - t * slope) / (0.5 + t * 0.35)));
                }
                // Contact occlusion: a ring of taps a few units out.
                float ring = 0.0;
                float rr = 2.6;
                [unroll] for (int j = 0; j < 8; j++)
                {
                    float a = j * 0.785398;
                    ring += H(uv + float2(cos(a), sin(a)) * rr / _SizeUnits.xy);
                }
                float ao = saturate((ring / 8.0 - h11) / (_HeightUnits * 0.9));
                float shadow = saturate(occ * 0.62 + ao * 0.3) * _ShadowStrength * step(0.5, _Lamp.w);

                ResolveOut o;
                o.surf = float4(g * 0.5 + 0.5, saturate(m.r * inv), saturate(m.g * inv));
                o.fx = float4(saturate(m.b * inv), saturate(f.r * invF), saturate(f.g * invF), shadow);
                return o;
            }
            ENDCG
        }
    }
}
