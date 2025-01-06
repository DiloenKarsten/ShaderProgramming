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
            float d = 0;
            float3 color = float3(0,0,0);

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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex)*2-1;
                
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
            float box(in float2 _st, in float2 _size){
                _size = float2(0.5,0.5) - _size*0.5;
                float2 uv = smoothstep(_size,
                                    _size+float2(0.001,0.001),
                                    _st);
                uv *= smoothstep(_size,
                                _size+float2(0.001,0.001),
                                float2(1.0,1.0)-_st);
                return uv.x*uv.y;
            }

            float _cross(in float2 _st, float _size){
                return  box(_st, float2(_size,_size/100.)) +
                        box(_st, float2(_size/4.,_size));
            }
            

            fixed4 frag (v2f i) : SV_Target
            {
                float2 st = i.uv;

                float crosus=_cross(st,1);

                float2 pos = float2(.1,0)-st;

                float dist = distance(pos,st-float2(0.1,0.));
                dist = step(min(0.2,abs(sin(0.1+_Time.y))),dist);
                
                float r = length(pos);
                float a = atan2(pos.y,pos.x);

                float f = cos(a*3.);
                f =abs(cos(a*12.)*sin(a*3.856+_Time.y))*3.312+0.036;

                color = float3(step(f,r)*step(r*0.096,f*0.694),step(f,r)*step(r*0.096,f*0.694),step(f,r)*step(r*0.096,f*0.694));
                //color = float3(1-smoothstep(f,f+0.02,r),1-smoothstep(f,f+0.02,r),1-smoothstep(f,f+0.02,r));
                color = color*float3(0.,1.,.2) + ((1.-color)*float3(0.,0,1));

                d = length(abs(st)-.3);
                d = length( min(abs(st)-.4,0.));
                d = length( max(abs(st)-.4,0.));
                

                float3 rectangle = createRectangle(0.04,0.1,st);
                float3 circle = createCircle(0.3,1,st);
                
                float3 SDF = float3(frac(d*10),frac(d*10),frac(d*10));

                //Draw the SDF
                SDF = step(0.2,d);
                //Draw the sdf outline
                SDF = step(0.2,d)*step(d,0.3);
               
                //Draw SDF outline with smooth corners
                //SDF = smoothstep(0.3,.4,d)*smoothstep(d,.6,0.5);
            
                // Plot the plot onto the color gradient
                //color = circle;

                float3 timeHype =float3(color*dist);
                if (timeHype.r==0&timeHype.g==0&timeHype.b==0)
                {
                    timeHype.rgb=1;
                }
                
              
                return float4(timeHype,1);
            }
            ENDCG
        }
    }
}
