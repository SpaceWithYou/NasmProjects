    bits 64
    ; res=(a^3 + b^3)/(a^2 * c - b^2 * d + e)
    section .bss
    res: 
        resb 8
    temp: 
        resb 8
    section .data
    a: 
        dw 0
    b: 
        db 0
    c: 
        dd 234
    d: 
        dd 20
    e:
        dd 0
    section .text
    global _start
    _start:
        mov rbp, rsp; for correct debugging
        movzx   rax, word[a]
        movzx   rbx, word[a]
        mul     rbx
        mul     rbx             ;rax = a^3
        
        mov     rcx, rax
        movzx   rax, byte[b]
        movzx   rbx, byte[b]
        mul     rbx
        mul     rbx             ;rax = b^3, rcx = a^3
        add     rax, rcx
        jc      exit
        mov     [temp], rax
        
        movzx   rax, word[a]
        movzx   rbx, word[a]
        mul     rbx
        mov     ebx, dword[c]
        mul     rbx     
        mov     rsi, rax        ;rsi = a^2*c
        
        movzx   rax, byte[b]
        movzx   rbx, byte[b]
        mul     rbx
        mov     rbx, 0
        mov     ebx, dword[d]
        mul     rbx             ;rax = b^2*d
        
        cmp     rsi, rax
        jae      m1
        jmp     badexit
    m1:                         ;Результат вычитания - положительное число
        sub     rsi, rax
        mov     rax, 0
        mov     eax, dword[e]
        add     rax, rsi        ;rax = a^2*c - b^2*d + e
        ;jc      exit
        mov     rcx, rax
        mov     rax, qword[temp]
        cmp	rcx, 0
        je	badexit
        div     rcx
        mov     [res], rax
        jmp     exit
    badexit:
        jmp     exit
    exit:
        mov     rax, 60
        mov     rdi, 0
        syscall

