/*
** Sudoku - Sources\Game\Game.c
** Nicolas ROBERT [NRX] - France 2006
*/

////////////////
// Inclusions //
////////////////
#include "..\Common\Common.h"
#include "Sudoku\Sudoku.h"

////////////
// Macros //
////////////
#define COUNT      1000 // 1000
#define GRID       3
#define DIFFICULTY 20

///////////
// Types //
///////////

////////////////////////
// Variables globales //
////////////////////////

/////////////////////
// GameDisplayGrid //
/////////////////////
static void GameDisplayGrid(unsigned char* grid)
{
   unsigned short* screen;
   unsigned char cell;
   unsigned char x,y;

   screen=(unsigned short*)SCREEN_BASE_BLOCK(28);
   cell=0;
   for(y=0;y<9;++y)
      for(x=0;x<9;++x)
         screen[x+(x/3)+((y+(y/3))<<5)]=grid[cell++]+'0'-' ';
}

///////////////////////
// GameDisplayNumber //
///////////////////////
static void GameDisplayNumber(unsigned short number,unsigned char x,unsigned char y)
{
   unsigned short* screen;

   screen=(unsigned short*)SCREEN_BASE_BLOCK(28)+x+(y<<5);
   do
   {
      *screen=(number%10)+'0'-' ';
      number=number/10;
      --screen;
   }
   while(number);
   *screen=0;
}

///////////////////
// GameSolveGrid //
///////////////////
static void GameSolveGrid(unsigned char* grid)
{
   unsigned short timer;
   unsigned short count;
   unsigned short difficulty;

   // Resolutions : d'abord N fois sans mise a jour de la grille, puis 1 fois avec mise a jour
   timer=commonVblCounter;
   for(count=0;count<COUNT;++count)
      SudokuGridSolve(grid,SUDOKU_OPTION_NONE);
   timer=commonVblCounter-timer;

   difficulty=SudokuGridSolve(grid,SUDOKU_OPTION_UPDATE_GRID);

   // Affichage de la grille resolue
   GameDisplayGrid(grid);

   // Affichage du chrono
   GameDisplayNumber(timer,10,17);

   // Affichage de la difficulte
   GameDisplayNumber(difficulty,10,19);
}

