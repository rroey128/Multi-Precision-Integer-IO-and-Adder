section .data
    format db "%02x", 0
    tst: db "Got here", 10, 0 ; for testing
    int_format db "%d",10, 0
    char_fomat db "%c", 10, 0
    str_format db "%s",10, 0
    hexa_format db "%02x",0
    hex_format db "%x", 10, 0
    Number_end: db "", 10, 0
    bin_format db "%16b", 0
    buffer_size equ 600
    x_struct: db 5
    x_num: db 0xaa, 1,2,0x44,0x4f
    y_struct: db 6
    y_num: db 0xaa, 1,2,3,0x44,0x4f
    STATE dw 0xACE1
    MASK dw 0x002D 

section .bss
buffer resb buffer_size

section .text
global main
global getMaxMin
global add_multi
global rand_num
global PRmulti
extern printf
extern puts
extern fgets
extern malloc
extern strlen
extern stdin


main:
push ebp
mov ebp, esp
mov esi, [ebp+12]      ; get first arg
mov eax, [esi+4]
add esp, 8
test eax, eax           ; is there an argument?
je .handle_none
cmp word[eax], "-I"
jz .handle_I
cmp word[eax], "-R"
jz .handle_R
.handle_I:
  call getmulti
  mov ebx, eax
  push ebx
  call getmulti
  pop ebx
  call add_multi
  push eax
  call print_multi
  add esp, 4
  jmp .end
.handle_R:
  call PRmulti
  mov ebx, eax
  push ebx
  call PRmulti
  pop ebx
  push eax
  call print_multi
  push ebx
  call print_multi
  pop eax
  pop ebx
  call add_multi
  push eax
  call print_multi
  add esp, 4
  jmp .end
.handle_none:
  mov eax, x_struct
  mov ebx, y_struct
  call add_multi      ; after that eax holds the sum
  push eax
  call print_multi
  ; add esp, 4
.end:
; popa
;1a test
  ; push x_struct
  ; call print_multi
;1a test


;1b test (value of new struct is returned to eax at the end of the getmulti function)
; call getmulti
; push eax 
; call print_multi
;1b test

;2a test
;mov eax, my_struct
;mov ebx, my_struct2
;call getMaxMin
;2a test

;start 2b test
; mov eax, x_struct
; mov ebx, y_struct
; call add_multi      ; after that eax holds the sum
; push eax
; call print_multi
; add esp, 4
; add esp, 8
;end 2b test

; start rand_num test
; call rand_num
; push eax
; push hex_format
; call printf
; add esp, 8
; end rand_num test

;start PRmulti test
; call PRmulti
; push eax
; call print_multi
; call PRmulti
; push eax
; call print_multi
;end PRmulti test

; Part 4


pop ebp
 mov eax, 1 ; system call number for exit
 xor ebx, ebx ; exit status code (0)
 int 0x80 ; invoke the system call



print_multi:
push ebp ;storing current ebp status
mov ebp, esp ;moving stack pointer to ebp 
mov eax, [ebp+8] ; moving function's argument to eax : argument is a pointer to a struct with a number and it's size 
movzx ecx, byte [eax] ; moving to ecx first field of the struct - the size of the number to read in bytes 
lea edx, [eax+1] ; moving to edx the second field of the struct - pointer to an array of characters to read : [edx+eax] is now the first character i need to read
;mov edx, [eax+1] ; MOVING to edx the second field of the struct - pointer to an array of hexafigits values to read
;mov ebx, 0 ; setting ebx to 0, this will represent the number of bytes to substract from the pointer to the word 
sub ecx, 1
loop_start:
cmp ecx, 0 ; check if im done reading the number, as eax represents the number of bytes read, starting with the size of the number
jl loop_end ; fix it !
pushad
movzx ebx, byte [edx+ecx]  ;at the beginning of the loop - this is the last byte of the array. pushing it as an argument to printf #CAUSING SEGMENTATION FAULT
push ebx
push hexa_format
call printf
add esp, 8
popad
sub ecx, 1 ;substracting 1 from eax untill we read all the bytes in reverse order ("little endian")
jmp loop_start

loop_end:
  push Number_end
  call printf
  add esp, 4
pop ebp
mov eax, 0 ; ??
ret 


getmulti: 
push ebp ;storing current ebp status
mov ebp, esp ;moving stack pointer to ebp 
;pushad

