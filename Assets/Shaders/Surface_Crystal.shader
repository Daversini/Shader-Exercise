Shader "Custom/Surface_Crystal"
{
    Properties
    {
        // Refraction Properties
        [Header(Refraction)]
        _RefractionIndex ("Refraction Index", Range(0.0, 0.5)) = 0.1 // Indice di rifrazione
        _InnerColor ("Inner Color", Color) = (0.6,0,1,0.5) // Colore interno

        // Rim Light Properties
        [Header(Rim Light)]
        _RimColor ("Rim Light Color", Color) = (1,0,0,1) // Colore della rim light
        _RimPower ("Rim Light Power", Range(0.0, 10.0)) = 0.2 // Potenza della rim light
        _RimIntensity ("Rim Light Intensity", Range(0.0, 10.0)) = 10.0 // Intensità della rim light
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
        float _RimPower;
        float _RimIntensity;

        struct Input
        {
            float3 worldPos; // Posizione nel mondo
            float3 viewDir; // Direzione della vista
            float4 screenPos; // Posizione sullo schermo per il GrabPass
            float3 worldNormal; // Normale del mondo
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Calcola le coordinate UV della texture catturata
            float2 grabUV = IN.screenPos.xy / IN.screenPos.w;

            // Calcola il vettore di rifrazione
            float3 viewDir = normalize(IN.viewDir);
            float3 normal = normalize(IN.worldNormal);
            float3 refracted = refract(viewDir, normal, 1.0);

            // Applica la distorsione basata sull'indice di rifrazione alle UV sia orizzontali che verticali
            grabUV += refracted.xy * _RefractionIndex;

            // Campiona la texture catturata con le coordinate distorte
            fixed4 grabbedColor = tex2D(_GrabTexture, grabUV);

            // Applica il colore del vetro
            grabbedColor.rgb = lerp(grabbedColor.rgb, _InnerColor.rgb, _InnerColor.a);

            // Calcola il fattore di rim light usando il termine di Fresnel
            float rimFactor = pow(1.0 - saturate(dot(viewDir, normal)), 1.0 / _RimPower);
            fixed4 rimColor = _RimColor * _RimIntensity * rimFactor;

            // Combina il colore della rim light con il colore rifratto
            grabbedColor.rgb += rimColor.rgb;

            // Assegna i valori di output
            o.Albedo = grabbedColor.rgb;  // Usa il colore finale con la rim light
            o.Alpha = grabbedColor.a;  // Usa l'alpha dalla texture catturata per la trasparenza
        }
        ENDCG
    }
    FallBack "Transparent/Diffuse"
}