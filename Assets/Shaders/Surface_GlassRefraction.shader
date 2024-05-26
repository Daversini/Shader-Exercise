Shader "Custom/Crystal"
{
    Properties
    {
        _RefractionIndex ("Refraction Index", Range(0.0, 0.2)) = 0.1 // Indice di rifrazione
        _InnerColor ("Inner Color", Color) = (0.6,0,1,0.5) // Colore interno
        _RimColor ("Rim Light Color", Color) = (1,1,1,1) // Colore della rim light
        _RimIntensity ("Rim Light Intensity", Range(0, 1)) = 1.0 // Intensità della rim light
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" } // Imposta il render type come trasparente
        LOD 200

        GrabPass { "_GrabTexture" } // Cattura la scena dietro l'oggetto per l'effetto di rifrazione

        CGPROGRAM
        #pragma surface surf Standard alpha:fade // Usa il surface shader standard con trasparenza fade

        sampler2D _GrabTexture;
        float _RefractionIndex;
        fixed4 _InnerColor;
        fixed4 _RimColor;
        float _RimIntensity;

        struct Input
        {
            float3 worldPos; // Posizione nel mondo
            float3 viewDir; // Direzione della vista
            float4 screenPos; // Posizione sullo schermo per il GrabPass
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Calcola la rim light invertita
            float rim = saturate(1.0 - dot(normalize(IN.viewDir), normalize(o.Normal)));
            fixed4 rimLight = _RimColor * rim * _RimIntensity;

            // Calcola le coordinate UV della texture catturata
            float2 grabUV = IN.screenPos.xy / IN.screenPos.w;

            // Calcola il vettore di rifrazione
            float3 viewDir = normalize(IN.viewDir);
            float3 normal = normalize(o.Normal);
            float3 refracted = refract(viewDir, normal, 1.0);

            // Applica la distorsione basata sull'indice di rifrazione alle UV sia orizzontali che verticali
            grabUV += refracted.xy * _RefractionIndex; // L'indice di rifrazione controlla di quanto spostare le UV

            // Campiona la texture catturata con le coordinate distorte
            fixed4 grabbedColor = tex2D(_GrabTexture, grabUV);

            // Applica il colore del vetro
            grabbedColor.rgb = lerp(grabbedColor.rgb, _InnerColor.rgb, _InnerColor.a);

            // Combina la rim light distorta con il colore distorto
            fixed4 finalColor = grabbedColor + rimLight;

            // Assegna i valori di output
            o.Albedo = finalColor.rgb;  // Usa il colore rifratto e colorato, con l'effetto di rim light
            o.Alpha = grabbedColor.a;  // Usa l'alpha dalla texture catturata per la trasparenza
        }
        ENDCG
    }
    FallBack "Diffuse"
}