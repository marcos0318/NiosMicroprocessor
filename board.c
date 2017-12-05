#include <stdlib.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include "vga.h"
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
  float n = time(NULL);
  printf("%.2f\n" , n);
  srand(time(NULL));
}

// board_addr, the address of the board
// typeIndex is the block type that you want to add
// The default starting point of "2" is (4, 1)
int insertType(int* board_addr, int typeIndex) {
  printf("Type: %i\n",typeIndex);
  int x0 = 4;
  int y0 = 1;
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

// 240 means cannot find a center
int find_center (int* gameboard) {
  int i;
  for (i=0; i<240; i++) {
    if (gameboard[i] == 3) {
      return i;
    }
  }
  return 240;
}

// returns 240 when it is out of boundary
// returns the block number after rotate clockwise
int rotate_from (int center, int block) {
  int center_x = center % 10;
  int center_y = center / 10;
  int block_x = block % 10;
  int block_y = block / 10;
  int vector_x = block_x - center_x;
  int vector_y = block_y - center_y;
  int after_x = center_x + vector_y;
  int after_y = center_y - vector_x;
  // if after the rotate the things get out of the scope
  if (after_x < 0 || after_x > 9 || after_y < 0 || after_y > 23) {
    return 240;
  }
  return after_y * 10 + after_x;
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
  // left rotate down right
  printf("%d\n", direction);
  int temp_board[240]={0};
  int center;
  int i;
  int valid = 1;
  int x_min = 10;
  int x_max = -1;
  center = find_center(board_addr);
  if (center == 240) {
    printf("There is no center in the board\n");
    return;
  }

  // check x the min and max of block
  for (i=0; i<240; i++) {
    if ( *(board_addr+i) > 1 && *(board_addr+i) < 4) {
      int x = i%10;
      // update the min and max
      if (x_min > x) x_min = x;
      if (x_max < x) x_max = x;

      // if on the boundary and coresbonding move is invalid
      if (x_min == 0 && direction == 0) {
        return;
      }
      if (x_max == 9 && direction == 3) {
        return;
      }
    }
  }


  // collision checking
  for (i=0; i<240; i++) {
    if ( *(board_addr+i) > 1 && *(board_addr+i) < 4) {
      if (direction == 0) {
        if ( *(board_addr+i-1)==1){
          	return;
        }
      } else if (direction == 3) {
        if ( *(board_addr+i+1)==1){
          return;
        }
      } else if (direction == 1) {
        int new_block_num = rotate_from(center, i);
        if ( new_block_num == 240 ) {
          printf("rotate out of boundary\n");
          return;
        }
        if ( board_addr[new_block_num] == 1) {
          printf("rotate to a taken block\n");
          return;
        }
      }
    }
  }

  // things are valid, move the block
  copy_board(temp_board, board_addr);
  remove_falling_block(temp_board);

  for (i=0; i<240; i++) {
    if ( *(board_addr+i) > 1 && *(board_addr+i) < 4) {
      if (direction == 0) {
        temp_board[i-1] = board_addr[i];
      } else if (direction == 3) {
        temp_board[i+1] = board_addr[i];
      } else if (direction == 1) {
        int new_block_num = rotate_from(center, i);
        temp_board[new_block_num] = board_addr[i];
      }
    }
  }
  copy_board(board_addr, temp_board);
  print_gameboard(board_addr);
}

void zeroOutTakenUntil(int *board_addr, int line_number) {
  // line number is from 0 to 23
  int upper_bound = (line_number+1)* 10;
  int i;
  for (i = 0; i< upper_bound  ;i++) {
    if (board_addr[i] == 1) {
      board_addr[i] = 0;
    }
  }
}

int isLineFilled(int* board_addr, int line_number) {
  // line is from 0 to 23
  int filled == 1;
  int i;
  for (i = 0; i < 10; i++) {
    if (board_addr[line_number*10 + i] != 1) {
      filled == 0;
    }
  }
  return filled;
}

int moveDownTakenBy(int* board_addr, int line_number) {
  int local_board[240] = {0};
  copy_board(local_board, board_addr);
  zeroOutTakenUntil(local_board, line_number);
  int i;
  for (i=0; i< (line_number-1)*10; i++) {
    if (board_addr[i] == 1) {
      local_board[i+10] = 1;
    }
  }
  copy_board(board_addr, local_board);
}

void check_line_filled (int *board_addr) {
  int cleared_lines = 0;
  // we check from to to the end
  // if a line is all taken, o out that line, move the taken blocks above down by1
  // then add to the cleared_lines counter
  int i;
  for (i=0; i<24; i++) {
    if (isLineFilled(board_addr, i) == 1) {
      cleared_lines ++;
      moveDownTakenBy(board_addr, i);
    }
  }

  // then print the board

}
