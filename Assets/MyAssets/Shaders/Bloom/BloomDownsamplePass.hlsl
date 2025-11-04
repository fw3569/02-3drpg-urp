Texture2D _MainTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  return output;
}
half ColorToGray(half3 color) {
  return dot(color, half3(0.299, 0.587, 0.114));
}
half4 Frag(Varyings input) : SV_TARGET0 {
  int2 lowerPositionCS = input.positionCS.xy * 2;
  half3 color = half3(0, 0, 0);
  for(int i = 0; i < 2; ++i) {
    for(int j = 0; j < 2; ++j) {
      color = max(color, _MainTex.mips[_MipLevel][lowerPositionCS + int2(i, j)].rgb);
    }
  }
  half luminance = ColorToGray(color);
  half knee = _BloomThreshold * 0.5;
  half soft = saturate((luminance - _BloomThreshold + knee) / (2 * knee));
  return half4(color, 1) * soft;
}
