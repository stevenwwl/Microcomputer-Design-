;8253:0280H-0283H  8255:0290H-0293H
;16*16���������JX1��չ�ӿڣ��и�8λ-02B1H���е�8λ-02B0H���и�8λ-02B3H���е�8λ-02B2H
;LCD12864:RS-PC0  RW-PC1  E-PC2
;���ݶζ���
DATA    SEGMENT
    MES DB 'PRESS ANY KEY EXIT TO DOS',0AH,0DH,'$';DOS�����ʾ��Ϣ
    INT_SEG DW ?            ;IRQ3ԭ�ж������λ�ַ
    INT_OFF DW ?            ;IRQ3ԭ�ж�����ƫ��
    INT_SEG1 DW ?           ;IRQ4ԭ�ж������λ�ַ
    INT_OFF1 DW ?           ;IRQ4ԭ�ж�����ƫ��
    INTSOR DB ?             ;ԭ�ж�������
    TIME_TO_LOAD DW 0FFFFH  ;ÿ�ο�ʼʱ������װ��ĳ�ֵ
    TIME DW 0000H           ;������ʱ��
    IS_TIMING DB 00H        ;�������ֱ����ж�ʱ��ʼ��ʱ������ͣ��ʱ
    TIME_STRING DB ' 00.00s ';��ʾ�����ַ���,8���ַ�
    LCD_CMD DB ?            ;д���LCD�������
    LCD_DATA DB ?           ;д���LCD�ַ�ACSii��
    LINE_1 DB ' Digital  Timer ';��һ����ʾ,16���ַ�
    SWITCH_NUM_HIGH DB ?    ;����״̬��λ
    SWITCH_NUM_LOW DB ?     ;����״̬��λ
    COLUMN_ADDRESS DW ?     ;�����е�ַ
    ROW_ADDRESS1 DW ?        ;�����е�ַ
    ROW_ADDRESS2 DW ?
    ROW_CODE_OFFSET DW ?    ;�������ƫ�Ƶ�ַ
    LED_TABLE   DW 0000H,07F0H,0808H,1004H,1004H,0808H,07F0H,0000H
                DW 0000H,0804H,0804H,1FFCH,0004H,0004H,0000H,0000H
                DW 0000H,0E0CH,1014H,1024H,1044H,1184H,0E0CH,0000H       
                DW 0000H,0C18H,1004H,1104H,1104H,1288H,0C70H,0000H
                DW 0000H,00E0H,0320H,0424H,0824H,1FFCH,0024H,0000H
                DW 0000H,00E0H,0320H,0424H,0824H,1FFCH,0024H,0000H    
                DW 0000H,07F0H,0888H,1104H,1104H,1888H,0070H,0000H
                DW 0000H,1C00H,1000H,10FCH,1300H,1C00H,1000H,0000H                       
                DW 0000H,0E38H,1144H,1084H,1084H,1144H,0E38H,0000H                        
                DW 0000H,0700H,088CH,1044H,1044H,0888H,07F0H,0000H
                DW 0004H,003CH,03C4H,1C40H,0740H,00E4H,001CH,0004H                          
                DW 1004H,1FFCH,1104H,1104H,1104H,0E88H,0070H,0000H
                DW 03E0H,0C18H,1004H,1004H,1004H,1008H,1C10H,0000H
                DW 1004H,1FFCH,1004H,1004H,1004H,0808H,07F0H,0000H
                DW 1004H,1FFCH,1104H,1104H,17C4H,1004H,0818H,0000H
                DW 1004H,1FFCH,1104H,1100H,17C0H,1000H,0800H,0000H             
    COLUMN DB 01H,02H,04H,08H,10H,20H,40H,80H
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
    MOV DX, OFFSET MES
    MOV AH, 09H
    INT 21H
;��ʼ��8253
    ;CNT0���ã�OUT0Ϊ100Hz����
    MOV DX, 0293H           ;���ƶ�
    MOV AL, 36H             ;CNT0-�ߵ��ֽ�-��ʽ3-������ 00110110
    OUT DX, AL
    MOV DX, 0290H           ;CNT0
    MOV AX, 2710H           ;10000=2710H, 1MHz to 100Hz
    OUT DX, AL
    MOV AL, AH
    OUT DX, AL
