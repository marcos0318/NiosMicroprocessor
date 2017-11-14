# Tetris game
# 10x22 screen size

.data
.align 2 
Timeout_period: .word 100000000

.equ TIMER, 0xFF202000     # timer 0 address
.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000

.text
.global main


.section .exceptions, "ax"
myISR:
	# find out interupt here

keyboardInterrupt:

buttonInterrupt:

timerInterrupt:
	movi r4, 1
	#call printDec
	movia r8, TIMER
	stwio r0, 0(r8)

exitISR:
	subi ea, ea, 4
	eret



main:
# ...
	#initialization
  movia r2,ADDR_VGA
  movia r3, ADDR_CHAR
  movui r4,0xffff  /* White pixel */
  movi  r5, 0x41   /* ASCII for 'A' */
  sthio r4,1032(r2) /* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */
  stbio r5,132(r3) /* character (4,1) is x + y*128 so (4 + 128 = 132) */

	#call initSp
	#call clear_screen

	#enable global interrupts:
	movia r8, 1
	wrctl ctl0, r8

	#call setupKeyboard
	#call setupButton
	#call setupTimer

	#call startGame
loop: 
    br loop
	ret	# Make sure this returns to main's caller

initSp:
	movia sp, 0x03FFFFFC
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
	

	movi r9, 0b111 # enable interupts, restart on timeout
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
