section .data
    buffer db 64 dup(0)
    buff_len equ $ - buffer

section .text
    global _start

; NOTE: IN THE FOLLOWING COMMENTS, '*' COULD 
; MEAN EITHER A MEMORY DEREFERENCE OR A MULTIPLICATION
; IT SHOULD BE CLEAR WITH CONTEXT

_start:

    ; read(0, buffer, buff_len)
    mov rax,0
    mov rdi,0
    mov rsi,buffer
    mov rdx,buff_len
    syscall

    ; now convert number to integer
    mov rsi, buffer  ; rsi points to buffer
    xor rax, rax        ; accumulator = 0

.convert1:
    movzx rcx, byte [rsi] ; load byte
    cmp rcx, 10           ; check for newline
    je .done1
    sub rcx, '0'          ; convert ASCII to digit
    imul rax, rax, 10
    add rax, rcx
    inc rsi
    jmp .convert1

.done1:
    ; the input number is stored inside rax
    
;;;;;;;;;;;;;;;;; Task 1 : allocate memory ;;;;;;;;;;;;;;;;;;;;;
; Allocate memory for arr
; How to get arr?
; Two uses of the brk syscall (syscall number = 12)
; arr = brk(0);
; brk(arr + n*8); Why 8? Each element of arr is of 8 bytes.
;rax is n now
mov rdx,rax
mov rbx,rax
imul rbx,8; rbx = n*8
mov rax,12
xor rdi,rdi
syscall
test rax,rax
js .allocation_error
mov r12,rax;storing array base into r12
mov rdi,r12
add rdi,rbx;updating the array memory
mov rax,12
syscall
test rax,rax
js .allocation_error
jmp .alloc_ok
.allocation_error:
    ; Print error message or exit with error code
    mov rax,60        ; exit syscall
    mov rdi,1         ; non-zero exit code
    syscall
.alloc_ok:

;;;;;;;;;;;;;;;;;; Task 2 : Store local variables ;;;;;;;;;;;;;;;;;;;
; Store local variables (n and arr) in the stack
; Subtract 16 from the stack pointer to make space for them
; That is, rsp -= 16
; Now, *(rsp) = n
; *(rsp + 8) = arr
sub rsp,16
mov [rsp],rdx
mov [rsp+8],r12
;;;;;;;;;;;;;;;;;;; Task 3 : For loop 1 ;;;;;;;;;;;;;;;
; Make space on the stack for i
; That is, rsp -= 8
; Note now, *(rsp) = i, *(rsp + 8) = n and *(rsp + 16) = arr
; Store 0 in i, that is *(rsp) = 0
sub rsp,8
mov qword [rsp],0
.for1Begin:
    ; Write code to jump to for1End if i >= n
    mov rcx,[rsp+8];rcx->n
    mov rdx,[rsp];rdx->i
    cmp rdx,rcx
    jge .for1End
    ; Do array[i] = 0
    ; *(*(rsp + 16) + i*8) = 0 (Why 8? Because each element of the array is of 8 bytes)
    mov rcx,rdx
    imul rcx,8
    mov rbx,[rsp+16]
    add rbx,rcx
    mov qword [rbx],0
    ; load and increment i
    mov rdx,[rsp]
    inc rdx
    mov [rsp],rdx
    ; That is, *(rsp)++;
    ; Jump to for1Begin
    jmp .for1Begin
.for1End:
; Restore stack, rsp += 8
add rsp,8
;;;;;;;;;;;;;;;;;; Task 4 : For loop 2 ;;;;;;;;;;;;;;;;;;;;;
; Make space on the stack for i
; That is, rsp -= 8
; Note now, *(rsp) = i, *(rsp + 8) = n and *(rsp + 16) = arr
; Store 2 in i, that is *(rsp) = 2
sub rsp,8
mov qword [rsp],2
.for2Begin:
    ; Write code to jump to for2End if i >= n
    mov rcx,[rsp+8]
    mov rdx,[rsp]
    cmp rdx,rcx
    jge .for2End
    ; Write code to jump to else if array[i] != 0
    ; *(*(rsp + 16) + i*8) = array[i]
    mov rcx,rdx
    imul rcx,8
    mov rbx,[rsp+16]
    add rbx,rcx
    cmp qword [rbx],0
    jne .else
