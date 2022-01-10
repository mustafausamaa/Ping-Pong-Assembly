;keys and read and print macros
;Get a key press
GetKeyPressed MACRO
    MOV AH, 01H
    INT 16H
ENDM GetKeyPressed

  ;Wait for key press
WaitforKeyPress MACRO
    MOV AH, 00H
    INT 16H
ENDM WaitforKeyPress

;Get key press and flush it
GetKeyPressAnddisposes  MACRO
    LOCAL nokeypressed
    GetKeyPressed
    JZ nokeypressed
    WaitforKeyPress
    nokeypressed:
ENDM GetKeyPressAnddisposes

;Empty the key queue
EmptyKeyQueue MACRO
    LOCAL Back, Return
    Back:
    GetKeyPressed
    JZ Return
    WaitforKeyPress
    JMP Back
    Return:
ENDM EmptyKeyQueue

;Display one character
PrintChar MACRO char
    MOV AH, 02H
    MOV DL, char
    INT 21H
ENDM PrintChar

;Read one character without echo in AL
ReadChar MACRO char
    MOV AH, 07H
    INT 21H
    MOV char, AL
ENDM ReadChar

;Display string
PrintString MACRO string
    MOV AH, 09H
    MOV DX, OFFSET string
    INT 21H
ENDM PrintString

;Read string from user
ReadString MACRO string
    MOV AH, 0AH
    MOV DX, OFFSET string
    INT 21H
ENDM ReadString

;PORT INITIALIZATION
InitiatSerialPort MACRO
    ;Set divisor latch access bit
    MOV DX, 3fbh    ;Line control register
    MOV AL, 10000000b
    OUT DX, AL
 
    ;Set the least significant byte of the Baud rate divisor latch register
    MOV DX, 3f8h
    MOV AL, 0CH
    OUT DX, AL

    ;Set the most significant byte of the Baud rate divisor latch register
    MOV DX, 3f9h
    MOV AL, 0
    OUT DX, AL

    ;Set serial port configurations
    MOV DX, 3fbh    ;Line Control Register
    MOV AL, 00011011B
    ;0:     Access to receiver and transmitter buffers
    ;0:     Set break disabled
    ;011:   Even parity
    ;0:     One stop bit
    ;11:    8-bit word length
    OUT DX, AL
ENDM InitiatSerialPort
  
SendChar MACRO char
    LOCAL Send

    MOV DX, 3FDH    ;Line Status Register
Send:  IN AL, DX
    AND AL, 00100000B       ;Check transmitter holding register status: 1 ready, 0 otherwise
    JZ Send                 ;Transmitter is not ready
    MOV DX, 3f8h
    MOV AL, char
    OUT DX, AL
ENDM SendChar

;Receive a character from the serial port into AL
ReceiveChar MACRO
    LOCAL Return
    MOV AL, 0
    MOV DX, 3fdh   ;Line Status Register
    Return:    IN AL, DX
    AND AL, 1B       ;Check for data ready
    JZ Return        ;No character received
    MOV DX, 3f8h     ;Receive data register
    IN AL, DX

ENDM ReceiveChar
  
  ;__DrawBall macro_

DrawBall macro xball,yball,ballsize ; drawingball
local Draw
mov cx,xball        ;starts drawing the lines on x. 
mov dx,yball
Draw:
mov al, 0fh       ;white colour
mov ah, 0ch
int 10h           ;draw the start point
inc cx            ;moves to next point.
mov ax,cx
sub ax,xball                
cmp ax, ballsize     ;compare the next point with the ball size 
jnz Draw
mov cx,xball      ;reset the x point of the ball  
inc dx            ;increase the y value
mov ax,dx
sub ax,yball
cmp ax,ballsize  ;compare the y value with the ball size
jnz Draw  
ENDM
;__DrawPaddels macro__
DrawPaddels macro paddelxstart1,paddelxend1,paddelxstart2,paddelxend2,paddelystart1,paddelyend1,paddelystart2,paddelyend2
local drawpaddel1
local drawpaddel2
 
mov al, 0fh       ;white colour
mov ah, 0ch
mov cx, paddelxstart1        ;starts drawing the lines on x. 
mov bx,paddelystart1
drawpaddel1:
mov dx, bx        ;putting point at the bottom.
int 10h
inc cx                ;moves to next point.
cmp cx, paddelxend1         ;yet checks if it's the end.
jnz drawpaddel1
mov cx,paddelxstart1
inc bx
cmp bx,paddelyend1
jnz drawpaddel1

mov cx, paddelxstart2        ;starts drawing the lines on x. 
mov bx,paddelystart2
drawpaddel2:
mov dx, bx        ;putting point at the bottom.
int 10h
inc cx                ;moves to next point.
cmp cx, paddelxend2         ;yet checks if it's the end.
jnz drawpaddel2
mov cx,paddelxstart2
inc bx
cmp bx,paddelyend2
jnz drawpaddel2

endm
DrawLine MACRO StartX, StartY, VerticalLength, HorizontalWidth, Char, Color, PageNum
    LOCAL Back
    
    MOV SI, 0
    
    Back:
        MOV CX, SI
        ADD CL, StartY
        SetCursorPos StartX, CL, PageNum
         MOV AH, 09H         ;Display
        MOV BH, PageNum     ;Page 0
        MOV AL, Char        ;Character to display
        MOV BL, Color       ;Color(back:fore)
        MOV CX, Cnt         ;Number of times
        INT 10H
        
        INC SI
        CMP SI, VerticalLength
        JB Back
ENDM DrawLine
;___________________Draw Air hockey goals macro_____________________

DrawAirHockeyGoals macro xgoalstart1,xgoalend1,xgoalstart2,xgoalend2,ygoalstart,ygoalend  ; drawing the goals 
local drawgoal1
local drawgoal2
mov al, 0fh       ;white colour
mov ah, 0ch
mov cx, xgoalstart1      ;starts drawing the lines on x.  
drawGoal1:
mov dx, ygoalstart          ;putting point at the bottom.
int 10h
mov dx, ygoalend      ;putting point in the top.
int 10h
inc cx                ;moves to next point.
cmp cx, xgoalend1         ;yet checks if it's the end.
jnz drawgoal1

mov cx, xgoalstart2
drawGoal2:
mov dx, ygoalstart          ;putting point at the bottom.
int 10h
mov dx, ygoalend      ;putting point in the top.
int 10h
inc cx                ;moves to next point.
cmp cx, xgoalend2         ;yet checks if it's the end.
jnz drawGoal2
Endm
;____________Moving The Ball Macro________________

Ballmovement macro xball,ballspeedx1,yball,ballspeedy1,ballsize,xstart,xend,ystart,yend,WINDOW_BOUNDS
 local NEG_speedX
 local NEG_speedy
 local endf
		
		MOV AX,ballspeedx1    
		ADD xball,AX             ;move the ball horizontally
		
		MOV AX,4
        add ax,xstart
		CMP xball,AX                         
		JL NEG_speedX         ;BALL_X < 0 + WINDOW_BOUNDS (Y -> collided)
		
		MOV AX,xend
		SUB AX,ballsize
		SUB AX,4
		CMP xball,AX	          ;BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS (Y -> collided)
		JG NEG_speedX
		
		
		MOV AX,ballspeedy1
		ADD yball,AX             ;move the ball vertically
		
		MOV AX,4
        add ax,ystart
		CMP yball,AX   ;BALL_Y < 0 + WINDOW_BOUNDS (Y -> collided)
		JL NEG_speedY                          
		
		MOV AX,yend	
		SUB AX,ballsize
		SUB AX,4
		CMP yball,AX
		JG NEG_speedY		  ;BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS (Y -> collided)
		
		   jmp endf
		
		NEG_speedX:
			NEG ballspeedx1   ;BALL_VELOCITY_X = - BALL_VELOCITY_X
			jmp endf
			
		NEG_speedY:
			NEG ballspeedy1   ;BALL_VELOCITY_Y = - BALL_VELOCITY_Y
			jmp endf
     endf:

	
