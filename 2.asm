org  100h

section	.text

VIDEOSEG	equ	0b800h
WIDTH_SIZE	equ 	80


SET_CODE        equ     0x2 ; '1' key
DELETE_CODE     equ     0x3 ; '2' key

BINARY_MODE     equ     1
OCT_MODE        equ     3
HEX_MODE        equ     4
DEC_MODE        equ     10

OUTPUT_MODE     equ     DEC_MODE
START_LINE	equ	6
INDENT	equ	0

%if OUTPUT_MODE == BINARY_MODE
LENGTH	equ	24
%else 
LENGTH	equ	12
%endif

END_LINE        equ     11
LAST_INNER_LINE	equ	END_LINE - 1

TEXT_ATTR       equ     0x4E

START1_CHAR	equ 	0x4EC9
INNER13_CHAR	equ	0x4ECD
END1_CHAR	equ	0x4EBB

START3_CHAR	equ 	0x4EC8
END3_CHAR	equ	0x4EBC

START_END2_CHAR	equ 	0x4EBA
INNER2_CHAR	equ	0x4E00



%macro  mpush 1-* 

  %rep  %0 
        push    %1 
  %rotate 1 
  %endrep 

%endmacro

%macro npush 2

  %rep %1
        push    %2
  %endrep

%endmacro

%macro  mpop 1-* 

  %rep %0 
  %rotate -1 
        pop     %1 
  %endrep 

%endmacro

%macro popw 0-1 1
        add sp, 2 * %1
%endmacro


jmp start

set_interrupt:  ;dx - new interrupt
                ;bx - interrupt number
                ;si - ptr to store old interrupt address
                mpush   cx, es, bx, dx
                xor     cx, cx
                mov     es, cx
                imul    bx, 4           ; sizeof(ID)
                mov     cx, es:[bx]
                mov     cs:[si], cx     ;save offset
                mov     cx, es:[bx + 2]
                mov     cs:[si + 2], cx ;save segment
        
                cli
                mov     es:[bx], dx 
                mov     dx, cs
                mov     es:[bx + 2], dx ;set new interrupt
                sti

                mpop    cx, es, bx, dx
                ret

reg_int_9:
                mpush   ax, dx, ds, bx, si, cx, es

                in      al, 0x60                   ; get scan code from keyboard
                
                cmp     al, DELETE_CODE  
                je      .delete

                cmp     al, SET_CODE 
                jne     .end_int

                cmp     byte cs:[is_reg_enable], 1 ; if dont need to replace
                je     .end_int

                mov     ax, cs
                mov     ds, ax

                mov     dx, draw_reg_monitor       ; add reg monitor
                mov     bx, 8            
                mov     si, old_int_8
                call    set_interrupt

                mov     byte cs:[is_reg_enable], 1 

                jmp     .end_int

.delete:        cmp     byte cs:[is_reg_enable], 1 
                jne     .end_int
                
                xor     cx, cx
                mov     es, cx          ; es = 0
                mov     bx, 8 * 4       
                mov     ax, word cs:[old_int_8]         
                mov     es:[bx], ax                     ; save offset      
                mov     ax, word cs:[old_int_8 + 2]
                mov     es:[bx + 2], ax                 ; save segment
                mov     byte cs:[is_reg_enable], 0
                
.end_int:       mpop    ax, dx, ds, bx, si, cx, es

                db      0xEA                            ; jmp code
old_int_9:      dd      0              


is_reg_enable:  db      0x0

draw_reg_monitor:
                mpush ax, dx, cx, di, si, ds
                mpush dx, cx, bx, ax
                mov ax, cs
                mov ds, ax
                mov dl, START_LINE
                mov ch, LAST_INNER_LINE
                mov dh, INDENT
                mov cl, LENGTH
                call draw_table

                pop ax
                mov di, 7
                mov si, 2
                mov cx, 2 ; hard code but optimize
                mov bx, reg_name_ax
                call draw_reg

                pop ax
                inc di
                mov bx, reg_name_bx
                call draw_reg

                pop ax
                inc di
                mov bx, reg_name_cx
                call draw_reg

                pop ax
                inc di
                mov bx, reg_name_dx
                call draw_reg

                mpop ax, dx, cx, di, si, ds
                db      0xEA                         ; jmp code
old_int_8:      dd      0x0 


reg_name_ax        db "AX"
reg_name_ax_end:

reg_name_bx        db "BX"
reg_name_bx_end:

reg_name_cx        db "CX"
reg_name_cx_end:

reg_name_dx        db "DX"
reg_name_dx_end:

