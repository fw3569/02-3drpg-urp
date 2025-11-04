Texture2D _MainTex;
SamplerState sampler_MainTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  return output;
}
// some rasterization area exceptions with mipmap?
half4 Frag(Varyings input) : SV_TARGET0 {
  float2 samplePoint = (input.positionCS.xy - 1) / 2;
  uint2 samplePointIndex = floor(samplePoint);
  float2 samplePointSubcoord = samplePoint - samplePointIndex;
  return lerp(lerp(_MainTex.mips[_MipLevel][samplePointIndex], _MainTex.mips[_MipLevel][samplePointIndex + uint2(1, 0)], samplePointSubcoord.x), lerp(_MainTex.mips[_MipLevel][samplePointIndex + uint2(0, 1)], _MainTex.mips[_MipLevel][samplePointIndex + uint2(1, 1)], samplePointSubcoord.x), samplePointSubcoord.y) * _BloomIntensity;
}
