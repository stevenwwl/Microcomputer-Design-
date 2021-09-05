;8255:0290H-0293H
;数据段定义
DATA    SEGMENT
    MES1 DB 'PRESS 0-F ON PS2 KEYBOARD',0AH,0DH,'$';DOS输出提示信息
    MES2 DB 'PRESS ANY KEY ON PC KEYBOARD TO EXIT TO DOS',0AH,0DH,'$'
    TAB DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH,77H,7CH,39H,5EH,79H,71H;数码管段码
    PS2 DB 45H,16H,1EH,26H,25H,2EH,36H,3DH,3EH,46H,1CH,32H,21H,23H,24H,2BH;PS2键盘0-F对应通码(断码2字节，+F0H)
    ;       0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    PRESS_NUM DB 00H        ;按键次数
    INPUT_BIT DB 00H        ;一次传输中，当前传输的位数
    INPUT_KEY_PS2 DB 00H    ;传输的编码
    INPUT_KEY DB 00H        ;按键值(00H-0FH)
    HEX_NUM DB ?            ;子程序NUM_DIVIDE入口参数
    TENS DB ?               ;转换后十位
    ONES DB ?               ;转换后个位
    DISPLAY_NUM DB ?        ;数码管要显示的数
    C_CONTROL DB ?          ;8255C口控制字
    SHOULD_LOAD DB 01H      ;状态位，CLK为低时，1表示接收数据，0不接收数据
DATA    ENDS
;堆栈段定义
STACKS   SEGMENT
    STA DW 100 DUP(?)
    TOP EQU LENGTH STA
STACKS   ENDS
;程序段初始化
CODE    SEGMENT
    ASSUME  CS:CODE,DS:DATA,SS:STACKS,ES:DATA
START:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX
    MOV AX, STACKS
    MOV SS, AX
    MOV SP, TOP
;显示提示信息
    MOV DX, OFFSET MES1
    MOV AH, 09H
    INT 21H
    MOV DX, OFFSET MES2
    MOV AH, 09H
    INT 21H
;初始化8255
    MOV DX, 0293H           ;控制端
    MOV AL, 90H             ;方式选择控制字-方式0-A入B出C出 10000000
    OUT DX, AL              ;写入控制字
;主循环
LOOP0:
    CALL LOAD
;显示按键值
    MOV AL, INPUT_KEY
    MOV HEX_NUM, AL
    CALL NUM_DIVIDE         ;把按键值分解

    MOV AL, ONES
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 01H      ;0000 000 1 PC0置1
    CALL LED_DISPLAY

    MOV AL, TENS
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 03H      ;0000 001 1 PC1置1
    CALL LED_DISPLAY
;显示按键次数
    MOV AL, PRESS_NUM
    MOV HEX_NUM, AL
    CALL NUM_DIVIDE         ;把按键次数分解

    MOV AL, ONES
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 05H      ;0000 010 1 PC2置1
    CALL LED_DISPLAY

    MOV AL, TENS
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 07H      ;0000 011 1 PC3置1
    CALL LED_DISPLAY
;判断是否退出程序
    MOV AH, 0BH
    INT 21H                 ;键扫描：无键入AL=00H，有键入AL=FFH
    CMP AL, 0FFH
    JNZ LOOP0               ;有键入则退出循环
    MOV AH, 4CH
    INT 21H
;----------------------------------------------------------------------------
;子程序LOAD：       串口通信
;入口参数：         INPUT_BIT       当前传输位数
;                   INPUT_KEY_PS2   上次传输的编码
;出口参数：         INPUT_BIT       下次传输位数
;                   INPUT_KEY_PS2   本次传输完成的编码
;所用寄存器：       AH,AL,CL,DX
;----------------------------------------------------------------------------
    LOAD PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
AGAIN2:        
        MOV DX, 0290H
        IN  AL, DX              ;PA0接DATA，PA4接CLK
        MOV BL, AL              ;复制AL
        AND AL, 01H             ;AL=01H,DATA=1;AL=00H,DATA=0
        AND BL, 10H             ;BL=10H,CLK=1;BL=00H,CLK=0
        TEST BL, 10H
        JNZ  CLK_HIGH
        JMP CLK_LOW
CLK_HIGH:
        MOV SHOULD_LOAD, 01H    ;高电平时，等待下一次低电平
        MOV CL, INPUT_BIT
        TEST CL, 0FFH
        JZ  IGNORE
        JMP AGAIN2