;��ʼ��LCD12864
    CALL DELAY_LONG
    CALL LCD_INIT
;�洢�ж�����
    CLI                     ;���ж�
    MOV AH, 35H             ;DOS����-��ȡ�ж�����,ES:BX�ж�����
    MOV AL, 0BH             ;�����ж�������(IRQ3)
    INT 21H
    MOV AX, ES
    MOV INT_SEG, AX         ;��λ�ַ
    MOV INT_OFF, BX         ;��ƫ��
    MOV AH, 35H             ;DOS����-��ȡ�ж�����,ES:BX�ж�����
    MOV AL, 0CH             ;�����ж�������(IRQ4)
    INT 21H
    MOV AX, ES
    MOV INT_SEG1, AX        ;��λ�ַ
    MOV INT_OFF1, BX        ;��ƫ��
;�������ж�����
    PUSH DS                 ;�ݴ�DS
    MOV AX, SEG INT_TIMER
    MOV DS, AX              ;�жϳ���CS
    MOV DX, OFFSET INT_TIMER;�жϳ���IP
    MOV AH, 25H             ;DOS����-�����ж�����,DS:DX=�жϳ������
    MOV AL, 0BH             ;�����ж�������(IRQ3)
    INT 21H
    MOV AX, SEG INT_CLEAR
    MOV DS, AX              ;�жϳ���CS
    MOV DX, OFFSET INT_CLEAR;�жϳ���IP
    MOV AH, 25H             ;DOS����-�����ж�����,DS:DX=�жϳ������
    MOV AL, 0CH             ;�����ж�������(IRQ4)
    INT 21H
    POP DS                  ;�ָ�DS
    IN  AL, 21H
    MOV INTSOR, AL          ;����ԭ�ж�������
    AND AL, 0E7H            ;����IRQ3��IRQ34
    OUT 21H, AL
    STI                     ;���ж�
;ѭ������Ƿ��м�����
LOOP0:
    CALL GET_TIME
    CALL TIME_DIVIDE
    CALL LCD_DISPLAY_TIME
    CALL GET_SWITCH_NUM
    CALL ARRAY_DISPLAY
    JMP LOOP0
;----------------------------------------------------------------------------
;�ж��ӳ���INT_TIMER��      ��IS_TIMINGΪ0��ת����ʼ��ʱ��IS_TIMINGΪ1��ͣ��ʱ
;��ڲ�����                 IS_TIMING       ���α�ʶλ
;                           TIME_TO_LOAD    ���γ�ֵ
;���ڲ�����                 IS_TIMING       �´α�ʶλ
;                           TIME_TO_LOAD    �´γ�ֵ
;���üĴ�����               AX,BX,DX
;----------------------------------------------------------------------------
    INT_TIMER PROC FAR
        CLI                 ;���ж�
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV AL, IS_TIMING
        CMP AL, 00H
        JZ START_TIMING     ;IS_TIMINGΪ0��ת����ʼ��ʱ
        CMP AL, 01H
        JZ STOP_TIMING      ;IS_TIMINGΪ1��ת����ͣ��ʱ        
START_TIMING:
        MOV DX, 0293H       ;���ƶ�
        MOV AL, 70H         ;CNT1-�ߵ��ֽ�-��ʽ0-������ 01110000
        OUT DX, AL
        MOV DX, 0291H       ;CNT1
        MOV AX, WORD PTR TIME_TO_LOAD;д���ֵ
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        MOV IS_TIMING, 01H  ;IS_TIMING��1���´���ͣ��ʱ
        JMP FINISH
