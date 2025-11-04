sampler2D _MainTex; 
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 xyCS       : TEXCOORD0;
  float2 uv         : TEXCOORD1;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  output.xyCS = output.positionCS.xy;
  output.uv = GetFullScreenTriangleTexCoord(vertexID);
  return output;
}
half ColorToGray(half3 color) {
  return dot(color, half3(0.299, 0.587, 0.114));
}
half Frag(Varyings input) : SV_TARGET0 {
  float4 lightDirWS = float4(_MainLightPosition.xyz, 0);
  float4 lightDirCS = mul(UNITY_MATRIX_VP, lightDirWS);
  float4 normalizeLightDirCS = lightDirCS / lightDirCS.w;
  float2 toLightCS = normalizeLightDirCS.xy - input.xyCS;
  toLightCS *= _MainTex_TexelSize.zw;
  toLightCS /= max(abs(toLightCS.x), abs(toLightCS.y));
  toLightCS *= _MainTex_TexelSize.xy;
  half color = tex2D(_MainTex, input.uv).r;
  half blendColor = 0;
  int k = 0;
  for(int i = -1; i < 2; ++i) {
    float2 sampleuv = input.xyCS - toLightCS * (_BlurStep + i);
    if(sampleuv.x > -1 && sampleuv.x < 1 && sampleuv.y > -1 && sampleuv.y < 1) {
      blendColor += tex2D(_MainTex, (float2(sampleuv.x, -sampleuv.y) + 1) / 2).r;
      ++k;
    }
  }
  if(blendColor > color * k) {
    blendColor /= k ;
    static const float deviation = 0.01;
    float w = exp2(-pow(color - blendColor, 2) / (2 * deviation * deviation));
    color = lerp(color, blendColor, w / (1 + w));
  }
  return color;
}
