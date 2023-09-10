bits 64
section .text
extern round
global Rotate
Rotate:                 ;unsigned char *data = rdi, int width = rsi, int height = rdx, unsigned char *output = rcx, double sin(alpha) = xmm0, double cos(alpha) = xmm1; double o_width (.0) = xmm2, double (.0) o_height = xmm3; output - void
push rbp
mov rbp, rsp
sub rsp, 64
			;[rbp-8] -  o_width
			;[rbp-16] - o_height
			;[rpb-24] - cx
			;[rbp-32] - cy
                         ;[rbp-40] - add_x
                         ;[rbp-48] - add_y
                         ;[rbp-56] - o_width/2
                         ;[rbp-64] - o_height/2

mov r9, -1               ;r9 = i
mov r8, -1               ;r8 = j
mov rax, rsi
mov rbx, 2
push rdx
mov rdx, 0
div rbx
pop rdx
mov r12, rax            ;r12 = width/2
mov rax, rsi
and rax, 1
test rax, 1
jnz odd_width
sub r12, 1
odd_width:
mov [rbp-24], r12       ;cx
mov rax, rdx
push rdx
mov  rdx, 0
div rbx
pop rdx
mov rbx, rax            ;rbx = height/2
mov rax, rdx
and rax, 1
test rax, 1
jnz odd_height
sub rbx, 1
odd_height:
mov [rbp-32], rbx       ;cy
cvtsd2si rax, xmm2
mov [rbp-8], rax        ;o_width
and rax, 1
cmp rax, 0
jne  .m1
mov rax, [rbp-8]
push rdx
mov rdx, 0
mov rbx, 2
div rbx
pop rdx
mov [rbp-56], rax
cmp [rbp-24], rax
jl  .m1
mov qword[rbp-40], -1        ;add_x
jmp .m2
.m1: 
mov qword[rbp-40], 0
.m2:
cvtsd2si rax, xmm3           ;o_height
mov [rbp-16], rax
and rax, 1
cmp rax, 0
jne .m3
mov rax, [rbp-16]
push rdx
mov rdx, 0
mov rbx, 2
div rbx
pop rdx
mov [rbp-64], rax
cmp [rbp-32], rax
jl  .m3
mov qword[rbp-48], -1
jmp .for1
.m3:
mov qword[rbp-48], 0

mov rax, [rbp-8]
push rdx
mov rdx, 0
mov rbx, 2
div rbx
pop rdx
mov [rbp-56], rax

mov rax, [rbp-16]
push rdx
mov rdx, 0
mov rbx, 2
div rbx
pop rdx
mov [rbp-64], rax
.for1:                  ;for(int j = 0; j < height; j++)
inc r8
mov r9, -1
cmp r8, rdx
je  exit
.for2:                  ;for(int i = 0; i < width; i++)
inc r9
cmp r9, rsi
je  .for1
                        ;move point to center of img
mov r10, r9
sub r10, [rbp-24]
mov r11, r8
neg r11
add r11, [rbp-32]
                        ;rotate point
cvtsi2sd xmm2, r10      ;get_x
cvtsi2sd xmm3, r11
mulsd    xmm2, xmm1
mulsd    xmm3, xmm0
subsd    xmm2, xmm3
movsd    xmm4, xmm2
movsd    xmm6, xmm0
movsd    xmm0, xmm4
xor      rax, rax
push     rcx
push     rdx
push     r10
push     r11
push     rsi
call     round
pop      rsi
pop	 r11
pop	 r10
pop	 rdx
pop	 rcx
movsd    xmm4, xmm0     ;xmm4 = x
movsd    xmm0, xmm6

cvtsi2sd xmm2, r10      ;get_y
cvtsi2sd xmm3, r11
mulsd    xmm2, xmm0
mulsd    xmm3, xmm1
addsd    xmm2, xmm3
movsd    xmm5, xmm2
movsd    xmm6, xmm0
movsd    xmm0, xmm5
xor      rax, rax
push	 rcx
push	 rdx
push	 r10
push	 r11
push     rsi
call     round
pop      rsi
pop	 r11
pop	 r10
pop	 rdx
pop	 rcx
movsd    xmm5, xmm0
movsd    xmm0, xmm6      ;xmm5 = y

cvtsd2si r10, xmm4	;r10 = x
cvtsd2si r11, xmm5	;r11 = y
	                 ;move to old center;
add r10, [rbp-56]
add r10, [rbp-40]         ;new x

neg r11
add r11, [rbp-64]
add r11, [rbp-48]         ;new y

cmp r10, 0
jl  .for2
cmp r11, 0
jl  .for2
cmp r10, [rbp-8]
jge  .for2
cmp r11, [rbp-16]
jge  .for2

mov  rax, rsi
push rdx
mov  rdx, 0
mul  r8
add  rax, r9
mov  rbx, 3
mul  rbx
pop  rdx                  ;rax = (i + width * j)*3
movzx rbx, byte[rdi + rax]
push rbx
inc rax
movzx  rbx, byte[rdi + rax]
push rbx
inc  rax
movzx  rbx, byte[rdi + rax]
push rbx                  ;blue, green, red val's of pixel

mov rax, r11
push rdx
mov  rdx, 0
mul qword [rbp-8]
add rax, r10
mov rbx, 3
mul rbx                  ;rax = (y * o_width + x)*3
pop rdx
add rax, 2
pop rbx
mov byte[rcx + rax], bl
pop rbx
dec rax
mov byte[rcx + rax], bl
pop rbx
dec rax
mov byte[rcx + rax], bl

jmp .for2
exit:
xor rax, rax
leave
ret
