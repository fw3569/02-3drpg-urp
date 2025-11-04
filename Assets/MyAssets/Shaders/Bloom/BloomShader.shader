Shader "Custom/BloomShader" {
  Properties {
    [HideInInspector] [MainTexture] _MainTex("Main Texture", 2D) = "white" {}
    [HideInInspector] _MipLevel("Main Texture Mip Level", int) = 0
    [HideInInspector] _BloomThreshold("Bloom Threshold", Range(0, 1)) = 1.0
    [HideInInspector] _BloomIntensity("Bloom Intensity", Range(0, 1)) = 1.0
    [HideInInspector] [KeywordEnum(All, Step0, Step1)] _BlurType("Blur Type", int) = 0
  }
  SubShader {
    Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Overlay" "Queue"="Overlay" "DisableBatching"="False"}
    ZTest Off
    ZWrite Off
    Cull Off
    LOD 100
    HLSLINCLUDE
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    CBUFFER_START(UnityPerMaterial)
      float _MipLevel;
      float _BloomThreshold;
      float _BloomIntensity;
      int _BlurType;
    CBUFFER_END
    ENDHLSL
    Pass {
      Blend Off
      Name "BloomDownsamplePass"
      Tags {"LightMode" = "BloomDownsamplePass"}
      HLSLPROGRAM
      #include "./BloomDownsamplePass.hlsl"
      ENDHLSL
    }
    Pass {
      Blend One One, One Zero
      Name "BloomUpsamplePass"
      Tags {"LightMode" = "BloomUpsamplePass"}
      HLSLPROGRAM
      #include "./BloomUpsamplePass.hlsl"
      ENDHLSL
    }
    Pass {
      Blend Off
      Name "BloomUpsamplePass2"
      Tags {"LightMode" = "BloomUpsamplePass"}
      HLSLPROGRAM
      #include "./BloomUpsamplePass.hlsl"
      ENDHLSL
    }
  }
}
