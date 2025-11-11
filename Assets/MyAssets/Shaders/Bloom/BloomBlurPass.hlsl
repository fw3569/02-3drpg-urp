Texture2D _MainTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  return output;
}
half4 Frag(Varyings input) : SV_TARGET0 {
  // sigma = 0.8
  static const half gaussian_blur[5] = {
    {0.02192964486238937, 0.22851214688447105, 0.4991164165062792, 0.22851214688447105, 0.02192964486238937}
  };
  uint width, height, mipCount;
  _MainTex.GetDimensions(_MipLevel, width, height, mipCount);
  half4 color = half4(0, 0, 0, 0);
  uint2 positionCS = input.positionCS.xy;
#if defined(BLUR_X)
  for(int i = 0; i < 5; ++i) {
    uint2 sampleUpperPositionCS = positionCS + uint2(0, i - 2);
    sampleUpperPositionCS.y = min(max(sampleUpperPositionCS.y, 0), height);
    color += _MainTex.mips[_MipLevel][sampleUpperPositionCS] * gaussian_blur[i];
  }
#elif defined(BLUR_Y)
  for(int i = 0; i < 5; ++i) {
    uint2 sampleUpperPositionCS = positionCS + uint2(i - 2, 0);
    sampleUpperPositionCS.x = min(max(sampleUpperPositionCS.x, 0), width);
    color += _MainTex.mips[_MipLevel][sampleUpperPositionCS] * gaussian_blur[i];
  }
#endif
  return color;
}
