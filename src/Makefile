include Rules.inc
# This makefile is the master makefile

all:
	make SOURCE_ROOT=$$PWD -C kernel $$TARGET
	make SOURCE_ROOT=$$PWD -C ../staging $$TARGET


clean:
	make SOURCE_ROOT=$$PWD TARGET=clean 
