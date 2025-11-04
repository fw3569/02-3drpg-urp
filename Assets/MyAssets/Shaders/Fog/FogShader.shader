Shader "Custom/FogShader" {
  Properties {
    [HideInInspector] [MainTexture] _MainTex("Main Texture", 2D) = "white" {}
    [HideInInspector] _DensityFar("DensityFar", Float) = 0.001
    [HideInInspector] _DensityHeight("DensityHeight", Float) = 0.03
    [HideInInspector] _Color("Color", Color) = (1, 1, 1, 1)
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
      float _DensityFar;
      float _DensityHeight;
      float4 _Color;
    CBUFFER_END
    ENDHLSL
    Pass {
      Blend One One, One Zero
      Name "FogPass"
      Tags {"LightMode" = "FogPass"}
      HLSLPROGRAM
      #include "./FogPass.hlsl"
      ENDHLSL
    }
  }
}
