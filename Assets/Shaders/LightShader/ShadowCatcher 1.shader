Shader "Unlit/AdjustableSoftEdgesShadowCatcher"
{
    Properties
    {
        _ShadowColor ("Shadow Color", Color) = (0,0,0,1) // Shadow color
        _EdgeSoftness ("Edge Softness", Range(0, 1)) = 0.1 // Soft edge size
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 shadowCoords : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _ShadowColor;    // Shadow color
            float _EdgeSoftness;    // Soft edge size
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.shadowCoords = GetShadowCoord(vertexInputs);

                return OUT;
            }

            float SampleSoftShadow(float4 shadowCoords, float softness)
            {
                float shadowStrength = 0.0;
                int sampleCount = 9;

                // Offsets for sampling (a 3x3 kernel)
                float2 offsets[9] = {
                    float2(-1, -1), float2(0, -1), float2(1, -1),
                    float2(-1,  0), float2(0,  0), float2(1,  0),
                    float2(-1,  1), float2(0,  1), float2(1,  1)
                };

                // Accumulate shadow strength
                for (int i = 0; i < sampleCount; i++)
                {
                    float2 offset = offsets[i] * softness;
                    shadowStrength += MainLightRealtimeShadow(shadowCoords + float4(offset, 0, 0));
                }

                return shadowStrength / sampleCount; // Average the samples
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Sample soft shadow with edge softness
                float shadowStrength = SampleSoftShadow(IN.shadowCoords, _EdgeSoftness);

                // Calculate shadow alpha
                float shadowAlpha = saturate(1.0 - shadowStrength); // Invert shadow strength

                // Output shadow color with adjusted transparency
                return float4(_ShadowColor.rgb, shadowAlpha);
            }

            ENDHLSL
        }
    }
}