endm
;_________________________MovePaddels_____________________________________


;-------------------------------------------------------------;
;-------------------------------------------------------------;

;-------------------------------------------------------------;
;-------------------------------------------------------------;
.model small

.stack 100h

.data
;___main menu screen data variables__
menu db 13,10
     db 13,10
     db 13,10
     db 13,10
     db 13,10
     db 13,10
     db 13,10
     db 13,10
     db 13,10
     db "                              Please select a choice:",13,10
     db 13,10
     db "                              F1. Enter the game",13,10
     db 13,10
     db "                              F2. Enter Chat module",13,10
     db 13,10
     db "                              F3. Exit",13,10,'$'
     db 13,10
	 invalidchoice db "Invalid number please enter valid number",13,10,'$'
;__video game mode__	 
mode      db 13h     ;320 x 200.
dash db '-'
Chatinvte              DB      0   ;0 if there is No invitations, 1-means invitation was sent, 2-invitation was  received
ChatModuleInvitationSentMsg       DB      'You sent a chat invitation to $'
ChatModuleInvitationReceivedMsg   DB      'Press F2 to accept chat invitation from $'

gameinvite              DB      0   ;0-No invitations, 1-invitation sent, 2-invitation-received
GameInvitationSentMsg       DB      'You sent a game invitation to $'
GameInvitationReceivedMsg   DB      'Press F2 to accept game invitation from $'
;__Game Level ____

EnterGameLevel db 13,10
db "Please Enter the Game level ",'$'

GameLevel db 30,?,30 dup('$')
GameLevelReal dw ?
;_players usernames__
username db 13,10
db "Please Enter username: ",'$'

username2     db 13,10
db "Please Enter username 2: ",'$'
;__variables which the usernames will be stored at__
msg1 db 15,?,15 dup('$')
usernamesize dw 15
 WaitinguserMessage    DB      'Waiting other User to connect...$'   
    
msg2 db 15,?,15 dup('$')
   
scoremess db ":score:",'$'
;________________this is the winner messege_____________
message db "    And The Winner Is :  ",'$'

;_______________angles determination variables__________
r db ?
SetAngle dw ?
col db 0fh
d equ   80h
a equ   0h
f equ   24h
b equ   21h

c equ   1h
gameinvitation db " send you a game invitation press f1 to accept  ",'$'
gameinvitation2 db "you recieved game inivitation  ",'$'
chatinvitation db " send you a chat invitation press f2 to accept  ",'$'
barrier db "--------------------------------------------------------------------------------",'$'
;_______________angles messages__________
mesangle45 db "45",'$'
mesangleneg45 db "-45",'$'
mesangle30 db "30",'$'
mesangleneg30 db "-30",'$'
mesangle0 db "0",'$'
;________________________________
startingplayermessage db "please enter l or r which determine which player will have the ball",'$'
startingplayer db 30,?,30 dup('$')
winscoremessage db "please enter the number of goals player should score to win",'$'
winscore db ?

welcome                  DB      'Welcome $'
Connected            DB      'You are connected with $'
;________________________________
;frame dimensions
xstart    dw 10
ystart    dw 10
xend      dw 300
yend      dw 150
;Ball dimensions
xball     dw 180
yball     dw 75
ballsize  dw 2  ;2*2 size 

;1st level Paddels dimensions
Paddelxstart1 dw 20 
paddelxend1   dw 24
paddelxstart2 dw 289
paddelxend2   dw 293
Paddelystart1  dw 70
paddelyend1    dw 90
paddelystart2 dw 70
paddelyend2   dw 90

;2nd level Paddels dimensions
Paddelxstart12 dw 20 
paddelxend12  dw 24
paddelxstart22 dw 289
paddelxend22   dw 293
Paddelystart12  dw 70
paddelyend12    dw 80
paddelystart22 dw 70
paddelyend22   dw 80

;paddles specs
paddlevelocity dw 5

;1st level goal dimensions
xgoalstart1 dw 10
xgoalend1   dw 15
xgoalstart2 dw 295
xgoalend2   dw 300
ygoalstart  dw 45
ygoalend    dw 110
;2nd level goal dimensions
xgoalstart12 dw 10
xgoalend12   dw 15
xgoalstart22 dw 295
xgoalend22   dw 300
ygoalstart2  dw 55
ygoalend2    dw 95

sendedchar     DB      ?
recievedchar   DB      ?

;game modes     
gamemode DB 3bh ; f1 scan code
chatmode DB 3ch ; f2 scan code
exit DB 3dh ; f3 scan code
;time variable
t db 0 ;for checking

;1st level ball velocity 
ballspeedx1 dw 4 ; velocity of the ball in x axis
ballspeedy1 dw 4 ; velocity of the ball in y axis

;2nd level ball velocity
ballspeedx12 dw 10 ; velocity of the ball in x axis
ballspeedy12 dw 10; velocity of the ball in y axis


;recentering variable
recenter db 0

;Score values
 rightscore db 30,?,30 dup('$')  ;score of the right player
 leftscore  db  30,?,30 dup('$') ;score of the left player

.code

main proc far

;INITIALIZE DATA SEGMENT.
  mov  ax, @data
  mov  ds, ax
 InitiatSerialPort
 call clear_screen
 PrintString username
 ;call display_username1
 ReadString msg1
 call waitforotheruser 

;  mov  ah,0Ah
;  mov  dx,offset msg1
; int   21h      
call clear_screen
call DrawNotiBar
call display_menu    

;WAIT FOR ANY KEY.    
enternum:
 mov ah,0
 int 16h
 mov bl,gamemode ;move 1 to bh
 cmp ah,bl ; if the entered value equal 1
 je DetermineGameLevel
  mov bl,chatmode ;move 1 to bh
 cmp ah,bl ; if the entered value equal 1
 je chatmodule
 mov Bl,exit ;move 1 to bh
 cmp ah,bl ; if the entered value equal 3
 je finish
 call display_invalid ; if the user input is not 1,2,3
 jmp enternum


;---------------------------------------------
chatmodule:
    


DetermineGameLevel:
call clear_screen
call DisplayEnterGameLevel
mov ah,0h
int 16h
cmp al,49
je beginlevel1
cmp al,50
je beginlevel22
finish: ;exit the program
call exitprogram
;The game mode will be here
beginlevel22:
jmp beginlevel2

beginlevel1:
call clear_screen
call display_username1
mov ah,0Ah
mov dx,offset msg1
int 21h
call display_username2
mov ah,0Ah
mov dx,offset msg2
int 21h
mov ah,30h
mov leftscore,ah
mov ah,30h
mov rightscore,ah
mov ax,0
mov ballspeedx1,ax
mov ballspeedy1,ax
mov setangle,2
;players shall enter which side will the ball start at his side
looop: 
call displaystartingplayermessage
mov ah,00h
int 16h
cmp al,6ch
jne rightplayer
mov ax,130
mov xball,ax
;
mov ax,75
mov yball,ax
DrawBall xball,yball,ballsize,Draw
jmp deteminewinscore
rightplayer:
cmp al,72h
jne looop
mov ax,175
mov xball,ax
;
mov ax,75
mov yball,ax
DrawBall xball,yball,ballsize,Draw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
deteminewinscore:
call displaywinscoremessage
mov ah,00h
int 16h
mov winscore,al
jmp timecheck1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
timecheck1:
;first we will check the time with the FPS
mov ah,2ch
int 21h;  Dl frames per second

