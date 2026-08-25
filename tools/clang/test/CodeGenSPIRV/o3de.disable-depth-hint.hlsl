// RUN: %dxc -T ps_6_0 -E main -spirv -fcgl %s | FileCheck %s --check-prefix=DEFAULT
// RUN: %dxc -T ps_6_0 -E main -spirv -fcgl -fvk-disable-depth-hint %s | FileCheck %s --check-prefix=DISABLED

// DEFAULT-DAG: OpTypeImage %float 2D 2 0 0 2 Rgba32f
// DEFAULT-DAG: OpTypeImage %float 2D 2 0 0 1 Unknown

// DISABLED-DAG: OpTypeImage %float 2D 0 0 0 2 Rgba32f
// DISABLED-DAG: OpTypeImage %float 2D 2 0 0 1 Unknown

RWTexture2D<float4> outputTexture : register(u0);
Texture2D<float4> inputTexture : register(t0);

float4 main(float2 uv : TEXCOORD) : SV_Target {
  const uint2 location = uint2(uv);
  const float4 value = inputTexture.Load(int3(location, 0));
  outputTexture[location] = value;
  return value;
}
