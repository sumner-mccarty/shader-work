#ifndef SDF_ICONS_INCLUDED
#define SDF_ICONS_INCLUDED

#include "../SDFPrimitives.cginc"
#include "../SDFOperations.cginc"
#include "SDFIconsBasic.cginc"
#include "SDFIconsUI.cginc"

// Icon type ranges for different categories
#define ICON_RANGE_BASIC_START    1
#define ICON_RANGE_BASIC_END      19
#define ICON_RANGE_UI_START       20
#define ICON_RANGE_UI_END         39
#define ICON_RANGE_CUSTOM_START   40
#define ICON_RANGE_CUSTOM_END     99

// Convenience aliases for commonly used icons
#define ICON_NONE           0

// Basic Media Icons (1-19)
// Already defined in SDFIconsBasic.cginc:
// ICON_PLAY = 1, ICON_PAUSE = 2, ICON_STOP = 3, etc.

// UI Icons (20-39) 
// Already defined in SDFIconsUI.cginc:
// ICON_HAMBURGER = 20, ICON_CLOSE = 21, ICON_INFO = 22, etc.

// Custom Icons (40-99) - Reserved for user-defined icons
// These can be extended in SDFIconsCustom.cginc

// Additional common aliases for easier use
#define ICON_MENU           ICON_HAMBURGER
#define ICON_X              ICON_CLOSE
#define ICON_GEAR           ICON_SETTINGS
#define ICON_MAGNIFY        ICON_SEARCH
#define ICON_ADD            ICON_PLUS
#define ICON_SUBTRACT       ICON_MINUS
#define ICON_CHECKMARK      ICON_CHECK
#define ICON_UP_ARROW       ICON_ARROW_UP
#define ICON_DOWN_ARROW     ICON_ARROW_DOWN
#define ICON_LEFT_ARROW     ICON_ARROW_LEFT  
#define ICON_RIGHT_ARROW    ICON_ARROW_RIGHT

// ----------------------
// Icon Size Presets
// ----------------------

#define ICON_SIZE_TINY      0.1
#define ICON_SIZE_SMALL     0.15
#define ICON_SIZE_MEDIUM    0.2
#define ICON_SIZE_LARGE     0.3
#define ICON_SIZE_HUGE      0.4

// ----------------------
// Main Icon Dispatcher
// ----------------------

float GetIconSDF(int iconType, float2 p, float size)
{
    // Handle no icon case
    if (iconType == ICON_NONE)
        return 1000.0;
    
    // Basic media control icons (1-19)
    if (iconType >= ICON_RANGE_BASIC_START && iconType <= ICON_RANGE_BASIC_END)
    {
        return GetBasicIconSDF(p, iconType, size);
    }
    
    // UI navigation icons (20-39)
    if (iconType >= ICON_RANGE_UI_START && iconType <= ICON_RANGE_UI_END)
    {
        return GetUIIconSDF(p, iconType, size);
    }
    
    // Custom icons (40-99)
    if (iconType >= ICON_RANGE_CUSTOM_START && iconType <= ICON_RANGE_CUSTOM_END)
    {
#ifdef SDF_ICONS_CUSTOM_INCLUDED
        return GetCustomIconSDF(p, iconType, size);
#else
        return 1000.0; // No custom icons defined
#endif
    }
    
    // Unknown icon type
    return 1000.0;
}

// ----------------------
// Convenience Functions
// ----------------------

// Get icon with automatic size scaling based on icon type
float GetIconSDFAutoSize(int iconType, float2 p, float baseSize)
{
    float adjustedSize = baseSize;
    
    // Some icons look better with slight size adjustments
    switch (iconType)
    {
        case ICON_PLAY:
            adjustedSize *= 1.1; // Play icon tends to look smaller
            break;
        case ICON_SETTINGS:
            adjustedSize *= 0.9; // Gear icon tends to look larger
            break;
        case ICON_INFO:
            adjustedSize *= 1.05; // Info icon with circle border
            break;
        case ICON_SEARCH:
            adjustedSize *= 1.1; // Magnifying glass with handle
            break;
        case ICON_HOME:
            adjustedSize *= 1.05; // House icon with roof
            break;
        case ICON_VOLUME_UP:
        case ICON_VOLUME_DOWN:
        case ICON_VOLUME_MUTE:
            adjustedSize *= 0.95; // Volume icons have speaker + waves
            break;
    }
    
    return GetIconSDF(iconType, p, adjustedSize);
}

// Get icon with centered positioning
float GetIconSDFCentered(int iconType, float2 p, float2 center, float size)
{
    return GetIconSDF(iconType, p - center, size);
}

// Get icon with rotation
float GetIconSDFRotated(int iconType, float2 p, float size, float rotation)
{
    float2 rotatedP = OpRotate(p, rotation);
    return GetIconSDF(iconType, rotatedP, size);
}

// Get icon with both centering and rotation
float GetIconSDFTransformed(int iconType, float2 p, float2 center, float size, float rotation)
{
    float2 transformedP = OpRotate(p - center, rotation);
    return GetIconSDF(iconType, transformedP, size);
}

