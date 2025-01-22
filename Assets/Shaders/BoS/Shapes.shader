Shader "Unlit/Shapes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float Pi = 3.14;

            float plot(float2 st)
            {
                return smoothstep(0.02,0.0, abs(st.y - st.x));
                
            }

              float plotExp(float2 st, float pct)
            {
                return smoothstep( pct-0.02, pct, st.y) -
                    smoothstep( pct, pct+0.02, st.y);
                
            }
            
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 st = i.uv/1;
                
                
                // set to 1 for linear curve
                float yExp = pow(st.x,2);
                float yStep = step(0.5,st.x);
                float ySmoothStep =smoothstep(0.01,0.8,st.x);
                float Y = ySmoothStep;
                
                    
                
                float3 color = float3(Y,Y,Y);
                
                float pct = plotExp(st,Y);

                // Plot the plot onto the color gradient
                color = (1-pct)*color+pct*float3(0,1,0);
                
              
                return float4(color,1);
            }
            ENDCG
        }
    }
}
