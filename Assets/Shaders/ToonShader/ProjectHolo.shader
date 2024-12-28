Shader "Custom/InvisibleStencil"
{
    Properties
    {
        _StencilValue ("Stencil Value", Float) = 1
        _Color ("Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            // Stencil setup
            Stencil
            {
                Ref [_StencilValue] // Reference value to write
                Comp Always         // Always pass stencil test
                Pass Replace        // Replace the stencil value with Ref
            }

            // Skip writing to the color buffer
            ColorMask 0 // Prevents any color output (R, G, B, or A)
            ZWrite On  // Optional: Disable depth writes for extra performance

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION;
            };
            float4 _Color;
            v2f vert (appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(0,0,0,0); // Color is irrelevant because of ColorMask 0
            }
            ENDCG
        }
    }
}
