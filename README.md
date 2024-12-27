# luma-os
Luma is a lightweight, open-source operating system designed to provide a clean and efficient environment. Built from scratch, Luma focuses on simplicity, speed, and usability. This project aims to explore the fundamentals of OS development while creating a smooth and minimalistic user experience.

This Operating System is based on x86 Architechture, and assembly code is written according to the NASM-Assembler.

This OS has been designed to be Legacy Booted.

*Legacy Booting*

- BIOS loads first sector of memory from each bootable device into memory (always at the location 0x7C00, it has also been the industry standard to store the memory at that location.)

- BIOS checks for 0xAA55 signature (The BIOS wil check the memory until this signature is found, this signature marks the end of what we refer to as the "Boot Sector" or "Master Boot Record[MBR]". It indicates that the device is bootable. One important thing to note is that the signature is marked at the end of the first 512 bytes of a bootable storage device, the *last two bytes* of the *Boot Sector* is occupied by the signature.)

- Once the signature is found, it starts executing i.e. the OS boots up.

*Explaining the Assembly code*

- As you have noticed mentions of ax in the *main.asm* file, AX (or ax) is a 16-bit general purpose register. AX is further composed of two 8-bit registers, AH and AL, AH represents the higher 8 bits of AX and AL represents the lower 8 bits of AX. 
    Example: AX = 0x1234
                Then, AH = 0x12 (upper byte)
                      AL = 0x34 (lower byte)

- **loadsb** Instruction: The loadsb instruction is explicitly designed to lead a single byte from memory into AL, it will always uses AL by convention. 