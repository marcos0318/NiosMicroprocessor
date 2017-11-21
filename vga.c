#include <stdio.h>
#define ADDR_VGA 0x08000000

void printOct ( int val ) { printf ("%o\n", val); }

void printHex ( int val ) { printf ("%X\n", val); } 

void printDec ( int val ) { printf ("%u\n", val); }

/* set a single pixel on the screen at x,y
 * x in [0,319], y in [0,239], and colour in [0,65535]
 */




void write_pixel(int x, int y, short colour) {
  volatile short *vga_addr=(volatile short*)(ADDR_VGA + (y<<10) + (x<<1));
  *vga_addr=colour;
  return;
}


/* use write_pixel to set entire screen to black (does not clear the character buffer) */
void clear_screen() {
  int x, y;
  for (x = 0; x < 320; x++) {
    for (y = 0; y < 240; y++) {
	  write_pixel(x,y,0xf800);
	  
	}
 }
}


/*the print screen function takes the address of the game board 
and print it to the VGA out put by using write block function*/
// 320 = 107*3 -1, just take 100 as the offset of x
 
void print_gameboard(int* board_addr) {
  int x, y;
  for (x=0; x<10; x++) {
    for (y=0; y<24; y++) {
      if (*board_addr == 1)
        print_block(x*10 + 100, y*10, 0x66ffcc);
      else if (*board_addr == 0);
        print_block(x*10 + 100, y*10, 0);
      else if (*board_addr == 2)
        print_block(x*10 + 100, y*10, 0x11f800);
      board_addr++;
    }
  }
}

/* we have board as 24*10. the height of the screen is 240
then the size of a single block is 10*10, so we scale the block
position by ten*/
void print_block(int a, int b, short colour) {
  int x, y;
  for (x=0; x<9; x++) {
    for (y=0; y<9; y++) {
      write_pixel(a+x, b+y, colour);
    }
  }
}
