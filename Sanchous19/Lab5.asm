; ������������ �1(������� 8)
.MODEL SMALL
.STACK 100h

.DATA
	matrixAsString db 500 dup(?)
	len dw 0
	handle dw 1
	matrix dw 50 dup(?)
	numOfRows dw 1
	numOfColumns dw 1
	k dw ?
	l dw ?
	integerNumber db 6 dup(?)
	minus db 0
	ten dw 10
	inputFileName db 'input.txt', 0
	outputFileName db 'output.txt', 0
	kMessage db 'k: ', '$'
	lMessage db 'l: ', '$'
	fileErrorMessage db 'Error with file', 13, 10, '$'
	valueOfElementsInFileErrorMessage db 'The elements of matrix in file have incorrect value', 13, 10, '$'
	inputErrorMessage db 'Input error, please enter the number again', 13, 10, '$'
	borderErrorMessage db 'l-row(column) in matrix does not exist', 13, 10, '$'
	endline db 13, 10, '$'
.CODE

readMatrixFromFile proc							; ��������� ������ ������ �� �����
	push ax
	push bx
	push cx
	push dx

	mov ah,3dH
	lea dx,inputFileName
	xor al,al
	int 21h										; �������� �����
	jnc fileIsOpen1
	call errorWithFile
fileIsOpen1:
	mov [handle],ax
	mov bx,ax
	mov ah,3fH
	lea dx,matrixAsString
	mov cx,500
	int 21h										; ������ �����
	jnc fileIsRead
	call errorWithFile
fileIsRead:
	mov len,ax
	lea bx,matrixAsString
	add bx,ax
	mov byte ptr[bx],'$'

	mov ah,3eH									; �������� �����
	mov bx,[handle]
	int 21h
	jnc fileIsClose1
	call errorWithFile
fileIsClose1:

	pop dx
	pop cx
	pop bx
	pop ax
	ret
readMatrixFromFile endp


writeMatrixInFile proc							; ��������� ������ ������ � ����
	push ax
	push bx
	push cx
	push dx

	mov ah,3cH
	xor cx,cx
	lea dx,outputFileName
	int 21h										; �������� �����
	jnc fileIsOpen2
	call errorWithFile
fileIsOpen2:
	mov [handle],ax
	mov bx,ax
	mov ah,40H
	lea dx,matrixAsString
	mov cx,len
	int 21h										; ������ � ����
	jnc recordedInFile
	call errorWithFile
recordedInFile:
	mov ah,3eH
	mov bx,[handle]
	int 21h										; �������� �����
	jnc fileIsClose2
	call errorWithFile
fileIsClose2:

	pop dx
	pop cx
	pop bx
	pop ax
	ret
writeMatrixInFile endp


errorWithFile proc								; ���������, �������������� ������ � �������
	lea dx,fileErrorMessage
	call printString
	mov ah,4ch
    int 21h
errorWithFile endp


convertStringInMatrix proc					; ��������� �������������� ������ � �������
	push ax
	push bx
	push cx						
	push dx
	push di
	
	lea di,matrixAsString
	mov cx,len
viewString:									; ������ ���� ������ �������� �� ������ ���������
	cmp byte ptr[di],10
	jne symbolIsNot10
	mov byte ptr[di],9
symbolIsNot10:
	cmp byte ptr[di],13
	jne symbolIsNot13
	mov byte ptr[di],9
	inc numOfRows
symbolIsNot13:
	inc di
	loop viewString
	mov byte ptr[di],9

	cld
	lea di,matrixAsString
	inc len
	mov cx,len
	xor dx,dx
findWord:
	cmp cx,0
	je finishSolveFunction

	lea cx,matrixAsString
	sub cx,di
	add cx,len
	mov al,9
	repe scasb
	jcxz finishSolveFunction
	mov bx,di								; ���������� ������ �������� �������
	dec bx
	repne scasb
	mov cx,di
	dec cx
	sub cx,bx								; ���������� ����� �������� �������
	push di

	mov di,bx								; ���������� ��������� �� ������ ��������
	call CheckIntegerNumber
	mov bx,dx
	mov matrix[bx],ax						; ������ �������� � �������
	add dx,2
	pop di
	jmp findWord

finishSolveFunction:
	mov ax,dx
	shr ax,1
	xor dx,dx
	div numOfRows
	mov numOfColumns,ax
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
convertStringInMatrix endp


