Shader "Unlit/SoftShadowCatcher"
{
    Properties
    {
       
    }
   SubShader
    {

        Tags { "RenderType" = "AlphaTest" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
             #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes
            {
                float4 positionOS  : POSITION;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float4 shadowCoords : TEXCOORD3;
                float3 shadowFade : TEXCOORD4;
            };

            
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                // Get the VertexPositionInputs for the vertex position  
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);

                // Convert the vertex position to a position on the shadow map
                float4 shadowCoordinates = GetShadowCoord(positions);
              

                // Pass the shadow coordinates to the fragment shader
                OUT.shadowCoords = shadowCoordinates;
             

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {half4 shadowParams = GetMainLightShadowParams();
                
                 ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                
               
                return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_LinearClampCompare), IN.shadowCoords, shadowSamplingData, shadowParams, false);
             
            }
            
            ENDHLSL
        }
    }
}
