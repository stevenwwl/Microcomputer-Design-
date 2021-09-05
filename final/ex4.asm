;8253:0280H-0283H  8255:0290H-0293H
;16*16点阵外挂在JX1扩展接口，列高8位-02B1H，列低8位-02B0H，行高8位-02B3H，行低8位-02B2H
;LCD12864:RS-PC0  RW-PC1  E-PC2
;数据段定义
DATA    SEGMENT
    MES DB 'PRESS ANY KEY EXIT TO DOS',0AH,0DH,'$';DOS输出提示信息
    INT_SEG DW ?            ;IRQ3原中断向量段基址
    INT_OFF DW ?            ;IRQ3原中断向量偏移
    INT_SEG1 DW ?           ;IRQ4原中断向量段基址
    INT_OFF1 DW ?           ;IRQ4原中断向量偏移
    INTSOR DB ?             ;原中断屏蔽字
    TIME_TO_LOAD DW 0FFFFH  ;每次开始时计数器装入的初值
    TIME DW 0000H           ;真正的时间
    IS_TIMING DB 00H        ;用以区分本次中断时开始计时还是暂停计时
    TIME_STRING DB ' 00.00s ';显示数字字符串,8个字符
    LCD_CMD DB ?            ;写入的LCD命令代码
    LCD_DATA DB ?           ;写入的LCD字符ACSii码
    LINE_1 DB ' Digital  Timer ';第一行显示,16个字符
    SWITCH_NUM_HIGH DB ?    ;开关状态高位
    SWITCH_NUM_LOW DB ?     ;开关状态低位
    COLUMN_ADDRESS DW ?     ;点阵列地址
    ROW_ADDRESS1 DW ?        ;点阵行地址
    ROW_ADDRESS2 DW ?
    ROW_CODE_OFFSET DW ?    ;行输出的偏移地址
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
    MOV DX, OFFSET MES
    MOV AH, 09H
    INT 21H
;初始化8253
    ;CNT0设置，OUT0为100Hz方波
    MOV DX, 0293H           ;控制端
    MOV AL, 36H             ;CNT0-高低字节-方式3-二进制 00110110
    OUT DX, AL
    MOV DX, 0290H           ;CNT0
    MOV AX, 2710H           ;10000=2710H, 1MHz to 100Hz
    OUT DX, AL
    MOV AL, AH
    OUT DX, AL
;初始化LCD12864
    CALL DELAY_LONG
    CALL LCD_INIT
;存储中断向量
    CLI                     ;关中断
    MOV AH, 35H             ;DOS调用-获取中断向量,ES:BX中断向量
    MOV AL, 0BH             ;传入中断向量号(IRQ3)
    INT 21H
    MOV AX, ES
    MOV INT_SEG, AX         ;存段基址
    MOV INT_OFF, BX         ;存偏移
    MOV AH, 35H             ;DOS调用-获取中断向量,ES:BX中断向量
    MOV AL, 0CH             ;传入中断向量号(IRQ4)
    INT 21H
    MOV AX, ES
    MOV INT_SEG1, AX        ;存段基址
    MOV INT_OFF1, BX        ;存偏移
;设置新中断向量
    PUSH DS                 ;暂存DS
    MOV AX, SEG INT_TIMER
    MOV DS, AX              ;中断程序CS
    MOV DX, OFFSET INT_TIMER;中断程序IP
    MOV AH, 25H             ;DOS调用-设置中断向量,DS:DX=中断程序入口
    MOV AL, 0BH             ;传入中断向量号(IRQ3)
    INT 21H
    MOV AX, SEG INT_CLEAR
    MOV DS, AX              ;中断程序CS
    MOV DX, OFFSET INT_CLEAR;中断程序IP
    MOV AH, 25H             ;DOS调用-设置中断向量,DS:DX=中断程序入口
    MOV AL, 0CH             ;传入中断向量号(IRQ4)
    INT 21H
    POP DS                  ;恢复DS
    IN  AL, 21H
    MOV INTSOR, AL          ;保护原中断屏蔽字
    AND AL, 0E7H            ;开放IRQ3、IRQ34
    OUT 21H, AL
    STI                     ;开中断
;循环检测是否有键按下
LOOP0:
    CALL GET_TIME
    CALL TIME_DIVIDE
    CALL LCD_DISPLAY_TIME
    CALL GET_SWITCH_NUM
    CALL ARRAY_DISPLAY
    JMP LOOP0
