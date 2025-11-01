sampler2D _MainTex;
struct Attributes {
  float4 positionOS : POSITION;
  float2 texcoord   : TEXCOORD0;
};
struct Vertex {
  float2 texcoord   : TEXCOORD0;
  float3 positionOS : TEXCOORD1;
};
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 uv         : TEXCOORD0;
};

Vertex Vert (Attributes input) {
  Vertex output;
  output.positionOS = input.positionOS.xyz;
  output.texcoord = input.texcoord;
  return output;
}
[maxvertexcount(6)]
void Geo(triangle Vertex input[3], inout TriangleStream<Varyings> output) {
  if(all(input[0].positionOS == input[1].positionOS) || all(input[1].positionOS == input[2].positionOS)) {
    return;
  }
  float4 positionCS[3];
  float4 normalizePositionCS[3];
  float3 centerCS = float3(0.0f, 0.0f, 0.0f);
  float zVS[3];
  for(int i = 0; i < 3; ++i) {
    positionCS[i] = TransformObjectToHClip(input[i].positionOS);
    zVS[i] = positionCS[i].w;
    normalizePositionCS[i] = positionCS[i] / positionCS[i].w;
    centerCS += (normalizePositionCS[i] / normalizePositionCS[i].w).xyz;
  }
  centerCS /= 3.0f;
  float3 normal = normalize(cross((normalizePositionCS[2] - normalizePositionCS[1]).xyz, (normalizePositionCS[0] - normalizePositionCS[1]).xyz));
  float aspect = _ScreenParams.y / _ScreenParams.x;
  static const float outlineWidth = 0.1f;
  // for smooth width curve
  static const float outlineCameraBais = 5.0f;
  if(_Cull == 0) {
    Varyings vertex[6];
    [unroll]
    for(int i = 0; i < 3; ++i) {
      vertex[2 * i].uv = input[i].texcoord;
      vertex[2 * i + 1].uv = input[i].texcoord;
      float3 outlineVec = cross(normal, (normalizePositionCS[(i + 2) % 3] - normalizePositionCS[i]).xyz);
      float3 outlineStep = outlineWidth / length(outlineVec.xy) * length(outlineVec) * normalize(outlineVec) / (zVS[i] + outlineCameraBais);
      outlineStep.x *= aspect;
      outlineStep.z = -dot(outlineStep.xy, normal.xy) / normal.z;
      float3 outlinePositionCS = normalizePositionCS[i].xyz + outlineStep;
      outlinePositionCS.z -= (1 - outlinePositionCS.z) * 0.001f;
      vertex[2 * i].positionCS = float4(outlinePositionCS, 1.0f) * zVS[i];
      vertex[2 * i].positionCS.z = min(vertex[2 * i].positionCS.z, positionCS[i].z);
      outlineVec = cross((normalizePositionCS[(i + 1) % 3] - normalizePositionCS[i]).xyz, normal);
      outlineStep = outlineWidth / length(outlineVec.xy) * length(outlineVec) * normalize(outlineVec) / (zVS[i] + outlineCameraBais);
      outlineStep.x *= aspect;
      outlineStep.z = -dot(outlineStep.xy, normal.xy) / normal.z;
      outlinePositionCS = normalizePositionCS[i].xyz + outlineStep;
      outlinePositionCS.z -= (1 - outlinePositionCS.z) * 0.001f;
      vertex[2 * i + 1].positionCS = float4(outlinePositionCS, 1.0f) * zVS[i];
      vertex[2 * i + 1].positionCS.z = min(vertex[2 * i + 1].positionCS.z, positionCS[i].z);
    }
    output.Append(vertex[0]);
    output.Append(vertex[1]);
    output.Append(vertex[5]);
    output.Append(vertex[2]);
    output.Append(vertex[4]);
    output.Append(vertex[3]);
  } else {
    if(normal.z >= 0) {
      return;
    }
    [unroll]
    for(int i = 2; i >= 0; --i)  {
      Varyings vertex;
      vertex.uv = input[i].texcoord;
      float3 outlineVec = normal;
      float3 outlineStep = outlineWidth / length(outlineVec.xy) * length(outlineVec) * normalize(outlineVec) / (zVS[i] + outlineCameraBais);
      outlineStep.x *= aspect;
      outlineStep.z = 0.0f;
      float3 outlinePositionCS = normalizePositionCS[i].xyz + outlineStep;
      outlinePositionCS.z -= (1 - outlinePositionCS.z) * 0.001f;
      vertex.positionCS = float4(outlinePositionCS, 1.0f) * zVS[i];
      vertex.positionCS.z = min(vertex.positionCS.z, positionCS[i].z);
      output.Append(vertex);
    }
  }
}
half4 Frag (Varyings input) : SV_Target0 {
  float alpha = tex2D(_MainTex, input.uv).a;
  clip(alpha - _AlphaClip * _Cutoff);
  return half4(0, 0, 0, 1);
}