// ----------------------
// Icon Validation and Info
// ----------------------

// Check if an icon type is valid
bool IsValidIconType(int iconType)
{
    if (iconType == ICON_NONE)
        return true;
    
    if (iconType >= ICON_RANGE_BASIC_START && iconType <= ICON_RANGE_BASIC_END)
        return true;
    
    if (iconType >= ICON_RANGE_UI_START && iconType <= ICON_RANGE_UI_END)
        return true;
    
    if (iconType >= ICON_RANGE_CUSTOM_START && iconType <= ICON_RANGE_CUSTOM_END)
    {
#ifdef SDF_ICONS_CUSTOM_INCLUDED
        return true;
#else
        return false;
#endif
    }
    
    return false;
}

// Get the category name for an icon type (for debugging)
int GetIconCategory(int iconType)
{
    if (iconType == ICON_NONE)
        return 0; // None
    
    if (iconType >= ICON_RANGE_BASIC_START && iconType <= ICON_RANGE_BASIC_END)
        return 1; // Basic
    
    if (iconType >= ICON_RANGE_UI_START && iconType <= ICON_RANGE_UI_END)
        return 2; // UI
    
    if (iconType >= ICON_RANGE_CUSTOM_START && iconType <= ICON_RANGE_CUSTOM_END)
        return 3; // Custom
    
    return -1; // Invalid
}

// ----------------------
// Multi-Icon Compositions
// ----------------------

// Combine two icons (useful for composite icons like "play with border")
float CombineIconsSDF(int iconType1, int iconType2, float2 p, float size1, float size2, int operation)
{
    float sdf1 = GetIconSDF(iconType1, p, size1);
    float sdf2 = GetIconSDF(iconType2, p, size2);
    
    switch (operation)
    {
        case 0: // Union
            return OpUnion(sdf1, sdf2);
        case 1: // Subtraction (icon1 - icon2)
            return OpSubtraction(sdf2, sdf1);
        case 2: // Intersection
            return OpIntersection(sdf1, sdf2);
        case 3: // Smooth Union
            return OpSmoothUnion(sdf1, sdf2, 0.02);
        default:
            return OpUnion(sdf1, sdf2);
    }
}

// Create a badge icon (small icon overlaid on larger icon)
float CreateBadgeIconSDF(int mainIcon, int badgeIcon, float2 p, float mainSize, float badgeSize, float2 badgeOffset)
{
    float mainSDF = GetIconSDF(mainIcon, p, mainSize);
    float badgeSDF = GetIconSDF(badgeIcon, p - badgeOffset, badgeSize);
    return OpUnion(mainSDF, badgeSDF);
}

// ----------------------
// Animation Helpers
// ----------------------

// Get animated icon (useful for loading spinners, etc.)
float GetAnimatedIconSDF(int iconType, float2 p, float size, float time, float speed)
{
    float rotation = time * speed;
    return GetIconSDFRotated(iconType, p, size, rotation);
}

// Pulsing icon effect
float GetPulsingIconSDF(int iconType, float2 p, float baseSize, float time, float speed, float pulseAmount)
{
    float pulse = sin(time * speed) * 0.5 + 0.5;
    float size = baseSize * (1.0 + pulse * pulseAmount);
    return GetIconSDF(iconType, p, size);
}

// ----------------------
// Shader Property Helpers
// ----------------------

// Helper for shader properties that use icon enums
// This should match the enum values in your shader properties
float GetShaderIconSDF(int shaderIconEnum, float2 p, float size)
{
    // Map shader enum values to icon IDs
    // This assumes your shader uses a simple 0-based enum
    // Adjust mapping as needed for your specific shader enums
    
    int iconType = ICON_NONE;
    
    // Example mapping - adjust based on your shader's enum order
    switch (shaderIconEnum)
    {
        case 0:
            iconType = ICON_PLAY;
            break;
        case 1:
            iconType = ICON_PAUSE;
            break;
        case 2:
            iconType = ICON_STOP;
            break;
        case 3:
            iconType = ICON_MENU;
            break;
        case 4:
            iconType = ICON_SETTINGS;
            break;
        case 5:
            iconType = ICON_CLOSE;
            break;
        case 6:
            iconType = ICON_PLUS;
            break;
        case 7:
            iconType = ICON_MINUS;
            break;
        case 8:
            iconType = ICON_CHECK;
            break;
        case 9:
            iconType = ICON_HOME;
            break;
        case 10:
            iconType = ICON_SEARCH;
            break;
        case 11:
            iconType = ICON_INFO;
            break;
        case 12:
            iconType = ICON_ARROW_UP;
            break;
        case 13:
            iconType = ICON_ARROW_DOWN;
            break;
        case 14:
            iconType = ICON_ARROW_LEFT;
            break;
        case 15:
            iconType = ICON_ARROW_RIGHT;
            break;
        default:
            iconType = ICON_NONE;
            break;
    }
    
    return GetIconSDF(iconType, p, size);
}

#endif