cmp dl,t ;t is initially 0 where the ball is at rest
je timecheck1 ;as its the same time so ball wont move
mov t,dl ;to update the time
call SetVideoMode;sets the resolution
call SetBackGroundColour
call DrawFrame ;proc draws the game frame
DrawBall xball,yball,ballsize,Draw
call checkgoal 
call DisplayPlayersNames
 
;determine random angle
jmp endangles
endangles:
DrawAirHockeyGoals  xgoalstart1,xgoalend1,xgoalstart2,xgoalend2,ygoalstart,ygoalend,drawgoal1,drawgoal2
DrawPaddels  paddelxstart1,paddelxend1,paddelxstart2,paddelxend2,paddelystart1,paddelyend1,paddelystart2,paddelyend2,drawpaddel1,drawpaddel2
call checkpaddel
Ballmovement  xball,ballspeedx1,yball,ballspeedy1,ballsize,xstart,xend,ystart,yend,window_bounds,NEG_speedX, NEG_speedy,end
call movepaddels

call DrawPlayGroundCenter
mov bl,winscore
cmp leftscore,bl            ;compare if the left player win show his name on the screen and press enter to end the game
je ENDGAMEANDSHOWTHELEFTWINNER
cmp rightscore,bl
je ENDGAMEANDSHOWTHERIGHTWINNER
jmp timecheck1

ENDGAMEANDSHOWTHELEFTWINNER:
call clear_screen
mov ah,9
mov dx,offset message
int 21h

call displayUN
mov ah,0Ah
mov dx,offset msg1
int 21h
call finish

ENDGAMEANDSHOWTHERIGHTWINNER:
call clear_screen

mov ah,9
mov dx,offset message
int 21h

call displayUN1
mov ah,0Ah
mov dx,offset msg2
int 21h

call finish

beginlevel2:
call clear_screen
call display_username1
mov ah,0Ah
mov dx,offset msg1
int 21h
call display_username2
mov ah,0Ah
mov dx,offset msg2
int 21h
mov ah,30h
mov leftscore,ah
mov ah,30h
mov rightscore,ah
mov ax,0
mov ballspeedx12,ax
mov ballspeedy12,ax
mov setangle,2
;players shall enter which side will the ball start at his side
looop2: 
call displaystartingplayermessage
mov ah,00h
int 16h
cmp al,6ch
jne rightplayer2
mov ax,130
mov xball,ax
;
mov ax,75
mov yball,ax
DrawBall xball,yball,ballsize,Draw
jmp deteminewinscore2
rightplayer2:
cmp al,72h
jne looop2
mov ax,175
mov xball,ax
;
mov ax,75
mov yball,ax
DrawBall xball,yball,ballsize,Draw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
deteminewinscore2:
call displaywinscoremessage
mov ah,00h
int 16h
mov winscore,al
jmp timecheck2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
timecheck2:
;first we will check the time with the FPS
mov ah,2ch
int 21h;  Dl frames per second
cmp dl,t ;t is initially 0 where the ball is at rest
je timecheck2 ;as its the same time so ball wont move
mov t,dl ;to update the time
call SetVideoMode;sets the resolution
call SetBackGroundColour
call DrawFrame ;proc draws the game frame

DrawBall xball,yball,ballsize,Draw

call checkgoal2 ; de lesa feha howar
call DisplayPlayersNames
jmp endangles2
endangles2:
DrawAirHockeyGoals  xgoalstart12,xgoalend12,xgoalstart22,xgoalend22,ygoalstart2,ygoalend2,drawgoal1,drawgoal2
DrawPaddels  paddelxstart12,paddelxend12,paddelxstart22,paddelxend22,paddelystart12,paddelyend12,paddelystart22,paddelyend22,drawpaddel1,drawpaddel2
call checkpaddel2
Ballmovement  xball,ballspeedx12,yball,ballspeedy12,ballsize,xstart,xend,ystart,yend,window_bounds,NEG_speedX, NEG_speedy,end
call movepaddels2
call DrawPlayGroundCenter
mov bl,winscore
cmp leftscore,bl            ;compare if the left player win show his name on the screen and press enter to end the game
je ENDGAMEANDSHOWTHELEFTWINNER2
cmp rightscore,bl
je ENDGAMEANDSHOWTHERIGHTWINNER2
jmp timecheck2

ENDGAMEANDSHOWTHELEFTWINNER2:
call clear_screen
mov ah,9
mov dx,offset message
int 21h

call displayUN
mov ah,0Ah
mov dx,offset msg1
int 21h
call finish

ENDGAMEANDSHOWTHERIGHTWINNER2:
call clear_screen

mov ah,9
mov dx,offset message
int 21h

call displayUN1
mov ah,0Ah
mov dx,offset msg2
int 21h

call finish




main endp

Send_Receive_name PROC Near 
			
	mov DI,2 ; Index to Player1 name
	mov CL,15 ; The max size for name
	mov SI,0 ; Index to player2 name
	
	Send_Receive_loop:
	WaitTheotherPlayer: ; Check is the sending buffer is empty .. so you wait for the other player to receive
  mov dx,3FDH
  in al,dx
  test al,00100000b
  JZ WaitTheotherPlayer ; If nothing is sent go back and start again
	mov al,msg1[DI] ; Getting ready to send the name
			;-------------------- Sending the name user entered
  mov dx,3f8h
  out dx,al
	INC DI
            ;-------------------- Receving the name the other user entered
	WaitToRec:
	mov dx,3fdh
	in al,dx
	test al,1
	JZ WaitToRec ; If nothing is sent yet ... wait for the player 
	mov dx,03f8h
  in al,dx
			;------------------
  mov msg2[SI],al ; Filling player2 name with the sent name
	INC SI
	loop Send_Receive_loop
	ret
Send_Receive_name ENDP
;__Setting BackGround Colour__

waitforotheruser PROC

    PrintString WaitinguserMessage
    
    ;Hide the cursor some where in the screen
        MOV AH, 02H
    MOV BH, 0
    MOV DL, 80
    MOV DH, 25
    INT 10H
    
    MOV BX, 2
    
    UserName_Send:
    ;Send a letter of username
    MOV CL, msg1[BX]
    SendChar CL
    
    ;Receive a letter from other player
    UserName_SendNotReceived:
    
    ;Check if ESC is pressed to quit the program
    GetKeyPressAnddisposes
    CMP AL, 01H
    JNE UserName_ContinueReceive
    MOV AX, 4C00H
    INT 21H         ;Back to the system
    
    UserName_ContinueReceive:
    ReceiveChar
    JZ UserName_SendNotReceived
    
    MOV msg2[BX], AL
    INC BX
    CMP BX, usernamesize
    JLE UserName_Send
    
    EmptyKeyQueue
    RET
