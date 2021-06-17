/*
** God - Sources\World\AStar\AStar.h
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

#ifndef ASTAR_H
#define ASTAR_H

////////////////
// Inclusions //
////////////////
#include "..\..\Common\Common.h"

///////////
// Types //
///////////
typedef struct
{
   signed short idx;
   signed short start;
   unsigned short max;
   unsigned char* dir;
}
Path;

typedef struct
{
   signed short idx;
   unsigned short max;
   signed short* mapIdx;
}
Goal;

////////////////
// Prototypes //
////////////////
void AStarInit(unsigned char (*mapIsGround)(signed short),unsigned short mapWidthShift,unsigned short mapHeight);
void AStarDestroy(void);

Path* AStarPathInit(unsigned short size);
signed short CODE_IN_IWRAM AStarPathFind(signed short mapIdx,Goal* goal,Path* path);
signed short AStarPathMove(Path* path,signed short mapIdx);
void AStarPathRestore(Path* path);
void AStarPathDestroy(Path* path);

Goal* AStarGoalInit(unsigned short size);
signed short AStarGoalAdd(Goal* goal,signed short mapIdx);
signed short AStarGoalRemove(Goal* goal,signed short mapIdx);
inline void AStarGoalClean(Goal* goal);
void AStarGoalDestroy(Goal* goal);

#endif // ASTAR_H
