new_09h  endp

;
; обработчик мультиплексорного прерывания
;

new_2fh proc
    cmp ah, 0fah		; проверить номер функции мультиплексорного прерывания
    jne out_2fh		; если не наша - выход
    cmp al, 0		; это подфункция проверки на повторную установку?
    je inst			; если да, то сообщить о невозможности повторн.установки
    cmp al, 01h		; подфункция выгрузки
    je  rezoff		; если да - выгрузка
    jmp out_2fh		; неизвестная подфункция – выход
inst:
    mov al,0ffh		; программа уже установлена
    iret			; выход из прерывания
out_2fh:			
    jmp cs:old_2fh		; переход в следующий по цепочке обработчик прерывания 2Fh
rezoff:  
    push ds
    push es
    push dx

    mov ax, 2509h		; восстановим вектор 09h
    lds dx, cs:old_09h	; ds:dx – вектор старого 09h
    int  21h

    mov ax, 252Fh		; восстановим старый вектор 2Fh
    lds  dx, cs:old_2Fh
    int  21h

    mov es, cs:2Ch		; выгрузка области окружения
    mov ah, 49h		; функция освобождения памяти
    int 21h

    push  cs
    pop  es			; выгрузка резидента 
    mov  ah,  49h
    int  21h
    
    pop dx
    pop es
    pop  ds
    iret
new_2fh endp

resident=$			; смещение конца резидентной части программы
main endp

;
; процедура инициализации
;

init proc
                    ; проверить, не установлена ли уже данная программа
    mov ah,0fah		; установить номер функции и подфункции для проверки
    mov al, 0		; на наличие резидентной программы в оперативной памяти
    int 2fh
    cmp al,0ffh		; программа установлена?
    je if_instaled		; если да, то перейти к выводу предупрежд. сообщения
                        ; сохранить вектор 2fh
    mov ax,352fh		; функция получения вектора 2fh
    int 21h

    mov word ptr cs:old_2fh,bx		; сохранить смещение системного обработчика
    mov word prt cs:old_2fh+2,es	; сохранить сегмент системного обработчика
                                    ; заполнить вектор 2fh
    mov ax,252fh			; функция установления вектора прерывания 2fh
    mov dx,offset new_2fh	; смещение нового обработчика
    int 21h
                            ; сохранить вектор 09h
	mov ax,3509h			; функция получения вектора 09h
	int 21h

    mov word prt cs:old_09h,bx		; сохранить смещение системного обработчика
    mov word prt cs:old_09h+2,es	; сохранить сегмент системного обработчика
                                    ; заполнить вектор 09h
    mov ax,2509h			; функция установления вектора прерывания 09h
    mov dx,offset new_09h	; смещение нового обработчика
    int 21h

    mov ah,09h			; функция вывода на экран
    lea dx.mes1;		; DS:DX - адрес строки
    int 21h
                        ; остаться резидентом
    mov ax,3100h		; функция «завершиться и остаться резидентом»
    mov dx,(resident-main+10fh)/16	; размер в параграфах
    int 21h

if_installed:
    mov cl, es:80h		; проверим длину параметров
    cmp cl, 00h			; если не 0, обработаем строку параметров
    jne  uninst			; иначе сообщим о наличии резидента в ОП	
    mov ah,09h			; функция вывода на экран
    lea dx,mes2			; DS:DX - адрес строки
    int 21h
    mov ax,4c01h				; функция завершения с кодом возврата
    int 21h

uninst: 
    xor ch, ch			; в сх – длина парам
    mov di, 81h		; stroka param
    lea si, unload		;  
    mov  al, ‘ ‘		; удалим пробелы в начале строки
    repe scasb			; cканирование строки
    dec  di
    mov cx,  2  		; длина проверяемого параметра ‘un’
    repe	cmpsb
    jne  m1
    mov ax, 0FA01h	; функция с подфункцией выгрузки мультиплексного прерывания
    int  2Fh
    mov ah,  09h
    Lea dx, mes3
    int 21h

m1:	
    mov ax, 4c03h
    int 21h
    
    
    mes1 db ‘Program installed!$’			; сообщение при установке резидента
    mes2 db ‘Program already installed!$’		; сообщение при попытке повторной установки
    mes3 db ‘Program unload!$’			; mess.  3
    unload db ‘un’
init endp
code ends
end main