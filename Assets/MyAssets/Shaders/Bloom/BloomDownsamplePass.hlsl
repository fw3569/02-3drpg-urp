Texture2D _MainTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  return output;
}
half ColorToGray(half4 color) {
  return dot(color, half4(0.299, 0.587, 0.114, 0));
}
half4 Frag(Varyings input) : SV_TARGET0 {
  int2 lowerPositionCS = floor(input.positionCS.xy) * 2;
  half4 color = half4(0, 0, 0, 0);
  for(int i = 0; i < 2; ++i) {
    for(int j = 0; j < 2; ++j) {
      color = max(color, _MainTex.mips[_MipLevel][lowerPositionCS + uint2(i, j)]);
    }
  }
  half luminance = ColorToGray(color);
  half knee = _BloomThreshold * 0.5;
  half soft = saturate((luminance - _BloomThreshold + knee) / (2 * knee));
  return color * soft;
}
