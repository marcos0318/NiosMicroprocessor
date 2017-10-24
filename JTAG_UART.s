1. the Readings 

Base 0x10001020

Data Register
31:16 - Number of bytes available to read (approximate)
15 - Read data is valid
7:0 - The data itself

Control Register
31:16 - Spaces available for writing
10 - AC (has value of 1 if JTAG UART has been accessed by host, cleared by writing 1 to it)
9 - Write interrupt is pending
8 - Read interrupt is pending
1 - Enable write interrupts
0 - Enable read interrupts

IRQ line 3
Set bit 1 and/or 0 in the Control Register for write and read interrupts respectively
Read (write) interrupts acknowledged by reading (writing) to the Data Register


read -> pop to a queue
write -> push to a queue

Data register:
  stwio: sending, write
  ldwid: receiving, read

Note: for reading:
  The "Number of bytes available" must not be used for polling. because it indicates the number of one cycle before. 
  Use Data[15] instead, showing the current status


Assembly Example: Sending the character '0' through the JTAG

  movia r7, 0x10001020 /* r7 now contains the base address */
WRITE_POLL:
  ldwio r3, 4(r7) /* Load from the JTAG */
  srli  r3, r3, 16 /* Check only the write available bits */
  beq   r3, r0, WRITE_POLL /* If this is 0 (branch true), data cannot be sent */
  movui r2, 0x30 /* ASCII code for 0 */
  stwio r2, 0(r7) /* Write the byte to the JTAG */

Assembly Example: Polling the JTAG until valid data has been received

  movia r7, 0x10001020 /* r7 now contains the base address */
READ_POLL:
  ldwio r2, 0(r7) /* Load from the JTAG */
  andi  r3, r2, 0x8000 /* Mask other bits */
  beq   r3, r0, READ_POLL /* If this is 0 (branch true), data is not valid */
  andi  r3, r2, 0x00FF /* Data read is now in r3 */



2. 
  1)  "On the track" sensor state is indicated by a value of 1 and "off the track" state is indicated by a value of 0. 
      0x00 means all sensors are off-track
  2) 0x05 means sending the steering messsege. 0x9c is 0b 1001 1100 which is the 2'complement of 0b 0110 0100,  decimal -100, 
      a hard left turning
  3) two bytes, first indicate the setting of acc, which with value 0x04. Second indicate the acc, be the greatest number 0x7F, decimal 127 

3.  1) code for ReadOneByteFromUART():

ReadOneByteFromUART:
  addi sp, sp, -12 /* save the callee-saved regs and use these */
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw r18, 8(sp)

  movia r16, 0x10001020 /*load base of data reg to r16 */

  READ_POLL:
    ldwio r17, 0(r16) /* Load from the JTAG */
    andi  r18, r17, 0x8000 /* Mask other bits */
    beq   r18, r0, READ_POLL /* If this is 0 (branch true), data is not valid */
  
  andi  r2, r17, 0x00FF /* Data read is now in r2, which is the return value */

  ldw r16, 0(sp) /* restore the callee-saved registers */
  ldw r17, 4(sp)
  ldw r18, 8(sp)
  addi sp, sp, 12

  ret

    
    2) code for WriteOneByteToUART(byte_to_write):

WriteOneByteToUART:
  addi sp, sp, -8 /* save the callee-saved regs and use these */
  stw r16, 0(sp)
  stw r17, 4(sp)

  movia r16, 0x10001020 /*load base of data reg to r16 */

  WRITE_POLL:
    ldwio r17, 4(r16) /* Load from the JTAG */
    srli  r17, r17, 16 /* Check only the write available bits */
    beq   r17, r0, WRITE_POLL /* If this is 0 (branch true), data cannot be sent */
  
  stwio r4, 0(r16) /* Write argument containinng the byte to the JTAG */


  ldw r16, 0(sp) /* restore the callee-saved registers */
  ldw r17, 4(sp)
  addi sp, sp, 8

  ret

4.  pseudo code here: 

OnePossibleAlgorithm:
  call ReadSensorsAndSpeed()
  
  # Decide what to do
  if sensors are 0x1f
    call SetSteering to steer straight
  else if sensors are 0x1e
    call SetSteering to steer right
  else if sensors are 0x1c
    call SetSteering to steer hard right
  else if sensors are 0x0f
    call SetSteering to steer left
  else if sensors are 0x07
    call SetSteering to steer hard left
  else
    Hope this doesn't happen

  # Also do something about the speed.

  ...  
  
ReadSensorsAndSpeed:
  /* all the code follows ABI */
  /* put the sensors value in r2 and speed data in r3 */

  addi sp, sp, -8
  stw ra 0(sp) /* nested procedure call need to save this */
  stw r16 4(sp)

  # Request sensors and speed: Send a 0x02.
  mov r4, 0x02
  call WriteOneByteToUART

  # Read the response
  call ReadOneByteFromUART
  bne r2, r0, EndReadSensorsAndSpeed /* check that data read is 0 */

  call ReadOneByteFromUART  
  mov r16, r2 /* look at sensor states */
  call ReadOneByteFromUART
  mov r3, r2 /* look at current speed */ 

  mov r2, r16

EndReadSensorsAndSpeed:
  ldw ra 0(sp)
  ldw r16 4(sp)
  addi sp, sp, 8
  ret



  
SetSteering:
  addi sp, sp, -8
  stw ra 0(sp) /* nested procedure call need to save this */
  stw r16 4(sp)

  mov r16, r4 /* save the passed here steering value */

  mov r4, 0x05
  call WriteOneByteToUART

  mov r4, r16
  call WriteOneByteToUART

  ldw ra 0(sp)
  ldw r16 4(sp)
  addi sp, sp, 8
  ret





