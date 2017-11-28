#include <stdlib.h>
void randomInit() {
  srand(time(NULL)); 
}

// We are using 7 type of blocks, they are numbered in sequence
/* 
  21
  11
  
  1
  211
  
    1
  112

   1
  121

  1
  21
   1

   1
  21
  1
  
  1211
*/
void createNewBlock(int* board_addr, int* gamestate) {
  if (*gamestate != 0) {
    // the game is not running, already win or lose
    return;
  }
}

void checkType(int* board_addr, int typeIndex) {
  
}

void setLose(int* gamestate) {
  *gamestate = -1;
}