;Author: Ido Senn
.286
IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
	PaletteBuffer db 300h dup (?)
	filename1 db 'title.bmp',0
	filename2 db 'credit.bmp' ,0
	filename3 db 'GMOV.bmp', 0
	menuFile1 db 'M1.bmp', 0
	menuFile2 db 'M2.bmp', 0
	menuFile3 db 'M3.bmp', 0
	menuFile4 db 'M4.bmp', 0
	filehandle dw (?)
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error', 13, 10,'$'
	
	randomNumber db (?) ;The random number that the computer will generate.
	randomSeed dw (?) ;A varuable for the random function. Put the milliseconds here at the begining.
	randomCounter db 0 ;Counts how many time a random number was generated. if it was more then 4, the milliseconds will be added to the seed.
	Car1Xval db 3 ;0-3
	Car1Yval db 0   ;0-8
	Car2Xval db 2 ;0-3
	Car2Yval db 2   ;0-8
	Car3Xval db 1 ;0-3
	Car3Yval db 4   ;0-8
	BACKCOLOR db 07h
	CARCOLOR db 20h
	ENEMYCOLOR db 28h
	LINECOLOR db 0Eh
	LOCATIONSX db 17, 67, 117, 167 ;0, 1, 2, 3
	LOCATIONSY db 2, 22, 42, 62, 82, 102, 122, 142, 162, 182 ;
	playerLocation db 0 ;0-3
	GameSpeed db 8 ;The higher the number, the slower the game!
	score dw 0
	actualNum db 30h, 30h, 30h, 30h, 30h, '$'
	
	speedText db "Speed: ", 30h, '$'
	scoreText db "Score: ", '$'
	
	beepTime db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	frequencys dw 3619, 3619, 3619, 3619, 3619, 3619, 4304, 4304, 4304, 3619, 3619, 3619, 3619, 4304, 2873, 3224, 2873, 3619, 3619, 3619, 3619, 3619, 3619, 4304, 2873, 3224, 3619, 3224, 3224, 3224, 3224, 3224, 3224, 3224, 3834, 2873, 2873, 3224, 3619, 3834, 4304, 4304, 2873, 2415, 2559, 4304, 4304, 2873, 2415, 2559, 2415, 2152
	delayTime db 1, 1, 2, 1, 1, 2, 5, 1, 1, 2, 1, 1, 2, 5, 2, 2, 6, 1, 1, 2, 1, 1, 2, 5, 5, 5, 5, 10, 1, 1, 2, 1, 1, 2, 2, 2, 5, 5, 5, 5, 5, 2, 2, 2, 8, 5, 2, 2, 2, 5, 2, 5
	NUMBER_OF_NOTES dw 52
	keyPressedWhileInMusicLoop dw (?)
	
	menuPos db 0
	
	
