# 3D Lighting and Beveling Effects for SDFButton and Knob Shaders

This document explains the new 3D lighting and beveling effects that have been incorporated into the SDFButton and Knob shaders, inspired by the advanced lighting techniques from your shader code.

## Overview

The enhanced shaders now include:
- **3D Normal Calculation**: Dynamic normal vectors based on shape geometry
- **Lambert Diffuse Lighting**: Realistic diffuse reflection
- **Blinn-Phong Specular Lighting**: Realistic specular highlights
- **Ambient Lighting**: Base illumination level
- **Beveling Effects**: Depth-based normal modification for enhanced 3D appearance
- **Configurable Light Properties**: Full control over lighting parameters

## New Properties

### Light Direction
- `_LightDirection`: Vector3 controlling the direction of the light source
- Default: `(-0.2, 0.2, 1.0)` - Top-right-front lighting

### Light Intensity
- `_LightIntensity`: Controls the overall brightness of the light
- Range: `0.0` to `2.0`
- Default: `1.0`

### Light Color
- `_LightColor`: Color of the light source (affects specular highlights)
- Default: `(1.0, 1.0, 0.9, 1.0)` - Warm white

### Ambient Intensity
- `_AmbientIntensity`: Base illumination level (prevents completely dark areas)
- Range: `0.0` to `1.0`
- Default: `0.2`

### Specular Properties
- `_SpecularPower`: Controls the sharpness of specular highlights
- Range: `1` to `200`
- Default: `100`
- Higher values = sharper, more focused highlights

- `_SpecularIntensity`: Controls the brightness of specular highlights
- Range: `0.0` to `2.0`
- Default: `1.0`

### Beveling Effects
- `_BevelDepth`: Controls the depth of the bevel effect
- Range: `0.0` to `0.1`
- Default: `0.02`
- Higher values = more pronounced 3D effect

- `_BevelSmoothness`: Controls the smoothness of bevel transitions
- Range: `0.001` to `0.1`
- Default: `0.01`
- Lower values = sharper bevel edges

## Implementation Details

### Normal Calculation

The shaders calculate 3D normals based on the geometry:

**SDFButton:**
- **Rounded Rectangle**: Normals based on distance from edges with smooth transitions
- **Ellipse**: Radial normals with edge-based height variation
- **Circle**: Simple radial normals with distance-based height

**Knob:**
- **Ring**: Normals based on distance from the line center with radial components
- **Nub**: Rectangular normals with edge-based height variation
- **Fill Area**: Radial normals for the center fill

### Lighting Model

The lighting calculation uses:
1. **Lambert Diffuse**: `dot(normal, lightDirection)`
2. **Blinn-Phong Specular**: `pow(dot(halfVector, normal), specularPower)`
3. **Ambient**: Base illumination level
4. **Bevel Effect**: Additional normal modification based on distance from edges

### Formula
```
finalColor = baseColor * (diffuse + ambient) + lightColor * specular
```

## Usage Examples

### Basic Setup
1. Apply the enhanced shader to your UI Image components
2. Adjust the lighting properties in the material inspector
3. Use the `LightingDemo.cs` script for runtime control

### Recommended Settings

**Subtle 3D Effect:**
- Light Intensity: `0.8`
- Ambient Intensity: `0.3`
- Specular Power: `50`
- Specular Intensity: `0.5`
- Bevel Depth: `0.01`
- Bevel Smoothness: `0.02`

**Strong 3D Effect:**
- Light Intensity: `1.2`
- Ambient Intensity: `0.1`
- Specular Power: `150`
- Specular Intensity: `1.0`
- Bevel Depth: `0.05`
- Bevel Smoothness: `0.005`

**Dramatic Lighting:**
- Light Direction: `(-0.5, 0.3, 1.0)`
- Light Intensity: `1.5`
- Ambient Intensity: `0.05`
- Specular Power: `200`
- Specular Intensity: `1.5`
- Bevel Depth: `0.08`
- Bevel Smoothness: `0.001`

## Performance Considerations

- The 3D lighting calculations add minimal performance overhead
- Normal calculations are optimized for UI elements
- Bevel effects use efficient smoothstep functions
- All calculations are done in the fragment shader for maximum quality

## Integration with Existing Features

The 3D lighting system works seamlessly with:
- All existing gradient types (Linear, Radial, Angular, Diamond, Triangle)
- Fill, Line, Outline, and Glow layers
- Icon rendering and custom textures
- Aspect ratio compensation
- Unity UI clipping and stencil operations

## Troubleshooting

**No lighting visible:**
- Check that `_LightIntensity` is greater than 0
- Ensure `_LightDirection` is not zero
- Verify `_AmbientIntensity` provides base illumination

**Too dark:**
- Increase `_AmbientIntensity`
- Increase `_LightIntensity`
- Adjust `_LightDirection` for better angle

**Too bright:**
- Decrease `_LightIntensity`
- Decrease `_SpecularIntensity`
- Increase `_AmbientIntensity` for more even lighting

**Sharp artifacts:**
- Increase `_BevelSmoothness`
- Decrease `_BevelDepth`
- Adjust `_SpecularPower` for softer highlights

## Demo Script

Use the included `LightingDemo.cs` script to:
- Control lighting properties at runtime
- Create interactive lighting demos
- Test different lighting configurations
- Provide user controls for lighting adjustments

The script provides public methods that can be connected to UI sliders and other controls for real-time lighting adjustment.
