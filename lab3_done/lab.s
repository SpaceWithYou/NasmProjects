bits 64
%define env_filename    %!FILENAME
section .data
null        equ     0             ; end of string
STD_out     equ     1             ; standard output
Sys_read    equ     0             ; system read file code
Sys_write   equ     1             ; system write code
Sys_open    equ     2             ; system file open code
Sys_close   equ     3             ; system file close code
Ronly       equ     000000q       ; read only mode
;Filename    db     "text", null
filename    db      env_filename, null
Buf_size    equ      1024         ; chars to read
Buf_overflow_size  equ  1023      ; buffer overflow size
;OBuf_size   equ     2048; chars to write
Error_msg_open   db     "er_openfile"
Error_msg_open_len   dq  11
Error_msg_read   db     "er_readfile"
Error_msg_read_len   dq  11
Error_msg_overflow  db "er_overflow"    
Error_msg_overflow_len  dq 11
section .bss
Read_buf    resb    Buf_size
;Write_buf   resb    OBuf_size
Write_buf   resb    2 * Buf_size
section .text
global _start
_start:
mov     rbp, rsp                  ; for correct debugging
mov     r8, 0                     ; index
jmp     file_open

file_open:                        ;Открытие файла
mov     rax, Sys_open
mov     rdi, filename
mov     rsi, Ronly
syscall
mov     rbx, rax    
cmp     rax, 0                    ;Здесь дескриптор файла
jl      error_open
jmp     file_read

file_read:                        ;Чтение файла
mov     rdi, rax        
mov     rax, Sys_read
mov     rsi, Read_buf
mov     rdx, Buf_size
mov     rcx, rax                  ;Количество прочитанных символов
syscall
jl      error_read
cmp     rcx, Buf_overflow_size    ;Проверка на переполнение
je      overflow     
jmp     close_file

close_file:                       ;Закрытие файла
mov     rax, Sys_close
mov     rdi, rbx
syscall
jmp     buf_read

buf_read:                         ;Обход буфера
mov      r8, 0                    ;Индекс последнего символа в буфере вывода
mov      r9, 0                    ;Индекс первого символа слова
mov      rax, -1                  ;Счетчик
mov      rcx, 0                   ;Is word?
mov      rbx, 0
mov      rdx, 0

loop1:
inc     rax
movzx   rdi, byte[rsi + rax]      ;Очередной символ
check:
cmp     rdi, 10                   ;Символ перехода строки
je      print
cmp     rdi, 0                    ;Если null переход
je      print
cmp     rdi, 9                    ;Если tab
je      copy_symbol
cmp     rdi, 32                   ;Если space
je      copy_symbol
cmp     rcx, 1
je      loop2
                                  ;Попали в слово
mov     r9, rax                   ;Сохраняем позицию
mov     rcx, 1
mov     rbx, 0 
dec     rax
jmp     loop1
loop2:
mov     [Write_buf + r8 + rbx], rdi
inc     rbx
jmp     loop1

copy_word:
add     r8, rbx
copy_symbol:                      ;Копируем " ", "\t", "\n"
cmp     rcx, 1
je      double_word
movzx   rdi, byte[rsi + rax]      ;Очередной символ
mov     [Write_buf + r8], rdi
inc     r8
jmp     loop1

double_word:
add      r8, rbx
mov      rcx, 0
mov      rbx, 0 
push     rax
sub      rax, r9                  ;Длина слова конец - начало + 1 
test     rax, 1
pop      rax
jz       m                  
jmp      copy_word

m:
mov     rdx, r9
doubling:
cmp     rax, rdx
je      copy_word
movzx   rdi, byte[rsi + rdx]      ;Очередной символ
mov     [Write_buf + r8 + rbx], rdi
inc     rbx
inc     rdx
jmp     doubling

print:
mov      rdx, r8
mov      rax, Sys_write
mov      rdi, STD_out
mov      rsi, Write_buf
syscall
jmp      exit

overflow:
mov     rax, Sys_write
mov     rdi, STD_out
mov     rsi, Error_msg_overflow
mov     rdx, qword [Error_msg_overflow_len]
syscall
jmp     exit

error_read:
mov     rax, Sys_write
mov     rdi, STD_out
mov     rsi, Error_msg_overflow
mov     rdx, qword [Error_msg_overflow_len]
syscall
jmp     exit

error_open:
mov     rax, Sys_write
mov     rdi, STD_out
mov     rsi, Error_msg_open
mov     rdx, qword [Error_msg_open_len]
syscall
jmp     exit

exit:
mov     rax, 60
xor     rdi, rdi           
syscall	