//////////////
// GameMain //
//////////////
void GameMain(void)
{
   unsigned char test;
   unsigned char grid[][9][9]=
   {
      // #0 = Empty
      {
         {0,0,0, 0,0,0, 0,0,0},
         {0,0,0, 0,0,0, 0,0,0},
         {0,0,0, 0,0,0, 0,0,0},

         {0,0,0, 0,0,0, 0,0,0},
         {0,0,0, 0,0,0, 0,0,0},
         {0,0,0, 0,0,0, 0,0,0},

         {0,0,0, 0,0,0, 0,0,0},
         {0,0,0, 0,0,0, 0,0,0},
         {0,0,0, 0,0,0, 0,0,0}
      },
      // #1 = Completed
      {
         {1,2,3, 4,5,6, 7,8,9},
         {4,5,6, 7,8,9, 1,2,3},
         {7,8,9, 1,2,3, 4,5,6},

         {2,3,1, 6,7,4, 8,9,5},
         {8,7,5, 9,1,2, 3,6,4},
         {6,9,4, 5,3,8, 2,1,7},

         {3,1,7, 2,6,5, 9,4,8},
         {5,4,2, 8,9,7, 6,3,1},
         {9,6,8, 3,4,1, 5,7,2}
      },
      // #2 = Real grid (easy)
      {
         {0,1,0, 8,0,0, 7,0,0},
         {0,0,0, 3,0,1, 8,0,2},
         {6,8,3, 7,0,0, 9,0,0},

         {0,7,0, 0,0,0, 6,2,4},
         {0,0,0, 0,0,0, 0,0,0},
         {4,3,1, 0,0,0, 0,9,0},

         {0,0,9, 0,0,2, 1,6,8},
         {8,0,7, 4,0,3, 0,0,0},
         {0,0,2, 0,0,8, 0,7,0}
      },
      // #3 = Real grid (difficult)
      {
         {0,0,0, 8,1,9, 0,0,0},
         {0,0,1, 0,0,0, 3,0,0},
         {0,2,0, 0,7,0, 0,8,0},

         {4,0,0, 0,0,0, 0,0,2},
         {3,0,6, 0,0,0, 8,0,9},
         {7,0,0, 0,0,0, 0,0,5},

         {0,8,0, 0,2,0, 0,7,0},
         {0,0,9, 0,0,0, 6,0,0},
         {0,0,0, 4,6,3, 0,0,0}
      },
      // #4 = Wrong (from the beginning)
      {
         {0,0,0, 0,1,0, 0,0,0},
         {0,3,0, 0,0,0, 0,3,0},
         {0,0,0, 0,0,0, 0,0,0},

         {0,0,0, 4,0,4, 0,0,0},
         {2,0,0, 0,0,0, 0,0,2},
         {0,0,0, 4,0,4, 0,0,0},

         {0,0,0, 0,0,0, 0,0,0},
         {0,3,0, 0,0,0, 0,3,0},
         {0,0,0, 0,1,0, 0,0,0}
      },
      // #5 = Wrong (later)
      {
         {1,2,3, 4,5,6, 7,8,9},
         {0,0,0, 2,1,0, 0,0,0},
         {0,0,0, 0,0,0, 0,0,1},

         {0,1,0, 0,0,0, 0,2,0},
         {0,0,0, 1,0,0, 0,0,0},
         {0,0,0, 0,0,0, 1,0,0},

         {0,0,1, 0,0,0, 2,0,0},
         {0,0,0, 0,0,1, 0,0,0},
         {0,0,0, 0,0,0, 0,1,0}
      },
      // #6 = Free test #1
      {
         {0,0,0, 6,3,0, 5,0,0},
         {0,9,6, 0,0,8, 1,0,0},
         {0,0,0, 0,0,0, 0,6,3},

         {0,2,0, 0,0,3, 0,8,0},
         {4,0,0, 2,8,1, 0,0,9},
         {0,3,0, 9,0,0, 0,2,0},

         {9,4,0, 0,0,0, 0,0,0},
         {0,0,1, 8,0,0, 3,4,0},
         {0,0,2, 0,5,4, 0,0,0}
      },
      // #7 = Free test #2
      {
         {0,0,0, 0,0,0, 0,6,8}, // 0,0,3, ...
         {0,0,0, 5,0,0, 1,0,2},
         {0,0,0, 0,3,0, 7,0,0},

         {6,0,1, 0,8,0, 0,2,9},
         {0,0,0, 0,0,0, 0,0,0},
         {7,9,0, 0,6,0, 3,0,1},

         {0,0,2, 1,0,0, 0,0,0},
         {8,0,5, 0,0,9, 0,0,0},
         {1,6,0, 0,0,0, 0,0,0}
      }
   };

   // Mise en place de l'affichage
   REG_DISPCNT=BG0_ENABLE;

   // Initialisation du Sudoku
   SudokuInit();

   // On teste des grilles pre-etablies
   for(test=0;test<8;++test)
   {
      // Resolution
      GameDisplayNumber(test,0,19);
      GameSolveGrid((unsigned char*)grid[test]);

      // Petite pause
      while(REG_KEYS&KEY_A);
      while(!(REG_KEYS&KEY_A));
   }

   // Initialise le generateur de nombres aleatoires
   srand(commonVblCounter);

   // Generation d'une grille
   GameDisplayNumber(0,0,19);
   GameDisplayNumber(SudokuGridGenerate((unsigned char*)grid[0],DIFFICULTY),10,19);
   GameDisplayGrid((unsigned char*)grid[0]);

   // Petite pause
   while(REG_KEYS&KEY_A);
   while(!(REG_KEYS&KEY_A));

   // Resolution(s) de cette grille
   GameSolveGrid((unsigned char*)grid[0]);

   // On s'arrete la...
   while(1)
      CommonVwait(0);
}
