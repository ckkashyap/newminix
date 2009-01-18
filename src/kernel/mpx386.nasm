extern irq_handlers
extern intr_handle
extern irq_actids
extern k_reenter
extern next_ptr
extern sys_call
extern proc_ptr
extern tss
extern exception
extern level0_func

extern gdt
extern main
global set_the_new_descriptors

global	divide_error
global	single_step_exception
global	nmi
global	breakpoint_exception
global	overflow
global	bounds_check
global	inval_opcode
global	copr_not_available
global	double_fault
global	copr_seg_overrun
global	inval_tss
global	segment_not_present
global	stack_exception
global	general_protection
global	page_fault
global	copr_error
global restart

global s_call
global level0_call

global	hwint00	
global	hwint01
global	hwint02
global	hwint03
global	hwint04
global	hwint05
global	hwint06
global	hwint07
global	hwint08
global	hwint09
global	hwint10
global	hwint11
global	hwint12
global	hwint13
global	hwint14
global	hwint15

INT_CTL         equ	0x20    ;; I/O port for interrupt controller */
INT_CTLMASK     equ	0x21    ;; setting bits in this port disables ints */
INT2_CTL        equ	0xA0    ;; I/O port for second interrupt controller */
INT2_CTLMASK    equ	0xA1    ;; setting bits in this port disables ints */

END_OF_INT	equ	0x20

WORD_SIZE       equ       4      ; Machine word size.
; Offsets in struct proc. They MUST match proc.h.
P_STACKBASE     equ       0
GSREG           equ       P_STACKBASE
FSREG           equ       GSREG + 2       ; 386 introduces FS and GS segments
ESREG           equ       FSREG + 2
DSREG           equ       ESREG + 2
DIREG           equ       DSREG + 2
SIREG           equ       DIREG + WORD_SIZE
BPREG           equ       SIREG + WORD_SIZE
STREG           equ       BPREG + WORD_SIZE       ; hole for another SP
BXREG           equ       STREG + WORD_SIZE
DXREG           equ       BXREG + WORD_SIZE
CXREG           equ       DXREG + WORD_SIZE
AXREG           equ       CXREG + WORD_SIZE
RETADR          equ       AXREG + WORD_SIZE       ; return address for save() call
PCREG           equ       RETADR + WORD_SIZE
CSREG           equ       PCREG + WORD_SIZE
PSWREG          equ       CSREG + WORD_SIZE
SPREG           equ       PSWREG + WORD_SIZE
SSREG           equ       SPREG + WORD_SIZE
P_STACKTOP      equ       SSREG + WORD_SIZE
P_LDT_SEL       equ       P_STACKTOP
P_LDT           equ       P_LDT_SEL + WORD_SIZE
Msize           equ       9               ; size of a message in 32-bit words
K_STACK_BYTES	equ	1024

DIVIDE_VECTOR      equ	0   ; /* divide error */
DEBUG_VECTOR       equ	1   ; /* single step (trace) */
NMI_VECTOR         equ	2   ; /* non-maskable interrupt */
BREAKPOINT_VECTOR  equ	3   ; /* software breakpoint */
OVERFLOW_VECTOR    equ	4   ; /* from INTO */

BOUNDS_VECTOR       equ	 5  ;/* bounds check failed */
INVAL_OP_VECTOR     equ	 6  ;/* invalid opcode */
COPROC_NOT_VECTOR   equ	 7  ;/* coprocessor not available */
DOUBLE_FAULT_VECTOR equ	 8
COPROC_SEG_VECTOR   equ	 9  ;/* coprocessor segment overrun */
INVAL_TSS_VECTOR    equ	10  ;/* invalid TSS */
SEG_NOT_VECTOR      equ	11  ;/* segment not present */
STACK_FAULT_VECTOR  equ	12  ;/* stack exception_2 */
PROTECTION_VECTOR   equ	13  ;/* general protection */

PAGE_FAULT_VECTOR   equ 14
COPROC_ERR_VECTOR  equ  16  ;/* coprocessor error */

TSS3_S_SP0	equ	4



