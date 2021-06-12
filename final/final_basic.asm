;�޸����ڣ�2021-3-16
;���ߣ���ΰ��
;�汾��v1.1
;----------------------------------------------------------------------------
;Ӳ����ַ��
;8253:0280H-0283H
;8255:0290H-0293H
;----------------------------------------------------------------------------
NAME BASIC

DATA    SEGMENT
    MES DB 'PRESS ANY KEY EXIT TO DOS',0AH,0DH,'$';DOS�����ʾ��Ϣ
    TAB DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH,77H,7CH,39H,5EH,79H,71H;����ܶ���
    INT_SEG DW ?            ;ԭ�ж������λ�ַ
    INT_OFF DW ?            ;ԭ�ж�����ƫ��
    INTSOR DB ?             ;ԭ�ж�������
DATA    ENDS

STACK   SEGMENT
    STA DW 300 DUP(?)
    TOP EQU LENGTH STA
STACK   ENDS

CODE    SEGMENT
    ASSUME  CS:CODE,DS:DATA,SS:STACK,ES:DATA
START:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX
    MOV AX, STACK
    MOV SS, AX
    MOV SP, TOP
;��ʾ��ʾ��Ϣ
    MOV DX, OFFSET MES
    MOV AH, 09H
    INT 21H
;��ʼ��8255
    MOV DX, 0293H           ;���ƶ�
    MOV AL, 90H             ;��ʽѡ�������-��ʽ0-A��B��C�� 10000000
    OUT DX, AL              ;д�������
;��ʼ��8253
    ;CLK0���ã�OUT0Ϊ1kHz����
    MOV DX, 0283H           ;���ƶ�
    MOV AL, 36H             ;CLK0-�ߵ��ֽ�-��ʽ3-������ 00110110
    OUT DX, AL
    MOV DX, 0280H           ;CLK0
    MOV AX, 03E8H           ;1000=03E8H, 1MHz to 1kHz
    OUT DX, AL
    MOV AL, AH
    OUT DX, AL
    ;CLK1���ã�OUT1Ϊ2Hz����
    MOV DX, 0283H           ;���ƶ�
    MOV AL, 76H             ;CLK1-�ߵ��ֽ�-��ʽ3-������ 01110110
    OUT DX, AL
    MOV DX, 0281H           ;CLK1
    MOV AX, 01F4H           ;500=01F4H, 1kHz to 2Hz
    OUT DX, AL
    MOV AL, AH
    OUT DX, AL
;�洢�ж�����
    CLI                     ;���ж�
    MOV AH, 35H             ;DOS����-��ȡ�ж�����,ES:BX�ж�����
    MOV AL, 0BH             ;�����ж�������(IRQ3)
    INT 21H
    MOV AX, ES
    MOV WORD PTR INT_SEG, AX         ;��λ�ַ
    MOV WORD PTR INT_OFF, BX         ;��ƫ��
;�������ж�����
    PUSH DS                 ;�ݴ�DS
    MOV AX, SEG INT_PR
    MOV DS, AX              ;�жϳ���CS
    MOV DX, OFFSET INT_PR   ;�жϳ���IP
    MOV AH, 25H             ;DOS����-�����ж�����,DS:DX=�жϳ������
    MOV AL, 0BH             ;�����ж�������(IRQ3)
    INT 21H
    POP DS                  ;�ָ�DS
    IN  AL, 21H
    MOV INTSOR, AL          ;����ԭ�ж�������
    AND AL, 0F7H            ;����IRQ3
    OUT 21H, AL
    STI                     ;���ж�
    MOV CH,03H
;ѭ������Ƿ��м�����
LOOP0:
    STI
    JMP LOOP0               ;ѭ��
;�˳�ǰ���ָ�ԭ�ж�����
FINISH1:
    CLI                     ;���ж�
    MOV AX, INT_SEG
    MOV DS, AX
    MOV DX, INT_OFF
    MOV AH, 25H
    MOV AL, 0BH
    INT 21H                 ;;DOS����-�����ж�����
    MOV AL, INTSOR
    OUT 21H, AL             ;�ָ��ж�������
;����DOS
    MOV AH, 4CH
    INT 21H
;----------------------------------------------------------------------------
;�ж��ӳ���INT_PR�� ÿ0.5s����һ�Σ����������ʾA�˿ڰ���ֵ��/����λ
;��ڲ�����         CH       ���ѭ������ֵ��Ϊ1ʱ��ʾ����λ��Ϊ2/3ʱ��ʾ����λ
;                  TAB      ָ��0-F��Ӧ�����������
;���ڲ�����         CH       ��������
;���üĴ�����       AX,BX,CX,DX
;----------------------------------------------------------------------------
    INT_PR PROC FAR
        CLI                 ;���ж�
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH DX
        PUSHF
        MOV AX, 0FE6H
        MOV DS, AX
        MOV AH, 0BH
        INT 21H                 ;��ɨ�裺�޼���ZF=1���м���ZF=0
        CMP AL,0FFH
        JZ FINISH1
        MOV BX, OFFSET TAB  ;�������ݵ�ַ
        MOV DX, 0290H       ;A��
        IN  AL, DX
        CMP CH, 01H         ;��������1�Ƚ�
        JZ  DISPLAY_LOW     ;����1��ʾ����λ������(2/3)��ʾ����λ
        AND AL, 0F0H        ;��������λ
        MOV CL, 4
        SHR AL, CL          ;������λ
        JMP OUTPUT
DISPLAY_LOW:
        AND AL, 0FH
OUTPUT:
        XLAT                ;(BX:AL) to AL��AL�������������
        MOV DX, 0291H       ;B��
        OUT DX, AL          ;B�����
        DEC CH
        JNZ FINISH
        MOV CH, 03H         ;���¿�ʼһ��
FINISH:
        POPF                ;�ָ��ֳ�
        POP DX
        POP BX
        POP AX
        MOV AL, 20H         ;�������ж�����
        OUT 20H, AL
        STI                 ;���ж�
        IRET                ;���򷵻�
    INT_PR ENDP
CODE    ENDS
END     START