global phys_copy
global phys_insw
global phys_insb
global phys_outsb
global phys_outsw
global phys_memset
global int86
global enable_irq
global disable_irq
global read_tsc
global idle_task

FLAT_DS_SELECTOR	equ	0x21
CLICK_SHIFT		equ	12
INT_CTLMASK		equ	0x21
INT2_CTLMASK		equ	0xA1


global cp_mess
global outb
extern irq_actids

extern level0_func



monitor:
mov esp,[dword 0x0]
mov dx,0x28
mov ds,dx
mov es,dx
mov fs,dx
mov gs,dx
mov ss,dx
pop edi
pop esi
pop ebp
o16 retf

int86:
hlt

;*===========================================================================*
;*				cp_mess					     *
;*===========================================================================*
; PUBLIC void cp_mess(int src, phys_clicks src_clicks, vir_bytes src_offset,
;		      phys_clicks dst_clicks, vir_bytes dst_offset);
; This routine makes a fast copy of a message from anywhere in the address
; space to anywhere else.  It also copies the source address provided as a
; parameter to the call into the first word of the destination message.
;
; Note that the message size, "Msize" is in DWORDS (not bytes) and must be set
; correctly.  Changing the definition of message in the type file and not
; changing it here will lead to total disaster.

CM_ARGS	equ	4 + 4 + 4 + 4 + 4	; 4 + 4 + 4 + 4 + 4
;		es  ds edi esi eip	proc scl sof dcl dof
cp_mess:
cld
push esi
push edi
push ds
push es

mov eax,FLAT_DS_SELECTOR
mov ds,ax
mov es,ax

mov esi,[esp+CM_ARGS+4]
shl esi,CLICK_SHIFT
add esi,[esp+CM_ARGS+4+4]
mov edi,[esp+CM_ARGS+4+4+4]
shl edi,CLICK_SHIFT
add edi,[esp+CM_ARGS+4+4+4+4]

mov eax,[esp+CM_ARGS]
stosd
add esi,byte +0x4
mov ecx,0x8
rep movsd

pop es
pop ds
pop edi
pop esi
ret


;*===========================================================================*
;*				exit					     *
;*===========================================================================*
; PUBLIC void exit();
; Some library routines use exit, so provide a dummy version.
; Actual calls to exit cannot occur in the kernel.
; GNU CC likes to call ___main from main() for nonobvious reasons.
exit:
_exit:
__exit:
sti
jmp exit

_main:
__main:
ret


;*===========================================================================*
;*				phys_insw				     *
;*===========================================================================*
; PUBLIC void phys_insw(Port_t port, phys_bytes buf, size_t count);
; Input an array from an I/O port.  Absolute address version of insw().
phys_insw:
push ebp
mov ebp,esp
cld
push edi
push es
mov ecx,FLAT_DS_SELECTOR
mov es,cx
mov edx,[ebp+0x8]
mov edi,[ebp+0xc]
mov ecx,[ebp+0x10]
shr ecx,1
rep insw
pop es
pop edi
pop ebp
ret

;*===========================================================================*
;*				phys_insb				     *
;*===========================================================================*
; PUBLIC void phys_insb(Port_t port, phys_bytes buf, size_t count);
; Input an array from an I/O port.  Absolute address version of insb().

phys_insb:
push ebp
mov ebp,esp
cld
push edi
push es
mov ecx,FLAT_DS_SELECTOR
mov es,cx
mov edx,[ebp+0x8]
mov edi,[ebp+0xc]
mov ecx,[ebp+0x10]
rep insb
pop es
pop edi
pop ebp
ret


;*===========================================================================*
;*				phys_outsw				     *
;*===========================================================================*
; PUBLIC void phys_outsw(Port_t port, phys_bytes buf, size_t count);
; Output an array to an I/O port.  Absolute address version of outsw().

align 16
phys_outsw:
push ebp
mov ebp,esp
cld
push esi
push ds
mov ecx,FLAT_DS_SELECTOR
mov ds,cx
mov edx,[ebp+0x8]
mov esi,[ebp+0xc]
mov ecx,[ebp+0x10]
shr ecx,1
rep outsw
pop ds
pop esi
pop ebp
ret


;*===========================================================================*
;*				phys_outsb				     *
;*===========================================================================*
; PUBLIC void phys_outsb(Port_t port, phys_bytes buf, size_t count);
; Output an array to an I/O port.  Absolute address version of outsb().
align 16
phys_outsb:
push ebp
mov ebp,esp
cld
push esi
push ds
mov ecx,FLAT_DS_SELECTOR
mov ds,cx
mov edx,[ebp+0x8]
mov esi,[ebp+0xc]
mov ecx,[ebp+0x10]
rep outsb
pop ds
pop esi
pop ebp
ret


;*==========================================================================*
;*				enable_irq				    *
;*==========================================================================*/
; PUBLIC void enable_irq(irq_hook_t *hook)
; Enable an interrupt request line by clearing an 8259 bit.
; Equivalent C code for hook->irq < 8:
;   if ((irq_actids[hook->irq] &= ~hook->id) == 0)
;	outb(INT_CTLMASK, inb(INT_CTLMASK) & ~(1 << irq));
align 16
enable_irq:
push ebp
mov ebp,esp
pushfd
cli
mov eax,[ebp+0x8]
mov ecx,[eax+0x8]
mov eax,[eax+0xc]
not eax
and [ecx*4+irq_actids],eax
jnz en_done
mov ah,~1
rol ah,cl
mov edx,INT_CTLMASK
cmp cl,0x8
jc enable_irq_0
mov edx,INT2_CTLMASK
enable_irq_0:
in al,dx
and al,ah
out dx,al
en_done:
popfd
leave
ret