%macro hwint_master 1
        call    save                    
        push    dword [dword irq_handlers+4*%1]   
        call    intr_handle            
        pop     ecx                     
        cmp     dword [dword irq_actids+4*%1], 0  
        jz      %%skip
        in     al,INT_CTLMASK             
        or     al, (1<<%1)
        out    INT_CTLMASK,al             
%%skip:      mov    al, END_OF_INT          
        out    INT_CTL,al
        ret         
%endmacro

align	16
hwint00:
	hwint_master(0)

align	16
hwint01:		
	hwint_master(1)

align	16
hwint02:	
	hwint_master(2)

align	16
hwint03:
	hwint_master(3)

align	16
hwint04:
	hwint_master(4)

align	16
hwint05:
	hwint_master(5)

align	16
hwint06:
	hwint_master(6)

align	16
hwint07:
	hwint_master(7)

%macro hwint_slave 1
	call	save			
	push	dword [dword irq_handlers+4*%1]
	call	intr_handle		
	pop	ecx			
	cmp	dword [dword irq_actids+4*%1], 0	
	jz	%%skip			
	in	al,INT2_CTLMASK		
	or	al, (1<<(%1-8))
	out	INT2_CTLMASK,al
%%skip:	mov	al, END_OF_INT		
	out	INT_CTL,al
	out	INT2_CTL,al	
	ret				
%endmacro

align	16
hwint08:
	hwint_slave(8)

align	16
hwint09:
	hwint_slave(9)

align	16
hwint10:
	hwint_slave(10)

align	16
hwint11:
	hwint_slave(11)

align	16
hwint12:
	hwint_slave(12)

align	16
hwint13:
	hwint_slave(13)

align	16
hwint14:
	hwint_slave(14)

align	16
hwint15:
	hwint_slave(15)

align	16
save:
	cld			; set direction flag to a known value
	pushad			; save "general" registers
    o16	push	ds		; save ds
    o16	push	es		; save es
    o16	push	fs		; save fs
    o16	push	gs		; save gs
	mov	dx, ss		; ss is kernel data segment
	mov	ds, dx		; load rest of kernel segments
	mov	es, dx		; kernel does not use fs, gs
	mov	eax, esp	; prepare to return
	inc	byte [dword k_reenter]	; from -1 if not reentering
	jnz	set_restart1	; stack is already kernel stack
	mov	esp, k_stktop
	push	restart	; build return address for int handler
	xor	ebp, ebp	; for stacktrace
	jmp	[eax+RETADR-P_STACKBASE]

align	4
set_restart1:
	push	restart1
	jmp	[eax+RETADR-P_STACKBASE]

;*===========================================================================*
;*				_s_call					     *
;*===========================================================================*
align	16
s_call:
p_s_call:
	cld			; set direction flag to a known value
	sub	esp, 6*4	; skip RETADR, eax, ecx, edx, ebx, est
	push	ebp		; stack already points into proc table
	push	esi
	push	edi
    o16	push	ds
    o16	push	es
    o16	push	fs
    o16	push	gs
	mov	dx, ss
	mov	ds, dx
	mov	es, dx
	inc	byte [dword k_reenter]
	mov	esi, esp	; assumes P_STACKBASE == 0
	mov	esp, k_stktop
	xor	ebp, ebp	; for stacktrace
				; end of inline save
				; now set up parameters for sys_call()
	push	ebx		; pointer to user message
	push	eax		; src/dest
	push	ecx		; SEND/RECEIVE/BOTH
	call	sys_call	; sys_call(function, src_dest, m_ptr)
				; caller is now explicitly in proc_ptr
	mov	[esi+AXREG], eax; sys_call MUST PRESERVE si

; Fall into code to restart proc/task running.

;*===========================================================================*
;*				restart					     *
;*===========================================================================*
restart:

; Restart the current process or the next process if it is set. 

	cmp	dword [dword next_ptr], 0x0		; see if another process is scheduled
	jz	zero_forward1
	mov 	eax, [next_ptr]
	mov	[proc_ptr], eax	; schedule new process 
	mov	dword [dword next_ptr], 0x0
zero_forward1:
	mov	esp, [proc_ptr]	; will assume P_STACKBASE == 0
	lldt	[esp + P_LDT_SEL]		; enable process' segment descriptors 
	lea	eax, [esp+P_STACKTOP]	; arrange for next interrupt
	mov	[tss+TSS3_S_SP0], eax	; to save state in process table