STOP_TIMING:
        MOV DX, 0293H       ;���ƶ�
        MOV AL, 40H         ;CNT1����
        MOV DX, 0291H       ;CNT1
        IN  AL, DX
        MOV BL, AL          ;��8λ
        IN  AL, DX
        MOV BH, AL          ;��8λ
        MOV TIME_TO_LOAD, BX;������ͣʱ�ļ�����ֵ���´ο�ʼʱ��װ��
        MOV IS_TIMING, 00H  ;IS_TIMING��0���´ο�ʼ��ʱ
FINISH:
        MOV AL, 20H         ;�������ж�����
        OUT 20H, AL
        POPF                ;�ָ��ֳ�
        POP DX
        POP CX
        POP BX
        POP AX
        STI                 ;���ж�
        IRET                ;���򷵻�
    INT_TIMER ENDP
;----------------------------------------------------------------------------
;�ж��ӳ���INT_CLEAR��      ��ʱ��ͣʱ�������������
;��ڲ�����                 IS_TIMING       ��ʶλ
;���ڲ�����                 TIME_TO_LOAD    �´μ�����ֵ
;���üĴ�����               AL
;----------------------------------------------------------------------------
    INT_CLEAR PROC FAR
        CLI                 ;���ж�
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV AL, IS_TIMING
        CMP AL, 01H         ;�����ڼ�ʱ������ʹ�����㹦��
        JZ FINISH1
        MOV TIME_TO_LOAD, 0FFFFH;���ó�ֵ
FINISH1:
        MOV AL, 20H         ;�������ж�����
        OUT 20H, AL
        POPF                ;�ָ��ֳ�
        POP DX
        POP CX
        POP BX
        POP AX
        STI                 ;���ж�
        IRET                ;���򷵻�
    INT_CLEAR ENDP
;----------------------------------------------------------------------------
;�ӳ���LCD_DISPLAY_TIME��   LCD�ڶ�����ʾ�������
;��ڲ�����                 TIME_STRING     8�ֽڵ���ʾ�ַ���
;���ڲ�����
;���üĴ�����               AL,BX,CX,SI
;----------------------------------------------------------------------------
    LCD_DISPLAY_TIME PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSHF
        MOV LCD_CMD, 92H
        CALL WRITE_CMD      ;����Ƶ��ڶ���ƫ��
        MOV BX, OFFSET TIME_STRING
        MOV SI, 0
        MOV CX, 8
AGAIN1:
        MOV AL, BX[SI]
        MOV LCD_DATA, AL
        CALL WRITE_DATA     ;д��' xx.xxs '
        INC SI
        DEC CX
        JNZ AGAIN1
        POPF                ;�ָ��ֳ�
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    LCD_DISPLAY_TIME ENDP
;----------------------------------------------------------------------------
;�ӳ���GET_TIME��           ��ȡӦ����ʾ��ʱ��
;��ڲ�����                 IS_TIMING       ��ʶλ
;                          TIME_TO_LOAD    ������ֵ
;���ڲ�����                 TIME            ���ص�Ӧ����ʾ��ʱ��
;���üĴ�����               AX,BX,DX
;----------------------------------------------------------------------------
    GET_TIME PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV BL, IS_TIMING
        CMP BL, 00H
        JZ NOT_READ
        CMP BL, 01H
        JZ READ
NOT_READ:
        MOV AX, 0FFFFH
        MOV BX, WORD PTR TIME_TO_LOAD
        SUB AX, BX
        JMP FINISH2
READ:
        MOV DX, 0293H       ;���ƶ�
        MOV AL, 40H         ;CNT1����
        MOV DX, 0291H       ;CNT1
        IN  AL, DX
        MOV BL, AL          ;��8λ
        IN  AL, DX
        MOV BH, AL          ;��8λ
        MOV AX, 0FFFFH
        SUB AX,BX
FINISH2:
        CMP AX, 10000
        JB SKIP             ;С��10000(Ϊ4λ��)ʱ��ת
        MOV AX, 9999