;pushing arguments for fgets 
; debug
mov eax, [stdin]
mov ebx, 600
mov ecx, buffer ; most likely the problem is here because the buffer is uninitialized
; debug
push dword [stdin]
push dword 600
push buffer
call fgets ;after this call, the input from stding will reside in the buffer 
add esp, 12


push buffer ; pushing arguments for strlen  - the buffer pointer
call strlen ; after this call, eax will contain the size of the bytes read in the buffer (untill after the \n) = NUMBER OF CHARACTERS = NUMBER OF HEXA DIGITS
add esp, 4
sub eax, 1 ; ? check ?
;new code 
mov edx, eax 
and edx, 1
cmp edx, 0
jnz oddNumber
backFromOdd:
shr al, 1 ; dividing number by 2 - we have 2 hexa digits in each byte, and this is the number of bytes we want for our array of hexa values 

;creating a 'new struct' - reserving a space for it using malloc 
push eax
inc eax
push dword eax ; pushing size of the struct (1 byte for size, n bytes for the char array)
call malloc  ; returned pointer will be in eax
add esp, 4 ; clearing the stack 
mov esi, eax ; moving the pointer to the struct from eax to esi 
pop eax



;  ~~~~~~~~~~~~ I MAY NEED TO SUBSTRACT 1 FROM THIS SIZE ~~~~~~~~~~~~
mov byte [esi], al ; moving the buffer size to the first byte of the struct 


lea edi, [esi+1] ; storing the pointer to the char array in edi so I could access it's space 

; IN HERE I NEED TO PROCESS THE BUFFER BYTE BY BYTE (EACH BYTE IS A PAIR OF 2 HECADECIMAL DIGITS) AND PUT THE VALUE IN THE POINTER TO THE CHAR ARRAY

mov ecx, 0 ; counter for digits read 
mov edx, 0
loopStart:
movzx eax, byte [buffer+ecx] ; reading next byte from the buffer 
cmp al, 10 ; if the character is new line char, this is the end of the buffer 
je loopEnd
cmp al, '9' ; checks if the number is smaller than '9' - then it is certainly a number, or greater than '9' - then it is certainly a letter
jbe handleNumberAL ; handles numbers if the value is smaller then 9
ja handleLetterAL ; handles letters if the value is greater than 9
back:
inc ecx ; increment counter 
movzx ebx, byte [buffer+ecx] ; moving another character to bl 
cmp bl, 10
je oddCalc
shl al, 4 ; shifting 4 bits left to make room for another digit
;  movzx ebx, byte [buffer+ecx] ; moving another character to bl 
;  cmp bl, 10
;  je loopEnd
cmp bl, '9' ; checks if the number is smaller than '9' - then it is certainly a number, or greater than '9' - then it is certainly a letter
jbe handleNumberBL ; handles numbers if the value is smaller then 9
ja handleLetterBL ; handles letters if the value is greater than 9
back2:
or al, bl ; combining the two digits to 1 byte that represent two hexa digits 
inc ecx ; incrementing counter
mov [edi+edx], byte al ; store the byte (2 heca digits) in it's correct place in the char aray (-2 because we just read 2 characters using ecx)
inc edx 
; DEBUG : worked 

jmp loopStart



loopEnd:
;popad
mov eax, esi
pop ebp
ret 

handleNumberAL:
sub al, '0'
jmp back


handleLetterAL:
sub al, 'A'
add al, 10
jmp back

handleNumberBL:
sub bl, '0'
jmp back2


handleLetterBL:
sub bl, 'A'
add bl, 10
jmp back2


oddNumber:
inc eax
jmp backFromOdd

oddCalc:
inc ecx ; incrementing counter
mov [edi+edx], byte al ; store the byte (2 heca digits) in it's correct place in the char aray (-2 because we just read 2 characters using ecx)
inc edx 
jmp loopEnd

getMaxMin:
  push ebp ;storing current ebp status
  mov ebp, esp ;moving stack pointer to ebp 
  movzx ecx, byte [eax] ; moving to cl the size field of first struct
  movzx edx, byte [ebx] ; moving to dl the size field of the second struct
  cmp cl, dl 
  ja loopEnd2 ; first struct size field is greater than second struct size field, no need to do a thing 
  jb switch ; first struct size field is smaller than second struct size field, we need to switch the pointers
  loopEnd2:
  pop ebp
  ret

  switch:
  mov ecx, eax
  mov eax, ebx 
  mov ebx, ecx
  jmp loopEnd2

