Shader "Custom/Surface_Crystal"
{
    Properties
    {
        // Refraction Properties
        [Header(Refraction)]
        _RefractionColor ("Refraction Color", Color) = (0.6,0,1,0.5)
        _RefractionIndex ("Refraction Index", Range(0.0, 0.5)) = 0.1

        // Fresnel Properties
        [Header(Fresnel)]
        _FresnelColor ("Fresnel Color", Color) = (1,0,0,1)
        _FresnelPower ("Fresnel Power", Range(0.0, 10.0)) = 0.2
        _FresnelIntensity ("Fresnel Intensity", Range(0.0, 10.0)) = 10.0
    }

    SubShader
    {
        // Setting render type to transparent
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200

        // Capturing the scene behind the object for refraction effect
        GrabPass { "_GrabTexture" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _GrabTexture;
            fixed4 _RefractionColor;
            float _RefractionIndex;
            fixed4 _FresnelColor;
            float _FresnelPower;
            float _FresnelIntensity;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.screenPos = ComputeScreenPos(o.pos);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                // Calculating UV coordinates of the captured texture
                float2 grabUV = i.screenPos.xy / i.screenPos.w;

                // Calculating the refraction vector
                float3 viewDir = normalize(i.viewDir);
                float3 normal = normalize(i.worldNormal);
                float3 refracted = refract(viewDir, normal, 1.0);

                // Applying distortion based on the refraction index to both horizontal and vertical UVs
                grabUV += refracted.xy * _RefractionIndex;

                // Sampling the captured texture with distorted coordinates
                fixed4 grabbedColor = tex2D(_GrabTexture, grabUV);

                // Applying the refraction color to the grabbed color
                grabbedColor.rgb = lerp(grabbedColor.rgb, _RefractionColor.rgb, _RefractionColor.a);

                // Calculating the fresnel factor using the Fresnel term
                float fresnelFactor = pow(1.0 - saturate(dot(viewDir, normal)), 1.0 / _FresnelPower);
                fixed4 fresnelColor = _FresnelColor * _FresnelIntensity * fresnelFactor;

                // Combining the fresnel color with the refracted color
                grabbedColor.rgb += fresnelColor.rgb;

                // Returning the final color to the fragment shader
                return fixed4(grabbedColor.rgb, grabbedColor.a);
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}