;8255:0290H-0293H
;���ݶζ���
DATA    SEGMENT
    MES1 DB 'PRESS 0-F ON PS2 KEYBOARD',0AH,0DH,'$';DOS�����ʾ��Ϣ
    MES2 DB 'PRESS ANY KEY ON PC KEYBOARD TO EXIT TO DOS',0AH,0DH,'$'
    TAB DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH,77H,7CH,39H,5EH,79H,71H;����ܶ���
    PS2 DB 45H,16H,1EH,26H,25H,2EH,36H,3DH,3EH,46H,1CH,32H,21H,23H,24H,2BH;PS2����0-F��Ӧͨ��(����2�ֽڣ�+F0H)
    ;       0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    PRESS_NUM DB 00H        ;��������
    INPUT_BIT DB 00H        ;һ�δ����У���ǰ�����λ��
    INPUT_KEY_PS2 DB 00H    ;����ı���
    INPUT_KEY DB 00H        ;����ֵ(00H-0FH)
    HEX_NUM DB ?            ;�ӳ���NUM_DIVIDE��ڲ���
    TENS DB ?               ;ת����ʮλ
    ONES DB ?               ;ת�����λ
    DISPLAY_NUM DB ?        ;�����Ҫ��ʾ����
    C_CONTROL DB ?          ;8255C�ڿ�����
    SHOULD_LOAD DB 01H      ;״̬λ��CLKΪ��ʱ��1��ʾ�������ݣ�0����������
DATA    ENDS
;��ջ�ζ���
STACKS   SEGMENT
    STA DW 100 DUP(?)
    TOP EQU LENGTH STA
STACKS   ENDS
;����γ�ʼ��
CODE    SEGMENT
    ASSUME  CS:CODE,DS:DATA,SS:STACKS,ES:DATA
START:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX
    MOV AX, STACKS
    MOV SS, AX
    MOV SP, TOP
;��ʾ��ʾ��Ϣ
    MOV DX, OFFSET MES1
    MOV AH, 09H
    INT 21H
    MOV DX, OFFSET MES2
    MOV AH, 09H
    INT 21H
;��ʼ��8255
    MOV DX, 0293H           ;���ƶ�
    MOV AL, 90H             ;��ʽѡ�������-��ʽ0-A��B��C�� 10000000
    OUT DX, AL              ;д�������
;��ѭ��
LOOP0:
    CALL LOAD
;��ʾ����ֵ
    MOV AL, INPUT_KEY
    MOV HEX_NUM, AL
    CALL NUM_DIVIDE         ;�Ѱ���ֵ�ֽ�

    MOV AL, ONES
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 01H      ;0000 000 1 PC0��1
    CALL LED_DISPLAY

    MOV AL, TENS
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 03H      ;0000 001 1 PC1��1
    CALL LED_DISPLAY
;��ʾ��������
    MOV AL, PRESS_NUM
    MOV HEX_NUM, AL
    CALL NUM_DIVIDE         ;�Ѱ��������ֽ�

    MOV AL, ONES
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 05H      ;0000 010 1 PC2��1
    CALL LED_DISPLAY

    MOV AL, TENS
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 07H      ;0000 011 1 PC3��1
    CALL LED_DISPLAY
;�ж��Ƿ��˳�����
    MOV AH, 0BH
    INT 21H                 ;��ɨ�裺�޼���AL=00H���м���AL=FFH
    CMP AL, 0FFH
    JNZ LOOP0               ;�м������˳�ѭ��
    MOV AH, 4CH
    INT 21H
;----------------------------------------------------------------------------
;�ӳ���LOAD��       ����ͨ��
;��ڲ�����         INPUT_BIT       ��ǰ����λ��
;                   INPUT_KEY_PS2   �ϴδ���ı���
;���ڲ�����         INPUT_BIT       �´δ���λ��
;                   INPUT_KEY_PS2   ���δ�����ɵı���
;���üĴ�����       AH,AL,CL,DX
;----------------------------------------------------------------------------
    LOAD PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
AGAIN2:        
        MOV DX, 0290H
        IN  AL, DX              ;PA0��DATA��PA4��CLK
        MOV BL, AL              ;����AL
        AND AL, 01H             ;AL=01H,DATA=1;AL=00H,DATA=0
        AND BL, 10H             ;BL=10H,CLK=1;BL=00H,CLK=0
        TEST BL, 10H
        JNZ  CLK_HIGH
        JMP CLK_LOW
CLK_HIGH:
        MOV SHOULD_LOAD, 01H    ;�ߵ�ƽʱ���ȴ���һ�ε͵�ƽ
        MOV CL, INPUT_BIT
        TEST CL, 0FFH
        JZ  IGNORE
        JMP AGAIN2
