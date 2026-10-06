Shader "Hidden/DeprecatedSlider"
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

/*
// ============================================================================
// LEGACY SHADER - DEPRECATED - DO NOT USE
// ============================================================================
// This file is preserved for reference only. It is fully commented out to prevent
// Unity parse errors. See LEGACY_SHADERS.md for migration details.
//
// To view the original code, remove the comment block below.
// ============================================================================


// Shader "UI/Slider"
// {
//     Properties
//     {
//         [PerRendererData] _MainTex ("Texture", 2D) = "white" {}

//         // Line gradient properties (track/background)
//         _LineGradientColorA ("Line Gradient A", Color) = (0.3,0.3,0.3,1)
//         _LineGradientColorB ("Line Gradient B", Color) = (0.5,0.5,0.5,1)
//         _LineGradientColorC ("Line Gradient C", Color) = (0.2,0.2,0.2,1)
//         _LineGradientColorD ("Line Gradient D", Color) = (0.4,0.4,0.4,1)
//         _LineGradientDirection ("Line Gradient Direction", Vector) = (1,0,0,0)
//         _LineGradientSpeed ("Line Gradient Speed", Float) = 1
//         _LineGradientScale ("Line Gradient Scale", Float) = 1
//         _LineGradientOffset ("Line Gradient Offset", Float) = 0
//         _LineGlobalBlend ("Line Global Blend", Range(0,1)) = 0
//         _LineGlobalIntensity ("Line Global Intensity", Range(0,2)) = 1
//         [Enum(Linear,0,Radial,1,Angular,2,Diamond,3,Triangle,4)] _LineGradientType ("Line Gradient Type", Int) = 0
//         _LineAlpha ("Line Alpha", Range(0,1)) = 1

//         // Value filled gradient properties
//         _ValueFilledGradientColorA ("Value Filled Gradient A", Color) = (1,0,0,1)
//         _ValueFilledGradientColorB ("Value Filled Gradient B", Color) = (1,0.5,0,1)
//         _ValueFilledGradientColorC ("Value Filled Gradient C", Color) = (1,1,0,1)
//         _ValueFilledGradientColorD ("Value Filled Gradient D", Color) = (0,1,0,1)
//         _ValueFilledGradientDirection ("Value Filled Gradient Direction", Vector) = (1,0,0,0)
//         _ValueFilledGradientSpeed ("Value Filled Gradient Speed", Float) = 1
//         _ValueFilledGradientScale ("Value Filled Gradient Scale", Float) = 1
//         _ValueFilledGradientOffset ("Value Filled Gradient Offset", Float) = 0
//         _ValueFilledGlobalBlend ("Value Filled Global Blend", Range(0,1)) = 0
//         _ValueFilledGlobalIntensity ("Value Filled Global Intensity", Range(0,2)) = 1
//         [Enum(Linear,0,Radial,1,Angular,2,Diamond,3,Triangle,4)] _ValueFilledGradientType ("Value Filled Gradient Type", Int) = 0
//         _ValueFilledAlpha ("Value Filled Alpha", Range(0,1)) = 1

//         // Value unfilled gradient properties
//         _ValueUnfilledGradientColorA ("Value Unfilled Gradient A", Color) = (0,0,1,1)
//         _ValueUnfilledGradientColorB ("Value Unfilled Gradient B", Color) = (0,1,1,1)
//         _ValueUnfilledGradientColorC ("Value Unfilled Gradient C", Color) = (0.5,0.5,1,1)
//         _ValueUnfilledGradientColorD ("Value Unfilled Gradient D", Color) = (0,0,0.5,1)
//         _ValueUnfilledGradientDirection ("Value Unfilled Gradient Direction", Vector) = (1,0,0,0)
//         _ValueUnfilledGradientSpeed ("Value Unfilled Gradient Speed", Float) = 1
//         _ValueUnfilledGradientScale ("Value Unfilled Gradient Scale", Float) = 1
//         _ValueUnfilledGradientOffset ("Value Unfilled Gradient Offset", Float) = 0
//         _ValueUnfilledGlobalBlend ("Value Unfilled Global Blend", Range(0,1)) = 0
//         _ValueUnfilledGlobalIntensity ("Value Unfilled Global Intensity", Range(0,2)) = 1
//         [Enum(Linear,0,Radial,1,Angular,2,Diamond,3,Triangle,4)] _ValueUnfilledGradientType ("Value Unfilled Gradient Type", Int) = 0
//         _ValueUnfilledAlpha ("Value Unfilled Alpha", Range(0,1)) = 1

//         // Nub gradient properties
//         _NubGradientColorA ("Nub Gradient A", Color) = (1,1,1,1)
//         _NubGradientColorB ("Nub Gradient B", Color) = (0.8,0.8,0.8,1)
//         _NubGradientColorC ("Nub Gradient C", Color) = (0.6,0.6,0.6,1)
//         _NubGradientColorD ("Nub Gradient D", Color) = (0.4,0.4,0.4,1)
//         _NubGradientDirection ("Nub Gradient Direction", Vector) = (0,1,0,0)
//         _NubGradientSpeed ("Nub Gradient Speed", Float) = 1
//         _NubGradientScale ("Nub Gradient Scale", Float) = 1
//         _NubGradientOffset ("Nub Gradient Offset", Float) = 0
//         _NubGlobalBlend ("Nub Global Blend", Range(0,1)) = 0
//         _NubGlobalIntensity ("Nub Global Intensity", Range(0,2)) = 1
//         [Enum(Linear,0,Radial,1,Angular,2,Diamond,3,Triangle,4)] _NubGradientType ("Nub Gradient Type", Int) = 0
//         _NubAlpha ("Nub Alpha", Range(0,1)) = 1

//         // Outline gradient properties
//         _OutlineGradientColorA ("Outline Gradient A", Color) = (0.5,0.5,0.5,1)
//         _OutlineGradientColorB ("Outline Gradient B", Color) = (0.7,0.7,0.7,1)
//         _OutlineGradientColorC ("Outline Gradient C", Color) = (0.3,0.3,0.3,1)
//         _OutlineGradientColorD ("Outline Gradient D", Color) = (0.6,0.6,0.6,1)
//         _OutlineGradientDirection ("Outline Gradient Direction", Vector) = (0,1,0,0)
//         _OutlineGradientSpeed ("Outline Gradient Speed", Float) = 1
//         _OutlineGradientScale ("Outline Gradient Scale", Float) = 1
//         _OutlineGradientOffset ("Outline Gradient Offset", Float) = 0
//         _OutlineGlobalBlend ("Outline Global Blend", Range(0,1)) = 0
//         _OutlineGlobalIntensity ("Outline Global Intensity", Range(0,2)) = 1
//         [Enum(Linear,0,Radial,1,Angular,2,Diamond,3,Triangle,4)] _OutlineGradientType ("Outline Gradient Type", Int) = 0
//         _OutlineAlpha ("Outline Alpha", Range(0,1)) = 1

//         // Nub outline gradient properties
//         _NubOutlineGradientColorA ("Nub Outline Gradient A", Color) = (1,0,1,1)
//         _NubOutlineGradientColorB ("Nub Outline Gradient B", Color) = (0,1,1,1)
//         _NubOutlineGradientColorC ("Nub Outline Gradient C", Color) = (1,1,0,1)
//         _NubOutlineGradientColorD ("Nub Outline Gradient D", Color) = (1,0,0,1)
//         _NubOutlineGradientDirection ("Nub Outline Gradient Direction", Vector) = (1,0,0,0)
//         _NubOutlineGradientSpeed ("Nub Outline Gradient Speed", Float) = 1
//         _NubOutlineGradientScale ("Nub Outline Gradient Scale", Float) = 1
//         _NubOutlineGradientOffset ("Nub Outline Gradient Offset", Float) = 0
//         _NubOutlineGlobalBlend ("Nub Outline Global Blend", Range(0,1)) = 0
//         _NubOutlineGlobalIntensity ("Nub Outline Global Intensity", Range(0,2)) = 1
//         [Enum(Linear,0,Radial,1,Angular,2,Diamond,3,Triangle,4)] _NubOutlineGradientType ("Nub Outline Type", Int) = 0
//         _NubOutlineAlpha ("Nub Outline Alpha", Range(0,1)) = 1

//         // Glow gradient properties
//         _GlowGradientColorA ("Glow Gradient A", Color) = (1,0,1,1)
//         _GlowGradientColorB ("Glow Gradient B", Color) = (1,1,0,1)
//         _GlowGradientColorC ("Glow Gradient C", Color) = (0,1,1,1)
//         _GlowGradientColorD ("Glow Gradient D", Color) = (1,0,0,1)
//         _GlowGradientDirection ("Glow Gradient Direction", Vector) = (1,1,0,0)
//         _GlowGradientSpeed ("Glow Gradient Speed", Float) = 1
//         _GlowGradientScale ("Glow Gradient Scale", Float) = 1
//         _GlowGradientOffset ("Glow Gradient Offset", Float) = 0
//         _GlowGlobalBlend ("Glow Global Blend", Range(0,1)) = 0
//         _GlowGlobalIntensity ("Glow Global Intensity", Range(0,2)) = 1
//         [Enum(Linear,0,Radial,1,Angular,2,Diamond,3,Triangle,4)] _GlowGradientType ("Glow Gradient Type", Int) = 0
//         _GlowWidth ("Glow Width", Range(0.01,0.5)) = 0.1
//         _GlowIntensity ("Glow Intensity", Range(0,5)) = 2
//         _GlowAlpha ("Glow Alpha", Range(0,1)) = 1

//         // Slider parameters
//         _Value ("Value", Range(0,1)) = 0.5
//         _ValueWidthFactor ("Value Width Factor", Range(0.1, 1.0)) = 0.75
//         _NubWidth ("Nub Width", Range(0.001, 1.0)) = 0.05
//         _NubHeight ("Nub Height", Range(0.001, 1.0)) = 0.25
//         _OutlineWidth ("Outline Width", Range(0.001, 0.5)) = 0.02
//         _RoundedRadius ("Rounded Radius", Range(0,0.5)) = 0.1
//         _GlowWidth ("Glow Width", Range(0.001, 0.5)) = 0.1

//         // Unity UI
//         _StencilComp ("Stencil Comparison", Float) = 8
//         _Stencil ("Stencil ID", Float) = 0
//         _StencilOp ("Stencil Operation", Float) = 0
//         _StencilWriteMask ("Stencil Write Mask", Float) = 255
//         _StencilReadMask ("Stencil Read Mask", Float) = 255
//         _ColorMask ("Color Mask", Float) = 15
//     }

//     SubShader
//     {
//         Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }
        
//         Stencil {
//             Ref [_Stencil]
//             Comp [_StencilComp]
//             Pass [_StencilOp]
//             ReadMask [_StencilReadMask]
//             WriteMask [_StencilWriteMask]
//         }

//         Cull Off
//         Lighting Off
//         ZWrite Off
//         ZTest [unity_GUIZTestMode]
//         ColorMask [_ColorMask]

//         Pass
//         {
//             Name "MainSlider"
//             Blend SrcAlpha OneMinusSrcAlpha

//             CGPROGRAM
//             #pragma vertex vert
//             #pragma fragment frag
//             #include "UnityCG.cginc"
//             #include "UnityUI.cginc"
//             #include "./CG/Core/UIGradients.cginc"
//             #include "./CG/SDF/SDFPrimitives.cginc"
//             #include "./CG/SDF/SDFOperations.cginc"

//             struct appdata_t
//             {
//                 float4 vertex : POSITION;
//                 float4 color : COLOR;
//                 float2 texcoord : TEXCOORD0;
//             };

//             struct v2f
//             {
//                 float4 vertex : SV_POSITION;
//                 float2 texcoord : TEXCOORD0;
//                 float4 screenPos : TEXCOORD1;
//                 float4 worldPos : TEXCOORD2;
//             };

//             // Line gradient (track/background)
//             float4 _LineGradientColorA, _LineGradientColorB, _LineGradientColorC, _LineGradientColorD;
//             float2 _LineGradientDirection; 
//             float _LineGradientSpeed, _LineGradientScale, _LineGradientOffset;
//             float _LineGlobalBlend, _LineGlobalIntensity;
//             int _LineGradientType;
//             float _LineAlpha;

//             // Value filled gradient
//             float4 _ValueFilledGradientColorA, _ValueFilledGradientColorB, _ValueFilledGradientColorC, _ValueFilledGradientColorD;
//             float2 _ValueFilledGradientDirection; 
//             float _ValueFilledGradientSpeed, _ValueFilledGradientScale, _ValueFilledGradientOffset;
//             float _ValueFilledGlobalBlend, _ValueFilledGlobalIntensity;
//             int _ValueFilledGradientType;
//             float _ValueFilledAlpha;

//             // Value unfilled gradient
//             float4 _ValueUnfilledGradientColorA, _ValueUnfilledGradientColorB, _ValueUnfilledGradientColorC, _ValueUnfilledGradientColorD;
//             float2 _ValueUnfilledGradientDirection; 
//             float _ValueUnfilledGradientSpeed, _ValueUnfilledGradientScale, _ValueUnfilledGradientOffset;
//             float _ValueUnfilledGlobalBlend, _ValueUnfilledGlobalIntensity;
//             int _ValueUnfilledGradientType;
//             float _ValueUnfilledAlpha;
//             float _ValueWidthFactor;

//             // Nub gradient
//             float4 _NubGradientColorA, _NubGradientColorB, _NubGradientColorC, _NubGradientColorD;
//             float2 _NubGradientDirection; 
//             float _NubGradientSpeed, _NubGradientScale, _NubGradientOffset;
//             float _NubGlobalBlend, _NubGlobalIntensity;
//             int _NubGradientType;
//             float _NubAlpha;

//             // Outline gradient
//             float4 _OutlineGradientColorA, _OutlineGradientColorB, _OutlineGradientColorC, _OutlineGradientColorD;
//             float2 _OutlineGradientDirection; 
//             float _OutlineGradientSpeed, _OutlineGradientScale, _OutlineGradientOffset;
//             float _OutlineGlobalBlend, _OutlineGlobalIntensity;
//             int _OutlineGradientType;
//             float _OutlineAlpha;

//             // Nub outline gradient
//             float4 _NubOutlineGradientColorA, _NubOutlineGradientColorB, _NubOutlineGradientColorC, _NubOutlineGradientColorD;
//             float2 _NubOutlineGradientDirection; 
//             float _NubOutlineGradientSpeed, _NubOutlineGradientScale, _NubOutlineGradientOffset;
//             float _NubOutlineGlobalBlend, _NubOutlineGlobalIntensity;
//             int _NubOutlineGradientType;
//             float _NubOutlineAlpha;

//             // Slider parameters
//             float _Value;
//             float _NubWidth;
//             float _NubHeight;
//             float _OutlineWidth;
//             float _RoundedRadius;
//             float _GlowWidth;
            
//             float4 _ClipRect;

//             v2f vert(appdata_t v)
//             {
//                 v2f o;
//                 o.vertex = UnityObjectToClipPos(v.vertex);
//                 o.texcoord = v.texcoord * 2.0 - 1.0; // [-1,1] range
//                 o.screenPos = ComputeScreenPos(o.vertex);
//                 o.worldPos = v.vertex;
//                 return o;
//             }

//             fixed4 frag(v2f i) : SV_Target
//             {
//                 float2 uv = i.texcoord;
                
//                 // Antialiasing width
//                 float aa = fwidth(length(uv)) * 0.75;
                
//                 // Calculate aspect ratio and orientation (like SDFButton)
//                 float2 derivatives = float2(length(float2(ddx(uv.x), ddy(uv.x))), 
//                                          length(float2(ddx(uv.y), ddy(uv.y))));
//                 bool isHorizontal = derivatives.x < derivatives.y;
                
//                 // Calculate aspect ratio scale for proper compensation (like SDFButton)
//                 float maxDerivative = max(derivatives.x, derivatives.y);
//                 float2 aspectRatio = float2(derivatives.x / maxDerivative, derivatives.y / maxDerivative);
                
//                 // Apply aspect ratio compensation ONLY to margins and corner radius (not thicknesses)
//                 // Thicknesses should maintain consistent screen-space appearance
                
//                 // Calculate per-dimension margins for uniform screen-space edge distance
//                 float rawMargin = _GlowWidth + _OutlineWidth;
                
//                 // The slider fills most of the quad, leaving room for outline/glow
//                 // Use the same margin for both dimensions to ensure consistent spacing
//                 float2 mainSize = float2(1.0 - rawMargin * 2.0, 1.0 - rawMargin * 2.0);
//                 float2 outlineSize = mainSize + _OutlineWidth * 2.0; // Outline extends beyond main area
//                 float2 glowSize = float2(1.0, 1.0); // Keep full bounds for glow calculation
                
//                 // Scale corner radius based on aspect ratio for consistent visual appearance
//                 float scaledRadius = _RoundedRadius * min(aspectRatio.x, aspectRatio.y);
                
//                 // Calculate sizes based on orientation
//                 float2 lineSize, valueSize, nubSize, valueUnfilledSize;
//                 float2 nubPos;
                
//                 // Calculate base nub size based on orientation
//                 float2 baseNubSize;
                
//                 if (isHorizontal) {
//                     // For horizontal slider - use the full available height minus just outline/glow
//                     float nubHeight = mainSize.y * _NubHeight;
//                     float nubWidth = nubHeight * _NubWidth; // Maintain aspect ratio
//                     baseNubSize = float2(nubWidth, nubHeight);
                    
//                     // Use the full available height for the line (minus just outline/glow margins)
//                     float availableHeight = mainSize.y;
//                     float baseLineWidth = availableHeight; // Use 100% of available height
//                     float valueTrackWidth = baseLineWidth * _ValueWidthFactor;
                    
//                     lineSize = float2(mainSize.x, baseLineWidth);
//                     valueSize = float2(mainSize.x * _Value, valueTrackWidth);
//                     valueUnfilledSize = float2(mainSize.x, valueTrackWidth);
                    
//                     // Position nub within the main area bounds
//                     float nubTravel = mainSize.x - baseNubSize.x;
//                     nubPos = float2((_Value * 2.0 - 1.0) * nubTravel * 0.5, 0);
//                 } else {
//                     // For vertical slider - use the full available width minus just outline/glow
//                     float nubWidth = mainSize.x * _NubWidth;
//                     float nubHeight = nubWidth * _NubHeight; // Maintain aspect ratio
//                     baseNubSize = float2(nubWidth, nubHeight);
                    
//                     // Use the full available width for the line (minus just outline/glow margins)
//                     float availableWidth = mainSize.x;
//                     float baseLineWidth = availableWidth; // Use 100% of available width
//                     float valueTrackWidth = baseLineWidth * _ValueWidthFactor;
                    
//                     lineSize = float2(baseLineWidth, mainSize.y);
//                     valueSize = float2(valueTrackWidth, mainSize.y * _Value);
//                     valueUnfilledSize = float2(valueTrackWidth, mainSize.y);
                    
//                     // Position nub within the main area bounds
//                     float nubTravel = mainSize.y - baseNubSize.y;
//                     nubPos = float2(0, (_Value * 2.0 - 1.0) * nubTravel * 0.5);
//                 }
                
//                 nubSize = baseNubSize;
                
//                 // Calculate distances for shapes
//                 float lineDist = RoundedRectSDF(uv, lineSize, scaledRadius);
//                 float lineOutlineDist = RoundedRectSDF(uv, lineSize + _OutlineWidth, scaledRadius);
                
//                 // Value distance (positioned from start)
//                 float2 valueOffset = isHorizontal ? 
//                     float2(-lineSize.x + valueSize.x, 0) : 
//                     float2(0, -lineSize.y + valueSize.y);
//                 float valueDist = RoundedRectSDF(uv - valueOffset, valueSize, scaledRadius);
                
//                 // Value unfilled distance (full line length but with value width)
//                 float valueUnfilledDist = RoundedRectSDF(uv, valueUnfilledSize, scaledRadius);
                
//                 // Nub distances
//                 float nubDist = RoundedRectSDF(uv - nubPos, nubSize, scaledRadius);
//                 float nubOutlineDist = RoundedRectSDF(uv - nubPos, nubSize + _OutlineWidth, scaledRadius);
                
//                 // Create masks
//                 float lineMask = smoothstep(aa, -aa, lineDist);
//                 float lineOutlineMask = smoothstep(aa, -aa, lineOutlineDist) * (1.0 - lineMask);
//                 float valueMask = smoothstep(aa, -aa, valueDist) * lineMask;
//                 float valueUnfilledMask = smoothstep(aa, -aa, valueUnfilledDist);
//                 float nubMask = smoothstep(aa, -aa, nubDist);
//                 float nubOutlineMask = smoothstep(aa, -aa, nubOutlineDist) * (1.0 - nubMask);
                
//                 // Clamp masks to UI bounds to prevent extending beyond the quad
//                 float2 clampedUV = clamp(uv, -1.0, 1.0);
//                 float distanceFromBounds = length(uv - clampedUV);
//                 float boundsMask = 1.0 - saturate(distanceFromBounds / 0.05); // Sharp cutoff near bounds
                
//                 lineMask *= boundsMask;
//                 lineOutlineMask *= boundsMask;
//                 valueMask *= boundsMask;
//                 valueUnfilledMask *= boundsMask;
//                 nubMask *= boundsMask;
//                 nubOutlineMask *= boundsMask;
                
//                 // Initialize output color
//                 fixed4 col = fixed4(0, 0, 0, 0);
                
//                 // "Unwrapped" UV for linear gradients
//                 float2 unwrappedUV = uv / lineSize;
                
//                 // Render line (track background)
//                 if (lineMask > 0.01) {
//                     float2 gradientUV = (_LineGradientType == 2) ? uv : unwrappedUV;
                    
//                     GradientParams lineParams;
//                     lineParams.colorA = _LineGradientColorA;
//                     lineParams.colorB = _LineGradientColorB;
//                     lineParams.colorC = _LineGradientColorC;
//                     lineParams.colorD = _LineGradientColorD;
//                     lineParams.direction = _LineGradientDirection;
//                     lineParams.speed = _LineGradientSpeed;
//                     lineParams.manualPosition = 0;
//                     lineParams.globalBlend = _LineGlobalBlend;
//                     lineParams.globalIntensity = _LineGlobalIntensity;
//                     lineParams.scale = _LineGradientScale;
//                     lineParams.offset = _LineGradientOffset;
                    
//                     float4 lineColor = GetGradientColor(lineParams, _LineGradientType, gradientUV, i.screenPos, _Time.y);
//                     lineColor.a *= _LineAlpha * lineMask;
//                     col = lerp(col, lineColor, lineColor.a);
//                 }

//                 // Render outline (border around the line)
//                 if (lineOutlineMask > 0.01) {
//                     float2 gradientUV = (_OutlineGradientType == 2) ? uv : unwrappedUV;
                    
//                     GradientParams outlineParams;
//                     outlineParams.colorA = _OutlineGradientColorA;
//                     outlineParams.colorB = _OutlineGradientColorB;
//                     outlineParams.colorC = _OutlineGradientColorC;
//                     outlineParams.colorD = _OutlineGradientColorD;
//                     outlineParams.direction = _OutlineGradientDirection;
//                     outlineParams.speed = _OutlineGradientSpeed;
//                     outlineParams.manualPosition = 0;
//                     outlineParams.globalBlend = _OutlineGlobalBlend;
//                     outlineParams.globalIntensity = _OutlineGlobalIntensity;
//                     outlineParams.scale = _OutlineGradientScale;
//                     outlineParams.offset = _OutlineGradientOffset;
                    
//                     float4 outlineColor = GetGradientColor(outlineParams, _OutlineGradientType, gradientUV, i.screenPos, _Time.y);
//                     outlineColor.a *= _OutlineAlpha * lineOutlineMask;
//                     col = lerp(col, outlineColor, outlineColor.a);
//                 }

//                 // Render value unfilled area (background for the entire track)
//                 if (valueUnfilledMask > 0.01) {
//                     float2 gradientUV = (_ValueUnfilledGradientType == 2) ? uv : unwrappedUV;
                    
//                     GradientParams valueUnfilledParams;
//                     valueUnfilledParams.colorA = _ValueUnfilledGradientColorA;
//                     valueUnfilledParams.colorB = _ValueUnfilledGradientColorB;
//                     valueUnfilledParams.colorC = _ValueUnfilledGradientColorC;
//                     valueUnfilledParams.colorD = _ValueUnfilledGradientColorD;
//                     valueUnfilledParams.direction = _ValueUnfilledGradientDirection;
//                     valueUnfilledParams.speed = _ValueUnfilledGradientSpeed;
//                     valueUnfilledParams.manualPosition = 0;
//                     valueUnfilledParams.globalBlend = _ValueUnfilledGlobalBlend;
//                     valueUnfilledParams.globalIntensity = _ValueUnfilledGlobalIntensity;
//                     valueUnfilledParams.scale = _ValueUnfilledGradientScale;
//                     valueUnfilledParams.offset = _ValueUnfilledGradientOffset;
                    
//                     float4 valueUnfilledColor = GetGradientColor(valueUnfilledParams, _ValueUnfilledGradientType, gradientUV, i.screenPos, _Time.y);
//                     valueUnfilledColor.a *= _ValueUnfilledAlpha * valueUnfilledMask;
//                     col = lerp(col, valueUnfilledColor, valueUnfilledColor.a);
//                 }

//                 // Render value filled area (on top of unfilled)
//                 if (valueMask > 0.01) {
//                     float2 gradientUV = (_ValueFilledGradientType == 2) ? uv : unwrappedUV;
                    
//                     GradientParams valueFilledParams;
//                     valueFilledParams.colorA = _ValueFilledGradientColorA;
//                     valueFilledParams.colorB = _ValueFilledGradientColorB;
//                     valueFilledParams.colorC = _ValueFilledGradientColorC;
//                     valueFilledParams.colorD = _ValueFilledGradientColorD;
//                     valueFilledParams.direction = _ValueFilledGradientDirection;
//                     valueFilledParams.speed = _ValueFilledGradientSpeed;
//                     valueFilledParams.manualPosition = 0;
//                     valueFilledParams.globalBlend = _ValueFilledGlobalBlend;
//                     valueFilledParams.globalIntensity = _ValueFilledGlobalIntensity;
//                     valueFilledParams.scale = _ValueFilledGradientScale;
//                     valueFilledParams.offset = _ValueFilledGradientOffset;
                    
//                     float4 valueFilledColor = GetGradientColor(valueFilledParams, _ValueFilledGradientType, gradientUV, i.screenPos, _Time.y);
//                     valueFilledColor.a *= _ValueFilledAlpha * valueMask;
//                     col = lerp(col, valueFilledColor, valueFilledColor.a);
//                 }

//                 // Render nub outline
//                 if (nubOutlineMask > 0.01) {
//                     float2 nubSpaceUV = (uv - nubPos) / nubSize; // Normalized for linear/radial
//                     float2 gradientUV = (_NubOutlineGradientType == 2) ? uv : nubSpaceUV;
                    
//                     GradientParams nubOutlineParams;
//                     nubOutlineParams.colorA = _NubOutlineGradientColorA;
//                     nubOutlineParams.colorB = _NubOutlineGradientColorB;
//                     nubOutlineParams.colorC = _NubOutlineGradientColorC;
//                     nubOutlineParams.colorD = _NubOutlineGradientColorD;
//                     nubOutlineParams.direction = _NubOutlineGradientDirection;
//                     nubOutlineParams.speed = _NubOutlineGradientSpeed;
//                     nubOutlineParams.manualPosition = 0;
//                     nubOutlineParams.globalBlend = _NubOutlineGlobalBlend;
//                     nubOutlineParams.globalIntensity = _NubOutlineGlobalIntensity;
//                     nubOutlineParams.scale = _NubOutlineGradientScale;
//                     nubOutlineParams.offset = _NubOutlineGradientOffset;
                    
//                     float4 nubOutlineColor = GetGradientColor(nubOutlineParams, _NubOutlineGradientType, gradientUV, i.screenPos, _Time.y);
//                     nubOutlineColor.a *= _NubOutlineAlpha * nubOutlineMask;
//                     col = lerp(col, nubOutlineColor, nubOutlineColor.a);
//                 }

//                 // Render nub
//                 if (nubMask > 0.01) {
//                     float2 nubSpaceUV = (uv - nubPos) / nubSize; // Normalized for linear/radial
//                     float2 gradientUV = (_NubGradientType == 2) ? uv : nubSpaceUV;
                    
//                     GradientParams nubParams;
//                     nubParams.colorA = _NubGradientColorA;
//                     nubParams.colorB = _NubGradientColorB;
//                     nubParams.colorC = _NubGradientColorC;
//                     nubParams.colorD = _NubGradientColorD;
//                     nubParams.direction = _NubGradientDirection;
//                     nubParams.speed = _NubGradientSpeed;
//                     nubParams.manualPosition = 0;
//                     nubParams.globalBlend = _NubGlobalBlend;
//                     nubParams.globalIntensity = _NubGlobalIntensity;
//                     nubParams.scale = _NubGradientScale;
//                     nubParams.offset = _NubGradientOffset;
                    
//                     float4 nubColor = GetGradientColor(nubParams, _NubGradientType, gradientUV, i.screenPos, _Time.y);
//                     nubColor.a *= _NubAlpha * nubMask;
//                     col = lerp(col, nubColor, nubColor.a);
//                 }
                
//                 // Apply Unity UI clipping
//                 col.a *= UnityGet2DClipping(i.worldPos.xy, _ClipRect);
                
//                 return col;
//             }
//             ENDCG
//         }

//         Pass
//         {
//             Name "AdditiveGlow"
//             Blend One One
//             CGPROGRAM
//             #pragma vertex vert
//             #pragma fragment frag
//             #include "UnityCG.cginc"
//             #include "UnityUI.cginc"
//             #include "./CG/Core/UIGradients.cginc"
//             #include "./CG/SDF/SDFPrimitives.cginc"
//             #include "./CG/SDF/SDFOperations.cginc"

//             struct appdata_t
//             {
//                 float4 vertex : POSITION;
//                 float4 color : COLOR;
//                 float2 texcoord : TEXCOORD0;
//             };

//             struct v2f
//             {
//                 float4 vertex : SV_POSITION;
//                 float2 texcoord : TEXCOORD0;
//                 float4 screenPos : TEXCOORD1;
//                 float4 worldPos : TEXCOORD2;
//             };

//             // Glow gradient
//             float4 _GlowGradientColorA, _GlowGradientColorB, _GlowGradientColorC, _GlowGradientColorD;
//             float2 _GlowGradientDirection; 
//             float _GlowGradientSpeed, _GlowGradientScale, _GlowGradientOffset;
//             float _GlowGlobalBlend, _GlowGlobalIntensity;
//             int _GlowGradientType;
//             float _GlowWidth, _GlowIntensity;
//             float _GlowAlpha;

//             // Slider parameters needed for glow calculation
//             float _Value;
//             float _ValueWidthFactor;
//             float _NubWidth;
//             float _NubHeight;
//             float _OutlineWidth;
//             float _RoundedRadius;
            
//             float4 _ClipRect;

//             v2f vert(appdata_t v)
//             {
//                 v2f o;
//                 o.vertex = UnityObjectToClipPos(v.vertex);
//                 o.texcoord = v.texcoord * 2.0 - 1.0; // [-1,1] range
//                 o.screenPos = ComputeScreenPos(o.vertex);
//                 o.worldPos = v.vertex;
//                 return o;
//             }

//             // Get distance from the slider geometry for glow calculation
//             float getSliderGeometryDistance(float2 uv)
//             {
//                 // Calculate aspect ratio and orientation (EXACTLY like main pass)
//                 float2 derivatives = float2(length(float2(ddx(uv.x), ddy(uv.x))), 
//                                          length(float2(ddx(uv.y), ddy(uv.y))));
//                 bool isHorizontal = derivatives.x < derivatives.y;
                
//                 // Calculate aspect ratio scale for proper compensation (EXACTLY like main pass)
//                 float maxDerivative = max(derivatives.x, derivatives.y);
//                 float2 aspectRatio = float2(derivatives.x / maxDerivative, derivatives.y / maxDerivative);
                
//                 // Calculate per-dimension margins for uniform screen-space edge distance (EXACTLY like main pass)
//                 float rawMargin = _GlowWidth + _OutlineWidth;
                
//                 // The slider fills most of the quad, leaving room for outline/glow
//                 // Use the same margin for both dimensions to ensure consistent spacing
//                 float2 mainSize = float2(1.0 - rawMargin * 2.0, 1.0 - rawMargin * 2.0);
                
//                 // Scale corner radius based on aspect ratio for consistent visual appearance (EXACTLY like main pass)
//                 float scaledRadius = _RoundedRadius * min(aspectRatio.x, aspectRatio.y);
                
//                 // Calculate sizes based on orientation (EXACTLY like main pass)
//                 float2 lineSize, nubSize;
//                 float2 nubPos;
                
//                 // Calculate base nub size based on orientation
//                 float2 baseNubSize;
                
//                 if (isHorizontal) {
//                     // For horizontal slider - use the full available height minus just outline/glow
//                     float nubHeight = mainSize.y * _NubHeight;
//                     float nubWidth = nubHeight * _NubWidth; // Maintain aspect ratio
//                     baseNubSize = float2(nubWidth, nubHeight);
                    
//                     // Use the full available height for the line (minus just outline/glow margins)
//                     float availableHeight = mainSize.y;
//                     float baseLineWidth = availableHeight; // Use 100% of available height
//                     float valueTrackWidth = baseLineWidth * _ValueWidthFactor;
                    
//                     lineSize = float2(mainSize.x, baseLineWidth);
//                     float nubTravel = mainSize.x - baseNubSize.x;
//                     nubPos = float2((_Value * 2.0 - 1.0) * nubTravel * 0.5, 0);
//                 } else {
//                     // For vertical slider - use the full available width minus just outline/glow
//                     float nubWidth = mainSize.x * _NubWidth;
//                     float nubHeight = nubWidth * _NubHeight; // Maintain aspect ratio
//                     baseNubSize = float2(nubWidth, nubHeight);
                    
//                     // Use the full available width for the line (minus just outline/glow margins)
//                     float availableWidth = mainSize.x;
//                     float baseLineWidth = availableWidth; // Use 100% of available width
//                     float valueTrackWidth = baseLineWidth * _ValueWidthFactor;
                    
//                     lineSize = float2(baseLineWidth, mainSize.y);
//                     float nubTravel = mainSize.y - baseNubSize.y;
//                     nubPos = float2(0, (_Value * 2.0 - 1.0) * nubTravel * 0.5);
//                 }
                
//                 nubSize = baseNubSize;
                
//                 // Calculate distances - EXACTLY like main pass
//                 // Use raw _OutlineWidth (no aspect ratio compensation) for consistent screen-space glow
//                 float lineOutlineDist = RoundedRectSDF(uv, lineSize + _OutlineWidth, scaledRadius);
//                 float nubOutlineDist = RoundedRectSDF(uv - nubPos, nubSize + _OutlineWidth, scaledRadius);
                
//                 // Return minimum distance to any visible geometry
//                 return min(lineOutlineDist, nubOutlineDist);
//             }

//             fixed4 frag(v2f i) : SV_Target
//             {
//                 float2 uv = i.texcoord;
                
//                 // Get distance from the slider geometry
//                 float geomDistance = getSliderGeometryDistance(uv);
                
//                 // Only apply glow outside the shape (positive distances)
//                 if (geomDistance <= 0.0) {
//                     return fixed4(0, 0, 0, 0); // No glow inside the shape
//                 }
                
//                 // Calculate glow falloff: full intensity at edge (distance = 0), zero at glow width
//                 // Use raw _GlowWidth (no aspect ratio compensation) for consistent screen-space glow
//                 float normalizedDistance = geomDistance / _GlowWidth;
//                 float glowFalloff = 1.0 - saturate(normalizedDistance);
                

                
//                 // Apply smooth falloff curve for more natural glow
//                 glowFalloff = pow(glowFalloff, 1.5); // Slightly softer than quadratic
                
//                 // Antialiasing for smooth edges
//                 float aa = fwidth(geomDistance) * 0.75;
//                 float glowMask = smoothstep(0.0, aa, glowFalloff);
                
//                 GradientParams glowParams;
//                 glowParams.colorA = _GlowGradientColorA;
//                 glowParams.colorB = _GlowGradientColorB;
//                 glowParams.colorC = _GlowGradientColorC;
//                 glowParams.colorD = _GlowGradientColorD;
//                 glowParams.direction = _GlowGradientDirection;
//                 glowParams.speed = _GlowGradientSpeed;
//                 glowParams.manualPosition = 0;
//                 glowParams.globalBlend = _GlowGlobalBlend;
//                 glowParams.globalIntensity = _GlowGlobalIntensity;
//                 glowParams.scale = _GlowGradientScale;
//                 glowParams.offset = _GlowGradientOffset;
                
//                 float4 glowColor = GetGradientColor(glowParams, _GlowGradientType, uv, i.screenPos, _Time.y);
                
//                 // For additive glow: apply falloff directly to RGB, keep alpha constant for blending
//                 glowColor.rgb *= glowFalloff * _GlowIntensity * _GlowAlpha;
//                 glowColor.a = _GlowAlpha; // Keep alpha constant for proper additive blending

//                 glowColor.a *= UnityGet2DClipping(i.worldPos.xy, _ClipRect);

//                 return glowColor;
//             }
//             ENDCG
//         }
//     }
//     FallBack "UI/Default"
// }
*/
