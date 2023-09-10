bits	64
;one point precison ss
section	.data
null        equ     0                   ; end of string
input_msg   db      "Input x: ", 10, null
epsilon_msg db	    "Input epsilon: ", 10, null
type_msg    db      "%f", null
sin_msg	    db	    "(sin(%3.6f))^3 = %3.6f", 10, null
filemode    db	    "a+", 10,  null
err_open_msg  db    "Error on open file", 10, null
term_msg    db	    "Term = %3.6f, # = %d", 10,  null
my_sin_calc db	    "Series calculations = %3.6f", 10, null
overflow_msg db	    "Overflow", 10, null
overflow_const dd   4294967295.0	;2^32 - 1
epsilon     dd      0.0
res_rh	    dd	    0.0
file_handler dq	    0
filename_default    db	    "text", null
filename    db      null
prog_name   db	    "/home/students/p/pavlov.av/lab4/lab", null
zero	    dd      0.0
one	    dd	    1.0
nine	    dd	    9.0
k           dd      0.75
_one	    dd	    -1.0
sum_temp    dd	    0.0
term_temp   dd	    0.0
section     .text
extern	printf
extern	scanf
extern  sin
extern  fopen
extern  fclose
extern	fprintf
extern	exit
extern  fabs
global  main
main:
push    rbp				;Save stack base
mov     rbp, rsp
mov	rcx, [rsp]
mov	rax, 0
cmp	rcx, 2
je	search
mov	rcx, [filename_default]
mov	[filename], rcx
jmp	_default
search:
mov	rcx, qword[rsp+288]
mov	rbx, [rcx]
mov	[filename],  rbx
;inc    rax
;cmp	rax, 40
;je	error_on_open
;mov	rcx, [rsp + 8*rax]
;cmp	rcx, prog_name
;je	get_filename
;jmp	search
;get_filename:
;inc     rax
;mov     rcx, [rsp + 8*rax]
;mov	[filename], rcx
_default:
sub     rsp, 80				;For local var's
mov	rdi, input_msg
xor	rax, rax			;For func output
call 	printf

mov	rdi, type_msg
lea	rsi, [rbp-8]
xor	rax, rax
call	scanf
movss	xmm0, [rbp-8]
cvtss2sd xmm1, xmm0
movsd	xmm0, xmm1
call	sin				;xmm0 = sin(x) - double, x - double
movss   [rbp-16], xmm0
cvtsd2ss xmm1, xmm0
movss 	xmm0, xmm1
mulss	xmm0, xmm1
mulss	xmm0, xmm1			;(sin(x))^3 - float

movss	[rbp - 16], xmm0
mov     rdi, sin_msg
;movss   xmm0, [rbp-8]
;movss   xmm1, [rbp-16]
cvtss2sd xmm0, [rbp-8]
cvtss2sd xmm1, [rbp-16]
mov     rax, 2
call    printf

xor	rax, rax
mov	rdi, epsilon_msg
call	printf

mov     rdi, type_msg
lea     rsi, [rbp-24]
xor     rax, rax
call    scanf
movss	[rbp-24], xmm0			;epsilon
jmp     rh_sin

global  pow
pow:					;get xmm0 in power rax > 0
push	rbp				;input - xmm0, rax; output - xmm0 = xmm0 ^ rax
mov	rbp, rsp
push	rax
movss	xmm1, [one]
movss	xmm5, xmm0
alg:
cmp	rax, 0
je	leave_pow
test	rax, 1
jz	pow_m1
jnz	pow_m0
pow_m0:
mulss	xmm1, xmm0
pow_m1:
mulss	xmm0, xmm0
;mulss	xmm1, xmm0
shr	rax, 1
jmp 	alg
leave_pow:
pop	rax
movss	xmm0, xmm1
leave
ret

rh_sin:
mov	rax, 1				;iter = n
mov	rbx, 1				;temp
movss	xmm0, [one]			;temp
movss	xmm1, [one]			;temp
movss	xmm2, [one]			;temp
movss	xmm3, [one]			;temp
movss	xmm4, [zero]			;result
movss	xmm5, [zero]			;delta
movss	xmm6, [zero]			;temp
series:
cmp	rax, 10000
je	overflow
movss	xmm5, [rbp-16]
subss	xmm5, xmm4
movss	xmm6, xmm0
cvtss2sd xmm0, xmm5
call    fabs
cvtsd2ss xmm5, xmm0
ucomiss xmm5, [rbp-24]
jb	end_program
movss	xmm0, xmm6
jmp	series_term
series_term:
movss   xmm2, [one]
movss   xmm3, [one]
mov	rbx, rax
add	rbx, rax
add	rbx, 2				;rbx = 2n + 2
cvtsi2ss xmm1, rbx
movss   xmm6, [rbp-8]
powx_factorial:				;x^(2n+1)/(2n+1)!
ucomiss xmm3, [overflow_const]
jae	overflow
movss   xmm6, [rbp-8]
divss   xmm6, xmm2
mulss	xmm3, xmm6
addss	xmm2, [one]
ucomiss	xmm1, xmm2
je	.m0
jne	powx_factorial
.m0:
sub	rbx, rax
xchg	rax, rbx
sub	rax, 2
movss	xmm0, [nine]
call	pow
xchg    rax, rbx
ucomiss xmm0, [overflow_const]          ;xmm0 = 9^n
jae	overflow
subss	xmm0, [one]
movss	xmm2, xmm0
mulss	xmm2, xmm3
mulss	xmm2, [k]
test    rax, 1
jnz	print_term
mulss	xmm2, [_one]
print_term:
mov	rbx, rax
mov	rdi, filename
mov	rsi, filemode
movss	[sum_temp], xmm4
movss	[term_temp], xmm2
call    fopen
cmp	rax, 0
jl	error_on_open
mov	rdi, rax
mov	[file_handler], rax
mov	rsi, term_msg
cvtss2sd xmm0, [term_temp]
mov	rdx, rbx
mov	rax, 4
call	fprintf
mov	rdi, [file_handler]
call	fclose
mov	rax, rbx
inc	rax
movss	xmm4, [sum_temp]
movss	xmm2, [term_temp]
addss	xmm4, xmm2
jmp	series

overflow:
mov	rdi, overflow_msg
xor	rax, rax
call	printf
mov	rax, -2
call 	exit

error_on_open:
mov	rdi, err_open_msg
xor	rax, rax
call 	printf
mov	rax, -1
call 	exit

end_program:
mov	rdi, my_sin_calc
cvtss2sd xmm0, xmm4
;movss	[rbp-16], xmm4
mov	rax, 2
call 	printf
mov	rax, 0
call 	exit
