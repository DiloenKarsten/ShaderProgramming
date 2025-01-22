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

            float3 createRectangle(float width,float height,float2 uv)
            {
                
                float2 bl = step(float2(width,height),uv);
                float2 tr = step(float2(width,height),1-uv);
                float pct =bl.x*bl.y*tr.x*tr.y;

                return float3(pct,pct,pct);
            }

            float createCircle(float radius,float smoothness, float2 uv)
            {
                float2 origin = float2(0.5,0.5);
                float pct = distance(uv,origin)*2;
                return smoothstep(radius,radius*smoothness,pct);
            }
            

            fixed4 frag (v2f i) : SV_Target
            {
                float2 st = i.uv;
                
                                   
                float3 color = float3(0,0,0);
                

                float3 rectangle = createRectangle(0.04,0.1,st);
                float3 circle = createCircle(0.3,1,st);
                
                
                // Plot the plot onto the color gradient
                color = circle;
                
              
                return float4(color,1);
            }
            ENDCG
        }
    }
}
