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
    ; the above line will also modify the flag register
    jz .done ; Jumps to the done label if the 0 flag is set
    
    mov ah, 0x0e
    mov bh, 0
    int 0x10
    
    jmp .loop

.done:
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
    mov si, msg_hello
    call printout


    hlt

.halt:
    jmp .halt

msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0 ; Pad with zeroes to occupy 510 bytes 
dw 0AA55h ; Adding the 2 byte Boot Signature at the end