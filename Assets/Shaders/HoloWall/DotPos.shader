Shader "Custom/PlayerPositionDot"
{
    Properties
    {
        _PlayerPosition ("Player Position", Vector) = (0, 0, 0, 0)
        _TargetPosition ("Target Position", Vector) = (0, 0, 0, 0)

        _DotColor ("Dot Color", Color) = (1, 0, 0, 1)
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
        _DotSize ("Dot Size", Float) = 0.1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            float4 _PlayerPosition;
            float4 _TargetPosition;
            float4 _DotColor;
            float4 _BackgroundColor;
            float _DotSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

           fixed4 frag (v2f i) : SV_Target
            {
                // Calculate distance in XZ plane
                float2 posXZ = i.worldPos.xy;
                float2 playerXZ = _PlayerPosition.xy;
                float distance = length(posXZ - playerXZ); // Ensure radial distance calculation

                // Render the dot based on distance and dot size
                float dotAlpha = smoothstep(_DotSize, _DotSize * 0.9, distance);

                // Interpolate between dot color and background color
                return lerp(_DotColor, _BackgroundColor, dotAlpha);
            }
            ENDCG
        }
    }
}
 