add_multi:
  push ebp
  mov ebp, esp
  sub esp, 8                  ; Allocate space for local variables

  push eax
  push ebx
  push esi
  push edi

  call getMaxMin               ; Get pointers to the structures with higher and lower lengths
  mov edx, ebx                 ; edx = pointer to structure with lower length
  mov ebx, eax                 ; ebx = pointer to structure with higher length
  ;pop ebx
  ;pop eax

  mov eax, ebx                 ; eax = max_len = length of structure with higher length

  sub esp, 4       ; Allocate space on the stack to save the registers
  mov [esp], edx   ; Save the value of %ecx on the stack

  add eax, 1                   ; Increase max_len by 1
  push eax
  call malloc                  ; Allocate memory for result array
  add esp, 4
  mov edi, eax                 ; edi = pointer to the result array
  ; pop eax

  mov edx, [esp] ; Restore the value of %edx from the stack
  add esp, 4       ; Deallocate the stack space
  xor ecx, ecx                 ; Initialize index variable
  mov eax, [ebx]  ; move the longer num to eax
  inc eax         ; inc its size by one ASSUME there wont be carry in the last one
  mov [edi+ecx], al ; move it to edi which will be returned
  and al, al ; CHECK - what to use for the carry
  pushf

.addition_loop:
  mov al, byte [ecx+ebx + 1]       ; Load byte from the higher length structure
  popf
  adc al, byte [ecx+edx + 1]       ; Add byte from the lower length structure
  pushf
  ; adc al, dl                   ; Add the carry from the previous addition
  mov [ecx+edi + 1], al            ; Store the result in the result array
  inc ecx                      ; Increment index
  cmp cl, byte[edx]            ; Compare the masked value with the value in %ecx
  jl .addition_loop            ; Jump if index < min_len

.remaining_loop:
  and al, 0                         ; reset al value
  popf
  adc al, byte [ecx+ebx + 1]       ; Load byte from the higher length structure
  pushf
  mov [ecx+edi + 1], al            ; Store the result in the result array
  inc ecx                      ; Increment index
  cmp cl, byte[ebx]                 ; Compare index with max_len
  jl .remaining_loop           ; Jump if index < max_len

  popf
  jnc no_carry
  mov al, 1
  mov [ecx+edi + 1], al
  jmp move_on
no_carry:
  mov eax, [edi]
  dec eax
  mov [edi], eax
move_on:
  ; Clean up and return the result array
  mov eax, edi                 ; Move the result array pointer to eax

  pop edi
  pop esi
  pop ebx
  mov esp, ebp
  pop ebp
  ret


rand_num:
  mov bx, [STATE]   ; bx will be state non-masked
  mov cx, 0         ; counter bit


.loop:
  mov ax, bx
  inc cx
  and ax, [MASK]     ; get relevant bits
  jp .even_parity    ; jump if party is even
  shr bx, 1         ; shift ah right
  and bx, 0x7FFF      ; set the MSB to 0
  mov [STATE], bx
  jmp .continue      
.even_parity:
  shr bx, 1
  or bx, 0x8000       ; set the MSB to 1
  mov [STATE], bx
.continue:
  ; cmp bx, [STATE]   ; stop condition - if ah equals start state
  ; jnz .loop          ; if they are not even, continue with the loop
  mov eax, ebx      ; mov the output to eax
  mov [STATE], bx
  ; rol eax, 16
  ret


PRmulti:
  push ebp
  mov ebp, esp
  sub esp, 8                  ; Allocate space for local variables

  ; push eax
  ; push ebx
  ; push esi
  ; push edi

  call rand_num
  and eax, 0x000000FF          ; get just 8-bits for size
  mov ecx, eax                 ; ecx will have the size of the number
  push ecx
  push eax
  call malloc                  ; Allocate memory for result
  add esp, 4
  pop ecx
  mov edi, eax                 ; edi = pointer to the result
  mov edx, 0                   ; counter
  mov [edi + edx], cl
.loop_multi:
  push ecx
  ; push edx
  call rand_num
  ; pop edx
  pop ecx
  inc edx                      ; Increment index
  mov [edx+edi], al            ; Store the result in the result array
  cmp edx, ecx           ; Compare the masked value with the value in %ecx
  jl .loop_multi            ; Jump if index < min_len

  mov eax, edi
  ; pop edi
  ; pop esi
  pop ebx
  mov esp, ebp
  pop ebp
  ret
