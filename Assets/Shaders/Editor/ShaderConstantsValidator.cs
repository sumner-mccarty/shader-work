// ShaderConstantsValidator.cs
// Runs in the editor at load time and warns if ShaderConstants.cs enum values
// have drifted from the matching #define values in the .cginc files.
#if UNITY_EDITOR
using System.IO;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

[InitializeOnLoad]
public static class ShaderConstantsValidator
{
    static ShaderConstantsValidator() => Validate();

    [MenuItem("Tools/Validate Shader Constants")]
    public static void Validate()
    {
        string root = Application.dataPath + "/Shaders/CG/Core/";
        CheckDefine(root + "UIGradients.cginc", "GRADIENT_LINEAR",       (int)GradientType.Linear);
        CheckDefine(root + "UIGradients.cginc", "GRADIENT_RADIAL",       (int)GradientType.Radial);
        CheckDefine(root + "UIGradients.cginc", "GRADIENT_ANGULAR",      (int)GradientType.Angular);
        CheckDefine(root + "UIGradients.cginc", "GRADIENT_DIAMOND",      (int)GradientType.Diamond);
        CheckDefine(root + "UIGradients.cginc", "GRADIENT_TRIANGLE",     (int)GradientType.Triangle);
        CheckDefine(root + "UIGradients.cginc", "GRADIENT_BEVEL_DEPTH",  (int)GradientType.BevelDepth);
        CheckDefine(root + "UIGradients.cginc", "GRADIENT_BEVEL_WALLS",  (int)GradientType.BevelWalls);

        CheckDefine(root + "UIPatterns.cginc",  "PATTERN_PLASTIC",       (int)PatternType.Plastic);
        CheckDefine(root + "UIPatterns.cginc",  "PATTERN_METAL",         (int)PatternType.Metal);
        CheckDefine(root + "UIPatterns.cginc",  "PATTERN_RADIAL_BRUSHED",(int)PatternType.RadialBrushed);
    }

    static void CheckDefine(string file, string define, int expectedValue)
    {
        if (!File.Exists(file)) { Debug.LogWarning($"[ShaderConstants] File not found: {file}"); return; }
        foreach (var line in File.ReadAllLines(file))
        {
            var m = Regex.Match(line, $@"#define\s+{Regex.Escape(define)}\s+(\d+)");
            if (!m.Success) continue;
            int actual = int.Parse(m.Groups[1].Value);
            if (actual != expectedValue)
                Debug.LogError($"[ShaderConstants] MISMATCH: {define} is {actual} in .cginc but {expectedValue} in ShaderConstants.cs — update one to match the other.");
            return;
        }
        Debug.LogWarning($"[ShaderConstants] Define '{define}' not found in {Path.GetFileName(file)}");
    }
}
#endif