CheckIntegerNumber proc						; �������� �� ����� �����	
	push bx
	push cx		
	push dx
 	
	xor ax,ax
 	cmp byte ptr[di], '-'					; ��������� ������� �� ���������������
	jne positiveNumber			
	inc di
	dec cl
	mov minus,1
 positiveNumber:							; ��������������� ������ � �����
	mov bl,byte ptr[di]
	inc di
	cmp bl,'0'
	jb errorLabel
	cmp bl,'9'
	ja errorLabel				
	sub bl,'0'
	mul ten						
	jc errorLabel
	add ax,bx
	jc errorLabel
	loop positiveNumber

	cmp minus,1
	jne cmpmax					
	cmp ax,32768
	ja errorLabel
	neg ax
	jmp finishCheckIntegerNumber
cmpmax:
	cmp ax,32767
	ja errorLabel
	jmp finishCheckIntegerNumber

errorLabel:
	call printValueOfElementsInFileErrorMessage
	call printEndline
	mov ah,4ch
    int 21h

finishCheckIntegerNumber:
	mov minus,0
	pop dx
	pop cx						
	pop bx
	ret
CheckIntegerNumber endp


convertMatrixInString proc							; ��������� �������������� ������� � ������
	push cx
	push di
	push si

	lea di,matrixAsString
	lea si,matrix
	mov cx,numOfRows
convertRow:											; �������������� ������ ������� � ������
	push cx

	mov cx,numOfColumns
convertElement:										; �������������� ������� �������� � ������
	mov ax,[si]
	add si,2
	call writeElementInString
	mov byte ptr[di],9								; ���������
	inc di
	loop convertElement

	pop cx
	mov byte ptr[di],13
	inc di
	mov byte ptr[di],10								; ����� ������ � �������
	inc di
	loop convertRow

theEndOfMatrix:
	sub di,3
	mov byte ptr[di],'$'
	mov len,di
	lea di,matrixAsString
	sub len,di										; ���������� ���� � ������ ��� ������ �������
	pop si
	pop di
	pop cx
	ret
convertMatrixInString endp


writeElementInString proc							; ��������� ������ �������� ������� � ����
	push ax
	push cx
	push dx
	xor cx,cx

	cmp ax,0										; �������� �� ���������������
	jge convertToChar			
	mov byte ptr[di],'-'							; ������� � ������ �����, ���� ����� �������������
	inc di
	neg ax

convertToChar:										; ��������������� ���� � ������� � ������ � ����
	inc cx
	xor dx,dx
	div ten
	add dx,'0'					
	push dx
	test ax,ax
	jnz convertToChar
	
putCharactersInString:								; ��������� �������� � ������
	pop dx
	mov [di],dl
	inc di						
	loop putCharactersInString

	pop dx
	pop cx
	pop ax
	ret 
writeElementInString endp


deleteRow proc										; �������� ������ �� �������
	push ax
	push cx
	push dx
	push di
	push si

	mov ax,l
	cmp ax,numOfRows								; �������� ���� ���� ������� ��������� ������
	je finishDeleteRow

	mov ax,numOfRows
	sub ax,l
	mul numOfColumns
	mov cx,ax										; ������������ ���������� ������� ���������

	mov ax,l
	dec ax
	mul numOfColumns
	shl ax,1
	lea si,matrix
	add si,ax
	shr ax,1
	add ax,numOfColumns
	shl ax,1
	lea di,matrix
	add di,ax										; ������������ � ������ �������� ���� ��������

moveElement1:										; ����� ��������� �� ����� �������
	mov ax,word ptr[di]
	mov word ptr[si],ax
	add di,2
	add si,2
	loop moveElement1	

finishDeleteRow:
	dec numOfRows									; ���������� ���������� ����� � �������
	pop si
	pop di
	pop dx
	pop cx
	pop ax
	ret
deleteRow endp


deleteColumn proc									; �������� ������� �� �������
	push ax
	push cx
	push dx
	push di
	push si

	mov ax,l
	cmp ax,numOfColumns									; �������� ���� ���� ������� ��������� �������
	je finishDeleteColumn

	mov ax,numOfColumns
	sub ax,1
	mul numOfRows
	sub ax,l
	inc ax
	mov cx,ax										; ������������ ���������� ������� ���������

	mov ax,l
	dec ax
	shl ax,1
	lea di,matrix
	add di,ax										; ������������ � ������ �������� ���� ��������
	mov si,di
	xor dx,dx

moveElement2:										; ����� ��������� �� ����� �������
	cmp dx,0
	jne isNotZero
	add di,2
	mov dx,numOfColumns
	dec dx
isNotZero:
	mov ax,word ptr[di]
	mov word ptr[si],ax
	add di,2
	add si,2
	dec dx
	loop moveElement2	

