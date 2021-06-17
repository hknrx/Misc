/*
** Sudoku - Sources\Game\Sudoku\Sudoku.h
** Nicolas ROBERT [NRX] - France 2006
*/

#ifndef SUDOKU_H
#define SUDOKU_H

////////////////
// Inclusions //
////////////////

////////////
// Macros //
////////////
#define SUDOKU_OPTION_NONE         0
#define SUDOKU_OPTION_UPDATE_GRID  1
#define SUDOKU_OPTION_CHECK_UNIQUE 2

#define SUDOKU_RESULT_IMPOSSIBLE 0
#define SUDOKU_RESULT_SOLVED     1
#define SUDOKU_RESULT_NOT_UNIQUE 2

////////////////
// Prototypes //
////////////////
void CODE_IN_IWRAM SudokuInit(void);
unsigned short CODE_IN_IWRAM SudokuGridSolve(unsigned char* grid,unsigned char options);
unsigned short CODE_IN_IWRAM SudokuGridGenerate(unsigned char* grid,unsigned short difficulty);

#endif // SUDOKU_H
