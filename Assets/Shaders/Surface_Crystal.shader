Shader "Custom/Surface_Crystal"
{
    Properties
    {
        _MainTex ("Color Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _AOMap ("Ambient Occlusion Map", 2D) = "white" {}
        _RoughnessMap ("Roughness Map", 2D) = "white" {}
        _DistortionIntensity ("Distortion Intensity", Range(0, 1)) = 0.5
        _RimLightColor ("Rim Light Color", Color) = (1,0,0,1)
        _RimLightIntensity ("Rim Light Intensity", Range(0, 1)) = 1.0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.8
        _Transparency ("Transparency", Range(0, 1)) = 0.8
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" } // Set render type to transparent
        LOD 200

        GrabPass { "_GrabTexture" } // Capture the screen for distortion

        CGPROGRAM
        #pragma surface surf Standard alpha:fade // Use Standard surface with fade transparency

        // Texture and variable declarations
        sampler2D _MainTex;
        sampler2D _NormalMap;
        sampler2D _AOMap;
        sampler2D _RoughnessMap;
        sampler2D _GrabTexture;
        float _DistortionIntensity;
        fixed4 _RimLightColor;
        float _RimLightIntensity;
        float _Smoothness;
        float _Transparency;

        struct Input
        {
            float2 uv_MainTex; // UV coordinates for the main texture
            float3 worldPos; // World position
            float3 viewDir; // View direction
            float4 screenPos; // Screen position for grab pass
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 tiledUV = IN.uv_MainTex; // Adjust UVs for tiling and offset

            fixed4 c = tex2D(_MainTex, tiledUV); // Sample the main texture

            // Apply distortion based on world position
            float3 distOffset = normalize(IN.worldPos) * _DistortionIntensity;
            float2 distUV = IN.uv_MainTex + distOffset.xy;
            c = tex2D(_MainTex, distUV); // Sample the main texture with distortion

            // Sample the grabbed texture for refraction effect
            float2 grabUV = IN.screenPos.xy / IN.screenPos.w;
            grabUV += distOffset.xy * _DistortionIntensity;
            fixed4 grabbedColor = tex2D(_GrabTexture, grabUV);

            // Calculate rim light effect
            float rim = saturate(dot(normalize(IN.viewDir), o.Normal));
            rim = 1.0 - rim;
            fixed4 rimLight = _RimLightColor * rim * _RimLightIntensity;

            // Output assignments
            o.Albedo = c.rgb;
            o.Alpha = c.a * _Transparency;  // Apply transparency
            o.Emission = rimLight.rgb + grabbedColor.rgb * _DistortionIntensity;

            // Sample normal map and calculate normal
            fixed3 normalTex = UnpackNormal(tex2D(_NormalMap, tiledUV));
            o.Normal = normalize(normalTex);

            // Sample roughness map and assign values
            o.Metallic = tex2D(_RoughnessMap, tiledUV).r;
            o.Smoothness = _Smoothness;

            // Sample ambient occlusion map
            o.Occlusion = tex2D(_AOMap, tiledUV).r;
        }
        ENDCG
    }
    FallBack "Diffuse"
}