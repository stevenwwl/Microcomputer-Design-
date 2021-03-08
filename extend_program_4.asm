;8253:0280H-0283H  8255:0290H-0293H
;16*16点阵外挂在JX1扩展接口，列高8位-02B1H，列低8位-02B0H，行高8位02B3H，行低8位02B2H
;数据段定义
DATA    SEGMENT
    MES DB 'PRESS ANY KEY EXIT TO DOS',0AH,0DH,'$';DOS输出提示信息
    INT_SEG DW ?            ;原中断向量段基址
    INT_OFF DW ?            ;原中断向量偏移
    INTSOR DB ?             ;原中断屏蔽字
    TIME DW 0000H           ;秒表数字
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
    ;CLK0设置，OUT0为1kHz方波
    MOV DX, 0283H           ;控制端
    MOV AL, 36H             ;CLK0-高低字节-方式3-二进制 00110110
    OUT DX, AL
    MOV DX, 0280H           ;CLK0
    MOV AX, 03E8H           ;1000=03E8H, 1MHz to 1kHz
    OUT DX, AL
    MOV AL, AH
    OUT DX, AL
    ;CLK1设置，OUT1为100Hz方波
    MOV DX, 0283H           ;控制端
    MOV AL, 76H             ;CLK1-高低字节-方式3-二进制 01110110
    OUT DX, AL
    MOV DX, 0281H           ;CLK1
    MOV AX, 000AH           ;10=000AH, 1kHz to 100Hz
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
    INT 21H                 ;;DOS调用-设置中断向量
    MOV AL, INTSOR
    OUT 21H, AL             ;恢复中断屏蔽字
;返回DOS
    MOV AH, 4CH
    INT 21H
;----------------------------------------------------------------------------
;中断子程序INT_PR： 每0.01s触发一次，时间计数值+1
;入口参数：         TIME    计数时间
;                   
;出口参数：         TIME    更新后的计数时间
;所用寄存器：       AX,BX,CL,DX
;----------------------------------------------------------------------------
    INT_PR PROC FAR
        CLI                 ;关中断
        PUSH AX             ;现场保护
        PUSH BX
        PUSH CX
        PUSH DX
        PUSHF
        MOV AX, TIME
        INC AX
        CMP AX, 03E8H       ;
        





        POPF                ;恢复现场
        POP DX
        POP CX
        POP BX
        POP AX
        STI                 ;开中断
        IRET                ;程序返回
    INT_PR ENDP









CODE    ENDS
END     START 