Shader "Custom/SimpleTransparentShader" {
  Properties {
    [KeywordEnum(Off, Front, Back)] _Cull("Cull Mode", Float) = 2.0
  }
  SubShader {
    Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "DisableBatching"="False"}
    ZTest On
    ZWrite On
    BlendOp Add
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    Cull [_Cull]
    LOD 200
    HLSLINCLUDE
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    CBUFFER_START(UnityPerMaterial)
    CBUFFER_END
    ENDHLSL
    Pass {
      Name "Forward"
      Tags {"LightMode" = "UniversalForward"}
      HLSLPROGRAM
      struct Attributes {
        float4 positionOS : POSITION;
        float4 color      : Color;
      };
      struct Varyings {
        float4 positionCS : SV_POSITION;
        float4 color      : Color;
      };

      Varyings Vert(Attributes input) {
        Varyings output;
        output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
        output.color = input.color;
        return output;
      }
      half4 Frag(Varyings input) : SV_Target0 {
        return input.color;
      }
      ENDHLSL
    }
  }
}
