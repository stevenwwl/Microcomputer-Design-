# Microcomputer-Design-
微机原理课设
## basic_program.asm
![image](https://user-images.githubusercontent.com/48176748/110308009-8b645900-803a-11eb-8c50-067ed8f584ad.png)
通过A端口读入按键值，用数码管轮流显示按键值的高四位和低四位，具体方式为：高四位显示 1 秒，低四位显示 0.5 秒。 如此反复循环显示，如果有键盘按键输入，则退出程序并返回操作系统。  
![basic_program](https://user-images.githubusercontent.com/48176748/110316084-2f530200-8045-11eb-8caa-e90175a86ef7.png)

## extend_program_1.asm
通过实验台上 PS2 接口连接键盘，要求：   
1）输入字符（0\~F），转换成十进制后用数码管（1、2）显示（00\~15）；   
2）用实验台上的数码管（3、4）显示输入的次数，计数范围 0～99。  
[参考](https://blog.csdn.net/xqhrs232/article/details/78350203?utm_medium=distribute.pc_relevant.none-task-blog-baidujs_baidulandingword-8&spm=1001.2101.3001.4242)

## extend_program_4.asm
利用 8253、8255 和中断系统实现以下功能：  
 1）使液晶屏实现秒表功能，显示数字 00.00～10.00，每隔 0.01 秒数字变化一次；   
 2）读入8个开关的状态值，将这两位数字以16进制（范围 00H～FFH）在 16x16LED点阵模块上显示。  
[ST7920说明书](https://wenku.baidu.com/view/19f93f58be23482fb4da4c21.html)
![image](https://user-images.githubusercontent.com/48176748/111020583-02666c80-8402-11eb-89a1-58be1fc3e10b.png)
[16*8字模](https://wenku.baidu.com/view/e9b30eeb524de518964b7d77.html)
