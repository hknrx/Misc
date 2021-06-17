/*
** God - Sources\World\AStar\AStar.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "AStar.h"

////////////
// Macros //
////////////
#define ASTAR_OLD_NODE  -1
#define ASTAR_NEW_NODE  -2
#define ASTAR_GOAL_NODE -3

///////////
// Types //
///////////
typedef struct
{
   unsigned short f;
   unsigned short g;
   signed short closeIdx;
}
OpenNode;

typedef struct
{
   signed short mapIdx;
   signed short fromDir;
   signed short openIdx;
}
CloseNode;

typedef struct
{
   unsigned char (*mapIsGround)(signed short);

   unsigned short mapWidthShift;
   unsigned short mapWidthMask;

   signed short mapMove[4];

   signed short openIdx;
   unsigned short openMax;
   OpenNode* openNodes;

   signed short closeIdx;
   unsigned short closeMax;
   CloseNode* closeNodes;
   signed short* closeNodesDirectAddress;
}
AStar;

////////////////////////
// Variables globales //
////////////////////////
AStar astar;

///////////////////
// HeapArrangeUp //
///////////////////
signed short CODE_IN_IWRAM HeapArrangeUp(signed short openIdx,signed short closeIdx,unsigned short g,unsigned short h)
{
   unsigned short f;
   signed short openParentIdx;

   f=g+h;
   while(openIdx)
   {
      openParentIdx=(openIdx-1)>>1;
      if(f>=astar.openNodes[openParentIdx].f)
         break;
      astar.openNodes[openIdx]=astar.openNodes[openParentIdx];
      astar.closeNodes[astar.openNodes[openIdx].closeIdx].openIdx=openIdx;
      openIdx=openParentIdx;
   }
   astar.openNodes[openIdx].f=f;
   astar.openNodes[openIdx].g=g;
   astar.openNodes[openIdx].closeIdx=closeIdx;
   astar.closeNodes[closeIdx].openIdx=openIdx;

   return(openIdx);
}

//////////////
// HeapPush //
//////////////
inline signed short CODE_IN_IWRAM HeapPush(signed short closeIdx,unsigned short g,unsigned short h)
{
   if(astar.openIdx==astar.openMax)
      return(-1);

   return(HeapArrangeUp(astar.openIdx++,closeIdx,g,h));
}

////////////////
// HeapModify //
////////////////
inline signed short CODE_IN_IWRAM HeapModify(signed short openIdx,unsigned short g)
{
   if(openIdx<0 || openIdx>=astar.openIdx)
      return(-1);

   if(g>=astar.openNodes[openIdx].g)
      return(-1);

   return(HeapArrangeUp(openIdx,astar.openNodes[openIdx].closeIdx,g,astar.openNodes[openIdx].f-astar.openNodes[openIdx].g));
}

/////////////
// HeapPop //
/////////////
inline signed short CODE_IN_IWRAM HeapPop(unsigned short* g)
{
   signed short openIdx,closeIdx,openParentIdx;

   if(!astar.openIdx)
      return(-1);

   *g=astar.openNodes[0].g;
   closeIdx=astar.openNodes[0].closeIdx;
   astar.closeNodes[closeIdx].openIdx=ASTAR_OLD_NODE;

   --astar.openIdx;

   // Rearrange the heap (up -> down)
   openParentIdx=0;
   while((openIdx=(openParentIdx<<1)+1)<astar.openIdx)
   {
      if(astar.openNodes[openIdx+1].f<astar.openNodes[openIdx].f)
         ++openIdx;
      if(astar.openNodes[openIdx].f>=astar.openNodes[astar.openIdx].f)
         break;
      astar.openNodes[openParentIdx]=astar.openNodes[openIdx];
      astar.closeNodes[astar.openNodes[openParentIdx].closeIdx].openIdx=openParentIdx;
      openParentIdx=openIdx;
   }
   astar.openNodes[openParentIdx]=astar.openNodes[astar.openIdx];
   astar.closeNodes[astar.openNodes[openParentIdx].closeIdx].openIdx=openParentIdx;

   return(closeIdx);
}

/////////////////////////
// DirectAddressInsert //
/////////////////////////
inline signed short CODE_IN_IWRAM DirectAddressInsert(signed short mapIdx,signed short openIdx)
{
   if(astar.closeIdx==astar.closeMax)
      return(-1);

   astar.closeNodes[astar.closeIdx].mapIdx=mapIdx;
   astar.closeNodes[astar.closeIdx].openIdx=openIdx;
   astar.closeNodesDirectAddress[mapIdx]=astar.closeIdx;

   return(astar.closeIdx++);
}

///////////////////////
// DirectAddressFind //
///////////////////////
inline signed short CODE_IN_IWRAM DirectAddressFind(signed short mapIdx)
{
   signed short closeIdx;

   if((closeIdx=astar.closeNodesDirectAddress[mapIdx])<astar.closeIdx)
      if(astar.closeNodes[closeIdx].mapIdx==mapIdx)
         return(closeIdx);

   return(-1);
}

///////////////
// AStarInit //
///////////////
void AStarInit(unsigned char (*mapIsGround)(signed short),unsigned short mapWidthShift,unsigned short mapHeight)
{
   unsigned short mapWidth;

   astar.mapIsGround=mapIsGround;

   mapWidth=1<<mapWidthShift;
   astar.mapWidthShift=mapWidthShift;
   astar.mapWidthMask=mapWidth-1;

   astar.mapMove[0]=1;
   astar.mapMove[1]=mapWidth;
   astar.mapMove[2]=-mapWidth;
   astar.mapMove[3]=-1;

   astar.openMax=(mapWidth+mapHeight)<<1;
   astar.openNodes=(OpenNode*)malloc(astar.openMax*sizeof(OpenNode));

   astar.closeMax=mapHeight<<(mapWidthShift-1);
   astar.closeNodes=(CloseNode*)malloc(astar.closeMax*sizeof(CloseNode));
   astar.closeNodesDirectAddress=(signed short*)malloc((mapHeight<<mapWidthShift)*sizeof(signed short));
}

//////////////////
// AStarDestroy //
//////////////////
void AStarDestroy(void)
{
   free(astar.openNodes);
   free(astar.closeNodes);
   free(astar.closeNodesDirectAddress);
}

////////////////////
// AStarHeuristic //
////////////////////
inline unsigned short CODE_IN_IWRAM AStarHeuristic(signed short mapIdx,Goal* goal)
{
   unsigned short h,distance;
   signed short goalIdx;
   signed short x,y,deltaX,deltaY;

   // Take each of the goals and find the nearest one...
   // Note: it behaves like Dijkstra's algorithm when no goal is provided (h=constant)
   h=0xFFFF;

   x=mapIdx&astar.mapWidthMask;
   y=mapIdx>>astar.mapWidthShift;

   goalIdx=goal->idx;
   while(goalIdx--)
   {
      mapIdx=goal->mapIdx[goalIdx];

      // Compute the distance from the current location to the goal
      if((deltaX=x-(mapIdx&astar.mapWidthMask))<0)
         deltaX=-deltaX;
      if((deltaY=y-(mapIdx>>astar.mapWidthShift))<0)
         deltaY=-deltaY;
      distance=deltaX+deltaY;

      // Take the shortest way (smallest distance)
      if(h>distance)
         h=distance;
   }
   return(h);
}

///////////////////
// AStarPathInit //
///////////////////
Path* AStarPathInit(unsigned short size)
{
   Path* path=(Path*)malloc(sizeof(Path));

   path->idx=0;
   path->start=0;
   size=(size+3)>>2; // We store the direction on 2 bits => 4 directions per byte
   path->max=size<<2;
   path->dir=(unsigned char*)malloc(size*sizeof(unsigned char));

   return(path);
}

/////////////////////
// AStarPathCreate //
/////////////////////
inline signed short CODE_IN_IWRAM AStarPathCreate(Path* path,unsigned char dir,signed short mapIdx)
{
   signed char fromDir;
   unsigned char byteValue,byteIdx,bitIdx;
   signed short idx;

   byteValue=dir;
   byteIdx=0;
   bitIdx=0;

   idx=0;
   while(idx++<path->max)
   {
      if((fromDir=astar.closeNodes[DirectAddressFind(mapIdx)].fromDir)==-1)
      {
         path->dir[byteIdx]=byteValue;
         path->idx=idx;
         path->start=idx;
         return(0);
      }

      mapIdx+=astar.mapMove[fromDir];
      dir=3-fromDir;

      if(bitIdx<6)
      {
         bitIdx+=2;
         byteValue|=dir<<bitIdx;
      }
      else
      {
         path->dir[byteIdx++]=byteValue;
         bitIdx=0;
         byteValue=dir;
      }
   }
   path->idx=0;
   path->start=0;
   return(-1);
}

///////////////////
// AStarPathFind //
///////////////////
signed short CODE_IN_IWRAM AStarPathFind(signed short mapIdx,Goal* goal,Path* path)
{
   unsigned short g;
   signed char dir,fromDir;
   signed short goalIdx,openIdx,closeIdx,newMapIdx;

   // Reset "open" & "close"
   astar.openIdx=0;
   astar.closeIdx=0;

   // Register all the goals and check if we need to move
   goalIdx=goal->idx;
   if(!goalIdx)
      return(-1);
   while(goalIdx--)
   {
      newMapIdx=goal->mapIdx[goalIdx];
      if(mapIdx==newMapIdx)
      {
         path->idx=0;
         path->start=0;
         return(0);
      }
      if(DirectAddressInsert(newMapIdx,ASTAR_GOAL_NODE)==-1)
         return(-1);
   }

   // Here is the very first node
   g=0;
   fromDir=-1;

   if((closeIdx=DirectAddressInsert(mapIdx,ASTAR_OLD_NODE))==-1)
      return(-1);
   astar.closeNodes[closeIdx].fromDir=fromDir;

   // Search
   while(g<path->max)
   {
      // Increment the cost
      ++g;

      // Look around
      for(dir=3;dir>=0;--dir)
      {
         // Do not move back!
         if(dir==fromDir)
            continue;

         // Move
         newMapIdx=mapIdx+astar.mapMove[dir];

         // Try to find this location in "close"
         if((closeIdx=DirectAddressFind(newMapIdx))!=-1)
         {
            openIdx=astar.closeNodes[closeIdx].openIdx;
            if(openIdx==ASTAR_OLD_NODE)
               continue;
            if(openIdx==ASTAR_GOAL_NODE)
            {
               // We've reached the goal, let's create the path and return the cost
               if(AStarPathCreate(path,dir,mapIdx)==-1)
                  return(-1);
               return(g);
            }
            if(HeapModify(openIdx,g)==-1)
               continue;
         }

         // Check we can walk here
         else if(!astar.mapIsGround(newMapIdx))
            continue;

         // That's a new location: insert it into both "close" and "open"
         else if((closeIdx=DirectAddressInsert(newMapIdx,ASTAR_NEW_NODE))==-1)
            return(-1);
         else if(HeapPush(closeIdx,g,AStarHeuristic(newMapIdx,goal))==-1)
            return(-1);

         // Save the direction in "close"
         astar.closeNodes[closeIdx].fromDir=3-dir;
      }

      // Get the best node from "open"
      if((closeIdx=HeapPop(&g))==-1)
         return(-1);
      mapIdx=astar.closeNodes[closeIdx].mapIdx;
      fromDir=astar.closeNodes[closeIdx].fromDir;
   }

   // Ouuups... there wouldn't be enough memory to store the path!
   return(-1);
}

///////////////////
// AStarPathMove //
///////////////////
signed short AStarPathMove(Path* path,signed short mapIdx)
{
   unsigned char byteIdx,bitIdx,dir;

   // Have we already reached the end of the path?
   if(!path->idx)
      return(-1);

   // Find the next direction
   --path->idx;
   byteIdx=path->idx>>2;
   bitIdx=(path->idx&3)<<1;
   dir=(path->dir[byteIdx]>>bitIdx)&3;

   // Follow the path: move according to the direction
   mapIdx+=astar.mapMove[dir];

   // Can we walk here?
   if(!astar.mapIsGround(mapIdx))
      return(-1);

   // That's our new location
   return(mapIdx);
}

//////////////////////
// AStarPathRestore //
//////////////////////
void AStarPathRestore(Path* path)
{
   path->idx=path->start;
}

//////////////////////
// AStarPathDestroy //
//////////////////////
void AStarPathDestroy(Path* path)
{
   free(path->dir);
   free(path);
}

///////////////////
// AStarGoalInit //
///////////////////
Goal* AStarGoalInit(unsigned short size)
{
   Goal* goal=(Goal*)malloc(sizeof(Goal));

   goal->idx=0;
   goal->max=size;
   goal->mapIdx=(signed short*)malloc(size*sizeof(signed short));

   return(goal);
}

//////////////////
// AStarGoalAdd //
//////////////////
signed short AStarGoalAdd(Goal* goal,signed short mapIdx)
{
   signed short idx;

   idx=goal->idx;

   if(idx==goal->max)
      return(-1);

   while(idx--)
      if(goal->mapIdx[idx]==mapIdx)
         return(idx);

   goal->mapIdx[goal->idx]=mapIdx;

   return(goal->idx++);
}

/////////////////////
// AStarGoalRemove //
/////////////////////
signed short AStarGoalRemove(Goal* goal,signed short mapIdx)
{
   signed short idx;

   idx=goal->idx;
   while(idx--)
      if(goal->mapIdx[idx]==mapIdx)
      {
         goal->mapIdx[idx]=goal->mapIdx[--goal->idx];
         return(idx);
      }
   return(-1);
}

////////////////////
// AStarGoalClean //
////////////////////
inline void AStarGoalClean(Goal* goal)
{
   goal->idx=0;
}

//////////////////////
// AStarGoalDestroy //
//////////////////////
void AStarGoalDestroy(Goal* goal)
{
   free(goal->mapIdx);
   free(goal);
}
