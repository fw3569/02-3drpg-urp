sampler2D _BaseMap;
struct Attributes {
  float4 positionOS : POSITION;
  float2 texcoord   : TEXCOORD0;
  UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct Vertex {
  float4 positionCS : SV_POSITION;
  float2 texcoord   : TEXCOORD0;
  float4 positionOS : TEXCOORD1;
  UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct Varyings {
  float4 positionCS : SV_POSITION;
  float2 uv         : TEXCOORD0;
  UNITY_VERTEX_INPUT_INSTANCE_ID
};

Vertex Vert (Attributes input) {
  Vertex output;
  UNITY_SETUP_INSTANCE_ID(input);
  UNITY_TRANSFER_INSTANCE_ID(input, output);
  output.positionOS = input.positionOS;
  output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
  output.texcoord = TRANSFORM_TEX(input.texcoord, _BaseMap);
  return output;
}
[maxvertexcount(6)]
void Geo(triangle Vertex input[3], inout TriangleStream<Varyings> output) {
  if(all(input[0].positionOS == input[1].positionOS) || all(input[1].positionOS == input[2].positionOS)) {
    return;
  }
  {
    [unroll(3)]
    for(uint i = 0; i < 3; ++i) {
      UNITY_SETUP_INSTANCE_ID(input[i]);
    }
  }
  // (width, height, 1 + 1 / width, 1 + 1 / height)
  float aspect = _ScreenParams.y * (_ScreenParams.z - 1);
  float aspect_inv = _ScreenParams.x * (_ScreenParams.w - 1);
  float4 normalizePositionCS[3];
  float3 centerCS = float3(0.0f, 0.0f, 0.0f);
  float zVS[3];
  {
    for(uint i = 0; i < 3; ++i) {
      zVS[i] = input[i].positionCS.w;
      normalizePositionCS[i] = input[i].positionCS / input[i].positionCS.w;
      normalizePositionCS[i].x *= aspect_inv;
      centerCS += normalizePositionCS[i].xyz;
    }
  }
  centerCS /= 3.0f;
  float3 normal = cross((normalizePositionCS[2] - normalizePositionCS[1]).xyz, (normalizePositionCS[0] - normalizePositionCS[1]).xyz);
  if(_Cull != 0 && normal.z >= 0) {
    return;
  }
  static const float outlineWidth = 0.1f;
  // for smooth width curve
  static const float outlineCameraBais = 10.0f;
  Varyings vertex[6];
  for(uint i = 0; i < 3; ++i) {
    UNITY_TRANSFER_INSTANCE_ID(input[i], vertex[(i << 1)]);
    UNITY_TRANSFER_INSTANCE_ID(input[i], vertex[(i << 1) + 1]);
    vertex[(i << 1)].uv = input[i].texcoord;
    vertex[(i << 1) + 1].uv = input[i].texcoord;
    float cameraDistance = abs(zVS[i]) + outlineCameraBais;
    float3 outlineVec = cross(normal, (normalizePositionCS[(i + 2) % 3] - normalizePositionCS[i]).xyz);
    float3 outlineStep = outlineWidth / (length(outlineVec.xy) * cameraDistance) * outlineVec;
    // outlineStep.z = -dot(outlineStep.xy, normal.xy) / normal.z;
    float3 outlinePositionCS = normalizePositionCS[i].xyz + outlineStep;
    outlinePositionCS.z -= (1 - outlinePositionCS.z) * 0.0001f;
    vertex[(i << 1)].positionCS = float4(outlinePositionCS, 1.0f) * zVS[i];
    vertex[(i << 1)].positionCS.x *= aspect;
    // vertex[(i << 1)].positionCS.z = min(vertex[(i << 1)].positionCS.z, input[i].positionCS.z);
    outlineVec = cross((normalizePositionCS[(i + 1) % 3] - normalizePositionCS[i]).xyz, normal);
    outlineStep = outlineWidth / (length(outlineVec.xy) * cameraDistance) * outlineVec;
    // outlineStep.z = -dot(outlineStep.xy, normal.xy) / normal.z;
    outlinePositionCS = normalizePositionCS[i].xyz + outlineStep;
    outlinePositionCS.z -= (1 - outlinePositionCS.z) * 0.0001f;
    vertex[(i << 1) + 1].positionCS = float4(outlinePositionCS, 1.0f) * zVS[i];
    vertex[(i << 1) + 1].positionCS.x *= aspect;
    // vertex[(i << 1) + 1].positionCS.z = min(vertex[(i << 1) + 1].positionCS.z, input[i].positionCS.z);
  }
  output.Append(vertex[1]);
  output.Append(vertex[0]);
  output.Append(vertex[2]);
  output.Append(vertex[5]);
  output.Append(vertex[3]);
  output.Append(vertex[4]);
  // procedural geometry silhouetting, too many crevices, low cost, when _Cull 0
  // if(normal.z >= 0) {
  //   return;
  // }
  // for(uint i = 2; i >= 0; --i)  {
  //   Varyings vertex;
  //   UNITY_TRANSFER_INSTANCE_ID(input[i], vertex);
  //   vertex.uv = input[i].texcoord;
  //   float3 outlineVec = normal;
  //   float3 outlineStep = outlineWidth / length(outlineVec.xy) * length(outlineVec) * normalize(outlineVec) / (abs(zVS[i]) + outlineCameraBais);
  //   outlineStep.x *= aspect;
  //   outlineStep.z = 0.0f;
  //   float3 outlinePositionCS = normalizePositionCS[i].xyz + outlineStep;
  //   outlinePositionCS.z -= (1 - outlinePositionCS.z) * 0.0001f;
  //   vertex.positionCS = float4(outlinePositionCS, 1.0f) * zVS[i];
  //   vertex.positionCS.z = min(vertex.positionCS.z, positionCS[i].z);
  //   output.Append(vertex);
  // }
}
half4 Frag (Varyings input) : SV_Target0 {
  UNITY_SETUP_INSTANCE_ID(input);
  return half4(0, 0, 0, tex2D(_BaseMap, input.uv).a > _Cutoff);
}
