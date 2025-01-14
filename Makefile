ASM=nasm
CC=gcc

TOOLS_DIR=tools
SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always tools_fat

all: floppy_image tools_fat

#
#	Floppy Image 
#
floppy_image:  $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
#creates a blank floppy image with size 1.44MB (512bytes/sector, 2880 sectors)
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880 
#formats the image with FAT12 and assings the vloume label with "NBOS"
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
#Writes the bootloader binary into the first 512 bytes of the image without truncating the rest
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc 
#Uses mcopy to add the kernel library (kernel.bin) to the floppy under the same name "kernel.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	

#
#	Bootloader
#

# The line below declares a dependency for the bootloader target. It means that the bootloader depends on the existence of the file mentioned.
# If the file doesn't exist or is out of date (compared to the source file), the commands below will be executed to generate it.
bootloader: $(BUILD_DIR)/bootloader.bin 

# the always target ensures that BUILD_DIR exists
$(BUILD_DIR)/bootloader.bin: always
# nasm compiles the assembly source code (boot.asm) into a flat binary file, the output is written into bootloader.bin file
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#
#	Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin


#
#	Tools
#
tools_fat: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c
#
#	Always
#
always:
	mkdir -p $(BUILD_DIR)


#
#	Clean
# 
clean:
	rm -rf $(BUILD_DIR)/*


