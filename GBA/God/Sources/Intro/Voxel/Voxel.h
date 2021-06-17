/*
** God - Sources\Intro\Voxel\Voxel.h
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

#ifndef VOXEL_H
#define VOXEL_H

////////////////
// Inclusions //
////////////////
#include "..\..\Common\Common.h"

////////////
// Macros //
////////////
#define MAP_SIZE_SHIFT 7
#define MAP_SIZE       (1<<MAP_SIZE_SHIFT)
#define MAP_SIZE_MASK  (MAP_SIZE-1)
#define MAP_DEF_SHIFT  5

#define DIST_MIN       4
#define DIST_MAX       98
#define DIST_CAM_SHIFT 6

#define SPEED_SHIFT 1

////////////////
// Prototypes //
////////////////
void VoxelInit(void);
void VoxelDestroy(void);
signed long VoxelMove(signed long* x,signed long* z,unsigned char Ry);
void CODE_IN_IWRAM VoxelDisplay(signed long x,signed long y,signed long z,unsigned char Ry);

#endif // VOXEL_H
