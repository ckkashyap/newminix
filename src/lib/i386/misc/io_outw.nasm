;	outw() - Output one word			Author: Kees J. Bot
;								18 Mar 1996
;	void outw(U16_t port, U16_t value);

global outw
outw:
	push bp
	mov bp,sp
	mov dx,[di+0x8]
	mov ax,[di+0xc]
	out dx,eax
	pop bp
	ret