finishDeleteColumn:
	dec numOfColumns									; ���������� ���������� �������� � �������
	pop si
	pop di
	pop dx
	pop cx
	pop ax
	ret
deleteColumn endp


inputIntegerNumber proc								; ��������� ������ ����� �� �������
	push bx
	push cx											; ���������� �������� �� ��������� � ����
	push dx
	xor bx,bx

inputCharacter:										; �������� �� ������� �������
	mov ah,01h					
	inc cx
	int 21h
	cmp al,27
	je pressedEscape
	cmp al,8
	je pressedBackspace
	cmp al,13
	je theEndOfInput
	cmp al,32
	je theEndOfInput
	jmp addNewNumeral								; ������ ���� � ����������

addNewNumeral:										; ������� ������ � �����
	xor ah,ah
	xchg ax,bx
	cmp bl,'0'
	jb inputErrorLabel								; �������� �� ������������ �����
	cmp bl,'9'
	ja inputErrorLabel					
	sub bl,'0'							
	mul ten						
	jc inputErrorLabel
	add ax,bx
	jc inputErrorLabel
	xchg ax,bx
	jmp inputCharacter

pressedEscape:										; ��������� ������� �� ������� Escape
	call deleteLastSymbol
	loop pressedEscape
	xor bx,bx
	jmp inputCharacter

pressedBackspace:									; ��������� ������� �� ������� Backspace
	mov dl,' '
	call printSymbol
	call deleteLastSymbol
	dec cx
	cmp cx,0
	je inputCharacter
	xor dx,dx
	xchg ax,bx
	div ten
	xchg ax,bx
	dec cx
	jmp inputCharacter

inputErrorLabel:
	call printEndline
	call printInputErrorMessage						; ������������� ������ ����� � ���������
	xor bx,bx
	jmp inputCharacter

theEndOfInput:
	mov ax,bx
	pop dx
	pop cx											; ����������� �������� �� �����
	pop bx
	ret
inputIntegerNumber endp


deleteLastSymbol proc								; ��������� �������� ���������� ������� � �������
	push dx
	mov dl,8
	call printSymbol
	mov dl,32
	call printSymbol
	mov dl,8
	call printSymbol
	pop dx
	ret
deleteLastSymbol endp


printString proc									; ��������� ��������� ������
	push ax
	mov ah,09h
	int 21h	
	pop ax
	ret
printString endp


printSymbol proc									; ��������� ��������� ������
	push ax
	mov ah,02h
	int 21h	
	pop ax
	ret
printSymbol endp


printMatrix proc									; ��������� ��������� �������
	push dx
	lea dx,matrixAsString
	call printString
	call printEndline
	pop dx
	ret
printMatrix endp


printKMessage proc									; ��������� ��������� 'k: '
	push dx
	lea dx,kMessage
	call printString
	pop dx
	ret
printKMessage endp
	

printLMessage proc									; ��������� ��������� 'l: '
	push dx
	lea dx,lMessage
	call printString
	pop dx
	ret
printLMessage endp


printValueOfElementsInFileErrorMessage proc			; ��������� ��������� ������ �������� �������� ������� � �����
	push dx
	lea dx,valueOfElementsInFileErrorMessage
	call printString
	pop dx
	ret
printValueOfElementsInFileErrorMessage endp


printInputErrorMessage proc							; ��������� ��������� ������ �����
	push dx
	lea dx,inputErrorMessage
	call printString
	pop dx
	ret
printInputErrorMessage endp


printBorderErrorMessage proc						; ��������� ��������� ������ ������ �� ������� �������
	push dx
	lea dx,borderErrorMessage
	call printString
	pop dx
	ret
printBorderErrorMessage endp


printEndline proc									; ��������� �������� ������� �� ������ ������
	push dx
	lea dx,endline
	call printString
	pop dx
	ret
printEndline endp


START:
    mov ax,@data
	mov ds,ax
	mov es,ax
	
	call readMatrixFromFile
	call printMatrix
	call convertStringInMatrix

	call printKMessage
	call inputIntegerNumber
	mov k,ax
	call printLMessage
	call inputIntegerNumber
	mov l,ax
	cmp ax,0
	je borderError

	cmp k,0
	jne compareWith1
	cmp ax,numOfRows
	ja borderError
	call deleteRow
	jmp printAnswer
compareWith1:
	cmp k,1
	jne exit
	cmp ax,numOfColumns
	ja borderError
	call deleteColumn
	jmp printAnswer
	
borderError:
	call printBorderErrorMessage
	jmp exit
printAnswer:
	call convertMatrixInString
	call printMatrix
	call writeMatrixInFile
exit:
	mov ah,4ch
    int 21h
END START