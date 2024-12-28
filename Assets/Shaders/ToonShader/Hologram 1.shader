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
        _Cells ("Cells", Range(1, 100)) = 20
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
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(MeshData v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv; // Pass UV coordinates
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Scale UV coordinates by the Cells property
                float2 coords = i.uv * _Cells;

                // Find the center of the current cell
                float2 cellCenter = floor(coords) + 0.5;

                // Compute Signed Distance Function (SDF) for a circle
                float sdf = length(frac(coords) - 0.5) - 0.3;

                // Create circle mask (1 inside the circle, 0 outside)
                float circleMask = smoothstep(0.0, 0.1, -sdf);

                // Background color with consistent transparency
                fixed4 backgroundColor = _BackgroundColor;
                backgroundColor.a *= 0.5;

                // Hologram color modulated by circle mask
                fixed4 hologramColor = _HoloColor * circleMask;
                hologramColor.a = circleMask;

                // Combine background and hologram
                fixed4 finalColor = lerp(backgroundColor, hologramColor, circleMask);

                // Apply transparency
                finalColor.a = max(backgroundColor.a, hologramColor.a);

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Unlit/Transparent"
}
