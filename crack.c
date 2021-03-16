#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <openssl/evp.h>

static double rand_double() {
  return rand() * 1. / RAND_MAX;
}

static const int MAX_TIME = 300000;
static const int MIN_TIME = 100;

static void progress_bar() {
  for (int i = 0; i <= 26; i++) {
    printf("[");
    for (int j = 0; j < 26; j++) {
      printf("%c", j < i ? '#' : ' ');
    }
    printf("]");
    printf("\t%.1lf%%", ((double) i * 100) / 26);
    fflush(stdout);
    usleep(MIN_TIME + (rand_double() * (MAX_TIME - MIN_TIME)));
    printf("\r");
  }
  printf("\n");
}

const unsigned char
    md5_hash[] = {0x16, 0xcb, 0x36, 0x50, 0x57, 0x84, 0x00, 0x66, 0xd4, 0x84, 0x10, 0x0e, 0xc3, 0xa8, 0x45, 0x6c};
const unsigned char
    cracked_hash[] = {0xc6, 0xa7, 0xbc, 0x7c, 0xf8, 0x92, 0x86, 0xb7, 0x05, 0x7e, 0x89, 0xdf, 0xcb, 0xbd, 0x1b, 0x44};

static long fsize(FILE* fp) {
  long cur = ftell(fp);
  long size = 0;
  fseek(fp, 0, SEEK_END);
  size = ftell(fp);
  fseek(fp, cur, SEEK_SET);
  return size;
}

enum hash_status {
  OK, WRONG_FILE, CRACKED_FILE
};

static enum hash_status check_hash(const char* str, long size) {
  unsigned char md_value[EVP_MAX_MD_SIZE];
  unsigned md_size = 0;
  const EVP_MD* md = EVP_md5();

  EVP_MD_CTX* mdctx = EVP_MD_CTX_new();
  EVP_DigestInit_ex(mdctx, md, NULL);
  EVP_DigestUpdate(mdctx, str, size);
  EVP_DigestFinal_ex(mdctx, md_value, &md_size);
  EVP_MD_CTX_free(mdctx);

  if (strncmp((const char*) md_value, (const char*) md5_hash, md_size) == 0) return OK;
  if (strncmp((const char*) md_value, (const char*) cracked_hash, md_size) == 0) return CRACKED_FILE;
  return WRONG_FILE;
}

int main(int argc, char** argv) {
  srand(time(NULL));
  if (argc < 2) {
    fprintf(stderr, "Not enough args\n");
    return 1;
  }

  FILE* fp = fopen(argv[1], "rb");
  long size = fsize(fp);

  char* mem = malloc(size);
  fread(mem, 1, size, fp);
  fclose(fp);

  enum hash_status status = check_hash(mem, size);
  if (status == WRONG_FILE) {
    fprintf(stderr, "Wrong file\n");
    return 1;
  }

  if (status == CRACKED_FILE) {
    fprintf(stderr, "Already cracked\n");
    return 1;
  }

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

