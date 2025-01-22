Shader "Custom/ConsistentHologramShader"
{
    Properties
    {
        _HoloColor ("Hologram Color", Color) = (0, 0.5, 1, 1)
        _BackgroundColor ("Background Color", Color) = (0, 0, 0, 1)
        _NoiseScale ("Noise Scale", Float) = 10.0
        _ScrollSpeed ("Scroll Speed", Float) = 0.5
        _GlowIntensity ("Glow Intensity", Float) = 1.0
        _ParticleSize ("Particle Size", Float) = 0.1
         _Cells("Cells",Range(0,200)) = 20
    }
   
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" }
        Blend SrcAlpha OneMinusSrcAlpha
        Stencil
        {
            Ref 1               // Reference value for stencil operations
            Comp Equal          // Render only where stencil buffer == Ref
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Properties
            float4 _HoloColor;
            float4 _BackgroundColor;
            float _NoiseScale;
            float _ScrollSpeed;
            float _GlowIntensity;
            float _ParticleSize;
             int _Cells;

             struct MeshData {
                float4 vertex : POSITION; // Position of the Vertex
       
                float2 uv : TEXCOORD0; // UV of the vertex
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0; //Normal Map textures for calculating toon shader
            
                float3 worldPos : TEXCOORD2; // World position for noise stability
                
            };

            v2f vert (MeshData v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // Transform vertex to clip space
                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // Transform to world space
                 o.uv = v.uv; // Pass UV coordinates
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 coords = i.uv * _Cells;

               

                // Compute Signed Distance Function (SDF) for a circle
                float sdf = length(frac(coords) - 0.5) - 0.3;

                // Create a mask for valid SDF regions
                 float sdfMask = step(-0.01, -sdf); // Mask is 1.0 inside the circle, 0.0 outside


                // Scale world position for procedural noise
                float3 worldCoords = i.worldPos * _NoiseScale;

                
                
                // Apply scrolling noise effect
                float timeOffset = -_Time.y * _ScrollSpeed;
                worldCoords.xy += timeOffset;

                // Generate procedural noise
               // float noise = frac(sin(dot(worldCoords.xy, float2(12.9898, 78.233))) * 43758.5453)*sdfMask;
          

                // Create gaps based on particle size
                float particlePattern = step(_ParticleSize, frac(worldCoords.z + worldCoords.y));

                // Combine noise with particle effect
                float intensity = sdfMask * particlePattern * _GlowIntensity;

                // Background color with consistent transparency
                fixed4 backgroundColor = _BackgroundColor;
                backgroundColor.a *= 0.8; // Adjust this value for desired background transparency

                // Hologram color modulated by intensity
                fixed4 hologramColor = _HoloColor * intensity;
                hologramColor.a = intensity;

                // Combine background and hologram
                fixed4 finalColor = lerp(backgroundColor, hologramColor, intensity);

                // Set final alpha to combine both effects
                finalColor.a = max(backgroundColor.a, hologramColor.a);

                return finalColor;
            }

            ENDCG
        }
       
    }
    FallBack "Unlit/Transparent"
}
