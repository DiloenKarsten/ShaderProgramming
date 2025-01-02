Shader "Unlit/Colors"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Color 1", Color) = (1,0,0,1)
        _Color2 ("Color 2", Color) = (0,0,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                float2 uv : TEXCOORD0;
               
                float4 vertex : SV_POSITION;
            };

            float4 _Color1;
            float4 _Color2;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            float easeInElastic (float x)
            {
                float con4 = (2*3.14)/3;
                return -pow(2,10*x-10)*sin((x*10-10,75)*con4);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 color = float3(0,0,0);

                float pct = abs(sin(_Time.y));

                color = lerp(_Color1.rgb,_Color2.rgb,easeInElastic(pct));
                
              
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
