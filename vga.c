#include <stdio.h>
#include "vga.h"
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

/* cell types:
0 - empty block
1 - taken block
2 - falling figure
3 - center of the figure
*/


/*the print screen function takes the address of the game board 
and print it to the VGA out put by using write block function*/
// 320 = 107*3 -1, just take 100 as the offset of x
int mockBoard[240] = {
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,2,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,1,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,2,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,1,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,3,0,0,0,0,
  0,0,0,0,0,3,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,
};



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

void print_gameboard(int* board_addr) {
  printf("print_gameboard %i",board_addr);
  int x, y;
  for (y=0; y<24; y++) {
    for (x=0; x<10; x++) {
      if (*board_addr == 1)
        print_block(x*10 + 100, y*10, 0xffcc);
      else if (*board_addr == 0)
        print_block(x*10 + 100, y*10, 0xffff);
      else if (*board_addr == 2)
        print_block(x*10 + 100, y*10, 0xf800);
      else if (*board_addr == 3)
		print_block(x*10 + 100, y*10, 0x0fff); // center
      board_addr++;
    }
  }
  return;
}


/* use write_pixel to set entire screen to black (does not clear the character buffer) */
void clear_screen() {

  //int x, y;
  //for (x = 0; x < 320; x++) {
  //for (y = 0; y < 240; y++) {
	 //write_pixel(x,y,0xf800);
	  
	//}
  //
  print_gameboard(mockBoard);
}

// checks if block underneath is occupied and by what
int block_below(int* board_addr, int block) {
	if(block >= 230) // bottom of the screen
		return 1; // block below is taken
	return board_addr[block+10];
}

int is_clear(int* board_addr) {
	// check that for each falling part the block below is either also falling or empty
	int i;
	for(i=0;i<240;i++) {
		if(board_addr[i] >= 2) {
			int below = block_below(board_addr, i);
			if(below == 1) {
				return 0;
			}
		}
	}
	return 1;
}
void copy_board(int* new_board, int* board_addr) {
	int i;
	for(i=0;i<240;i++) {
		new_board[i] = board_addr[i];
	}
}
int descend(int* board_addr){
	printf("descend %i\n",board_addr);
	if(is_clear(board_addr) == 0) {
		return 0;
	}
	printf("clear");
	int i;
	int temp_board[240];
	for(i=0;i<240;i++) temp_board[i]=0;
	//copy_board(temp_board,board_addr);

	for(i=0; i<240;i++) {
		if(board_addr[i] >= 2) {
			temp_board[i+10] = board_addr[i];
		}
		else if(temp_board[i] == 0) {
			temp_board[i] = board_addr[i];
		}
	}
	copy_board(board_addr,temp_board);
	print_gameboard(board_addr);
	return 1;
}
void storeBlock(int* board) {
	int i=0;
	for(i=0;i<240;i++)
	{
		if(board[i] >= 2) board[i]=1;
	}
	return;
}
