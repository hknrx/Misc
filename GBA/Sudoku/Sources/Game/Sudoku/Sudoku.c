/*
** Sudoku - Sources\Game\Sudoku\Sudoku.c
** Nicolas ROBERT [NRX] - France 2006
*/

////////////////
// Inclusions //
////////////////
#include "..\..\Common\Common.h"
#include "Sudoku.h"

////////////
// Macros //
////////////
#define SUDOKU_ALL_FLAGS ((1<<9)-1)

///////////
// Types //
///////////
typedef struct
{
   unsigned short flags[9*9];
   unsigned char constraints[9*9][(9-1)+(9-1)+(2*2)];
   unsigned char moves[9*9];
   unsigned char moveBegin,moveEnd;
   unsigned short difficulty;
}
Sudoku;

////////////////////////
// Variables globales //
////////////////////////
Sudoku sudoku;

////////////////
// SudokuInit //
////////////////
void CODE_IN_IWRAM SudokuInit(void)
{
   unsigned char x,y,otherX,otherY,dx,dy,cell,constraint;

   cell=0;
   for(y=0;y<9;++y)
   {
      dy=(y/3)*3;
      for(x=0;x<9;++x)
      {
         dx=(x/3)*3;

         constraint=0;

         for(otherX=0;otherX<9;++otherX)
            if(otherX!=x)
               sudoku.constraints[cell][constraint++]=otherX+y*9;

         for(otherY=0;otherY<9;++otherY)
            if(otherY!=y)
               sudoku.constraints[cell][constraint++]=x+otherY*9;

         for(otherY=dy;otherY<dy+3;++otherY)
            if(otherY!=y)
               for(otherX=dx;otherX<dx+3;++otherX)
                  if(otherX!=x)
                     sudoku.constraints[cell][constraint++]=otherX+otherY*9;

         ++cell;
      }
   }
}

////////////////////
// SudokuMovesAdd //
////////////////////
static unsigned char CODE_IN_IWRAM SudokuMovesAdd(void)
{
   unsigned char cell,otherCell;
   unsigned short flag,otherFlags;
   unsigned short constraint;

   while(sudoku.moveBegin<sudoku.moveEnd)
   {
      cell=sudoku.moves[sudoku.moveBegin++];
      flag=sudoku.flags[cell];
      for(constraint=0;constraint<20;++constraint)
      {
         otherCell=sudoku.constraints[cell][constraint];
         otherFlags=sudoku.flags[otherCell];
         if(otherFlags==flag)
            return(0);
         if(otherFlags&flag&SUDOKU_ALL_FLAGS)
         {
            otherFlags-=flag;
            sudoku.flags[otherCell]=otherFlags;
            if((otherFlags>>9)==1)
               sudoku.moves[sudoku.moveEnd++]=otherCell;
         }
      }
   }
   return(1);
}

///////////////////////
// SudokuMovesRemove //
///////////////////////
static void CODE_IN_IWRAM SudokuMovesRemove(unsigned char generate)
{
   unsigned char moveBegin;
   unsigned char cell,otherCell;
   unsigned short flag,flags,otherFlags;
   unsigned short constraint,otherConstraint;



for(sudoku.moveEnd=0;sudoku.moveEnd<sudoku.moveBegin;++sudoku.moveEnd)
   sudoku.flags[sudoku.moves[sudoku.moveEnd]]|=1<<15;
sudoku.moveBegin=0;
for(cell=0;cell<9*9;++cell)
   if(sudoku.flags[cell]&(1<<15))
{
if(generate)
++sudoku.difficulty;
else
      sudoku.flags[cell]&=~(1<<15);
}
   else
      sudoku.flags[cell]=(9<<9)+SUDOKU_ALL_FLAGS;
SudokuMovesAdd();
return;



   // Marque les coups
   moveBegin=sudoku.moveBegin;
   while(moveBegin<sudoku.moveEnd)
      sudoku.flags[sudoku.moves[moveBegin++]]|=1<<15;

   // Supprime les coups
   while(sudoku.moveBegin<sudoku.moveEnd)
   {
      cell=sudoku.moves[--sudoku.moveEnd];
      flag=sudoku.flags[cell]&~(1<<15);
      flags=(9<<9)+SUDOKU_ALL_FLAGS;
      for(constraint=0;constraint<20;++constraint)
      {
         otherCell=sudoku.constraints[cell][constraint];
         otherFlags=sudoku.flags[otherCell];
         if(otherFlags&(1<<15))
            continue;
         if((otherFlags>>9)==1)
         {
            if(otherFlags&flags&SUDOKU_ALL_FLAGS)
               flags-=otherFlags;
         }
         else if(!(otherFlags&flag&SUDOKU_ALL_FLAGS))
         {
            for(otherConstraint=0;otherConstraint<20;++otherConstraint)
               if(sudoku.flags[sudoku.constraints[otherCell][otherConstraint]]==flag)
                  break;
            if(otherConstraint==20)
               sudoku.flags[otherCell]=otherFlags+flag;
         }
      }
      if(generate)
      {
         sudoku.difficulty+=flags>>9;
         flags|=1<<15;
      }
      sudoku.flags[cell]=flags;
   }
}

///////////////////////////
// SudokuMovesSearchNext //
///////////////////////////
static unsigned char CODE_IN_IWRAM SudokuMovesSearchNext(unsigned char* bestCell)
{
   unsigned short possibilities,lowestPossibilities;
   unsigned char cell;

   lowestPossibilities=10;
   for(cell=0;cell<9*9;++cell)
   {
      possibilities=sudoku.flags[cell]>>9;
      if(possibilities>1 && possibilities<lowestPossibilities)
      {
         lowestPossibilities=possibilities;
         *bestCell=cell;
      }
   }
   return(lowestPossibilities<10);
}

