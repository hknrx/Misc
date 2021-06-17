#ifndef RAYCASTER_H
#define RAYCASTER_H

#include "Commun.h"

void initRayCaster(void);
void deplacementRC(signed long* xcam,signed long* zcam,unsigned char A);
void sol(signed long xcam,signed long ycam,signed long zcam,unsigned char A);
void rayCaster(signed long xcam,signed long ycam,signed long zcam,unsigned char A);

#endif // RAYCASTER_H
