/*
** Bomb Jack - Sources\Menu\Menu.h
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

#ifndef MENU_H
#define MENU_H

////////////////
// Inclusions //
////////////////
#include "..\Common\Common.h"
#include "..\Game\GamePersistentData.h"

////////////////
// Prototypes //
////////////////
void MenuHiScoreInit(void);
void MenuMain(void);
void MenuBonus(GamePlayer* player);

#endif // MENU_H
