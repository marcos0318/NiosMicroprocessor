# Tetris game
# 10x24 screen size

.data
# addresses
.equ TIMER, 0xFF202000     # timer 0 address
.equ KEYBOARD, 0xFF200100 # PS2 0 address
.equ PUSHBUTTONS, 0xFF200050
.equ LED, 0xFF200000
.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000

.equ ADDR_HEX, 0xFF200020
.equ ADDR_HEX2, 0xFF200030 # off by 16


.align 2
HexChars:
	.word 0b0111111 # 0
	.word 0b0000110 # 1
	.word 0b1011011 # 2
	.word 0b1001111 # 3
	.word 0b1100110 # 4
	.word 0b1101101 # 5
	.word 0b1111101 # 6
	.word 0b0000111 # 7
	.word 0b1111111 # 8
	.word 0b1101111 # 9


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
	stw et, 4(sp) 
	
	stw r8, 8(sp)
	stw r9, 12(sp)

	# find out interupt here

    rdctl et, ctl4


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
	
	bgt r23, r0, ignoreKey

	# else

	movi r8, 0xFF # mask to get the data
	and et, et, r8

	
	movi r4, 240
	beq et, r4, setIgnore


	movia r9, GameState
	ldw r9, 0(r9)
	movi r5, -1
	beq r5, r9, exitISR # game has ended



	movia r4, BoardState # first argument is board address


	movi r5, 28 # A - left
	beq et, r5, moveLeft
	
	movi r5, 35 # D - right
	beq et, r5, moveRight

	movi r5, 27 # S - down
	beq et, r5, moveDown

	movi r5, 29 # W - up
	beq et, r5, moveUp # rotate


	br exitISR # no key pressed from WASD


moveLeft:
	movi r5, 0
	call move_block
	br exitISR
moveRight:
	movi r5, 3
	call move_block
	br exitISR

moveUp:
	movi r5, 1
	call move_block
	#call rotate
	br exitISR
moveDown:
	movi r5, 1
	call descend
# update score
	movia r4, Score
	ldw r5, 0(r4)
	addi r5, r5, 1 # add one for each down press
	stw r5, 0(r4)
	call setScore

	br exitISR



setIgnore:
	movi r23, 1
	br exitISR

ignoreKey:
	movi r23, 0
	br exitISR


buttonInterrupt:
# check which button

	movia r8,PUSHBUTTONS
	movia r9,0xF	  # Enable interrrupt mask = 1111
	ldwio r4,12(r8) # find value of button
	stwio r9,12(r8) # Clear edge capture register to prevent unexpected interrupt

	movi r8, 1
	beq r4, r8, decreaseDiff
	movi r8, 2
	beq r4, r8, increaseDiff
	movi r8, 4
	beq r4, r8, resetGame
	br exitISR

decreaseDiff:
	movia r8, Difficulty
	ldw r9, 0(r8)
	beq r9, r0, exitISR
	addi r9, r9, -1
	stw r9, 0(r8)
	mov r4, r9
	br setDif

increaseDiff:
	movia r8, Difficulty
	ldw r9, 0(r8)
	movi r4, 5
	beq r9, r4, exitISR
	addi r9, r9, 1
	stw r9, 0(r8)
	mov r4, r9
	br setDif # only for clarity

setDif:

updateLED:
	# difficulty in r4
	
	mov r8, r4 
	movi r10, 1
	loopled:
		beq r8, r0, doneled
		slli r10, r10, 1
		addi r10, r10, 1
		addi r8, r8, -1
		br loopled
	doneled:
	movia r9, LED
	stwio r10, 0(r9)

updateSPEED:
	# difficulty in r4
	addi r4,r4, 1
	movia r9, 100000000
	div r4, r9, r4 # r4 = r9 / r4
	movia r9, Timeout_period # read the timeout period in the memory
	stw r4, 0(r9) # store the new timeout
	call setupTimer


	br exitISR

resetGame:
	# reset score
	movia r8, Score
	stw r0, 0(r8)
	# reset difficulty
	movia r8, Difficulty
	stw r0, 0(r8)
	# reset board
	call initBoardState
	call startGame
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



	movia r8, TIMER
	stwio r0, 0(r8)

	movia r8, GameState
	ldw et, 0(r8)
	movi r9, -1
	beq et, r9, exitISR # game has ended



	movia r4, BoardState

	call descend
	beq r2, r0, newBlock

	movia r4, BoardState

	call check_line_filled

	# update score
	movia r4, Score
	ldw r5, 0(r4)

	add r5, r5, r2

	stw r5, 0(r4)


	call setScore


	br exitISR
	

