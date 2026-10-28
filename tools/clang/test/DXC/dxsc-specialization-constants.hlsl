// RUN: %dxc -T ps_6_0 -E main -Fo %t.dxil -Fc %t.ll %s
// RUN: FileCheck %s --check-prefix=MARKERS < %t.ll
// RUN: %dxsc -sv=1164413184 -o=%t.patched.dxil -f=%t.offsets.json %t.dxil | FileCheck %s --check-prefix=DXSC
// RUN: %dxc -dumpbin %t.patched.dxil | FileCheck %s --check-prefix=SENTINELS
// RUN: python %S/Inputs/verify_dxsc_offsets.py %t.patched.dxil %t.offsets.json %t.tampered.dxil 0x45678900 0=42 255=17
// RUN: %dxv %t.tampered.dxil -o %t.resigned.dxil | FileCheck %s --check-prefix=VALIDATED
// RUN: %dxc -dumpbin %t.resigned.dxil | FileCheck %s --check-prefix=PATCHED
// RUN: not %dxsc -sv=1164413184 -o=%t.missing-input.dxil -f=%t.missing-input.json 2>&1 | FileCheck %s --check-prefix=MISSING-INPUT
// RUN: not %dxsc -o=%t.missing-sentinel.dxil -f=%t.missing-sentinel.json %t.dxil 2>&1 | FileCheck %s --check-prefix=MISSING-SENTINEL
// RUN: %dxsc --help 2>&1 | FileCheck %s --check-prefix=HELP

// MARKERS-DAG: store volatile i32 0
// MARKERS-DAG: store volatile i32 255
// MARKERS-DAG: load volatile i32

// DXSC: Specialized Constants Patching succeeded.

// SENTINELS-DAG: i32 1164413184
// SENTINELS-DAG: i32 1164413439

// VALIDATED: Validation succeeded.

// PATCHED-DAG: i32 42
// PATCHED-DAG: i32 17

// MISSING-INPUT: dxsc: error: missing input DXIL file
// MISSING-SENTINEL: dxsc: error: missing -sv sentinel value

// HELP: OVERVIEW: dxsc patching
// HELP: -sv=<int>

int GetSpecializationConstant_Zero() {
  volatile int sc_Zero = 0;
  return sc_Zero;
}

int GetSpecializationConstant_Max() {
  volatile int sc_Max = 255;
  return sc_Max;
}

int2 main() : SV_Target {
  return int2(GetSpecializationConstant_Zero(),
              GetSpecializationConstant_Max());
}