;----------------------------------------------------------------------------
;中断子程序INT_TIMER：      当IS_TIMING为0跳转到开始计时，IS_TIMING为1暂停计时
;入口参数：                 IS_TIMING       本次标识位
;                           TIME_TO_LOAD    本次初值
;出口参数：                 IS_TIMING       下次标识位
;                           TIME_TO_LOAD    下次初值
;所用寄存器：               AX,BX,DX
;----------------------------------------------------------------------------
    INT_TIMER PROC FAR
        CLI                 ;关中断
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV AL, IS_TIMING
        CMP AL, 00H
        JZ START_TIMING     ;IS_TIMING为0跳转到开始计时
        CMP AL, 01H
        JZ STOP_TIMING      ;IS_TIMING为1跳转到暂停计时        
START_TIMING:
        MOV DX, 0293H       ;控制端
        MOV AL, 70H         ;CNT1-高低字节-方式0-二进制 01110000
        OUT DX, AL
        MOV DX, 0291H       ;CNT1
        MOV AX, WORD PTR TIME_TO_LOAD;写入初值
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        MOV IS_TIMING, 01H  ;IS_TIMING置1，下次暂停计时
        JMP FINISH
STOP_TIMING:
        MOV DX, 0293H       ;控制端
        MOV AL, 40H         ;CNT1锁存
        MOV DX, 0291H       ;CNT1
        IN  AL, DX
        MOV BL, AL          ;低8位
        IN  AL, DX
        MOV BH, AL          ;高8位
        MOV TIME_TO_LOAD, BX;保存暂停时的计数器值，下次开始时再装入
        MOV IS_TIMING, 00H  ;IS_TIMING置0，下次开始计时
FINISH:
        MOV AL, 20H         ;发结束中断命令
        OUT 20H, AL
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        STI                 ;开中断
        IRET                ;程序返回
    INT_TIMER ENDP
;----------------------------------------------------------------------------
;中断子程序INT_CLEAR：      计时暂停时，按键清零秒表
;入口参数：                 IS_TIMING       标识位
;出口参数：                 TIME_TO_LOAD    下次计数初值
;所用寄存器：               AL
;----------------------------------------------------------------------------
    INT_CLEAR PROC FAR
        CLI                 ;关中断
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV AL, IS_TIMING
        CMP AL, 01H         ;若正在计时，不能使用清零功能
        JZ FINISH1
        MOV TIME_TO_LOAD, 0FFFFH;重置初值
FINISH1:
        MOV AL, 20H         ;发结束中断命令
        OUT 20H, AL
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        STI                 ;开中断
        IRET                ;程序返回
    INT_CLEAR ENDP
;----------------------------------------------------------------------------
;子程序LCD_DISPLAY_TIME：   LCD第二行显示秒表数字
;入口参数：                 TIME_STRING     8字节的显示字符串
;出口参数：
;所用寄存器：               AL,BX,CX,SI
;----------------------------------------------------------------------------
    LCD_DISPLAY_TIME PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSHF
        MOV LCD_CMD, 92H
        CALL WRITE_CMD      ;光标移到第二行偏左
        MOV BX, OFFSET TIME_STRING
        MOV SI, 0
        MOV CX, 8
AGAIN1:
        MOV AL, BX[SI]
        MOV LCD_DATA, AL
        CALL WRITE_DATA     ;写入' xx.xxs '
        INC SI
        DEC CX
        JNZ AGAIN1
        POPF                ;恢复现场
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    LCD_DISPLAY_TIME ENDP
;----------------------------------------------------------------------------
;子程序GET_TIME：           获取应该显示的时间
;入口参数：                 IS_TIMING       标识位
;                          TIME_TO_LOAD    计数初值
;出口参数：                 TIME            返回的应该显示的时间
;所用寄存器：               AX,BX,DX
;----------------------------------------------------------------------------
    GET_TIME PROC NEAR
        PUSH AX             ;现场保护
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
        MOV DX, 0293H       ;控制端
        MOV AL, 40H         ;CNT1锁存
        MOV DX, 0291H       ;CNT1
        IN  AL, DX
        MOV BL, AL          ;低8位
        IN  AL, DX
        MOV BH, AL          ;高8位
        MOV AX, 0FFFFH
        SUB AX,BX
FINISH2:
        CMP AX, 10000
        JB SKIP             ;小于10000(为4位数)时跳转
        MOV AX, 9999