draw_reg:       ; di - line number
                ; si - indent
                ; ax - value
                ; bx - name addr
                ; cx - length
                mpush bp, es, cx, di, bx, si, ax
                mov ax, VIDEOSEG
                mov es, ax
                imul di, 80 * 2
                imul si, 2
                add di, si
                mov ah, TEXT_ATTR
                
.loop:          
                mov al, [bx]
                stosw
                inc bx
                loop .loop
%if OUTPUT_MODE == 10
                mov bp, sp
                mov ax, [bp]
                call num_str
%else
                mov al, OUTPUT_MODE
                mov bp, sp
                mov bx, [bp]
                call bin_str
%endif

                mov ah, TEXT_ATTR
                add di, 2

.loop_num:      cmp byte [si], '$'
                je  .out
                lodsb
                stosw
                jmp .loop_num
.out:           mpop bp, es, cx, di ,bx, si, ax
                ret


bin_str:        ; result address of string in si
                %define mode   al ; 1 - binary, 3 - oct, 4 - hex
                %define number bx

                mpush ax, bx, dx, cx, di, es
                std
                mov di, bin_str_buf_end - 1
                
                xchg cx, ax
                mov ax, ds
                mov es, ax
                xchg cx, ax
                xor dx, dx        ; mask = 0
                movzx cx, al      ; move length of mask

                mov si, 1       
.loop:          
                or dx, si
                shl si, 1
                loop .loop           


.loop_str:      mov cx, bx
                and cx, dx
                xchg mode, cl
                shr bx, cl
                xchg mode, cl

                mov si, num_char
                add si, cx 
                movsb

                cmp bx, 0
                jne .loop_str
                mov si, di
                inc si
                cld
                mpop ax, bx, dx, cx, di, es
                ret

div_table:
                dw 10000
                dw 1000
                dw 100
                dw 10
                dw 1
                dw 0

num_str: ; ax - number
                mpush ax, bx, dx, di, es
                mov bx, ds
                mov  es, bx
                mov  di, num_str_buf
                mov  bx, div_table
.next_digit:
                xor dx,dx          
                div word [bx]      ;ax = quotient, dx = remainder
                mov si, num_char
                add si, ax
                movsb
                mov ax, dx           ;ax = remainder
                add bx, 2            ;bx = address of next divisor
                cmp word [bx], 0     
                jne .next_digit
                mov al, '$'
                stosb
                mpop ax, bx, dx, di, es
                mov si, num_str_buf
                ret



num_char:       db '0123456789ABCDEF'

bin_str_buf:    db 17 dup ('$')
bin_str_buf_end:

num_str_buf:    db 17 dup ('$')


;------------------------------TABLE---------------------------------------;

draw_table:	 ; dl - start, dh - indent, cl - length, ch - endline
                %define		cur_line dl
                %define		indent	 dh
                %define		length	 cl
                %define		endline  ch

                push bp
                mov  bp, sp
                push dx
                push ax
                push es

                mov  ax, VIDEOSEG	
                mov  es, ax		;set video segment

                mov  al, length	
                push START1_CHAR
                push INNER13_CHAR
                push END1_CHAR
                call draw_line 		;draw first line
                add  sp, 6		;clear stack

                push START_END2_CHAR
                push INNER2_CHAR
                push START_END2_CHAR	;pass args for inner table

.loop:		
                inc  cur_line		;lines iterate
                call draw_line
                cmp  cur_line, endline		
                jne  .loop
                add  sp, 6		;clear stack

                push START3_CHAR
                push INNER13_CHAR
                push END3_CHAR
                inc  cur_line
                call draw_line		;draw last line
                add  sp, 6		;clear stack

                pop es
                pop ax
                pop dx
                pop bp
                ret



draw_line:	
                %push
                %stacksize     large
                %arg           end_char:word,  inner_char:word, start_char:word
                %define		line_index  dl
                %define		indent      dh
                %define 	length	    al

                push bp
                mov  bp, sp
                
                push ax
                push cx
                push di
        

                mov   di, WIDTH_SIZE * 2
                movzx cx, line_index
                imul  di, cx
                movzx cx, indent
                add   di, cx
                add   di, cx  		;calc line start in VMEM

                movzx cx, length 	;move number of line
                sub   cx, 2             ;sub end & start

                mov ax, [start_char]
                stosw	                ;draw first 

                mov ax, [inner_char]		
                rep stosw               ;draw inner
              
                mov ax, [end_char]	;draw end 
                stosw

                pop di
                pop cx
                pop ax
                pop bp
                ret 

program_end:

start:
                mov dx, reg_int_9
                mov bx, 9
                mov si, old_int_9
                call set_interrupt       ;set reg monitor interrupt

                mov     ax, 0x3100
                mov     dx,  program_end 
                shr     dx, 4
                inc     dx

                int     0x21             ; save resident