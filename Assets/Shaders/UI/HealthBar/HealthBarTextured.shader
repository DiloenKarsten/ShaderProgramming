Shader "Unlit/HealthBar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HealthSlider ("HealthBar Slider", Range(0,1)) = 1
        _BorderWidth ("Border Width", Range(0,1)) = 1
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
            float _BorderWidth;
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
            float RoundedRectangle(float2 UV, float Width, float Height, float Radius)
            {
                Radius = max(min(min(abs(Radius * 2), abs(Width)), abs(Height)), 1e-5);
                float2 uv = abs(UV * 2 - 1) - float2(Width, Height) + Radius; //Absolute tager i begge sider så der kan anvendes abs(inverseLerp) til at lave mere præcis rundet firkant.
                float d = length(max(0, uv)) / Radius;
                return saturate((1 - d) / fwidth(d));
            }

            fixed4 frag (v2f i) : SV_Target
            {


                float2 coords = i.uv;
                coords.x *= 8; //Scale bredde siden y scale er 0.125

                float2 pointsOnLineSeg = float2(clamp(coords.x,0.5,7.5),0.5);
                float sdf = distance(coords,pointsOnLineSeg)*2-1;
                clip(-sdf);
                float borderSDF = sdf+_BorderWidth;

                float pd = fwidth(borderSDF);

               //float borderMask = step(0,-borderSDF);
                float borderMask = 1-saturate(borderSDF/pd);
                float healthbarMask = _HealthSlider > i.uv.x;
               
                
                fixed3 healthbarColor = tex2D(_MainTex, float2(_HealthSlider, i.uv.y));
                //float healthbarMask = _HealthSlider > floor(i.uv.x*8)/8;
               if(_HealthSlider < 0.2){
                float flash = cos(_Time.y *4) * 0.3 + 1;
                healthbarColor *= flash;
               }
          
                //return float4(sdf.xxx,1);

                //return float4(borderMask.xxx,1); 
                
                // sample the texture
                
                return float4(healthbarColor*healthbarMask*borderMask,1);
                //return col;

            }
            ENDCG
        }
    }
}
