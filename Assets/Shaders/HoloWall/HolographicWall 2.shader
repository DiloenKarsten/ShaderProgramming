Shader "Custom/HolographicWall1"
{
    Properties
    {
        _PlayerPosition ("Player Position", Vector) = (0,0,0,0) // can be removed
        
        [Header (Transparency)]
        _RevealDistance ("Reveal Distance", Float) = 10.0
        _FadeStrength ("Fade Strength", Float) = 10.0
       
        [Header (Color Gradient)]
        _NearColor ("Close Color", Color) = (0.0, 0.7, 1.0, 1.0)
        _FarColor ("Distant Color", Color) = (0.0, 0.7, 1.0, 1.0)
        
        [Header (Hex Modifiers)]
        _HexScale ("HexScale", Range(0,100)) = 100
        _HexMultiplier ("Hex Multiplier",Range(0,1)) =1
        _maxGrowth ("Max Hex Size",Range(0,1)) =0.5
        _HexesprRow ("HexProw",Int) =1
        _HexRows ("HexRows",Int) =1
    
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

            float _RevealDistance;
            float _FadeStrength;
            
            float4 _NearColor;
            float4 _FarColor;
            
            float _HexScale;
            int  _HexesprRow;
            float _HexMultiplier;
            int _HexRows;
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

            float2 ProjectedUV(float3 worldPos)
            {
                 float3 playerWorldPos = _PlayerPosition.xyz;

                // Project player position onto plane
                float3 planeNormal = float3(0, 0,1);
                float3 pointOnPlane = playerWorldPos - dot(playerWorldPos - worldPos, planeNormal) * planeNormal;

                // Transform point to object space
                float3 pointInObjectSpace = mul(unity_WorldToObject, float4(pointOnPlane, 1.0)).xyz;

                // Fit projected point to the planes uv
                float2 worldToUVScale = float2(10.0, 10.0); //Currently adjust til appropriate

                //1 - uv since it is inverted at some point 
                return  1-float2(
                    (pointInObjectSpace.x + worldToUVScale.x * 0.5) / worldToUVScale.x, // Normalize and center
                    (pointInObjectSpace.z + worldToUVScale.y * 0.5) / worldToUVScale.y  
                );
            }

              float lerpVisibility(float distance, float revealDist, float fadeRange)
            {
                return smoothstep(revealDist + fadeRange, revealDist, distance);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Project Player Position
                float2 p_uv =ProjectedUV(i.worldPos); 

                //Get z Distance since it is independent of uv placement
                float zDistance = max(distance(i.worldPos.z,_PlayerPosition.z),_maxGrowth*8);

                // Hex grid logic making it scalable 
                float horizontalOffset = 0.2 * saturate(_HexMultiplier);      
                float verticalOffset = 0.056 * saturate(_HexMultiplier);   

                //Empty color vector colored in by hexes in loop
                float1 visibility = 0;
                float4 color = (0,0,0,visibility);
           
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
                        
                        distanceToHex*=zDistance;
                        float hex = hexagon(i.uv, hexCenter, distanceToHex * _HexScale);

                        //Invert hex to color it
                        hex = 1-hex;
                        
                    if (hex > 0.0 )
                    {
                        color = lerp(_NearColor, _FarColor,distanceToHex*3);
                        visibility = lerpVisibility(_RevealDistance,-distanceToHex,_FadeStrength);
                    }
                        
                        // Debug: Mark hex centers in red
                       // if (distance(i.uv, hexCenter) < 0.01) {
                        //    return fixed4(1.0, 0.0, 0.0, 1.0); // Red highlight for hex centers
                        //}
                    }
                }
        
                return fixed4(color.rgb,visibility*0.6);
            }


            ENDCG
        }
    }
    FallBack "Transparent"
}
