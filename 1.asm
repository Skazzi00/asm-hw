org  100h

section	.text

VIDEOSEG	equ	0b800h
WIDTH_SIZE	equ 	80

START_LINE	equ	6
INIT_INDENT	equ	20
INIT_LENGTH	equ	40
ITER_CNT	equ 	10
END_LINE        equ     16
LAST_INNER_LINE	equ	END_LINE - 1

FINAL_INDENT    equ     INIT_INDENT - ITER_CNT
FINAL_LENGTH    equ     INIT_LENGTH + (ITER_CNT * 2)

TEXT_ATTR       equ     0x4E

START1_CHAR	equ 	0x4EC9
INNER13_CHAR	equ	0x4ECD
END1_CHAR	equ	0x4EBB

START3_CHAR	equ 	0x4EC8
END3_CHAR	equ	0x4EBC


START_END2_CHAR	equ 	0x4EBA
INNER2_CHAR	equ	0x4E00

SHADOW_CHAR	equ 	0x4b0

%define vmem(row,col) ((row)*80*2) + ((col)*2) - 2


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



start:
                mov dl, START_LINE
                mov ch, LAST_INNER_LINE
                mov dh, INIT_INDENT
                mov cl, INIT_LENGTH
                mov al, ITER_CNT

.anim_loop:     call draw_table
                call sleep
                dec  dh
                add  cl, 2
                dec  al
                jnz  .anim_loop


                npush 3, SHADOW_CHAR
                mov  dl, END_LINE + 1                   ;next line after end
                mov  dh, FINAL_INDENT + 2               ;shift 2 chars
                mov  al, FINAL_LENGTH - 1               ;shift 1 char
                call draw_line				;draw horizontal shadow


                mov cx, END_LINE - START_LINE + 1       ;height
                mov dl, START_LINE + 1                  
                mov dh, (FINAL_INDENT) + FINAL_LENGTH - 1 
                mov al, 2                               ;width

.vertical_loop:		
                call draw_line
                inc  dl
                loop .vertical_loop  			;draw vertical shadow


                movzx cx, byte [0x80]                   ;read length of message
                cmp   cx, 0
                je    .exit                             ;if (length == 0) exit

                dec cx
                mov si, 0x82
                mov di, vmem(START_LINE + 1, FINAL_INDENT + 4) 
                mov ah, TEXT_ATTR
                mov dx, 0                               ;dx - char counter

.text_loop      lodsb 
                stosw                                   ;print char with common attr
                inc dx
                cmp dx, FINAL_LENGTH - 6
                jl  .else                               ;if line is ended then go to new line

                ;new line calculations
                imul dx, 2
                sub  di, dx 
                add  di, (WIDTH_SIZE) * 2
                mov  dx, 0
                mov  ah, TEXT_ATTR

.else           loop .text_loop


.exit		mov ax, 0x4C00
                int 0x21                                ; return 0 



sleep:		;sleep for ? sec

                mpush ax,cx,dx
                

                mov cx, 0x0
                mov dx, 0x8480
                mov ah, 0x86
                int 0x15

                mpop ax,cx,dx

                ret



draw_table:	 ; dl - start, dh - indent, cl - length, ch - endline
                %define		cur_line dl
                %define		indent	 dh
                %define		length	 cl
                %define		endline  ch

                push bp
                mov  bp, sp
                push dx
                push ax

                mov  ax, VIDEOSEG	
                mov  es, ax		;set video segment
                call cls		;clear screen

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

                pop cx
                pop ax
                pop bp
                ret 



cls:
                push ax
                mov  ah, 0x00
                mov  al, 0x03
                int  0x10
                pop  ax
                ret