.if:
    ; Make space on the stack for j
    ; That is, rsp -= 8
    sub rsp,8
    ; Note now, *(rsp) = j. *(rsp + 8) = i, *(rsp + 16) = n and *(rsp + 24) = arr
    mov rdx, [rsp+8]
    mov rcx,rdx
    imul rcx,2
    mov [rsp],rcx
    ; Store i * 2 in j, that is *(rsp) = 2 * *(rsp + 8)
    .innerForBegin:
        ; Write code to jump to innerForEnd if j >= n
        mov rcx, [rsp]
        mov rdx,[rsp+16]
        cmp rcx,rdx
        jge .innerForEnd
        ; Write code to jump to innerElse if array[j] != 0
        ; *(*(rsp + 24) + j * 8) = array[j]
        mov rdx,rcx
        imul rdx,8
        mov rbx,[rsp+24]
        add rbx,rdx
        cmp qword [rbx],0
        jne .innerElse
        .innerIf:
        ; array[j] = i
        ; That is, *(*(rsp + 24) + j*8) = *(rsp + 8)
        mov rax,[rsp+8]
        mov qword [rbx],rax
        .innerElse:
        ; Load and do j += i
        ; That is, *(rsp) += *(rsp + 8)
        mov rcx,[rsp]
        mov rax,[rsp+8]
        add rcx,rax
        mov [rsp],rcx
        jmp .innerForBegin
        ; Jump to innerForBegin
    .innerForEnd:
    ; Restore the stack, rsp += 8
    add rsp,8
.else:
    ; load and increment i
    ; That is, *(rsp)++;

    mov rax,[rsp]
    inc rax
    mov [rsp],rax
    jmp .for2Begin
    ; Jump to for2Begin
.for2End:
; Restore stack, rsp += 8
add rsp,8
;;;;;;;;;;;;;;;;;;; Task 5 : For loop 3 ;;;;;;;;;;;;;;;;;;;;;
; Make space on the stack for i
; That is, rsp -= 8
sub rsp,8
; Note now, *(rsp) = i, *(rsp + 8) = n and *(rsp + 16) = arr
; Store 2 in i, that is *(rsp) = 2
mov qword [rsp],2
.for3Begin:
; Write code to jump to for3End if i >= n
mov rcx,[rsp]
mov rdx,[rsp+8]
cmp rcx,rdx
jge .for3End
; rax = array[i]
; That is, rax = *(*(rsp + 16) + i*8)
mov rdx,rcx
imul rdx,8
mov rbx,[rsp+16]
add rbx,rdx
mov rax, qword [rbx]
    ; Prints the number stored in rax to stdout
    cmp rax,0
    jne .do_convert
    mov byte [buffer], '0'
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 1
    syscall
    jmp .after_print
    .do_convert:
    mov rdi, buffer + 63 ; Start from the end of the buffer
    mov rbx, 10          ; Base 10 for conversion
    mov rcx, 0           ; Digit count
.convert_loop:
    xor rdx, rdx         ; Clear rdx for division
    div rbx             ; rax = rax / 10, rdx = rax % 10
    add dl, '0'         ; Convert digit to ASCII
    mov [rdi], dl        ; Store the digit in the buffer
    dec rdi              ; Move buffer pointer backwards    
    inc rcx              ; Increment digit count
    test rax, rax        ; Check if rax is zero
    jnz .convert_loop     ; If not zero, continue converting
    
    inc rdi
    mov rsi, rdi 
    mov rax, 1   
    mov rdi, 1        ; syscall: write
           ; rsi points to the start of the string
    mov rdx, rcx        ; rdx is the number of digits
    syscall             ; Write the string to stdout
    .after_print:

; load and increment i
; That is, *(rsp)++;
mov rax,[rsp]
inc rax
mov [rsp],rax
jmp .for3Begin
; Jump to for3Begin
.for3End:
; Restore stack, rsp += 8
add rsp,8
add rsp,16
    mov rax, 60
    xor rdi, rdi
    syscall