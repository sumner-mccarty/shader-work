# Legacy Shader Reference Documentation

**Created:** February 18, 2026  
**Status:** ARCHIVED - DO NOT USE IN PRODUCTION  
**Migration Target:** SDFKnob.shader

## Overview

This folder contains legacy shader implementations that have been deprecated in favor of the new pure function library architecture. These files are preserved for reference purposes only.

## Deprecated Shaders

### 1. Knob.shader.backup
**Original Path:** `Assets/Shaders/Knob.shader`  
**Shader Name:** `UI/Knob`  
**Line Count:** ~1,056 lines  
**Status:** Fully deprecated

**Features:**
- Multi-component knob UI control
- Fill, Line, Outline, Value areas (filled/unfilled), Nub components
- Gradient system for each component
- 3D lighting effects with beveling
- Additive glow pass
- Angular range control with end caps
- Rotation system for nub positioning

**Issues:**
- Referenced global properties from UILighting.cginc (_LightDirection, _LightIntensity, etc.)
- Used deprecated lighting functions (calculateLighting, apply3DLighting, applyVisualBevel)
- Required _BevelSmoothness property from UILighting.cginc
- Tight coupling between shader and include files

**Related Materials:**
- `Reference/Knob.mat` - Material instance using deprecated shader

---

### 2. SDFButton.shader.backup
**Original Path:** `Assets/Shaders/SDFButton.shader`  
**Shader Name:** `UI/SDFButton`  
**Line Count:** ~792 lines  
**Status:** Fully deprecated

**Features:**
- SDF-based button rendering
- Fill and Line gradient components
- Global gradient effects
- Material pattern system
- 3D lighting integration

**Issues:**
- Used old lighting architecture with global properties
- Called ApplyUILighting() without ambientIntensity parameter
- Referenced removed calculateLighting() function
- Required UILighting.cginc global state

**Related Materials:**
- `Reference/SDFButton.mat` - Material instance using deprecated shader

---

### 3. NeomorphicSDF.shader
**Original Path:** `Assets/Shaders/NeomorphicSDF.shader`  
**Shader Name:** `NeomorphicSDF`  
**Line Count:** ~138 lines  
**Status:** Fully deprecated

**Features:**
- Neomorphic design aesthetic (soft UI)
- Rounded rectangle SDF rendering
- Bevel lighting for depth
- Noise texture integration
- Billowing effect for plastic appearance

**Issues:**
- Used global lighting properties
- Required migration to explicit parameter passing
- Legacy lighting function calls

**Related Materials:**
- `Reference/NeomorphicSDF.mat` - Material instance using deprecated shader (if exists)

---

## Architecture Problems

All three legacy shaders violated the **Pure Function Library** architecture by:

1. **Direct Property Access:** Referenced global shader properties declared in .cginc files
2. **Hidden Dependencies:** Functions in UILighting.cginc expected specific properties to exist
3. **Tight Coupling:** Shaders couldn't be modified independently from include files
4. **Global State:** Properties like `_BevelSmoothness`, `_LightIntensity` created hidden coupling

### Problematic Pattern (OLD):
```hlsl
// UILighting.cginc (BAD)
float _BevelSmoothness;  // Global property declaration

float3 calculateButtonNormal(...) {
    float power = lerp(20.0, 0.5, _BevelSmoothness);  // Direct reference
    // ...
}

// Knob.shader (BAD)
// Just calls function, doesn't know about _BevelSmoothness dependency
float3 normal = calculateButtonNormal(uv, size, ...);
```

### Modern Pattern (NEW):
```hlsl
// UILighting.cginc (GOOD)
// No property declarations, only function signatures

float3 ApplyUILighting(float3 normal, float3 baseColor, float ambientIntensity, ...) {
    // All parameters explicit
}

// SDFKnob.shader (GOOD)
float _LightingAmbient;  // Declared in shader CGPROGRAM section

// Explicitly pass all parameters
float3 litColor = ApplyUILighting(normal, color, _LightingAmbient, ...);
```

---

## Migration Guide

### Step 1: Use SDFKnob.shader as Template
`Assets/Shaders/SDFKnob.shader` is the reference implementation. Study its structure:
- Properties declared in CGPROGRAM section
- Explicit parameter passing to all lighting functions
- No global dependencies except UIGlobalUniforms.cginc (intentional)

### Step 2: Declare Properties Locally
```hlsl
CGPROGRAM
// Lighting properties now declared HERE, not in .cginc files
float _LightingAmbient;
// ... other properties

// Architecture documentation
// REQUIRED: Declare _LightingAmbient here and pass to ApplyUILighting():
//   ApplyUILighting(normal, color, _LightingAmbient, specularMod, ...)
```

### Step 3: Update Function Calls
Replace all deprecated function calls:

**OLD:**
```hlsl
float3 litColor = apply3DLighting(baseColor, normal);  // Missing parameters!
```

**NEW:**
```hlsl
float3 litColor = ApplyUILighting(normal, baseColor, _LightingAmbient, 
                                   specularMod, normalOffset, light1, light2, light3);
```

