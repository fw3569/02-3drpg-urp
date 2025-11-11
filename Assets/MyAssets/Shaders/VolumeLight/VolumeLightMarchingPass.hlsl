// Texture2D<float> _CameraDepthTexture;
Texture2D<float> _MainTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 xyCS       : TEXCOORD0;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  output.xyCS = output.positionCS.xy;
  return output;
}
half SampleFogDensity(float3 positionWS) {
  // assume density uniformity
  return _Intensity;
}
float findIntersection(float4 startWS, float4 endWS, half startLight, half endLight) {
  float4 offsetWS = endWS - startWS;
  float l = 0, r = 1, u;
  static const int compareTimes = 2;
  for(int i = 0; i < compareTimes; ++i) {
    u = (l + r) / 2;
    float4 intersection = startWS + offsetWS * u;
    half light = MainLightShadow(TransformWorldToShadowCoord(intersection.xyz), intersection.xyz, half4(1, 1, 1, 1), _MainLightOcclusionProbes);
    if(light == startLight) {
      l = u;
    } else {
      r = u;
    }
  }
  return (l + r) / 2;
}
half MieScattering(half coslv) {
  half x = (1 - _MieScattering);
  half y = (1 + _MieScattering * _MieScattering - 2 * _MieScattering * coslv);
  return x * x / (4 * 3.141592653589793 * pow(abs(y), 1.5));
}
half ExtingctionFunc(inout half length) {
	half extingction = exp2(-length * _ExtingctionFactor);
  // equivalence integral to multiple
  length = (1 - extingction) / _ExtingctionFactor;
  return extingction;
}
float flatSample(float x) {
  x = x * 2 - 1;
  return (0.75 - 0.25 * x * x) * x + 0.5;
}
half Frag(Varyings input) : SV_TARGET0 {
  float depth = _MainTex[input.positionCS.xy * 2];
  if(depth == 0) {
    // Draw sum or not?
    // float4 lightDirWS = float4(_MainLightPosition.xyz, 0);
    // float4 lightDirCS = mul(UNITY_MATRIX_VP, lightDirWS);
    // lightDirCS /= lightDirCS.w;
    // if (length((lightDirCS.xy - input.xyCS) * float2(1, _ScreenParams.y * (_ScreenParams.z - 1))) < 0.05) {
    //   return 1;
    // }
    return 0;
  }
  float4 positionCS = float4(input.xyCS, depth, 1.0);
  float4 positionVS = mul(UNITY_MATRIX_I_P, positionCS);
  positionVS /= positionVS.w;
  float4 positionWS = mul(UNITY_MATRIX_I_V, positionVS);
  float4 positionCameraWS = float4(UNITY_MATRIX_I_V[0][3], UNITY_MATRIX_I_V[1][3], UNITY_MATRIX_I_V[2][3], 1);
  float4 lightToCameraWS = float4(positionCameraWS.xyz - positionWS.xyz, 1);
  float4 lightToCameraDirWS = float4(normalize(lightToCameraWS.xyz), 0);
  float lightToCameraDisWS = length(lightToCameraWS.xyz);
  static const int sampleCount = 16;
  // flatSample function above
  // static const float step[17] = {0.0, 0.01123046875, 0.04296875, 0.09228515625, 0.15625, 0.23193359375, 0.31640625, 0.40673828125, 0.5, 0.59326171875, 0.68359375, 0.76806640625, 0.84375, 0.90771484375, 0.95703125, 0.98876953125, 1.0};
  static const float step[17] = {0.0, 0.0936279296875, 0.1865234375, 0.2779541015625, 0.3671875, 0.4534912109375, 0.5361328125, 0.6143798828125, 0.6875, 0.7547607421875, 0.8154296875, 0.8687744140625, 0.9140625, 0.9505615234375, 0.9775390625, 0.9942626953125, 1.0};
  // static const float step[17] = {0.0, 0.01967592592592593, 0.07407407407407407, 0.15625, 0.25925925925925924, 0.37615740740740744, 0.5, 0.6238425925925927, 0.7407407407407407, 0.7944155092592593, 0.84375, 0.8878761574074074, 0.9259259259259258, 0.95703125, 0.9803240740740741, 0.9949363425925926, 1.0};
  // save 0.7ms(31% of this pass) if use half sample point
  // static const float step[9] = {0.0, 0.1865234375, 0.3671875, 0.5361328125, 0.6875, 0.8154296875, 0.9140625, 0.9775390625, 1.0};
  // uniform
  // static const float step[17] = {0.0, 0.0625, 0.125, 0.1875, 0.25, 0.3125, 0.375, 0.4375, 0.5, 0.5625, 0.625, 0.6875, 0.75, 0.8125, 0.875, 0.9375, 1.0};
  half intensity = 0;
  float4 lastSamplePositionWS = positionWS;
  float4 samplePositionWS = positionWS + lightToCameraWS * step[1];
  half lastLight = MainLightShadow(TransformWorldToShadowCoord(positionWS.xyz), positionWS.xyz, half4(1, 1, 1, 1), _MainLightOcclusionProbes);
  float lastStep = 0;
  // Parallel light
  half scattering = MieScattering(dot(_MainLightPosition.xyz, -lightToCameraDirWS.xyz));
  for(int i = 1; i < sampleCount; ++i) {
    half light = MainLightShadow(TransformWorldToShadowCoord(samplePositionWS.xyz), samplePositionWS.xyz, half4(1, 1, 1, 1), _MainLightOcclusionProbes);
    if(lastLight != light) {
      float u = findIntersection(lastSamplePositionWS, samplePositionWS, lastLight, light);
      // TBD apply extinction to origin color attachment
      float currStep = lerp(step[i - 1], step[i], u);
      half len = (currStep - lastStep) * lightToCameraDisWS;
      lastStep = currStep;
      intensity *= ExtingctionFunc(len);
      intensity += scattering * lastLight * len;
      lastLight = light;
    }
    lastSamplePositionWS = samplePositionWS;
    samplePositionWS = positionWS + lightToCameraWS * step[i + 1];
  }
  half len = (1 - lastStep) * lightToCameraDisWS;
  intensity *= ExtingctionFunc(len);
  intensity += scattering * lastLight * len;
  return intensity;
}
