#!/usr/bin/env python3

import json
import pathlib
import sys


BITS_PER_GROUP = 8
PAYLOAD_BITS_PER_GROUP = 7
VBR_GROUP_COUNT = 5


def get_bit(data, bit_offset):
    return (data[bit_offset // 8] >> (bit_offset % 8)) & 1


def set_bit(data, bit_offset, value):
    mask = 1 << (bit_offset % 8)
    byte_offset = bit_offset // 8
    if value:
        data[byte_offset] |= mask
    else:
        data[byte_offset] &= ~mask


def read_vbr32(data, bit_offset):
    encoded = 0
    encoded_bit = 0
    current = bit_offset
    for group in range(VBR_GROUP_COUNT):
        for _ in range(PAYLOAD_BITS_PER_GROUP):
            encoded |= get_bit(data, current) << encoded_bit
            current += 1
            encoded_bit += 1
        continuation = get_bit(data, current)
        current += 1
        expected_continuation = group != VBR_GROUP_COUNT - 1
        if continuation != expected_continuation:
            raise ValueError(
                "unexpected VBR continuation bit at group {}".format(group))
    return encoded >> 1


def write_vbr32(data, bit_offset, value):
    encoded = value << 1
    current = bit_offset
    for group in range(VBR_GROUP_COUNT):
        for _ in range(PAYLOAD_BITS_PER_GROUP):
            set_bit(data, current, encoded & 1)
            encoded >>= 1
            current += 1
        set_bit(data, current, group != VBR_GROUP_COUNT - 1)
        current += 1


def main():
    if len(sys.argv) < 6:
        raise ValueError(
            "usage: verify_dxsc_offsets.py INPUT OFFSETS OUTPUT SENTINEL "
            "ID=VALUE ID=VALUE [ID=VALUE ...]")

    input_path = pathlib.Path(sys.argv[1])
    offsets_path = pathlib.Path(sys.argv[2])
    output_path = pathlib.Path(sys.argv[3])
    sentinel = int(sys.argv[4], 0)
    patches = {
        int(shader_id): int(value, 0)
        for shader_id, value in (item.split("=", 1) for item in sys.argv[5:])
    }

    offsets_json = json.loads(offsets_path.read_text(encoding="utf-8"))
    offsets = {int(shader_id): int(offset) for shader_id, offset in offsets_json.items()}
    if set(offsets) != set(patches):
        raise ValueError(
            "expected specialization IDs {}, found {}".format(
                sorted(patches), sorted(offsets)))

    bytecode = bytearray(input_path.read_bytes())
    for shader_id, replacement in patches.items():
        bit_offset = offsets[shader_id]
        original = read_vbr32(bytecode, bit_offset)
        expected = sentinel + shader_id
        if original != expected:
            raise ValueError(
                "specialization ID {} points to {:#x}, expected {:#x}".format(
                    shader_id, original, expected))
        write_vbr32(bytecode, bit_offset, replacement)

    output_path.write_bytes(bytecode)


if __name__ == "__main__":
    main()
