Texture2D<float> _CameraDepthTexture;
struct Varyings {
  float4 positionCS  : SV_POSITION;
  float2 uv          : TEXCOORD0;
  float4 positionCS2 : TEXCOORD1;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  output.uv = GetFullScreenTriangleVertexPosition(vertexID);
  output.positionCS2 = output.positionCS;
  return output;
}
float Grad(int hash, float x, float y) {
  switch(hash & 0x3) {
    case 0x0: return  x + y;
    case 0x1: return -x + y;
    case 0x2: return  x - y;
    case 0x3: return -x - y;
    default: return 0;
  }
}
// Fade function as defined by Ken Perlin
float fade(float t) {
  return t * t * t * (t * (t * 6 - 15) + 10);
}
float Noise(float x, float y){
  static const int noiseTex[5][5] = {
    {1, 2, 2, 1, 3},
    {2, 2, 2, 3, 0},
    {2, 1, 2, 3, 1},
    {0, 2, 2, 3, 0},
    {2, 3, 3, 1, 2}
  };
  static const int size = 5;
  int intx = floor(x);
  float floatx = x - intx;
  int inty = floor(y);
  float floaty = y - inty;
  intx = (intx % size + size) % size;
  inty = (inty % size + size) % size;
  float noise0 = Grad(noiseTex[intx][inty], floatx, floaty);
  float noise1 = Grad(noiseTex[(intx + 1) % 5][inty], floatx - 1, floaty);
  float noise2 = Grad(noiseTex[intx][(inty + 1) % 5], floatx, floaty - 1);
  float noise3 = Grad(noiseTex[(intx + 1) % 5][(inty + 1) % 5], floatx - 1, floaty - 1);
  float u = fade(floatx);
  float v = fade(floaty);
  return lerp(lerp(noise0, noise1, u), lerp(noise2, noise3, u), v);
}
float FogFactor(float l, float h) {
  return exp2(l - h) - 1;
}
half4 Frag(Varyings input) : SV_TARGET0 {
  float depth = _CameraDepthTexture[input.positionCS.xy];
  float4 positionCS = float4(input.uv, depth, 1.0);
  float4 positionVS = mul(UNITY_MATRIX_I_P, positionCS);
  positionVS /= positionVS.w;
  float4 positionWS = mul(UNITY_MATRIX_I_V, positionVS);
  float4 positionCamera = float4(UNITY_MATRIX_I_V[0][3], UNITY_MATRIX_I_V[1][3], UNITY_MATRIX_I_V[2][3], 1);
  float4 positionFog = positionWS - positionCamera;
  half fogFactor = FogFactor((positionFog.x * positionFog.x + positionFog.z * positionFog.z) * _DensityFar, positionFog.y * _DensityHeight);
  fogFactor *= (Noise(positionWS.x / 4 + _Time.y, positionWS.z / 4 + _Time.y) + 2) / 4;
  return half4(_Color.rgb * fogFactor, 1);
}
