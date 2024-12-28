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
        _Cells ("Cells", Range(1, 200)) = 20
    }
   
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" }
        Blend SrcAlpha OneMinusSrcAlpha

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

            struct MeshData
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 localPos : TEXCOORD0; // Local-space position for uniform patterns
            };

            v2f vert(MeshData v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // Transform vertex to local space for consistent patterns
                o.localPos = mul(unity_ObjectToWorld, v.vertex).xyz * _NoiseScale;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Generate grid-based coordinates using local-space position
                float2 gridCoords = float2(i.localPos.y, i.localPos.x) * _Cells;

                // Compute Signed Distance Function (SDF) for a circle
                float sdf = length(frac(gridCoords) - 0.5) - 0.3;

                // Create a mask for valid SDF regions
                float sdfMask = step(-0.01, -sdf); // Mask is 1.0 inside the circle, 0.0 outside

                // Apply scrolling effect
                float timeOffset = -_Time.y * _ScrollSpeed;
                gridCoords += timeOffset;

                // Generate procedural noise
                float noise = frac(sin(dot(gridCoords, float2(12.9898, 78.233))) * 43758.5453);

                // Create gaps based on particle size
                float particlePattern = step(_ParticleSize, frac(gridCoords.x + gridCoords.y));

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
