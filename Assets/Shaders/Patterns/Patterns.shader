Shader "Unlit/Radar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) ="bump" {}
        _HeightMap ("Normal Map", 2D) ="gray" {}
         _Angle ("Angle", float) = 0
        _GlassSeed ("GlassSeed", float) =12
        _BumpStrength ("Bump Strength", Range(0,1)) =0.5
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
        
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

   

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL; // XYZ = Tangent direction, W = tangent direction
                float4 tangent: TANGENT; // XYZ = Tangent direction, W = tangent direction 
                float2 uv : TEXCOORD0; //Static Elements
                float2 uv1 : TEXCOORD1; // Rotating elements
                float4 lightDir:POSITION;
     
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normal :TEXCOORD5;
                float3 tangent: TEXCOORD2;
                float3 bitangent: TEXCOORD3;
                float4 vertex : SV_POSITION;
                float3 lightDir:TEXCOORD4;
            };


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

            float2 offset(float2 _st){
                float2 uv;

                if(_st.x>0.5){
                    uv.x = _st.x - 1.5;
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
            float3 NormalMap (float2 uv, float3 tangent, float3 bitangent, float3 normal,
                sampler2D _NormalMap, float _BumpStrength)
             {
                 float3 tangentSpaceNormal = UnpackNormal(tex2D(_NormalMap,uv));
                tangentSpaceNormal = normalize(lerp(float3(0,1,0),tangentSpaceNormal,_BumpStrength));

                float3x3 mtxTangToWorld={
                tangent.x,bitangent.x,normal.x,
                tangent.y,bitangent.y,normal.y,
                tangent.z,bitangent.z,normal.z,
                };
                 //return the Normals 
                return  mul(mtxTangToWorld,tangentSpaceNormal);
             }
            float LambertianLighting(float3 N)
             {
                 
                    float3 worldNormal = normalize(N)*-1; // Assuming normal is already in world space
                    float3 L = normalize(_WorldSpaceLightPos0.xyz); // Light direction in world space
                    return  max(0, dot(worldNormal, L)); // Lambertian lighting calculation
             }

            
            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _HeightMap;
            float4 _MainTex_ST;
            float _Angle;
            float _GlassSeed;
            float _BumpStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityWorldToObjectDir(v.normal);
                o.tangent = UnityWorldToObjectDir(v.tangent.xyz);
                o.bitangent = cross(o.normal,o.tangent);
                o.bitangent*=v.tangent.w*unity_WorldTransformParams.w;
                 o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
                o.uv = v.uv;
                o.uv1 = v.uv1;
                return o;
            }

           fixed4 frag(v2f i) : SV_Target
            {
                float2 st = i.uv;     // UV coordinates
                float2 st1 = i.uv1;   // Secondary UVs if needed for offset
                float2 st2 =i.uv;
               
                st=offset(st);
                float3 color = float3(0, 0, 0); // Base color
                float3 color1 = float3(0, 0, 0); // Base color
                 st*=float2(6,6/2);
                st1*=6;
                st1=offset(st1);
                
                float3 N = NormalMap(i.uv,i.tangent,i.bitangent,i.normal,_NormalMap,_BumpStrength);
               

                
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
                //return fixed4(N,1);
                return fixed4(color*LambertianLighting(N),1);
            }

            ENDCG
        }
    }
}
