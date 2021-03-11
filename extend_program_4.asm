;8253:0280H-0283H  8255:0290H-0293H
;16*16点阵外挂在JX1扩展接口，列高8位-02B1H，列低8位-02B0H，行高8位02B3H，行低8位02B2H
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
    THOUSANDS DB ?          ;LCD显示的ASCii码
    HUNDREDS DB ?
    TENS DB ?
    ONES DB ?
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
    ;CLK0设置，OUT0为100Hz方波
    MOV DX, 0283H           ;控制端
    MOV AL, 36H             ;CLK0-高低字节-方式3-二进制 00110110
    OUT DX, AL
    MOV DX, 0280H           ;CLK0
    MOV AX, 2710H           ;10000=2710H, 1MHz to 100Hz
    OUT DX, AL
    MOV AL, AH
    OUT DX, AL
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
        MOV DX, 0283H       ;控制端
        MOV AL, 70H         ;CLK1-高低字节-方式0-二进制 01110000
        OUT DX, AL
        MOV DX, 0281H       ;CLK1
        MOV AX, WORD PTR TIME_TO_LOAD;写入初值
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        MOV IS_TIMING, 01H  ;IS_TIMING置1，下次暂停计时
        JMP FINISH
STOP_TIMING:
        MOV DX, 0283H       ;控制端
        MOV AL, 40H         ;CLK1锁存
        MOV DX, 0281H       ;CLK1
        IN  AL, DX
        MOV BL, AL          ;低8位
        IN  AL, DX
        MOV BH, AL          ;高8位
        MOV TIME_TO_LOAD, BX;保存暂停时的计数器值，下次开始时再装入
        MOV IS_TIMING, 00H  ;IS_TIMING置0，下次开始计时
FINISH:
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
        MOV WORD PTR TIME_TO_LOAD, 0FFFFH;重置初值
FINISH1:
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        STI                 ;开中断
        IRET                ;程序返回
    INT_CLEAR ENDP
;----------------------------------------------------------------------------
;子程序GET_TIME：           获取应该显示的时间
;入口参数：                 IS_TIMING       标识位
;                           TIME_TO_LOAD    计数初值
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
        MOV DX, 0283H       ;控制端
        MOV AL, 40H         ;CLK1锁存
        MOV DX, 0281H       ;CLK1
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
        MOV WORD PTR TIME, AX;返回出口参数
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    GET_TIME ENDP
;----------------------------------------------------------------------------
;子程序TIME_DIVIDE：        分割16进制数为千、百、十、个
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
        MOV AX, WORD PTR TIME
        MOV DX, 0
        MOV CX, 1000
        DIV CX              ;商在AX，余数在DX
        ADD AL, 30H
        MOV THOUSANDS, AL
        MOV AX, DX
        MOV CL, 100
        DIV CL              ;商在AL,余数在AH
        ADD AL, 30H
        MOV HUNDREDS, AL
        MOV AL, AH
        MOV AH, 0
        MOV CL, 10
        DIV CL              ;商在AL,余数在AH
        ADD AL, 30H
        MOV TENS, AL
        ADD AH, 30H
        MOV ONES, AH
        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    TIME_DIVIDE ENDP












CODE    ENDS
END     START 