SKIP:
        MOV TIME, AX        ;返回出口参数
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    GET_TIME ENDP
;----------------------------------------------------------------------------
;子程序TIME_DIVIDE：        分割16进制数为十位、个位、十分位、百分位
;入口参数：                 TIME            要分割的时间
;出口参数：                 THOUSANDS,HUNDREDS,TENS,ONES分割好的位数的ASCii码
;所用寄存器：               AX,CX,DX
;----------------------------------------------------------------------------
    TIME_DIVIDE PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV BX, OFFSET TIME_STRING
        MOV AX, WORD PTR TIME
        MOV DX, 0
        MOV CX, 1000
        DIV CX              ;商在AX，余数在DX
        ADD AL, 30H
        MOV [BX+01H], AL    ;存十位
        MOV AX, DX
        MOV CL, 100
        DIV CL              ;商在AL,余数在AH
        ADD AL, 30H
        MOV [BX+02H], AL    ;存个位
        MOV AL, AH
        MOV AH, 0
        MOV CL, 10
        DIV CL              ;商在AL,余数在AH
        ADD AL, 30H
        MOV [BX+04H], AL    ;存十分位
        ADD AH, 30H
        MOV [BX+05H], AH    ;存百分位
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    TIME_DIVIDE ENDP
;----------------------------------------------------------------------------
;子程序LCD_INIT：           LCD初始化设置
;入口参数：                 LINE_1          第一行显示的字符串
;出口参数：
;所用寄存器：               AL,BX,CX,SI
;----------------------------------------------------------------------------
    LCD_INIT PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSHF
        MOV LCD_CMD, 30H
        CALL WRITE_CMD
        MOV LCD_CMD, 30H
        CALL WRITE_CMD      ;功能设定：8位接口，基本指令集
        MOV LCD_CMD, 0CH
        CALL WRITE_CMD      ;显示开关设置：整体显示开，游标显示关，反白显示关
        MOV LCD_CMD, 01H
        CALL WRITE_CMD      ;清除显示
        MOV LCD_CMD, 06H
        CALL WRITE_CMD      ;进入设定点：游标右移,画面不移动
        MOV LCD_CMD, 80H
        CALL WRITE_CMD      ;光标移到第一行开头
        MOV BX, OFFSET LINE_1
        MOV SI, 0
        MOV CX, 16
AGAIN:
        MOV AL, BX[SI]
        MOV LCD_DATA, AL
        CALL WRITE_DATA     ;写入' Digital  Timer '
        INC SI
        DEC CX
        JNZ AGAIN
        POPF                ;恢复现场
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    LCD_INIT ENDP
;----------------------------------------------------------------------------
;子程序WRITE_CMD：          写入控制命令(RS=0,RW=0)
;入口参数：                 LCD_CMD         要写入的命令编码
;出口参数：
;所用寄存器：               AL,DX
;----------------------------------------------------------------------------
    WRITE_CMD PROC NEAR
        PUSH AX
        PUSH DX
        MOV  DX,0283H
        MOV  AL,90H
        OUT  DX,AL           ;A入C出
        MOV  DX,0283H
        MOV  AL,00H
        OUT  DX,AL           ;把RS（ID）置零（此处对C口操作，所以把控制字写入控制寄存器中，以下都用此处）
        MOV  DX,0283H
        MOV  AL,03H
        OUT  DX,AL           ;把PC1即RW置1，以读取忙碌标志位
WC1: 
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;把PC2即E置1
        CALL DELAY_SHORT
        MOV  DX,0280H
        IN   AL,DX           ;把A口的数据写入
        PUSH AX              ;把该数据保存起来
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;把PC2即E置0
        POP  AX
        AND  AL,80H          ;把AL取最高位即忙位
        JNZ  WC1             ;查忙
        MOV  DX,0283H
        MOV  AL,80H
        OUT  DX,AL           ;8255A出C出
        MOV  DX,0283H
        MOV  AL,02H
        OUT  DX,AL           ;把PC1即RW置0
        CALL DELAY_SHORT
        MOV  AL,LCD_CMD
        MOV  DX,0280H
        OUT  DX,AL           ;输出指令
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;把PC2即E置1
        CALL DELAY_SHORT
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;把PC2即E置0
        POP  DX
        POP  AX
        RET
    WRITE_CMD ENDP
;----------------------------------------------------------------------------
;子程序WRITE_DATA：         写入显示字符(RS=1,RW=0)
;入口参数：                 LCD_DATA         要写入的LCD字符ACSii码
;出口参数：
;所用寄存器：               AL,DX
;----------------------------------------------------------------------------
    WRITE_DATA PROC NEAR
        PUSH AX
        PUSH DX
        MOV  DX,0283H    
        MOV  AL,90H
        OUT  DX,AL           ;8255选择A入C出
        MOV  DX,0283H
        MOV  AL,00H
        OUT  DX,AL           ;把RS（ID）置零
        MOV  DX,0283H
        MOV  AL,03H
        OUT  DX,AL           ;把PC1即RW置1，以读取忙碌标志位
