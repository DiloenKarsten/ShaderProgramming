Shader "Custom/HolographicWall1"
{
    Properties
    {
        _PlayerPosition ("Player Position", Vector) = (0,0,0,0)
        _FadeRange ("Fade Range", Range(0,100)) = 0
        _BaseColor ("Base Color", Color) = (0.0, 0.7, 1.0, 1.0)
        _SecondColor ("Base Color", Color) = (0.0, 0.7, 1.0, 1.0)
        
        _HexesprRow ("HexProw",Int) =1
        _HexRows ("HexRows",Int) =1
        _HexMultiplier ("Hex Multiplier",Range(0,1)) =1
        _xPoint ("X Point",Range(0,1)) =0.5
        _yPoint ("Y Point",Range(0,1)) =0.5
        _maxGrowth ("Max Hex Size",Range(0,1)) =0.5
    
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
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
                float3 localPos : TEXCOORD2;
            };

            float4 _PlayerPosition;
            float _FadeRange;
            float _HexScale;
            float4 _BaseColor;
            float4 _SecondColor;
            int  _HexesprRow;
            float _HexMultiplier;
            int _HexRows;
            float _xPoint;
            float _yPoint;
            float _maxGrowth;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex.xyz;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }

            float3 hexagon(float2 uv, float2 center, float scale)
            {
                int N = 6; // Number of edges for the hexagon
                float pi = 3.14159265359;
                
                float2 r = center - uv;
                r *= scale;

                float a = atan2(r.x, r.y);
                float b = pi * 2 / N;

                return smoothstep(0.5, 0.51, cos(floor(0.5 + a / b) * b - a) * length(r));
            }

            

            fixed4 frag(v2f i) : SV_Target
            {
            
                float3 playerWorldPos = _PlayerPosition.xyz;

                // Project player position onto plane
                float3 planeNormal = float3(0, 0,1);
                float3 pointOnPlane = playerWorldPos - dot(playerWorldPos - i.worldPos, planeNormal) * planeNormal;

                // Transform point to object space
                float3 pointInObjectSpace = mul(unity_WorldToObject, float4(pointOnPlane, 1.0)).xyz;

                // Fit projected point to the planes uv
                float2 worldToUVScale = float2(10.0, 10.0); //Currently adjust til appropriate

                //1 - uv since it is inverted at some point 
                float2 p_uv = 1-float2(
                    (pointInObjectSpace.x + worldToUVScale.x * 0.5) / worldToUVScale.x, // Normalize and center
                    (pointInObjectSpace.z + worldToUVScale.y * 0.5) / worldToUVScale.y  
                );
                
                // Hex grid logic
                float horizontalOffset = 0.2 * saturate(_HexMultiplier);      
                float verticalOffset = 0.056 * saturate(_HexMultiplier);   

                
                float4 color = (0,0,0,0);
           
                for (int y = 0; y <= _HexRows; y++)
                {
                    float rowY = y * verticalOffset;

                    for (int x = 0; x <= _HexesprRow; x++)
                    {
                        float offsetX = (y % 2 == 0) ? 0.0 : horizontalOffset * 0.5;

                        // Calculate hexagon center in UV space
                        float2 hexCenter = float2(
                            x * horizontalOffset + offsetX,
                            rowY
                        );

                        // Measure distance in UV space
                        float distanceToHex = max(distance(hexCenter, p_uv), _maxGrowth); // Ensure a minimum distance
                        //float zDistance = max(distance(i.worldPos.z,_PlayerPosition.z),_maxGrowth*8);
                        //distanceToHex*=zDistance;
                        float hex = hexagon(i.uv, hexCenter, distanceToHex * _FadeRange);

                        //Invert hex to color it
                        hex = 1-hex;
                        
                    if (hex > 0.0 )
                    {
                        color = lerp(_BaseColor, _SecondColor,distanceToHex*3);
                        
                    }
                        
                        // Debug: Mark hex centers in red
                       // if (distance(i.uv, hexCenter) < 0.01) {
                        //    return fixed4(1.0, 0.0, 0.0, 1.0); // Red highlight for hex centers
                        //}
                    }
                }
        

                
                
                
               
                // Return the final result
                 //return fixed4(color * hexCutout, hexCutout);
                return fixed4(color*float4(1,1,1,1));
            }


            ENDCG
        }
    }
    FallBack "Transparent"
}