CLK_LOW:
        MOV BH, SHOULD_LOAD
        TEST BH, 0FFH           ;��ȻΪ�͵�ƽ�����Ѿ�������λ
        JZ AGAIN2
        MOV SHOULD_LOAD, 00H
        MOV AH, INPUT_KEY_PS2
        MOV CL, INPUT_BIT
        TEST CL, 0FFH
        JZ  BEGIN_LOAD          ;CL=0��ձ���Ϊ������׼��
        CMP CL, 08H
        JA  FINISH              ;CL>8�Ѵ��꣬���ԶԱ������
        SHR AH, 1               ;CL=1~8ʱ������1λ
        TEST AL, 0FFH
        JZ  FINISH
        OR  AH, 80H             ;��λDATA=1��AH���λ��1
        JMP FINISH
BEGIN_LOAD:
        MOV INPUT_KEY_PS2, 00H
        INC CL
        MOV INPUT_BIT, CL
        JMP AGAIN2
FINISH:
        INC CL
        MOV INPUT_KEY_PS2, AH
        CMP CL, 0BH             ;��CL=11ʱ�������Ѵ��꣬�����׼����һ�ν���
        JNZ NO_CALL
        MOV CL, 00H
        MOV INPUT_BIT, CL
        CALL TRANSFORM_PS2      ;���ú�������PS2����תΪ0-F
        JMP IGNORE
NO_CALL:
        MOV INPUT_BIT, CL
        JMP AGAIN2   
IGNORE:
        POPF                ;�ָ��ֳ�
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    LOAD ENDP
;----------------------------------------------------------------------------
;�ӳ���TRANSFORM_PS2��  ��PS2����תΪ0-F����Ϊ���룬�򰴼�������1
;��ڲ�����             INPUT_KEY_PS2   ����PS2����
;���ڲ�����             INPUT_KEY       ת���󰴼�ֵ
;                       PRESS_NUM       ��������
;���üĴ�����           AX,BX,SI
;----------------------------------------------------------------------------
    TRANSFORM_PS2 PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSHF
        MOV AL, INPUT_KEY_PS2
        CMP AL, 0F0H
        JZ  PRESS_OFF       ;��Ϊ��������ת
        MOV BX, OFFSET PS2  ;ѭ��
        MOV SI, 0000H
AGAIN:  
        MOV AH, BX[SI]
        INC SI
        CMP AH, AL
        JNZ AGAIN
        DEC SI
        MOV AX, SI
        MOV INPUT_KEY, AL   ;INPUT_KEY����ת����0-F
        JMP FINISH1
PRESS_OFF:
        MOV BL, PRESS_NUM
        INC BL
        MOV PRESS_NUM, BL
FINISH1:
        POPF                ;�ָ��ֳ�
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    TRANSFORM_PS2 ENDP
;----------------------------------------------------------------------------
;�ӳ���NUM_DIVIDE��     ��0-99��Χ�ڵ�1�ֽ���ת��Ϊʮλ�͸�λ
;��ڲ�����             HEX_NUM             Ҫת����1�ֽ���
;���ڲ�����             TENS                ת����ʮλ
;                       ONES                ת�����λ
;���üĴ�����           AX,CL
;----------------------------------------------------------------------------
    NUM_DIVIDE PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH CX
        PUSHF
        MOV AL, HEX_NUM     ;��ת��������
        MOV AH, 00H
        MOV CL, 10
        DIV CL              ;AX/CL������AL��������AH
        MOV TENS, AL        ;���ؽ��
        MOV ONES, AH
        POPF                ;�ָ��ֳ�
        POP CX
        POP AX
        RET
    NUM_DIVIDE ENDP
;----------------------------------------------------------------------------
;�ӳ���LED_DISPLAY��    �������ʾ
;��ڲ�����             DISPLAY_NUM         Ҫ��ʾ������
;                       TAB                 ����ܶ���
;                       C_CONTROL           PC������
;���ڲ�����
;���üĴ�����           AL,BX,CX,DX
;----------------------------------------------------------------------------
    LED_DISPLAY PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH DX
        PUSHF
        MOV BX, OFFSET TAB  ;�������ݵ�ַ
        MOV AL, DISPLAY_NUM
        XLAT                ;(BX:AL) to AL��AL�������������
        MOV DX, 0291H       ;PB
        OUT DX, AL          ;д������
        MOV DX, 0293H       ;������
        MOV AL, C_CONTROL
        OUT DX, AL          ;������Ӧ�����
        MOV CX,500
LOOP1:
        CALL LOAD        ;��ʱ
        LOOP LOOP1
        AND AL, 0FEH        ;�����Ӧ�����λ����0��PC������
        OUT DX, AL          ;Ϩ���Ӧ�����
        POPF                ;�ָ��ֳ�
        POP DX
        POP BX
        POP AX
        RET
    LED_DISPLAY ENDP
CODE    ENDS
END     START