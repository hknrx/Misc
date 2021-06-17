/*
** Mister Jelly - Sources\Common\GBAccelerometer\GBAccelerometer.h
** Nicolas ROBERT [NRX] - France 2006
*/

#ifndef GBACCELEROMETER_H
#define GBACCELEROMETER_H

////////////////
// Prototypes //
////////////////
void GBAccelerometerInit(void);
unsigned char GBAccelerometerTest(void);
signed long GBAccelerometerReadX(void);
signed long GBAccelerometerReadY(void);
signed long GBAccelerometerReadZ(void);
unsigned char GBAccelerometerReadAngleXY(void);

#endif // GBACCELEROMETER_H
