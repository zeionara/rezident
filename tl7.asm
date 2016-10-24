STACK SEGMENT PARA 'stack'
	DB 100H DUP(?)
STACK ENDS

DATA SEGMENT PARA PUBLIC 'data'
	
DATA ENDS

delay  macro  t
	local  m1, m2
	
	push  cx
	mov  cx,  t
	m1:  push  cx
          mov  cx,  65535
	m2:  loop m2
         pop  cx
         loop  m1
	pop  cx
endm

CODE SEGMENT PARA PUBLIC 'code'
	ASSUME CS: CODE, DS: DATA, SS: STACK
	
	START:    
	MOV AX, DATA
	MOV DS, AX

	in  al,  61h
	or  al,  3h
	out  61h,  al
	
	delay  40
	
	and  al,  11111100b   ;  0fch
	out  61h,  al

	

	MOV AX, 4C00H
	INT   21H
CODE ENDS
END  START
