#ifndef UI_COMPONENTS_INCLUDED
#define UI_COMPONENTS_INCLUDED

#include "Constants.cginc"
#include "UIMath.cginc"

// Component structure for all UI elements
struct UIComponent {
    // Base color and alpha
    float4 color;
    float alpha;
    
    // Bevel properties
    float bevelDepth;
    float bevelSmoothness;
    float bevelDistance;
    float fillFaceSmoothness; // 0=flat, positive=outward, negative=inward like divot
    
    // Gradient properties
    float gradientEnabled;  // NEW: Explicit enable flag (replaces gradientType == GRADIENT_NONE check)
    float4 gradientColorA;
    float4 gradientColorB; 
    float4 gradientColorC;
    float4 gradientColorD;
    float2 gradientDirection;
    float gradientSpeed;
    float gradientScale;
    float gradientOffset;
    float globalBlend;
    float globalIntensity;
    int gradientType;
    int gradientNumColors; // number of active color stops: 2, 3, or 4
    
    // Pattern properties
    float patternEnabled;   // NEW: Explicit enable flag (replaces patternType == PATTERN_NONE check)
    float patternType;
    float patternScale;
    float patternIntensity;
    float patternContrast;
    float patternSpecularEffect;
    float patternRoughnessEffect;
    float patternRotateWithValue;
    float patternModWithValue;
    float patternModAmount;
    float patternModFrequency;
    float patternOffset;
    float patternParam1;
    float patternParam2;
    float patternParam3;

    // Pattern color properties
    float patternColorEnabled;       // 0 = off (existing brightness modulation unchanged)
    int   patternColorMode;          // 0=modulate, 1=lerp, 2=additive, 3=multiply
    int   patternColorType;          // PATTERN_COLORTYPE_GRADIENT..BANDS
    int   patternColorUsed;          // 2-4 active palette slots
    float4 patternColorA;
    float4 patternColorB;
    float4 patternColorC;
    float4 patternColorD;
};

// Builder struct for UIComponent - makes it easy to create components with defaults
struct UIComponentParams {
    // Base properties (required)
    float4 color;
    float alpha;
    
    // Bevel properties
    float bevelDepth;
    float bevelSmoothness;
    float bevelDistance;
    float fillFaceSmoothness;
    
    // Gradient properties
    float4 gradientColorA;
    float4 gradientColorB;
    float4 gradientColorC;
    float4 gradientColorD;
    float2 gradientDirection;
    float gradientSpeed;
    float gradientScale;
    float gradientOffset;
    float globalBlend;
    float globalIntensity;
    int gradientType;
    int gradientNumColors; // number of active color stops: 2, 3, or 4
    
    // Pattern properties
    float patternType;
    float patternScale;
    float patternIntensity;
    float patternContrast;
    float patternSpecularEffect;
    float patternRoughnessEffect;
    float patternRotateWithValue;
    float patternModWithValue;
    float patternModAmount;
    float patternModFrequency;
    float patternOffset;
    float patternParam1;
    float patternParam2;
    float patternParam3;

    // Pattern color properties
    float patternColorEnabled;
    int   patternColorMode;
    int   patternColorType;
    int   patternColorUsed;
    float4 patternColorA;
    float4 patternColorB;
    float4 patternColorC;
    float4 patternColorD;
};

// Initialize UIComponentParams with sensible defaults
UIComponentParams InitUIComponentParams() {
    UIComponentParams params;
    
    // Base defaults
    params.color = float4(1, 1, 1, 1);
    params.alpha = 1.0;
    
    // Bevel defaults
    params.bevelDepth = 0.0;
    params.bevelSmoothness = 0.0;
    params.bevelDistance = 0.0;
    params.fillFaceSmoothness = 0.0;
    
    // Gradient defaults
    params.gradientColorA = float4(0, 0, 0, 0);
    params.gradientColorB = float4(0, 0, 0, 0);
    params.gradientColorC = float4(0, 0, 0, 0);
    params.gradientColorD = float4(0, 0, 0, 0);
    params.gradientDirection = float2(1, 0);
    params.gradientSpeed = 0.0;
    params.gradientScale = 1.0;
    params.gradientOffset = 0.0;
    params.globalBlend = 0.0;
    params.globalIntensity = 1.0;
    params.gradientType = 0;
    params.gradientNumColors = 4;
    
    // Pattern defaults
    params.patternType = 0.0;
    params.patternScale = 1.0;
    params.patternIntensity = 0.5;
    params.patternContrast = 1.0;
    params.patternSpecularEffect = 0.0;
    params.patternRoughnessEffect = 0.0;
    params.patternRotateWithValue = 0.0;
    params.patternModWithValue = 0.0;
    params.patternModAmount = 20.0;
    params.patternModFrequency = 1.0;
    params.patternOffset = 0.0;
    params.patternParam1 = 0.5;
    params.patternParam2 = 0.5;
    params.patternParam3 = 0.5;

    // Pattern color defaults (disabled — preserves existing brightness modulation output)
    params.patternColorEnabled    = 0.0;
    params.patternColorMode      = 1;          // PATTERN_COLORTYPE_FEATURE (Lerp default)
    params.patternColorType      = 2;          // PATTERN_COLORTYPE_ZONES
    params.patternColorUsed      = 2;
    params.patternColorA = float4(1,   1,   1,   1);
    params.patternColorB = float4(0.5, 0.5, 0.5, 1);
    params.patternColorC = float4(0.3, 0.3, 0.3, 1);
    params.patternColorD = float4(0.1, 0.1, 0.1, 1);

    return params;
}

