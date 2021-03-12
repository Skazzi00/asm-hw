compile3_1: 3_1.o printf.o
		ld -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lSystem 3_1.o printf.o 

compile3_2: 3_2.o printf.o 3_2_asm.o
	ld -static 3_2.o printf.o 3_2_asm.o

clean:
	rm *.o

3_1.o:
	clang -c 3_1.c

3_2.o:
	clang -c 3_2.c

3_2_asm.o:
	nasm -f macho64 3_2.asm -o 3_2_asm.o
printf.o:
	nasm -f macho64 printf.asm
