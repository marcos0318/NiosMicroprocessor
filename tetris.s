# Tetris game
# 10x24 screen size

.data
# addresses
.equ TIMER, 0xFF202000     # timer 0 address
.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000

# the controller of game speed 
.align 2 
Timeout_period: .word 100000000

# the block infomation of the game
# the game size is 24*10
# we store each block's infomation in words so we skip 24*10*4 bytes
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
	# find out interupt here

keyboardInterrupt:
# check which key is pressed 
# if the result is valid, rotate ccw
# if the result is valid, rotate cw
# if the result is valud, move left 
# if the result is valid, move right

# if the result is valid, move up/dowm 
# (not needed in the real game, but be useful in testing)
# reprint the gameboard 

buttonInterrupt:
# check which button

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
	subi ea, ea, 4
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

	ret

setupButton:

	ret

startGame:
	
	ret
