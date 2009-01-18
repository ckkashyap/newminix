extern cstart
global	start, _start

section .text
start:
_start:
	jmp skip_grub_signature

align	4
	
multiboot_header:
	dd 0x1BADB002
	dd 0x00000007
	dd -(0x1BADB002+0x00000007)
	dd 0 ; multiboot_header
	dd 0 ; _start
	dd 0 ; 
	dd 0 ; _end
	dd 0 ; skip_grub_signature


skip_grub_signature:
	mov	esp,stack_top

	push	$0
	popf

	push	ebx
	push	eax

	call	cstart

stack:
	times 0x4000 db 0
stack_top:
