Texture2D _BaseMap;
Texture2D _DepthTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  return output;
}
half ColorToGray(half4 color) {
  return dot(color.rgb, half3(0.299, 0.587, 0.114));
}
half EdgeValue(Texture2D tex, uint2 uv) {
  static const half sobleX[2][2] = {{ 1,-1}, {1,-1}};
  static const half sobleY[2][2] = {{-1,-1}, {1, 1}};
  half edgeX = 0.0;
  half edgeY = 0.0;
  for(int i = 0; i < 2; ++i) {
    for(int j = 0; j < 2; ++j) {
      half gray = ColorToGray(tex[uv + uint2((i - 1), (j - 1))]);
      edgeX += sobleX[i][j] * gray;
      edgeY += sobleY[i][j] * gray;
    }
  }
  return abs(edgeX) + abs(edgeY);
}
half4 Frag (Varyings input) : SV_Target0 {
  uint2 uv = input.positionCS.xy;
  half colorEdgeValue = EdgeValue(_BaseMap, uv);
  half depthEdgeValue = EdgeValue(_DepthTex, uv);
  half isEdge = (colorEdgeValue > _EdgeThresholdColor) || (depthEdgeValue > _EdgeThresholdDepth);
  return half4((1 - isEdge) * _BaseMap[uv].rgb, 1.0);
}
