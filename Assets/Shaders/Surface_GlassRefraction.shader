Shader "Custom/Surface_GlassRefraction"
{
    Properties
    {
        _RefractionIndex ("Refraction Index", Range(0.0, 1.0)) = 0.5 // Indice di rifrazione controllabile
        _Transparency ("Transparency", Range(0, 1)) = 0.8 // Trasparenza del materiale
        _GlassColor ("Glass Color", Color) = (0,1,0,0.5) // Colore del vetro
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
        float _Transparency;
        fixed4 _GlassColor;
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
            // Calcola le coordinate UV della texture catturata
            float2 grabUV = IN.screenPos.xy / IN.screenPos.w;

            // Calcola il vettore di rifrazione
            float3 viewDir = normalize(IN.viewDir);
            float3 normal = normalize(o.Normal);
            float3 refracted = refract(viewDir, normal, 1.0); // Mantieni l'indice di rifrazione fisso a 1.0 per ottenere il vettore di rifrazione

            // Applica la distorsione basata sull'indice di rifrazione alle UV sia orizzontali che verticali
            float2 distUV = grabUV + refracted.xy * _RefractionIndex; // L'indice di rifrazione controlla di quanto spostare le UV

            // Campiona la texture catturata con le coordinate distorte
            fixed4 grabbedColor = tex2D(_GrabTexture, distUV);

            // Applica il colore del vetro
            grabbedColor.rgb = lerp(grabbedColor.rgb, _GlassColor.rgb, _GlassColor.a);

            // Calcola l'effetto di rim light
            float rim = 1.0 - saturate(dot(viewDir, normal));
            fixed4 rimLight = _RimColor * pow(rim, _RimIntensity);

            // Assegna i valori di output
            o.Albedo = grabbedColor.rgb + rimLight.rgb;  // Usa il colore rifratto e colorato, con l'effetto di rim light

            // Calcola la trasparenza distorta
            o.Alpha = _Transparency; // Mantieni la trasparenza costante
        }
        ENDCG
    }
    FallBack "Diffuse"
}