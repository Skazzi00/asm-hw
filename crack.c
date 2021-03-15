#include <stdlib.h>
#include <stdio.h>

int main(int argc, char ** argv) {
  FILE * fp = fopen(argv[1], "rb");

  long size = 0;
  fseek(fp, 0, SEEK_END);
  size = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  unsigned char * mem = malloc(size);
  fread(mem, 1, size, fp);
  fclose(fp);

  unsigned char rewrite[] = {0x90, 0x90, 0x90, 0x3a, 0xc0,0x74, 0x22, 0x0d};

  for(int i = 0; i < sizeof(rewrite); i++) {
    mem[0x252 + i] = rewrite[i];
  }

  fp = fopen(argv[1], "wb");
  fwrite(mem, 1, size, fp);
  fclose(fp);
  return 0;
}

