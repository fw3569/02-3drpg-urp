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
  static const half gaussian_blur[5][5] = {
    {0.00048090932379052045, 0.005011190227918607, 0.010945445758971118, 0.005011190227918607, 0.00048090932379052045},
    {0.005011190227918607, 0.05221780127375007, 0.11405416388113371, 0.05221780127375007, 0.005011190227918607},
    {0.010945445758971118, 0.11405416388113371, 0.24911719722606956, 0.11405416388113371, 0.010945445758971118},
    {0.005011190227918607, 0.05221780127375007, 0.11405416388113371, 0.05221780127375007, 0.005011190227918607},
    {0.00048090932379052045, 0.005011190227918607, 0.010945445758971118, 0.005011190227918607, 0.00048090932379052045}
  };
  uint width, height, mipCount;
  _MainTex.GetDimensions(_MipLevel, width, height, mipCount);
  half3 color = half3(0, 0, 0);
  if(_BlurType == 1) {
    for(int i = 0; i < 5; ++i) {
      int2 sampleUpperPositionCS = floor(input.positionCS.xy) + int2(0, i - 2);
      sampleUpperPositionCS.y = min(max(sampleUpperPositionCS.y, 0), height);
      color += _MainTex.mips[_MipLevel][sampleUpperPositionCS].rgb * gaussian_blur[2][i];
    }
    return half4(color / 0.4991164165062792, 1.0);
  } else if(_BlurType == 2) {
    for(int i = 0; i < 5; ++i) {
      int2 sampleUpperPositionCS = floor(input.positionCS.xy) + int2(i - 2, 0);
      sampleUpperPositionCS.x = min(max(sampleUpperPositionCS.x, 0), width);
      color += _MainTex.mips[_MipLevel][sampleUpperPositionCS].rgb * gaussian_blur[i][2];
    }
    return half4(color / 0.4991164165062792, 1.0);
  } else {
    for(int i = 0; i < 5; ++i) {
      for(int j = 0; j < 5; ++j) {
        int2 sampleUpperPositionCS = floor(input.positionCS.xy) + int2(i - 2, j - 2);
        sampleUpperPositionCS.x = min(max(sampleUpperPositionCS.x, 0), width);
        sampleUpperPositionCS.y = min(max(sampleUpperPositionCS.y, 0), height);
        color += _MainTex.mips[_MipLevel][sampleUpperPositionCS].rgb * gaussian_blur[i][j];
      }
    }
    return half4(color, 1.0);
  }
}
