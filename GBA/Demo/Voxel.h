#ifndef VOXEL_H
#define VOXEL_H

#include "Commun.h"

void initVoxel(void);
signed long deplacementVoxel(signed long* xcam,signed long* zcam,unsigned char A);
void voxel(signed long xcam,signed long ycam,signed long zcam,unsigned char A);

#endif // VOXEL_H
