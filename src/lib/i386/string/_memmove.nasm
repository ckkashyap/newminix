;	_memmove()					Author: Kees J. Bot
;								2 Jan 1994
;sect .text; .sect .rom; .sect .data; .sect .bss
; void *_memmove(void *s1, const void *s2, size_t n)
;	Copy a chunk of memory.  Handle overlap.
;
global _memmove, _memcpy
	align	16
_memmove:
	push	ebp
	mov	ebp,esp
	push	esi
	push	edi
	mov	edi,[ebp+0x8]
	mov	esi,[ebp+0xc]
	mov	ecx,[ebp+0x10]
	mov	eax,edi
	sub	eax,esi
	cmp	eax,ecx
	jc	downwards	; if (s2 - s1) < n then copy downwards
_memcpy:
	cld			; Clear direction bit: upwards
	cmp	ecx,byte +0x10
	jc 	upbyte		; Don't bother being smart with short arrays
	mov	eax, esi
	or	eax, edi
	test	al, 0x1
	jnz	upbyte		; Bit 0 set, use byte copy
	test	al, 0x2
	jnz	upword		; Bit 1 set, use word copy
uplword:shrd	eax,ecx,0x2	; Save low 2 bits of ecx in eax
	shr	ecx,0x2
	rep	movsd
	shld	ecx, eax, 2	; Restore excess count
upword:	shr	ecx, 1
	rep	movsw
	adc	ecx, ecx	; One more byte?
upbyte:	rep	movsb
done:	mov	eax,[ebp+0x8]	; Absolutely noone cares about this value
	pop	edi
	pop	esi
	pop	ebp
	ret

; Handle bad overlap by copying downwards, don't bother to do word copies.
downwards:
	std
	lea	esi,[esi+ecx-0x1]
	lea	edi,[edi+ecx-0x1]
	rep	movsb
	cld
	jmp	done



