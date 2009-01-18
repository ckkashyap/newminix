#include <sys/types.h>

void outb( u16_t nPort, u8_t nValue ) {
        asm volatile( "outb %%al, %%dx" : : "a" ( nValue ), "d" ( nPort ) );
}

void outw( u16_t nPort, u16_t nValue ) {
        asm volatile( "outw %%ax, %%dx" : : "a" ( nValue ), "d" ( nPort ) );
}

void outl( u16_t nPort, u32_t nValue ) {
        asm volatile( "outl %%eax, %%dx" : : "a" ( nValue ), "d" ( nPort ) );
}

u8_t inb( u16_t nPort ) {
        u8_t nRet;

        asm volatile( "inb %%dx, %%al" : "=a" ( nRet ) : "d" ( nPort ) );

        return nRet;
}

u16_t inw( u16_t nPort ) {
        u16_t nRet;

        asm volatile( "inw %%dx, %%ax" : "=a" ( nRet ) : "d" ( nPort ) );

        return nRet;
}

u32_t inl( u16_t nPort ) {
        u32_t nRet;

        asm volatile( "inl %%dx, %%eax" : "=a" ( nRet ) : "d" ( nPort ) );

        return nRet;
}

void Insw( u16_t nPort, void *pAddr, u32_t nCount ) {
        asm volatile( "rep; insw": "=D" (pAddr), "=c"(nCount):"d"(nPort),"0"(pAddr),"1"(nCount));
}