CLK_LOW:
        MOV BH, SHOULD_LOAD
        TEST BH, 0FFH           ;虽然为低电平，但已经读过此位
        JZ AGAIN2
        MOV SHOULD_LOAD, 00H
        MOV AH, INPUT_KEY_PS2
        MOV CL, INPUT_BIT
        TEST CL, 0FFH
        JZ  BEGIN_LOAD          ;CL=0清空编码为本次做准备
        CMP CL, 08H
        JA  FINISH              ;CL>8已传完，忽略对编码操作
        SHR AH, 1               ;CL=1~8时，右移1位
        TEST AL, 0FFH
        JZ  FINISH
        OR  AH, 80H             ;本位DATA=1，AH最高位置1
        JMP FINISH
BEGIN_LOAD:
        MOV INPUT_KEY_PS2, 00H
        INC CL
        MOV INPUT_BIT, CL
        JMP AGAIN2
FINISH:
        INC CL
        MOV INPUT_KEY_PS2, AH
        CMP CL, 0BH             ;当CL=11时，本次已传完，清变量准备下一次接收
        JNZ NO_CALL
        MOV CL, 00H
        MOV INPUT_BIT, CL
        CALL TRANSFORM_PS2      ;调用函数，把PS2编码转为0-F
        JMP IGNORE
NO_CALL:
        MOV INPUT_BIT, CL
        JMP AGAIN2   
IGNORE:
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    LOAD ENDP
;----------------------------------------------------------------------------
;子程序TRANSFORM_PS2：  将PS2编码转为0-F，若为断码，则按键次数加1
;入口参数：             INPUT_KEY_PS2   键盘PS2编码
;出口参数：             INPUT_KEY       转换后按键值
;                       PRESS_NUM       按键次数
;所用寄存器：           AX,BX,SI
;----------------------------------------------------------------------------
    TRANSFORM_PS2 PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSHF
        MOV AL, INPUT_KEY_PS2
        CMP AL, 0F0H
        JZ  PRESS_OFF       ;若为断码则跳转
        MOV BX, OFFSET PS2  ;循环
        MOV SI, 0000H
AGAIN:  
        MOV AH, BX[SI]
        INC SI
        CMP AH, AL
        JNZ AGAIN
        DEC SI
        MOV AX, SI
        MOV INPUT_KEY, AL   ;INPUT_KEY放入转换后0-F
        JMP FINISH1
PRESS_OFF:
        MOV BL, PRESS_NUM
        INC BL
        MOV PRESS_NUM, BL
FINISH1:
        POPF                ;恢复现场
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    TRANSFORM_PS2 ENDP
;----------------------------------------------------------------------------
;子程序NUM_DIVIDE：     将0-99范围内的1字节数转换为十位和个位
;入口参数：             HEX_NUM             要转换的1字节数
;出口参数：             TENS                转换后十位
;                       ONES                转换后个位
;所用寄存器：           AX,CL
;----------------------------------------------------------------------------
    NUM_DIVIDE PROC NEAR
        PUSH AX             ;现场保护
        PUSH CX
        PUSHF
        MOV AL, HEX_NUM     ;被转换数传入
        MOV AH, 00H
        MOV CL, 10
        DIV CL              ;AX/CL，商在AL，余数在AH
        MOV TENS, AL        ;返回结果
        MOV ONES, AH
        POPF                ;恢复现场
        POP CX
        POP AX
        RET
    NUM_DIVIDE ENDP
;----------------------------------------------------------------------------
;子程序LED_DISPLAY：    数码管显示
;入口参数：             DISPLAY_NUM         要显示的数字
;                       TAB                 数码管段码
;                       C_CONTROL           PC控制字
;出口参数：
;所用寄存器：           AL,BX,CX,DX
;----------------------------------------------------------------------------
    LED_DISPLAY PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH DX
        PUSHF
        MOV BX, OFFSET TAB  ;换码数据地址
        MOV AL, DISPLAY_NUM
        XLAT                ;(BX:AL) to AL，AL放入数码管字形
        MOV DX, 0291H       ;PB
        OUT DX, AL          ;写入字形
        MOV DX, 0293H       ;控制字
        MOV AL, C_CONTROL
        OUT DX, AL          ;点亮对应数码管
        MOV CX,500
LOOP1:
        CALL LOAD        ;延时
        LOOP LOOP1
        AND AL, 0FEH        ;算出对应数码管位码置0的PC控制字
        OUT DX, AL          ;熄灭对应数码管
        POPF                ;恢复现场
        POP DX
        POP BX
        POP AX
        RET
    LED_DISPLAY ENDP
CODE    ENDS
END     START