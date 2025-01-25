Shader "Custom/ToonShaderWithLightDirection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1, 1, 1, 1)
        _PercentPerShades ("Percent Per Shades", Float) = 0.49
        _MinValue ("Min Value", Float) = 0.3
        _MaxValue ("Max Value", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //Takes code from another file and includes it in the shader
            #include "UnityCG.cginc"

            struct MeshData {
                float4 vertex : POSITION; // Position of the Vertex
                float3 normal : NORMAL;  // Normal of the Vertex
                float2 uv : TEXCOORD0; // UV of the vertex
            };

            struct v2f { // The data passed from vertex to fragment shader
                float4 vertex : SV_POSITION; //Clip space this is always needed 
                float2 uv : TEXCOORD0; //Normal Map textures for calculating toon shader
                float3 normal : TEXCOORD1; 
                float3 wPos : TEXCOORD2;
            };

           
            sampler2D _MainTex; // 2D Texture 
            float4 _MainTex_ST; // tex suffix (x,y: Tilling) (z,w: Offset)

            float4 _Color; //RGBA

            float _PercentPerShades; //How many percent each shade takes up 
            float _MinValue;
            float _MaxValue;

            v2f vert (MeshData v) {
                v2f o;
               
                o.vertex = UnityObjectToClipPos(v.vertex); // Transforms from local space to clip space (MVP)
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // Transforms 2D UV by scale/bias property
                o.normal = UnityObjectToWorldNormal(v.normal); // Transforms local normals into world normals
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            // Remap a value from one range to another
            float remap(float In, float2 InMinMax, float2 OutMinMax) {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            fixed4 frag (v2f i) : SV_Target {
                // Access light direction
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // Direction toward the light
                float3 normal = normalize(i.normal); // Ensure surface normal is normalized

                // Use the dot product of the light direction and the surface normal
                float dotted = (dot(normal, lightDir));

                // Toon shading (posterization)
                float remappedDot = remap(dotted, float2(-1, 1.0), float2(0, 1));
                float shades = floor(remappedDot / _PercentPerShades); //returns the value that is less than or equal to the value of input
                float remappedShades = remap(shades, float2(0.0, 1/_PercentPerShades), float2(_MinValue, _MaxValue));

                // Sample the texture and apply toon shading
                fixed4 texColor = tex2D(_MainTex, i.uv);
                fixed4 result = texColor * _Color * remappedShades;

                return result;
            }

            ENDCG
        }
        Pass
        {
            Tags {"lightmode"="ShadowCaster"}
        }
    }
}