SKIP:
        MOV TIME, AX        ;���س��ڲ���
        POPF                ;�ָ��ֳ�
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    GET_TIME ENDP
;----------------------------------------------------------------------------
;�ӳ���TIME_DIVIDE��        �ָ�16������Ϊʮλ����λ��ʮ��λ���ٷ�λ
;��ڲ�����                 TIME            Ҫ�ָ��ʱ��
;���ڲ�����                 THOUSANDS,HUNDREDS,TENS,ONES�ָ�õ�λ����ASCii��
;���üĴ�����               AX,CX,DX
;----------------------------------------------------------------------------
    TIME_DIVIDE PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV BX, OFFSET TIME_STRING
        MOV AX, WORD PTR TIME
        MOV DX, 0
        MOV CX, 1000
        DIV CX              ;����AX��������DX
        ADD AL, 30H
        MOV [BX+01H], AL    ;��ʮλ
        MOV AX, DX
        MOV CL, 100
        DIV CL              ;����AL,������AH
        ADD AL, 30H
        MOV [BX+02H], AL    ;���λ
        MOV AL, AH
        MOV AH, 0
        MOV CL, 10
        DIV CL              ;����AL,������AH
        ADD AL, 30H
        MOV [BX+04H], AL    ;��ʮ��λ
        ADD AH, 30H
        MOV [BX+05H], AH    ;��ٷ�λ
        POPF                ;�ָ��ֳ�
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    TIME_DIVIDE ENDP
;----------------------------------------------------------------------------
;�ӳ���LCD_INIT��           LCD��ʼ������
;��ڲ�����                 LINE_1          ��һ����ʾ���ַ���
;���ڲ�����
;���üĴ�����               AL,BX,CX,SI
;----------------------------------------------------------------------------
    LCD_INIT PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSHF
        MOV LCD_CMD, 30H
        CALL WRITE_CMD
        MOV LCD_CMD, 30H
        CALL WRITE_CMD      ;�����趨��8λ�ӿڣ�����ָ�
        MOV LCD_CMD, 0CH
        CALL WRITE_CMD      ;��ʾ�������ã�������ʾ�����α���ʾ�أ�������ʾ��
        MOV LCD_CMD, 01H
        CALL WRITE_CMD      ;�����ʾ
        MOV LCD_CMD, 06H
        CALL WRITE_CMD      ;�����趨�㣺�α�����,���治�ƶ�
        MOV LCD_CMD, 80H
        CALL WRITE_CMD      ;����Ƶ���һ�п�ͷ
        MOV BX, OFFSET LINE_1
        MOV SI, 0
        MOV CX, 16
AGAIN:
        MOV AL, BX[SI]
        MOV LCD_DATA, AL
        CALL WRITE_DATA     ;д��' Digital  Timer '
        INC SI
        DEC CX
        JNZ AGAIN
        POPF                ;�ָ��ֳ�
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    LCD_INIT ENDP
;----------------------------------------------------------------------------
;�ӳ���WRITE_CMD��          д���������(RS=0,RW=0)
;��ڲ�����                 LCD_CMD         Ҫд����������
;���ڲ�����
;���üĴ�����               AL,DX
;----------------------------------------------------------------------------
    WRITE_CMD PROC NEAR
        PUSH AX
        PUSH DX
        MOV  DX,0283H
        MOV  AL,90H
        OUT  DX,AL           ;A��C��
        MOV  DX,0283H
        MOV  AL,00H
        OUT  DX,AL           ;��RS��ID�����㣨�˴���C�ڲ��������԰ѿ�����д����ƼĴ����У����¶��ô˴���
        MOV  DX,0283H
        MOV  AL,03H
        OUT  DX,AL           ;��PC1��RW��1���Զ�ȡæµ��־λ
WC1: 
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;��PC2��E��1
        CALL DELAY_SHORT
        MOV  DX,0280H
        IN   AL,DX           ;��A�ڵ�����д��
        PUSH AX              ;�Ѹ����ݱ�������
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;��PC2��E��0
        POP  AX
        AND  AL,80H          ;��ALȡ���λ��æλ
        JNZ  WC1             ;��æ
        MOV  DX,0283H
        MOV  AL,80H
        OUT  DX,AL           ;8255A��C��
        MOV  DX,0283H
        MOV  AL,02H
        OUT  DX,AL           ;��PC1��RW��0
        CALL DELAY_SHORT
        MOV  AL,LCD_CMD
        MOV  DX,0280H
        OUT  DX,AL           ;���ָ��
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;��PC2��E��1
        CALL DELAY_SHORT
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;��PC2��E��0
        POP  DX
        POP  AX
        RET
    WRITE_CMD ENDP
