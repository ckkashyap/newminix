include $(SOURCE_ROOT)/Rules.inc

OBJECTS=\
	boot.o \
	start.o \
	table.o \
	protect.o \
	mpx386.o \
	klib386.o \
	i8259.o \
	proc.o \
	exception.o \
	utility.o \
	clock.o \
	system.o \
	main.o \
	early_print.o
		





all: $(OBJECTS)
	make -C system
	make -C ../lib/ansi
	make -C ../lib/i386/rts
	make -C ../lib/i386/string
	make -C ../lib/i386/misc
	make -C ../lib/other
	make -C ../lib/posix
	make -C ../lib/timers
	ld -Tkernel.ld $? system/*.o ../lib/ansi/*.o ../lib/i386/rts/*.o ../lib/i386/string/*.o ../lib/other/*.o ../lib/posix/*.o ../lib/timers/*.o ../lib/i386/misc/*.o -o ../../staging/iso/kernel 


#ld $? system/*.o ../lib/ansi/*.o ../lib/i386/rts/*.o ../lib/i386/string/*.o ../lib/other/*.o ../lib/posix/*.o ../lib/timers/*.o ../lib/i386/misc/*.o last.o -e start -Ttext=0x100000 -o ../../staging/iso/kernel 

