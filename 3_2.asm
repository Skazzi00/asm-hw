global start
extern _add
extern _printf
default rel

section .text

start:
  mov rdi, 3
  mov rsi, 5
  call _add

  mov rdi, 1
  lea rsi, [format]
  mov rdx, rax
  call _printf

  mov rax, 0x02000001
  xor rdi, rdi
  syscall ;exit

section .data

format: db "%d", 0