CODESEG

	proc MegaMan
		push ax
		push bx
		push cx
		push dx
		push 1
		call WaitTicks
		
		xor di, di ;+2 each run
		xor si, si ;+1 each run
		xor ax, ax
		MegaManLoop:
			xor ax, ax
			mov al, [beepTime + si]
			push ax
			mov ax, [frequencys + di]
			push ax
			call PlayBeep
			xor ax, ax
			mov al, [delayTime + si]
			push ax
			call WaitTicks
			inc si
			add di, 2
			;reset pointers
			cmp si, [NUMBER_OF_NOTES]
			jb NoNeedToResetNotePointer
			xor di, di
			xor si, si
			NoNeedToResetNotePointer:
			;chek if a button was pressed
			mov ah, 1
			int 16h
			jz NoDataWhilePlaying
			jmp stopMusic
			NoDataWhilePlaying:
			jmp MegaManLoop
		stopMusic:
		mov [keyPressedWhileInMusicLoop], ax
		call ClearKeyboardBuffer
		pop dx
		pop cx
		pop bx
		pop ax
		ret 
	endp MegaMan
	
	proc OpenFile
	; Open file
		push bp
		mov bp, sp
		offsetFilename equ [bp+4]
		mov ah, 3Dh
		xor al, al
		mov dx, offsetFilename
		int 21h
		jc openerror
		mov [filehandle], ax
		pop bp
		ret 2
		openerror:
		mov dx, offset ErrorMsg
		mov ah, 9h
		int 21h
		pop bp
		ret 2
	endp OpenFile
	
	
	proc ReadHeader
	; Read BMP file header, 54 bytes
		mov ah,3fh
		mov bx, [filehandle]
		mov cx,54
		mov dx,offset Header
		int 21h
		ret
	endp ReadHeader
	
	proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
		mov ah,3fh
		mov cx,400h
		mov dx,offset Palette
		int 21h
		ret
	endp ReadPalette
	
	proc CopyPal
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
		mov si,offset Palette
		mov cx,256
		mov dx,3C8h
		mov al,0
		; Copy starting color to port 3C8h
		out dx,al
		; Copy palette itself to port 3C9h
		inc dx
			PalLoop:
				; Note: Colors in a BMP file are saved as BGR values rather than RGB.
				mov al,[si+2] ; Get red value.
				shr al,2 ; Max. is 255, but video palette maximal
				; value is 63. Therefore dividing by 4.
				out dx,al ; Send it.
				mov al,[si+1] ; Get green value.
				shr al,2
				out dx,al ; Send it.
				mov al,[si] ; Get blue value.
				shr al,2
				out dx,al ; Send it.
				add si,4 ; Point to next color.
				; (There is a null chr. after every color.)
			loop PalLoop
		ret
	endp CopyPal
	
	proc CopyBitmap
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
		mov ax, 0A000h
		mov es, ax
		mov cx,200
			PrintBMPLoop:
				push cx
				; di = cx*320, point to the correct screen line
				mov di,cx
				shl cx,6
				shl di,8
				add di,cx
				; Read one line
				mov ah,3fh
				mov cx,320
				mov dx,offset ScrLine
				int 21h
				; Copy one line into video memory
				cld ; Clear direction flag, for movsb
				mov cx,320
				mov si,offset ScrLine
				rep movsb ; Copy line to the screen
				;rep movsb is same as the following code:
				;mov es:di, ds:si
				;inc si
				;inc di
				;dec cx
				;loop until cx=0
				pop cx
			loop PrintBMPLoop
		ret
	endp CopyBitmap
	
	proc CloseFile
		mov ah,3Eh
		mov bx, [filehandle]
		int 21h
		ret
	endp CloseFile
	
	proc clear_screen
		push bp
		mov ax, 0A000h
		mov es, ax
		mov ax, 0
		mov cx, 32000
		mov di, 0
		cld
		rep stosw	
		pop bp
		ret
	endp clear_screen
	
	proc ProcessBMPfile
	;Print a BMP picture on the screen. 
		push bp
		mov bp, sp
		filenameOffset equ [bp+4]
		call clear_screen
		push filenameOffset
		call OpenFile
		call ReadHeader
		call ReadPalette
		call CopyPal
		call CopyBitmap
		call CloseFile
		pop bp
		ret 2
	endp ProcessBMPfile
	
	proc ProcessBMPfileNoClear
	;Print a BMP picture on the screen without clearing the screen. 
		push bp
		mov bp, sp
		filenameOffset equ [bp+4]
		push filenameOffset
		call OpenFile
		call ReadHeader
		call ReadPalette
		call CopyPal
		call CopyBitmap
		call CloseFile
		pop bp
		ret 2
	endp ProcessBMPfileNoClear
	
	proc GetActualNum
		push bp
		mov bp, sp
		numToWrite equ [bp + 4] ;NOT LOCATION, number (word)
		push dx
		push cx
		push bx
		push ax
		
		xor dx, dx
		mov bx, numToWrite
		
		cmp bx, 10000
		jb after10K
		mov cx, 1
		before10K:
		sub bx, 10000
		inc dl
		cmp bx, 10000
		jae before10K
		
		add dl, '0'
		mov [actualNum+0], dl
		xor dx, dx
		
		after10K:
		;;;;;;
		cmp bx, 1000
		jae while1K
		pre1K:
		cmp cx, 1
		jne after1K
		mov dl, '0'
		mov [actualNum+1], dl
		jmp after1K
		while1K:
		mov cx, 1
		sub bx, 1000
		inc dl
		cmp bx, 1000
		ja while1K
		
		add dl, '0'
		mov [actualNum+1], dl
		xor dx, dx
		
		after1K:
		;;;;;;;;;
		
		
		cmp bx, 100
		jae while100
		pre100:
		cmp cx, 1
		jne after100
		mov dl, '0'
		mov [actualNum+2], dl
		jmp after100
		while100:
		mov cx, 1
		sub bx, 100
		inc dl
		cmp bx, 100
		jae while100
		
		add dl, '0'
		mov [actualNum+2], dl
		
		after100:
		xor dx, dx
		;;;;;;;;;;
		
		
		cmp bx, 10
		jae while10
		pre10:
		cmp cx, 1
		jne after10
		mov dl, '0'
		mov [actualNum+3], dl
		jmp after10
		while10:
		mov cx, 1
		sub bx, 10
		inc dl
		cmp bx, 10
		jae while10
		
		add dl, '0'
		mov [actualNum+3], dl
		xor dx, dx
		
		after10:
		mov dx, bx
		add dx, '0'
		mov [actualNum+4], dl
		
		pop ax
		pop bx 
		pop cx
		pop dx
		pop bp 
		ret 2
	endp GetActualNum
	
	proc PrintTextMatrix
		;A procedure that prints text in a specific place on the screen
		push bp
		mov bp, sp
		push ax
		push bx
		push cx
		push dx
		Collum equ [bp+8]
		Row equ [bp+6]
		TextOffset equ [bp+4]
		mov  dl, Collum   ;Column ---till 39
		mov  dh, Row   ;Row ---till 24
		mov  bh, 0    ;Display page
		mov  ah, 02h  ;SetCursorPosition
		int  10h
		mov ah, 9h
		mov dx, TextOffset
		int 21h
		pop dx
		pop cx
		pop bx
		pop ax
		pop bp
		ret 6
	endp PrintTextMatrix
	
	proc ClearKeyboardBuffer
		push ax
		push es
		mov	ax, 0000h
		mov	es, ax
		mov bx, 041eh
		mov	[es:041ah], bx
		mov	[es:041ch], bx				; Clears keyboard buffer
		pop	es
		pop	ax
		ret
	endp ClearKeyboardBuffer

	proc Random 
	;Recives the number to random (generates a number between 0 and the number) and generates a random number in that area. the number can be 1, 3, 7, 15, 31, 63, 127, 255.
		push bp
		mov bp, sp
		push ax
		push bx
		push cx
		push dx
		next equ [bp+4]
		;========================================================================
		;Check if the seed was used too many tines and add miiliseconds if it did
		;========================================================================
		add [randomCounter], 1
		cmp [randomCounter], 4
		jnae DontResetRandom
		mov al, 0
		mov [randomCounter], 0
		mov ax, 40h
		mov es, ax
		mov ax, [es:6Ch]
		xor [randomSeed], ax
		add [randomSeed], 13
		DontResetRandom:
		;====================================
		;xor and shift to get a random number
		;====================================
		mov ax, [randomSeed]
		mov bx, [randomSeed]
		rol bx, 13
		xor ax, bx
		mov bx, 5
		mul bx
		xor ax, bx
		mov [randomSeed], ax
		;================================================================================================
		;set var randomNumber as a number in the range 0-(next-1). Same output as rnd.Next(0,next) in C#.
		;================================================================================================
		and al, next 
		mov [randomNumber], al
		pop dx
		pop cx
		pop bx
		pop ax
		pop bp
		ret 2
	endp Random
	
	proc WaitTicks
	;Wait [TicksToWait] Ticks. Tick is 55 miliseconds.
		push bp
		mov bp, sp
		TicksToWait equ [bp+4]
		push ax
		push bx
		push cx
		push dx
		mov cx, TicksToWait
		WaitTick:
			mov ax, 40h
			mov es, ax
			mov bl, [es:6Ch]
			CheckForChange:
				cmp bl, [es:6Ch]
				je CheckForChange
			loop WaitTick
		pop dx
		pop cx
		pop bx
		pop ax
		pop bp
		ret 2
	endp WaitTicks
	
	proc PlayBeep
		push bp
		mov bp, sp
		timeToBeep equ [bp+6]
		frequency equ [bp+4]
		push ax
		push bx
		push cx
		push dx
		; open speaker
		in al, 61h
		or al, 00000011b
		out 61h, al
		; send control word to change frequency
		mov al, 0B6h
		out 43h, al
		; play frequency 131Hz
		mov ax, frequency
		out 42h, al ; Sending lower byte
		mov al, ah
		out 42h, al ; Sending upper byte
		;wait
		mov dx, timeToBeep
		push dx
		call WaitTicks
		; close the speaker
		in al, 61h
		and al, 11111100b
		out 61h, al
		pop dx
		pop cx
		pop bx
		pop ax
		pop bp
		ret 4
	endp PlayBeep

	proc PlayBoom
		push ax
		push bx
		push cx
		push dx
		mov dx, 0
		mov cx, 0FFFFh
			BoomLoop:
				; open speaker
				in al, 61h
				or al, 00000011b
				out 61h, al
				; send control word to change frequency
				mov al, 0B6h
				out 43h, al
				; play frequency 131Hz
				mov ax, dx
				out 42h, al ; Sending lower byte
				mov al, ah
				out 42h, al ; Sending upper byte
				; close the speaker
				in al, 61h
				and al, 11111100b
				out 61h, al
				;increce frec
				inc dx
			loop BoomLoop
		; close the speaker
		in al, 61h
		and al, 11111100b
		out 61h, al
		pop dx
		pop cx
		pop bx
		pop ax
		ret
	endp PlayBoom
	
	proc PrintPixel ;in claim: x (dw),y (dw),color(db)
		push bp
		mov bp, sp
		push ax
		push bx
		push cx
		push dx
		X equ [word ptr bp+8]
		Y equ [word ptr bp+6]
		color equ [bp+4]
		; Print pixel
		mov bh,0h ;book says bl needs to be 0. maybe they ment bh?
		mov cx,	X ;cx the X cords
		mov dx, Y ;dx the Y cords
		mov al,	color ;al contains the color
		mov ah,	0ch ;bios  inturrupt
		int 10h
		pop dx
		pop cx
		pop bx
		pop ax
		pop bp
		ret 6
	endp PrintPixel
	
	proc PrintVerticalLine
		push bp
		mov bp, sp
		push ax
		push bx
		push cx
		push dx
		LineLength equ [word ptr bp+10]
		X equ [word ptr bp+8]
		Y equ [word ptr bp+6]
		Color equ [bp+4]
		mov cx, LineLength
		DotPrint:
			push X
			push Y
			push Color
			call PrintPixel
			inc Y
			loop DotPrint
		pop dx
		pop cx
		pop bx
		pop ax
		pop bp
		ret 8
	endp PrintVerticalLine
	
	proc PrintMalben
		;Print a malben. In claim: HorizontalLength, VerticalLength, X and Y of top left corner, color.
		push bp
		mov bp, sp
		push ax
		push bx
		push cx
		push dx
		HorizontalLength equ [word ptr bp+12]
		VerticalLength equ [word ptr bp+10]
		X equ [word ptr bp+8]
		Y equ [word ptr bp+6]
		Color equ [bp+4]
		mov cx, HorizontalLength
		LinePrint:
			push VerticalLength
			push X
			push Y
			push Color
			call PrintVerticalLine
			inc X
			loop LinePrint
		pop dx
		pop cx
		pop bx
		pop ax
		pop bp
		ret 10
	endp PrintMalben
	
	proc SwitchToGraphics
	; Switch to graphics mode
		push ax
		mov ax, 13h
		int 10h
		pop ax
		ret
	endp SwitchToGraphics
	
	proc ReturnToText
	; Return to text mode
		push ax
		mov ax, 2
		int 10h
		pop ax
		ret
	endp ReturnToText
	
	proc WaitForInput
	;Wait a key press
		push ax
		mov ah, 00h
		int 16h
		pop ax
		ret
	endp WaitForInput
	
	proc DrawBorad
		push ax
		;draw black on the bmp
		push 118
		push 200
		push 202
		push 0
		push 0
		call PrintMalben
		;Draw Back
		push 202 ;width
		push 200 ;hight
		push 0 ;X
		push 0 ;y
		push 1 ;color
		call PrintMalben
		push 200 ;width
		push 200 ;hight
		push 0 ;X
		push 0 ;Y
		xor ax, ax
		mov al, [BACKCOLOR]
		push ax ;Color
		call PrintMalben
		;Draw lines
		;1
		push 2
		push 200
		push 100
		push 0
		xor ax, ax
		mov al, [LINECOLOR]
		push ax
		call PrintMalben
		;2
		push 2
		push 200
		push 50
		push 0
		xor ax, ax
		mov al, [LINECOLOR]
		push ax
		call PrintMalben
		;3
		push 2
		push 200
		push 150
		push 0
		xor ax, ax
		mov al, [LINECOLOR]
		push ax
		call PrintMalben
		;delete parts if teh stripes
		xor ax, ax
		mov al, [BACKCOLOR]
		mov cx, 10
		xor di, di
		DeleteLine:
			push 200
			push 4
			push 0
			push di
			push ax
			call PrintMalben
			add di, 20
			loop DeleteLine
		pop ax
		ret
	endp DrawBorad
	
	proc DeleteCar
		push bp
		mov bp, sp
		push ax
		yVal equ [bp+6]
		xVal equ [bp+4]
		push 26 ;width
		push 36 ;hight
		push xVal ;X
		push yVal ;y
		xor ax, ax
		mov al, [BACKCOLOR]
		push ax ;color
		call PrintMalben
		pop ax
		pop bp
		ret 4
	endp DeleteCar
	
	proc MovePlayerCar
		push bp
		mov bp, sp
		ascii equ [bp+6]
		scanCode equ [bp+4]
		push ax
		push bx
		;chack if left or right arrow pressed
		xor ax, ax
		mov al, 04Dh
		cmp ascii, ax ;Right arrow
		jne NotRightArrow
		cmp [playerLocation], 3
		je NotRightArrow ;Cannot be more then 3.
		inc [playerLocation]
		NotRightArrow:
		xor ax, ax
		mov al, 04Bh
		cmp ascii, ax ;Left arrow
		jne NotLeftArrow
		cmp [playerLocation], 0
		je NotLeftArrow ;Cannot be less then 0.
		dec [playerLocation]
		NotLeftArrow:
		pop bx
		pop ax
		pop bp
		ret 4
	endp MovePlayerCar
	
	proc DrawPlayerCar
		push ax
		push bx
		push cx
		push dx
		push 16
		push 36
		xor bx, bx
		xor ax, ax
		mov bl, [playerLocation]
		mov al, [LOCATIONSX + bx]
		push ax
		push 160
		xor ax, ax
		mov al, [CARCOLOR]
		push ax
		call PrintMalben
		pop dx
		pop cx
		pop bx
		pop ax
		ret
	endp DrawPlayerCar
	
	proc DeleteEnemyCars
		push ax
		push bx
		push cx
		push dx
		;Delete Car 1
		push 16
		push 36
		xor bx, bx
		xor ax, ax
		mov bl, [Car1Xval]
		mov al, [LOCATIONSX + bx]
		push ax ;X
		xor bx, bx
		xor ax, ax
		mov bl, [Car1Yval]
		mov al, [LOCATIONSY + bx]
		push ax ;Y
		mov al, [BACKCOLOR]
		push ax
		call PrintMalben
		;Delete Car 2
		push 16
		push 36
		xor bx, bx
		xor ax, ax
		mov bl, [Car2Xval]
		mov al, [LOCATIONSX + bx]
		push ax ;X
		xor bx, bx
		xor ax, ax
		mov bl, [Car2Yval]
		mov al, [LOCATIONSY + bx]
		push ax ;Y
		mov al, [BACKCOLOR]
		push ax
		call PrintMalben
		;Delete Car 3
		push 16
		push 36
		xor bx, bx
		xor ax, ax
		mov bl, [Car3Xval]
		mov al, [LOCATIONSX + bx]
		push ax ;X
		xor bx, bx
		xor ax, ax
		mov bl, [Car3Yval]
		mov al, [LOCATIONSY + bx]
		push ax ;Y
		mov al, [BACKCOLOR]
		push ax
		call PrintMalben
		pop dx
		pop cx
		pop bx
		pop ax
		ret
	endp DeleteEnemyCars
	
	proc UpdateEnemyCarLocation
		push ax
		push bx
		push cx
		push dx
		;increce enemy cars y location
		inc [Car1Yval]
		inc [Car2Yval]
		inc [Car3Yval]
		;Chack if cars y value is 10 if it is, change it to 0 and set a new x value.
		;car1
		cmp [Car1Yval], 9
		jb NoNeedToResetCar1
		mov al, 0
		mov [Car1Yval], al
		push 3
		call Random
		mov al, [randomNumber]
		mov [Car1Xval], al
		inc [score]
		NoNeedToResetCar1:
		;car2
		cmp [Car2Yval], 9
		jb NoNeedToResetCar2
		mov al, 0
		mov [Car2Yval], al
		push 3
		call Random
		mov al, [randomNumber]
		mov [Car2Xval], al
		inc [score]
		NoNeedToResetCar2:
		;car3
		cmp [Car3Yval], 9
		jb NoNeedToResetCar3
		mov al, 0
		mov [Car3Yval], al
		push 3
		call Random
		mov al, [randomNumber]
		mov [Car3Xval], al
		inc [score]
		NoNeedToResetCar3:
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp UpdateEnemyCarLocation
	
	proc DrawEnemyCars
		push ax
		push bx
		push cx
		push dx
		;Car1
		push 16
		push 36
		xor bx, bx
		xor ax, ax
		mov bl, [Car1Xval]
		mov al, [LOCATIONSX + bx]
		push ax
		xor bx, bx
		xor ax, ax
		mov bl, [Car1Yval]
		mov al, [LOCATIONSY + bx]
		push ax
		xor ax, ax
		mov al, [ENEMYCOLOR]
		push ax
		call PrintMalben
		;Car2
		push 16
		push 36
		xor bx, bx
		xor ax, ax
		mov bl, [Car2Xval]
		mov al, [LOCATIONSX + bx]
		push ax
		xor bx, bx
		xor ax, ax
		mov bl, [Car2Yval]
		mov al, [LOCATIONSY + bx]
		push ax
		xor ax, ax
		mov al, [ENEMYCOLOR]
		push ax
		call PrintMalben
		;Car3
		push 16
		push 36
		xor bx, bx
		xor ax, ax
		mov bl, [Car3Xval]
		mov al, [LOCATIONSX + bx]
		push ax
		xor bx, bx
		xor ax, ax
		mov bl, [Car3Yval]
		mov al, [LOCATIONSY + bx]
		push ax
		xor ax, ax
		mov al, [ENEMYCOLOR]
		push ax
		call PrintMalben
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp DrawEnemyCars
	
	proc UpdateSpeed
		push ax
		push bx
		push cx
		push dx
		mov bx, [score]
		xor ax, ax
		mov al, [GameSpeed]
		mov ah, 9
		sub ah, al
		mov al, ah
		xor ah, ah
		;ax now contains the speed 1-8 when 1 is the slowest and 8 is the fastest
		cmp ax, 7
		je Fastest
		mov cx, 50
		mul cx
		cmp ax, bx
		ja Fastest
		;play speed up sound
		push 1
		push 8000
		call PlayBeep
		push 1
		push 4000
		call PlayBeep
		push 1
		push 1000
		call PlayBeep
		;increce speed
		dec [GameSpeed]
		Fastest:
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp UpdateSpeed
	
	proc UpdateInfo
		push ax
		push bx
		push cx
		push dx
		;print speed
		mov cl, [GameSpeed]
		mov dl, 9
		sub dl, cl
		add dl, 30h
		mov [speedText + 7], dl
		push 26
		push 1
		push offset speedText
		call PrintTextMatrix
		;print score
		push [score]
		call GetActualNum
		push 26
		push 3
		push offset scoreText
		call PrintTextMatrix
		mov ah, 9
		mov dx, offset actualNum
		int 21h
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp UpdateInfo
	
	proc TitleScreen
		push ax
		push bx
		push cx
		push dx
		;print credits
		push offset filename2
		call ProcessBMPfile
		call PlayBoom
		push 12
		call WaitTicks
		;Print title and play music
		push offset filename1
		call ProcessBMPfile
		call ClearKeyboardBuffer
		call MegaMan
		call MainMenu
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp TitleScreen
	
		;WORD Buffer Segment
		;WORD Buffer  Offset
		;DF = Direction of saving
	proc SavePalette
		push bp
		mov bp, sp

		push es
		push di
		push ax
		push dx
		push cx

		mov es, [bp+06h]
		mov di, [bp+04h]

		xor al, al
		mov dx, 3c7h
		out dx, al      ;Read from index 0

		inc dx
		inc dx
		mov cx, 300h        ;3x256 reads
		rep insb    

		pop cx
		pop dx
		pop ax
		pop di
		pop es

		pop bp
		ret 04h
	endp SavePalette


		;WORD Buffer Segment
		;WORD Buffer  Offset
		;DF = Direction of loading
	proc RestorePalette
		push bp
		mov bp, sp

		push ds
		push si
		push ax
		push dx
		push cx

		mov ds, [bp+06h]
		mov si, [bp+04h]

		xor al, al
		mov dx, 3c8h
		out dx, al      ;Write from index 0

		inc dx
		mov cx, 300h        ;3x256 writes
		rep outsb       

		pop cx
		pop dx
		pop ax
		pop si
		pop ds

		pop bp
		ret 04h
	endp RestorePalette
	
	proc ResetGameValues
		push ax
		push bx
		push cx
		push dx
		; Car1Xval db 3 ;0-3
		; Car1Yval db 0   ;0-8
		; Car2Xval db 2 ;0-3
		; Car2Yval db 2   ;0-8
		; Car3Xval db 1 ;0-3
		; Car3Yval db 4   ;0-8
		; GameSpeed db 8 ;The higher the number, the slower the game!
		; score dw 0
		mov al, 3
		mov [Car1Xval], al
		mov al, 0
		mov [Car1Yval], al
		mov al, 2
		mov [Car2Xval], al
		mov al, 2
		mov [Car2Yval], al
		mov al, 1
		mov [Car3Xval], al
		mov al, 4
		mov [Car3Yval], al
		mov al, 8
		mov [GameSpeed], al
		xor ax, ax
		mov [score], ax
		mov [playerLocation], al
		mov al, 1
		mov [menuPos], al
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp ResetGameValues
	
	proc MainMenu
		push ax
		push bx
		push cx
		push dx
		call ClearKeyboardBuffer
		ButtonPressLoop:
			xor ax, ax
			mov al, [menuPos]
			cmp ax, 0
			jne Not0
			;1
			push offset menuFile1
			call ProcessBMPfileNoClear
			jmp GetButtomInput
			Not0:
			cmp ax, 1
			jne Not1
			;1
			push offset menuFile2
			call ProcessBMPfileNoClear
			jmp GetButtomInput
			Not1:
			cmp ax, 2
			jne Not2
			;2
			push offset menuFile3
			call ProcessBMPfileNoClear
			jmp GetButtomInput
			Not2:
			;3
			push offset menuFile4
			call ProcessBMPfileNoClear
			GetButtomInput:
			mov ah, 1
			int 16h
			jz GetButtomInput
			call ClearKeyboardBuffer
			cmp ah, 50h
			je DownArrow
			cmp ah, 48h
			je UpArrow
			;Action Button
			mov al, [menuPos]
			cmp al, 0
			je ExitMenu
			cmp al, 3
			jne DoNotExitGame
			jmp exit
			DoNotExitGame:
			cmp al, 2
			jne DoNotShowCredits
			call Credits
			jmp ButtonPressLoop
			DoNotShowCredits:
			jmp ExitMenu
			;Move
			DownArrow:
			mov al, [menuPos]
			cmp al, 3
			je ButtonPressLoop
			inc al
			mov [menuPos], al
			jmp ButtonPressLoop
			UpArrow:
			mov al, [menuPos]
			cmp al, 0
			je ButtonPressLoop
			dec al
			mov [menuPos], al
			jmp ButtonPressLoop
		ExitMenu:
		call clear_screen
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp MainMenu
	
	proc Credits
		push ax
		push bx
		push cx
		push dx
		push offset filename2
		call ProcessBMPfile
		call ClearKeyboardBuffer
		call MegaMan
		pop dx 
		pop cx
		pop bx
		pop ax
		ret
	endp Credits
	
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	;switch to graphic mode
	call SwitchToGraphics
	;save standard color pallet (changes when printing bmp)
	push ds
	push offset PaletteBuffer
	call SavePalette
	;title screen
	call TitleScreen
	;restore standard color pallet
	push ds
	push offset PaletteBuffer
	call RestorePalette
	call DrawBorad
	GameLoop:
		;update game sprrd
		call UpdateSpeed 
		;delete enemy cars
		call DeleteEnemyCars
		;increce enemy cars y value by 1
		;check if a car's y value is 10 and if it is, change it to 0 and set a new x value.
		call UpdateEnemyCarLocation 
		;update game info
		call UpdateInfo
		;delete car on old place
		push 160
		xor bx, bx
		mov bl, [playerLocation]
		xor cx, cx
		mov cl,  [LOCATIONSX + bx]
		push cx
		call DeleteCar
		;check if input and change x location if needed
		;check for key press
		mov ah, 1
		int 16h
		jz NoData
		xor bx, bx
		mov bl, ah
		push bx ;ascii
		xor cx, cx
		mov cl, al
		push cx ;scan code
		call MovePlayerCar
		NoData:
		;draw player car
		call DrawPlayerCar
		;draw enemy cars
		call DrawEnemyCars
		;clear buffer so the game won't count button presses during animation
		call ClearKeyboardBuffer
		;Did the user lose? (y location 7 and same x)
		;car1
		xor ax, ax
		xor bx, bx
		mov bl, [Car1Yval]
		cmp bl, 7
		jnae Car1IsSafe
		mov bl, [Car1Xval]
		mov bh, [playerLocation]
		cmp bl, bh
		jne Car1IsSafe
		call PlayBoom
		jmp GameOver
		Car1IsSafe:
		;car2
		xor ax, ax
		xor bx, bx
		mov bl, [Car2Yval]
		cmp bl, 7
		jnae Car2IsSafe
		mov bl, [Car2Xval]
		mov bh, [playerLocation]
		cmp bl, bh
		jne Car2IsSafe
		call PlayBoom
		jmp GameOver
		Car2IsSafe:
		;car3
		xor ax, ax
		xor bx, bx
		mov bl, [Car3Yval]
		cmp bl, 7
		jnae Car3IsSafe
		mov bl, [Car3Xval]
		mov bh, [playerLocation]
		cmp bl, bh
		jne Car3IsSafe
		call PlayBoom
		jmp GameOver
		Car3IsSafe:
		;Wait
		xor ax, ax
		mov al, [GameSpeed]
		push ax
		call WaitTicks
		jmp GameLoop
	GameOver:
	;Print Game Over Screen
	push offset filename3
	call ProcessBMPfile
	call WaitForInput
	call ResetGameValues
	jmp start
exit:
	call ReturnToText
	mov ax, 4c00h
	int 21h
END start