waitforotheruser ENDP
DrawNotiBar PROC
    ;Draw begin separator
        MOV SI, 0
        Back:
        MOV CX, SI
        ADD CL, 24
        mov ah,2h  
        mov dh,24
        mov dl,2
        int 10h
        MOV AH, 09H         ;Display
        MOV BH, 0     ;Page 0
        MOV AL, dash        ;Character to display
        MOV BL, col       ;Color(back:fore)
        MOV CX, 80         ;Number of times
        INT 10H

        
        INC SI
        CMP SI, 1
        JB Back
    ;Draw end separator
    ;DrawLine 0, 24, 1, 80, dash, 0FH, 0
  
    ;Chat invitation sent message
    NotificationChatSent:
    CMP Chatinvte, 1
    JNE NotificationChatReceived
    mov ah,2h  
    mov dh,24
    mov dl,2
    int 10h
    PrintString ChatModuleInvitationSentMsg
    PrintString msg2+2
    ;==================================
    
    ;Chat invitation received message
    NotificationChatReceived:
    CMP Chatinvte, 2
    JNE NotificationGameSent
    MOV AH, 02H
    MOV BH, 0
    MOV DL, 1
    MOV DH, 22
    INT 10H
    PrintString ChatModuleInvitationReceivedMsg
    PrintString msg2+2
    ;==================================
    
    ;Game invitation sent message
    NotificationGameSent:
    CMP gameinvite, 1
    JNE NotificationGameReceived
    MOV AH, 02H
    MOV BH, 0
    MOV DL, 1
    MOV DH, 23
    INT 10H
    PrintString GameInvitationSentMsg
    PrintString msg2+2
    ;==================================
    
    ;Game invitation received message
    NotificationGameReceived:
    CMP gameinvite, 2
    JNE NotificationReturn
    MOV AH, 02H
    MOV BH, 0
    MOV DL, 1
    MOV DH, 22
    INT 10H
    PrintString GameInvitationReceivedMsg
    PrintString msg2+2
    ;==================================
    
    NotificationReturn:

    MOV AH, 02H
    MOV BH, 0
    MOV DL, 0
    MOV DH, 0
    INT 10H
    PrintString welcome
    PrintString msg1+2
    PrintString connected
    PrintString msg2+2


    RET
DrawNotiBar ENDP
SetBackGroundColour proc near;background colour
 mov ah,0bh            ;set configuration 
 mov bh,00h            ;to the background
 mov bl, 4        ;set background game colour
 int 10h
 ret
SetBackGroundColour endp

;__SetVideoMode__
SetVideoMode proc near ;Set 640*480
mov ah, 00            ;sub_function 0.
mov al, mode        ;selecting mode 18.
int 10h  
ret             ;calls the graphic interrupt.
SetVideoMode endp

;__display_menu__

display_menu proc near ;display menu
  mov  dx, offset menu
  mov  ah, 9
  int  21h
  ret
display_menu endp
;__display_invalid__
display_invalid proc near ;display invalid
  mov  dx, offset invalidchoice
  mov  ah, 9
  int  21h
  ret
display_invalid endp
;__clear_screen__
clear_screen proc near ;clear screen
  mov  ah, 0
  mov  al, 3
  int  10H
  ret
clear_screen endp

display_score proc near ;display menu
  mov  dx, offset scoremess
  mov  ah, 9
  int  21h
  ret
display_score endp


displayleftscore proc near ;;display left score in videomode
mov dx, offset leftscore
mov ah,9
int 21h
ret
displayleftscore endp

displayrightscore proc near
mov dx, offset rightscore
mov ah,9
int 21h
ret
displayrightscore endp

DisplayEnterGameLevel proc near ;display enter game level messege
  mov  dx, offset entergamelevel
  mov  ah, 9
  int  21h
  ret
DisplayEnterGameLevel endp

display_username1 proc near ;display enter player 1 name messege
  mov  dx, offset username
  mov  ah, 9
  int  21h
  ret
display_username1 endp

display_username2 proc near ;display enter player 2 name messege
  mov  dx, offset username2
  mov  ah, 9
  int  21h
  ret
display_username2 endp

displaystartingplayermessage proc near
call clear_screen
mov  dx, offset startingplayermessage
mov  ah, 9
int  21h
ret
 displaystartingplayermessage endp

 displaywinscoremessage proc near
call clear_screen
mov  dx, offset winscoremessage
mov  ah, 9
int  21h
ret
 displaywinscoremessage endp

DisplayPlayersNames proc near ;display players names in game
mov ah,2h  
mov dh,147
mov dl,7
int 10h
call displayUN
mov ah,2h  
mov dh,147
mov dl,70
int 10h
call displayUN1
mov ah,2h  
mov dh,147
mov dl,17
int 10h
call display_score
mov ah,2h  
mov dh,150
mov dl,10
int 10h
call displayleftscore
mov ah,2h  
mov dh,150
mov dl,28
int 10h
call displayrightscore
ret
DisplayPlayersNames endp

;check if the ball entered the goal
checkgoal proc near

cmp xball,15;;check if right player scored a goal to increase his score
jg checkright
mov ax,yball
cmp ax,ygoalstart
jl nochange
cmp ax,ygoalend
jg nochange
inc rightscore
mov ax,135
mov xball,ax
mov ax,75
mov yball,ax
mov ax,0
mov ballspeedx1,0
mov ax,0
mov ballspeedy1,0

call ResetPaddelslevel1

checkright:   ;;check if left player scored a goal to increase his score 
mov ax,xball
add ax,ballsize
cmp ax,294
jl nochange
mov ax,yball
cmp ax,ygoalstart
jl nochange
cmp ax,ygoalend
jg nochange

inc leftscore
mov ax,170
mov xball,ax
mov ax,75
mov yball,ax
mov ballspeedx1,0
mov ax,0
mov ballspeedy1,0

call ResetPaddelslevel1

nochange:
ret
checkgoal endp

;check goal for level 2
checkgoal2 proc near

cmp xball,15;;check if right player scored a goal to increase his score
jg checkright2
mov ax,yball
cmp ax,ygoalstart2
jl nochange2
cmp ax,ygoalend2
jg nochange2
inc rightscore
mov ax,135
mov xball,ax
mov ax,75
mov yball,ax
mov ax,0
mov ballspeedx12,0
mov ax,0
mov ballspeedy12,0

call ResetPaddelslevel2

checkright2:   ;;check if left player scored a goal to increase his score 
mov ax,xball
add ax,ballsize
cmp ax,294
jl nochange2
mov ax,yball
cmp ax,ygoalstart2
jl nochange2
cmp ax,ygoalend2
jg nochange2

inc leftscore
mov ax,170
mov xball,ax
mov ax,75
mov yball,ax
mov ballspeedx12,0
mov ax,0
mov ballspeedy12,0

call ResetPaddelslevel2

nochange2:
ret
checkgoal2 endp

ResetPaddelslevel2 proc near  ;reset the paddels locations when a player scores a goal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov [paddelxstart12],20
mov [paddelxend12],24
mov [paddelxstart22],289
mov [paddelxend22],293
mov [paddelystart12],70
mov [paddelyend12],80
mov [paddelystart22],70
mov [paddelyend22],80
mov ax,2
mov SetAngle,ax
ret

ret
ResetPaddelslevel2 endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkpaddel proc near  ;check if the ball collided with the paddle

MOV AX,xball
checkrightpadel:; check right paddel collision and what happens if it collides and all angles determination
ADD AX,ballsize
CMP AX,Paddelxstart2
JNG checkleftpadeltemp  ;if that it doesnt collied with right paddle
		
MOV AX,paddelxend2
CMP xball,AX
JNL checkleftpadeltemp  ;if that it doesnt collied with right paddle
		
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart2
JNG checkleftpadeltemp  ;if that it doesnt collied with right paddle
		
