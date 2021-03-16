all: 3.1 3.2 4.1 4.2

3.1: 3.1.o printf.o
	ld -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lSystem 3_1.o printf.o -o 3.1

3.2: 3.2.o printf.o 3.2.asm.o
	ld -static 3_2.o printf.o 3_2_asm.o -o 3.2

4.1:
	nasm -f bin 4.asm -o 4.com

4.2:
	clang crack.c -o crack

3.1.o:
	clang -c 3_1.c

3.2.o:
	clang -c 3_2.c

3.2.asm.o:
	nasm -f macho64 3_2.asm -o 3_2_asm.o

printf.o:
	nasm -f macho64 printf.asm

clean:
	rm *.o
	rm 3.1 3.2 crack
	rm 4.com
