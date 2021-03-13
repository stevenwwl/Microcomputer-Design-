data segment
data ends
code segment
start:assume ds:data,cs:code
mov dx,029bh
mov al,90h
out dx,al
 
 again:mov dx,0298h
        in al,dx
       mov dx,0299h
       out dx,al
       jmp again
code ends
end start