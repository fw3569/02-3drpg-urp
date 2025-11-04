Shader "Custom/VolumeLightShader" {
  Properties {
    [HideInInspector] [MainTexture] _MainTex("Main Texture", 2D) = "white" {}
    [HideInInspector] _Intensity("Intensity", Float) = 5
    [HideInInspector] _MieScattering("MieScattering", Range(0, 1)) = 0.5
    [HideInInspector] _ExtingctionFactor("ExtingctionFactor", Float) = 0.5
    [HideInInspector] _BlurStep("BlurStep", int) = 1
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    CBUFFER_START(UnityPerMaterial)
      float _Intensity;
      float _MieScattering;
      float _ExtingctionFactor;
      float4 _MainTex_TexelSize;
      int _BlurStep;
    CBUFFER_END
    ENDHLSL
    Pass {
      Blend Off
      Name "VolumeLightMarchingPass"
      Tags {"LightMode" = "VolumeLightMarchingPass"}
      HLSLPROGRAM
      #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
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
      Blend One One, One Zero
      // Blend Off
      Name "VolumeLightBlendgPass"
      Tags {"LightMode" = "VolumeLightBlendPass"}
      HLSLPROGRAM
      #include "./VolumeLightBlendPass.hlsl"
      ENDHLSL
    }
  }
}
