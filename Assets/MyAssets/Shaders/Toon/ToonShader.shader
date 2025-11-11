Shader "Custom/ToonShader" {
  Properties {
    [Toggle(_Toon)] _Toon("Toon", int) = 0
    [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
    _Specular("Specular", Range(0, 1)) = 0.0
    _Metallic("Metallic", Range(0, 1)) = 0.0
    _Smoothness("Smoothness", Range(0, 1)) = 0.0
    [ToggleUI] _AlphaClip("Enable Alpha Clip", Float) = 1
    _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
    [KeywordEnum(Off, Front, Back)] _Cull("Cull Mode", Float) = 2.0
    _LightThreshold0("Light Threshold0", Range(-1, 1)) = 0.2
    _LightThreshold1("Light Threshold1", Range(-1, 1)) =-0.3
    _LightingIntensity0("Lighting Intensity0", Range(0, 1)) = 0.5
    _LightingIntensity1("Lighting Intensity1", Range(0, 1)) = 0.2
    _ToonSmoothness("Toon Smoothness", Range(0, 1)) = 0.3
    [HideInInspector] _DepthTex("_DepthTex", 2D) = "white" {}
    [HideInInspector] _EdgeThresholdColor("_EdgeThresholdColor", Range(0, 1)) = 0.5
    [HideInInspector] _EdgeThresholdDepth("_EdgeThresholdDepth", Range(0, 1)) = 0.001
    [KeywordEnum(PBR, BlinnPhong, Lambert)] _WorkflowMode("WorkflowMode", Float) = 0.0
  }
  SubShader {
    Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="TransparentCutout" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "DisableBatching"="False"}
    ZTest On
    ZWrite On
    Blend Off
    Cull [_Cull]
    LOD 200
    HLSLINCLUDE
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma shader_feature_local _CULL_OFF _CULL_FRONT _CULL_BACK
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    CBUFFER_START(UnityPerMaterial)
      float4 _BaseMap_ST;
      half4 _BaseColor;
      float _Specular;
      float _Metallic;
      float _Smoothness;
      float _Cutoff;
      float _AlphaClip;
      float _EdgeThresholdColor;
      float _EdgeThresholdDepth;
      float _LightThreshold0;
      float _LightThreshold1;
      float _LightingIntensity0;
      float _LightingIntensity1;
      float _ToonSmoothness;
      float _Cull;
    CBUFFER_END
    ENDHLSL
    Pass {
      Name "Forward"
      Tags {"LightMode" = "UniversalForward"}
      HLSLPROGRAM
      #pragma shader_feature_local_fragment _WORKFLOWMODE_PBR _WORKFLOWMODE_BLINNPHONG _WORKFLOWMODE_LAMBERT
      #pragma shader_feature_local_fragment _Toon
      // Following part is copied from LitForwardPass.hlsl
      // Material Keywords
      #pragma shader_feature_local _ALPHATEST_ON
      // Universal Pipeline keywords
      #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
      #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
      #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
      #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
      #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
      #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
      #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
      #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
      #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
      #pragma multi_compile_fragment _ _LIGHT_COOKIES
      #pragma multi_compile _ _LIGHT_LAYERS
      #pragma multi_compile _ _FORWARD_PLUS
      // Unity defined keywords
      #pragma multi_compile _ SHADOWS_SHADOWMASK
      #pragma multi_compile _ DIRLIGHTMAP_COMBINED
      #pragma multi_compile _ LIGHTMAP_ON
      #pragma multi_compile _ DYNAMICLIGHTMAP_ON
      #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"
      // GPU Instancing
      // #pragma multi_compile_instancing
      #pragma instancing_options renderinglayer
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
      // --------------------------------------------------------------------
      #include "./ToonForwardPass.hlsl"
      ENDHLSL
    }
    Pass {
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha, DstAlpha Zero
      Name "OutlineForward"
      Tags {"LightMode" = "ToonOutlineForwardPass"}
      HLSLPROGRAM
      #pragma require geometry
      #pragma geometry Geo
      // #pragma shader_feature_local _ALPHATEST_ON
      #include "./ToonOutlineForwardPass.hlsl"
      ENDHLSL
    }
    Pass {
      Name "ShadowCaster"
      Tags {"LightMode" = "ShadowCaster"}
      HLSLPROGRAM
      #define SHADOWCASTER
      #pragma shader_feature_local _ALPHATEST_ON
      #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
      #pragma multi_compile_shadowcaster
      #include "./ToonDepthPass.hlsl"
      ENDHLSL
    }
    Pass {
      Name "DepthOnly"
      Tags {"LightMode" = "DepthOnly"}
      HLSLPROGRAM
      #pragma shader_feature_local _ALPHATEST_ON
      #include "./ToonDepthPass.hlsl"
      ENDHLSL
    }
    Pass {
      Name "DepthOnly"
      Tags {"LightMode" = "DepthNormals"}
      HLSLPROGRAM
      #define REQUIRES_NORMAL
      #pragma shader_feature_local _ALPHATEST_ON
      #include "./ToonDepthPass.hlsl"
      ENDHLSL
    }
    Pass {
      Name "OutlinePost"
      Tags {"LightMode" = "ToonOutlinePostPass"}
      ZTest Off
      ZWrite Off
      HLSLPROGRAM
      #include "./ToonOutlinePostPass.hlsl"
      ENDHLSL
    }
  }
}
