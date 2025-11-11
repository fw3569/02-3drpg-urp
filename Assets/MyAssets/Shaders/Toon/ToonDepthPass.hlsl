sampler2D _BaseMap;
float3 _LightDirection;
float3 _LightPosition;
struct Attributes {
  float4 positionOS : POSITION;
  float2 texcoord   : TEXCOORD0;
#if defined(REQUIRES_NORMAL) || defined(SHADOWCASTER)
  float3 normalOS   : NORMAL;
#endif
  UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 uv         : TEXCOORD0;
#ifdef REQUIRES_NORMAL
  float3 normalWS   : TEXCOORD1;
#endif
  UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings Vert(Attributes input) {
  Varyings output;
  UNITY_SETUP_INSTANCE_ID(input);
  UNITY_TRANSFER_INSTANCE_ID(input, output);
#if defined(REQUIRES_NORMAL) || defined(SHADOWCASTER)
  float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
#endif
#if defined(SHADOWCASTER)
  float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
#if _CASTING_PUNCTUAL_LIGHT_SHADOW
  float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
  float3 lightDirectionWS = _LightDirection;
#endif
  float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
  positionCS = ApplyShadowClamping(positionCS);
  output.positionCS = positionCS;
#else
  output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
#endif
  output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
#ifdef REQUIRES_NORMAL
  output.normalWS = normalWS;
#endif
  return output;
}
#ifdef REQUIRES_NORMAL
float4 Frag(Varyings input) : SV_TARGET {
#else
void Frag(Varyings input) {
#endif
  UNITY_SETUP_INSTANCE_ID(input);
#ifdef _ALPHATEST_ON
  clip(tex2D(_BaseMap, input.uv).a - _Cutoff);
#endif
#ifdef REQUIRES_NORMAL
  return float4(normalize(input.normalWS), 0.0f);
#else
  return;
#endif
}
