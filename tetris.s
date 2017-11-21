# Tetris game
# 10x24 screen size

.data
# addresses
.equ TIMER, 0xFF202000     # timer 0 address
.equ KEYBOARD, 0xFF200100 # PS2 0 address


.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000

# the controller of game speed 
.align 2 
Timeout_period: .word 100000000

# the block infomation of the game
# the game size is 24*10
# we store each block infomation in words so we skip 24*10*4 bytes
.align 2
BoardState:
	.skip 960

.align 2

# the state that we store the score of the game
Score:
	.word 0

# this is the value that shows on the LEDS, indicate the dificulty
# of the game. 
# should be from 1 to 5
# can be set by button, and increases natually by the score
Difficulty:
	.word 0

# win? lose? or in the game?
# 0 means in process
# 1 means win
# -1 means lose
GameState:
	.word 0


.text
.section .exceptions, "ax"

myISR:
	

	#store temp variables et, ctl1, r8 and r9
	addi sp, sp, -16
	stw et, 0(sp)

	rdctl et, ctl1
	stw et, 4(sp)  #Make a backup of ctl1 because we'll enable nested interrupts
	
	stw r8, 8(sp)
	stw r9, 12(sp)

	# find out interupt here

    rdctl et, ctl4


	mov r8, et

	mov r4, et
	call printDec

	mov r8, et


	andi r8, r8, 0b10000000 # check if interrupt pending from IRQ7 (keyboard)

	bgt r8, r0, keyboardInterrupt # if true go to keyboardInterrupt


	andi r8, et, 0b10 # check if interrupt pending from IRQ1 (button press)
	bgt r8, r0, buttonInterrupt

	andi r8, et, 0b1 # check if pending from IRQ0 (timer)
	bgt r8,r0, timerInterrupt


	br exitISR # no interupt detected?



keyboardInterrupt:
# check which key is pressed 
	# read only the first element in the queue

	movia r8, KEYBOARD
	ldwio et, 0(r8)

	# is data valid:

	srli r8, et, 15
	andi r8, r8, 1

	beq r8, r0, exitISR # invalid data

	# else

	movi r8, 0xFF # mask to get the data
	and et, et, r8

	mov r4, r8
	call printDec
	br exitISR

	


	


# if the result is valid, rotate ccw
# if the result is valid, rotate cw
# if the result is valud, move left 
# if the result is valid, move right

# if the result is valid, move up/dowm 
# (not needed in the real game, but be useful in testing)
# reprint the gameboard 

buttonInterrupt:
# check which button

	movi r4, 2 # button prints 2
	call printDec
	br exitISR


# reset the game
# increase the difficulty
# decrease the difficulty
# reprint the gameboard, because may be restarted

timerInterrupt:
# descent the falling block if valid. 
# if not valid, fix the block and randomly create a new block

# check whether there is a full row
# if there is, clear that row and move down the rows above
# notice there maybe multiple rows

# update the scores, by some function that bonus on combo

# check the scroe, increse the difficulty every ?? loop

# debug msg
	movi r4, 1
	call printDec
	movia r8, TIMER
	stwio r0, 0(r8)

exitISR:
	#restore variables
	ldw et, 4(sp)¨
	wrctl ctl1, et

	ldw et, 0(sp)
	
	ldw r8, 8(sp)
	ldw r9, 12(sp)


	addi sp,sp, 16
	subi ea, ea, 4

	movi r4, 0 # exit ISR prints 0
	call printDec

	eret


.global main
main:
# ...
	#initialization
	# VGA testing code in main, this works well
  #movia r2,ADDR_VGA
  #movia r3, ADDR_CHAR
  #movui r4,0xffff  /* White pixel */
  #movi  r5, 0x41   /* ASCII for 'A' */
  #sthio r4,1032(r2) /* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */
  #stbio r5,132(r3) /* character (4,1) is x + y*128 so (4 + 128 = 132) */

	call initSp
	call initBoardState
	#call clear_screen

	#enable global interrupts:
	movia r8, 1
	wrctl ctl0, r8

	call setupKeyboard
	call setupButton
	call setupTimer

	call startGame
loop: 
    br loop
	ret	# Make sure this returns to main's caller

initSp:
	movia sp, 0x03FFFFFC
	ret

initBoardState: 
	# set all the data in the gamestate to 0
	movia r8, BoardState # the address of Boardstate
	movi r9, 240 # the counter of initializer
  initBoardStateLoop:
  stw r0, 0(r8)
  addi r8, r8, 4
  addi r9, r9, -1

  bne r9, r0, initBoardStateLoop
  ret 



setupTimer:
	movia r8, TIMER
	stwio r0, 0(r8) # set timeout to 0
	# set up timeout period to Timeout_period
	movia r9, Timeout_period # read the timeout period in the memory
	ldw r10, 0(r9) 
	
	# set the lower 16 bits of the timeout
	andi r11, r10, 0xFFFF
	stwio r11, 8(r8)
	
	# set the upper 16 bits of the timeout
	srli r11, r10, 16
	stwio r11, 12(r8)
	

	movi r9, 0b111 # enable interupts, restart on timeout, start the timer
	stwio r9, 4(r8) 
	
	rdctl r8, ctl3
	movi r9, 1 # mask 0x001
	or	r8, r8, r9 # or
	wrctl ctl3, r8 # enable timer interupts on line 0

	ret

setupKeyboard:
	movia r8, KEYBOARD
	movi r9, 0x1 # enable read interrupts
	stwio r9, 4(r8) # 

	rdctl r8, ctl3
	movi r9, 0b10000000 # mask 
	or	r8, r8, r9 # or
	wrctl ctl3, r8 # enable timer interupts on IRQ line 7




	ret

setupButton:

	rdctl r8, ctl3
	movi r9, 0b10 # mask
	or	r8, r8, r9 # or
	wrctl ctl3, r8 # enable timer interupts on line 1

	ret

startGame:
	
	ret

