Shader "Custom/BloomShader" {
  Properties {
    [HideInInspector] [MainTexture] _MainTex("Main Texture", 2D) = "white" {}
    [HideInInspector] _MipLevel("Main Texture Mip Level", int) = 0
    [HideInInspector] _BloomThreshold("Bloom Threshold", Range(0, 1)) = 1.0
    [HideInInspector] _BloomIntensity("Bloom Intensity", Range(0, 1)) = 1.0
    // [HideInInspector] [KeywordEnum(BLUR_X, BLUR_Y)] _BlurType("Blur Type", Float) = 0
  }
  SubShader {
    Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Overlay" "Queue"="Overlay" "DisableBatching"="False"}
    ZTest Off
    ZWrite Off
    Cull Off
    LOD 100
    HLSLINCLUDE
    #pragma target 4.0
    #pragma vertex Vert
    #pragma fragment Frag
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    CBUFFER_START(UnityPerMaterial)
      int _MipLevel;
      float _BloomThreshold;
      float _BloomIntensity;
    CBUFFER_END
    ENDHLSL
    Pass {
      Blend Off
      // TBD Also need blur in downsample to avoid flicker
      Name "BloomDownsamplePass"
      Tags {"LightMode" = "BloomDownsamplePass"}
      HLSLPROGRAM
      #include "./BloomDownsamplePass.hlsl"
      ENDHLSL
    }
    Pass {
      Blend Off
      Name "BloomBlurPass"
      Tags {"LightMode" = "BloomBlurPass"}
      HLSLPROGRAM
      #pragma shader_feature_fragment BLUR_X BLUR_Y
      #include "./BloomBlurPass.hlsl"
      ENDHLSL
    }
    Pass {
      Blend One One
      Name "BloomUpsamplePass"
      Tags {"LightMode" = "BloomUpsamplePass"}
      HLSLPROGRAM
      #include "./BloomUpsamplePass.hlsl"
      ENDHLSL
    }
  }
}
