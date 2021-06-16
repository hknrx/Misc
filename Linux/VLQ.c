#include <stdint.h>
#include <stdio.h>

// VLQ encoding (integer => variable-length quantity)
static void EncodeValue (uint64_t value, uint8_t* out) {
  while (value >= 128) {
    *out++ = value | 128;
    value -= 128;
    value >>= 7;
  }
  *out = value;
}

// VLQ decoding (variable-length quantity => integer)
static uint64_t DecodeValue (uint8_t* in) {
  uint64_t value = 0;
  uint8_t shift = 0;
  while (1) {
    uint8_t byte = *in;
    value += (uint64_t)byte << shift;
    if (!(byte & 128)) {
      return value;
    }
    shift += 7;
    ++in;
  }
}

// Test
int main (int argc, char** argv) {
  uint8_t vlq [10];
  uint64_t i = -1;
  for (i = 0; i < 0x10000000000; i = (i + 1) * 3) {
    EncodeValue (i, vlq);
    uint64_t j = DecodeValue (vlq);

    printf ("%llX =>", i);
    int c = 0;
    do {
      printf (" %02X", vlq [c]);
    } while (vlq [c++] > 127);
    printf (" => %llX\n", j);
  }
  return 0;
}
