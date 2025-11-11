sampler2D _BaseMap;
struct Attributes {
  float4 positionOS        : POSITION;
  float3 normalOS          : NORMAL;
  float2 texcoord          : TEXCOORD0;
  float2 staticLightmapUV  : TEXCOORD1;
  float2 dynamicLightmapUV : TEXCOORD2;
  UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct Varyings {
  float4 positionCS        : SV_POSITION;
  float2 uv                : TEXCOORD0;
  float3 positionWS        : TEXCOORD1;
  float3 normalWS          : TEXCOORD2;
#ifdef LIGHTMAP_ON
  float2 staticLightmapUV  : TEXCOORD3;
#else
  half3 vertexSH           : TEXCOORD3;
#endif
#ifdef DYNAMICLIGHTMAP_ON
  float2 dynamicLightmapUV : TEXCOORD4;
#endif
#ifdef USE_APV_PROBE_OCCLUSION
  float4 probeOcclusion    : TEXCOORD5;
#endif
  UNITY_VERTEX_INPUT_INSTANCE_ID
};

// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
// #pragma instancing_options assumeuniformscaling
UNITY_INSTANCING_BUFFER_START(Props)
  // put more per-instance properties here
UNITY_INSTANCING_BUFFER_END(Props)
Varyings Vert (Attributes input) {
  Varyings output;
  UNITY_SETUP_INSTANCE_ID(input);
  UNITY_TRANSFER_INSTANCE_ID(input, output);
  output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
  output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
  output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
  output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
  // Following part is copied from LitForwardPass.hlsl
  VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
  OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
  output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
  OUTPUT_SH4(vertexInput.positionWS, output.normalWS.xyz, GetWorldSpaceNormalizeViewDir(vertexInput.positionWS), output.vertexSH, output.probeOcclusion);
  // ------------------------------------------------------------------------
  return output;
}

// Most of following part is copied from Lighting.hlsl
half3 ToonLightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
  half3 lightColor, half3 lightDirectionWS, float lightAttenuation,
  half3 normalWS, half3 viewDirectionWS,
  half clearCoatMask, bool specularHighlightsOff) {
  half NdotL = dot(normalWS, lightDirectionWS);
  half3 radiance = lightColor * (lightAttenuation * saturate(NdotL));
// Step Lighting
// TBD AO
#ifdef _Toon
  half lightingIntensity;
  float threshold0 =_LightThreshold0 + 0.5 * _ToonSmoothness * (1 - _LightingIntensity0);
  float threshold1 =_LightThreshold0 - 0.5 * _ToonSmoothness * (1 - _LightingIntensity0);
  float threshold2 =_LightThreshold1 + 0.5 * _ToonSmoothness * (_LightingIntensity0 - _LightingIntensity1);
  float threshold3 =_LightThreshold1 - 0.5 * _ToonSmoothness * (_LightingIntensity0 - _LightingIntensity1);
  if(NdotL > threshold0) {
    lightingIntensity = 1;
  } else if(NdotL > threshold1) {
    lightingIntensity = lerp(_LightingIntensity0, 1, (NdotL - threshold1) / (threshold0 - threshold1));
  } else if(NdotL > threshold2) {
    lightingIntensity = _LightingIntensity0;
  } else if(NdotL > threshold3) {
    lightingIntensity = lerp(_LightingIntensity1, _LightingIntensity0, (NdotL - threshold3) / (threshold2 - threshold3));
  } else {
    lightingIntensity = _LightingIntensity1;
  }
  radiance = lightColor * (lightingIntensity * lightAttenuation);
#endif
  half3 brdf = brdfData.diffuse;
#ifndef _SPECULARHIGHLIGHTS_OFF
  [branch] if (!specularHighlightsOff) {
    brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);
      half NoV = saturate(dot(normalWS, viewDirectionWS));
      half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);
    brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
#endif
  }
#endif
  return brdf * radiance;
}
half3 ToonLightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff) {
  return ToonLightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
}
half3 ToonCalculateLightingColor(LightingData lightingData, half3 albedo) {
  half3 lightingColor = 0;
  if (IsOnlyAOLightingFeatureEnabled()) {
      return lightingData.giColor;
  }
  if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_GLOBAL_ILLUMINATION)) {
      lightingColor += lightingData.giColor;
  }
  if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT)) {
      lightingColor += lightingData.mainLightColor;
  }
  if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS)) {
      lightingColor += lightingData.additionalLightsColor;
  }
  if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING)) {
      lightingColor += lightingData.vertexLightingColor;
  }
  lightingColor *= albedo;
  if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_EMISSION)) {
      lightingColor += lightingData.emissionColor;
  }
  return lightingColor;
}
half4 ToonCalculateFinalColor(LightingData lightingData, half alpha) {
  half3 finalColor = ToonCalculateLightingColor(lightingData, 1);
  return half4(finalColor, alpha);
}
void InitializeBakedGIData(Varyings input, inout InputData inputData) {
#if defined(DYNAMICLIGHTMAP_ON)
  inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
  inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
#elif !defined(LIGHTMAP_ON) && (defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2))
  inputData.bakedGI = SAMPLE_GI(input.vertexSH,
    GetAbsolutePositionWS(inputData.positionWS),
    inputData.normalWS,
    inputData.viewDirectionWS,
    input.positionCS.xy,
    input.probeOcclusion,
    inputData.shadowMask);
#else
  inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
  inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
#endif
}
half4 ToonFragmentPBR(InputData inputData, SurfaceData surfaceData) {
#if defined(_SPECULARHIGHLIGHTS_OFF)
  bool specularHighlightsOff = true;
#else
  bool specularHighlightsOff = false;
#endif
  BRDFData brdfData;
  InitializeBRDFData(surfaceData, brdfData);
#if defined(DEBUG_DISPLAY)
  half4 debugColor;
  if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor)) {
    return debugColor;
  }
