; /usr/local/bin/nasm -f macho64 printf.asm 
default rel

global _printf
section .text

_printf:     ;  void printf(int fd(rdi), const char * format(rsi), ...)

    mov rax, [rsp] ; save return addr
    mov [rsp], r9  ; 4 arg
    push r8        ; 3 arg
    push rcx       ; 2 arg
    push rdx       ; 1 arg
    push rax       ; return addr
    push rbp
    
    mov rbp, rsp
    mov rdx, rbp ; rdx is arg pointer
    add rdx, 16
    mov r11, rdi    ; save fd 
    lea rdi, [printf_buffer] ; rdi is pointer to end of result string
    push rbx
.print_loop:

    lodsb       ; al = *(rsi++);
    cmp al, 0   ; if (al == 0) break; 
    je .print_loop_out

    cmp al, '%'
    je .parse_arg ; if (al =='%') goto .parse_arg;

    stosb
    jmp .print_loop

.parse_arg:
    lodsb        ; al = *(rsi++); "%[s|b|o|x|d]"
    cmp al, '%'  ; if (al == '%') stosb
    jne .else
    stosb
    jmp .print_loop
.else:
    sub al, 'b'  
    cmp al, 'x' - 'b'   ; if al > all cases char codes
    ja .default_switch
    movzx rax, al  
    lea rbx, [.jmp_table]
    mov rax, [rbx + 8 * rax]
    jmp rax

.jmp_table:
        dq   .binary_print   ; b
        dq   .char_print     ; c
        dq   .digit_print    ; d
        dq   .default_switch ; e
        dq   .default_switch ; f
        dq   .default_switch ; g
        dq   .default_switch ; h
        dq   .default_switch ; i
        dq   .default_switch ; j
        dq   .default_switch ; k
        dq   .default_switch ; l
        dq   .default_switch ; m
        dq   .default_switch ; n
        dq   .oct_print      ; o
        dq   .default_switch ; p
        dq   .default_switch ; q
        dq   .default_switch ; r
        dq   .string_print   ; s
        dq   .default_switch ; t
        dq   .default_switch ; u
        dq   .default_switch ; v
        dq   .default_switch ; w
        dq   .hex_print      ; x

%macro call_nts 1
    push rsi
    xor rsi, rsi
    mov esi, [rdx]
    add rdx, 8
    push rdx
    mov rdx, %1
    call num_to_str

    pop rdx
    pop rsi
%endmacro

.char_print:
    mov al, byte [rdx]
    add rdx, 8
    stosb
    jmp .print_loop

.digit_print:
    call_nts 10
    jmp .print_loop
.string_print:
    push rsi
    mov rsi, [rdx]
    add rdx, 8

.copy_loop:    
    cmp byte [rsi], 0
    je .copy_out
    movsb
    jmp .copy_loop    
.copy_out:
    pop rsi
    jmp .print_loop

.hex_print:
    mov al, '0'
    stosb
    mov al, 'x'
    stosb
    
    call_nts 16
    jmp .print_loop

.binary_print:
    mov al, '0'
    stosb
    mov al, 'b'
    stosb
    call_nts 2
    jmp .print_loop


.oct_print:
    mov al, '0'
    stosb
    call_nts 8
    jmp .print_loop

   

.default_switch:
    jmp .print_loop

.print_loop_out:
    lea     rsi, [printf_buffer]
    mov     rdx, rdi
    sub     rdx, rsi
    mov     rax, 0x2000004 ; write
    mov     rdi, r11       ; fd
    
    syscall
    
    pop rbx
    pop rbp
    pop rax
    add rsp, 32
    push rax
    ret 


num_to_str: ; void num_to_str(void *buffer(rdi), int num(rsi), int radix(rdx))
            ; destroy: r9, rax, rdx, rsi 
            ; rdi is end of destintation string    
    mov r9, rdx
    push rdi
    mov rax, rsi
    lea rdi, [num_to_str_buf_end - 1]
    std
    
.loop:
    cmp rax, 0
    je .out
    xor rdx, rdx
    div r9
    lea rsi, [numchar]
    add rsi, rdx
    movsb
        

    jmp .loop
.out:
    cld
    ;write to buffer
    inc rdi
    mov rsi, rdi
    pop rdi 
    
.copy_loop:
    cmp byte [rsi], 0
    je .copy_out
    movsb
    jmp .copy_loop    
.copy_out:
    mov byte [rdi], 0 

    ret

section .bss

printf_buffer:      resb    1024
num_to_str_buf:     resb    128
num_to_str_buf_end: resb    128
section .data

numchar:  db    "0123456789ABCDEFGHIKLMNOPQRSTVXYZ", 0
