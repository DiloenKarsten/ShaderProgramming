Shader"Unlit/Disolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff ("Displacement slider", float) = 1
        _NoiseScale ("Noise Scale", float) = 5
        _NoiseWidth ("Noise Width", float) = 1
        
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"  }
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define TAU 6.28318530718

            float random(float2 uv)
            {
                return frac(sin(dot(uv,float2(12.9898, 78.233))) * 43758.5453);
            }

            float noise (float2 uv)
            {
                float2 i =floor(uv);
                float2 f =frac(uv);

                float a = random(i);
                float b = random(i + float2(1.000,0.000));
                float c = random(i + float2(0.0, 1.0));
                float d = random(i + float2(1.0, 1.0));

                float2 u = smoothstep(0.,1.,f);

                return lerp(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
            }
                   
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2; // World position for noise stability
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;
            float _NoiseScale;
            float _NoiseWidth;

               float2 rotate2d(float2 uv, float _angle)
            {
                uv -=0.5;
                float2x3 rMatrix = float2x3(cos(_angle),-sin(_angle),1,
                       sin(_angle),cos(_angle),1);
                 uv = mul(uv,rMatrix);
                uv+=0.5;
                 return float2(uv.x,uv.y);
            }
            float sdfSphere(float3 p)
            {
             return length(p)-1;   
            }
           

             float GetWave( float2 uv ) {
                 
                float2 uvsCentered = uv*2-1 ; 
                float radialDistance = length( uvsCentered );
                 //længde til centrum - tid for at ripple i korrekt retning 
                float wave = sin( (-radialDistance + _Time.y * 0.1) * TAU * 5) * 0.1 + 0.5;
                wave *= 1-radialDistance;
                return wave;
            }
            
            v2f vert (appdata v)
            {
                
                v2f o;
                   
                 v.vertex.xy =float2(sin(10*v.vertex.x),sin(10*v.vertex.y));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float2 pos = float2(i.uv*_NoiseScale);
                pos = noise(pos) *_NoiseWidth;

                //Direction it dissolves in
                pos += i.worldPos.y;
                float dissolve = step(_Cutoff,pos);
                fixed4 col = tex2D(_MainTex, i.uv);
             
                return fixed4(GetWave(i.uv)+i.uv,0,dissolve);
            }
            ENDCG
        }
    }
}
