#include <stdlib.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
/*
1. We are using 7 type of blocks, they are numbered in sequence
2. 2 implies it is the center, 1 means the one should change during the rotation
3. the stopped blocks at button will be marked like 3, empty is 0
*/

/*  The format of the blocks
22  2      2    2    2    2
32  322  223   232   32  32  2322
                      2  2
*/
void randomInit() {
  srand(time(NULL));
}

// board_addr, the address of the board
// typeIndex is the block type that you want to add
// The default starting point of "2" is (4, 1)
int insertType(int* board_addr, int typeIndex) {
  printf("Type: %i\n",typeIndex);
  int x0 = 4;
  int y0 = 2;
  int* center = board_addr + y0*10 + x0;
  *center = 3;
  switch (typeIndex) {
    case 0:
      *(center-10) = 2;
      *(center+1) = 2;
      *(center-9) = 2;
      break;
    case 1:
      *(center-10) = 2;
      *(center+1) = 2;
      *(center+2) = 2;
      break;
    case 2:
      *(center-10) = 2;
      *(center-1) = 2;
      *(center-2) = 2;
      break;
    case 3:
      *(center-10) = 2;
      *(center+1) = 2;
      *(center-1) = 2;
      break;
    case 4:
      *(center-10) = 2;
      *(center+1)  = 2;
      *(center+11) = 2;
      break;
    case 5:
      *(center-9) = 2;
      *(center+1) = 2;
      *(center+10) = 2;
      break;
    case 6:
      *(center-1) = 2;
      *(center+1) = 2;
      *(center+2) = 2;
      break;
  }
  return 0;
}

void setLose(int* gamestate) {
  *gamestate = -1;
}

void createNewBlock(int* board_addr, int* gamestate) {
  // the game is not running, already win or lose
  if (*gamestate != 0) {
    return;
  }
  // randonly generate the block type
  int type = rand()%7;
  int result = insertType(board_addr, type);
  // if cannot add a new block, gameover
  if (result == -1) {
    setLose(gamestate);
  }
}

void copy_board(int* new_board, int* board_addr) {
  int i;
  for (i=0; i<240; i++) {
    new_board[i] = board_addr[i];
  }
}

void remove_falling_block(int* board_addr) {
  int i;
  for (i = 0; i<240; i++) {
    if (board_addr[i] > 1) board_addr[i] = 0;
  }
}

/* cell types:
0 - empty block
1 - taken block
2 - falling figure
3 - center of the figure
*/

void move_block(int* board_addr, int direction) {
  // 0   1  2   3
  // left up down right

  int temp_board[240]={0};
  int i;
  int valid = 1;
  int x_min = 10;
  int x_max = -1;
  // check x the min and max of block
  for (int i=0; i<240; i++) {
    if ( *(board_addr+i) > 1 && *(board_addr+i) < 4) {
      int x = i%10;
      // update the min and max
      if (x_min > x) x_min = x;
      if (x_max < x) x_max = x;

      // if on the boundary and coresbonding move is invalid
      if (x_min == 0 && direction == 1) return;
      if (x_max == 9 && direction == 3) return;
    }
  }

  // collision checking
  for (int i=0; i<240; i++) {
    if ( *(board_addr+i) > 1 && *(board_addr+i) < 4) {
      if (direction == 0) {
        if ( *(board_addr+i-1)<2) return;
      } else if (direction == 3) {
        if ( *(board_addr+i+1)<2) return;
      }
    }
  }

  // things are valid, move the block
  copy_board(temp_board, board_addr);
  remove_falling_block(temp_board);

  for (int i=0; i<240; i++) {
    if ( *(board_addr+i) > 1 && *(board_addr+i) < 4) {
      if (direction == 0) {
        temp_board[i-1] = board_addr[i];
      } else if (direction == 3) {
        temp_board[i+1] = board_addr[i];
      }
    }
  }
}
