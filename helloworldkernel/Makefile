all: kernel.c boot.S
	gcc -c kernel.c -I. -fno-builtin -nostdinc -O -g -Wall
	gcc -c boot.S -I.
	ld boot.o kernel.o -o dummy -e start -Ttext=0x100000
	cp -v dummy ../staging/iso/kernel

