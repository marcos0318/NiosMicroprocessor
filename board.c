#include <stdlib.h>
void randomInit() {
  srand(time(NULL));
}
/*
1. We are using 7 type of blocks, they are numbered in sequence
2. 2 implies it is the center, 1 means the one should change during the rotation
3. the stopped blocks at button will be marked like 3, empty is 0
*/
/*  The format of the blocks
11  1      1    1    1    1
21  211  112   121   21  21  1211
                      1  1
*/

// board_addr, the address of the board
// typeIndex is the block type that you want to add
// The default starting point of "2" is (4, 1)
int insertType(int* board_addr, int typeIndex) {
  int x0 = 4;
  int y0 = 1;
  int* center = board_addr + y0*10 + x0;
  *center = 2;
  switch (typeIndex) {
    case 0:
      *(center-10) = 1;
      *(center+1) = 1;
      *(center-9) = 1;
      break;
    case 1:
      *(center-10) = 1;
      *(center+1) = 1;
      *(center+2) = 1;
      break;
    case 2:
      *(center-10) = 1;
      *(center-1) = 1;
      *(center-2) = 1;
      break;
    case 3:
      *(center-10) = 1;
      *(center+1) = 1;
      *(center-1) = 1;
      break;
    case 4:
      *(center-10) = 1;
      *(center+1) = 1;
      *(center+11) = 1;
      break;
    case 5:
      *(center-9) = 1;
      *(center+1) = 1;
      *(center+2) = 1;
      break;
    case 6:
      *(center-10) = 1;
      *(center+1) = 1;
      *(center+10) = 1;
      break;
  }

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