//////////////////////////
// SudokuMovesSearchAll //
//////////////////////////
static unsigned char CODE_IN_IWRAM SudokuMovesSearchAll(unsigned char options)
{
   unsigned char bestCell;
   unsigned char solved;
   unsigned char moveCurrent;
   unsigned short flag,flags;
   unsigned char result;

   // Resolution primaire
   if(!SudokuMovesAdd())
      return(SUDOKU_RESULT_IMPOSSIBLE);

   // Termine ?
   if(sudoku.moveEnd==9*9)
      return(SUDOKU_RESULT_SOLVED);

   // Continue de jouer (on joue la ou il y a le moins de possibilites)
   if(SudokuMovesSearchNext(&bestCell))
   {
      solved=0;
      moveCurrent=sudoku.moveBegin;
      flags=sudoku.flags[bestCell]&SUDOKU_ALL_FLAGS;
      for(flag=1;flag<=flags;flag<<=1)
         if(flags&flag)
         {
            sudoku.flags[bestCell]=(1<<9)+flag;
            sudoku.moves[sudoku.moveEnd++]=bestCell;
            result=SudokuMovesSearchAll(options);
            if(result!=SUDOKU_RESULT_IMPOSSIBLE)
            {
               if(!(options&SUDOKU_OPTION_CHECK_UNIQUE))
                  return(SUDOKU_RESULT_SOLVED);
               if(solved || result==SUDOKU_RESULT_NOT_UNIQUE)
                  return(SUDOKU_RESULT_NOT_UNIQUE);
               solved=1;
            }
            sudoku.moveBegin=moveCurrent;
            SudokuMovesRemove(0);
         }
      if(solved)
         return(SUDOKU_RESULT_SOLVED);
   }

   // On abandonne
   return(SUDOKU_RESULT_IMPOSSIBLE);
}

//////////////////////
// SudokuGridUpdate //
//////////////////////
static void CODE_IN_IWRAM SudokuGridUpdate(unsigned char* grid)
{
   unsigned char cell;
   unsigned short flags;
   unsigned short value;

   for(cell=0;cell<9*9;++cell)
   {
      flags=sudoku.flags[cell];
      if((flags>>9)!=1)
         grid[cell]=0;
      else
      {
         for(value=1;!(flags&1);++value,flags>>=1);
         grid[cell]=value;
      }
   }
}

///////////////////////
// SudokuGridPrepare //
///////////////////////
static void CODE_IN_IWRAM SudokuGridPrepare(unsigned char cellOrigin)
{
   unsigned char value;
   unsigned char trigger;
   unsigned char cell,cellChange;

   for(value=9;value;--value)
   {
      trigger=rand()%value;
      cell=cellOrigin;
      cellChange=3;
      while(1)
      {
         if((sudoku.flags[cell]>>9)>1)
            if(!trigger--)
            {
               sudoku.flags[cell]=(1<<9)+(1<<(value-1));
               sudoku.moves[sudoku.moveEnd++]=cell;
               break;
            }
         if(--cellChange)
            ++cell;
         else
         {
            cell+=9-2;
            cellChange=3;
         }
      }
   }
}

/////////////////////
// SudokuGridSolve //
/////////////////////
unsigned short CODE_IN_IWRAM SudokuGridSolve(unsigned char* grid,unsigned char options)
{
   unsigned char cell;
   unsigned char value;

   // Initialisation
   sudoku.moveBegin=0;
   sudoku.moveEnd=0;
   sudoku.difficulty=0;
   for(cell=0;cell<9*9;++cell)
   {
      value=grid[cell];
      if(value)
      {
         sudoku.flags[cell]=(1<<9)+(1<<(value-1));
         sudoku.moves[sudoku.moveEnd++]=cell;
      }
      else
         sudoku.flags[cell]=(9<<9)+SUDOKU_ALL_FLAGS;
   }

   // Resolution de la grille
   if(SudokuMovesSearchAll(options)!=SUDOKU_RESULT_IMPOSSIBLE)
   {
      // Mise a jour de la grille
      if(options&SUDOKU_OPTION_UPDATE_GRID)
         SudokuGridUpdate(grid);
   }

   // Retourne la difficulte
   return(sudoku.difficulty);
}

////////////////////////
// SudokuGridGenerate //
////////////////////////
unsigned short CODE_IN_IWRAM SudokuGridGenerate(unsigned char* grid,unsigned short difficulty)
{
   unsigned char cell;

   // Nettoyage de la grille
   for(cell=0;cell<9*9;++cell)
      sudoku.flags[cell]=(9<<9)+SUDOKU_ALL_FLAGS;

   // Generation de la grille
   sudoku.moveBegin=0;
   sudoku.moveEnd=0;

   SudokuGridPrepare(0);
   SudokuGridPrepare(3+3*9);
   SudokuGridPrepare(6+6*9);

   SudokuMovesSearchAll(SUDOKU_OPTION_NONE);

   // Supprime certains coups (en respectant la symetrie de la grille)
   sudoku.difficulty=0;
   while(sudoku.difficulty<difficulty)
   {
      cell=rand()%41;
      if(sudoku.flags[cell]&(1<<15))
         continue;
      sudoku.moves[--sudoku.moveBegin]=cell;
      if(cell!=40)
         sudoku.moves[--sudoku.moveBegin]=80-cell;
      SudokuMovesRemove(1);
   }

   // Mise a jour de la grille
   SudokuGridUpdate(grid);

   // Retourne la difficulte reelle
   return(sudoku.difficulty);
}
