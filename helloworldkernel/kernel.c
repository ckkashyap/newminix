
#include <multiboot.h>

void
cmain (unsigned long magic, unsigned long addr)
{
	char *ptr=(char*)0xb8000;
	char *string="HELLO WORLD";
	int i;

	for(i=0;i<11;i++){ // sorry, no strlen at this point
		ptr[i*2]=string[i];
		ptr[i*2+1]=0x4f; // 0x4f is red on white!
	}
}    

