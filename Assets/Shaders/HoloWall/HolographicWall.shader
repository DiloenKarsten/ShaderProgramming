Shader "Custom/HolographicWall"
{
    Properties
    {
        _TextureHolo ("Texture Hologram", 2D) ="white" {}
        _PlayerPosition ("Player Position", Vector) = (0,0,0,0)
        _RevealDistance ("Reveal Distance", Float) = 10.0
        _FadeRange ("Fade Range", Float) = 2.0
        _BaseColor ("Base Color", Color) = (0.0, 0.7, 1.0, 1.0)
      
    
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        // Standard Setup for transparent material it multiplies the output by the sources alpha which is zero
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        
       
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

             #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            float4 _PlayerPosition;
            float _RevealDistance;
            float _FadeRange;
            float _HexScale;
            float4 _BaseColor;
            float _HexStepMax;
            float _HexStepMin;
            sampler2D _TextureHolo;
            float4 _TextureHolo_ST;
            
            

            // Vertex shader
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _TextureHolo);
                return o;
            }

          

            // Lerp visibility based on distance
            float lerpVisibility(float distance, float revealDist, float fadeRange)
            {
                return smoothstep(revealDist + fadeRange, revealDist, distance);
            }

            // Fragment shader
            fixed4 frag (v2f i) : SV_Target
            {
                 fixed4 col = tex2D(_TextureHolo, i.uv);
                // Calculate distance from player to wall
                float distance = length(i.worldPos - _PlayerPosition.xyz);

                // Calculate visibility based on distance
                float visibility = lerpVisibility(distance, _RevealDistance, _FadeRange);

                // Set the color and transparency
                return float4(col.rgb, visibility);
            }
            ENDCG
        }
    }
    FallBack "Transparent"
}
