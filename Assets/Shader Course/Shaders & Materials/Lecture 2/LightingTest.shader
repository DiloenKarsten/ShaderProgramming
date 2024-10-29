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

            #include "UnityCG.cginc"

            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 wPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _PercentPerShades;
            float _MinValue;
            float _MaxValue;

            v2f vert (MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            // Remap a value from one range to another
            float remap(float In, float2 InMinMax, float2 OutMinMax) {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            fixed4 frag (v2f i) : SV_Target {
                // Access light direction
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);  // Direction towards the light

                // Use the dot product of the light direction and the surface normal
                float lambert = saturate(dot(i.normal, lightDir));

                // Toon shading (posterization)
                float remappedDot = remap(lambert, float2(0.0, 1.0), float2(_MinValue, _MaxValue));
                float shades = floor(remappedDot / _PercentPerShades);
                float remappedShades = remap(shades, float2(0.0, 1.0 / _PercentPerShades), float2(_MinValue, _MaxValue));

                // Sample the texture and apply toon shading
                fixed4 texColor = tex2D(_MainTex, i.uv);
                fixed4 result = texColor * _Color * remappedShades;

                return result;
            }

            ENDCG
        }
    }
}
