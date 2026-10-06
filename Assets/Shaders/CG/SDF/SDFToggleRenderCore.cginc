// SDFToggleRenderCore.cginc
// Fragment shader for all per-type SDFToggle shaders.
// Must be included AFTER:
//   - SDFToggleSharedUniforms.cginc  (all non-param uniforms)
//   - SDFToggle{Type}Defs.cginc      (named uniforms + #defines for _ToggleParamN)
//   - SDFToggleLayers.cginc          (helper functions)
// and the v2f struct must already be defined.

#ifndef SDFTOGGLE_RENDER_CORE_INCLUDED
#define SDFTOGGLE_RENDER_CORE_INCLUDED

fixed4 frag(v2f IN) : SV_Target
{
    float2 uv     = IN.texcoord;
    float2 center = float2(0.5, 0.5);
    float time    = _Time.y;

    // Aspect ratio correction
    float rectAspect = (_AspectRatio > 0.001)
        ? _AspectRatio
        : abs(ddy(uv.y)) / max(0.0001, abs(ddx(uv.x)));
    float2 aspectScale = float2(max(rectAspect, 1.0), max(1.0 / rectAspect, 1.0));

    float2 pos   = (uv - center) * 2.0 * aspectScale;
    float2 uvIso = (uv - center) / float2(aspectScale.x, aspectScale.y) + center;

    // Background half-extents
    float bgHalfW = max(0.001, aspectScale.x - _BgPadding);
    float bgHalfH = max(0.001, aspectScale.y - _BgPadding);

    // Toggle body half-extents
    float bodyHalfW = max(0.001, bgHalfW - _TogglePadding);
    float bodyHalfH = max(0.001, bgHalfH - _TogglePadding);

    // Bevel geometry
    float bevelDistVal  = (_ToggleBevelEnabled > 0.5) ? _ToggleBevelDistance : 0.0;
    float bevelDepthRaw = (_ToggleBevelEnabled > 0.5) ? abs(_ToggleBevelDepth) : 0.0;
    float maxDim        = min(bodyHalfW, bodyHalfH);
    float pseudoHeight  = maxDim * lerp(0.05, 0.5, bevelDepthRaw);
    float rimWidth      = (_ToggleRimEnabled > 0.5) ? _ToggleRimWidth : 0.0;
    float faceInset     = rimWidth + bevelDistVal;

    // Lights
    // The three scene lights. No per-material lights exist any more — see UILighting.cginc.
    // Resolved ONCE here; every shadow call below reads these locals instead of re-expanding
    // the macro (which is what made this fragment program so expensive to compile).
    UILight light1 = UI_LIGHT_1;
    UILight light2 = UI_LIGHT_2;
    UILight light3 = UI_LIGHT_3;
    float3 lightDir1 = light1.direction;
    float3 lightDir2 = light2.direction;
    float3 lightDir3 = light3.direction;

    float4 finalColor    = float4(0, 0, 0, 0);
    float3 emissiveAccum = float3(0, 0, 0);

    // ========================================================================
    // 1. Edge indent
    // ========================================================================
    if (_EdgeEnabled > 0.5) {
        float3 edgeBaseColor = _EdgeColor.rgb;
        if (_EdgeGradientEnabled > 0.5) {
            float4 gc = CalculateGradient(uv, _EdgeGradientColorA, _EdgeGradientColorB,
                _EdgeGradientColorC, _EdgeGradientColorD, _EdgeGradientDirection,
                _EdgeGradientType, _EdgeGradientSpeed, _EdgeGradientScale,
                _EdgeGradientOffset, time, _EdgeGradientColorUsed);
            edgeBaseColor = lerp(edgeBaseColor, gc.rgb, gc.a);
        }
        if (_EdgeGlobalBlend > 0.0) {
            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
            edgeBaseColor = lerp(edgeBaseColor, gc.rgb, _EdgeGlobalBlend * _EdgeGlobalIntensity);
        }
        float indentAlpha = calculateToggleEdgeIndent(uv, pos, _EdgeWidth, _EdgeSoftness,
            bgHalfW, bgHalfH, _BgRounding, _EdgeInset);
        if (indentAlpha > 0.001) {
            float edgeMask = indentAlpha * _EdgeIntensity;
            buttonCompositeOver(finalColor, edgeBaseColor, edgeMask * _EdgeRenderAlpha);
            emissiveAccum += edgeBaseColor * edgeMask * _EdgeRenderEmissive;
        }
    }

    // ========================================================================
    // 2. External shadows
    // ========================================================================
    if (_LightingShadow1Enabled > 0.5) {
        float sa = calculateToggleExternalShadow(uv, lightDir1,
            _LightingShadow1Blur, _LightingShadow1Distance, _LightingShadow1BlurFactor,
            bgHalfW, bgHalfH, _BgRounding, aspectScale);
        if (sa > 0.001)
            buttonCompositeOver(finalColor, _LightingShadow1Color.rgb,
                _LightingShadow1Color.a * sa * _LightingShadow1Intensity);
    }
    if (_LightingShadow2Enabled > 0.5) {
        float sa = calculateToggleExternalShadow(uv, lightDir2,
            _LightingShadow2Blur, _LightingShadow2Distance, _LightingShadow2BlurFactor,
            bgHalfW, bgHalfH, _BgRounding, aspectScale);
        if (sa > 0.001)
            buttonCompositeOver(finalColor, _LightingShadow2Color.rgb,
                _LightingShadow2Color.a * sa * _LightingShadow2Intensity);
    }
    if (_LightingShadow3Enabled > 0.5) {
        float sa = calculateToggleExternalShadow(uv, lightDir3,
            _LightingShadow3Blur, _LightingShadow3Distance, _LightingShadow3BlurFactor,
            bgHalfW, bgHalfH, _BgRounding, aspectScale);
        if (sa > 0.001)
            buttonCompositeOver(finalColor, _LightingShadow3Color.rgb,
                _LightingShadow3Color.a * sa * _LightingShadow3Intensity);
    }

    // ========================================================================
    // 3. Background panel
    // ========================================================================
    if (_BgEnabled > 0.5) {
        float minDimBg = min(bgHalfW, bgHalfH);
        float bgR      = minDimBg * (1.0 - saturate(_BgRounding));
        float bgDist   = RoundedRectSDF(pos, float2(bgHalfW, bgHalfH), bgR);
        float bgAA     = fwidth(bgDist) * 0.75;
        float bgMask   = smoothstep(bgAA, -bgAA, bgDist);

        if (bgMask > 0.001) {
            UIComponent bgComp = CreateUIComponent(
                _BgColor, _BgRenderAlpha,
                _BgBevelDepth, _BgBevelSmoothness, _BgBevelDistance, _BgFaceSmoothness,
                _BgGradientColorA, _BgGradientColorB, _BgGradientColorC, _BgGradientColorD,
                _BgGradientDirection, _BgGradientSpeed, _BgGradientScale, _BgGradientOffset,
                _BgGlobalBlend, _BgGlobalIntensity, _BgGradientType,
                _BgPatternType, _BgPatternScale, _BgPatternIntensity, _BgPatternContrast,
                _BgPatternSpecularEffect, _BgPatternRoughnessEffect, _BgPatternRotateEnabled,
                _BgPatternModEnabled, _BgPatternModAmount, _BgPatternModFrequency, _BgPatternOffset,
                _BgPatternParam1, _BgPatternParam2, _BgPatternParam3,
                _BgGradientEnabled, _BgPatternEnabled,
                _BgPatternColorEnabled, _BgPatternColorMode,
                _BgPatternColorType, _BgPatternColorUsed,
                _BgPatternColorA, _BgPatternColorB, _BgPatternColorC, _BgPatternColorD
            );

            float3 baseColor = bgComp.color.rgb;
            if (bgComp.gradientEnabled > 0.5) {
                float4 gc = CalculateGradient(uv, bgComp.gradientColorA, bgComp.gradientColorB,
                    bgComp.gradientColorC, bgComp.gradientColorD, bgComp.gradientDirection,
                    bgComp.gradientType, bgComp.gradientSpeed, bgComp.gradientScale,
                    bgComp.gradientOffset, time, _BgGradientColorUsed);
                baseColor = lerp(baseColor, gc.rgb, gc.a);
            }
            if (bgComp.globalBlend > 0.0) {
                float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                baseColor = lerp(baseColor, gc.rgb, bgComp.globalBlend * bgComp.globalIntensity);
            }

            float specMod;
            float2 normOff;
            float3 bgPatternColor = ApplyMaterialPattern(baseColor, uvIso, bgComp, 0.0, 0.0, specMod, normOff);

            float effBevelDepth = (_BgBevelEnabled > 0.5) ? bgComp.bevelDepth : 0.0;
            float effBevelDist  = bgComp.bevelDistance;
            if (abs(effBevelDepth) > 0.0001) {
                float ds = sign(effBevelDepth);
                float bh = minDimBg * lerp(0.05, 1.0, abs(effBevelDepth));
                float bd = max(0.0001, effBevelDist);
                float tb = bh / bd;
                effBevelDepth = ds * tb / (1.0 + tb * 0.5);
            }

            float bgFaceInset   = (_BgRimEnabled > 0.5 ? _BgRimWidth : 0.0) + effBevelDist;
            float bgTopFaceDist = bgDist + bgFaceInset;

            float3 bgNormal = CalculateShapeBevelNormal(bgTopFaceDist, effBevelDepth,
                effBevelDist, bgComp.bevelSmoothness, bgComp.fillFaceSmoothness,
                _BgBevelProfileType, _BgBevelProfileSharpness, aspectScale);

            ButtonBevelRenderResult bgBevel = RenderButtonBevelWithPatternAndGradient(
                uv, uvIso, baseColor, bgPatternColor, bgNormal, bgTopFaceDist,
                effBevelDepth, effBevelDist, bgComp.bevelSmoothness, _BgBevelEnabled,
                _BgBevelPatternEnabled, _BgBevelPatternType, _BgBevelPatternScale,
                _BgBevelPatternIntensity, _BgBevelPatternContrast,
                _BgBevelPatternSpecularEffect, _BgBevelPatternRoughnessEffect,
                _BgBevelGradientEnabled, _BgBevelGradientType,
                _BgBevelGradientColorA, _BgBevelGradientColorB,
                _BgBevelGradientColorC, _BgBevelGradientColorD, _BgBevelGradientDirection,
                _BgBevelGradientSpeed, _BgBevelGradientScale, _BgBevelGradientOffset,
                _BgBevelPatternParam1, _BgBevelPatternParam2, _BgBevelPatternParam3,
                _BgBevelGradientColorUsed,
                _BgBevelPatternColorEnabled, _BgBevelPatternColorMode,
                _BgBevelPatternColorType, _BgBevelPatternColorUsed,
                _BgBevelPatternColorA, _BgBevelPatternColorB,
                _BgBevelPatternColorC, _BgBevelPatternColorD,
                time, light1, light2, light3);

            ButtonRimResult bgRim = CalculateButtonRimFromSDF(
                uv, bgBevel.litColor, bgBevel.normal, bgDist,
                _BgRimEnabled, _BgRimDepth, _BgRimWidth, _BgRimSmoothness,
                light1, light2, light3, aspectScale);

            float3 bgLit = ApplyUILighting(bgRim.normal, bgRim.litColor,
                _LightingAmbient, specMod, normOff, light1, light2, light3);

            buttonCompositeOver(finalColor, bgLit, bgMask * bgComp.alpha);
            emissiveAccum += baseColor * bgMask * _BgRenderEmissive;
        }
    }

    // ========================================================================
    // 4. Track (PILL / SLIDE)
    // ========================================================================
    if (_TrackEnabled > 0.5) {
        float trackDist = getToggleTrackSDF(pos, bodyHalfW, bodyHalfH);
        if (trackDist < 1e8) {
            float trackAA   = fwidth(trackDist) * 0.75;
            float trackMask = smoothstep(trackAA, -trackAA, trackDist);

            if (trackMask > 0.001) {
                float3 trackBase = _TrackColor.rgb;
                if (_TrackGradientEnabled > 0.5) {
                    float4 gc = CalculateGradient(uv, _TrackGradientColorA, _TrackGradientColorB,
                        _TrackGradientColorC, _TrackGradientColorD, _TrackGradientDirection,
                        _TrackGradientType, _TrackGradientSpeed, _TrackGradientScale,
                        _TrackGradientOffset, time, _TrackGradientColorUsed);
                    trackBase = lerp(trackBase, gc.rgb, gc.a);
                }
                if (_TrackGlobalBlend > 0.0) {
                    float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                    trackBase = lerp(trackBase, gc.rgb, _TrackGlobalBlend * _TrackGlobalIntensity);
                }

                float trackMinDim        = min(bodyHalfW, bodyHalfH);
                float trackEffBevelDepth = (_TrackBevelEnabled > 0.5) ? _TrackBevelDepth : 0.0;
                float trackEffBevelDist  = _TrackBevelDistance;
                float trackFaceInset     = trackEffBevelDist;
                float trackTopFaceDist   = trackDist + trackFaceInset;

                if (abs(trackEffBevelDepth) > 0.0001) {
                    float ds = sign(trackEffBevelDepth);
                    float bh = trackMinDim * lerp(0.05, 1.0, abs(trackEffBevelDepth));
                    float bd = max(0.0001, trackEffBevelDist);
                    float tb = bh / bd;
                    trackEffBevelDepth = ds * tb / (1.0 + tb * 0.5);
                }

                float3 trackNormal = CalculateShapeBevelNormal(trackTopFaceDist,
                    trackEffBevelDepth, trackEffBevelDist, _TrackBevelSmoothness, _TrackFaceSmoothness,
                    _TrackBevelProfileType, _TrackBevelProfileSharpness, aspectScale);

                UIComponent trackComp = CreateUIComponent(
                    _TrackColor, _TrackRenderAlpha,
                    _TrackBevelDepth, _TrackBevelSmoothness, _TrackBevelDistance, _TrackFaceSmoothness,
                    _TrackGradientColorA, _TrackGradientColorB, _TrackGradientColorC, _TrackGradientColorD,
                    _TrackGradientDirection, _TrackGradientSpeed, _TrackGradientScale, _TrackGradientOffset,
                    0.0, 1.0, _TrackGradientType,
                    _TrackPatternType, _TrackPatternScale, _TrackPatternIntensity, _TrackPatternContrast,
                    _TrackPatternSpecularEffect, _TrackPatternRoughnessEffect, 0.0,
                    0.0, 0.0, 0.0, 0.0,
                    _TrackPatternParam1, _TrackPatternParam2, _TrackPatternParam3,
                    _TrackGradientEnabled, _TrackPatternEnabled,
                    _TrackPatternColorEnabled, _TrackPatternColorMode,
                    _TrackPatternColorType, _TrackPatternColorUsed,
                    _TrackPatternColorA, _TrackPatternColorB, _TrackPatternColorC, _TrackPatternColorD
                );
                float trackSpecMod;
                float2 trackNormOff;
                float3 trackPatColor = ApplyMaterialPattern(trackBase, uvIso, trackComp,
                    0.0, 0.0, trackSpecMod, trackNormOff);

                float3 trackLit = ApplyUILighting(trackNormal, trackPatColor,
                    _LightingAmbient, trackSpecMod, trackNormOff, light1, light2, light3);

                buttonCompositeOver(finalColor, trackLit, trackMask * _TrackRenderAlpha);
                emissiveAccum += trackBase * trackMask * _TrackRenderEmissive;
            }
        }
    }

    // ========================================================================
    // 5. Toggle body shadows
    // ========================================================================
    if (_ToggleShadow1Enabled > 0.5) {
        float sa = calculateToggleBodyShadow(uv, lightDir1,
            _ToggleShadow1Blur, _ToggleShadow1Distance, _ToggleShadow1BlurFactor, _ToggleShadow1Cast,
            bodyHalfW, bodyHalfH, faceInset, pseudoHeight, aspectScale);
        if (sa > 0.001)
            buttonCompositeOver(finalColor, _ToggleShadow1Color.rgb,
                _ToggleShadow1Color.a * sa * _ToggleShadow1Intensity);
    }
    if (_ToggleShadow2Enabled > 0.5) {
        float sa = calculateToggleBodyShadow(uv, lightDir2,
            _ToggleShadow2Blur, _ToggleShadow2Distance, _ToggleShadow2BlurFactor, _ToggleShadow2Cast,
            bodyHalfW, bodyHalfH, faceInset, pseudoHeight, aspectScale);
        if (sa > 0.001)
            buttonCompositeOver(finalColor, _ToggleShadow2Color.rgb,
                _ToggleShadow2Color.a * sa * _ToggleShadow2Intensity);
    }
    if (_ToggleShadow3Enabled > 0.5) {
        float sa = calculateToggleBodyShadow(uv, lightDir3,
            _ToggleShadow3Blur, _ToggleShadow3Distance, _ToggleShadow3BlurFactor, _ToggleShadow3Cast,
            bodyHalfW, bodyHalfH, faceInset, pseudoHeight, aspectScale);
        if (sa > 0.001)
            buttonCompositeOver(finalColor, _ToggleShadow3Color.rgb,
                _ToggleShadow3Color.a * sa * _ToggleShadow3Intensity);
    }

    // ========================================================================
    // 6. LED bloom (halo rendered before toggle body)
    // ========================================================================
    float toggleBodyDist = 1e9;
    if (_ToggleEnabled > 0.5) {
        toggleBodyDist = getToggleBodySDF(pos, bodyHalfW, bodyHalfH);
    }
    if (_LedEnabled > 0.5 && _LedIntensity > 0.001) {
        float bloom = calculateLedBloom(toggleBodyDist, _LedGlowRadius,
            _LedGlowSharpness, _LedIntensity);
        if (bloom > 0.001) {
            buttonCompositeOver(finalColor, _LedColor.rgb, bloom * _LedColor.a);
            emissiveAccum += _LedColor.rgb * bloom * _LedRenderEmissive;
        }
    }

    // ========================================================================
    // 7. Toggle body
    // ========================================================================
    if (_ToggleEnabled > 0.5) {
        float bodyDist = toggleBodyDist;
        float bodyAA   = fwidth(bodyDist) * 0.75;
        float bodyMask = smoothstep(bodyAA, -bodyAA, bodyDist);

        float topFaceDist = bodyDist + faceInset;

        if (bodyMask > 0.001) {
            UIComponent bodyComp = CreateUIComponent(
                _ToggleColor, _ToggleRenderAlpha,
                _ToggleBevelDepth, _ToggleBevelSmoothness, _ToggleBevelDistance, _ToggleFaceSmoothness,
                _ToggleGradientColorA, _ToggleGradientColorB, _ToggleGradientColorC, _ToggleGradientColorD,
                _ToggleGradientDirection, _ToggleGradientSpeed, _ToggleGradientScale, _ToggleGradientOffset,
                _ToggleGlobalBlend, _ToggleGlobalIntensity, _ToggleGradientType,
                _TogglePatternType, _TogglePatternScale, _TogglePatternIntensity, _TogglePatternContrast,
                _TogglePatternSpecularEffect, _TogglePatternRoughnessEffect, _TogglePatternRotateEnabled,
                _TogglePatternModEnabled, _TogglePatternModAmount, _TogglePatternModFrequency, _TogglePatternOffset,
                _TogglePatternParam1, _TogglePatternParam2, _TogglePatternParam3,
                _ToggleGradientEnabled, _TogglePatternEnabled,
                _TogglePatternColorEnabled, _TogglePatternColorMode,
                _TogglePatternColorType, _TogglePatternColorUsed,
                _TogglePatternColorA, _TogglePatternColorB, _TogglePatternColorC, _TogglePatternColorD
            );

            float3 baseColor = bodyComp.color.rgb;
            if (_LedEnabled > 0.5 && _LedSurfaceBlend > 0.001)
                baseColor = lerp(baseColor, _LedColor.rgb, _LedSurfaceBlend * _Value);

            if (bodyComp.gradientEnabled > 0.5) {
                float4 gc = CalculateGradient(uv, bodyComp.gradientColorA, bodyComp.gradientColorB,
                    bodyComp.gradientColorC, bodyComp.gradientColorD, bodyComp.gradientDirection,
                    bodyComp.gradientType, bodyComp.gradientSpeed, bodyComp.gradientScale,
                    bodyComp.gradientOffset, time, _ToggleGradientColorUsed);
                baseColor = lerp(baseColor, gc.rgb, gc.a);
            }
            if (bodyComp.globalBlend > 0.0) {
                float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
                baseColor = lerp(baseColor, gc.rgb, bodyComp.globalBlend * bodyComp.globalIntensity);
            }

            float specMod;
            float2 normOff;
            float3 patternedColor = ApplyMaterialPattern(baseColor, uvIso, bodyComp,
                0.0, 0.0, specMod, normOff);

            float effBevelDepth = (_ToggleBevelEnabled > 0.5) ? bodyComp.bevelDepth : 0.0;
            float effBevelDist  = bodyComp.bevelDistance;
            if (abs(effBevelDepth) > 0.0001) {
                float ds = sign(effBevelDepth);
                float bh = maxDim * lerp(0.05, 1.0, abs(effBevelDepth));
                float bd = max(0.0001, effBevelDist);
                float tb = bh / bd;
                effBevelDepth = ds * tb / (1.0 + tb * 0.5);
            }

            float3 bodyNormal = CalculateShapeBevelNormal(topFaceDist, effBevelDepth,
                effBevelDist, bodyComp.bevelSmoothness, bodyComp.fillFaceSmoothness,
                _ToggleBevelProfileType, _ToggleBevelProfileSharpness, aspectScale);

            ButtonBevelRenderResult bevelResult = RenderButtonBevelWithPatternAndGradient(
                uv, uvIso, baseColor, patternedColor, bodyNormal, topFaceDist,
                effBevelDepth, effBevelDist, bodyComp.bevelSmoothness, _ToggleBevelEnabled,
                _ToggleBevelPatternEnabled, _ToggleBevelPatternType, _ToggleBevelPatternScale,
                _ToggleBevelPatternIntensity, _ToggleBevelPatternContrast,
                _ToggleBevelPatternSpecularEffect, _ToggleBevelPatternRoughnessEffect,
                _ToggleBevelGradientEnabled, _ToggleBevelGradientType,
                _ToggleBevelGradientColorA, _ToggleBevelGradientColorB,
                _ToggleBevelGradientColorC, _ToggleBevelGradientColorD, _ToggleBevelGradientDirection,
                _ToggleBevelGradientSpeed, _ToggleBevelGradientScale, _ToggleBevelGradientOffset,
                _ToggleBevelPatternParam1, _ToggleBevelPatternParam2, _ToggleBevelPatternParam3,
                _ToggleBevelGradientColorUsed,
                _ToggleBevelPatternColorEnabled, _ToggleBevelPatternColorMode,
                _ToggleBevelPatternColorType, _ToggleBevelPatternColorUsed,
                _ToggleBevelPatternColorA, _ToggleBevelPatternColorB,
                _ToggleBevelPatternColorC, _ToggleBevelPatternColorD,
                time, light1, light2, light3);

            ButtonRimResult rimResult = CalculateButtonRimFromSDF(
                uv, bevelResult.litColor, bevelResult.normal, bodyDist,
                _ToggleRimEnabled, _ToggleRimDepth, _ToggleRimWidth, _ToggleRimSmoothness,
                light1, light2, light3, aspectScale);

            float3 litColor = ApplyUILighting(rimResult.normal, rimResult.litColor,
                _LightingAmbient, specMod, normOff, light1, light2, light3);

            buttonCompositeOver(finalColor, litColor, bodyMask * bodyComp.alpha);
            emissiveAccum += baseColor * bodyMask * _ToggleRenderEmissive;
        }

        // ====================================================================
        // 8. Toggle face
        // ====================================================================
        if (_ToggleFaceEnabled > 0.5 && faceInset > 0.001) {
            float faceMargin = (1.0 - saturate(_ToggleFaceSize)) * maxDim;
            float faceHalfW  = max(0.001, bodyHalfW - faceMargin);
            float faceHalfH  = max(0.001, bodyHalfH - faceMargin);

            float faceDist = getToggleBodySDF(pos, faceHalfW, faceHalfH);
            faceDist = max(faceDist, -toggleBodyDist - 0.001);

            float faceAA   = fwidth(faceDist) * 0.75;
            float faceMask = smoothstep(faceAA, -faceAA, faceDist);
            faceMask *= (toggleBodyDist < 0.001) ? 1.0 : 0.0;

            if (faceMask > 0.001) {
                float3 faceColor = _ToggleFaceColor.rgb;
                if (_LedEnabled > 0.5 && _LedSurfaceBlend > 0.001)
                    faceColor = lerp(faceColor, _LedColor.rgb, _LedSurfaceBlend * _Value);
                if (_ToggleFaceGradientEnabled > 0.5) {
                    float4 gc = CalculateGradient(uv, _ToggleFaceGradientColorA, _ToggleFaceGradientColorB,
                        _ToggleFaceGradientColorC, _ToggleFaceGradientColorD, _ToggleFaceGradientDirection,
                        _ToggleFaceGradientType, _ToggleFaceGradientSpeed, _ToggleFaceGradientScale,
                        _ToggleFaceGradientOffset, time, _ToggleFaceGradientColorUsed);
                    faceColor = lerp(faceColor, gc.rgb, gc.a);
                }
                buttonCompositeOver(finalColor, faceColor, faceMask * _ToggleFaceRenderAlpha);
                emissiveAccum += faceColor * faceMask * _ToggleFaceRenderEmissive;
            }
        }

        // ====================================================================
        // 9. Type-specific extras
        // ====================================================================
        // Per-type shaders define TOGGLE_TYPE_EXTRAS in their Defs.cginc.
        // Old shaders (Bat, Push, Rocker, Rotary) define it via #define macros.
        // New shaders with no extras (Pill, Radio) simply don't define it.
        #ifdef TOGGLE_TYPE_EXTRAS
        TOGGLE_TYPE_EXTRAS
        #endif
    } // end _ToggleEnabled

    // ========================================================================
    // 10. Border
    // ========================================================================
    if (_BorderEnabled > 0.5) {
        float3 borderBase = _BorderColor.rgb;
        if (_BorderGradientEnabled > 0.5) {
            float4 gc = CalculateGradient(uv, _BorderGradientColorA, _BorderGradientColorB,
                _BorderGradientColorC, _BorderGradientColorD, _BorderGradientDirection,
                _BorderGradientType, _BorderGradientSpeed, _BorderGradientScale,
                _BorderGradientOffset, time, _BorderGradientColorUsed);
            borderBase = lerp(borderBase, gc.rgb, gc.a);
        }
        if (_BorderGlobalBlend > 0.0) {
            float4 gc = CalculateGlobalGradient(IN.worldPosition.xy, time);
            borderBase = lerp(borderBase, gc.rgb, _BorderGlobalBlend * _BorderGlobalIntensity);
        }
        float borderTerritory;
        float4 borderResult = calculateToggleBorder(uv, borderBase, _BorderWidth, _BorderSoftness,
            bgHalfW, bgHalfH, _BgRounding, aspectScale, borderTerritory);
        float borderMask = borderResult.a * _BorderIntensity;

        float borderPresence     = max(_BorderRenderAlpha, _BorderRenderEmissive);
        float effectiveTerritory = borderTerritory * borderPresence;
        if (effectiveTerritory > 0.001) {
            float clearFactor = 1.0 - effectiveTerritory;
            finalColor.rgb  *= clearFactor;
            finalColor.a    *= clearFactor;
            emissiveAccum   *= clearFactor;
        }
        if (borderMask > 0.001) {
            buttonCompositeOver(finalColor, borderResult.rgb, borderMask * _BorderRenderAlpha);
            emissiveAccum += borderResult.rgb * borderMask * _BorderRenderEmissive;
        }
    }

    // Unity UI clip rect
    #ifdef UNITY_UI_CLIP_RECT
    float clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
    finalColor    *= clipMask;
    emissiveAccum *= clipMask;
    #endif

    // Vertex color tint
    finalColor    *= IN.color;
    emissiveAccum *= IN.color.rgb;

    // Premultiplied alpha output with additive emissive
    finalColor.rgb = finalColor.rgb + emissiveAccum;

    // Receive shadows from knobs/buttons/sliders. Toggles draw their OWN shadows inline (no
    // _ShadowPassMode, no shadow quad), so nothing of this toggle is in the buffer.
    if (finalColor.a > 0.001 && _ReceiveSceneShadows > 0.5) {
        float2 shadowUV = IN.screenPos.xy / IN.screenPos.w;
        finalColor.rgb *= sampleUIShadowBuffer(shadowUV);
    }
    return finalColor;
}

#endif // SDFTOGGLE_RENDER_CORE_INCLUDED
