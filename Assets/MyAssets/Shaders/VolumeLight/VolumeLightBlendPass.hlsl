Texture2D<half> _MainTex; 
struct Varyings {
  float4 positionCS : SV_POSITION;
};

Varyings Vert (uint vertexID : SV_VertexID) {
  Varyings output;
  output.positionCS = GetFullScreenTriangleVertexPosition(vertexID);
  return output;
}
half4 Frag(Varyings input) : SV_TARGET0 {
  return half4(_MainLightColor.rgb * _MainTex[floor(input.positionCS.xy)], 1);
}
