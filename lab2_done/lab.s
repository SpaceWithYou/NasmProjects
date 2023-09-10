bits 64
%define SetMode(x) mov r8, x
section .data
;matrix:     db 5, 10, 15, -20, 25, 2, 6, 9, 12, 18, 30, 35, 40, 45, 50 ;(5, 10, 15, -20, 25)(2, 6, 9, 12, 18)(30, 35, 40, 50)
matrix:     db -10, 4, 5, 1, 1, 1, 5, 6, 7, 16, 50, -3 ;(-10, 4, 5, 1)(1, 1, 5, 6)(7, 16, 50, -3)
rows:       equ 3 
cols:       equ 4 
min_elements: times rows db 0 
section .text
global _start
Swap_rows: ;принимает row1 - r10, row2 - r11
    push    rax
    push    rbx
    push    rdi      ;счетчик
    xor     rdi, rdi
swap_loop:
    cmp     rdi, cols 
    je      endloop
    movsx   rax, byte[r10 + rdi]
    movsx   rbx, byte[r11 + rdi]
    xchg    rax, rbx ; swap row1, row2
    mov     byte[r10 + rdi], al
    mov     byte[r11 + rdi], bl
    inc     rdi
    jmp     swap_loop
endloop:
    pop     rdi
    pop     rbx
    pop     rax
ret
_start:
    mov rbp, rsp; for correct debugging;Ищем минимальные элементы  
    mov     rsi, matrix
    mov     rdi, min_elements
    mov     r10, 0 ; счетчик строк
outer_loop:
    xor     rax, rax
    xor     rbx, rbx
    movsx   rax, byte[rsi + r10*cols]
    mov     r11, 1 ; счетчик элементов
inner_loop:
    cmp     r11, cols 
    je      end_inner_loop
    push    rax         ;effective adress
    mov     rax, r10
    mov     rcx, cols
    mul     rcx
    add     rax, r11
    mov     rcx, rax
    pop     rax
    movsx   rbx, byte[matrix + rcx]
    cmp     rbx, rax 
    cmovl   rax, rbx 
    inc     r11
    jmp     inner_loop
end_inner_loop:
    mov     byte[rdi + r10], al
    inc     r10
    cmp     r10, rows
    jl      outer_loop   
GnomeSort:
    SetMode(0)
    mov     rax, 1 ;i
    mov     rbx, 2 ;j
sort_loop:
    cmp     rax, rows  
    jge     Sort_end
    movsx   rcx, byte[rdi + rax - 1]
    cmp     r8, 1
    je      mD
    cmp     cl, byte[rdi + rax]
    jge     m1
    jmp     m2
mD:
    cmp     cl, byte[rdi + rax]
    jl      m1
    jmp     m2
m1:
    mov     rax, rbx
    inc     rbx
    jmp     sort_loop
m2:
    push    rax
    push    rbx
    mov     rbx, cols
    dec     rax
    mul     rbx
    ;lea     r10, [rsi + (rax - 1)*5]
    lea     r10, byte[rsi + rax]
    add     rax, cols
    ;lea     r11, [rsi + rax*5]
    lea     r11, byte[rsi + rax]
    pop     rbx
    pop     rax
    call    Swap_rows
    
    push    rax
    push    rbx
    push    rcx
    mov     rcx, rax
    movsx   rax, byte[rdi + rcx]
    movsx   rbx, byte[rdi + rcx - 1]
    xchg    rax, rbx
    mov     byte[rdi + rcx], al
    mov     byte[rdi + rcx - 1], bl
    pop     rcx
    pop     rbx
    pop     rax
    
    dec     rax
    cmp     rax, 0
    je      m3
    jmp     sort_loop
m3:
    mov     rax, rbx
    inc     rbx
    jmp     sort_loop
Sort_end:
exit:
    mov     eax, 60
    xor     ebx, ebx
    syscall
