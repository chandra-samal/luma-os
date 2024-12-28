org 0x7C00
bits 16


%define ENDL 0x0D, 0x0A


;
; FAT12 header
; 
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number, the value doesn't really matter
ebr_volume_label:           db 'LUMA OS    '        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes

;
; Code goes here
;


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

    ; read something from floppy disk
    ; BIOS should DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                       ; LBA=1, second sector from the disk
    mov cl, 1                       ; 1 sector to read
    mov bx, 0x7E00                  ; data should be after the bootloader
    call disk_read


    ; printing the message 
    mov si, msg_welcome
    call printout
    cli
    hlt

floppy_error:
    mov si, msg_read_failed
    call printout
    jmp wait_key_and_reboot
    hlt

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; wait for a keypress
    jmp 0FFFFh:0                ; jumps to beginning of BIOS, should reboot the system

.halt:
    cli                         ; disable interrupts, this way CPU won't be able to get out of the "halt" state
    hlt


;
; Disk routines 
;


;
; will convert an LBA address to a CHS address
; Params:
;   - ax, it will contain the LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head 
;

;
; NOTE : Remainder and Quotients are stored in registers according to the mode, we are operating in 16-bit mode
; In 16-bit mode:
; The quotient is stored in ax register
; The remainder is stored in dx register
;

lba_to_chs:
    push ax
    push dx


    xor dx, dx                                          ; dx =  0
    div word [bdb_sectors_per_track]                    ; ax = LBA / SectorsPerTrack
                                                        ; dx = LBA % SectorsPerTrack

    inc dx                                              ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                                          ; cx = sector   

    xor dx, dx                                          ; dx = 0
    div word [bdb_heads]                                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder number
                                                        ; dx = (LBA / SectorsPerTrack) % Heads = head number

    ; The lower byte of dx(dl) stores the head number because it is small enough to fit in one byte (0-255)
    mov dh, dl                                          ; dh = head number 
    mov ch, al                                          ; ch = cylinder (lower 8 bits)
    shl ah, 6                       
    or cl, ah                                           ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                                          ; restores DL
    pop ax
    ret

;
; Reads sectors from a disk 
; Parameters:
;       - ax = LBA
;       - cl = number of sectors to read (up to 128)
;       - dl = drive number
;       - es:bx = memory address where to store read data
;

disk_read:
    push ax                             ; saving the registers that we are going to modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; temporarily saves CL(numbers of sectors to read) in the stack
    call lba_to_chs                     ; compute CHS and stores it in CX, and DH
    pop ax                              ; AL = number of sectors
    mov ah, 02h
    mov di, 3

.retry:
    pusha                               ; Saves all the registers, as we are unaware of what the BIOS will modify
    stc                                 ; sets carry flag
    int 13h                             ; carry flag cleared = success = jump out of the loop
    jnc .done                           

    ; failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; after all attempts have been exhausted 
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             ; restore registers modified 
    ret

;
; Resets Disk Controller
; Parameters:
;   dl = drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_welcome: db 'Welcome to Luma-OS', ENDL, 0
msg_read_failed: db 'Unable to read from the disk!', ENDL, 0


times 510-($-$$) db 0 
; `$` represents the current position in the code
; `$$` represents the start of the section (in this case, it represents org)
; `$-$$` calculates the size of the code so far
; `510-($-$$)` calculates how much padding is needed to make the size exactly 510 bytes
dw 0AA55h ; Adding the 2 byte Boot Signature at the end