MOV AX,paddelyend2
CMP yball,AX
JNL checkleftpadeltemp
jmp kick

checkleftpadeltemp:
jmp checkleftpadel
ret
kick:
MOV AX,yball
ADD AX,ballsize
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart2
Jl exitttt  

mov bx,paddelyend2
sub bx,11
MOV AX,bx
CMP yball,AX
Jg exitttt

mov ax,SetAngle 
cmp ax,1
je kickangle45top
cmp ax,2
je exitttttt
cmp ax,3
je KickAngleNeg45Top
cmp ax,4
je KickAngle30Top
cmp ax,5
je close
ret
KickAngle45Top:;incident angle is 45 degree and reflection angle is -30 degree [add -2 on x ball position and -1 on y ball position]

mov ax,3
mov ballspeedy1,ax
mov ax,5
mov ballspeedx1,ax
mov ax,5
mov SetAngle,ax
;
jmp endd
exitttt:
jmp KickAngleBot
close:
jmp kickangleneg30top
exitttttt:
jmp exittt
KickAngleNeg45Top:; incident angle is -45 degree and reflection angle is 30 degree [add -2 on x ball position and -1 on y ball position]
mov ax,5
neg ax
mov ballspeedx1,ax
mov ax,3
neg ax
mov ballspeedy1,ax
mov ax,4
mov SetAngle,ax

jmp endd
exittt:
jmp KickAngle0Top
KickAngle30Top:;incident angle is 30 degree and reflection angle is 0 degree [add -1 on x ball position]

mov ax,4
neg ax
mov ballspeedx1,ax
mov ax,2
mov SetAngle,ax
;print the angle

jmp endd
exitt:
jmp kickanglebot
KickAngleNeg30Top:;incident angle is -30 degree and reflection angle is 0 degree [add -1 on x ball position ]

mov ax,4
neg ax
mov ballspeedx1,ax
mov ax,2
mov SetAngle,ax
;print the angle

jmp endd

KickAngle0Top:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]

mov ax,4
mov ballspeedy1,ax
mov ax,4
neg ax
mov ballspeedx1,ax
mov ax,3
mov SetAngle,ax
;print the angle
jmp endd

;________________bot part of the paddel_________________________
KickAngleBot:
mov ax,SetAngle 
cmp ax,1
je KickAngle45Top
cmp ax,2
je kickangle0bot
cmp ax,3
je KickAngleNeg45Top
cmp ax,4
je KickAngle30Top
cmp ax,5
je KickAngleNeg30Top
ret

KickAngle0bot:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]

mov ax,4
neg ax
mov ballspeedy1,ax
mov ballspeedx1,ax
mov ax,3
mov SetAngle,ax
jmp endd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
checkleftpadel:
MOV AX,xball
ADD AX,ballsize
CMP AX,Paddelxstart1
JNG endthen  ;if that it doesnt collied with right paddle
		
MOV AX,paddelxend1
CMP xball,AX
JNL endthen  ;if that it doesnt collied with right paddle
		
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart1
JNG endthen  ;if that it doesnt collied with right paddle
		
MOV AX,paddelyend1
CMP yball,AX
JNL endthen
;
MOV AX,yball
ADD AX,ballsize
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart1
Jl leftttt  

mov bx,paddelyend1
sub bx,11
MOV AX,bx
CMP yball,AX
Jg leftttt

mov ax,SetAngle 
cmp ax,1
je Leftkickangle45top
cmp ax,2
je leftttttt
cmp ax,3
je LeftKickAngleNeg45Top
cmp ax,4
je LeftKickAngle30Top
cmp ax,5
je closee
endthen:
jmp endd
LeftKickAngle45Top:;incident angle is 45 degree and reflection angle is -30 degree [add -2 on x ball position and -1 on y ball position]

mov ax,3
mov ballspeedy1,ax
mov ax,5
mov ballspeedx1,ax
mov ax,5
mov SetAngle,ax
;
jmp endd
leftttt:
jmp LeftKickAngleBot
closee:
jmp Leftkickangleneg30top
leftttttt:
jmp lefttt
LeftKickAngleNeg45Top:; incident angle is -45 degree and reflection angle is 30 degree [add -2 on x ball position and -1 on y ball position]
mov ax,5
mov ballspeedx1,ax
mov ax,3
neg ax
mov ballspeedy1,ax
mov ax,4
mov SetAngle,ax

jmp endd
lefttt:
jmp LeftKickAngle0Top

LeftKickAngle30Top:;incident angle is 30 degree and reflection angle is 0 degree [add -1 on x ball position]
mov ax,4
mov ballspeedx1,ax
mov ax,2
mov SetAngle,ax
jmp endd

leftt:
jmp Leftkickanglebot

LeftKickAngleNeg30Top:;incident angle is -30 degree and reflection angle is 0 degree [add -1 on x ball position ]
mov ax,4
mov ballspeedx1,ax
mov ax,2
mov SetAngle,ax
jmp endd

LeftKickAngle0Top:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]
mov ax,4
mov ballspeedy1,ax
mov ax,4
mov ballspeedx1,ax
mov ax,3
mov SetAngle,ax
jmp endd

;________________bot part of the paddel_________________________
LeftKickAngleBot:
mov ax,SetAngle 
cmp ax,1
je LeftKickAngle45Top
cmp ax,2
je Leftkickangle0bot
cmp ax,3
je LeftKickAngleNeg45Top
cmp ax,4
je LeftKickAngle30Top
cmp ax,5
je LeftKickAngleNeg30Top
ret

LeftKickAngle0bot:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]
mov ax,4
neg ax
mov ballspeedy1,ax
mov ax,4
mov ballspeedx1,ax
mov ax,3
mov SetAngle,ax
jmp endd
endd:
ret
checkpaddel endp

checkpaddel2 proc near  ;check if the ball collided with the paddle

MOV AX,xball
checkrightpadel2:; check right paddel collision and what happens if it collides and all angles determination
ADD AX,ballsize
CMP AX,Paddelxstart22
JNG checkleftpadeltemp2  ;if that it doesnt collied with right paddle
		
MOV AX,paddelxend22
CMP xball,AX
JNL checkleftpadeltemp2  ;if that it doesnt collied with right paddle
		
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart22
JNG checkleftpadeltemp2  ;if that it doesnt collied with right paddle
		
MOV AX,paddelyend22
CMP yball,AX
JNL checkleftpadeltemp2
jmp kick2

checkleftpadeltemp2:
jmp checkleftpadel2
ret
kick2:
MOV AX,yball
ADD AX,ballsize
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart22
Jl exitttt2

mov bx,paddelyend22
sub bx,11;;;mesh 3aref eh el rakam daa
MOV AX,bx
CMP yball,AX
Jg exitttt2

mov ax,SetAngle 
cmp ax,1
je kickangle45top2
cmp ax,2
je exitttttt2
cmp ax,3
je KickAngleNeg45Top2
cmp ax,4
je KickAngle30Top2
cmp ax,5
je close2
ret
KickAngle45Top2:;incident angle is 45 degree and reflection angle is -30 degree [add -2 on x ball position and -1 on y ball position]

mov ax,3
mov ballspeedy12,ax
mov ax,5
mov ballspeedx12,ax
mov ax,5
mov SetAngle,ax
;
jmp endd2
exitttt2:
jmp KickAngleBot2
close2:
jmp kickangleneg30top2
exitttttt2:
jmp exittt2
KickAngleNeg45Top2:; incident angle is -45 degree and reflection angle is 30 degree [add -2 on x ball position and -1 on y ball position]
mov ax,5
neg ax
mov ballspeedx12,ax
mov ax,3
neg ax
mov ballspeedy12,ax
mov ax,4
mov SetAngle,ax