newBlock:
	movia r4, BoardState
	call storeBlock
	movia r4, BoardState
	movia r5, GameState
	call createNewBlock

exitISR:
	#restore variables
	ldw et, 4(sp)¨
	wrctl ctl1, et

	ldw et, 0(sp)
	
	ldw r8, 8(sp)
	ldw r9, 12(sp)


	addi sp,sp, 16
	subi ea, ea, 4


	eret


.global main
main:
	#initialization
	call randomInit
	call initBoardState
	movi r4, 0
	call setHEX

	call setupKeyboard
	call setupButton

	#enable global interrupts:
	movia r8, 1
	wrctl ctl0, r8

	call startGame
loop: 
    br loop
	ret	# Make sure this returns to main's caller

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

	movia r8,PUSHBUTTONS
	movia r9,0b0111	  # Enable interrrupt mask = 0111
	stwio r9,8(r8)  # Enable interrupts on pushbuttons 1,2, and 3
	stwio r9,12(r8) # Clear edge capture register to prevent unexpected interrupt

	rdctl r8, ctl3
	movi r9, 0b10 # mask
	or	r8, r8, r9 # or
	wrctl ctl3, r8 # enable timer interupts on line 1

	ret

startGame:
	addi sp, sp, -4
	stw ra,0(sp)

	# set difficulty to 0
	movia r4, Difficulty
	stw r0, 0(r4)

	# update difficulty LED
	movia r4, LED
	movi r5, 1
	stwio r5, 0(r4)
	# set timer to default value
	movia r9, 100000000
	movia r8, Timeout_period
	stw r9, 0(r8) 
	call setupTimer

	movia r4, BoardState
	movia r5, GameState
	stw r0, 0(r5) # set gamestate to 0

	call createNewBlock
	movia r4, BoardState
	call print_gameboard


	ldw ra,0(sp)
	addi sp,sp, 4

	ret

setScore:
	movia r7, Score
	ldw r4, 0(r7)

setHEX:
	# argument in r4
	movia r7, ADDR_HEX
	movia r8, HexChars

	movi r2, 10

	# find first digit

	# use modulo operation

	# remainder in r5
	div r6, r4, r2 # / 10
	muli r5, r6, 10
	sub r5, r4, r5


	# r5 is remainder
	slli r5, r5, 2
	add r9, r8, r5

	ldw r10, 0(r9) # 6

	# first digit in r10

	# find second digit

	div r4, r4, r2 # shift by 1 decimal char
	
	# use modulo operation

	# remainder in r5
	div r6, r4, r2
	muli r5, r6, 10
	sub r5, r4, r5

	# r5 is remainder
	slli r5, r5, 2
	add r9, r8, r5

	ldw r11, 0(r9) 
	
	# second digit in r11

	# find third digit

	div r4, r4, r2 # shift by 1 decimal char

	# use modulo operation

	# remainder in r5
	div r6, r4, r2
	muli r5, r6, 10
	sub r5, r4, r5

	# r5 is remainder
	slli r5, r5, 2
	add r9, r8, r5

	ldw r12, 0(r9) 
	
	# third digit in r12

	# find fourth digit

	div r4, r4, r2 # shift by 1 decimal char

	# use modulo operation

	# remainder in r5
	div r6, r4, r2
	muli r5, r6, 10
	sub r5, r4, r5

	# r5 is remainder
	slli r5, r5, 2
	add r9, r8, r5

	ldw r13, 0(r9) 
	
	# fourth digit in r13

	# store first four digits

	movi r5, 0

	or r5,r5,r10

	slli r11,r11,8
	or r5,r5,r11

	slli r12,r12,16
	or r5,r5,r12

	slli r13,r13,24
	or r5,r5,r13

	stwio r5, 0(r7)

	# last two digits

	# find fifth digit

	div r4, r4, r2 # shift by 1 decimal char

	# use modulo operation

	# remainder in r5
	div r6, r4, r2
	muli r5, r6, 10
	sub r5, r4, r5

	# r5 is remainder
	slli r5, r5, 2
	add r9, r8, r5

	ldw r10, 0(r9) 
	
	# 5th digit in r10

	# find 6th digit

	div r4, r4, r2 # shift by 1 decimal char

	# use modulo operation

	# remainder in r5
	div r6, r4, r2
	muli r5, r6, 10
	sub r5, r4, r5

	# r5 is remainder
	slli r5, r5, 2
	add r9, r8, r5

	ldw r11, 0(r9) 
	
	# 6th digit in r11


	# store last 2 digits

	movi r5, 0

	or r5,r5,r10

	slli r11,r11,8
	or r5,r5,r11

	stwio r5, 16(r7)
	ret

