Texture2D _MainTex;
SamplerState sampler_MainTex;
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 uv         : TEXCOORD0;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  output.uv = GetFullScreenTriangleTexCoord(vertexID);
  return output;
}
half4 Frag(Varyings input) : SV_TARGET0 {
  return _MainTex.SampleLevel(sampler_MainTex, input.uv, _MipLevel) * _BloomIntensity;
}
