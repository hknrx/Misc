#ifndef Z80_H
#define Z80_H

#include "..\Common\Common.h"

void z80_init(void);
void z80_reset(unsigned short address);
void CODE_IN_IWRAM z80_execute(void);
void z80_loadSNA(unsigned char* SNA);

#endif // Z80_H
