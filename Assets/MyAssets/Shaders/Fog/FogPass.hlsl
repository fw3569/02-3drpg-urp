Texture2D<float> _CameraDepthTexture;
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 xyCS       : TEXCOORD0;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  output.xyCS = output.positionCS.xy;
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
  uint uintx = (intx % size + size) % size;
  uint uinty = (inty % size + size) % size;
  float noise0 = Grad(noiseTex[uintx][uinty], floatx, floaty);
  float noise1 = Grad(noiseTex[(uintx + 1) % size][uinty], floatx - 1, floaty);
  float noise2 = Grad(noiseTex[uintx][(uinty + 1) % size], floatx, floaty - 1);
  float noise3 = Grad(noiseTex[(uintx + 1) % size][(uinty + 1) % size], floatx - 1, floaty - 1);
  float u = fade(floatx);
  float v = fade(floaty);
  return lerp(lerp(noise0, noise1, u), lerp(noise2, noise3, u), v);
}
float FogFactor(float l, float h) {
  return max(exp2(l - h) - 1, 0);
}
half4 Frag(Varyings input) : SV_TARGET0 {
  float depth = _CameraDepthTexture[uint2(input.positionCS.xy)];
  float4 positionCS = float4(input.xyCS, depth, 1.0);
  float4 positionVS = mul(UNITY_MATRIX_I_P, positionCS);
  positionVS /= positionVS.w;
  float4 positionWS = mul(UNITY_MATRIX_I_V, positionVS);
  float4 positionCameraWS = float4(UNITY_MATRIX_I_V[0][3], UNITY_MATRIX_I_V[1][3], UNITY_MATRIX_I_V[2][3], 1);
  float4 distanceWS = positionWS - positionCameraWS;
  half fogFactor = FogFactor((distanceWS.x * distanceWS.x + distanceWS.z * distanceWS.z) * _DensityFar, distanceWS.y * _DensityHeight);
  fogFactor *= (Noise(positionWS.x / 4 + _Time.y, positionWS.z / 4 + _Time.y) + 2) / 4;
  return half4(_Color.rgb * fogFactor, 1);
}