;----------------------------------------------------------------------------
;�ӳ���WRITE_DATA��         д����ʾ�ַ�(RS=1,RW=0)
;��ڲ�����                 LCD_DATA         Ҫд���LCD�ַ�ACSii��
;���ڲ�����
;���üĴ�����               AL,DX
;----------------------------------------------------------------------------
    WRITE_DATA PROC NEAR
        PUSH AX
        PUSH DX
        MOV  DX,0283H    
        MOV  AL,90H
        OUT  DX,AL           ;8255ѡ��A��C��
        MOV  DX,0283H
        MOV  AL,00H
        OUT  DX,AL           ;��RS��ID������
        MOV  DX,0283H
        MOV  AL,03H
        OUT  DX,AL           ;��PC1��RW��1���Զ�ȡæµ��־λ
WD1: 
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;��E��1
        MOV  DX,0280H
        IN   AL,DX
        PUSH AX
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;��E��0
        POP  AX
        AND  AL,80H
        JNZ  WD1             ;��æλ
        MOV  DX,0283H
        MOV  AL,80H
        OUT  DX,AL           ;A��C��
        MOV  DX,0283H
        MOV  AL,01H
        OUT  DX,AL           ;��RS��ID����1
        MOV  DX,0283H
        MOV  AL,02H
        OUT  DX,AL           ;��PC1��RW��0
        MOV  AL,LCD_DATA
        MOV  DX,0280H
        OUT  DX,AL           ;�������
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;��PC2��E��1
        CALL DELAY_SHORT
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;��PC2��E��0
        POP  DX
        POP  AX
        RET
    WRITE_DATA ENDP
;----------------------------------------------------------------------------
;�ӳ���DELAY_LONG��         ����ʱ
;��ڲ�����
;���ڲ�����
;���üĴ�����               BX,CX
;----------------------------------------------------------------------------
    DELAY_LONG PROC NEAR
        PUSH BX
        PUSH CX
        PUSHF
        MOV BX,20
D1: 
        MOV CX,6000
D2: 
        LOOP D2
        DEC BX
        JNZ D1
        POPF
        POP CX
        POP BX
        RET
    DELAY_LONG ENDP
;----------------------------------------------------------------------------
;�ӳ���DELAY_SHORT��        ����ʱ
;��ڲ�����
;���ڲ�����
;���üĴ�����               CX
;----------------------------------------------------------------------------
    DELAY_SHORT PROC NEAR
        PUSH CX
        PUSHF
        MOV CX,500
D3: 
        LOOP D3
        POPF
        POP CX
        RET
    DELAY_SHORT ENDP
;----------------------------------------------------------------------------
;�ӳ���GET_SWITCH_NUM��     ��8������״̬,�ָߵ�λ����
;��ڲ�����
;���ڲ�����                 SWITCH_NUM_LOW      ��λ
;                          SWITCH_NUM_HIGH     ��λ
;���üĴ�����               AL,CL,DX
;----------------------------------------------------------------------------
    GET_SWITCH_NUM PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV DX, 0293H
        MOV AL, 92H
        OUT DX, AL          ;A��B��C��
        MOV DX, 0291H
        IN  AL, DX          ;��PB
        PUSH AX
        AND AL, 0FH
        MOV SWITCH_NUM_LOW, AL;�����λ
        POP AX
        AND AL, 0F0H
        MOV CL, 4
        SHR AL, CL          ;����4λ
        MOV SWITCH_NUM_HIGH, AL;�����λ
        POPF                ;�ָ��ֳ�
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    GET_SWITCH_NUM ENDP
;----------------------------------------------------------------------------
;�ӳ���ARRAY_DISPLAY��      ��16*16����ɨ����ʾ
;��ڲ�����                 SWITCH_NUM_HIGH     ���ظ�λ
;                          SWITCH_NUM_LOW      ���ص�λ
;���ڲ�����
;���üĴ�����               AX,BX
;----------------------------------------------------------------------------
    ARRAY_DISPLAY PROC NEAR
        PUSH AX             ;�ֳ�����
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSH DI
        PUSHF

        MOV SI, OFFSET LED_TABLE
        MOV DI, OFFSET COLUMN
        MOV AL, 00H
        MOV AH, SWITCH_NUM_HIGH
        ADD SI, AX
        MOV CX, 8
