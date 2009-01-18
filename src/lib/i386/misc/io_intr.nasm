;	intr_disable(), intr_enable - Disable/Enable hardware interrupts.
;							Author: Kees J. Bot
;								18 Mar 1996
;	void intr_disable(void);
;	void intr_enable(void);

global intr_disable
global intr_enable
intr_disable:
	cli
	ret

intr_enable:
	sti
	ret
