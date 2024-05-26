Shader "Unlit/NewUnlitShader" {
    Properties { // input data
        _Value ("Value", Float) = 1.0
    }
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Value;

            // automatically filled out by Unity
            struct MeshData { // per-vertex mesh data
                float4 vertex : POSITION; // vertex position
                float3 normal : NORMAL;
                // float4 tangent : TANGENT;
                // float4 color : COLOR;
                float4 uv0 : TEXCOORD0; // uv0 diffuse/normal map textures
                // float4 uv1 : TEXCOORD1; // uv1 coordinates lightmap coordinates
            };

            // data passed from the vertex shader to the fragment shader
            // this will interpolate/blend across the triangle!
            struct Interpolators {
                float4 vertex : SV_POSITION; // clip space position
                // float2 uv : TEXCOORD0;
            };
            
            
            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex); // local space to clip space
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                return float4(1, 0, 0, 1); // red
            }
            
            ENDCG
        }
    }
}
