Shader "Unlit/Radar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
         _Angle ("Angle", float) = 0
        _GlassSeed ("GlassSeed", float) =12
        _NormalMap ("Normal Map", 2D) ="bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
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
            
            float2 rotate2d(float2 uv, float _angle)
            {
                uv -=0.5;
                float2x3 rMatrix = float2x3(cos(_angle),-sin(_angle),1,
                       sin(_angle),cos(_angle),1);
                 uv = mul(uv,rMatrix);
                uv+=0.5;
                 return float2(uv.x,uv.y);
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


            float2 offset(float2 _st){
                float2 uv;

                if(_st.x>0.5){
                    uv.x = _st.x - 0.5;
                } else {
                    uv.x = _st.x + 0.5;
                }

                if(_st.y>0.5){
                    uv.y = _st.y - 2.5;
                } else {
                    uv.y = _st.y + 1.5;
                }

                return uv;
            }
            float CreateGrid(float2 uv,float seed)
             {
                          // Scale UVs to match the grid size
            float2 gridUV = uv ; // Adjust "6.0" to match your grid density
          
            float2 gridCell = floor(gridUV); // Identify the grid cell

            // Generate a unique ID for the grid cell
            float cellID = gridCell.x + gridCell.y * 100.0; // Combine X and Y for unique ID (adjust scale as needed)

            // Generate a random value for the grid cell (simple hash function)
            //float randomValue = frac(sin(cellID * 12.9898) * 43758.5453123);
            return clamp(frac(sin(cellID * seed) * 43758.5453123),0.01,1);
             }
            float3 RandomColor(float randomValue)
             {
                 return float3(
                    frac(randomValue * 2.3), // R
                    frac(randomValue * 3.7), // G
                    frac(randomValue * 5.1));  // B
             }
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Angle;
            float _GlassSeed;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv1 = v.uv1;
                return o;
            }

           fixed4 frag(v2f i) : SV_Target
{
    float2 st = i.uv;     // UV coordinates
    float2 st1 = i.uv1;   // Secondary UVs if needed for offset
   
    st=offset(st);
    float3 color = float3(0, 0, 0); // Base color
    float3 color1 = float3(0, 0, 0); // Base color
     st*=float2(6,6/2);
    st1*=6;
    st1=offset(st1);

   
   

    float randomValue = CreateGrid(st,_GlassSeed);
    float randomValue1 = CreateGrid(st1,_GlassSeed);
 
  
    st = frac(st); // Match the grid density to "6.0"
    st1 = frac(st1);
     st1= rotate2d(st1,_Angle);

    
    

    // Render rectangles with the random color
    
    if (st.y<0.1|| st.y > 0.6)
    {
        color1=createRectangle(0.35,0.35,st1);
        
    }
    
    color1 = step(color1,0);
    
    color += createRectangle(0.02, 0.01, st) * RandomColor(randomValue);
    color *=color1;
    
    
     if (st.y<0.1|| st.y > 0.6)
    {
          color +=max(0,(2*createRectangle(0.4,0.4,st1))*RandomColor(randomValue1));
        
    }
  

   

    // Return the final color
    return fixed4(color, 1.0);
}

            ENDCG
        }
    }
}
