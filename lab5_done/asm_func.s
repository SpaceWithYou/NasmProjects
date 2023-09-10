section .text
section .data
o_width dq 0
o_height dq 0
width_2  dq 0           ;width / 2
height_2 dq 0           ;height/2
extern round
global Rotate
Rotate:                 ;unsigned char *data = rdi, int width = rsi, int height = rdx, unsigned char *output = rcx, double sin(alpha) = xmm0, double cos(alpha) = xmm1; double o_width (.0) = xmm2, double (.0) o_height = xmm3; output - void
push rbp
mov rbp, rsp
mov r9, -1              ;r9 = i
mov r8, -1              ;r8 = j

mov rax, rsi
mov rbx, 2
div rbx
mov r12, rax            ;r12 = width/2
mov rax, rdx
div rbx
mov rbx, rax            ;rbx = height/2
mov [width_2], r12
mov [height_2], rbx

cvtsd2si rax, xmm2
mov [o_width], rax
cvtsd2si rax, xmm3
mov [o_height], rax
.for1:                  ;for(int i = 0; i < height; i++)
inc r9
cmp r9, rdx
je  exit
.for2:                  ;for(int j = 0; j < width; j++)
inc r8
cmp r8, rsi
je  .for1
                        ;move point to center of img    
mov r10, r9
sub r10, [width_2]            
mov r12, rsi
and r12, 1
not r12
sub r10, r12            ;r10 = a = i - width / 2 - !(width & 1);
neg r8
mov r11, r8
neg r8
add r11, [height_2]     ;r11 = b = -j + height / 2 + !(height & 1);
mov r12, rdx
and r12, 1
not r12
add r11, r12
                        ;rotate point
cvtsi2sd xmm2, r10
cvtsi2sd xmm3, r11
mulsd    xmm2, xmm1
mulsd    xmm3, xmm0
subsd    xmm2, xmm3     
movsd    xmm4, xmm2     
movsd    xmm6, xmm0
movsd    xmm0, xmm4
xor      rax, rax
call     round
movsd    xmm4, xmm0     ;xmm4 = x
movsd    xmm0, xmm6
                              
cvtsi2sd xmm2, r10
cvtsi2sd xmm3, r11
mulsd    xmm2, xmm0
mulsd    xmm3, xmm1
addsd    xmm2, xmm3
movsd    xmm5, xmm2     
movsd    xmm6, xmm0
xor      rax, rax
call     round
movsd    xmm5, xmm0
movsd    xmm0, xmm6     ;xmm5 = y

cvtsd2si r10, xmm4
cvtsd2si r11, xmm5
	                ;move to old center;
add r10, r10            
mov rax, [o_width]
mov rbx, 2
div rbx
add r10, rax
mov rax, [o_width]
and rax, 1
not rax
add r10, rax           ;x += o_width / 2 + !(o_width & 1);

neg r11
mov rax, [o_height]
mov rbx, 2
div rbx
add r11, rax
mov rax, [o_height]
and rax, 1
not rax
sub r11, rax
sub r11, rax          ;y = -y + o_height / 2 - 2 * !(o_height & 1);

cmp r10, 0
jl  .for2
cmp r11, 0
jl  .for2
cmp r10, [o_width]
jg  .for2
cmp r11, [o_height]
jg  .for2

mov  rax, rsi
mul  r8
add  rax, r9
mov  rbx, 3
mul  rbx                 ;rax = (i + width * j)*3
mov rbx, [rdi + rax]
push rbx
inc rax
push rbx
inc rax               ;blue, green, red val's of pixel

mov rax, r11
mul qword [o_width]
add rax, r10
push rdx
mov  rdx, 3
mul rdx
pop rdx
add rax, 3
mov [rcx + rax], rbx
pop rbx
dec rax
mov [rcx + rax], rbx
pop rbx
dec rax
mov [rcx + rax], rbx

jmp .for2
exit:
xor rax, rax
leave
ret
