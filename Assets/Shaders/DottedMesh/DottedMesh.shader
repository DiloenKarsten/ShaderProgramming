Shader "Unlit/DottedMesh"
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
        Cull Back
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 coords = i.uv;
                coords *= 30;

                float2 pointsOnLineSeg = float2(clamp(coords.x,0.5,0.5),0.5);
                float sdf = distance(frac(coords),pointsOnLineSeg)*2-1;
                float Step = step(0,sdf+ 0.2);

                clip(-Step);
        


                //return Step;
                //return float4(frac(coords),0,1);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
               
                return col;
            }
            ENDCG
        }
    }
}
