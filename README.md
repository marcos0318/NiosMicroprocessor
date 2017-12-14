# Tetris Game Build on Nios Microprocessir

# run it:
The reference of the nios processor and its hardware configuration is here:
http://www-ug.eecg.utoronto.ca/desl/nios_devices_SoC/
The actual device is install in the lab in Bahen building, Universisty of Toronto. \\
You can compile the program with FPGA and run it on the online simulator
compile the code and send the .elf file to the simulator
http://cpulator.01xz.net/

# The configuration of compilation:
* Choosing C program instead of Assembly.
* Choose option indicating there is an exception handler. 
* Remember the default size allocated for the ISR (interrupt serivce routine), may not be large enough. Just leave more memry for it.

# Specifications
* The project cuurently have three interrupts: timer interrupt, PS/2 keyboard interrupt and the push buttom interrupt
* The Seven Seg display will show your current score
* The number of LED lit up will indicate the game speed

# control and game details:
* W A S D for control, the push buttoms are for the adjustment of speed
* W for rotate
* A S D for move to corespnding direction
* When press S, the score increase by one.
* The rows reduce calculation is "The number of rows canceled together^2 * 100"


# need to improve:
* The color of the blocks