restart1:
	dec	byte [dword k_reenter]
    o16	pop	gs
    o16	pop	fs
    o16	pop	es
    o16	pop	ds
	popad
	add	esp, 4		; skip return adr
	iretd			; continue process

;*===========================================================================*
;*				exception_2 handlers			     *
;*===========================================================================*
divide_error:
	push	DIVIDE_VECTOR
	jmp	exception_2

single_step_exception:
	push	DEBUG_VECTOR
	jmp	exception_2

nmi:
	push	NMI_VECTOR
	jmp	exception_2

breakpoint_exception:
	push	BREAKPOINT_VECTOR
	jmp	exception_2

overflow:
	push	OVERFLOW_VECTOR
	jmp	exception_2

bounds_check:
	push	BOUNDS_VECTOR
	jmp	exception_2

inval_opcode:
	push	INVAL_OP_VECTOR
	jmp	exception_2

copr_not_available:
	push	COPROC_NOT_VECTOR
	jmp	exception_2

double_fault:
	push	DOUBLE_FAULT_VECTOR
	jmp	errexception

copr_seg_overrun:
	push	COPROC_SEG_VECTOR
	jmp	exception_2

inval_tss:
	push	INVAL_TSS_VECTOR
	jmp	errexception

segment_not_present:
	push	SEG_NOT_VECTOR
	jmp	errexception

stack_exception:
	push	STACK_FAULT_VECTOR
	jmp	errexception

general_protection:
	push	PROTECTION_VECTOR
	jmp	errexception

page_fault:
	push	PAGE_FAULT_VECTOR
	jmp	errexception

copr_error:
	push	COPROC_ERR_VECTOR
	jmp	exception_2

;*===========================================================================*
;*				exception_2				     *
;*===========================================================================*
; This is called for all exceptions which do not push an error code.

align	16
exception_2:
	mov	dword [dword ss:trap_errno], 0x0		; clear trap_errno
	pop	dword [dword ss:ex_number]
	jmp	exception1

;*===========================================================================*
;*				errexception				     *
;*===========================================================================*
; This is called for all exceptions which push an error code.

align	16
errexception:
 	pop	dword [dword ss:ex_number]
 	pop	dword [dword ss:trap_errno]
exception1:				; Common for all exceptions.
	push	eax			; eax is scratch register
	mov	eax, [esp+0x4]		; old eip
	mov	[ss:old_eip], eax
	movzx	eax, word[esp + 0x8]		; old cs
	mov	[ss:old_cs], eax
	mov	eax, [esp+0xc]		; old eflags
	mov	[ss:old_eflags], eax
	pop	eax
	call	save
	push	dword [dword old_eflags]
	push	dword [dword old_cs]
	push	dword [dword old_eip]
	push	dword [dword trap_errno]
	push	dword [dword ex_number]
	call	exception		; (ex_number, trap_errno, old_eip,
					;	old_cs, old_eflags)
	add	esp, 5*4
	ret

;*===========================================================================*
;*				level0_call				     *
;*===========================================================================*
level0_call:
	call	save
	jmp	[level0_func]

	


set_the_new_descriptors:
	lgdt [gdt+0x08]	; 8 because the first entry of
			; gdt is 0 (8byte descriptor) - GDT_SELECTOR
	lidt [gdt+0x10]	; 0x10 - IDT_SELECTOR

	push   0x00
	push   0x30 ; CS_SELECTOR - as in protect.h
	push   flush_cs
	iret
	flush_cs:

    o16 mov     ax, 0x18 ;DS_SELECTOR
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax
    o16 mov     ax, 0x40 ; TSS_SELECTOR        ! no other TSS is used
        ltr     ax
        push    0                       ; set flags to known good state
        popf                            ; esp, clear nested task and int enable

        jmp     main                   ; main()



;*===========================================================================*
;*				data					     *
;*===========================================================================*


dw	0x526F		; this must be the first data entry (magic #)


k_stack:
	times 	K_STACK_BYTES db 0	; kernel stack
k_stktop:			; top of kernel stack
ex_number	dd	0
trap_errno	dd	0
old_eip		dd	0
old_cs		dd	0
old_eflags	dd	0
