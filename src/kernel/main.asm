org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
    jmp main ; sets the main as the entry point of our program

; The general practice is to set the segment as 0, and the offset as 0x7C00

;
; This function is used to print something on the screen
; Params:
;         - ds:si points to the string 
;
printout:
    ; save registers we will modify
    push si
    push ax

.loop:
    lodsb          ; loads a byte from the ds:si into the al register and then increments si
    or al, al      ; the or instruction performs a bitwise or, and stores the result on the left side, verify if the next character is null
    ; the above line will also modify the flag register, if al is 0(end of the string), the zero flag is set
    jz .done ; Jumps to the done label if the zero flag is set 
    
    mov ah, 0x0e ; 0x0e is the teletype output service of the BIOS Interupt 0x10 
    mov bh, 0 ; sets the page number to 0
    int 0x10 ; This calls the BIOS interupt 0x10 which uses AH to determine the function (in this case, it's teletype output) and al as the data input (in this case, it's the character of the string)
    
    jmp .loop

.done:
    ; pop restores the original value of AX and SI registers from the stack x
    pop ax 
    pop si
    ret

main:
    ; setup data segments
    ; ax is the destination register where the data will be stored. The AX register is a 16-bit general purpose regiser in x86 asse,b;y
    mov ax, 0 ; moves the value 0 into the AX regiser.
    mov ds, ax
    mov es, ax

    ; setup stack
    ; Stack is a memory accessed in FIFO manner (First In, First Out)
    mov ss, ax
    mov sp, 0x7C00 ; stack grows downward, and we set it up in such a way that it points towards the start of our Operating System

    ; printing the message 
    mov si, msg_1
    call printout


    hlt

.halt:
    jmp .halt

msg_1: db 'Welcome to Luma-OS', ENDL, 0


times 510-($-$$) db 0 
; `$` represents the current position in the code
; `$$` represents the start of the section (in this case, it represents org)
; `$-$$` calculates the size of the code so far
; `510-($-$$)` calculates how much padding is needed to make the size exactly 510 bytes
dw 0AA55h ; Adding the 2 byte Boot Signature at the end
