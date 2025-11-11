sampler2D _MainTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 xyCS       : TEXCOORD0;
  float2 uv         : TEXCOORD1;
  float2 toLightCS  : TEXCOORD2;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  output.xyCS = output.positionCS.xy;
  output.uv = GetFullScreenTriangleTexCoord(vertexID);
  float4 lightDirWS = float4(_MainLightPosition.xyz, 0);
  float4 lightDirCS = mul(UNITY_MATRIX_VP, lightDirWS);
  lightDirCS /= abs(lightDirCS.w);
  output.toLightCS = lightDirCS.xy - output.xyCS;
  return output;
}
#ifdef BLEND_ON
half4 Frag(Varyings input) : SV_TARGET0 {
#else
half Frag(Varyings input) : SV_TARGET0 {
#endif
  float lightDis = length(input.toLightCS.xy);
  input.toLightCS *= _MainTex_TexelSize.zw;
  input.toLightCS /= max(abs(input.toLightCS.x), abs(input.toLightCS.y));
  // input.toLightCS = normalize(input.toLightCS);
  input.toLightCS *= _MainTex_TexelSize.xy;
  half color = tex2D(_MainTex, input.uv).r;
  half colorSum = color;
  half wSum = 1;
  float2 blurStep = input.toLightCS * _BlurStep;
  float2 sampleuv = input.xyCS - blurStep;
  half stepDisRate = length(blurStep.xy) / lightDis;
  half sampleDisRate = 1 + stepDisRate;
  for(int i = 0; i < 3; ++i) {
    if(sampleuv.x < -1 || sampleuv.x > 1 || sampleuv.y < -1 || sampleuv.y > 1) {
      break;
    }
    // TBD compare depth
    half sampleColor = tex2D(_MainTex, (float2(sampleuv.x, -sampleuv.y) + 1) * 0.5).r;
    sampleColor *= sampleDisRate * sampleDisRate;
    half colorDiff = color - sampleColor;
    half w = exp2(-colorDiff * colorDiff / (2 * _Deviation * _Deviation));
    if(sampleColor > color){
      w *= 0.1;
    }
    // w error in near boundary, but not obvious with using BilateralFiler, omit
    // int a, b;
    // if(input.toLightCS.x > 0) {
    //   a = (sampleuv.x + 1) / input.toLightCS.x;
    // } else {
    //   a = -(1 - sampleuv.x) / input.toLightCS.x;
    // }
    // if(input.toLightCS.y > 0) {
    //   b = (1 + sampleuv.y) / input.toLightCS.y;
    // } else {
    //   b = -(1 - sampleuv.y) / input.toLightCS.y;
    // }
    // w *= min(min(a, b) + 1, _BlurStep) / float(_BlurStep);
    wSum += w;
    colorSum += w * sampleColor;
    sampleuv -= blurStep;
    sampleDisRate += stepDisRate;
  }
  color = colorSum / wSum;
#ifdef BLEND_ON
  return half4(color * _Intensity * _MainLightColor.rgb, 1);
#else
  return color;
#endif
}