jmp endd2
exittt2:
jmp KickAngle0Top2
KickAngle30Top2:;incident angle is 30 degree and reflection angle is 0 degree [add -1 on x ball position]

mov ax,4
neg ax
mov ballspeedx12,ax
mov ax,2
mov SetAngle,ax
;print the angle

jmp endd2
exitt2:
jmp kickanglebot2
KickAngleNeg30Top2:;incident angle is -30 degree and reflection angle is 0 degree [add -1 on x ball position ]

mov ax,4
neg ax
mov ballspeedx12,ax
mov ax,2
mov SetAngle,ax
;print the angle

jmp endd2

KickAngle0Top2:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]

mov ax,4
mov ballspeedy12,ax
mov ax,4
neg ax
mov ballspeedx12,ax
mov ax,3
mov SetAngle,ax
;print the angle
jmp endd

;________________bot part of the paddel_________________________
KickAngleBot2:
mov ax,SetAngle 
cmp ax,1
je KickAngle45Top2
cmp ax,2
je kickangle0bot2
cmp ax,3
je KickAngleNeg45Top2
cmp ax,4
je KickAngle30Top2
cmp ax,5
je KickAngleNeg30Top2
ret

KickAngle0bot2:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]

mov ax,4
neg ax
mov ballspeedy12,ax
mov ballspeedx12,ax
mov ax,3
mov SetAngle,ax
jmp endd2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
checkleftpadel2:
MOV AX,xball
ADD AX,ballsize
CMP AX,Paddelxstart12
JNG endthen2  ;if that it doesnt collied with right paddle
		
MOV AX,paddelxend12
CMP xball,AX
JNL endthen2  ;if that it doesnt collied with right paddle
		
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart12
JNG endthen2  ;if that it doesnt collied with right paddle
		
MOV AX,paddelyend12
CMP yball,AX
JNL endthen2
;
MOV AX,yball
ADD AX,ballsize
MOV AX,yball
ADD AX,ballsize
CMP AX,paddelystart12
Jl leftttt2  

mov bx,paddelyend12
sub bx,11
MOV AX,bx
CMP yball,AX
Jg leftttt2

mov ax,SetAngle 
cmp ax,1
je Leftkickangle45top2
cmp ax,2
je leftttttt2
cmp ax,3
je LeftKickAngleNeg45Top2
cmp ax,4
je LeftKickAngle30Top2
cmp ax,5
je closee2
endthen2:
jmp endd2
LeftKickAngle45Top2:;incident angle is 45 degree and reflection angle is -30 degree [add -2 on x ball position and -1 on y ball position]

mov ax,3
mov ballspeedy12,ax
mov ax,5
mov ballspeedx12,ax
mov ax,5
mov SetAngle,ax
;
jmp endd2
leftttt2:
jmp LeftKickAngleBot2
closee2:
jmp Leftkickangleneg30top2
leftttttt2:
jmp lefttt2
LeftKickAngleNeg45Top2:; incident angle is -45 degree and reflection angle is 30 degree [add -2 on x ball position and -1 on y ball position]
mov ax,5
mov ballspeedx12,ax
mov ax,3
neg ax
mov ballspeedy12,ax
mov ax,4
mov SetAngle,ax

jmp endd2
lefttt2:
jmp LeftKickAngle0Top2

LeftKickAngle30Top2:;incident angle is 30 degree and reflection angle is 0 degree [add -1 on x ball position]
mov ax,4
mov ballspeedx12,ax
mov ax,2
mov SetAngle,ax
jmp endd2

leftt2:
jmp Leftkickanglebot2

LeftKickAngleNeg30Top2:;incident angle is -30 degree and reflection angle is 0 degree [add -1 on x ball position ]
mov ax,4
mov ballspeedx12,ax
mov ax,2
mov SetAngle,ax
jmp endd2

LeftKickAngle0Top2:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]
mov ax,4
mov ballspeedy12,ax
mov ax,4
mov ballspeedx12,ax
mov ax,3
mov SetAngle,ax
jmp endd2

;________________bot part of the paddel_________________________
LeftKickAngleBot2:
mov ax,SetAngle 
cmp ax,1
je LeftKickAngle45Top2
cmp ax,2
je Leftkickangle0bot2
cmp ax,3
je LeftKickAngleNeg45Top2
cmp ax,4
je LeftKickAngle30Top2
cmp ax,5
je LeftKickAngleNeg30Top2
ret

LeftKickAngle0bot2:;incident angle is 0 degree and reflection angle is -45 degree [add -1 on x ball position and 1 on y ball position]
mov ax,4
neg ax
mov ballspeedy12,ax
mov ax,4
mov ballspeedx12,ax
mov ax,3
mov SetAngle,ax
jmp endd2
endd2:
ret
checkpaddel2 endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;__exitprogram__
exitprogram proc near ;finish the game
mov ah, 00            ;again the subfunction 0.
mov al, 03            ;the text mode-3.
int 10h               ;calls the int.
mov ah, 04ch
mov al, 00            ;finishes the program.
int 21h
exitprogram endp
;__DrawFrame__

DrawFrame proc near  ;drawing the game frame

mov al, 0fh       ;white colour
mov ah, 0ch
mov cx, xstart        ;starts drawing the lines on x. 
  
drawhorizontal:
mov dx, yend          ;putting point at the bottom.
int 10h
mov dx, ystart        ;putting point in the top.
int 10h
inc cx                ;moves to next point.
cmp cx, xend          ;yet checks if it's the end.
jnz drawhorizontal

drawvertical:           ;(the y value is already ystart.)
mov cx, xstart        ;plotting on left-side.
int 10h
mov cx, xend          ;plotting on right side.
int 10h
inc dx                ;moves down to the next point.
cmp dx, yend          ;checks for the end.
jnz drawvertical
ret
DrawFrame endp

;-------------------------------------------------------------;
;-------------------------------------------------------------;
DrawPlayGroundCenter proc near  ;drawing the game frame

mov al, 8h       ;grey colour
mov ah, 0ch
mov cx, 145      ;starts drawing the lines on x. 
  
drawhorizontalplayground:
mov dx, 100          ;putting point at the bottom.
int 10h
mov dx, 60        ;putting point in the top.
int 10h
inc cx                ;moves to next point.
cmp cx, 165         ;yet checks if it's the end.
jnz drawhorizontalplayground


drawverticalplayground:
mov cx, 145           ;(the y value is already ystart.)
int 10h
mov cx, 165         ;plotting on right side.
int 10h
inc dx                ;moves down to the next point.
cmp dx, 100        ;checks for the end.
jnz drawverticalplayground

;draw vertical line 
mov cx,155
mov dx,ystart
drawverticalline:
int 10h
inc dx
cmp dx,yend
jnz drawverticalline
ret
DrawPlayGroundCenter endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ResetPaddelslevel1 proc near  ;reset the paddels locations when a player scores a goal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov [paddelxstart1],20
mov [paddelxend1],24
mov [paddelxstart2],289
mov [paddelxend2],293
mov [paddelystart1],70
mov [paddelyend1],90
mov [paddelystart2],70
mov [paddelyend2],90
mov ax,2
mov SetAngle,ax
ret

ret
ResetPaddelslevel1 endp

delay proc near
mov cx,1
startdelay:
cmp cx,100
je enddelay
inc cx
jmp startdelay
enddelay:
ret
delay endp


