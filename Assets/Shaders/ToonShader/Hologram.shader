Shader "Custom/HologramProjectionShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1, 1, 1, 1)
        _HoloColor ("Hologram Color", Color) = (0, 0.5, 1, 1)
        _PercentPerShades ("Percent Per Shades", Float) = 0.49
        _MinValue ("Min Value", Float) = 0.3
        _MaxValue ("Max Value", Float) = 1.0
        _Cells ("Cells", Range(0, 100)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" }
        Blend One One
        Pass
        {
            Cull Off
            ZWrite Off
            Tags {"LightMode" = "SRPDefaultUnlit"}
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
            float4 _HoloColor;
            float _PercentPerShades;
            float _MinValue;
            float _MaxValue;
            int _Cells;

            v2f vert (MeshData v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float remap(float In, float2 InMinMax, float2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Calculate light direction
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 normal = normalize(i.normal);
                float dotted = dot(normal, lightDir);

                // Project world position onto the plane
                float2 projUV = i.wPos.xy;

                // Calculate Signed Distance Field (SDF) for circular cutouts
                projUV *= _Cells;
                float2 circleCenter = float2(0.5, 0.5);
                float sdf = distance(frac(projUV), circleCenter) - 0.2; // Adjust radius as needed
                float cutout = step(0, sdf);

                clip(cutout - 0.1); // Clip outside the circle

                // Remap shading based on light direction
                float remappedDot = remap(dotted, float2(-1, 1.0), float2(0, 1));
                float shades = floor(remappedDot / _PercentPerShades);
                float remappedShades = remap(shades, float2(0.0, 1/_PercentPerShades), float2(_MinValue, _MaxValue));

                // Sample the texture
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // Combine hologram color and remapped shading
                fixed4 holoColor = _HoloColor * remappedShades;

                // Apply additive blending
                return holoColor;
            }
            ENDCG
        }
    }
}
