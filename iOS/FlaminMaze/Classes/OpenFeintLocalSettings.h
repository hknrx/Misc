typedef struct
{
	unsigned int level;
	NSString const*const achievementId;
}
OpenFeintAchievment;

static NSString const*const openFeintProductKey = @"IGFdodNXwSoOvkxmHuiA";
static NSString const*const openFeintSecret = @"wZDRmZbQWl8lTsJBvfdutUjvbeyHXKLfAr0uUbZg";
static NSString const*const openFeintDisplayName = @"Flamin Maze";
static NSString const*const openFeintDefaultLabel = @"OpenFeint";
static NSString const*const openFeintLeaderboardIdEscape = @"204574";
static NSString const*const openFeintLeaderboardIdExplore = @"520524";
static OpenFeintAchievment const openFeintAchievmentLevel[] =
{
	{ 4, @"209994"},
	{ 8, @"210004"},
	{16, @"210014"},
	{32, @"210024"},
	{64, @"210034"},
};
static const OpenFeintAchievment openFeintAchievmentCount[] =
{
	{  50, @"210074"},
	{ 200, @"210084"},
	{1000, @"210094"},
};
static const OpenFeintAchievment openFeintAchievmentGiveUp[] =
{
	{20, @"210044"},
	{41, @"210054"},
	{-1, @"210064"},
};