displayangle proc near

mov ax,setangle 
cmp ax,1
jne print2
;print the angle
mov ah,2
mov dh,160
mov dl,100
mov ah,9
mov dx,offset mesangle45
int 21h
jmp endz
;print the angle
print2:
cmp ax,3
jne print3
mov ah,2
mov dh,160
mov dl,100
mov ah,9
mov dx,offset mesangleneg45
int 21h
jmp endz
;print the angle
print3:
cmp ax,4
jne print4
mov ah,2
mov dh,160
mov dl,100
mov ah,9
mov dx,offset mesangle30
int 21h
jmp endz
;print the angle
print4:
cmp ax,5
jne print5
mov ah,2
mov dh,160
mov dl,100
mov ah,9
mov dx,offset mesangleneg30
int 21h
jmp endz
;print the angle
print5:
cmp ax,2
jne endz
mov ah,2
mov dh,160
mov dl,100
mov ah,9
mov dx,offset mesangle0
int 21h
endz:
ret
displayangle endp
;left and right paddels movment 
movepaddels proc near
;check if a key is pressed, ZF=1 if no key gets pressed
mov ah,01h
int 16h
jz check_Rpaddle_movement_temp ;ZF=1
;check the pressed key, ah=scan code
mov ah,00h
int 16h
cmp al,77h ;compare ASCII of 'w'
je move_Lpaddle_up
cmp al,73h ;compare ASCII of 's'
je move_Lpaddle_down
cmp al,61h ;compare ASCII of 'a'
je move_Lpaddle_left
cmp al,64h ;compare ASCII of 'd'
je left1
cmp ah,48h ;compare scancode of 'arrowup'
je rightup
CMP ah,50h ;compare scancode of 'arrowdown'
je rightdown
CMP ah,4bh ;compare scancode of 'arrowleft'
je rightleft
cmp ah,4Dh ;compare scancode of 'arrowdown'
je rightright

check_Rpaddle_movement_temp:
jmp check_Rpaddle_movement ; up and w are being pressed at the same time for instance
 
move_Lpaddle_up:;move left paddle up using 'w' key
mov ax,paddlevelocity
sub paddelystart1,ax;move paddle up by adding the velocity to the Y value(start)
sub paddelyend1,ax;move paddle up by adding the velocity to the Y value(end)
mov ax,ystart
cmp paddelystart1,ax;compare if the paddle exceeded the bounadries of the frame
jl reposition_left_paddle_Yposition_start
jmp check_Rpaddle_movement
reposition_left_paddle_Yposition_start: ;repositioning the paddle
mov ax,ystart
mov Paddelystart1,ax ;reposition top part at the bounds
mov paddelyend1,30 ; end part positioned 20 under the top part
jmp check_Rpaddle_movement
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
left1:
jmp move_Lpaddle_right
rightup:
jmp move_Rpaddle_up
rightdown:
jmp move_Rpaddle_down
rightleft:
jmp move_Rpaddle_left
rightright:
jmp move_Rpaddle_right
;;;;;;;;;;;;;;;;;;;;;;;;;;;
move_Lpaddle_down:;move left paddle down using 's' key
mov ax,paddlevelocity
add paddelystart1,ax
add paddelyend1,ax
mov ax,yend
cmp ax,paddelyend1;compare if the paddle exceeded the bounadries of the frame
jl reposition_left_paddle_Yposition_end
jmp check_Rpaddle_movement
reposition_left_paddle_Yposition_end: ;repositioning the paddle
mov ax,yend
mov paddelyend1,ax ;reposition top part at the bounds
mov paddelystart1,130; end part positioned 20 over the lower part
jmp check_Rpaddle_movement

move_Lpaddle_left:;move left paddle left using 'a' key
mov ax,paddlevelocity
sub paddelxstart1,ax
sub paddelxend1,ax
mov ax,16
cmp Paddelxstart1,ax
jl reposition_left_paddle_Xposition_start
jmp check_Rpaddle_movement
reposition_left_paddle_Xposition_start:
mov paddelxstart1,ax ;reposition left part at the bounds
mov paddelxend1,20; reposition right part
jmp check_Rpaddle_movement

move_Lpaddle_right:;move left paddle right using 'd' key
mov ax,paddlevelocity
add paddelxstart1,ax
add paddelxend1,ax
mov ax,147
cmp ax,paddelxend1
jl reposition_left_paddle_Xposition_end
jmp check_Rpaddle_movement
reposition_left_paddle_Xposition_end:
mov paddelxend1,ax ;reposition right part at the bounds
mov paddelxstart1,143; reposition left part
jmp check_Rpaddle_movement


check_Rpaddle_movement:
jmp check_RRpaddle_movement

 ;right paddel movement                          
 
move_Rpaddle_up:;move left paddle up using 'w' key
mov ax,paddlevelocity
sub paddelystart2,ax;move paddle up by adding the velocity to the Y value(start)
sub paddelyend2,ax;move paddle up by adding the velocity to the Y value(end)
mov ax,ystart
cmp paddelystart2,ax;compare if the paddle exceeded the bounadries of the frame
jl reposition_right_paddle_Yposition_start
jmp check_RRpaddle_movement
reposition_right_paddle_Yposition_start: ;repositioning the paddle
mov ax,ystart
mov Paddelystart2,ax ;reposition top part at the bounds
mov paddelyend2,30 ; end part positioned 20 under the top part
jmp check_RRpaddle_movement

move_Rpaddle_down:;move left paddle down using 's' key
mov ax,paddlevelocity
add paddelystart2,ax
add paddelyend2,ax
mov ax,yend
cmp ax,paddelyend2;compare if the paddle exceeded the bounadries of the frame
jl reposition_right_paddle_Yposition_end
jmp check_RRpaddle_movement
reposition_right_paddle_Yposition_end: ;repositioning the paddle
mov ax,yend
mov paddelyend2,ax ;reposition top part at the bounds
mov paddelystart2,130; end part positioned 20 over the lower part
jmp check_RRpaddle_movement

move_Rpaddle_left:;move left paddle left using 'a' key
mov ax,paddlevelocity
sub paddelxstart2,ax
sub paddelxend2,ax
mov ax,170
cmp Paddelxstart2,ax
jl reposition_right_paddle_Xposition_start
jmp check_RRpaddle_movement
reposition_right_paddle_Xposition_start:
mov paddelxstart2,ax ;reposition left part at the bounds
mov paddelxend2,174; reposition right part
jmp check_RRpaddle_movement

move_Rpaddle_right:;move left paddle right using 'd' key
mov ax,paddlevelocity
add paddelxstart2,ax
add paddelxend2,ax
mov ax,294
cmp ax,paddelxend2
jl reposition_right_paddle_Xposition_end
jmp check_RRpaddle_movement
reposition_right_paddle_Xposition_end:
mov paddelxend2,ax ;reposition right part at the bounds
mov paddelxstart2,290; reposition left part
jmp check_RRpaddle_movement

check_RRpaddle_movement:
ret
movepaddels endp



movepaddels2 proc near
;check if a key is pressed, ZF=1 if no key gets pressed
mov ah,01h
int 16h
jz check_Rpaddle_movement_temp2 ;ZF=1
;check the pressed key, ah=scan code
mov ah,00h
int 16h
cmp al,77h ;compare ASCII of 'w'
je move_Lpaddle_up2
cmp al,73h ;compare ASCII of 's'
je move_Lpaddle_down2
cmp al,61h ;compare ASCII of 'a'
je move_Lpaddle_left2
cmp al,64h ;compare ASCII of 'd'
je left2
cmp ah,48h ;compare scancode of 'arrowup'
je rightup2
CMP ah,50h ;compare scancode of 'arrowdown'
je rightdown2
CMP ah,4bh ;compare scancode of 'arrowleft'
je rightleft2
cmp ah,4Dh ;compare scancode of 'arrowdown'
je rightright2