### Step 4: Remove Legacy Function Usage
These functions are commented out in UILighting.cginc:
- ❌ `calculateLighting()` - Use `ApplyUILighting()` instead
- ❌ `apply3DLighting()` - Use `ApplyUILighting()` instead  
- ❌ `applyVisualBevel()` - Pass bevel parameters explicitly
- ❌ `calculateButtonNormal()` - Requires _BevelSmoothness parameter
- ❌ `getBeveledSDF()` - Requires _BevelSmoothness parameter
- ❌ `calculateFillNormal()` - Wrapper for calculateButtonNormal()

### Step 5: Test Compilation
1. Ensure no compilation errors
2. Check that lighting renders correctly
3. Verify gradients and patterns work as expected

---

## Pure Function Library Principles

### ✅ GOOD: Pure Function Libraries
Files that should contain ONLY functions, structs, and constants:
- `CG/Core/Constants.cginc`
- `CG/Core/UIMath.cginc`
- `CG/Core/UIComponents.cginc`
- `CG/Core/UIPatterns.cginc`
- `CG/Core/UIGradients.cginc`
- `CG/Core/UIRenderer.cginc`
- `CG/Core/UIEffects.cginc`
- `CG/Core/UILighting.cginc` ⚠️ Now clean
- `CG/SDF/*.cginc`

### ⚠️ EXCEPTION: Intentional Global State
**UIGlobalUniforms.cginc** - Contains intentional global uniforms for screen effects:
- `_GlobalGradient*` - Screen-space global gradient system
- These are purposefully global as they affect all UI elements uniformly

### ❌ BAD: Property Declarations in .cginc Files
```hlsl
// DON'T DO THIS
// MyLighting.cginc
float _LightIntensity;  // ❌ Creates hidden dependency
float3 _LightDirection;  // ❌ Other shaders might not declare this
```

### ✅ GOOD: Explicit Parameters
```hlsl
// DO THIS
// MyLighting.cginc
float3 CalculateLighting(float3 normal, float3 baseColor, 
                         float lightIntensity, float3 lightDirection) {
    // All dependencies explicit in function signature
}
```

---

## Files in this Folder

```
Reference/
├── LEGACY_SHADERS.md          (this file)
├── Knob.shader.backup          (~1,056 lines)
├── SDFButton.shader.backup     (~792 lines)
├── Neomorphic SDF.shader       (~138 lines)
├── Knob.mat                    (Material using Knob.shader)
├── SDFButton.mat               (Material using SDFButton.shader)
└── NeomorphicSDF.mat           (Material using NeomorphicSDF.shader, if exists)
```

---

## Placeholder Shaders (Active)

The following placeholder shaders now exist in the main Shaders folder to prevent compilation errors:

### Knob.shader
- **Shader Name:** `Hidden/DeprecatedKnob`
- **Behavior:** Renders magenta to indicate deprecated shader
- **Purpose:** Prevents "shader not found" errors in existing materials

### SDFButton.shader  
- **Shader Name:** `Hidden/DeprecatedSDFButton`
- **Behavior:** Renders magenta to indicate deprecated shader
- **Purpose:** Prevents "shader not found" errors in existing materials

### NeomorphicSDF.shader
- **Shader Name:** `Hidden/DeprecatedNeomorphicSDF`
- **Behavior:** Renders magenta to indicate deprecated shader
- **Purpose:** Prevents "shader not found" errors in existing materials

**⚠️ If you see magenta rendering:** Your material is using a deprecated shader. Update it to use SDFKnob.shader or create a new shader following the modern architecture.

---

## Future Development

### Building New Shaders
When creating SDFButton, SDFSlider, SDFToggle, or SDFPanel shaders:

1. **Copy SDFKnob.shader** as starting point
2. **Keep the architecture documentation** at the top
3. **Declare all properties** in the CGPROGRAM section
4. **Pass all parameters explicitly** to .cginc functions
5. **Reference this document** for migration patterns

### Architecture Validation
Before committing new shaders, verify:
- ✅ No property declarations in .cginc files (except UIGlobalUniforms.cginc)
- ✅ All lighting functions receive explicit parameters
- ✅ No hidden dependencies between shader and includes
- ✅ Architecture documentation included in shader header
- ✅ Test compilation succeeds

---

## Questions for Future LLM Conversations

### "I need to create a new UI shader"
1. Use `Assets/Shaders/SDFKnob.shader` as your template
2. Read the architecture documentation in its header (lines 38-52)
3. Follow the pure function library pattern documented in this file

### "Why don't my materials render correctly?"
1. Check if the material is using a deprecated shader (renders magenta)
2. Look for `Hidden/Deprecated*` in the material's shader field
3. Switch to SDFKnob.shader or create a new shader following modern architecture

### "How do I migrate old Knob.shader functionality?"
1. Reference `Reference/Knob.shader.backup` for the original implementation
2. Copy relevant features to a new shader based on SDFKnob.shader
3. Update all lighting function calls to pass explicit parameters
4. Declare properties locally in CGPROGRAM section

### "What happened to calculateLighting()?"
- It's been removed/commented out in UILighting.cginc
- Use `ApplyUILighting()` instead with explicit parameters
- See "Migration Guide" section above for examples

---

## Contact

For questions about shader migration or architecture:
- See: `Assets/Shaders/SDFKnob.shader` (reference implementation)
- Check: `Assets/Shaders/CG/Core/UILighting.cginc` (pure function library)
- Read: Architecture principles section above

**Last Updated:** February 18, 2026  
**Maintainer:** Architecture Refactor (Shader Pure Function Library Initiative)
