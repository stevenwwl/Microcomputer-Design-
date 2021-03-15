;8255:0290H-0293H
;CLK接非门再接IRQ3，8255PA7接DATA，PB接数码管段码，PC0-PC3接数码管位码
;数据段定义
DATA    SEGMENT
    MES1 DB 'PRESS 0-F ON PS2 KEYBOARD',0AH,0DH,'$';DOS输出提示信息
    MES2 DB 'PRESS ANY KEY ON PC KEYBOARD TO EXIT TO DOS',0AH,0DH,'$'
    TAB DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH,77H,7CH,39H,5EH,79H,71H;数码管段码
    PS2 DB 45H,16H,1EH,26H,25H,2EH,36H,3DH,3EH,46H,1CH,32H,21H,23H,24H,2BH;PS2键盘0-F对应通码(断码2字节，+F0H)
    INT_SEG DW ?            ;原中断向量段基址
    INT_OFF DW ?            ;原中断向量偏移
    INTSOR DB ?             ;原中断屏蔽字
    PRESS_NUM DB 00H        ;按键次数
    INPUT_BIT DB 00H        ;一次传输中，当前传输的位数
    INPUT_KEY_PS2 DB 00H    ;传输的编码
    INPUT_KEY DB 00H        ;按键值(00H-0FH)
    HEX_NUM DB ?            ;子程序NUM_DIVIDE入口参数
    TENS DB ?               ;转换后十位
    ONES DB ?               ;转换后个位
    DISPLAY_NUM DB ?        ;数码管要显示的数
    C_CONTROL DB ?          ;8255C口控制字
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
;存储中断向量
    CLI                     ;关中断
    MOV AH, 35H             ;DOS调用-获取中断向量,ES:BX中断向量
    MOV AL, 0BH             ;传入中断向量号(IRQ3)
    INT 21H
    MOV AX, ES
    MOV INT_SEG, AX         ;存段基址
    MOV INT_OFF, BX         ;存偏移
;设置新中断向量
    PUSH DS                 ;暂存DS
    MOV AX, SEG INT_PR
    MOV DS, AX              ;中断程序CS
    MOV DX, OFFSET INT_PR   ;中断程序IP
    MOV AH, 25H             ;DOS调用-设置中断向量,DS:DX=中断程序入口
    MOV AL, 0BH             ;传入中断向量号(IRQ3)
    INT 21H
    POP DS                  ;恢复DS
    IN  AL, 21H
    MOV INTSOR, AL          ;保护原中断屏蔽字
    AND AL, 0F7H            ;开放IRQ3
    OUT 21H, AL
    STI                     ;开中断
;主循环
LOOP0:
;显示按键值
    MOV AL, INPUT_KEY
    MOV HEX_NUM, AL
    CALL NUM_DIVIDE         ;把按键值分解

    MOV AL, ONES
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 00H      ;0000 000 0 PC0置0
    CALL LED_DISPLAY

    MOV AL, TENS
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 02H      ;0000 001 0 PC1置0
    CALL LED_DISPLAY
;显示按键次数
    MOV AL, PRESS_NUM
    MOV HEX_NUM, AL
    CALL NUM_DIVIDE         ;把按键次数分解

    MOV AL, ONES
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 04H      ;0000 010 0 PC2置0
    CALL LED_DISPLAY

    MOV AL, TENS
    MOV DISPLAY_NUM, AL
    MOV C_CONTROL, 06H      ;0000 011 0 PC3置0
    CALL LED_DISPLAY
;判断是否退出程序
    MOV AH, 0BH
    INT 21H                 ;键扫描：无键入AL=00H，有键入AL=FFH
    ADD AL, 01H
    JNZ LOOP0               ;有键入则退出循环
;退出前，恢复原中断向量
    CLI                     ;关中断
    MOV AX, INT_SEG
    MOV DS, AX
    MOV DX, INT_OFF
    MOV AH, 25H
    MOV AL, 0BH
    INT 21H                 ;;DOS调用-设置中断向量
    MOV AL, INTSOR
    OUT 21H, AL             ;恢复中断屏蔽字
;返回DOS
    MOV AH, 4CH
    INT 21H
;----------------------------------------------------------------------------
;中断子程序INT_PR： 每触发一次传输1位
;入口参数：         INPUT_BIT       当前传输位数
;                   INPUT_KEY_PS2   上次传输的编码
;出口参数：         INPUT_BIT       下次传输位数
;                   INPUT_KEY_PS2   传输完成的编码
;所用寄存器：       AH,AL,BX,CL,DX
;----------------------------------------------------------------------------
    INT_PR PROC FAR
        CLI                 ;关中断
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV DX, 0290H       ;PA
        IN  AL, DX          ;取本位DATA。为0，AL=7FH；为1，AL=FFH
        MOV AH, INPUT_KEY_PS2;AH装入上次传输的编码
        MOV CL, INPUT_BIT   ;CL装入当前传输的位数
        CMP CL, 00H
        JZ  CLEAR        ;CL=0清空编码为本次做准备
        CMP CL, 08H
        JA  IGNORE          ;CL>8已传完，忽略对编码操作
        SHR AH, 1           ;CL=1~8时，右移1位
        CMP AL, 7FH
        JZ  IGNORE
        OR  AH, 80H         ;本位DATA=1，AH最高位置1
        JMP IGNORE
CLEAR:
        MOV AH, 00H
IGNORE:
        INC CL

        CMP CL, 0BH         ;当CL=11时，本次已传完，清变量准备下一次接收
        JNZ FINISH
        MOV CL, 00H
        MOV INPUT_KEY_PS2, AH
        CALL TRANSFORM_PS2  ;调用函数，把PS2编码转为0-F
FINISH:
        MOV INPUT_KEY_PS2, AH
        MOV INPUT_BIT, CL
        MOV AL, 20H         ;发结束中断命令
        OUT 20H, AL
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        STI                 ;开中断
        IRET                ;程序返回
    INT_PR ENDP
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
        CMP AH, AL
        INC SI
        JNZ AGAIN
        MOV AX, SI
        MOV INPUT_KEY, AL   ;INPUT_KEY放入转换后0-F
        JMP FINISH1
PRESS_OFF:
        INC PRESS_NUM
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
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV AL, HEX_NUM     ;被转换数传入
        CBW                 ;扩展双字
        MOV CL, 10
        DIV CL              ;AX/CL，商在AL，余数在AH
        MOV TENS, AH        ;返回结果
        MOV ONES, AL
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    NUM_DIVIDE ENDP
;----------------------------------------------------------------------------
;子程序LED_DISPLAY：    数码管显示
;入口参数：             DISPLAY_NUM         要显示的数字
;                       TAB                 数码管段码
;                       C_CONTROL           PC控制字
;出口参数：
;所用寄存器：           AL,BX,DX
;----------------------------------------------------------------------------
    LED_DISPLAY PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
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
        CALL DELAY          ;延时
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    LED_DISPLAY ENDP
;----------------------------------------------------------------------------
;子程序DELAY：          延时一小段时间
;入口参数：
;出口参数：
;所用寄存器：           CX
;----------------------------------------------------------------------------
    DELAY PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV CX, 1000
AGAIN1:
        NOP
        LOOP AGAIN1
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    DELAY ENDP
CODE    ENDS
END     START