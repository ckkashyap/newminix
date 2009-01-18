INCLUDE=-I. -I $(SOURCE_ROOT)/include
CFLAGS=$(INCLUDE) -nodefaultlibs -nostdlib -static-libgcc -D_EM_WSIZE=4 -D_EM_PSIZE=4
CC=gcc

%o:%S
	gcc -c $(INCLUDE) $< -o $@

%o:%nasm
	nasm -f elf $< -o $@


dummy: all
	

clean:
	exec find . -name "*.o" -exec rm -f {} \;
