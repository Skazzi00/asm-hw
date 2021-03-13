org  100h

section	.text

start:
    mov ah, 0x09
    mov dx, welcome_msg
    int 0x21

    mov cx, 0
.loop:
    
    mov ah, 0x01
    mov al, 0
    int 0x21

    cmp al, 0x0D
    je .out
   
    mov bx, cx 
    mov [.input_buffer + bx], al
    inc cx

    jmp .loop
.input_buffer:  db '$' dup (16)
.out:
    mov si, .input_buffer
    mov di, password

.check_loop:
    cmpsb
    jne  wrong_pass    
    loop .check_loop

    mov ah, 0x09
    mov dx, success_msg
    int 0x21
  
    mov ax, 0x4c00
    int 0x21


welcome_msg:   db "Enter your password: ", '$'

success_msg:   db "Success!", '$'

wrong_pass_msg: db "Wrong password. Exit.", '$'

password:      db "Hy47zBKK"
.len:          db $ - password

wrong_pass:

 
    mov ah, 0x09
    mov dx, wrong_pass_msg
    int 0x21
  
    mov ax, 0x4c00
    int 0x21   