#endif
  BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
  half4 shadowMask = CalculateShadowMask(inputData);
  AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
  uint meshRenderingLayers = GetMeshRenderingLayer();
  Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
  MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
  LightingData lightingData = CreateLightingData(inputData, surfaceData);
  lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                            inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                            inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
#ifdef _LIGHT_LAYERS
  if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
  {
    lightingData.mainLightColor = ToonLightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                          mainLight,
                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                          surfaceData.clearCoatMask, specularHighlightsOff);
  }
#if defined(_ADDITIONAL_LIGHTS)
  uint pixelLightCount = GetAdditionalLightsCount();
#if USE_FORWARD_PLUS
  [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++) {
    FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
    Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
      lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                    inputData.normalWS, inputData.viewDirectionWS,
                                                                    surfaceData.clearCoatMask, specularHighlightsOff);
    }
  }
  #endif
  LIGHT_LOOP_BEGIN(pixelLightCount)
    Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
      lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                    inputData.normalWS, inputData.viewDirectionWS,
                                                                    surfaceData.clearCoatMask, specularHighlightsOff);
    }
  LIGHT_LOOP_END
#endif
  #if defined(_ADDITIONAL_LIGHTS_VERTEX)
  lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
#endif
#if REAL_IS_HALF
  return min(ToonCalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
#else
  return ToonCalculateFinalColor(lightingData, surfaceData.alpha);
#endif
}
// --------------------------------------------------------------------------

half4 Frag (Varyings input) : SV_Target0 {
  UNITY_SETUP_INSTANCE_ID(input);
  half4 color = tex2D(_BaseMap, input.uv);
#ifdef _ALPHATEST_ON
  clip(color.a - _Cutoff);
#endif
  color *=  _BaseColor;
#if defined(_WORKFLOWMODE_PBR)
  // Following part is copied from LitForwardPass.hlsl
  InputData inputData = (InputData)0;
  inputData.positionWS = input.positionWS;
  inputData.normalWS = input.normalWS;
  inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
  half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
  inputData.viewDirectionWS = viewDirWS;
  inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
  inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
  InitializeBakedGIData(input, inputData);
  SurfaceData surfaceData;
  surfaceData.albedo = color.rgb;
  surfaceData.specular = _Specular;
  surfaceData.metallic = _Metallic;
  surfaceData.smoothness = _Smoothness;
  surfaceData.normalTS = half3(0, 0, 1);
  surfaceData.emission = half3(0, 0, 0);
  surfaceData.occlusion = half(1.0);
  surfaceData.alpha = color.a;
  surfaceData.clearCoatMask = 0;
  surfaceData.clearCoatSmoothness = 1;
  color = ToonFragmentPBR(inputData, surfaceData);
  // ------------------------------------------------------------------------
#elif defined(_WORKFLOWMODE_BLINNPHONG)
  InputData inputData = (InputData)0;
  inputData.positionWS = input.positionWS;
  inputData.normalWS = input.normalWS;
  inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
  half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
  inputData.viewDirectionWS = viewDirWS;
  inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
  inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
  InitializeBakedGIData(input, inputData);
  SurfaceData surfaceData;
  surfaceData.albedo = color.rgb;
  surfaceData.alpha = color.a;
  surfaceData.emission = half3(0, 0, 0);
  surfaceData.metallic = 0;
  surfaceData.occlusion = 1;
  surfaceData.smoothness = _Smoothness;
  surfaceData.specular = _Specular;
  surfaceData.clearCoatMask = 0;
  surfaceData.clearCoatSmoothness = 1;
  surfaceData.normalTS = half3(0, 0, 1);
  color = UniversalFragmentBlinnPhong(inputData, surfaceData);
#else
  color *= half4(MainLightShadow(TransformWorldToShadowCoord(input.positionWS), input.positionWS, half4(1, 1, 1, 1), _MainLightOcclusionProbes) * saturate(dot(_MainLightPosition.xyz, input.normalWS)) * _MainLightColor.rgb, 1);
#endif
  return color;
}