WD1: 
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;把E置1
        MOV  DX,0280H
        IN   AL,DX
        PUSH AX
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;把E置0
        POP  AX
        AND  AL,80H
        JNZ  WD1             ;查忙位
        MOV  DX,0283H
        MOV  AL,80H
        OUT  DX,AL           ;A出C出
        MOV  DX,0283H
        MOV  AL,01H
        OUT  DX,AL           ;把RS（ID）置1
        MOV  DX,0283H
        MOV  AL,02H
        OUT  DX,AL           ;把PC1即RW置0
        MOV  AL,LCD_DATA
        MOV  DX,0280H
        OUT  DX,AL           ;输出数据
        MOV  DX,0283H
        MOV  AL,05H
        OUT  DX,AL           ;把PC2即E置1
        CALL DELAY_SHORT
        MOV  DX,0283H
        MOV  AL,04H
        OUT  DX,AL           ;把PC2即E置0
        POP  DX
        POP  AX
        RET
    WRITE_DATA ENDP
;----------------------------------------------------------------------------
;子程序DELAY_LONG：         长延时
;入口参数：
;出口参数：
;所用寄存器：               BX,CX
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
;子程序DELAY_SHORT：        短延时
;入口参数：
;出口参数：
;所用寄存器：               CX
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
;子程序GET_SWITCH_NUM：     读8个开关状态,分高低位保存
;入口参数：
;出口参数：                 SWITCH_NUM_LOW      低位
;                          SWITCH_NUM_HIGH     高位
;所用寄存器：               AL,CL,DX
;----------------------------------------------------------------------------
    GET_SWITCH_NUM PROC NEAR
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV DX, 0293H
        MOV AL, 92H
        OUT DX, AL          ;A入B入C出
        MOV DX, 0291H
        IN  AL, DX          ;读PB
        PUSH AX
        AND AL, 0FH
        MOV SWITCH_NUM_LOW, AL;保存低位
        POP AX
        AND AL, 0F0H
        MOV CL, 4
        SHR AL, CL          ;右移4位
        MOV SWITCH_NUM_HIGH, AL;保存高位
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    GET_SWITCH_NUM ENDP
;----------------------------------------------------------------------------
;子程序ARRAY_DISPLAY：      在16*16区域扫描显示
;入口参数：                 SWITCH_NUM_HIGH     开关高位
;                          SWITCH_NUM_LOW      开关低位
;出口参数：
;所用寄存器：               AX,BX
;----------------------------------------------------------------------------
    ARRAY_DISPLAY PROC NEAR
        PUSH AX             ;现场保护
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
        OUT DX, AL          ;右边清零
        MOV DX, 02B0H
        MOV AL, [DI]        ;列值
        OUT DX, AL
        MOV DX, 02B3H
        MOV AL, [SI]
        OUT DX, AL          ;上半部分
        INC SI
        MOV DX, 02B2H
        MOV AL, [SI]
        OUT DX, AL          ;下半部分
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
        OUT DX, AL          ;左边清零
        MOV DX, 02B1H
        MOV AL, [DI]        ;列值
        OUT DX, AL
        MOV DX, 02B3H
        MOV AL, [SI]
        OUT DX, AL          ;上半部分
        INC SI
        MOV DX, 02B2H
        MOV AL, [SI]
        OUT DX, AL          ;下半部分
        INC SI
        INC DI
        LOOP SHOW_LOW

        MOV AH, 0BH
        INT 21H                 ;键扫描：无键入AL=00H，有键入AL=FFH
        CMP AL, 0FFH
        JNZ SKIP2               ;有键入则退出循环
        CALL EXIT
SKIP2:
        POPF                ;恢复现场
        POP DI
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    ARRAY_DISPLAY ENDP
;----------------------------------------------------------------------------
;子程序ARRAY_DELAY：        列扫描延时
;入口参数：
;出口参数：
;所用寄存器：               CX
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
        INT 21H                 ;键扫描：无键入AL=00H，有键入AL=FFH
        CMP AL, 0FFH
        JZ EXIT1
        JMP NOT_EXIT
EXIT1:        
        ;退出前，恢复原中断向量
        CLI                     ;关中断
        MOV AX, INT_SEG
        MOV DS, AX
        MOV DX, INT_OFF
        MOV AH, 25H
        MOV AL, 0BH
        INT 21H                 ;DOS调用-设置中断向量
        MOV AX, INT_SEG1
        MOV DS, AX
        MOV DX, INT_OFF1
        MOV AH, 25H
        MOV AL, 0CH
        INT 21H                 ;DOS调用-设置中断向量
        MOV AL, INTSOR
        OUT 21H, AL             ;恢复中断屏蔽字
;返回DOS
        MOV AH, 4CH
        INT 21H
NOT_EXIT:     
        POP AX
        RET
    EXIT ENDP
CODE    ENDS
END     START 