Shader "Unlit/HealthBar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HealthSlider ("HealthBar Slider", Range(0,1)) = 1
        _StartColor("Healthy Color", Color)=(0,1,0,1)
        _EndColor("Injured Color", Color)=(1,0,0,1)
    }
    SubShader
    {
  

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HealthSlider;
            float4 _StartColor;
            float4 _EndColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

             float remap(float In, float2 InMinMax, float2 OutMinMax) {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            float inverseLerp(float A, float B, float T)
            {
                return  (T - A)/(B - A);
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float tHealthColor = inverseLerp(0.2,0.8,_HealthSlider);

                float3 healthbarColor = lerp(_EndColor,_StartColor, tHealthColor);
                float3 bgColor = float3(0,0,0);

                

                float healthbarMask = _HealthSlider > i.uv.x;
                clip(healthbarMask-0.001);
                //float healthbarMask = _HealthSlider > floor(i.uv.x*8)/8;

                float3 outColor = lerp(bgColor, healthbarColor, healthbarMask);

                
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                return float4(outColor,0);
            }
            ENDCG
        }
    }
}
