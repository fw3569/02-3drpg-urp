Texture2D<float> _CameraDepthTexture;
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
  return _Intensity;
}
float findIntersection(float4 startWS, float4 endWS, float startLight, float endLight) {
  float4 offsetWS = endWS - startWS;
  float l = 0, r = 1, u = 0.5;
  static const int compareTimes = 4;
  for(int i = 0; i < compareTimes; ++i) {
    u = (l + r) / 2;
    float4 intersection = startWS + offsetWS * u;
    float4 shadowCoord = TransformWorldToShadowCoord(intersection.xyz);
    half light = MainLightShadow(shadowCoord, intersection.xyz, half4(1, 1, 1, 1), _MainLightOcclusionProbes);
    if(light == startLight){
      l = u;
    } else {
      r = u;
    }
  }
  return u;
}
float MieScattering(float coslv) {
  float x = (1 - _MieScattering);
  float y = (1 + _MieScattering * _MieScattering - 2 * _MieScattering * coslv);
  return x * x / (4 * 3.141592653589793 * pow(abs(y), 1.5));
}
float ExtingctionFunc(inout float length) {
	float extingction = exp(-length * _ExtingctionFactor);
  // equivalence int to multiple
  length = (1 - extingction) / _ExtingctionFactor;
  return extingction;
}
float flatSample(float x) {
  x = x * 2 - 1;
  return (0.75 - 0.25 * x * x) * x + 0.5;
}
half Frag(Varyings input) : SV_TARGET0 {
  float depth = _CameraDepthTexture[floor(input.positionCS.xy)];
  float4 positionCS = float4(input.xyCS, depth, 1.0);
  float4 positionVS = mul(UNITY_MATRIX_I_P, positionCS);
  positionVS /= positionVS.w;
  float4 positionWS = mul(UNITY_MATRIX_I_V, positionVS);
  float4 positionCameraWS = float4(UNITY_MATRIX_I_V[0][3], UNITY_MATRIX_I_V[1][3], UNITY_MATRIX_I_V[2][3], 1);
  float4 distanceWS = float4(positionCameraWS.xyz - positionWS.xyz, 1);
  float4 directionCameraWS = float4(normalize(distanceWS.xyz), 0);
  float4 normalCameraWS = float4(-UNITY_MATRIX_I_V[0][2], -UNITY_MATRIX_I_V[1][2], -UNITY_MATRIX_I_V[2][2], 0);
  static const int sampleCount = 16;
  // flatSample function above
  static const float step[17] = {0, 0.01123046875, 0.04296875, 0.09228515625, 0.15625, 0.23193359375, 0.31640625, 0.40673828125, 0.5, 0.59326171875, 0.68359375, 0.76806640625, 0.84375, 0.90771484375, 0.95703125, 0.98876953125, 1};
  // static const float step[17] = {0.0, 0.0625, 0.125, 0.1875, 0.25, 0.3125, 0.375, 0.4375, 0.5, 0.5625, 0.625, 0.6875, 0.75, 0.8125, 0.875, 0.9375, 1};
  half intensity = 0;
  float4 lastSamplePositionWS = positionWS;
  float4 samplePositionWS = positionWS + distanceWS * step[1];
  float lenDistanceWS = length(distanceWS.xyz);
  // assume density uniformity
  float density = SampleFogDensity(samplePositionWS.xyz);
  float lastLight = MainLightShadow(TransformWorldToShadowCoord(positionWS.xyz), positionWS.xyz, half4(1, 1, 1, 1), _MainLightOcclusionProbes);
  float lastStep = 0;
  // Parallel light
  half scattering = MieScattering(dot(_MainLightPosition.xyz, -directionCameraWS.xyz));
  for(int i = 1; i < sampleCount; ++i) {
    float4 shadowCoord = TransformWorldToShadowCoord(samplePositionWS.xyz);
    half light = MainLightShadow(shadowCoord, samplePositionWS.xyz, half4(1, 1, 1, 1), _MainLightOcclusionProbes);
    if(lastLight != light) {
      float u = findIntersection(lastSamplePositionWS, samplePositionWS, lastLight, light);
      // TBD apply extinction to origin color attachment
      float currStep = lerp(step[i-1], step[i], u);
      float len = currStep - lastStep;
      lastStep = currStep;
      half extinction = ExtingctionFunc(len);
      intensity *= extinction;
      intensity += density * scattering * lastLight * len;
      lastLight = light;
    }
    lastSamplePositionWS = samplePositionWS;
    samplePositionWS = positionWS + distanceWS * step[i + 1];
  }
  float len = 1 - lastStep;
  half extinction = ExtingctionFunc(len);
  intensity *= extinction;
  intensity += density * scattering * lastLight * len;
  intensity = min(intensity, 0.5);
  return intensity;
}