// Create UIComponent from params struct
UIComponent CreateUIComponentFromParams(UIComponentParams params) {
    UIComponent comp;
    comp.color = params.color;
    comp.alpha = params.alpha;
    comp.bevelDepth = params.bevelDepth;
    comp.bevelSmoothness = params.bevelSmoothness;
    comp.bevelDistance = params.bevelDistance;
    comp.fillFaceSmoothness = params.fillFaceSmoothness;
    comp.gradientColorA = params.gradientColorA;
    comp.gradientColorB = params.gradientColorB;
    comp.gradientColorC = params.gradientColorC;
    comp.gradientColorD = params.gradientColorD;
    comp.gradientDirection = params.gradientDirection;
    comp.gradientSpeed = params.gradientSpeed;
    comp.gradientScale = params.gradientScale;
    comp.gradientOffset = params.gradientOffset;
    comp.globalBlend = params.globalBlend;
    comp.globalIntensity = params.globalIntensity;
    comp.gradientType = params.gradientType;
    comp.gradientNumColors = params.gradientNumColors;
    comp.patternType = params.patternType;
    comp.patternScale = params.patternScale;
    comp.patternIntensity = params.patternIntensity;
    comp.patternContrast = params.patternContrast;
    comp.patternSpecularEffect = params.patternSpecularEffect;
    comp.patternRoughnessEffect = params.patternRoughnessEffect;
    comp.patternRotateWithValue = params.patternRotateWithValue;
    comp.patternModWithValue = params.patternModWithValue;
    comp.patternModAmount = params.patternModAmount;
    comp.patternModFrequency = params.patternModFrequency;
    comp.patternOffset = params.patternOffset;
    comp.patternParam1 = params.patternParam1;
    comp.patternParam2 = params.patternParam2;
    comp.patternParam3 = params.patternParam3;
    comp.patternColorEnabled   = params.patternColorEnabled;
    comp.patternColorMode  = params.patternColorMode;
    comp.patternColorType  = params.patternColorType;
    comp.patternColorUsed  = params.patternColorUsed;
    comp.patternColorA = params.patternColorA;
    comp.patternColorB = params.patternColorB;
    comp.patternColorC = params.patternColorC;
    comp.patternColorD = params.patternColorD;
    return comp;
}

// Legacy helper function - kept for backward compatibility
// Prefer using InitUIComponentParams() + CreateUIComponentFromParams() for new code
UIComponent CreateUIComponent(
    float4 color, float alpha,
    float bevelDepth, float bevelSmoothness, float bevelDistance, float fillFaceSmoothness,
    float4 gradColorA, float4 gradColorB, float4 gradColorC, float4 gradColorD,
    float2 gradDirection, float gradSpeed, float gradScale, float gradOffset,
    float globalBlend, float globalIntensity, int gradType,
    float patternType, float patternScale, float patternIntensity, float patternContrast,
    float patternSpecular, float patternRoughness, float patternRotate,
    float patternMod, float patternModAmt, float patternModFreq, float patternOff,
    float patternP1, float patternP2, float patternP3,
    float gradientEnabled, float patternEnabled,  // Enable flags
    // Pattern color properties
    float patternColorEnabled, int patternColorMode, int patternColorType, int patternColorUsed,
    float4 patternColorA, float4 patternColorB, float4 patternColorC, float4 patternColorD
) {
    UIComponent comp;
    comp.color = color;
    comp.alpha = alpha;
    comp.bevelDepth = bevelDepth;
    comp.bevelSmoothness = bevelSmoothness;
    comp.bevelDistance = bevelDistance;
    comp.fillFaceSmoothness = fillFaceSmoothness;
    comp.gradientEnabled = gradientEnabled;  // NEW
    comp.gradientColorA = gradColorA;
    comp.gradientColorB = gradColorB;
    comp.gradientColorC = gradColorC;
    comp.gradientColorD = gradColorD;
    comp.gradientDirection = gradDirection;
    comp.gradientSpeed = gradSpeed;
    comp.gradientScale = gradScale;
    comp.gradientOffset = gradOffset;
    comp.globalBlend = globalBlend;
    comp.globalIntensity = globalIntensity;
    comp.gradientType = gradType;
    comp.gradientNumColors = 4; // legacy helper defaults to 4 color stops
    comp.patternEnabled = patternEnabled;  // NEW
    comp.patternType = patternType;
    comp.patternScale = patternScale;
    comp.patternIntensity = patternIntensity;
    comp.patternContrast = patternContrast;
    comp.patternSpecularEffect = patternSpecular;
    comp.patternRoughnessEffect = patternRoughness;
    comp.patternRotateWithValue = patternRotate;
    comp.patternModWithValue = patternMod;
    comp.patternModAmount = patternModAmt;
    comp.patternModFrequency = patternModFreq;
    comp.patternOffset = patternOff;
    comp.patternParam1 = patternP1;
    comp.patternParam2 = patternP2;
    comp.patternParam3 = patternP3;
    comp.patternColorEnabled   = patternColorEnabled;
    comp.patternColorMode  = patternColorMode;
    comp.patternColorType  = patternColorType;
    comp.patternColorUsed  = patternColorUsed;
    comp.patternColorA = patternColorA;
    comp.patternColorB = patternColorB;
    comp.patternColorC = patternColorC;
    comp.patternColorD = patternColorD;
    return comp;
}

#endif