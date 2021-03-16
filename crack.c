#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>


static double rand_double() {
  return rand() * 1. / RAND_MAX;
}

static const int MAX_TIME = 300000;
static const int MIN_TIME = 100;

static void progress_bar() {
  for (int i = 0; i <= 26; i++) {
    printf("[");
    for (int j = 0; j < 26; j++)
      printf("%c", j < i ? '#' : ' ');
    printf("]");
    printf("\t%.1lf%%", ((double) i * 100) / 26);
    fflush(stdout);
    usleep(MIN_TIME + (rand_double() * (MAX_TIME - MIN_TIME)));
    printf("\r");
  }
  printf("\n");
}

int main(int argc, char** argv) {
  srand(time(NULL));
  if (argc < 2) {
    fprintf(stderr, "Not enough args\n");
    return 1;
  }

  FILE* fp = fopen(argv[1], "rb");

  long size = 0;
  fseek(fp, 0, SEEK_END);
  size = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  unsigned char* mem = malloc(size);
  fread(mem, 1, size, fp);
  fclose(fp);

  unsigned char rewrite[] = {0x90, 0x90, 0x90, 0x3a, 0xc0, 0x74, 0x22, 0x0d};

  for (int i = 0; i < sizeof(rewrite); i++) {
    mem[0x252 + i] = rewrite[i];
  }

  fp = fopen(argv[1], "wb");
  fwrite(mem, 1, size, fp);
  fclose(fp);

  free(mem);

  printf("Cracking...\n");
  progress_bar();
  printf("Done!\n");
  return 0;
}