check_Rpaddle_movement_temp2:
jmp check_Rpaddle_movement2 ; up and w are being pressed at the same time for instance
 
move_Lpaddle_up2:;move left paddle up using 'w' key
mov ax,paddlevelocity
sub paddelystart12,ax;move paddle up by adding the velocity to the Y value(start)
sub paddelyend12,ax;move paddle up by adding the velocity to the Y value(end)
mov ax,ystart
cmp paddelystart12,ax;compare if the paddle exceeded the bounadries of the frame
jl reposition_left_paddle_Yposition_start2
jmp check_Rpaddle_movement2
reposition_left_paddle_Yposition_start2: ;repositioning the paddle
mov ax,ystart
mov Paddelystart12,ax ;reposition top part at the bounds
mov paddelyend12,20 ; end part positioned 20 under the top part
jmp check_Rpaddle_movement2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
left2:
jmp move_Lpaddle_right2
rightup2:
jmp move_Rpaddle_up2
rightdown2:
jmp move_Rpaddle_down2
rightleft2:
jmp move_Rpaddle_left2
rightright2:
jmp move_Rpaddle_right2
;;;;;;;;;;;;;;;;;;;;;;;;;;;
move_Lpaddle_down2:;move left paddle down using 's' key
mov ax,paddlevelocity
add paddelystart12,ax
add paddelyend12,ax
mov ax,yend
cmp ax,paddelyend12;compare if the paddle exceeded the bounadries of the frame
jl reposition_left_paddle_Yposition_end2
jmp check_Rpaddle_movement2
reposition_left_paddle_Yposition_end2: ;repositioning the paddle
mov ax,yend
mov paddelyend12,ax ;reposition top part at the bounds
mov paddelystart12,140; end part positioned 20 over the lower part
jmp check_Rpaddle_movement2

move_Lpaddle_left2:;move left paddle left using 'a' key
mov ax,paddlevelocity
sub paddelxstart12,ax
sub paddelxend12,ax
mov ax,16
cmp Paddelxstart12,ax
jl reposition_left_paddle_Xposition_start2
jmp check_Rpaddle_movement2
reposition_left_paddle_Xposition_start2:
mov paddelxstart12,ax ;reposition left part at the bounds
mov paddelxend12,20; reposition right part
jmp check_Rpaddle_movement2

move_Lpaddle_right2:;move left paddle right using 'd' key
mov ax,paddlevelocity
add paddelxstart12,ax
add paddelxend12,ax
mov ax,147
cmp ax,paddelxend12
jl reposition_left_paddle_Xposition_end2
jmp check_Rpaddle_movement2
reposition_left_paddle_Xposition_end2:
mov paddelxend12,ax ;reposition right part at the bounds
mov paddelxstart12,143; reposition left part
jmp check_Rpaddle_movement2


check_Rpaddle_movement2:
jmp check_RRpaddle_movement2

 ;right paddel movement                          
 
move_Rpaddle_up2:;move left paddle up using 'up arrow' key
mov ax,paddlevelocity
sub paddelystart22,ax;move paddle up by adding the velocity to the Y value(start)
sub paddelyend22,ax;move paddle up by adding the velocity to the Y value(end)
mov ax,ystart
cmp paddelystart22,ax;compare if the paddle exceeded the bounadries of the frame
jl reposition_right_paddle_Yposition_start2
jmp check_RRpaddle_movement2
reposition_right_paddle_Yposition_start2: ;repositioning the paddle
mov ax,ystart
mov Paddelystart22,ax ;reposition top part at the bounds
mov paddelyend22,20 ; end part positioned 20 under the top part
jmp check_RRpaddle_movement2

move_Rpaddle_down2:;move right paddle down using 'down arrow' key
mov ax,paddlevelocity
add paddelystart22,ax
add paddelyend22,ax
mov ax,yend
cmp ax,paddelyend22;compare if the paddle exceeded the bounadries of the frame
jl reposition_right_paddle_Yposition_end2
jmp check_RRpaddle_movement2
reposition_right_paddle_Yposition_end2: ;repositioning the paddle
mov ax,yend
mov paddelyend22,ax ;reposition top part at the bounds
mov paddelystart22,140; end part positioned 20 over the lower part
jmp check_RRpaddle_movement2

move_Rpaddle_left2:;move right paddle left using 'left arrow' key
mov ax,paddlevelocity
sub paddelxstart22,ax
sub paddelxend22,ax
mov ax,170
cmp Paddelxstart22,ax
jl reposition_right_paddle_Xposition_start2
jmp check_RRpaddle_movement2
reposition_right_paddle_Xposition_start2:
mov paddelxstart22,ax ;reposition right part at the bounds
mov paddelxend22,174; reposition right part
jmp check_RRpaddle_movement2

move_Rpaddle_right2:;move right paddle right using 'right arrow' key
mov ax,paddlevelocity
add paddelxstart22,ax
add paddelxend22,ax
mov ax,294
cmp ax,paddelxend22
jl reposition_right_paddle_Xposition_end2
jmp check_RRpaddle_movement2
reposition_right_paddle_Xposition_end2:
mov paddelxend22,ax ;reposition right part at the bounds
mov paddelxstart22,290; reposition right part
jmp check_RRpaddle_movement2

check_RRpaddle_movement2:
ret
movepaddels2 endp



displaygameinvMessage proc near ;display enter player 1 name messege
  mov  dx, offset gameinvitation
  mov  ah, 9
  int  21h
  ret
displaygameinvMessage endp
displaygameinvMessage2 proc near ;display enter player 1 name messege
  mov  dx, offset gameinvitation2
  mov  ah, 9
  int  21h
  ret
displaygameinvMessage2 endp

displaychatinvMessage proc near ;display enter player 1 name messege
  mov  dx, offset chatinvitation
  mov  ah, 9
  int  21h
  ret
displaychatinvMessage endp

displayBarrier proc near ;display enter player 1 name messege
 mov ah,2h  
 mov dh,21
 mov dl,0
 int 10h
  mov  dx, offset Barrier
  mov  ah, 9
  int  21h
  ret
displayBarrier endp

displayUN proc near ;display username in videomode
mov dx, offset msg1+2
mov ah,9
int 21h
ret
displayUN endp

displayUN1 proc near ;display username in videomode
mov dx, offset msg2+2
mov ah,9
int 21h
ret
displayUN1 endp

displaygameinvitation proc near
mov ah,2h  
mov dh,24
mov dl,2
int 10h
call displayUN
mov ah,2h  
mov dh,24
mov dl,10
int 10h
call displaygameinvMessage
ret
displaygameinvitation endp

displaygameinvitation2 proc near

mov ah,2h  
mov dh,24
mov dl,2
int 10h
call displayUN1
mov ah,2h  
mov dh,24
mov dl,10
int 10h
call displaygameinvMessage
ret
displaygameinvitation2 endp

displaychatinvitation proc near
mov ah,2h  
mov dh,22
mov dl,2
int 10h
call displayUN
mov ah,2h  
mov dh,22
mov dl,10
int 10h
call displaychatinvMessage
ret
displaychatinvitation endp
end main
