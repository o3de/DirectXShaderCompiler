// RUN: %dxc -T vs_6_0 -E main -spirv -fcgl -DPRECISE_POSITION %s | FileCheck %s --check-prefix=PRECISE
// RUN: %dxc -T vs_6_0 -E main -spirv -fcgl %s | FileCheck %s --check-prefix=DEFAULT

// PRECISE: OpDecorate %gl_Position BuiltIn Position
// PRECISE-NEXT: OpDecorate %gl_Position Invariant

// DEFAULT: OpDecorate %gl_Position BuiltIn Position
// DEFAULT-NOT: OpDecorate %gl_Position Invariant

struct VertexOutput {
#ifdef PRECISE_POSITION
  precise
#endif
  float4 position : SV_Position;
};

VertexOutput main(float3 position : POSITION) {
  VertexOutput output;
  output.position = float4(position, 1.0);
  return output;
}
