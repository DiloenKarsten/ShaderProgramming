Shader "Unlit/LightTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Glossyness ("Gloss", Range(0,1)) = 1
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass //Base Pass
        {
         
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"



            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 wPos : TEXCOORD1;
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 wPos : TEXCOORD1;
                LIGHTING_COORDS(3,4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Glossyness;
            float4 _Color;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal( v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o); // Lighting Actually
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Diffuse Lighting
                float3 N = normalize(i.normal); //normalized to improve specular
                float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));
                float3 lambert = saturate(dot(N,L));
                float3 diffuseLight = lambert*_LightColor0.xyz; //Falloff of light gradient if 0 object is dark.

                // Specular Lighting Phong 
                
                float3 V = normalize(_WorldSpaceCameraPos-i.wPos); //normalize to get direction to the camera
                float3 R = reflect(-L,N); // reflected light around normal (-L since L points towards light)
                //float3 specularLight = max(0,dot(V,R)); 
                
                // Specular Lighting Blinn-Phong

                float3 H = normalize(L+V);
                float3 specularLight = saturate(dot(H,N))*(lambert>0);

                float specularExponent = exp2(_Glossyness*8)+2; //bad for optimisation should probably be passed from c# instead of math here.
                specularLight = pow(specularLight, specularExponent); // Specular Exponent
                specularLight*=_LightColor0.xyz;

                float fresnel = (1-dot(V,N))*((cos(_Time.y*4))*0.5+0.5);



                return float4(diffuseLight*_Color+specularLight,1); //Specular light is not multiplied by color unless material is metallic

                //return float4(diffuseLight,1);
            }
            
            
            ENDCG
        }
         

    }
}
