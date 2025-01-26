Shader "Custom/UnlitShader"
{
    Properties
    {
        [MainTexture] _TextureAlbedo ("TextureAlbedo", 2D) = "white" {}
        _Glossyness ("Gloss", Range(0,1)) = 1
        _Color ("Color", Color) = (1,1,1,1)
        _LightRange ("Add Light Range", Range(0,1)) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
          
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 wPos : TEXCOORD1;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertexCS : SV_POSITION;
                float3 normal : NORMAL;
                float3 wPos : TEXCOORD1;
                half3 lightAmount : TEXCOORD2;
            };

            TEXTURE2D(_TextureAlbedo);
            SAMPLER(sampler_TextureAlbedo);

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float4 _TextureAlbedo_ST;
            float _Glossyness;
            float _LightRange;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.vertexCS = TransformObjectToHClip(IN.vertexOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _TextureAlbedo);
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.wPos = mul(unity_ObjectToWorld, IN.vertexOS);
               
                return OUT;
            }

            float3 DiffuseLighting(float3 N, float3 L, Light light)
            {
                float3 lambert = saturate(dot(N,L));
                return lambert*light.color.xyz; //Falloff of light gradient if 0 object is dark.
            }

            float3 SpecularLighting(float3 N, float3 L, float3 wPos)
            {
                float3 V = normalize(_WorldSpaceCameraPos-wPos); //normalize to get viev direction to the camera
                float3 R = reflect(-L,N); // reflected light around normal (-L since L points towards light)
                return max(0,dot(V,R));
            }

            float3 SpecularBlinnPhong(float3 N, float3 L, float3 wPos, Light light)
            {
               
                float3 lambert = saturate(dot(N,L));
                 float3 V = normalize(_WorldSpaceCameraPos-wPos); //View Vector
                float3 H = normalize(L+V); // Half-view vector

                float specularExponent = exp2(_Glossyness*8)+2; //bad for optimisation should probably be passed from c# instead of math here.
                float3 specularLight =  saturate(dot(H,N))*(lambert>0);
                specularLight = pow(specularLight, specularExponent); // Specular Exponent
                specularLight*=light.color.xyz;
                return specularLight;
            }
            

            half4 frag(Varyings IN) : SV_Target
            {
                half3 rock = SAMPLE_TEXTURE2D(_TextureAlbedo,sampler_TextureAlbedo,IN.uv).rgb;
                half3 surfaceColor = rock * _Color.rgb;
                
                Light light = GetMainLight();
              
                float3 N = normalize(IN.normal); //normalized to improve specular
                float3 L = normalize(light.direction);
                
                float3 diffuseLight = DiffuseLighting(N,L,light);
                
              
                float3 specularLight = SpecularLighting(N,L,IN.wPos); 
                
                // Specular Lighting Blinn-Phong
                float3 specularBlinnPhong = SpecularBlinnPhong(N,L, IN.wPos,light);
                

                
                // Fresnel giver skinnende kanter omkring runde objekter
               // float fresnel = (1-dot(V,N))*((cos(_Time.y*4))*0.5+0.5);


                
               return float4(diffuseLight*surfaceColor*specularBlinnPhong+IN.lightAmount,1); //Specular light is not multiplied by color unless material is metallic




               return float4(diffuseLight*_Color,1);
            }   
            ENDHLSL

            
        }
            Pass
            {
              Tags  {"lightmode"="ShadowCaster"}
            }
    }
}