SHOW_HIGH:
        MOV DX, 02B1H       
        MOV AL, 00H
        OUT DX, AL          ;�ұ�����
        MOV DX, 02B0H
        MOV AL, [DI]        ;��ֵ
        OUT DX, AL
        MOV DX, 02B3H
        MOV AL, [SI]
        OUT DX, AL          ;�ϰ벿��
        INC SI
        MOV DX, 02B2H
        MOV AL, [SI]
        OUT DX, AL          ;�°벿��
        INC SI
        INC DI
        LOOP SHOW_HIGH

        MOV SI, OFFSET LED_TABLE
        MOV DI, OFFSET COLUMN
        MOV AL, 00H
        MOV AH, SWITCH_NUM_HIGH
        ADD SI, AX
        MOV CX, 8
SHOW_LOW:
        MOV DX, 02B0H       
        MOV AL, 00H
        OUT DX, AL          ;�������
        MOV DX, 02B1H
        MOV AL, [DI]        ;��ֵ
        OUT DX, AL
        MOV DX, 02B3H
        MOV AL, [SI]
        OUT DX, AL          ;�ϰ벿��
        INC SI
        MOV DX, 02B2H
        MOV AL, [SI]
        OUT DX, AL          ;�°벿��
        INC SI
        INC DI
        LOOP SHOW_LOW

        MOV AH, 0BH
        INT 21H                 ;��ɨ�裺�޼���AL=00H���м���AL=FFH
        CMP AL, 0FFH
        JNZ SKIP2               ;�м������˳�ѭ��
        CALL EXIT
SKIP2:
        POPF                ;�ָ��ֳ�
        POP DI
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    ARRAY_DISPLAY ENDP
;----------------------------------------------------------------------------
;�ӳ���ARRAY_DELAY��        ��ɨ����ʱ
;��ڲ�����
;���ڲ�����
;���üĴ�����               CX
;----------------------------------------------------------------------------
    ARRAY_DELAY PROC NEAR
        PUSH CX
        PUSHF
        MOV CX, 4000
D4: 
        CALL GET_TIME
        CALL TIME_DIVIDE
        CALL LCD_DISPLAY_TIME
        LOOP D4
        POPF
        POP CX
        RET
    ARRAY_DELAY ENDP
    
    EXIT PROC NEAR
        PUSH AX
        MOV AH, 0BH
        INT 21H                 ;��ɨ�裺�޼���AL=00H���м���AL=FFH
        CMP AL, 0FFH
        JZ EXIT1
        JMP NOT_EXIT
EXIT1:        
        ;�˳�ǰ���ָ�ԭ�ж�����
        CLI                     ;���ж�
        MOV AX, INT_SEG
        MOV DS, AX
        MOV DX, INT_OFF
        MOV AH, 25H
        MOV AL, 0BH
        INT 21H                 ;DOS����-�����ж�����
        MOV AX, INT_SEG1
        MOV DS, AX
        MOV DX, INT_OFF1
        MOV AH, 25H
        MOV AL, 0CH
        INT 21H                 ;DOS����-�����ж�����
        MOV AL, INTSOR
        OUT 21H, AL             ;�ָ��ж�������
;����DOS
        MOV AH, 4CH
        INT 21H
NOT_EXIT:     
        POP AX
        RET
    EXIT ENDP
CODE    ENDS
END     START 