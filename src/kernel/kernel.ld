OUTPUT_FORMAT("elf32-i386", "elf32-i386","elf32-i386")
OUTPUT_ARCH(i386)

phys	= 0x100000;

ENTRY(_start)
SECTIONS
{
	. = phys;
	.text phys : AT(phys) { 
		h1 = .;
		*(.text)
	}

	. = ALIGN(4096);

	.data : AT(phys + ( h2 - h1 ) ) {
		h2 = .;
		*(data*)
	}

	.bss : AT(phys + (  h3 - h1 ) ) {
		h3 = .;
		*(bss*)
	}

	.ksymtab :  AT(phys + ( h4 - h1 ) ) {
		h4 = .;
		*(ksymtab*)
	}
	
	.rodata : AT(phys + ( h7 - h1 ) ) {
		h7 = .;
		*(rodata);
	}

	. = ALIGN(4096);
	_end = .;
	end =.;

	/DISCARD/ : { *(.comment .note .eh_frame .dtors) }
}
