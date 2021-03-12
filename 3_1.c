void printf(int fd, const char * format, ...);

int main() {
  printf(1, "test %d\n", 1);
  printf(1, "test %d\n", 2);
  printf(1, "test %d\n", 3);
  printf(1, "test %s %d %x %b %o %c, and I %s %x %d%%%c%b",
      "world", 1, 0x2f, 10, 0123, '$', "love", 3802, 100, 33, 255);
  return 0;
}
