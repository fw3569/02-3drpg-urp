Shader "Custom/VolumeLightShader" {
  Properties {
    [HideInInspector] [MainTexture] _MainTex("Main Texture", 2D) = "white" {}
    [HideInInspector] _Intensity("Intensity", Float) = 1
    [HideInInspector] _MieScattering("MieScattering", Range(0, 1)) = 0.5
    [HideInInspector] _ExtingctionFactor("ExtingctionFactor", Float) = 0.5
    [HideInInspector] _BlurStep("BlurStep", int) = 1
    [HideInInspector] _Deviation("Bilateral filter standard deviation", Float) = 0.01
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
      float4 _MainTex_TexelSize;
      half _Intensity;
      half _MieScattering;
      half _ExtingctionFactor;
      half _Deviation;
      int _BlurStep;
    CBUFFER_END
    ENDHLSL
    Pass {
      Blend Off
      Name "VolumeLightMarchingPass"
      Tags {"LightMode" = "VolumeLightMarchingPass"}
      HLSLPROGRAM
      #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
      #include "./VolumeLightMarchingPass.hlsl"
      ENDHLSL
    }
    Pass {
      Blend Off
      Name "VolumeLightBlurPass"
      Tags {"LightMode" = "VolumeLightBlurPass"}
      HLSLPROGRAM
      #include "./VolumeLightBlurPass.hlsl"
      ENDHLSL
    }
    Pass {
      Blend One One
      Name "VolumeLightBlendgPass"
      Tags {"LightMode" = "VolumeLightBlendPass"}
      HLSLPROGRAM
      #define BLEND_ON
      #include "./VolumeLightBlurPass.hlsl"
      ENDHLSL
    }
  }
}
