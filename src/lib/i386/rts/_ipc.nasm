; See src/kernel/ipc.h for C definitions
SEND EQU 1
RECEIVE EQU 2
SENDREC EQU 3 
NOTIFY EQU 4
ECHO EQU 8
SYSVEC EQU 33			; trap to kernel 

SRC_DST EQU 8			; source/ destination process 
ECHO_MESS EQU 8			; echo doesn't have SRC_DST 
MESSAGE EQU 12			; message pointer 

;*========================================================================*
;                           IPC assembly routines			  *
;*========================================================================*
; all message passing routines save ebp, but destroy eax and ecx.
global _echo, _notify, _send, _receive, _sendrec 

_send:
                            push ebp
                            mov ebp,esp
                            push ebx
                            mov eax,[ebp+SRC_DST]
                            mov ebx,[ebp+MESSAGE]
                            mov ecx,SEND
                            int SYSVEC
                            pop ebx
                            pop ebp
                            ret
_receive:
                            push ebp
                            mov ebp,esp
                            push ebx
                            mov eax,[ebp+SRC_DST]
                            mov ebx,[ebp+MESSAGE]
                            mov ecx,RECEIVE
                            int SYSVEC
                            pop ebx
                            pop ebp
                            ret
_sendrec:
                            push ebp
                            mov ebp,esp
                            push ebx
                            mov eax,[ebp+SRC_DST]
                            mov ebx,[ebp+MESSAGE]
                            mov ecx,SENDREC
                            int SYSVEC
                            pop ebx
                            pop ebp
                            ret

_notify:
                            push ebp
                            mov ebp,esp
                            push ebx
                            mov eax,[ebp+SRC_DST]
                            mov ecx,NOTIFY
                            int SYSVEC
                            pop ebx
                            pop ebp
                            ret

_echo:
                            push ebp
                            mov ebp,esp
                            push ebx
                            mov ebx,[ebp+ECHO_MESS]
                            mov ecx,ECHO
                            int SYSVEC
                            pop ebx
                            pop ebp
                            ret