;*==========================================================================*
;*				disable_irq				    *
;*==========================================================================*/
; PUBLIC int disable_irq(irq_hook_t *hook)
; Disable an interrupt request line by setting an 8259 bit.
; Equivalent C code for irq < 8:
;   irq_actids[hook->irq] |= hook->id;
;   outb(INT_CTLMASK, inb(INT_CTLMASK) | (1 << irq));
; Returns true iff the interrupt was not already disabled.
align 16
disable_irq:
push ebp
mov ebp,esp
pushfd
cli
mov eax,[ebp+0x8]
mov ecx,[eax+0x8]
mov eax,[eax+0xc]
or [ecx*4+irq_actids],eax
mov ah,0x1
rol ah,cl
mov edx,INT_CTLMASK
cmp cl,0x8
jc disable_irq_0
mov edx,INT2_CTLMASK
disable_irq_0:
in al,dx
test al,ah
jnz dis_already
or al,ah
out dx,al
mov eax,0x1
popfd
leave
ret
dis_already:
xor eax,eax
popfd
leave
ret


;*===========================================================================*
;*				phys_copy				     *
;*===========================================================================*
; PUBLIC void phys_copy(phys_bytes source, phys_bytes destination,
;			phys_bytes bytecount);
; Copy a block of physical memory.

PC_ARGS	equ	4 + 4 + 4 + 4	; 4 + 4 + 4
;		es edi esi eip	 src dst len
align 16
phys_copy:
cld
push esi
push edi
push es

mov eax,FLAT_DS_SELECTOR
mov es,ax

mov esi,[esp+PC_ARGS]
mov edi,[esp+PC_ARGS+4]
mov eax,[esp+PC_ARGS+4+4]

cmp eax,0xa
jc pc_small
mov ecx,esi
neg ecx
and ecx,byte +0x3
sub eax,ecx
es rep movsb
mov ecx,eax
shr ecx,0x2
es rep movsd
and eax,0x3
pc_small:
xchg eax,ecx
es rep movsb

pop es
pop edi
pop esi
ret

;*===========================================================================*
;*				phys_memset				     *
;*===========================================================================*
; PUBLIC void phys_memset(phys_bytes source, unsigned long pattern,
;	phys_bytes bytecount);
; Fill a block of physical memory with pattern.
align 16
phys_memset:
push ebp
mov ebp,esp
push esi
push ebx
push ds
mov esi,[ebp+0x8]
mov eax,[ebp+0x10]
mov ebx,FLAT_DS_SELECTOR
mov ds,bx
mov ebx,[ebp+0xc]
shr eax,0x2
fill_start:
mov [esi],ebx
add esi,byte +0x4
dec eax
jnz fill_start
mov eax,[ebp+0x10]
and eax,0x3
remain_fill:
cmp eax,0x0
jz fill_done
mov bl,[ebp+0xc]
mov [esi],bl
add esi,byte +0x1
inc ebp
dec eax
jmp remain_fill
fill_done:
pop ds
pop ebx
pop esi
pop ebp
ret


;*===========================================================================*
;*				mem_rdw					     *
;*===========================================================================*
; PUBLIC u16_t mem_rdw(U16_t segment, u16_t *offset);
; Load and return word at far pointer segment:offset.
align 16
mem_rdw:
mov ecx,ds
mov ds,[esp+0x4]
mov eax,[esp+0x8]
movzx eax,word [eax]
mov ds,cx
ret

;*===========================================================================*
;*				reset					     *
;*===========================================================================*
; PUBLIC void reset();
; Reset the system by loading IDT with offset 0 and interrupting.

reset:
lidt [idt_zero]
int3


;*===========================================================================*
;*				idle_task				     *
;*===========================================================================*
; This task is called when the system has nothing else to do.  The HLT
; instruction puts the processor in a state where it draws minimum power.
idle_task:
push halt
call level0
pop eax
jmp idle_task
halt:
sti
hlt
cli
ret


;*===========================================================================*
;*			      level0					     *
;*===========================================================================*
; PUBLIC void level0(void (*func)(void))
; Call a function at permission level 0.  This allows kernel tasks to do
; things that are only possible at the most privileged CPU level.
;
level0:
mov eax,[esp+0x4]
mov [level0_func],eax
int 0x22
ret

;*===========================================================================*
;*			      read_tsc					     *
;*===========================================================================*
; PUBLIC void read_tsc(unsigned long *high, unsigned long *low);
; Read the cycle counter of the CPU. Pentium and up. 
align 16
read_tsc:
rdtsc
push ebp
mov ebp,[esp+0x8]
mov [ebp+0x0],edx
mov ebp,[esp+0xc]
mov [ebp+0x0],eax
pop ebp
ret


;*===========================================================================*
;*			      read_flags					     *
;*===========================================================================*
; PUBLIC unsigned long read_cpu_flags(void);
; Read CPU status flags from C.
align 16
read_cpu_flags:
pushfd
mov eax,[esp]
popfd
ret

;*===========================================================================*
;*			      read_cr0					     *
;*===========================================================================*
; PUBLIC unsigned long read_cr0(void);
read_cr0:
push ebp
mov ebp,esp
mov eax,cr0
pop ebp
ret


;*===========================================================================*
;*			      write_cr0					     *
;*===========================================================================*
; PUBLIC void write_cr0(unsigned long value);
write_cr0:
push ebp
mov ebp,esp
mov eax,[ebp+0x8]
mov cr0,eax
jmp write_cr0
write_cr0_0
pop ebp
ret



;*===========================================================================*
;*			      write_cr3					     *
;*===========================================================================*
; PUBLIC void write_cr3(unsigned long value);
write_cr3:
push ebp
mov ebp,esp
mov eax,[ebp+0x8]
mov cr3,eax
pop ebp
ret

idt_zero:
	dd 0
