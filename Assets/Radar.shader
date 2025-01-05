Shader "Unlit/Radar"
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
                float2 uv : TEXCOORD0; //Static Elements
                float2 uv1 : TEXCOORD1; // Rotating elements
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
            
             float createCircle(float radius,float smoothness, float2 uv)
            {
                float2 origin = float2(sin(_Time).x*0.5,sin(_Time).y*0.2);
                float pct = distance(uv,origin)*2;
                return smoothstep(radius,radius*smoothness,pct);
            }

             float3 createRectangle(float width,float height,float2 uv)
            {
                
                float2 bl = step(float2(width,height),uv);
                float2 tr = step(float2(width,height),1-uv);
                float pct =bl.x*bl.y*tr.x*tr.y;

                return float3(pct,pct,pct);
            }
            
            float4 rotate2d(float _angle){
            return float4(cos(_angle),-sin(_angle),
                        sin(_angle),cos(_angle));
            }
            
            float movingLine(float2 uv, float2 center, float radius)
            {
                //angle of the line
                float PI = 3.1415926535897932384626433832795;
                
                float2 d = uv - center;
                float r = distance(d,0);
                if(r<radius)
                {
                     float theta = _Time*90*20;
                    float2 p = radius*float2(cos(theta*PI/180),
                                       -sin(theta*PI/180));
                    float l= length( d - p*clamp( dot(d,p)/dot(p,p), 0.0, 1) );
                   
                    float theta1 = fmod(180.0*atan2(d.y,d.x)/PI+theta,360.0);
                    float gradient = clamp(1.0-theta1/45.0,0.0,1.0);
                    return step(l,0.005)+0.5*gradient;
                }
                else
                {
                    return 0;
                }
                 
            }

            float circle(float2 uv, float2 center, float radius, float width)
            {
                float2 d = uv - center;
                 float r = distance(d,0);
                 
                return  step(r-width/2,radius)-step(r+width/2,radius);
                
            }
            
            float circle2(float2 uv, float2 center, float radius, float width, float opening)
            {
                float2 d = uv - center;
                float r = distance(d,0);
                d = normalize(d);
                 // places the opening horizontally if d.x they are placed vertically
                if( abs(d.y) > opening )
	                return step(r-width/2,radius)-step(r+width/2.0,radius);
                else
                    return 0.0;
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
                        box(_st, float2(_size/100.,_size));
            }
            float bip2(float2 uv, float2 center)
            {
                float r = length(uv - center);
                float R = 8.0+fmod(87.0*_Time, 80.0);
                return (0.5-0.5*cos(30.0*_Time)) * step(r,5.0)
                    + step(6.0,r)-step(8.0,r)
                    + smoothstep(max(8.0,R-20.0),R,r)-step(R,r);
            }
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv*2-1;
                o.uv1 = v.uv1;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 st = i.uv1;
               
                float3 color = float3(0,0,0);
                
            
             

                color = (0,0,0);
                
                
                
                float center = float2(0,0);
                float _Cross = _cross(st,0.6);
                color= float3(0.3*_Cross,0.3*_Cross,0.3*_Cross);
                
                color+= circle2(i.uv,center,0.7,0.005,0.5-0.2*cos(_Time.y));
                color+= (circle(i.uv,center,0.03,0.005)+
                    circle(i.uv,center,0.2,0.005)+
                    circle(i.uv,center,0.4,0.005))*float3(0.5,0.75,1.00);
                color+= circle(i.uv,center,0.6,0.01);
                color+=movingLine(i.uv,center,0.6)*float3(0.5,0.75,1.00);
                color+=(1-createCircle(0.1,1,st*2-1))*float3(1,0.5,0.2);
                
               
          
                
                
                return fixed4(color,1);
                //return fixed4(OuterRing,OuterRing,map+OuterRing,0.5);
            }
            ENDCG
        }
    }
}
